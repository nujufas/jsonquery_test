# jsonquery GUI test strategy (Robot Framework)

Status: **10 suites, 74 test cases implemented and passing** (as of
2026-09-05, second implementation pass; by 2026-10-06 it is 22 suites and 588 cases, see
`README.md` and [99_traceability_matrix.md](99_traceability_matrix.md), and the
file dialogs are no longer blocked, see "Native OS dialogs" below). The sections below through
"Tooling" are the original requirements pass. Everything from "Confirmed
during implementation" onward documents what was actually verified by
running the real stack — screen capture and native dialogs were the two
findings from the *first* pass that changed the plan; ["Second
implementation pass"](#second-implementation-pass-confirmed-findings) below
covers what the *second* pass (search/tree/text/toolbar/context/keyboard/
saving suites) found, all load-bearing for anyone extending this suite
further.

## Why this approach, and what was ruled out

`jsonquery_gui` is built on **egui/eframe**, an immediate-mode GUI: there is no
persistent, inspectable widget tree by default, so tools that drive an app by
locating widgets in an accessibility tree (Selenium-style "find by id/role/name")
don't have anything to attach to out of the box.

Before committing to an approach, this was checked empirically rather than assumed:

- `eframe` 0.36's `accesskit` feature *is* enabled by default, and the compiled
  binary genuinely links `accesskit_unix`/`accesskit_atspi_common` (confirmed via
  `strings` on the debug binary).
- In practice, on this dev machine (GNOME 49-ish / Wayland, AT-SPI bus running,
  `org.gnome.desktop.interface toolkit-accessibility` tried both `false` and `true`),
  the running `jsonquery_gui` process **never appeared** in the AT-SPI desktop
  registry (`Atspi.get_desktop(0)` children), across two separate launches. Reading
  `accesskit_unix` 0.21.1's source confirms it *should* call
  `SocketProxy::embed(...)` unconditionally at startup via a background thread —
  so this looks like a real gap or race in that crate/version on this platform
  combination, not a configuration problem on our side.
- Conclusion: **do not build the test architecture on accessibility-tree locators.**
  It may start working with a future `accesskit`/`egui`/`winit` upgrade (worth a
  quick re-check next time those deps bump), but treating it as available today
  would block every test on an unresolved upstream issue.

This rules out the "cucumber + egui_kittest" idea discussed earlier, too, for a
different reason: `egui_kittest` drives the app's own event loop in-process
(great for Rust-side unit/integration tests) but doesn't exercise the real
compiled binary, real window, real OS file dialogs, or real rendering — and the
user has asked for Robot Framework specifically.

### Chosen approach: coordinate/image-based GUI automation, with OCR for text assertions

Robot Framework drives the **real, compiled `jsonquery_gui` binary** as an external
process, interacting with it the way a user would — mouse clicks (by image-template
match, not raw coordinates, so tests survive window moves and are somewhat resilient
to layout drift), keyboard input, and clipboard reads. Where a test needs to assert
on *text* the app rendered (status bar messages, tree/text view content, error
strings), OCR (Tesseract) reads it off a screenshot region, since there is no
accessible/DOM-like text API to query.

This is the standard fallback technique for testing immediate-mode/canvas-rendered
GUIs with Robot Framework, and it works today with zero changes to the app. Its
known cost is fragility: font rendering, theme, DPI scaling, and window position all
affect image/OCR matching. Mitigations baked into the requirements below:

- Force a fixed window size and a fixed theme (Dark, the app's default-on-launch
  state — see [01_launch_and_window.md](01_launch_and_window.md)) for every test run,
  so template images and OCR crop regions are reproducible.
- Match by cropped **template image**, not absolute pixel coordinates, for anything
  clickable.
- Prefer reading small, high-contrast, monospace text regions for OCR (the app's
  status bar and text view are monospace already — see the feature inventory), and
  keep the default font size rather than shrinking it.
- Treat OCR assertions as "contains/starts-with", not exact string equality, where
  dynamic content (durations, byte counts, generated errors with OS-specific paths)
  makes exact matching brittle by construction — this is called out per test case
  in the feature docs where it applies.

**Confirmed OCR limitation**: the app's dim "weak" gray text style (used for
placeholder hints, byte sizes, and several secondary status messages throughout
the UI — see the feature inventory) is genuinely hard for Tesseract to read
reliably, even with a tight crop, 5x upscaling, and contrast/inversion
preprocessing all tried during implementation — it comes back garbled rather
than just low-confidence. **Bright/normal-contrast text** (button labels, error
text, primary status messages) OCRs reliably at a tight crop + 5x upscale. When a
test case's only observable text is styled "weak", either accept a weaker
assertion (e.g. confirm an adjacent higher-contrast element instead, as
[launch_and_window.robot](../suites/launch_and_window/launch_and_window.robot)'s
TC-WIN-003 does) or flag it as a manually-reviewed case in the traceability
matrix rather than forcing a flaky automated assertion.

