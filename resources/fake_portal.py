"""A stand-in for the desktop's file-chooser portal, so that the tests can use the
app's file dialogs: the `...` button beside the source field, and every Save...

Why it is needed: the app asks for a file name through `rfd`, which on Linux sends
`org.freedesktop.portal.FileChooser.OpenFile` or `.SaveFile` to
`org.freedesktop.portal.Desktop` on the session bus and blocks until a `Response`
signal comes back. On a real desktop the portal shows a dialog, and nothing in this
harness can drive that (see "Native OS dialogs" in docs/00_test_strategy.md). Without a
portal `rfd` falls back to running `zenity`, a window of its own that may not even be
installed.

So the harness runs a private session bus (`PrivateBus`) with a portal of its own on it
(`FakePortal`). A test says what the next dialog should return -- "save to this path",
"pick this file", "cancel" -- and afterwards reads what the app asked for: the title, the
suggested file name, the folder and the file filters. Everything on the app's side of the
dialog is real: the same D-Bus call, the same wait for the answer, the same file written.
Only the person at the dialog is simulated.

The app is started with `DBUS_SESSION_BUS_ADDRESS` pointing at this bus (AppLibrary), so
it can not reach the session bus of whoever runs the tests either; before, a Save... button
pressed from a test would have asked the real desktop's portal.
"""

import collections
import os
import select
import shutil
import subprocess
import tempfile
import threading
import time
import urllib.parse

from jeepney import DBusAddress, HeaderFields, MessageType
from jeepney import new_error, new_method_return, new_signal
from jeepney.bus_messages import message_bus
from jeepney.io.blocking import Proxy, open_dbus_connection

# A bus that can start nothing: no service directory, so a name that nobody owns is an
# error at once and not another program started on this bus (the accessibility bus, say).
_BUS_CONFIG = """<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <type>session</type>
  <listen>unix:path={socket}</listen>
  <auth>EXTERNAL</auth>
  <policy context="default">
    <allow send_destination="*" eavesdrop="true"/>
    <allow eavesdrop="true"/>
    <allow own="*"/>
  </policy>
</busconfig>
"""


