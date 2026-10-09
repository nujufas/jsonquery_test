# Tools window — test requirements

Source: `crates/app/src/tools.rs` (the window) and `crates/app/src/tools/` (a
file per page: `merge.rs`, `format.rs`, `diff.rs`, `patch.rs`, `validate.rs`;
`operand.rs` for the box JSON goes in, `widgets.rs` for the shared look,
`jobs.rs` for the work the worker thread does), the tools' own logic in
`crates/query/src/{merge,reformat,diff,patch,schema}.rs`, `Command::Merge` /
`Command::Tool` / `Command::SaveText` and `Event::MergeDone` / `Event::ToolDone`
in `crates/app/src/worker.rs`, and `App::apply_tools_request` and
`App::handle_drag_and_drop` in `crates/app/src/app.rs`.

A small, dim **🛠** button in the toolbar, just left of the 📖 tutorial button,
opens the **Tools window**: a second native window (an egui viewport that eframe
redraws by itself, as it does the panes' windows) titled "jsonquery — Tools".
Across its top are the tabs of the tools — **Merge JSON**, **Format JSON**,
**Diff JSON**, **Patch JSON** and **Validate schema** — and the selected tool's
page fills the rest.

Every page is built from the parts of the main window, in the main window's
sizes (stock egui buttons, text, spacing and margins — nothing is bigger):

- under the tabs, a **command row** with the page's main button (Merge, Format,
  Compare, Apply, Validate) and its options, as the Query row holds Run (Merge
  has its filter box under the row, as the query box is);
- under that, **two panes** side by side, with a line between them that can be
  dragged: what goes in on the left, what came out on the right. Each has a
  **header** like Source's and Results': a small title, its buttons (Open file…,
  Open document, Clear; Save…, Copy, Open in main window…, there from the start
  and usable once there is a result) pinned at the right, and nothing under it
  (the line above the panes is the only divider);
- at the bottom, a **status bar** that says what came out ("array · 6 items",
  "100 B (was 48 B)", "1 added · 1 removed · 1 changed", "Valid") and what was
  last done ("Saved to …", "Copied to the clipboard").

There is no paragraph of help: explanations are tooltips.

## Merge JSON

Combines several files into one document by running a jq filter over them, the
way `jq -s` does: the files are read in the order listed and slurped into one
array, which the filter sees as `.`; `$files` is the array of their names. The
files are added by dropping them on the window, or with **Add files…**; they can
be moved (⏶ ⏷), removed (×), sorted by name with numbers in order (**Sort A–Z**:
`part2` before `part10`) or cleared, and a file already in the list is not added
twice. **Merge as** picks a ready-made filter —

| Preset | Filter |
|---|---|
| Append arrays (the default) | `add` |
| Append, sorted and de-duplicated | `add \| unique` |
| Deep-merge objects | `reduce .[] as $file ({}; . * $file)` |
| Bundle by file name | `[range(0; length) as $i \| {file: $files[$i], data: .[$i]}]` |