### Recommended (optional) app-side reliability enhancement — not in scope here

Because this is a small, self-contained OSS app, the single highest-leverage change
to make these tests far more reliable would be a **test-support hook in the app
itself**: e.g. when an env var like `JSONQUERY_TEST_STATE_PATH` is set, the app
writes a small JSON snapshot of its own state (status bar text, result count, error
strings, loaded-doc flag, tree row count) to that path once per frame. Tests could
then read ground truth directly instead of OCR for state assertions, while still
using real mouse/keyboard for interaction — eliminating most of the OCR-fragility
risk for correctness checks (though not for purely visual checks like color-by-type
in the tree view, which would still need image inspection).

This would require touching `crates/app/src` (production code, in the app's own
repository), which is outside the scope of this suite. **Flagging it here for a
decision, not implementing it.** If approved later, it changes several "Automation
notes" below from OCR to "read state file" and meaningfully de-risks the whole suite.

## Native OS dialogs: the `…` file picker and Save… — answered by a stand-in portal

**Resolved 2026-10-06.** For a long time every case that needed a file dialog was **Blocked**
(12 of them, see the history below). The harness now answers the dialog itself, so those cases are
implemented and the ones that never could be written are too: the `…` button, every `Save…` trigger,
Ctrl+S and the Tools window's own Open, Add files and Save buttons
(`suites/saving/saving_dialogs.robot`, `suites/opening_sources/opening_dialog.robot`,
`suites/tools/tools_dialogs.robot`, and the file cases of `suites/output_formats/` and
`suites/workflows/`).

### How the app asks

`jsonquery_gui` depends on `rfd = "0.17.2"` with default features (`xdg-portal` + `wayland`).
Every `rfd::FileDialog::...().pick_file()` / `save_file()` is a call on the D-Bus **session bus**
to `org.freedesktop.portal.Desktop` — `org.freedesktop.portal.FileChooser.OpenFile` or `SaveFile`,
made through libdbus (`dbus_bus_get_private`) on the UI thread. The call returns a request handle
at once and the answer comes later, as a `Response` signal on that handle (`ua{sv}`: a code, and
`uris` for the files chosen). If the call fails, `rfd` falls back to running `zenity`.

### The stand-in

