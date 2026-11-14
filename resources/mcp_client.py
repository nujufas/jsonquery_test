"""Robot Framework library: an assistant of the app's MCP server, for the cases of suites/mcp/.

The app's MCP server listens on 127.0.0.1 once the
🔌 panel's Start is clicked, and keeps its port and token in `mcp.json`, in the folder of the
launch's settings (`App Home`). The keywords here read that file and talk to the server as an
assistant does, over Streamable HTTP (JSON-RPC 2.0, the `initialize` handshake, then
`tools/call`), or through `jsonquery-mcp`, the stdio bridge beside the app's binary, as Claude
Desktop and llama-server do. The window is still read by the usual keywords (AppLibrary.py):
what these give is what the assistant was told.

Nothing here starts the app or clicks anything; nothing here reaches beyond 127.0.0.1.
"""

import atexit
import http.client
import json
import os
import secrets
import shutil
import socket
import subprocess
import sys
import threading
import time

from robot.api import logger
from robot.api.deco import keyword, library
from robot.libraries.BuiltIn import BuiltIn

PROTOCOL_VERSION = "2025-11-25"
SERVER_PATH = "/mcp"
BRIDGE_NAME = "jsonquery-mcp"


def _app():
    return BuiltIn().get_library_instance("AppLibrary")


# The fill of a button of the question (the dark theme's), and the names of its three, in
# their order.
QUESTION_BUTTON_FILL = (60, 60, 60)
QUESTION_BUTTONS = ("Allow", "Always allow", "Don't allow")