— and the filter box under it can be edited freely; a filter that matches no
preset is shown as "Custom jq filter". **Merge** (or Ctrl+Enter) runs it on the
worker thread, with **Cancel** (and a spinner) in its place while it runs. The
status bar then says what the result is ("array · 6 items") and how it came
about ("Merged 2 files (6 B) in 1.2ms"), the right pane shows a bounded preview,
**Open in main window** makes the merged document the loaded source (shown in the
toolbar as "(merged from N files)" and saved as `merged.json` by default) and
**Save…** writes it — both are in the result's header — and the status bar says
how the save went. Each file in the list also says what it was ("array · 3 items
· 135 B"). Changing the files or the filter drops an old result.

A filter with several outputs (`.[]`) gives them as one array; one with none, a
runtime error (adding an array to an object), a syntax error or a file that is
not valid JSON is reported in the Result box. The files may add up to
128 MB (a merge happens in memory); more is refused with a message. A result as
big as a file is kept on disk from (a setting; 256 MB unless it was changed) is not
kept in memory either: it is printed to a temporary file that has no name, the
document is that file, mapped and indexed, and the status bar adds "result of
612 MB kept in a temporary file".

Dropping **several files on the main window** (instead of one, which opens) opens
the Tools window with them listed. Drag-and-drop does not work on native
Wayland (see the README); **Add files…** does.

## The box JSON goes in (Format, Diff, Patch, Validate)

Each takes its documents in a titled box: type or paste into it; drop a file on
the window (it goes to the first empty box, or replaces the last one); **Open
file…**; or **Open document**, the document open in the main window (disabled
when there is none). A file up to 1 MB is read into the box and can be edited;
a bigger one is shown as its name and size and read when the tool runs. **Clear**
empties the box. A file that can't be read (missing, not a file, not text) is
named in red next to the title and leaves the box as it was. Editing a box, or
changing an option, drops the page's old result.

## Format JSON

**Input** → **Result**. Options: **Indent** (2 spaces, 4 spaces, Tab, Minified),
**Sort keys**, **ASCII only**. **Format** (Ctrl+Enter) prints it; the status bar
says the result's size against the input's ("3.4 KB (was 1.2 KB)"); **Save…**
(named `<file>.formatted.json`, or `.min.json`) and **Copy** (up to 16 MB), in the
result's header, take all of it, the preview only the start of a long text. Text that isn't JSON is
reported as `Input: parsing JSON: … at line L column C`.

## Diff JSON

Four views, as tabs in the command row: **Documents** (Left and Right next
to each other), **Side by side**, **Changes** and **Patch**. **Compare**
(Ctrl+Enter) runs it and opens Side by side; **Swap** exchanges the documents
and goes back to Documents. Side by side shows the two documents line by line,
read-only, left and right, with a line only one has blank on the other side and
the colours red (removed), green (added) and amber (changed, with the differing
characters picked out); both sides scroll together; **⏶** / **⏷** (Alt+Up /
Alt+Down) walk the differences, the status bar says "Difference 2 of 5";
**Differences only** folds the same lines into "… 23 lines are the same";
clicking a difference copies its path. The Changes tab lists each addition,
removal and change with its JSON Pointer and value(s) — "Changes (3)" on the
tab, "1 added · 1 removed · 1 changed" in the status bar — and "The documents
are the same" when they are. The Patch tab shows the RFC 6902 patch, one
operation to a line; **Copy patch** and **Save patch…** (right end of the
command row, every view) take it. Object member order is not a difference and
numbers are compared by value (`1` = `1.0`); arrays are aligned by content, so an
insertion is one change. Both sides show members in the left document's order.
Documents over 200,000 lines are "Too long to show side by side" (the list and
the patch still work).

## Patch JSON

**Document** and **Patch** → **Result**. **Kind**: *Operations (RFC 6902)* or
*Merge patch (RFC 7386)*. **Apply** (Ctrl+Enter) runs it. A failing operation
is reported as `operation N (op path): reason` and changes nothing. **Open in
main window** shows the result as the loaded document ("(patched)" in the
toolbar, `patched.json` suggested for a save), **Save…** writes it and **Copy**
copies it.

## Validate schema

**Document** and **Schema** → **Problems**. **Check formats** (on by default,
in the command row).
**Validate** (Ctrl+Enter) runs it. The status bar says "Valid" or "N problems"; each
problem row has its JSON Pointer ("(document)" for the whole) and message, with
the keyword and the schema path in the tooltip. Clicking a row picks it; **Show
in main window** (or a double-click) puts its pointer in the main window's query
box under the Pointer engine and runs it — only for the document that is open in
the main window. **Copy report** copies the list. A schema that can't be used
(not a schema, a `$ref` that points outside it) is reported as `The schema can't
be used: …`; nothing is ever fetched.

## Cases

Six suites in `suites/tools/` share `resources/tools.resource` (every measured
region and click point of the window, and the keywords that use them). The pages
are driven the way a person drives them — pick the tool's tab, paste JSON into a
box (through the clipboard, as the main window's suites do) or drop a file on it,
press the page's main button — and the result is checked the most reliable way
each case allows:

- **the clipboard** for anything long or exact: the result's **Copy** button is
  pressed and the clipboard compared character for character (every Format layout,
  tabs and escapes included, the patched document, the report, the patch). The
  clipboard is set to a marker first, so a button that does nothing fails;
- **pixels** for state and look: a button is dim or bright by the brightness of its
  label (`Get Ink Bounds`, ~112 dim, ~180–240 bright), the selected tab and the
  picked row by their fill colour, the marks of the side-by-side view by their
  colours, "no line here" by `Region Should Be Plain`;
- **OCR** for short plain things — the status bar, an error's words, "Files (2" —
  asking only for what Tesseract reads reliably (a word, not `"b": 1,`; `Changes
  (5` and not `Changes (5)`, which comes back as `(5S)`; `Difference 2`, not
  `2 of 5`, which comes back as `1o0f2`).

### Shell and the Merge page's empty state — `tools.robot`

| ID | Title | Priority |
|---|---|---|
| TC-TWIN-001 | The Tools Button Opens A Window Of Its Own | P1 |
| TC-TWIN-002 | The Main Window Keeps Working With The Tools Window Open | P1 |
| TC-TWIN-003 | Closing The Window And Pressing The Button Again Reopens It | P1 |
| TC-TWIN-004 | Pressing The Button With The Window Open Brings It Forward | P2 |
| TC-TWIN-005 | Every Tool Is In The List And Opens Its Page | P1 |
| TC-TWIN-012 | A Maximized Tools Window Still Responds And Closes | P1 |
| TC-TWIN-013 | Each Page Keeps What Was Typed In It | P1 |
| TC-TWIN-014 | The Selected Tab Is Marked | P2 |
| TC-TWIN-015 | The Window Opens At Its Default Size | P2 |
| TC-TWIN-016 | The Tools Window Follows The Main Window's Theme | P2 |
| TC-TWIN-017 | No Line Under A Pane's Header | P2 |
| TC-TWIN-018 | The Line Between The Panes Can Be Dragged | P2 |
| TC-MRG-001 | Merge Has Nothing To Run Until There Are Files | P1 |
| TC-MRG-002 | The Presets Are Listed | P1 |
| TC-MRG-003 | Picking A Preset Puts Its Filter In The Box | P1 |
| TC-MRG-004 | A Filter Of One's Own Is Called Custom | P1 |
| TC-MRG-005 | Picking A Preset Replaces A Custom Filter | P2 |

### Merge with files — `tools_merge.robot`

The files are put on the list by **dropping** them (see
[16_drag_and_drop.md](16_drag_and_drop.md)): several on the main window, or any
on the Tools window. Results are read as words (`platypus`, `echidna`, `koala`,
`wombat`, `one`, `two`, `ten`), in the order of the files.

| ID | Title | Priority |
|---|---|---|
| TC-MRG-010 | Files Dropped On The Main Window Open The Merge Page | P1 |
| TC-MRG-011 | One File Dropped On The Main Window Is Opened | P1 |
| TC-MRG-012 | Files Dropped On The Tools Window Are Added | P1 |
| TC-MRG-013 | Append Arrays Joins The Files In Order | P1 |
| TC-MRG-014 | The Order Of The List Is The Order Of The Merge | P1 |
| TC-MRG-015 | A File Can Be Taken Off The List | P1 |
| TC-MRG-016 | Clear Empties The List | P1 |
| TC-MRG-017 | Sort A-Z Puts Numbers In Order | P1 |
| TC-MRG-018 | The Same File Is Listed Once | P2 |
| TC-MRG-019 | Append Arrays Takes Objects Too | P2 |
| TC-MRG-020 | Deep-Merge Keeps What Both Files Have Inside | P1 |
| TC-MRG-021 | Sorted And De-Duplicated Gives Each Value Once | P1 |
| TC-MRG-022 | Bundle By File Name Labels Each File | P1 |
| TC-MRG-023 | A Filter Of One's Own Runs | P1 |
| TC-MRG-024 | A Filter With Several Outputs Gives An Array Of Them | P2 |
| TC-MRG-025 | Adding An Array To An Object Is An Error | P1 |
| TC-MRG-026 | A File That Is Not JSON Is Named | P1 |
| TC-MRG-027 | A Filter That Gives Nothing Is An Error | P2 |
| TC-MRG-028 | A Filter That Never Stops Is Cut Off | P2 |
| TC-MRG-029 | Open In Main Window Makes It The Document | P1 |
| TC-MRG-030 | Changing The Files Drops The Result | P1 |
| TC-MRG-031 | Changing The Filter Drops The Result | P2 |
| TC-MRG-032 | Ctrl+Enter Merges | P2 |
| TC-MRG-033 | The Merge Button Is Bright With Files | P2 |
| TC-MRG-034 | Big Numbers Keep Their Digits | P2 |

### Merge with a big result — `tools_merge_big.robot`

A result as big as a file is kept on disk from (the limit of the Settings window; 1 KB is the
least a limit can be, which these cases set in the app's `settings.json`, so that a few lines
are "big") is not a value in memory: the worker prints it, as Save… does, to a temporary file
that has no name, and the document is that file, memory-mapped and indexed. The app is started
with that limit and with a `TMPDIR` of its own to look into (`Launch Jsonquery App
settings=… temp_dir=…`). Two lists of 60 words (`Make Lists Of Words`: `platypus` or
`echidna` first, then `wombat`) merge to 120 items and 1.4 KB when printed. That a file is
really held is read from the app's memory map (`/proc/<pid>/maps`: a mapped file whose name
ends `merged.json (deleted)`, `App Should Have Mapped A Deleted File`).

| ID | Title | Priority |
|---|---|---|
| TC-MRG-040 | A Result As Big As Files Are Kept On Disk From Is Kept In A Temporary File | P1 |
| TC-MRG-041 | A Result Under That Size Stays In Memory | P1 |
| TC-MRG-042 | A Big Result Opens In The Main Window As A File | P1 |
| TC-MRG-043 | A Big Result Is Saved Whole | P1 |
| TC-MRG-044 | The Temporary File Has No Name | P1 |
| TC-MRG-045 | The Size Is The One In The Settings | P1 |

#### Mutation checks of the big-result cases

One fault put into the app's merge at a time, in a build of its own (the suite is run against that build; the unit
tests of `worker.rs` are run against it too):