`resources/fake_portal.py` starts a **private `dbus-daemon`** (a generated minimal config, no
service activation) and puts a small `org.freedesktop.portal.Desktop` on it, written with
[jeepney](https://pypi.org/project/jeepney/). `AppLibrary.launch_jsonquery_app` points the app at
that bus with `DBUS_SESSION_BUS_ADDRESS`. A case says what the person chooses — `Portal Will Save
To`, `Portal Will Pick`, `Portal Will Accept Suggested Name In`, `Portal Will Cancel` — and the
stand-in answers the next dialog that way; it also records what the app *asked for* (title,
suggested file name, folder, file types, one file or several, folder or file), which `Get Portal
Requests` returns, so a case can check the name `results.csv` and the type `CSV` the app offered
before it checks the file the app wrote.

What this tests is the app's side of the dialog: what it asks for and what it does with the
answer. The dialog's own look and behaviour belong to the desktop (GTK, GNOME, KDE) and are not
covered, nor is the `zenity` fallback.

- **One bus per display**, so parallel lanes never share a portal; and **a test app never sees the
  desktop's session bus** any more, which makes the isolation of the whole suite stricter than it
  was. (An app launched without the variable, as the old suites launched it, inherits the bus of
  the desktop session it was started from, when there is one, and a file dialog would then have
  reached that session's own portal.)
- **The answer is delayed 0.4 s** (`FakePortal.ANSWER_DELAY`). `rfd` reads the method reply and
  only then waits for the `Response`; a signal that libdbus has already read *together with* the
  reply sits in a queue nobody looks at, and the UI thread then waits for ever. A real portal answers
  when the person has chosen — seconds later — so only a stand-in that answers at once can hit it
  (about one dialog in ten under load, in the first version of the stand-in). Not an app defect.
- **A click sent while a dialog is open is lost**: the UI thread is inside the dialog call.
  `Wait Until Portal Is Asked` waits for the answer *and* for the app to carry on; a case with
  several dialogs counts them (`Portal Request Count`).
- Needs `dbus-daemon` (apt: `dbus-daemon`) and the Python package `jeepney`; `run.sh` checks both.

### The history: why the real portals were no use

The first spike, before the stand-in, found that the file picker and every `Save…` froze the app's
whole UI thread in every environment tried:

1. **Real GNOME/Wayland session, inherited D-Bus** — the app froze for ever; no dialog ever became
   visible on the real display.
2. **Isolated `dbus-run-session`, `GDK_BACKEND=x11` + `XDG_CURRENT_DESKTOP=GNOME` forced** — the
   portal started fresh `xdg-desktop-portal` + `-gnome` + `-gtk` instances, the GNOME backend
   declined ("GDK backend forced via env var, portal dialogs will not work properly") and the GTK
   backend failed with `No such interface "org.freedesktop.impl.portal.FileChooser"`. That failed
   fast, so the app stayed responsive, but no dialog appeared to automate.
3. **Isolated `dbus-run-session`, no forced backend** — `xdg-desktop-portal-gtk` logged `Failed to
   associate portal window with parent window` and hung as in (1): `rfd` hands the portal a
   parent-window token made from `winit`'s raw X11 handle, which the GTK backend cannot turn into
   a window it knows.

That is an `rfd`-versus-non-GTK-toolkit gap, not a misconfiguration: it reproduced identically on
the real desktop and on an isolated Xvfb with a private bus. The way round it was not to fix the
portals but to *be* the portal: with nothing but a name and a handle to answer, none of the above
applies. (Building `rfd` with its `gtk3` feature would have been an app dependency change, and
would have tested GTK's dialog instead of the app's.)

## Known, permanent constraints (not bugs to fix, just test-planning facts)

- **Drag-and-drop does not work on native Wayland** (documented in the app's own
  README as an upstream `winit` gap). Any drag-and-drop test case must either run
  under Xorg/XWayland explicitly, or be marked skip-on-Wayland — don't spend effort
  chasing it as a failure if the test host is pure Wayland.
- The **Cancel** button on a running query is a genuine race: a few more streamed
  result rows can land after cancellation is requested client-side. Tests that
  cancel a query must poll/settle briefly rather than asserting immediately.
- egui's own event loop and this app's worker-thread architecture mean most
  state changes (load, query, search, render) are asynchronous relative to the
  triggering click — every test case that follows an action with an assertion
  needs an explicit wait/retry on the expected UI state, not a fixed sleep sized
  by guesswork. Standard Robot Framework `Wait Until Keyword Succeeds` pattern.

## Tooling

| Concern | Choice | Why |
|---|---|---|
| Test framework | `robotframework` | User's explicit choice. |
| Process lifecycle (launch/kill the binary per test) | Robot's built-in `Process` library | No extra dependency; already exhaustively documented and reliable. |
| Mouse/keyboard + image-template matching | `robotframework-imagehorizonlibrary` | Purpose-built for exactly this (SikuliX-style template matching) with a much smaller, more focused dependency footprint than pulling in the full `rpaframework` "RPA.Desktop" stack (which bundles many unrelated modules — browser, Excel, PDF, email, cloud — this project needs none of). Revisit if it proves unmaintained/incompatible during implementation; `rpaframework`'s `RPA.Desktop` is the documented fallback. |
| OCR text assertions | `pytesseract` + system Tesseract | Small, standard, widely used; the app's monospace status bar/text view are OCR-friendly. |
| Clipboard read-back (for "Copy JSON Path") | `pyperclip` (Linux needs `xclip` or `xsel` installed) | Minimal, single-purpose. |
| Screenshot-on-failure evidence | Robot's built-in `Screenshot` library + `mss` | Ships with core RF; `mss` is the lightest supported backend. |
| Window management glue (Linux) | `xdotool` (already present on this dev machine) | Fallback only, if ImageHorizonLibrary's own window handling proves insufficient for focusing/positioning the app window before each test. |

See [requirements.txt](../requirements.txt) for the pinned Python side of this.
**Python-version risk, confirmed**: this dev machine's default `python3` is 3.14.4;
`robotframework-imagehorizonlibrary`'s PyPI metadata doesn't advertise 3.14
compatibility. `run.sh` builds the venv against **pyenv's Python 3.12.3**
(`~/.pyenv/versions/3.12.3`) rather than fighting the system interpreter — with
that, every package in `requirements.txt` installs cleanly, including building
`pyautogui`'s handful of source-only transitive deps (`pyscreeze`, `pygetwindow`,
`python3-Xlib`, etc.) from sdists, which is normal and not a problem. Also note:
PyPI's latest `robotframework-imagehorizonlibrary` is `1.0` (last released 2019,
not the `>=1.9` originally guessed in the requirements pass) — pinned exactly in
`requirements.txt`; it works fine on 3.12 despite its age.