class PrivateBus:
    """A session bus of its own (`dbus-daemon`), listening on a socket in a directory of
    its own. `address` is what `DBUS_SESSION_BUS_ADDRESS` takes."""

    def __init__(self):
        self.address = None
        self._dir = None
        self._proc = None

    def start(self):
        # A unix socket's path can be at most 107 bytes: with a long TMPDIR (a lane's directory
        # in a deep checkout) the bus goes in /tmp, where it takes a few hundred bytes.
        base = tempfile.gettempdir()
        if len(base) + len("/jq-bus-XXXXXXXX/bus") > 100:
            base = "/tmp"
        self._dir = tempfile.mkdtemp(prefix="jq-bus-", dir=base)
        socket = os.path.join(self._dir, "bus")
        config = os.path.join(self._dir, "bus.conf")
        with open(config, "w") as f:
            f.write(_BUS_CONFIG.format(socket=socket))
        self._proc = subprocess.Popen(
            ["dbus-daemon", f"--config-file={config}", "--nofork", "--print-address"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        # The daemon prints its address once it is listening; if the configuration is
        # wrong it exits without printing anything.
        ready, _, _ = select.select([self._proc.stdout], [], [], 10)
        line = self._proc.stdout.readline().strip() if ready else ""
        if not line:
            err = ""
            if self._proc.poll() is not None:
                err = self._proc.stderr.read()
            self.stop()
            raise RuntimeError(f"dbus-daemon did not start: {err.strip() or 'no address printed'}")
        self.address = line

    def stop(self):
        if self._proc is not None:
            self._proc.terminate()
            try:
                self._proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._proc.kill()
                self._proc.wait(timeout=5)
            self._proc = None
        if self._dir is not None:
            shutil.rmtree(self._dir, ignore_errors=True)
            self._dir = None
        self.address = None


class FakePortal:
    """Answers the file-chooser calls that arrive on `address` the way a portal does
    (the method returns the path of a Request object, then that object emits `Response`),
    from a thread of this process.

    Each dialog the app opens takes the next answer a test has queued
    (`answer`, `answer_suggested`, `cancel`); with none queued it is cancelled, which is
    what a person closing the dialog does, so a button pressed by accident is harmless.
    Every call is recorded in `requests`. The answer comes `ANSWER_DELAY` seconds after the
    portal has accepted the call, as a person's would."""

    NAME = "org.freedesktop.portal.Desktop"
    CHOOSER = "org.freedesktop.portal.FileChooser"
    REQUEST = "org.freedesktop.portal.Request"
    # How long a "person" takes to answer, in seconds. Not for show: rfd (the dialog library
    # of the app) sends the call, reads the portal's reply and only then starts to wait for
    # the Response signal, and libdbus reads as many messages as are in the socket at once;
    # a Response that is already there when the reply is read sits in a queue that nobody
    # looks at, and the app's UI thread waits for it forever (confirmed: the window is
    # frozen on the frame of the click). A real portal's answer takes seconds, a person
    # being at the other end; an instant one made about one dialog in ten hang under load.
    ANSWER_DELAY = 0.4

    def __init__(self, address):
        self._address = address
        self._lock = threading.Lock()
        self._answers = collections.deque()
        self._requests = []
        self._conn = None
        self._thread = None
        self._stopping = threading.Event()
        self.failure = None
        # What happened, in order, with the time: every call that arrived and how it was
        # answered. A test that fails reads it (`Get Portal Log`) to tell a dialog the app
        # never opened from one it opened and was answered with a cancel.
        self._events = []
        self._t0 = time.monotonic()
        self._answered = 0

    # -- the harness side -----------------------------------------------------

    def start(self):
        self._conn = open_dbus_connection(bus=self._address)
        owner = Proxy(message_bus, self._conn).RequestName(self.NAME)
        if owner != (1,):  # DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER
            raise RuntimeError(f"could not own {self.NAME} on the private bus: {owner}")
        self._thread = threading.Thread(target=self._serve, name="fake-portal", daemon=True)
        self._thread.start()

    def stop(self):
        self._stopping.set()
        if self._thread is not None:
            self._thread.join(timeout=5)
            self._thread = None
        if self._conn is not None:
            try:
                self._conn.close()
            except Exception:
                pass
            self._conn = None

    def reset(self):
        """Forget every queued answer and every recorded request."""
        with self._lock:
            self._answers.clear()
            self._requests.clear()
            self._note("reset")

    def _note(self, text):
        # (the caller holds the lock, or does not need it)
        self._events.append(f"{time.monotonic() - self._t0:8.3f}s {text}")

    @property
    def answered(self):
        """How many dialogs have had their answer sent."""
        with self._lock:
            return self._answered

    @property
    def log(self):
        with self._lock:
            return list(self._events)

    def answer(self, *paths):
        """The next dialog returns these files, as if the person chose them."""
        with self._lock:
            self._answers.append(("paths", [str(p) for p in paths]))
            self._note(f"queued: choose {[str(p) for p in paths]}")

    def answer_suggested(self, folder):
        """The next dialog accepts the file name the app suggested, in `folder` --
        a person pressing Save in the dialog without touching the name."""
        with self._lock:
            self._answers.append(("suggested", str(folder)))
            self._note(f"queued: accept the suggested name in {folder}")

    def cancel(self):
        """The next dialog is closed without choosing anything."""
        with self._lock:
            self._answers.append(("cancel", None))
            self._note("queued: cancel")

    @property
    def requests(self):
        with self._lock:
            return [dict(r) for r in self._requests]

    # -- the portal side ------------------------------------------------------

    def _serve(self):
        while not self._stopping.is_set():
            try:
                msg = self._conn.receive(timeout=0.2)
            except TimeoutError:
                continue
            except Exception as exc:  # the bus went away: the run is over, or broken
                if not self._stopping.is_set():
                    self.failure = f"fake portal lost the bus: {exc!r}"
                return
            try:
                self._handle(msg)
            except Exception as exc:
                self.failure = f"fake portal failed on {msg.header.fields}: {exc!r}"

    def _handle(self, msg):
        fields = msg.header.fields
        if msg.header.message_type != MessageType.method_call:
            return
        interface = fields.get(HeaderFields.interface)
        member = fields.get(HeaderFields.member)
        if interface != self.CHOOSER or member not in ("OpenFile", "SaveFile"):
            self._conn.send_message(
                new_error(
                    msg,
                    "org.freedesktop.DBus.Error.UnknownMethod",
                    "s",
                    (f"the fake portal only knows OpenFile and SaveFile, not {interface}.{member}",),
                )
            )
            return

        parent, title, options = msg.body
        request = self._describe(member, parent, title, options)
        with self._lock:
            self._requests.append(request)
            queued = bool(self._answers)
            kind, value = self._answers.popleft() if self._answers else ("cancel", None)
            self._note(
                f"{member} from {fields.get(HeaderFields.sender)}: "
                f"name={request['current_name']!r}; "
                f"{'queued answer' if queued else 'NOTHING QUEUED, so cancelled'}: {kind} {value}"
            )
        if kind == "suggested":
            name = request["current_name"] or "unnamed"
            kind, value = "paths", [os.path.join(value, name)]

        # The Request object the answer will come from is named after the caller and the
        # token it chose (the portal specification), which it is already listening for.
        sender = fields[HeaderFields.sender]
        token = options["handle_token"][1]
        handle = (
            "/org/freedesktop/portal/desktop/request/"
            f"{sender.lstrip(':').replace('.', '_')}/{token}"
        )
        self._conn.send_message(new_method_return(msg, "o", (handle,)))
        time.sleep(self.ANSWER_DELAY)
        if kind == "paths":
            uris = ["file://" + urllib.parse.quote(p) for p in value]
            response = (0, {"uris": ("as", uris)})
        else:  # 1: the person closed the dialog
            response = (1, {})
        self._conn.send_message(
            new_signal(
                DBusAddress(handle, interface=self.REQUEST),
                "Response",
                "ua{sv}",
                response,
            )
        )
        with self._lock:
            self._answered += 1
            self._note(f"answered #{self._answered} with code {response[0]}")

    @staticmethod
    def _describe(method, parent, title, options):
        """What the app asked for, as plain data."""

        def text(key):
            return options[key][1] if key in options else None

        def path(key):
            raw = options[key][1] if key in options else None
            return raw.rstrip(b"\x00").decode() if raw is not None else None

        filters = []
        if "filters" in options:
            for name, globs in options["filters"][1]:
                filters.append({"name": name, "globs": [glob for _kind, glob in globs]})
        return {
            "method": method,
            "parent_window": parent,
            "title": title,
            "current_name": text("current_name"),
            "current_folder": path("current_folder"),
            "current_file": path("current_file"),
            "multiple": text("multiple"),
            "directory": text("directory"),
            "filters": filters,
        }