| Mutant | What is broken | Killed by |
|---|---|---|
| G1 | a big result is never written to a file (always a value in memory) | TC-MRG-040, 042, 044 (041, 043 and 045 need no file); unit: the tests of `worker.rs` for a result kept in a file |
| G2 | every result is written to a file, even one of a few bytes (and read back into memory, which looks the same from outside) | TC-MRG-041, whose temporary folder is one that is not there; unit: `a_merge_result_smaller_than_files_are_kept_on_disk_from_stays_in_memory` |

G2 survived all six cases at first: a small result written to a file with no name and read back is a value
in memory all the same, and nothing on the screen differs. TC-MRG-041 now starts the app with a `TMPDIR` that does
not exist, and a merge that made a file there would end in an error. The unit test got the same missing folder.

### Format JSON — `tools_format.robot`

| ID | Title | Priority |
|---|---|---|
| TC-TWIN-006 | Format JSON Pretty-Prints Pasted Text | P1 |
| TC-FMT-001 | The Layout Is Two Spaces To A Level By Default | P1 |
| TC-FMT-002 | Four Spaces To A Level | P1 |
| TC-FMT-003 | A Tab To A Level | P1 |
| TC-FMT-004 | Minified Has No White Space | P1 |
| TC-FMT-005 | Sort Keys Puts Every Object's Keys In Order | P1 |
| TC-FMT-006 | Without Sort Keys The Keys Keep Their Order | P2 |
| TC-FMT-007 | ASCII Only Escapes What Is Not ASCII | P1 |
| TC-FMT-008 | Characters Outside ASCII Are Kept By Default | P2 |
| TC-FMT-009 | Numbers Come Back As They Were Written | P1 |
| TC-FMT-010 | Empty Containers Stay On One Line | P2 |
| TC-FMT-011 | A Document That Is Only A Scalar Formats Too | P2 |
| TC-FMT-012 | Text That Is Not JSON Is Reported With Where | P1 |
| TC-FMT-013 | Several Values In A Row Are Read As One Array | P2 |
| TC-FMT-023 | Text After The Document Is An Error | P2 |
| TC-FMT-014 | Format Waits For Something To Format | P1 |
| TC-FMT-015 | Ctrl+Enter Formats | P1 |
| TC-FMT-016 | Clear Empties The Box And Drops The Result | P1 |
| TC-FMT-017 | Editing The Input Drops The Result | P1 |
| TC-FMT-018 | Changing An Option Drops The Result | P2 |
| TC-FMT-019 | Copy Says So In The Status Bar | P2 |
| TC-FMT-020 | The Status Bar Compares The Sizes | P2 |
| TC-FMT-021 | The Open Document Can Be Formatted | P1 |
| TC-FMT-022 | Open Document Is Dim Without A Document | P2 |
| TC-FMT-080 | A Document Kept On Disk Is Formatted As It Is Saved | P2 |