## Screen capture: the real desktop doesn't work either — CONFIRMED, use Xvfb

**Update from implementation**: this dev machine's real session is GNOME on
Wayland. Every X11-based screenshot method (`mss`, Pillow's `ImageGrab.grab()`,
`gnome-screenshot`'s own X11 fallback) returns an all-black image when pointed at
the real display (`DISPLAY=:0`) — confirmed both for the whole screen and
specifically for `jsonquery_gui`'s own window, including after forcing the app
itself to run via Xwayland (`WAYLAND_DISPLAY` unset). This is expected, not a bug:
Wayland compositors don't mirror their composited output onto the X11 root window
the way a real X server does, so legacy `XGetImage`-based capture sees nothing.
GNOME's actual Wayland-native capture path (`org.gnome.Shell.Screenshot` D-Bus
API, and the newer `org.freedesktop.portal.Screenshot`) both require **interactive,
per-call human approval** — direct D-Bus calls to `org.gnome.Shell.Screenshot` were
tried and rejected outright (`AccessDenied: Screenshot is not allowed`), and the
portal path pops a one-time permission dialog with no unattended bypass. Neither is
usable for unattended test runs.

**Fix: run the whole suite against an isolated Xvfb virtual display, not the real
session.** This sidesteps the Wayland problem entirely — Xvfb is a real, plain X
server, so `mss`/`pyautogui`/image-matching/OCR all work against it normally
(confirmed: a screenshot of the app running under Xvfb shows real, correct
content). This is also just the standard, CI-appropriate way to run GUI automation
on Linux regardless of the Wayland issue, so it's not a compromise specific to this
machine.

One more thing Xvfb needs that a real desktop provides for free: **a window
manager**. Bare Xvfb has no focus-follows-click policy and doesn't support
`_NET_ACTIVE_WINDOW` at all — clicking into a text field visually looks like it
focuses (egui draws its own focus ring) but the X server never gives the window
real input focus, so synthesized keystrokes silently go nowhere. Confirmed
concretely: typed text did not appear in a clicked-into text field under bare
Xvfb, and started appearing correctly once **`fluxbox`** (a minimal EWMH-capable
window manager) was run alongside it. `fluxbox` is now a required test-environment
package, launched once per suite run alongside Xvfb.

