"""Robot Framework library for driving the real jsonquery_gui binary.

Architecture (see docs/00_test_strategy.md for the full rationale and the
confirmed environment findings that shaped this):

- The whole suite runs against an isolated Xvfb virtual display, not whatever
  real desktop session happens to be running -- GNOME/Wayland screen capture
  is confirmed blocked for unattended automation, Xvfb is not.
- Xvfb has no window manager of its own, and bare Xvfb silently breaks
  keyboard-focus delivery (confirmed: typed keys go nowhere without one), so a
  minimal EWMH window manager (fluxbox) runs alongside it.
- The app is launched with WAYLAND_DISPLAY unset so winit picks the X11/Xwayland
  backend that the rest of this stack (mss, pyautogui, xdotool) can actually see.
- Clicking is coordinate-based, computed relative to the app window's current
  client-area origin (looked up fresh via xdotool for every interaction, so a
  suite doesn't care exactly where the window manager placed the window).
  Text assertions and text-based clicking use Tesseract OCR over a cropped,
  upscaled region -- confirmed far more reliable than whole-window OCR, which
  misses most of this UI's small toolbar text.
- Native Open File / Save dialogs are a confirmed dead end in this environment
  (rfd's default xdg-portal backend hangs or errors before showing anything
  usable -- see the strategy doc). Keywords here do not attempt to drive them.
"""

import collections
import functools
import http.server
import os
import re
import signal
import subprocess
import sys
import threading
import time

import pyautogui
import pyperclip
import pytesseract
from PIL import Image, ImageChops
from robot.api import logger
from robot.api.deco import keyword, library
from robot.libraries.BuiltIn import BuiltIn

pyautogui.FAILSAFE = False

# The app is its own repository (jsonquery_gui), beside this one. run.sh exports
# JQ_APP_DIR; without it the app is looked for next to this repository.
APP_DIR = os.path.abspath(
    os.environ.get(
        "JQ_APP_DIR",
        os.path.join(os.path.dirname(__file__), "..", "..", "jsonquery_gui"),
    )
)
# JQ_TEST_BINARY / JQ_TEST_DISPLAY (and JQ_TEST_RESULTS, JQ_TEST_NO_BUILD in
# run.sh) let a second run go on beside the first -- another display, its
# own results, a copy of the binary that a rebuild does not replace. Unset, they
# are the defaults.
BINARY_PATH = os.environ.get(
    "JQ_TEST_BINARY", os.path.join(APP_DIR, "target", "debug", "jsonquery_gui")
)

XVFB_DISPLAY = os.environ.get("JQ_TEST_DISPLAY", ":99")
XVFB_SCREEN_SIZE = "1280x900x24"


def _run(cmd, **kwargs):
    return subprocess.run(cmd, capture_output=True, text=True, **kwargs)