### Diff JSON — `tools_diff.robot`

| ID | Title | Priority |
|---|---|---|
| TC-TWIN-007 | Diff JSON Shows The Documents Side By Side | P1 |
| TC-DIF-001 | Compare Needs Both Documents | P1 |
| TC-DIF-002 | Documents That Are The Same Are Said To Be | P1 |
| TC-DIF-003 | Swap Exchanges The Two Documents | P1 |
| TC-DIF-004 | Swap After A Comparison Goes Back To The Documents | P2 |
| TC-DIF-005 | The Changes List Names Each Difference | P1 |
| TC-DIF-006 | A Document Of Another Kind Replaces The Whole | P2 |
| TC-DIF-007 | Walking The Differences | P1 |
| TC-DIF-008 | The Keyboard Walks The Differences Too | P2 |
| TC-DIF-009 | Differences Only Folds What Is The Same | P1 |
| TC-DIF-010 | Clicking A Difference Copies Its Path | P1 |
| TC-DIF-011 | Copy Patch Gives The Whole Patch | P1 |
| TC-DIF-012 | Copy Patch Works From Every View | P2 |
| TC-DIF-013 | Copy Patch Is Dim Until There Is A Patch | P2 |
| TC-DIF-014 | Editing A Document Drops The Comparison | P1 |
| TC-DIF-015 | A Second Comparison Replaces The First | P1 |
| TC-DIF-016 | The Marks Have Their Colours | P1 |
| TC-DIF-017 | A Change Alone Is Only Amber | P2 |
| TC-DIF-018 | A Left Document That Is Not JSON Is Named | P1 |
| TC-DIF-019 | A Right Document That Is Not JSON Is Named | P2 |
| TC-DIF-020 | The Two Columns Scroll As One | P1 |
| TC-DIF-021 | The Open Document Can Be One Of The Two | P1 |
| TC-DIF-022 | Clear Empties A Box | P2 |
| TC-DIF-023 | Ctrl+Enter Compares | P2 |