Startup sequence for every test run, in order: `Xvfb :99 -screen 0 <size>x24
-nolisten tcp` → `DISPLAY=:99 fluxbox` (backgrounded, give it ~1s) → launch
`jsonquery_gui` with `WAYLAND_DISPLAY` unset and `DISPLAY=:99` set. `run.sh`
and `resources/AppLibrary.py` implement exactly this.

## Environment prerequisites (Linux, primary target — this repo's dev/CI platform)

System packages (Debian/Ubuntu names; adjust for other distros) — all confirmed
installed and working during implementation:

```
sudo apt install tesseract-ocr wmctrl xclip xvfb fluxbox gnome-screenshot xdotool
```

(`gnome-screenshot` is needed transitively — `pyscreeze`, underneath
`ImageHorizonLibrary`, shells out to it as part of its Linux capture path even
though the actual pixel data ends up coming from Xvfb correctly once it's
installed; without it, `pyscreeze`/`pyautogui` raise an exception immediately
instead of attempting a capture at all.)

`xdotool` finds, sizes and focuses the app's windows; the AT-SPI stack of the earlier
investigation is not needed. The [README](../README.md#requirements) lists everything
a fresh machine or container needs, and how to point the suite at the app.

The app also builds on Windows and macOS (its own CI does) but there is no Windows or
macOS test environment available to validate against right now. **This requirements
pass targets Linux only.** A Windows port of this
suite would swap the native-dialog and window-management layer (e.g.
`pywinauto`/UI Automation, which can likely see real widget names there since
`accesskit_windows` targets UIA directly and Windows' automation stack is more
consistently populated than Linux AT-SPI in practice) but is out of scope until
there's a Windows box to develop and run it on.

## Directory layout (this pass)

```
jsonquery_test/
  README.md                      — entry point: status, how these docs relate, what's next
  requirements.txt                — pinned Python test dependencies
  docs/
    00_test_strategy.md           — this file
    01_launch_and_window.md
    02_opening_sources.md
    03_toolbar_and_status_bar.md
    04_query_bar_and_engines.md
    05_tree_view.md
    06_text_view.md
    07_context_menus.md
    08_search_and_find_in_source.md
    09_saving.md
    10_keyboard_shortcuts.md
    11_error_and_edge_cases.md
    99_traceability_matrix.md
```

Implementation (later) will add `suites/<area>/*.robot`, `resources/`
(shared keywords, image templates), and `run.sh` — mirroring this same
per-area breakdown 1:1, so each doc above maps directly onto one suite directory.
Each feature doc below lists concrete test-case IDs in the form `TC-<AREA>-NNN`;
the traceability matrix ([99_traceability_matrix.md](99_traceability_matrix.md))
is the single index of all of them and will track implementation status.

## Second implementation pass — confirmed findings

The first pass covered `launch_and_window`, `opening_sources`,
`query_engines`, and `context_menus` (14 tests). The second pass added
`toolbar_and_status`, `tree_view`, `text_view`, `search`,
`keyboard_shortcuts`, and `saving`, plus extending the four original suites
to 74 tests total. Getting all 74 green surfaced several confirmed findings
worth knowing before touching this suite again — most of the debugging time
in this pass went into these, not into writing the tests themselves.

**A too-tightly-cropped region can make Tesseract fail outright, not just
read poorly.** The search-results panel's header was originally cropped to
exactly its own 26px line height. Every PSM mode tried against that exact
crop returned pure noise (`'wMWEeoiLil Pl oUllo ~~ VSYVUILO...'` — nothing
resembling the real "Search results — Source..." text at all). Adding
~15px of vertical margin around the same content fixed it completely, at
every PSM mode tried. Lesson: give OCR regions real margin around the text
line, not an exact bounding box.

**Some panels size themselves to their content, not a fixed height —
confirmed for the search-results panel specifically.** A panel showing one
hit line renders its header at a visibly different y-position (~609) than a
bare "No matches found." panel (~739), even though both are the "same"
panel opened the same way. Any fixed-y-coordinate calibration for it was
consequently only ever valid for one specific content size. Fixed with one
wide `@{SEARCH_RESULTS_AREA}` region (OCR'd as a whole, regardless of where
within it the content actually landed) plus `Click Text In Region`-based
lookups for its "Close" button and hit lines, instead of fixed coordinates.
Don't assume other panels are laid out at a fixed position either without
checking — this one wasn't.

**`ui.weak()`-styled text is unreliable for OCR, and this generalizes beyond
the first pass's placeholder-hint finding.** Confirmed again for the
search-results match count ("N match(es)") and "No matches found." — both
low-contrast, both came back garbled even inside a well-sized region that
read everything else on the same screen perfectly. Treat any `ui.weak()`
text as "not OCR-assertable" by default; check adjacent normal-contrast
content instead (a hit line's own text, the heading text next to a weak
count) rather than trying harder on the weak text itself.

**Pasting only works from the empty state.** `Ctrl+V` only loads anything
while the "Paste JSON here…" box is showing (`app.rs`'s `paste_area`, only
rendered when `self.doc.is_none()`). Once a document is loaded, there is no
widget left to paste into, and no global paste-to-replace shortcut — Ctrl+V
silently does nothing. Any test needing to load a *second* document over an
already-loaded one (TC-OPEN-015, TC-TOOL-004) must use `Load Via Url`
instead (a plain toolbar button, unconditionally available), not a second
paste. This one cost real debugging time: the symptom was the tree quietly
still showing the *first* document with no error of any kind, easy to
misread as an unrelated flake.

**A click immediately after typing into a field can land on a still-disabled
button.** The Search dialog's "Find"/"Find All" and the toolbar's "Load"
are both disabled while their field is blank, and re-enable on the next
frame after typing finishes. Clicking immediately after `pyautogui.typewrite`
returns leaves essentially no gap for that frame to render, so the click can
land on a button that's still rendered disabled from the previous frame and
do nothing. Fixed by retry-and-verify wrapping (`Search For` and `Open Row
Context Menu` follow this pattern: act, then check the
expected effect actually happened, retrying the whole action — not just
waiting longer — if it didn't) rather than a longer fixed sleep, since the
window that matters is one repaint frame, not a fixed duration. `Load Via Url`
sidesteps the race a different way: it submits the toolbar's source field with
Enter, which needs nothing but the focused field, and `TC-OPEN-018` covers the
Load button itself.

**Two more specific OCR digit/letter confusions, beyond the already-known
weak-text limitation**: Tesseract sometimes reads the 2-character "jq"
label as "iq", and a leading digit `0` (as in "0 result(s)", "0 B", "0
items") sometimes reads as the letter "O" — or, in one case (a `0`
immediately followed by other small glyphs), something worse than either.
`AppLibrary._text_contains` now has a permissive 0/O fallback for the
general case; assertions that hit the "jq"/"iq" confusion or the
digit-immediately-adjacent-to-other-glyphs case are worded to avoid the
specific fragile substring instead (e.g. confirming an engine is jq by
ruling out the other three names, rather than asserting "jq" itself).

**A custom Robot Framework keyword needs its own `msg=` parameter to accept
Robot's usual `msg=...` failure-message convention.** `Region Should
(Not) Contain Text` didn't originally declare one, so a call like
`Region Should Not Contain Text ...    msg=explanation` silently mis-parsed:
Robot treated the unrecognized `msg=...` as a positional argument for the
keyword's next parameter (`psm`), which then failed with an unrelated
`ValueError` trying to `int()` the message string. Both keywords now accept
`msg=None` explicitly, matching `Colors Should (Not) Match`'s existing
signature.

## Redesign pass (2026-10-04) — what changed in how the suite is run and read

The Tools window was redesigned (tabs, command row, two panes, status bar), Diff
became a side-by-side view, the panes' headers lost their line and got smaller
titles, the Source pane's window gained a source field, and the Tools window, the
tutorial and About became windows eframe redraws by itself. The suite was
recalibrated and extended for all of it (about 130 cases on the Tools window alone,
plus `satellites/`, `pane_headers/` and `drag_and_drop/`). What is new in the
technique, beyond the earlier passes:

- **Real drag and drop.** `Drop Files On Window` (AppLibrary) drives
  `resources/xdnd.py`, an XDND source written with python-xlib: it owns the
  selection, offers the file list as `text/uri-list`, and goes through
  Enter / Position / Status / Drop / Finished with the target window. winit takes it
  for a file manager's drag. This reaches what `xdotool` could not — the Merge page
  (a list of files), the main window's "drop a file anywhere", dropping into the
  boxes of the Tools pages — see [16_drag_and_drop.md](16_drag_and_drop.md).
- **Exact checks through the clipboard.** A result's Copy button is pressed and the
  clipboard compared whole (`Copy Should Give`), after setting it to a marker so a
  button that does nothing fails. This replaced OCR for anything longer than a word:
  every Format layout (tabs and `\u` escapes included), the patch of a comparison, the
  patched document, the validation report. `Query Text Should Be` does the same for
  the query box, whose tinted text OCR reads as `.-hame` for `.name`.
- **Pixels for state and look.** `Get Ink Bounds` (how tall is this text, is this
  button's label dim or bright), `Region Should Be Plain` (nothing drawn here: no
  line under a header), `Get Rows With Color` (which rows are marked), plus the
  existing `Region Should (Not) Contain Color`. A disabled button's label is ~112
  grey and an enabled one's ~180–240, so "is it dim?" is a pixel probe, not an OCR
  guess. See [15_pane_headers.md](15_pane_headers.md).
- **Switching windows raises them.** `Switch To Window`, `Switch To Main Window`
  and `Close Window` raise the window with `wmctrl -a` (EWMH). `xdotool
  windowraise` is not enough under a reparenting window manager (it reorders the
  client inside its frame). It matters because the screen is what is read and
  clicked: the tutorial opens over the main window, and a window another covers
  completely is not even redrawn (eframe runs no UI pass for a window X11 reports as
  fully obscured), nor does it notice a close request — see
  [14_tutorial_and_about_windows.md](14_tutorial_and_about_windows.md).
- **Parallel lanes.** `JQ_TEST_DISPLAY`, `JQ_TEST_RESULTS`, `JQ_TEST_BINARY` and
  `JQ_TEST_NO_BUILD` (read by `run.sh` and AppLibrary; unset, nothing changes) let
  several runs go at once, each on its own Xvfb display with its own results and a
  frozen copy of the binary that a rebuild does not replace. A full run is ~370 cases
  and over an hour on one display; N lanes take about 1/N of that (the last full run
  used five).
  `JQ_TEST_APP_LOG=<file>` sends the app's stderr (a debug build's tracing) to a
  file, and `List Windows` logs every window with its class and pid — the teardown
  also warns about a window titled "egui window" (eframe's name for a window nobody
  titled), which should never be there.
- **Mutation checks.** Each new area was checked by running its cases against a build
  with the behaviour broken (a source mutant, or the build of the commit before the
  change) and confirming that they fail, and at the intended assertion. The results are
  listed per area in the feature docs.
- **Calibrate from screenshots, not from layout arithmetic.** The first version of the
  Tools suite used coordinates worked out from the layout's sizes; about half were
  wrong. A throwaway suite that takes `Screenshot Window` of every page in each state
  and a few lines of PIL to measure the pixels gave every constant in
  `resources/tools.resource` in an hour.
- **A suite finds real bugs.** The first run of the redesigned pages found that
  Diff's Compare did nothing (a `?` on the way out of a function dropped the request
  made earlier in it) — see [13_tools_window.md](13_tools_window.md).

## Test-case fields, used consistently in every feature doc

- **Preconditions** — required app/document state before the steps run.
- **Steps** — user-observable actions only (click, type, wait) — no internal state
  manipulation.
- **Expected** — observable pass criteria.
- **Automation notes** — the specific locator/assertion technique (image template,
  OCR region + expected pattern, clipboard read, etc.) and any known fragility.
- **Priority** — P1 (core correctness, must pass before any release), P2 (important
  but not release-blocking on its own), P3 (nice-to-have edge case coverage).
