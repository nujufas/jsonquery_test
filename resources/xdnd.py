"""Drops files on an X11 window the way a file manager does: an XDND source.

`xdotool` cannot drag and drop files (a drag needs a program that owns the
`XdndSelection` and answers the target's requests for it), which is why the
tests could not reach anything that takes files by dropping them -- the Merge
page's list, the main window's "drop a file anywhere". This is that program,
written against the XDND protocol (version 5) with python-xlib, which is
already in the test environment as a dependency of pyautogui:

  1. own `XdndSelection`;
  2. XdndEnter + XdndPosition to the target window (root coordinates of the
     "pointer", the files' type being `text/uri-list`);
  3. wait for XdndStatus (the target accepts);
  4. XdndDrop;
  5. answer the target's SelectionRequest with the `file://` URI list;
  6. wait for XdndFinished.

Run as a program (the keyword `Drop Files On Window` in AppLibrary does):

    python xdnd.py <display> <target-window-id> <root-x> <root-y> <file> [<file>...]

Exits 0 when the target said it was finished with the drop, 1 otherwise (and
says what it saw on stderr).

With `--hold` as the first argument the files are only *hovered* over the window,
not dropped: after the target has accepted and asked for the file list (which is
what makes it show a drop overlay) the program prints `READY` and goes on answering
until it is sent SIGTERM, when it sends XdndLeave (the drag is cancelled) and exits.
"""

import signal
import sys
import time
from urllib.parse import quote

from Xlib import X, Xatom, display
from Xlib.protocol import event

TIMEOUT = 5.0


def _client_message(window, client_type, data):
    return event.ClientMessage(window=window, client_type=client_type, data=(32, data))


def drop(display_name, target_id, root_x, root_y, paths, timeout=TIMEOUT, hold=False):
    d = display.Display(display_name)
    root = d.screen().root
    atom = d.intern_atom
    xdnd_selection = atom("XdndSelection")
    uri_list = atom("text/uri-list")
    enter, position, status = atom("XdndEnter"), atom("XdndPosition"), atom("XdndStatus")
    drop_atom, finished, leave = atom("XdndDrop"), atom("XdndFinished"), atom("XdndLeave")
    action_copy = atom("XdndActionCopy")

    target = d.create_resource_object("window", target_id)
    aware = target.get_full_property(atom("XdndAware"), Xatom.ATOM)
    if aware is None:
        print(f"window {target_id} is not XdndAware", file=sys.stderr)
        return False
    version = min(5, int(aware.value[0]))

    # The source: an unmapped window that owns the selection and receives the
    # target's replies.
    source = root.create_window(0, 0, 1, 1, 0, d.screen().root_depth, X.InputOutput, X.CopyFromParent)
    source.change_attributes(event_mask=X.PropertyChangeMask)
    source.set_selection_owner(xdnd_selection, X.CurrentTime)
    d.sync()
    if d.get_selection_owner(xdnd_selection) != source:
        print("could not own XdndSelection", file=sys.stderr)
        return False

    payload = "".join(f"file://{quote(str(p))}\r\n" for p in paths).encode()

    def send(client_type, data):
        target.send_event(_client_message(target, client_type, data), event_mask=X.NoEventMask)
        d.flush()

    send(enter, [source.id, version << 24, uri_list, 0, 0])
    send(position, [source.id, 0, (int(root_x) << 16) | int(root_y), X.CurrentTime, action_copy])

    accepted = False
    dropped = False
    done = False
    stop = []
    seen = []
    if hold:
        signal.signal(signal.SIGTERM, lambda *_: stop.append(True))
        timeout = 600.0
    deadline = time.time() + timeout
    while time.time() < deadline and not done and not stop:
        while d.pending_events():
            ev = d.next_event()
            if ev.type == X.ClientMessage:
                seen.append(d.get_atom_name(ev.client_type))
                if ev.client_type == status and not dropped:
                    flags = ev.data[1][1]
                    accepted = bool(flags & 1)
                    if accepted and hold:
                        pass  # keep hovering
                    elif accepted:
                        # A moment on the target, as a pointer hovering over it.
                        time.sleep(0.15)
                        send(drop_atom, [source.id, 0, X.CurrentTime, 0, 0])
                        dropped = True
                    else:
                        send(leave, [source.id, 0, 0, 0, 0])
                        print(f"the target did not accept the drop; saw {seen}", file=sys.stderr)
                        return False
                elif ev.client_type == finished:
                    done = True
            elif ev.type == X.SelectionRequest:
                seen.append("SelectionRequest:" + d.get_atom_name(ev.target))
                requestor = d.create_resource_object("window", ev.requestor)
                prop = ev.property or ev.target
                if ev.target == uri_list:
                    requestor.change_property(prop, uri_list, 8, payload)
                    reply = prop
                elif ev.target == atom("TARGETS"):
                    requestor.change_property(prop, Xatom.ATOM, 32, [uri_list])
                    reply = prop
                else:
                    reply = X.NONE
                notify = event.SelectionNotify(
                    time=ev.time, requestor=ev.requestor, selection=ev.selection,
                    target=ev.target, property=reply,
                )
                requestor.send_event(notify, event_mask=X.NoEventMask)
                d.flush()
                if hold and ev.target == uri_list:
                    print("READY", flush=True)
                if dropped and ev.target == uri_list:
                    # Version 1 targets send no XdndFinished; give a moment for the
                    # drop to be taken in and call it done.
                    if version < 2:
                        time.sleep(0.2)
                        done = True
        time.sleep(0.02)
    if hold:
        send(leave, [source.id, 0, 0, 0, 0])
        time.sleep(0.2)
        return True
    if not done:
        print(f"no XdndFinished (accepted={accepted} dropped={dropped}); saw {seen}", file=sys.stderr)
    return done


if __name__ == "__main__":
    args = sys.argv[1:]
    hold = bool(args) and args[0] == "--hold"
    if hold:
        args = args[1:]
    if len(args) < 5:
        print(__doc__)
        sys.exit(2)
    ok = drop(args[0], int(args[1]), args[2], args[3], args[4:], hold=hold)
    sys.exit(0 if ok else 1)