def _question_buttons(image):
    """Where the question's buttons are in `image` (the main window): the first row, from the
    top, that crosses three runs of the buttons' fill, the second the widest; or None."""
    rgb = image.convert("RGB")
    pixels = rgb.load()
    width, height = rgb.size

    def runs(y):
        found, start = [], None
        for x in range(width):
            near = all(abs(pixels[x, y][i] - QUESTION_BUTTON_FILL[i]) <= 4 for i in range(3))
            if near and start is None:
                start = x
            elif not near and start is not None:
                if x - start >= 25:
                    found.append((start, x - 1))
                start = None
        return found

    for y in range(height // 4, height * 3 // 4):
        row = runs(y)
        if len(row) != 3:
            continue
        widths = [b - a for a, b in row]
        if not (widths[1] > widths[0] and widths[1] > widths[2]):
            continue
        # The row must hold for a few pixels: a button, not a line.
        if [len(runs(y + d)) for d in (1, 2, 3)] != [3, 3, 3]:
            continue
        top = y
        bottom = y
        # Down the first button's left edge, which no label reaches, to its bottom (from a
        # row below its rounded corner).
        edge = runs(y + 2)[0][0] + 2
        while bottom + 1 < height and all(
            abs(pixels[edge, bottom + 1][i] - QUESTION_BUTTON_FILL[i]) <= 4 for i in range(3)
        ):
            bottom += 1
        middle = (top + bottom) // 2
        centers = {name: [(a + b) // 2, middle] for name, (a, b) in zip(QUESTION_BUTTONS, row)}
        left = max(0, row[0][0] - 20)
        centers["box"] = [left, max(0, top - 110), 440, 110]
        return centers
    return None


def _as_object(arguments):
    """A tool's arguments as a dictionary: from a dictionary of Robot's, or from JSON text."""
    if arguments is None or arguments == "":
        return {}
    if isinstance(arguments, str):
        value = json.loads(arguments)
        if not isinstance(value, dict):
            raise AssertionError(f"The arguments must be a JSON object, not {arguments!r}")
        return value
    return {str(k): v for k, v in dict(arguments).items()}


class _Call:
    """A tool call made on a thread of its own (`Start Mcp Call`), for a case that does
    something in the window while the call is out."""

    def __init__(self, target, args):
        self.result = None
        self.error = None
        self.thread = threading.Thread(target=self._run, args=(target, args), daemon=True)
        self.thread.start()

    def _run(self, target, args):
        try:
            self.result = target(*args)
        except Exception as e:  # handed to the case by `Wait For Mcp Call`
            self.error = e


@library(scope="GLOBAL")
class mcp_client:
    def __init__(self):
        self._next_id = 0
        self._alone = []
        atexit.register(self.remove_lonely_builds)

    # -- the settings file ----------------------------------------------------

    def _settings_path(self):
        home = _app().app_home()
        if not home:
            raise AssertionError("No app has been launched: there is no mcp.json")
        return os.path.join(home, "mcp.json")

    @keyword("Mcp Settings")
    def mcp_settings(self):
        """What the running app keeps in `mcp.json` (port, token, access, start_with_app), as a
        dictionary; fails if there is no such file or it is not a JSON object."""
        path = self._settings_path()
        try:
            with open(path, encoding="utf-8") as f:
                value = json.load(f)
        except OSError as e:
            raise AssertionError(f"mcp.json could not be read: {e}") from None
        if not isinstance(value, dict):
            raise AssertionError(f"mcp.json is not an object: {value!r}")
        return value

    @keyword("Mcp Settings File Exists")
    def mcp_settings_file_exists(self):
        return os.path.isfile(self._settings_path())

    @keyword("Mcp Settings File Mode")
    def mcp_settings_file_mode(self):
        """The permission bits of `mcp.json`, as an octal string (`600`)."""
        return format(os.stat(self._settings_path()).st_mode & 0o777, "o")

    @keyword("Wait Until Mcp Setting Is")
    def wait_until_mcp_setting_is(self, key, expected, timeout=5):
        """Waits for `mcp.json` to have `expected` at `key` (the app writes the file a moment
        after the change). A number or a boolean is compared as one; `None` is no such key."""
        deadline = time.time() + float(timeout)
        seen = "no file"
        while True:
            try:
                kept = self.mcp_settings()
                seen = kept.get(key)
                if _same(seen, expected):
                    return seen
            except AssertionError as e:
                seen = str(e)
            if time.time() > deadline:
                raise AssertionError(f"mcp.json has {key} = {seen!r}, not {expected!r}")
            time.sleep(0.2)

    @keyword("Free Port")
    def free_port(self):
        """A TCP port on 127.0.0.1 that nothing listens on now."""
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(("127.0.0.1", 0))
            # As text: it is typed, and looked for in what OCR reads.
            return str(s.getsockname()[1])

    @keyword("New Mcp Token")
    def new_mcp_token(self):
        """A token of the form the app makes: 64 hex digits."""
        return secrets.token_hex(32)

    @keyword("Mcp Json")
    def mcp_json(
        self,
        port=None,
        token=None,
        access=None,
        start_with_app=None,
        always_allow=None,
        answer_kb=None,
    ):
        """The text of an `mcp.json` with these values (what is not given is left out, and the
        app takes its default), to start an app with: `home_files` of `Launch Jsonquery App`."""
        kept = {}
        if port is not None:
            kept["port"] = int(port)
        if token is not None:
            kept["token"] = str(token)
        if access is not None:
            kept["access"] = str(access)
        if start_with_app is not None:
            kept["start_with_app"] = _truthy(start_with_app)
        if always_allow is not None:
            kept["always_allow"] = _truthy(always_allow)
        if answer_kb is not None:
            kept["answer_kb"] = int(answer_kb)
        return json.dumps(kept)

    @keyword("Question Buttons")
    def question_buttons(self):
        """The question an assistant waits on, over the main window: the centers of its three
        buttons, `Allow`, `Always allow` and `Don't allow` (app-relative), and `box`, the
        region of the question above them (x, y, width, height). Its buttons are found by
        their fill, as OCR does not read their small labels on the dimmed window, and the
        question is as tall as what it asks. Fails when no question is shown."""
        found = _question_buttons(_app().screenshot_window(log=False))
        if found is None:
            raise AssertionError("No question is shown over the main window")
        return found

    @keyword("No Question Should Be Shown")
    def no_question_should_be_shown(self, settle=0.5):
        """No question is over the main window, `settle` seconds from now."""
        time.sleep(float(settle))
        found = _question_buttons(_app().screenshot_window(log=False))
        if found is not None:
            raise AssertionError(f"A question is shown, its buttons at {found}")

    @keyword("Hold Port")
    def hold_port(self, port):
        """Listens on 127.0.0.1:`port` (as another program would) until `Release Port`; for
        the case of a port that is taken. Returns the port."""
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind(("127.0.0.1", int(port)))
        s.listen(1)
        self._held = getattr(self, "_held", [])
        self._held.append(s)
        return int(port)

    @keyword("Release Ports")
    def release_ports(self):
        for s in getattr(self, "_held", []):
            s.close()
        self._held = []

    # -- HTTP -----------------------------------------------------------------

    def _target(self, port, token):
        kept = None
        if port is None or token is None:
            kept = self.mcp_settings()
        return (
            int(port if port is not None else kept["port"]),
            str(token if token is not None else kept["token"]),
        )

    @keyword("Mcp Post")
    def mcp_post(self, body, port=None, token=None, headers=None, timeout=30, send_token=True):
        """POSTs `body` (a dictionary, a list, or JSON text as it is) to the server, as an
        assistant does, with the token of `mcp.json` (or `token`; with `send_token` false, no
        Authorization at all). Returns a dictionary: `status`, `body` (the text), `json` (it
        parsed, or None) and `headers`. Fails only when nothing answers."""
        port, token = self._target(port, token)
        text = body if isinstance(body, str) else json.dumps(_plain(body))
        sent = {
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
            "MCP-Protocol-Version": PROTOCOL_VERSION,
        }
        if _truthy(send_token):
            sent["Authorization"] = f"Bearer {token}"
        for name, value in dict(headers or {}).items():
            if value is None or value == "NONE":
                sent.pop(name, None)
            else:
                sent[name] = str(value)
        connection = http.client.HTTPConnection("127.0.0.1", port, timeout=float(timeout))
        try:
            connection.request("POST", SERVER_PATH, body=text.encode("utf-8"), headers=sent)
            response = connection.getresponse()
            raw = response.read().decode("utf-8", errors="replace")
            answer = {
                "status": response.status,
                "body": raw,
                "headers": {k.lower(): v for k, v in response.getheaders()},
            }
        except OSError as e:
            raise AssertionError(f"Nothing answered on 127.0.0.1:{port}: {e}") from None
        finally:
            connection.close()
        try:
            answer["json"] = json.loads(raw) if raw else None
        except ValueError:
            answer["json"] = None
        return answer

    @keyword("Mcp Server Should Not Answer")
    def mcp_server_should_not_answer(self, port=None):
        """Fails if anything accepts a connection on the port (of `mcp.json`, or `port`)."""
        if port is None:
            port = self.mcp_settings()["port"]
        try:
            with socket.create_connection(("127.0.0.1", int(port)), timeout=1):
                pass
        except OSError:
            return
        raise AssertionError(f"Something listens on 127.0.0.1:{port}")

    @keyword("Wait Until Mcp Server Answers")
    def wait_until_mcp_server_answers(self, timeout=5, port=None):
        """Waits until the server takes a connection on the port of `mcp.json` (or `port`)."""
        deadline = time.time() + float(timeout)
        last = None
        while True:
            try:
                p = int(port) if port is not None else int(self.mcp_settings()["port"])
                with socket.create_connection(("127.0.0.1", p), timeout=1):
                    return p
            except (OSError, AssertionError, KeyError, ValueError) as e:
                last = e
            if time.time() > deadline:
                raise AssertionError(f"The MCP server did not answer: {last}")
            time.sleep(0.2)

    def _request(self, method, params=None, port=None, token=None, timeout=30):
        self._next_id += 1
        body = {"jsonrpc": "2.0", "id": self._next_id, "method": method}
        if params is not None:
            body["params"] = params
        answer = self.mcp_post(body, port=port, token=token, timeout=timeout)
        if answer["status"] != 200 or not isinstance(answer["json"], dict):
            raise AssertionError(
                f"{method}: HTTP {answer['status']}, {answer['body'][:400]!r}"
            )
        return answer["json"]

    @keyword("Mcp Initialize")
    def mcp_initialize(self, client="Robot assistant", version="1.0", port=None, token=None):
        """The handshake, as an assistant called `client` (the panel names it); returns its
        result (protocolVersion, serverInfo, capabilities, instructions)."""
        reply = self._request(
            "initialize",
            {
                "protocolVersion": PROTOCOL_VERSION,
                "capabilities": {},
                "clientInfo": {"name": str(client), "version": str(version)},
            },
            port=port,
            token=token,
        )
        if "error" in reply:
            raise AssertionError(f"initialize: {reply['error']}")
        self.mcp_post(
            {"jsonrpc": "2.0", "method": "notifications/initialized"}, port=port, token=token
        )
        return reply["result"]

    @keyword("Mcp Tool Names")
    def mcp_tool_names(self, port=None, token=None):
        """The names of the tools the server lists (tools/list), in its order."""
        reply = self._request("tools/list", {}, port=port, token=token)
        if "error" in reply:
            raise AssertionError(f"tools/list: {reply['error']}")
        return [tool["name"] for tool in reply["result"]["tools"]]

    @keyword("Mcp Characters Before A Question")
    def mcp_characters_before_a_question(self, port=None, token=None):
        """What an assistant is given by the server before anything is asked of it, in characters:
        the instructions of the handshake and the list of the tools (as the JSON it comes in). It
        takes that much room in a model's context before the first question."""
        result = self.mcp_initialize(port=port, token=token)
        reply = self._request("tools/list", {}, port=port, token=token)
        if "error" in reply:
            raise AssertionError(f"tools/list: {reply['error']}")
        tools = json.dumps(reply["result"]["tools"], ensure_ascii=False)
        return len(result.get("instructions", "")) + len(tools)

    @keyword("Call Mcp Tool")
    def call_mcp_tool(self, name, arguments=None, port=None, token=None, timeout=60):
        """Calls the tool `name` with `arguments` (a dictionary, or JSON text). Returns a
        dictionary: `error` (the result's isError), `text` (what the assistant reads), and
        `value` (that text as JSON, or None when it is not JSON). A JSON-RPC error (an unknown
        tool, wrong arguments) fails the keyword with it."""
        reply = self._request(
            "tools/call",
            {"name": str(name), "arguments": _as_object(arguments)},
            port=port,
            token=token,
            timeout=timeout,
        )
        if "error" in reply:
            raise AssertionError(f"{name}: JSON-RPC error {reply['error']}")
        result = reply["result"]
        text = "".join(
            part.get("text", "") for part in result.get("content", []) if part.get("type") == "text"
        )
        try:
            value = json.loads(text)
        except ValueError:
            value = None
        outcome = {"error": bool(result.get("isError")), "text": text, "value": value}
        logger.info(f"{name} -> {'ERROR ' if outcome['error'] else ''}{text[:600]}")
        return outcome

    @keyword("Mcp Tool Should Succeed")
    def mcp_tool_should_succeed(self, name, arguments=None, timeout=60):
        """Calls the tool and fails with what it said if it said it failed; returns its value
        (the text as JSON, or the text when it is not JSON)."""
        outcome = self.call_mcp_tool(name, arguments, timeout=timeout)
        if outcome["error"]:
            raise AssertionError(f"{name} failed: {outcome['text']}")
        return outcome["value"] if outcome["value"] is not None else outcome["text"]

    @keyword("Mcp Tool Should Fail")
    def mcp_tool_should_fail(self, name, arguments=None, expected="", timeout=60):
        """Calls the tool and fails unless it says it failed, with `expected` in what it says.
        Returns that text."""
        outcome = self.call_mcp_tool(name, arguments, timeout=timeout)
        if not outcome["error"]:
            raise AssertionError(f"{name} did not fail: {outcome['text'][:400]}")
        if expected and str(expected) not in outcome["text"]:
            raise AssertionError(f"{name} failed with {outcome['text']!r}, not with {expected!r}")
        return outcome["text"]

    @keyword("Start Mcp Call")
    def start_mcp_call(self, name, arguments=None, timeout=120):
        """Calls the tool on a thread of its own and returns at once; `Wait For Mcp Call` gives
        what `Call Mcp Tool` would have. The port and token are read now."""
        port, token = self._target(None, None)
        return _Call(self.call_mcp_tool, (name, arguments, port, token, timeout))

    @keyword("Wait For Mcp Call")
    def wait_for_mcp_call(self, call, timeout=60):
        call.thread.join(float(timeout))
        if call.thread.is_alive():
            raise AssertionError(f"The call has not come back in {timeout} s")
        if call.error is not None:
            raise call.error
        return call.result

    @keyword("Mcp Build Without Bridge")
    def mcp_build_without_bridge(self):
        """The path of the app's binary in a folder that has no `jsonquery-mcp` beside it (a hard
        link, next to the build's own folder; a copy where no link can be made), for the case of an
        app without the bridge (built alone, or the Microsoft Store's). Removed when the run ends."""
        library_module = sys.modules[type(_app()).__module__]
        source = library_module.BINARY_PATH
        folder = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(source))), f"mcp-alone-{os.getpid()}"
        )
        os.makedirs(folder, exist_ok=True)
        target = os.path.join(folder, os.path.basename(source))
        if not os.path.exists(target):
            try:
                os.link(source, target)
            except OSError:
                shutil.copy2(source, target)
        if folder not in self._alone:
            self._alone.append(folder)
        if os.path.exists(os.path.join(folder, BRIDGE_NAME)):
            raise AssertionError(f"{folder} has a {BRIDGE_NAME}")
        return target

    @keyword("Remove Lonely Builds")
    def remove_lonely_builds(self):
        for folder in self._alone:
            shutil.rmtree(folder, ignore_errors=True)
        self._alone = []

    # -- the window, as the window manager has it ---------------------------------

    def _x(self, *command):
        app = _app()
        module = sys.modules[type(app).__module__]
        env = {**os.environ, "DISPLAY": module.XVFB_DISPLAY}
        return subprocess.run(list(command), capture_output=True, text=True, env=env)

    @keyword("Minimize Main Window")
    def minimize_main_window(self):
        """Iconifies the app's main window, as its title bar's button would (the suite's
        windows have none): it is not drawn and gets no frames until it is restored."""
        wid = _app()._main_window_id
        self._x("xdotool", "windowminimize", "--sync", wid)
        deadline = time.time() + 5
        while self.main_window_is_viewable():
            if time.time() > deadline:
                raise AssertionError("The main window did not go")
            time.sleep(0.2)

    @keyword("Restore Main Window")
    def restore_main_window(self):
        wid = _app()._main_window_id
        self._x("wmctrl", "-i", "-a", wid)
        deadline = time.time() + 5
        while not self.main_window_is_viewable():
            if time.time() > deadline:
                raise AssertionError("The main window did not come back")
            time.sleep(0.2)
        self._x("xdotool", "windowfocus", "--sync", wid)
        time.sleep(0.6)

    @keyword("Main Window Is Viewable")
    def main_window_is_viewable(self):
        out = self._x("xwininfo", "-id", _app()._main_window_id).stdout
        return "IsViewable" in out

    # -- the stdio bridge -------------------------------------------------------

    @keyword("Bridge Path")
    def bridge_path(self, binary=None):
        """`jsonquery-mcp`, beside the app's binary (the one under test, or `binary`)."""
        # The module of the library the suites load (AppLibrary.py), for where the binary is.
        library_module = sys.modules[type(_app()).__module__]
        app_binary = binary or library_module.BINARY_PATH
        # As the app names it: its own path with the links resolved (std::env::current_exe).
        return os.path.realpath(os.path.join(os.path.dirname(app_binary), BRIDGE_NAME))

    @keyword("Bridge Exchange")
    def bridge_exchange(self, *messages, home=None, timeout=30, environment=None):
        """Starts `jsonquery-mcp` as an assistant does (no arguments, the app's settings folder
        in JSONQUERY_HOME: the running app's, or `home`), writes each message (a dictionary,
        or JSON text) as a line, and reads one line back for each that has an id. Returns the
        replies, parsed, in the order they came; the bridge's stderr is logged."""
        lines = []
        expected = 0
        for message in messages:
            value = json.loads(message) if isinstance(message, str) else _plain(message)
            if isinstance(value, dict) and "id" in value:
                expected += 1
            lines.append(json.dumps(value))
        env = {
            "PATH": "/usr/bin:/bin",
            "HOME": os.environ.get("HOME", "/tmp"),
            "JSONQUERY_HOME": home or _app().app_home() or "",
        }
        env.update({str(k): str(v) for k, v in dict(environment or {}).items()})
        process = subprocess.Popen(
            [self.bridge_path()],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            text=True,
        )
        replies = []
        try:
            for line in lines:
                process.stdin.write(line + "\n")
                process.stdin.flush()
            deadline = time.time() + float(timeout)
            reader = _LineReader(process.stdout)
            while len(replies) < expected:
                left = deadline - time.time()
                if left <= 0:
                    raise AssertionError(
                        f"The bridge gave {len(replies)} of {expected} replies in {timeout} s"
                    )
                line = reader.next_line(left)
                if line is None:
                    break
                if line.strip():
                    replies.append(json.loads(line))
        finally:
            try:
                process.stdin.close()
            except OSError:
                pass
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            err = process.stderr.read()
            if err.strip():
                logger.info(f"jsonquery-mcp said: {err.strip()[:2000]}")
        if len(replies) < expected:
            raise AssertionError(f"The bridge ended after {len(replies)} of {expected} replies")
        return replies

    @keyword("Bridge Tool Call")
    def bridge_tool_call(self, name, arguments=None, home=None, timeout=60):
        """The handshake and one tools/call through `jsonquery-mcp`; returns what `Call Mcp
        Tool` would (error, text, value)."""
        replies = self.bridge_exchange(
            _initialize_message(1, "Robot over stdio"),
            {"jsonrpc": "2.0", "method": "notifications/initialized"},
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {"name": str(name), "arguments": _as_object(arguments)},
            },
            home=home,
            timeout=timeout,
        )
        reply = next(r for r in replies if r.get("id") == 2)
        if "error" in reply:
            raise AssertionError(f"{name}: JSON-RPC error {reply['error']}")
        result = reply["result"]
        text = "".join(p.get("text", "") for p in result.get("content", []))
        try:
            value = json.loads(text)
        except ValueError:
            value = None
        return {"error": bool(result.get("isError")), "text": text, "value": value}

    @keyword("Bridge Initialize Message")
    def bridge_initialize_message(self, id=1, client="Robot over stdio"):
        return _initialize_message(int(id), client)