@library(scope="GLOBAL")
class AppLibrary:
    """Keywords for launching, driving, and reading the jsonquery GUI."""

    def __init__(self):
        self._xvfb_proc = None
        self._wm_proc = None
        self._app_proc = None
        # The window the coordinate keywords act on (`Switch To Window`), and
        # the app's main window, which it goes back to.
        self._window_id = None
        self._main_window_id = None
        self._fixture_server = None
        self._fixture_server_thread = None
        self._shot_test_name = None
        self._shot_seq = 0
        self._hover_proc = None

    # -- display lifecycle (once per suite run) -----------------------------

    @staticmethod
    def _ensure_fluxbox_no_decoration_rule():
        """Writes a fluxbox apps-rule so the jsonquery window gets no
        titlebar/border -- required for `_window_origin` to be accurate; see
        its docstring. Must match by WM_CLASS (`class=`), not WM_NAME: this
        app's WM_CLASS is ("", "jsonquery_gui") with an empty instance part,
        so a `name=jsonquery` rule silently never matches anything."""
        fluxbox_dir = os.path.expanduser("~/.fluxbox")
        os.makedirs(fluxbox_dir, exist_ok=True)
        apps_path = os.path.join(fluxbox_dir, "apps")
        rule = "[app] (class=jsonquery_gui)\n  [Deco] {NONE}\n[end]\n"
        existing = ""
        if os.path.exists(apps_path):
            existing = open(apps_path).read()
        if rule not in existing:
            with open(apps_path, "a") as f:
                f.write(rule)

    @keyword("Start Test Display")
    def start_test_display(self):
        """Starts an isolated Xvfb display plus a minimal window manager.

        Idempotent-ish: if display :99 is already up (e.g. a previous run
        didn't get torn down cleanly), it's reused rather than double-started.
        """
        os.environ["DISPLAY"] = XVFB_DISPLAY
        self._ensure_fluxbox_no_decoration_rule()
        if not os.path.exists(f"/tmp/.X11-unix/X{XVFB_DISPLAY.lstrip(':')}"):
            self._xvfb_proc = subprocess.Popen(
                ["Xvfb", XVFB_DISPLAY, "-screen", "0", XVFB_SCREEN_SIZE, "-nolisten", "tcp"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            time.sleep(1)
        else:
            logger.info(f"Xvfb already running on {XVFB_DISPLAY}, reusing it.")

        self._wm_proc = subprocess.Popen(
            ["fluxbox"],
            env={**os.environ, "DISPLAY": XVFB_DISPLAY},
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        time.sleep(1)

    @keyword("Stop Test Display")
    def stop_test_display(self):
        """Stops the window manager and, if this run started it, Xvfb too."""
        for proc in (self._wm_proc, self._xvfb_proc):
            if proc is not None:
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
        self._wm_proc = None
        self._xvfb_proc = None

    # -- app lifecycle (once per test) ---------------------------------------

    @keyword("Launch Jsonquery App")
    def launch_jsonquery_app(self, timeout=10):
        """Starts a fresh jsonquery_gui process and waits for its window."""
        if not os.path.exists(BINARY_PATH):
            raise AssertionError(
                f"{BINARY_PATH} not found -- run `cargo build -p jsonquery_gui` first."
            )
        env = dict(os.environ)
        env["DISPLAY"] = XVFB_DISPLAY
        env.pop("WAYLAND_DISPLAY", None)
        # JQ_TEST_APP_LOG=<file>: the app's stderr (a debug build's tracing) goes
        # there instead of nowhere.
        app_log = os.environ.get("JQ_TEST_APP_LOG")
        self._app_proc = subprocess.Popen(
            [BINARY_PATH],
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=open(app_log, "a") if app_log else subprocess.DEVNULL,
        )

        deadline = time.time() + timeout
        wid = None
        while time.time() < deadline:
            wid = self._find_window_id()
            if wid:
                break
            time.sleep(0.2)
        if not wid:
            raise AssertionError("jsonquery window did not appear within timeout")
        self._window_id = wid
        self._main_window_id = wid
        # A freshly-mapped window isn't reliably ready to receive synthetic
        # keyboard input yet -- confirmed empirically: without an explicit
        # focus + settle here, the first keystrokes sent to a just-launched
        # window are silently dropped often enough to be a real flake source
        # (fluxbox's own focus-on-map isn't instant). Force focus and give it
        # a moment before any test interacts with the window.
        _run(
            ["xdotool", "windowfocus", "--sync", wid],
            env={**os.environ, "DISPLAY": XVFB_DISPLAY},
        )
        time.sleep(0.5)

    @keyword("Close Jsonquery App")
    def close_jsonquery_app(self):
        """Kills the current jsonquery_gui process, if any.

        First captures one full-window screenshot tagged with the test's
        final status, so every test -- not just ones that happen to make
        their own OCR/region checks -- leaves behind at least one piece of
        visual evidence in the log. Best-effort: a screenshot failure (e.g.
        the window already vanished) must never block the process cleanup
        below, since this keyword runs unconditionally as Test Teardown."""
        if self._window_id is not None:
            try:
                status = BuiltIn().get_variable_value("${TEST STATUS}") or "UNKNOWN"
                self._window_id = self._main_window_id
                self.screenshot_window(label=f"final-{status}")
                # Tests that open further windows (pop-out panes, the
                # tutorial) leave evidence of the whole screen too.
                self.screenshot_screen(label=f"screen-{status}")
            except Exception as e:
                logger.warn(f"Could not capture final screenshot: {e}")
        try:
            self.stop_hovering_files()
        except Exception:
            pass
        if self._app_proc is not None:
            try:
                # A window nobody gave a title ("egui window", eframe's default)
                # is a window the app opened without meaning to.
                strays = [w for w in self.list_windows() if w[1] == "egui window"]
                if strays:
                    logger.warn(f"STRAY WINDOW at the end of the test: {strays}")
            except Exception as e:
                logger.info(f"Could not list windows: {e}")
            try:
                self._app_proc.send_signal(signal.SIGKILL)
                self._app_proc.wait(timeout=5)
            except Exception:
                pass
        self._app_proc = None
        self._window_id = None
        self._main_window_id = None

    def _find_window_id(self):
        result = _run(
            ["xdotool", "search", "--name", "^jsonquery$"],
            env={**os.environ, "DISPLAY": XVFB_DISPLAY},
        )
        ids = [line for line in result.stdout.splitlines() if line.strip()]
        return ids[0] if ids else None

    # -- window geometry / coordinate translation ----------------------------

    def _window_origin(self):
        """Absolute screen coords of the app window's top-left corner.

        Requires `~/.fluxbox/apps` to mark this window class `Deco: NONE`
        (see `ensure_fluxbox_no_decoration_rule` / run.sh) -- without
        it, fluxbox adds a titlebar and `xdotool getwindowgeometry` reports a
        Y origin that does not match the window's actual visible top edge
        (confirmed empirically: ~26px off, cross-checked by OCR-locating the
        toolbar in a raw screenshot). With the Deco:NONE rule applied, the
        reported geometry matches the true content origin exactly.
        """
        if not self._window_id:
            raise AssertionError("No app window -- call `Launch Jsonquery App` first.")
        result = _run(
            ["xdotool", "getwindowgeometry", "--shell", self._window_id],
            env={**os.environ, "DISPLAY": XVFB_DISPLAY},
        )
        values = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
        return int(values["X"]), int(values["Y"])

    def _require_window(self):
        if not self._window_id:
            raise AssertionError("No app window -- call `Launch Jsonquery App` first.")

    # -- other windows of the app (pop-out panes) ------------------------------

    @staticmethod
    def _title_pattern(title):
        """A regex for `xdotool search --name` matching exactly `title`.
        xdotool reads the legacy (Latin-1) window name, in which the em dash of
        "jsonquery — Query" is three odd characters that a literal pattern
        never matches -- so each run of non-ASCII characters in the title
        becomes a wildcard."""
        parts = re.split(r"[^\x00-\x7f]+", title)
        return "^" + ".+".join(re.escape(part) for part in parts) + "$"

    @classmethod
    def _search_windows(cls, title):
        result = _run(
            ["xdotool", "search", "--name", cls._title_pattern(title)],
            env={**os.environ, "DISPLAY": XVFB_DISPLAY},
        )
        return [line for line in result.stdout.splitlines() if line.strip()]

    @keyword("Window Exists")
    def window_exists(self, title):
        """True if a window with exactly this title is open."""
        return bool(self._search_windows(title))

    @keyword("List Windows")
    def list_windows(self):
        """Every window of the test display that has a name, as (id, name,
        x, y, width, height) -- for finding a window that should not be there
        (the log gets the list too)."""
        env = {**os.environ, "DISPLAY": XVFB_DISPLAY}
        ids = _run(["xdotool", "search", "--name", "."], env=env).stdout.split()
        found = []
        for wid in ids:
            name = _run(["xdotool", "getwindowname", wid], env=env).stdout.strip()
            geo = _run(["xdotool", "getwindowgeometry", "--shell", wid], env=env).stdout
            v = dict(line.split("=", 1) for line in geo.splitlines() if "=" in line)
            if name:
                props = _run(["xprop", "-id", wid, "WM_CLASS", "_NET_WM_PID"], env=env).stdout
                props = " ".join(props.split())
                found.append(
                    (wid, name, int(v.get("X", 0)), int(v.get("Y", 0)),
                     int(v.get("WIDTH", 0)), int(v.get("HEIGHT", 0)), props)
                )
        logger.info("windows: " + "; ".join(repr(w) for w in found))
        return found

    @keyword("Count Windows")
    def count_windows(self, title):
        """How many windows have exactly this title (a window must not be
        opened twice)."""
        return len(self._search_windows(title))

    @keyword("Wait Until Window Exists")
    def wait_until_window_exists(self, title, timeout=5):
        deadline = time.time() + float(timeout)
        while time.time() < deadline:
            if self._search_windows(title):
                time.sleep(0.5)  # let it draw its first frames
                return
            time.sleep(0.2)
        raise AssertionError(f"No window titled {title!r} within {timeout}s")

    @keyword("Wait Until Window Closes")
    def wait_until_window_closes(self, title, timeout=5):
        deadline = time.time() + float(timeout)
        while time.time() < deadline:
            if not self._search_windows(title):
                return
            time.sleep(0.2)
        raise AssertionError(f"Window {title!r} was still open after {timeout}s")

    @keyword("Switch To Window")
    def switch_to_window(self, title):
        """Makes the window with this exact title the one every coordinate
        keyword (clicks, screenshots, OCR) is relative to, until
        `Switch To Main Window`. Its top-left is (0, 0), like the main
        window's -- popped-out panes are undecorated here, the same
        `Deco: NONE` rule as the main window."""
        ids = self._search_windows(title)
        if not ids:
            raise AssertionError(f"No window titled {title!r}")
        self._window_id = ids[0]
        self._raise_and_focus()

    @keyword("Switch To Main Window")
    def switch_to_main_window(self):
        self._window_id = self._main_window_id
        self._raise_and_focus()

    def _raise_and_focus(self):
        """Brings the current window to the front and gives it the keyboard
        focus. Raised, not only focused: the screen is what gets read and
        clicked, so a window another one covers (the tutorial opens over the
        main window) would be read -- and clicked -- through the other."""
        env = {**os.environ, "DISPLAY": XVFB_DISPLAY}
        # `wmctrl -a` (EWMH _NET_ACTIVE_WINDOW) raises the window's *frame*; a
        # plain XRaiseWindow on the client only reorders it inside its frame and
        # leaves the stack as it was.
        _run(["wmctrl", "-i", "-a", self._window_id], env=env)
        _run(["xdotool", "windowfocus", "--sync", self._window_id], env=env)
        time.sleep(0.3)

    @keyword("Close Window")
    def close_window(self, title):
        """Asks the window manager to close the window, as the close button
        of its title bar would -- the app sees a close request."""
        ids = self._search_windows(title)
        if not ids:
            raise AssertionError(f"No window titled {title!r}")
        env = {**os.environ, "DISPLAY": XVFB_DISPLAY}
        # Raised first, as a user must see a window to press its close button:
        # eframe (0.36) runs no UI pass at all for a window X11 reports as fully
        # obscured, so a close request to a window the main window covers
        # completely is not even noticed until it is uncovered (confirmed by
        # tracing eframe: `show_ui=false` for the covered window). That is the
        # toolkit's rule, not something the tests are about.
        _run(["wmctrl", "-i", "-a", ids[0]], env=env)
        time.sleep(0.4)
        _run(["wmctrl", "-i", "-c", ids[0]], env=env)

    @keyword("Get Window Geometry")
    def get_window_geometry(self, title):
        """(x, y, width, height) of the window on the screen."""
        ids = self._search_windows(title)
        if not ids:
            raise AssertionError(f"No window titled {title!r}")
        result = _run(
            ["xdotool", "getwindowgeometry", "--shell", ids[0]],
            env={**os.environ, "DISPLAY": XVFB_DISPLAY},
        )
        v = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
        return int(v["X"]), int(v["Y"]), int(v["WIDTH"]), int(v["HEIGHT"])

    @keyword("Maximize Window")
    def maximize_window(self, title):
        """Asks the window manager to maximize the window, as the maximize
        button of its title bar would, and waits for it to have grown."""
        ids = self._search_windows(title)
        if not ids:
            raise AssertionError(f"No window titled {title!r}")
        before = self.get_window_geometry(title)
        _run(
            ["wmctrl", "-i", "-r", ids[0], "-b", "add,maximized_vert,maximized_horz"],
            env={**os.environ, "DISPLAY": XVFB_DISPLAY},
        )
        deadline = time.time() + 5
        while time.time() < deadline and self.get_window_geometry(title) == before:
            time.sleep(0.2)
        time.sleep(1.0)  # let it draw at its new size
        if self.get_window_geometry(title) == before:
            raise AssertionError(f"Window {title!r} did not change size when maximized")

    @keyword("Move Window")
    def move_window(self, title, x, y):
        ids = self._search_windows(title)
        if not ids:
            raise AssertionError(f"No window titled {title!r}")
        _run(
            ["xdotool", "windowmove", ids[0], str(int(x)), str(int(y))],
            env={**os.environ, "DISPLAY": XVFB_DISPLAY},
        )
        time.sleep(0.3)

    @keyword("Get Window Size")
    def get_window_size(self):
        self._require_window()
        result = _run(
            ["xdotool", "getwindowgeometry", "--shell", self._window_id],
            env={**os.environ, "DISPLAY": XVFB_DISPLAY},
        )
        values = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
        return int(values["WIDTH"]), int(values["HEIGHT"])

    def _to_absolute(self, x, y):
        ox, oy = self._window_origin()
        return ox + x, oy + y

    # -- mouse / keyboard, relative to the app window ------------------------

    @keyword("Click At")
    def click_at(self, x, y, button="left"):
        """Clicks at (x, y) relative to the app window's client-area origin."""
        ax, ay = self._to_absolute(int(x), int(y))
        pyautogui.click(ax, ay, button=button)

    @keyword("Double Click At")
    def double_click_at(self, x, y):
        ax, ay = self._to_absolute(int(x), int(y))
        pyautogui.doubleClick(ax, ay)

    @keyword("Right Click At")
    def right_click_at(self, x, y):
        ax, ay = self._to_absolute(int(x), int(y))
        pyautogui.rightClick(ax, ay)

    @keyword("Move Mouse To")
    def move_mouse_to(self, x, y):
        ax, ay = self._to_absolute(int(x), int(y))
        pyautogui.moveTo(ax, ay)

    @keyword("Drag Mouse")
    def drag_mouse(self, x1, y1, x2, y2, duration=0.6):
        """Presses the left button at (x1, y1), drags to (x2, y2) over
        `duration` seconds, and releases -- all app-relative. The pauses and the
        gradual move matter: a drag that jumps straight to its target in one
        event is not reliably seen by egui as a drag at all."""
        ax1, ay1 = self._to_absolute(int(x1), int(y1))
        ax2, ay2 = self._to_absolute(int(x2), int(y2))
        pyautogui.moveTo(ax1, ay1)
        time.sleep(0.2)
        pyautogui.mouseDown()
        time.sleep(0.2)
        pyautogui.moveTo(ax2, ay2, duration=float(duration))
        time.sleep(0.2)
        pyautogui.mouseUp()
        time.sleep(0.2)

    @keyword("Drop Files On Window")
    def drop_files_on_window(self, x, y, *paths):
        """Drops the files on the current window at (x, y), window-relative, as
        a file manager's drag and drop does -- an XDND source written for these
        tests (`xdnd.py`: `xdotool` cannot drag files). Fails if the window
        does not take the drop or never says it is finished with it."""
        self._require_window()
        ax, ay = self._to_absolute(int(x), int(y))
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "xdnd.py")
        result = subprocess.run(
            [sys.executable, script, XVFB_DISPLAY, str(int(self._window_id)),
             str(ax), str(ay), *[str(p) for p in paths]],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            raise AssertionError(f"The drop failed: {result.stderr.strip() or result.stdout.strip()}")
        time.sleep(0.5)

    @keyword("Start Hovering Files")
    def start_hovering_files(self, x, y, *paths):
        """Holds files over the current window at (x, y), window-relative,
        without dropping them -- a drag in progress (see `xdnd.py --hold`) --
        until `Stop Hovering Files`. Returns once the window has taken the file
        list, which is what makes it draw its drop overlay."""
        self._require_window()
        self.stop_hovering_files()
        ax, ay = self._to_absolute(int(x), int(y))
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "xdnd.py")
        self._hover_proc = subprocess.Popen(
            [sys.executable, script, "--hold", XVFB_DISPLAY, str(int(self._window_id)),
             str(ax), str(ay), *[str(p) for p in paths]],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        ready = []
        reader = threading.Thread(
            target=lambda: ready.append(self._hover_proc.stdout.readline()), daemon=True
        )
        reader.start()
        reader.join(timeout=10)
        if not ready or "READY" not in ready[0]:
            self.stop_hovering_files()
            raise AssertionError("The window did not take the hovering files")
        time.sleep(0.6)

    @keyword("Stop Hovering Files")
    def stop_hovering_files(self):
        """Cancels the drag `Start Hovering Files` began (the window sees the
        files leave)."""
        proc = getattr(self, "_hover_proc", None)
        if proc is not None:
            try:
                proc.terminate()
                proc.wait(timeout=5)
            except Exception:
                proc.kill()
        self._hover_proc = None
        time.sleep(0.5)

    @keyword("Scroll At")
    def scroll_at(self, x, y, clicks):
        """Scrolls the mouse wheel `clicks` steps (negative = down) at the
        given app-relative point -- egui's scroll areas, like most UI
        toolkits, scroll whichever one the pointer is currently over."""
        ax, ay = self._to_absolute(int(x), int(y))
        pyautogui.moveTo(ax, ay)
        pyautogui.scroll(int(clicks))

    @keyword("Type Text")
    def type_text(self, text, interval=0.02):
        pyautogui.typewrite(text, interval=float(interval))

    @keyword("Press Keys")
    def press_keys(self, *keys):
        """E.g. `Press Keys    ctrl    enter` for Ctrl+Enter. Key names must
        be pyautogui's own lowercase names (`enter`, not `Return`/`Enter` --
        confirmed the capitalized X11-style name is NOT equivalent here and
        produces flaky, not consistently-failing, results, so this is an easy
        mistake to half-miss in testing). `interval` is passed to
        `pyautogui.hotkey` between each key-down -- confirmed during
        implementation that the default (0s, all keys sent essentially at
        once) is a real source of the "occasionally doesn't land" flakiness
        documented elsewhere in this suite: 8/8 trials landed cleanly with a
        50ms interval versus a noticeably-less-than-100% hit rate at 0s.
        Kept as a keyword-level default rather than hardcoded so a caller can
        override it if some other combo needs more (or can tolerate less)."""
        pyautogui.hotkey(*keys, interval=0.05)

    @keyword("Press Key")
    def press_key(self, key):
        pyautogui.press(key)

    # -- screenshots / OCR ----------------------------------------------------

    @staticmethod
    def _slugify(name):
        return re.sub(r"[^A-Za-z0-9_-]+", "_", name).strip("_") or "unknown"

    def _next_screenshot_path(self, tag):
        """Path (under `<outputdir>/screenshots/<test>/`) for the next
        auto-captured screenshot of the current test, numbered in the order
        they're taken so the log reads top-to-bottom the same way the test
        ran. Numbering (and the subfolder) resets whenever the active test
        name changes, so a re-run or a new test starts back at 1 rather than
        accumulating across the whole suite."""
        test_name = BuiltIn().get_variable_value("${TEST NAME}") or "no_test"
        if test_name != self._shot_test_name:
            self._shot_test_name = test_name
            self._shot_seq = 0
        self._shot_seq += 1
        out_dir = BuiltIn().get_variable_value("${OUTPUTDIR}") or "."
        shot_dir = os.path.join(out_dir, "screenshots", self._slugify(test_name))
        os.makedirs(shot_dir, exist_ok=True)
        filename = f"{self._shot_seq:03d}-{self._slugify(tag)}.png"
        return os.path.join(shot_dir, filename)

    def _embed_screenshot(self, abs_path, caption):
        """Logs `abs_path` into the Robot log as a clickable thumbnail, so
        every screenshot this library takes leaves behind visual evidence a
        human can actually check -- OCR/pixel text output alone can't show
        whether a mismatch was a genuine rendering bug or just a
        misread/timing artifact of the check itself."""
        out_dir = BuiltIn().get_variable_value("${OUTPUTDIR}") or "."
        rel_path = os.path.relpath(abs_path, out_dir)
        logger.info(
            f'{caption}<br/><a href="{rel_path}" target="_blank">'
            f'<img src="{rel_path}" style="max-width:480px;border:1px solid #999;"/></a>',
            html=True,
        )

    @keyword("Screenshot Region")
    def screenshot_region(self, x, y, width, height, path=None, log=True, label="region"):
        """Returns a PIL Image of the given app-relative region. Unless
        `log=False`, also saves it under `<outputdir>/screenshots/<test>/`
        and embeds it into the Robot log for this test (see
        `_embed_screenshot`) -- callers that only need a throwaway capture
        (e.g. `Get Pixel Color`'s 1x1 probe) pass `log=False` to skip this.
        `path`, if given, is an *additional* save location."""
        ax, ay = self._to_absolute(int(x), int(y))
        img = pyautogui.screenshot(region=(ax, ay, int(width), int(height)))
        if path:
            img.save(path)
        if log:
            auto_path = self._next_screenshot_path(label)
            img.save(auto_path)
            self._embed_screenshot(auto_path, f"{label} ({x},{y},{width}x{height})")
        return img

    @keyword("Screenshot Screen")
    def screenshot_screen(self, path=None, log=True, label="screen"):
        """The whole test display -- every window of the app at once."""
        img = pyautogui.screenshot()
        if path:
            img.save(path)
        if log:
            auto_path = self._next_screenshot_path(label)
            img.save(auto_path)
            self._embed_screenshot(auto_path, f"{label} (whole screen)")
        return img

    @keyword("Screenshot Window")
    def screenshot_window(self, path=None, log=True, label="window"):
        w, h = self.get_window_size()
        return self.screenshot_region(0, 0, w, h, path=path, log=log, label=label)

    @staticmethod
    def _ocr_words(img, upscale=5, psm=6):
        big = img.resize((img.width * upscale, img.height * upscale), Image.LANCZOS)
        data = pytesseract.image_to_data(
            big, output_type=pytesseract.Output.DICT, config=f"--psm {psm}"
        )
        words = []
        for i, text in enumerate(data["text"]):
            text = text.strip()
            if not text or int(data["conf"][i]) < 0:
                continue
            words.append(
                {
                    "text": text,
                    "left": data["left"][i] // upscale,
                    "top": data["top"][i] // upscale,
                    "width": data["width"][i] // upscale,
                    "height": data["height"][i] // upscale,
                    "line": (data["block_num"][i], data["par_num"][i], data["line_num"][i]),
                }
            )
        return words

    @staticmethod
    def _flatten_tints(img):
        """Grayscale copy in which everything up to the query box's dimmest
        tint is black and the text keeps its own (anti-aliased) brightness.

        The query box lays each step of the query on a tinted chip (max
        channel <= ~92 in the Dark theme) and Tesseract, given light text on
        one, reads nothing at all -- confirmed on a real failing capture
        (`.abcxyz` on orange came back as ''). Text is ~180, so a stretch from
        100..180 to 0..255 erases the tint and keeps the glyph edges smooth."""
        r, g, b = img.convert("RGB").split()
        brightest = ImageChops.lighter(ImageChops.lighter(r, g), b)
        return brightest.point(lambda v: 0 if v <= 100 else min(255, (v - 100) * 255 // 80))

    @keyword("Read Region Text")
    def read_region_text(self, x, y, width, height, psm=6, flatten_tints=False):
        """OCRs the given app-relative region and returns the recognized text.
        `flatten_tints=True` first erases the query box's tinted step
        backgrounds (see `_flatten_tints`); leave it off everywhere else --
        it would drop dim text."""
        img = self.screenshot_region(x, y, width, height, label="ocr-read")
        if flatten_tints:
            img = self._flatten_tints(img)
        words = self._ocr_words(img, psm=int(psm))
        # Group by line so multi-word text reads back in natural order.
        lines = {}
        for w in words:
            lines.setdefault(w["line"], []).append(w)
        out_lines = []
        for line_key in sorted(lines):
            line_words = sorted(lines[line_key], key=lambda w: w["left"])
            out_lines.append(" ".join(w["text"] for w in line_words))
        return "\n".join(out_lines)

    # Tesseract, at this font size, sometimes renders straight quotes/
    # apostrophes as their typographic "curly" equivalents (confirmed during
    # implementation: "start with '/'" came back as "start with '/'" with a
    # curly closing quote) -- normalize both sides before comparing so a test
    # asserting on straight ASCII quotes isn't tripped up by this.
    _QUOTE_MAP = str.maketrans(
        {"‘": "'", "’": "'", "“": '"', "”": '"'}
    )

    @classmethod
    def _normalize_for_match(cls, s):
        return s.lower().translate(cls._QUOTE_MAP)

    # Tesseract, at this font size, sometimes reads a digit "0" as the letter
    # "O" (confirmed: "0 B" came back as "OB", "0 result(s)" as "O
    # result(s)") -- folded into one more permissive fallback comparison
    # rather than avoiding the digit 0 in every assertion that might hit it.
    _ZERO_O_MAP = str.maketrans({"0": "o"})

    @classmethod
    def _text_contains(cls, actual, expected):
        a = cls._normalize_for_match(actual)
        e = cls._normalize_for_match(expected)
        if e in a:
            return True
        # Tesseract occasionally splits a single word around punctuation
        # into separate word-boxes (confirmed: "valid.json" -> "valid." +
        # "json"), which this library's own line-joining then reinserts a
        # space into -- retry with whitespace stripped from both sides as a
        # permissive fallback rather than failing on that alone.
        if e.replace(" ", "") in a.replace(" ", ""):
            return True
        a2 = a.translate(cls._ZERO_O_MAP).replace(" ", "")
        e2 = e.translate(cls._ZERO_O_MAP).replace(" ", "")
        return e2 in a2

    @keyword("Region Should Contain Text")
    def region_should_contain_text(
        self, x, y, width, height, expected, psm=6, msg=None, flatten_tints=False
    ):
        actual = self.read_region_text(
            x, y, width, height, psm=psm, flatten_tints=flatten_tints
        )
        if not self._text_contains(actual, expected):
            raise AssertionError(
                msg or f"Expected region to contain {expected!r}, but OCR read: {actual!r}"
            )

    @keyword("Region Should Not Contain Text")
    def region_should_not_contain_text(self, x, y, width, height, unexpected, psm=6, msg=None):
        actual = self.read_region_text(x, y, width, height, psm=psm)
        if self._text_contains(actual, unexpected):
            raise AssertionError(
                msg or f"Expected region NOT to contain {unexpected!r}, but OCR read: {actual!r}"
            )

    @keyword("Wait Until Region Contains Text")
    def wait_until_region_contains_text(self, x, y, width, height, expected, timeout=5, psm=6):
        deadline = time.time() + float(timeout)
        last_seen = ""
        while time.time() < deadline:
            last_seen = self.read_region_text(x, y, width, height, psm=psm)
            if self._text_contains(last_seen, expected):
                return last_seen
            time.sleep(0.2)
        raise AssertionError(
            f"Region never contained {expected!r} within {timeout}s "
            f"(last OCR read: {last_seen!r})"
        )

    @keyword("Wait Until Region Matches")
    def wait_until_region_matches(self, x, y, width, height, pattern, timeout=5, psm=6):
        """Like `Wait Until Region Contains Text` but matches a regex."""
        deadline = time.time() + float(timeout)
        last_seen = ""
        compiled = re.compile(pattern, re.IGNORECASE)
        while time.time() < deadline:
            last_seen = self.read_region_text(x, y, width, height, psm=psm)
            if compiled.search(last_seen):
                return last_seen
            time.sleep(0.2)
        raise AssertionError(
            f"Region never matched /{pattern}/ within {timeout}s "
            f"(last OCR read: {last_seen!r})"
        )

    @keyword("Find Text In Region")
    def find_text_in_region(self, x, y, width, height, target, psm=6):
        """Returns (center_x, center_y) of `target` within the region, in
        app-relative coordinates, or raises if not found. Case-insensitive.
        Checks single OCR word/tokens first, then contiguous runs of words on
        the same line (e.g. "Copy JSON Path" is 3 separate tokens to
        Tesseract) -- confirmed necessary during implementation for any
        multi-word button/menu-item label."""
        img = self.screenshot_region(x, y, width, height, label=f"find-{target}")
        words = self._ocr_words(img, psm=int(psm))
        target_l = target.lower()
        for w in words:
            if target_l in w["text"].lower():
                return (
                    int(x) + w["left"] + w["width"] / 2,
                    int(y) + w["top"] + w["height"] / 2,
                )
        lines = {}
        for w in words:
            lines.setdefault(w["line"], []).append(w)
        for line_words in lines.values():
            line_words = sorted(line_words, key=lambda w: w["left"])
            joined = " ".join(w["text"] for w in line_words).lower()
            if target_l in joined:
                left = min(w["left"] for w in line_words)
                right = max(w["left"] + w["width"] for w in line_words)
                top = min(w["top"] for w in line_words)
                bottom = max(w["top"] + w["height"] for w in line_words)
                return (int(x) + (left + right) / 2, int(y) + (top + bottom) / 2)
        raise AssertionError(
            f"Text {target!r} not found in region ({x},{y},{width},{height}); "
            f"OCR saw: {[w['text'] for w in words]}"
        )

    @keyword("Click Text In Region")
    def click_text_in_region(self, x, y, width, height, target, psm=6):
        """Finds `target` by OCR within the given region and clicks its center."""
        cx, cy = self.find_text_in_region(x, y, width, height, target, psm=psm)
        self.click_at(cx, cy)

    @keyword("Get Pixel Color")
    def get_pixel_color(self, x, y):
        """Returns an (r, g, b) tuple for the app-relative pixel."""
        # A single pixel is meaningless as visual evidence, so this one
        # capture is deliberately excluded from the log (see
        # `screenshot_region`'s `log` param).
        img = self.screenshot_region(x, y, 1, 1, log=False)
        return img.convert("RGB").getpixel((0, 0))

    @keyword("Colors Should Match")
    def colors_should_match(self, color_a, color_b, tolerance=6, msg=None):
        """Compares two (r, g, b) tuples allowing a small per-channel
        tolerance -- exact equality is too strict for screen-captured colors,
        which vary by a few units between frames from anti-aliasing and
        hover/selection transition easing (confirmed during implementation:
        a genuinely-still-selected button read (53,128,163) then
        (51,127,161) a moment later)."""
        diff = max(abs(a - b) for a, b in zip(color_a, color_b))
        if diff > int(tolerance):
            raise AssertionError(
                msg or f"Colors differ by {diff} (> tolerance {tolerance}): "
                f"{color_a} vs {color_b}"
            )

    @keyword("Colors Should Not Match")
    def colors_should_not_match(self, color_a, color_b, tolerance=6, msg=None):
        diff = max(abs(a - b) for a, b in zip(color_a, color_b))
        if diff <= int(tolerance):
            raise AssertionError(
                msg or f"Colors are within tolerance {tolerance} (diff {diff}), "
                f"expected a visible difference: {color_a} vs {color_b}"
            )

    def _pixels_near(self, x, y, width, height, r, g, b, tolerance):
        """How many pixels of the app-relative region are within `tolerance`
        (per channel) of (r, g, b)."""
        img = self.screenshot_region(x, y, width, height, label="color-probe")
        target = (int(r), int(g), int(b))
        tol = int(tolerance)
        return sum(
            1
            for px in img.convert("RGB").getdata()
            if max(abs(a - c) for a, c in zip(px, target)) <= tol
        )

    @keyword("Region Should Contain Color")
    def region_should_contain_color(
        self, x, y, width, height, r, g, b, tolerance=6, msg=None
    ):
        """Passes if any pixel in the region is close to (r, g, b). For
        colored *backgrounds behind text* (the query box's tinted steps): the
        glyphs cover part of the region, so a single fixed pixel might land on
        a stroke, but somewhere in a wide-enough strip the bare tint shows."""
        if not self._pixels_near(x, y, width, height, r, g, b, tolerance):
            raise AssertionError(
                msg or f"No pixel near ({r}, {g}, {b}) in region "
                f"({x},{y},{width},{height})"
            )

    @keyword("Region Should Not Contain Color")
    def region_should_not_contain_color(
        self, x, y, width, height, r, g, b, tolerance=6, msg=None
    ):
        count = self._pixels_near(x, y, width, height, r, g, b, tolerance)
        if count:
            raise AssertionError(
                msg or f"{count} pixel(s) near ({r}, {g}, {b}) in region "
                f"({x},{y},{width},{height}), expected none"
            )

    @keyword("Region Should Be Plain")
    def region_should_be_plain(self, x, y, width, height, tolerance=4, msg=None):
        """Passes when every pixel of the region is (nearly) the one colour
        that most of it is, i.e. nothing is drawn there -- no line, no text.
        For "there is no divider under this header": a strip across the pane,
        between the header and the content, must be bare background."""
        img = self.screenshot_region(x, y, width, height, label="plain-probe")
        pixels = list(img.convert("RGB").getdata())
        base = collections.Counter(pixels).most_common(1)[0][0]
        tol = int(tolerance)
        off = [p for p in pixels if max(abs(a - b) for a, b in zip(p, base)) > tol]
        if off:
            raise AssertionError(
                msg or f"{len(off)} of {len(pixels)} pixels in region "
                f"({x},{y},{width},{height}) differ from the background {base}, "
                f"e.g. {off[0]}"
            )

    @keyword("Get Rows With Color")
    def get_rows_with_color(self, x, y, width, height, r, g, b, tolerance=6):
        """The rows (y, relative to the region's top) in which some pixel is
        within `tolerance` of (r, g, b) -- where a coloured band is, e.g. the
        rows a diff view marks, to compare between two columns."""
        img = self.screenshot_region(x, y, width, height, label="rows-probe")
        target = (int(r), int(g), int(b))
        tol = int(tolerance)
        w, h = img.size
        px = img.convert("RGB").load()
        rows = []
        for yy in range(h):
            for xx in range(w):
                if max(abs(a - c) for a, c in zip(px[xx, yy], target)) <= tol:
                    rows.append(yy)
                    break
        return rows

    @keyword("Get Ink Bounds")
    def get_ink_bounds(self, x, y, width, height, threshold=110):
        """(left, top, right, bottom) of the bright pixels (any channel at
        least `threshold`) of the region, relative to its top-left corner --
        how big some text or an icon is drawn, which OCR cannot say. Raises if
        nothing in the region is that bright."""
        img = self.screenshot_region(x, y, width, height, label="ink-probe")
        thr = int(threshold)
        w, h = img.size
        px = img.convert("RGB").load()
        xs, ys = [], []
        for yy in range(h):
            for xx in range(w):
                if max(px[xx, yy]) >= thr:
                    xs.append(xx)
                    ys.append(yy)
        if not xs:
            raise AssertionError(
                f"Nothing as bright as {thr} in region ({x},{y},{width},{height})"
            )
        return min(xs), min(ys), max(xs), max(ys)

    # -- clipboard -------------------------------------------------------------

    @keyword("Get Clipboard")
    def get_clipboard(self):
        return pyperclip.paste()

    @keyword("Set Clipboard")
    def set_clipboard(self, text):
        pyperclip.copy(text)

    # -- local HTTP fixture server (for Open URL... tests) ---------------------

    @keyword("Start Fixture Server")
    def start_fixture_server(self, directory):
        """Serves `directory` over HTTP on an OS-assigned free port (bound to
        127.0.0.1 only -- these tests never need, and shouldn't risk, being
        reachable from outside the test machine). Runs in a background thread
        inside this same process rather than a subprocess: simpler lifecycle,
        nothing extra to kill on teardown beyond `shutdown()`. Returns the
        server's base URL (e.g. `http://127.0.0.1:51234`)."""
        handler = functools.partial(
            http.server.SimpleHTTPRequestHandler, directory=directory
        )
        self._fixture_server = http.server.HTTPServer(("127.0.0.1", 0), handler)
        self._fixture_server_thread = threading.Thread(
            target=self._fixture_server.serve_forever, daemon=True
        )
        self._fixture_server_thread.start()
        port = self._fixture_server.server_address[1]
        return f"http://127.0.0.1:{port}"

    @keyword("Stop Fixture Server")
    def stop_fixture_server(self):
        if self._fixture_server is not None:
            self._fixture_server.shutdown()
            self._fixture_server.server_close()
        self._fixture_server = None
        self._fixture_server_thread = None