### Patch JSON — `tools_patch.robot`

| ID | Title | Priority |
|---|---|---|
| TC-TWIN-008 | Patch JSON Applies A Patch And Opens The Result | P1 |
| TC-TWIN-009 | A Patch That Fails Names The Operation | P2 |
| TC-PAT-001 | Operations Apply In Order | P1 |
| TC-PAT-002 | A Merge Patch Replaces, Removes And Adds | P1 |
| TC-PAT-003 | Changing The Kind Drops The Result | P2 |
| TC-PAT-004 | A Patch That Is Not A List Is Explained | P1 |
| TC-PAT-005 | A Document That Is Not JSON Is Named | P1 |
| TC-PAT-006 | A Patch That Is Not JSON Is Named | P2 |
| TC-PAT-007 | A Failed Test Changes Nothing | P1 |
| TC-PAT-008 | An Array Index Out Of Range Is An Error | P2 |
| TC-PAT-009 | A Pointer Reaches A Key That Has A Slash | P2 |
| TC-PAT-010 | Apply Needs Both Boxes | P1 |
| TC-PAT-011 | Open In Main Window Waits For A Result | P2 |
| TC-PAT-012 | The Patched Document Becomes The Main Window's Document | P1 |
| TC-PAT-013 | Editing A Box Drops The Result | P1 |
| TC-PAT-014 | Clear Empties A Box | P2 |
| TC-PAT-015 | The Open Document Is Patched | P1 |
| TC-PAT-016 | Ctrl+Enter Applies | P2 |
| TC-PAT-017 | Copy Says So In The Status Bar | P2 |
| TC-PAT-018 | Numbers Keep Their Digits Through A Patch | P2 |