class _LineReader:
    """Lines of a pipe, with a deadline (a thread reads; the case waits)."""

    def __init__(self, stream):
        self._lines = []
        self._done = False
        self._cond = threading.Condition()
        threading.Thread(target=self._pump, args=(stream,), daemon=True).start()

    def _pump(self, stream):
        for line in stream:
            with self._cond:
                self._lines.append(line)
                self._cond.notify_all()
        with self._cond:
            self._done = True
            self._cond.notify_all()

    def next_line(self, timeout):
        with self._cond:
            end = time.time() + timeout
            while not self._lines and not self._done:
                left = end - time.time()
                if left <= 0:
                    return None
                self._cond.wait(left)
            return self._lines.pop(0) if self._lines else None


def _initialize_message(id, client):
    return {
        "jsonrpc": "2.0",
        "id": id,
        "method": "initialize",
        "params": {
            "protocolVersion": PROTOCOL_VERSION,
            "capabilities": {},
            "clientInfo": {"name": client, "version": "1.0"},
        },
    }


def _plain(value):
    """Robot's DotDicts and lists, as plain JSON values."""
    if isinstance(value, dict):
        return {str(k): _plain(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_plain(v) for v in value]
    return value


def _truthy(value):
    if isinstance(value, str):
        return value.strip().lower() in ("true", "yes", "1", "on")
    return bool(value)


def _same(seen, expected):
    if isinstance(expected, str):
        lowered = expected.strip().lower()
        if lowered == "none":
            return seen is None
        if isinstance(seen, bool):
            return seen == (lowered in ("true", "yes", "1"))
        if isinstance(seen, int):
            try:
                return seen == int(expected)
            except ValueError:
                return False
        return seen == expected
    return seen == expected
