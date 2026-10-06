# Drag and drop — test requirements

Source: `App::handle_drag_and_drop` in `crates/app/src/app.rs` (one dropped file
is opened as the document, several open the Tools window on its Merge page),
`Tools::add_files` and `dropped_files` / `deliver` / `drop_target` in
`crates/app/src/tools/operand.rs` (a dropped file goes into the first empty box of
a Tools page, or replaces the last), and the Merge page's list in
`crates/app/src/tools/merge.rs`.

This was listed as "not reachable" for as long as the suites drove the app with
`xdotool`: a drag of *files* needs a program that owns the X selection
`XdndSelection` and answers the target's requests for the file list, which
`xdotool` is not. The harness now has one:

- `resources/xdnd.py` is an **XDND source** (protocol version 5, written
  against python-xlib, which is already installed as a dependency of pyautogui).
  It owns `XdndSelection`, sends `XdndEnter` and `XdndPosition` to the target
  window, waits for `XdndStatus` (the target accepts), sends `XdndDrop`, answers
  the target's `SelectionRequest` with a `text/uri-list` of `file://` URIs, and
  waits for `XdndFinished`. winit's X11 backend takes it for a real drag and
  gives egui the files exactly as it would from a file manager.
- the keyword `Drop Files On Window    x    y    path...` (AppLibrary) runs it
  against the current window (`Switch To Window`) at a window-relative point and
  fails, with what it saw, if the window never accepts the drop;
- `Start Hovering Files    x    y    path...` / `Stop Hovering Files` hold a drag
  *over* the window without dropping it (`xdnd.py --hold`: it sends the enter and
  the position, answers the request for the file list, prints READY, and goes on
  until it is stopped, when it sends XdndLeave, the drag cancelled) — what makes the
  app draw its drop overlay.

Not on native Wayland, where the app gets no drops at all (see "Known
limitations" in the README) — the suite runs under X.

The dropped files are in `resources/fixtures/merge/` (`platypus.json` is
`["platypus"]`, `echidna.json` `["echidna"]`, `notes.txt` is not JSON, and so on:
words, not numbers, where something has to be read back, because OCR reads words
well and small digits badly).

## Cases (`suites/drag_and_drop/`)

| ID | Title | Priority |
|---|---|---|
| TC-DND-001 | A file dropped on the main window is opened | P1 |
| TC-DND-002 | It does not matter where on the window it is dropped | P2 |
| TC-DND-003 | A dropped file replaces the open document | P1 |
| TC-DND-004 | A file that is not JSON gives a load error | P1 |
| TC-DND-005 | A file with broken JSON gives a load error | P2 |
| TC-DND-006 | Several files open the Tools window on Merge | P1 |
| TC-DND-007 | Several files bring the Merge page up from another page | P2 |
| TC-DND-008 | A file dropped on Format goes into the Input box | P1 |
| TC-DND-009 | A second file dropped on Format replaces the first | P2 |
| TC-DND-010 | Two files fill the two boxes of Diff | P1 |
| TC-DND-011 | Two files fill the Document and the Patch | P1 |
| TC-DND-012 | Two files fill the Document and the Schema | P1 |
| TC-DND-013 | A file dropped on the Source window opens in it | P1 |
| TC-DND-014 | A folder is not added to the Merge list | P2 |
| TC-DND-015 | Files dropped on the Tools window do not open in the main window | P2 |
| TC-DND-016 | Files held over an empty window show the drop overlay | P1 |
| TC-DND-017 | The overlay goes when the files leave | P1 |
| TC-DND-018 | With a document loaded there is no overlay | P2 |

The Merge page's own cases (which need files in the list and so are driven by
drops too) are TC-MRG-010 to TC-MRG-034 in [13_tools_window.md](13_tools_window.md).

## What is still not reachable

- The native **Open file…** / **Add files…** / **Save…** dialogs are not part of a drop; they are
  answered by the stand-in portal and checked in [02_opening_sources.md](02_opening_sources.md),
  [09_saving.md](09_saving.md) and [13_tools_window.md](13_tools_window.md) (see "Native OS dialogs" in
  [00_test_strategy.md](00_test_strategy.md)).
- Files too big for a box (over 1 MB, kept as a path and read when the tool
  runs) and over the tools' 128 MB cap: a fixture that size is not worth
  keeping in the repository; `jobs.rs` and `operand.rs` cover them headlessly.