### Validate schema — `tools_validate.robot`

| ID | Title | Priority |
|---|---|---|
| TC-TWIN-010 | Validate Schema Lists The Problems | P1 |
| TC-TWIN-011 | A Problem Can Be Shown In The Main Window | P1 |
| TC-VAL-001 | A Document That Fits Is Valid | P1 |
| TC-VAL-002 | The Draft Comes From The Schema | P1 |
| TC-VAL-003 | Formats Are Checked By Default | P1 |
| TC-VAL-004 | Check Formats Can Be Turned Off | P1 |
| TC-VAL-005 | A Schema That Is Not A Schema Is Explained | P1 |
| TC-VAL-006 | A Reference To Somewhere Else Is Refused | P1 |
| TC-VAL-007 | A Reference Inside The Schema Works | P2 |
| TC-VAL-008 | A Document That Is Not JSON Is Named | P1 |
| TC-VAL-009 | A Schema That Is Not JSON Is Named | P2 |
| TC-VAL-010 | Validate Needs Both Boxes | P1 |
| TC-VAL-011 | The Report Can Be Copied | P1 |
| TC-VAL-012 | Copy Report Is Dim Without Problems | P2 |
| TC-VAL-013 | Picking A Row Marks It | P1 |
| TC-VAL-014 | Show In Main Window Needs The Open Document | P1 |
| TC-VAL-015 | A Double-Click Shows The Problem | P1 |
| TC-VAL-016 | Editing A Box Drops The Report | P1 |
| TC-VAL-017 | Ctrl+Enter Validates | P2 |
| TC-VAL-018 | Every Problem Is Listed | P2 |

### TC-TWIN-012 — A maximized Tools window still responds and closes
Priority: P1
Steps: open the Tools window on Format JSON and maximize it (it now covers the
screen, and the main window under it); paste a document into the Input box, press
Format; close the window through the window manager; paste a document into the main
window.
Expected: the formatted text is read in the result area; the window closes; the
main window loads and shows the document. (Under X this passes with or without the
fix — the bug was Wayland's; see below. It guards the window's own redraw path, the
worker's answer being taken in by it, and closing a maximized window, on a real
window.)

### What the first full run found

Running the redesigned page for the first time found **a real bug**: Diff's
**Compare** did nothing. The end of `Diff::ui` ended with `let text = patch?;` and
`act?`, which return from the whole function whenever there is no patch yet (or no
Copy/Save press) — and so threw away the `Compare` request made earlier in the same
function. Ten headless tests failed for it and so would the Robot cases
(TC-TWIN-007 and nearly every TC-DIF case); TC-DIF-015 (a second Compare after an
edit) pins the second form of it, where there *is* a patch but nothing pressed.
Mutation check: putting the early return back fails every comparing case.

## The file dialogs

The native file dialogs — **Add files…**, **Open file…**, **Save…**, **Save patch…** — were out of
reach until 2026-10-06 (see "Native OS dialogs" in [00_test_strategy.md](00_test_strategy.md)).
They are answered now by a stand-in for the desktop's file-chooser portal, which says what the
person chooses and records what the app asked for (suggested name and file type), and the nine
cases of `suites/tools/tools_dialogs.robot` use it:

| ID | What it checks |
|---|---|
| TC-TDLG-001 | Format's Save offers `formatted.json` and writes the formatted text |
| TC-TDLG-002 | Minified, it offers `min.json` |
| TC-TDLG-003 | Open file… asks for the JSON-like file types; the file chosen, formatted, is offered on Save as `people.formatted.json` (its own name with `.formatted` before the extension) |
| TC-TDLG-004 | Patch's Save offers `patched.json` |
| TC-TDLG-005 | Merge's Save offers `merged.json` |
| TC-TDLG-006 | Diff's Save offers `patch.json` and writes the patch |
| TC-TDLG-007 | Merge's Add files… takes several files from one dialog |
| TC-TDLG-008 | Closing a Save dialog writes nothing |
| TC-TDLG-009 | Closing an Open dialog leaves the box as it was |

Files still also go in by dropping them, which the harness does for real
([16_drag_and_drop.md](16_drag_and_drop.md)). What stays headless (`jobs.rs`, `worker.rs`) is the
detail of what a save writes for each tool.

### Mutation checks of the dialog cases

One suggested name or file filter broken at a time in a build of the app; each is killed by the
case for that button and by no other:

| Mutant | What is broken | Killed by |
|---|---|---|
| M15 | Format's save is called `format.json` | TC-TDLG-001, 003 (002, the minified name, is not affected) |
| M20 | Patch's save is called `patch_result.json` | TC-TDLG-004 |
| M21 | Merge's save is called `merge.json` | TC-TDLG-005 |
| M22 | Diff's save is called `diff.json` | TC-TDLG-006 |
| M18 | Add files… offers only `*.json` | TC-TDLG-007 |

## What stays headless

What a person sees of the merge itself, the presets run against real files, the
reordering and sorting, opening the result in the main window and the multi-file
drop on the main window are all driven (TC-MRG-010 to TC-MRG-034, and a result big
enough to be a file, TC-MRG-040 to TC-MRG-045). The details of
each tool — every error message, every option, every edge of the engines — are more
than OCR of a window can check, so they are covered in depth headlessly by `cargo
test`:

- `crates/query/src/merge.rs`: every preset against the real jq engine, `$files`,
  a custom filter, several outputs, no output, runtime and syntax errors, a
  filter that never stops, cancelling, and that numbers keep their exact digits.
- `crates/query/src/reformat.rs`: the layouts (2/4 spaces, tab, minified), empty
  containers, key sorting at every depth, `\uXXXX` and surrogate pairs, control
  characters, exact numbers, and that the output reads back as the same document.
- `crates/query/src/diff.rs` and `diff/view.rs`: JSON equality (key order, number
  notation, exact digits), added/removed/changed with their paths and escaping,
  array alignment (an insertion or removal is one change), type changes, the cap on
  listed changes, cancelling; and the side-by-side layout (rows, blanks, commas,
  blocks, the 200,000-row limit) with a random-documents invariant.
- `crates/query/src/patch.rs`: the examples of RFC 6902 appendix A and RFC 7386
  appendix A, error messages that name the operation, strict array places,
  atomicity, member order, and — the main one — thousands of generated pairs of
  documents for which applying `diff`'s patch to the first gives the second.
- `crates/query/src/schema.rs`: problems with their path and keyword, the draft
  taken from `$schema`, formats on and off, `$ref` inside the schema, that a
  reference outside it is an error (nothing fetched), exact numbers, the cap on
  problems, long values left out of messages, cancelling.
- `crates/app/src/worker.rs`: a merge's result under, exactly at and one byte over the size
  files are kept on disk from (a value in memory, and a mapped temporary file in a folder
  that is left empty), what the page shows (the preview, the number of outputs) the same
  either way, the file saved byte for byte as a result in memory is and numbers keeping
  their digits, a folder to spill into that is not there, a merge cancelled before its
  result is written, the count of the size stopping as soon as it knows, and the worker
  answering for it. `crates/core/src/document.rs`: a file that has just been written is
  read from its start, mapped or not.
- `crates/app/src/tools/jobs.rs`: each job against text, a file and the open
  document, bad input named by its box, the size cap, cancelling, previews.
- `crates/app/src/tools/operand.rs`, `shared.rs`, `side_by_side.rs` and the pages:
  reading a file into a box (byte-order mark, big file kept as a path, unreadable
  file), where a dropped file goes, swapping, a stale answer being dropped, the
  summaries, folding and stepping through differences.
- Native Wayland, a window maximized (or otherwise placed) over the whole main
  window: GNOME's compositor sends no redraw callbacks to a completely covered
  window, so the main window stops being redrawn, and the Tools window must not
  depend on that (it did while it was drawn inside the main window's frame: after
  maximizing it, nothing in it responded). Not reproducible under Xvfb, so no
  Robot case sees it: TC-TWIN-012 runs the flow under X, and `layout_tests.rs`
  checks what the window's own frame does without any frame of the main window.
  The same goes for the tutorial and About, which share the mechanism
  (`app/satellites.rs`, [14_tutorial_and_about_windows.md](14_tutorial_and_about_windows.md)).
- `crates/app/src/app/layout_tests.rs`: the button's place beside 📖; every tool
  listed and opening its page; merging two files through the window and into the
  main window; a failed merge; dropping several files on the main window; typing
  into Format and changing an option; a formatting error with its line; Diff
  comparing, listing changes and giving the patch, side by side with its marks, the
  differences stepped and folded, a click copying a path, documents too long for the
  view; Patch applying and opening the result, naming a failing operation; Validate
  against the open document and showing a problem in the main window, a valid
  document, an unusable schema; the two boxes of a page stacked under the command
  row, the headers of the two halves on one line, and the window's headings and
  buttons in the main window's text sizes; that the toolbar's labels and icons never
  overlap; and, with the harness that runs the app as eframe does (behind a lock,
  each window a deferred viewport redrawn on its own — `Windows`): that the Tools
  window, the tutorial and About are such windows, that the Tools window takes clicks
  and typing, runs Format and shows its answer without a single frame of the main
  window, that a click in it asks the main window to redraw, that the tutorial's
  "Load query" reaches the main window's query box in the same way, that closing a
  maximized or fullscreen window un-maximizes it (so that the main window is
  uncovered and drops it), that a closed window the main window never drops minimizes
  itself, that a closed window opens again, and that the worker's wake-up asks every
  window for a frame.

A test can't say that one window looks like another, so the look is checked by
eye as well: after a change to the pages, take the Tools window's screenshots in
the dark and the light theme, with a result on each page, and put them beside the
main window's. The headings, buttons, spacing and boxes should be the same ones
([15_pane_headers.md](15_pane_headers.md) pins the titles and the missing lines in
pixels; the headless test `the_tools_window_uses_the_main_windows_text_sizes` pins
the sizes of the text, not the look).
