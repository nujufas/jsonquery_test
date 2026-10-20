# Text menus — test requirements

Source: `crates/app/src/text_menu.rs` (the menu itself, and the read-only text box that stands in for a
selectable label), and where it is attached: `app.rs` (the query box, the source field, the paste box,
the Text views, the Find field, the status bar's messages, the About window), `tools/widgets.rs` (the boxes
and the results of the Tools), `tools/side_by_side.rs`, `tools/diff.rs` and `tools/validate.rs` (the lines of
their lists).

A text in the app has a **right-click menu**. egui gives a text box its keys (Ctrl+X, Ctrl+C, Ctrl+V, Ctrl+A)
and no menu, so the app makes one:

- **A box that can be typed in** has **Cut**, **Copy**, **Paste** and **Select All**, each with its key written
  beside it (`Ctrl+X`; `Cmd+X` on a Mac). Cut and Copy are dim until something is selected, Select All is
  dim in an empty box. The boxes: the query box, the source field (in the toolbar, and in a popped-out Source
  pane), the box of the empty Source pane ("Paste JSON here..."), the Text view of a pasted document, the Find
  field, every box of the Tools (Format's Input, Diff's Left and Right, Patch's Document and Patch, Validate's
  Document and Schema, Merge's filter) and the field that a double click puts in a line of Diff's
  side-by-side view (its menu has the path of the line under the four items).
- **A text that is only shown** has **Copy** and **Select All**: the Results pane's Text view, the Text view
  of a file that was opened (a document that was pasted is a box), the result of Format and Patch, and the
  red message a tool gives for a mistake. These are read-only text boxes, not labels: a right click on a
  label's selection throws the selection away, and a menu could not read it.
- **A line of a list, or a message**, has what that line can give: Side by side's lines **Copy line** (or
  **Copy left line** and **Copy right line** where the sides differ, with the moves and **Copy path** above
  them), the Changes list **Copy path** and **Copy line**, Validate's problems **Copy path**, **Copy
  message** and **Copy problem**, the hits of Find All **Copy path** and **Copy line**; a message in the
  status bar, and in the About window the version, the text about limitations and each line of the known
  issues, have **Copy**, and a link there has **Copy link**.
- Not in this document: the tree rows' menu ([07_context_menus.md](07_context_menus.md)), and the places that
  have none (Settings, the tutorial, the ⚠ notice of a Wayland window, which has a **Copy command** button
  of its own and is a popup: a menu opened in a popup closes it).

How the menu behaves, and what the cases look at:

- **It opens at the pointer**, its top-left corner there, and its items are 21 px apart, the first 16 px
  under the pointer (Cut 16, Copy 37, Paste 58, Select All 79; in a text that is only shown Copy 16, Select
  All 37). The cases click an item by that distance; OCR is only asked whether the menu is open, by a word
  that is bright (`Paste` in a box, `Select All` in a text that is only shown). Near the foot of the window
  the menu opens above the pointer instead: the status bar's case finds Copy by OCR.
- **A right click inside a selection leaves it selected**; a right click outside it puts the caret there, as
  it does anywhere. (egui moves the caret on a press of *any* button, which threw the selection away and
  left Copy nothing to copy.)
- **Paste, and Cut, are asked of the window system**, which answers a frame later with the event that the
  key makes: a menu cannot read the clipboard. The cases wait 0.6 s after the click before they look.
- **Copy** puts the selected text on the clipboard at once, and a message, a line or a link its whole text.
- **The line being typed over keeps its field** while its menu is used: a press on an item takes the focus
  from the field, which used to end the typing (and put in what was typed); the menu gives the focus back.

The cases read what was done exactly, from the clipboard (every case sets it to `nothing was copied` first, so
a menu that did nothing fails) and from the box (`Query Text Should Be`, `Source Field Should Be` copy all of a
box and compare), and never from OCR of small text.

## Cases

`suites/text_menus/text_menus.robot` is the main window's (17 cases); `suites/tools/tools_menus.robot` is the
Tools' (9, tagged `tools` so that the docked run has them too); the About window's three are in
`suites/satellites/` ([14_tutorial_and_about_windows.md](14_tutorial_and_about_windows.md)).

| ID | Title | Priority |
|---|---|---|
| TC-TXM-001 | The Query Box Has The Menu Of A Text Box | P1 |
| TC-TXM-002 | Paste In The Menu Of The Query Box Puts The Clipboard In It | P1 |
| TC-TXM-003 | Select All And Copy In The Menu Put The Whole Query On The Clipboard | P1 |
| TC-TXM-004 | Cut In The Menu Moves The Query To The Clipboard | P1 |
| TC-TXM-005 | A Right Click Inside A Selection Keeps It, So That Copy Copies Just That | P1 |
| TC-TXM-006 | A Right Click Outside A Selection Puts The Caret There, And Copy Is Dim | P2 |
| TC-TXM-007 | The Menu Of The Source Field Pastes A Path | P1 |
| TC-TXM-008 | Paste In The Menu Of The Empty Source Panel Loads The Document | P1 |
| TC-TXM-009 | The Results' Text View Has Copy And Select All, Not Cut Or Paste | P1 |
| TC-TXM-010 | Select All And Copy In The Results' Text View Give All Of The Text | P1 |
| TC-TXM-011 | A Word Taken In The Results' Text View Stays Taken Under A Right Click | P2 |
| TC-TXM-012 | The Text View Of A Pasted Document Has The Menu Of A Box | P2 |
| TC-TXM-013 | The Text View Of A File Has Copy And Select All, Not Cut Or Paste | P2 |
| TC-TXM-014 | An Error In The Status Bar Is Copied With A Right Click | P2 |
| TC-TXM-015 | The Find Field Has The Menu Of A Text Box | P3 |
| TC-TXM-016 | A Hit Of Find All Copies Its Path Or Its Line | P3 |
| TC-TXM-017 | Every Box Of The Tools Has The Menu Of A Text Box | P1 |
| TC-TXM-018 | Paste In The Menu Of A Box Of A Tool Puts The Clipboard In It | P1 |
| TC-TXM-019 | Select All And Cut In The Menu Of A Box Of A Tool Empty It Into The Clipboard | P2 |
| TC-TXM-020 | The Result Of A Tool Is Text With Copy And Select All, Not Cut Or Paste | P1 |
| TC-TXM-021 | An Error Of A Tool Is Text That Can Be Selected And Copied | P2 |
| TC-TXM-022 | A Line Of The Side By Side View Copies Its Text | P1 |
| TC-TXM-023 | The Menu Of A Line Being Typed Over Is That Of A Box, And The Typing Goes On | P1 |
| TC-TXM-024 | A Change In The List Copies Its Path Or Its Line | P2 |
| TC-TXM-025 | A Problem In The List Copies Its Path, Its Message Or Its Line | P2 |
| TC-TXM-026 | Ctrl+A In A Text View Takes All Of Its Text, As Select All In The Menu Does | P3 |

### The query box and the source field (TC-TXM-001 to 007)

The query is put in the box by a paste (typing sends some characters wrong), `.people | map(.name)`.

- **001** — select all of it and right-click inside the text: the menu has **Cut**, **Copy**, **Paste** and
  **Select All**, and their keys (`Ctrl+X`, `Ctrl+V`), all bright.
- **002** — the clipboard has `.[] | select(.age > 21)` and the box is empty: Paste (third item): the box holds it.
- **003** — Select All (fourth item), then Copy (second): the clipboard has the whole query, and the box is as it was.
- **004** — with all selected, Cut (first item): the clipboard has the query and the box is empty (all of an empty
  box is taken and copied, and the clipboard is still the marker).
- **005** — a double click on `people` takes the word; a right click on it leaves it taken; Copy: the clipboard
  has `people` and nothing else.
- **006** — the same word taken, and the right click far to the right of the text: the selection is gone, Copy is
  dim and a click on it copies nothing.
- **007** — the clipboard has a path; Paste in the source field's menu: the field holds it.

### The empty Source pane, the Text views, the status bar, Find (TC-TXM-008 to 016, 026)

- **008** — nothing is loaded and the clipboard has `people.json`: Paste in the box of the pane loads the
  document ("pasted JSON" in the toolbar, "3 items" in the tree).
- **009** — the Results pane's Text view (`.[] | .name`) has Copy and Select All, bright, and no Cut and no Paste.
- **010** — Select All, then Copy: the clipboard has `["Alice", "Bob", "Carol"]` as the view shows it, one to a line.
- **011** — a double click on `Bob`, a right click on it, Copy: the clipboard has `Bob`.
- **012** — the Source pane's Text view of a pasted document is a box (Apply reads it again): Paste and Select All.
- **013** — a file that was opened (typed in the source field) has a read-only Text view: its menu has Copy
  and Select All, no Cut and no Paste, and Select All and Copy give the whole text.
- **014** — `.[` does not parse; a right click on the red "Query error: ..." in the status bar and Copy: the
  clipboard begins `Query error: query syntax error`. (The bar is at the foot of the window, so the menu
  opens above the pointer: Copy is found by OCR.)
- **015** — Ctrl+F; Paste in the Find field's menu puts `Bob` in it; Enter finds it ("1 of 1").
- **016** — Find All for `Alice` lists the hit; a right click on it: Copy path gives `.[0].name`, Copy line a
  line that begins `[Source]`.
- **026** — a click in the Results pane's Text view, Ctrl+A and Ctrl+C: the clipboard has the whole text (the keys
  of a box work in a text that is only shown; a selectable label had no Ctrl+A).

### The Tools (TC-TXM-017 to 025)

- **017** — an empty box of every page (Format's Input, Diff's two, Patch's two, Validate's two, Merge's
  filter) has the menu: `Paste` is read, bright.
- **018** — Paste in Format's Input, then Format: Copy gives the document laid out.
- **019** — Select All and Cut in a box: the clipboard has the document, the box is empty.
- **020** — Format's result: Copy and Select All, no Cut and no Paste; Select All and Copy give the whole text.
- **021** — `{not json` is told in red in the result pane; Select All and Copy give the message
  (`Input: parsing JSON: ...`).
- **022** — Diff of `{"a":1,"b":2}` and `{"a":1,"b":3}`: the menu of `a` (the same on both sides) is Copy line
  alone and gives `  "a": 1,`; the menu of `b` has Move to the left, Move to the right, Copy path, Copy left
  line and Copy right line (a separator after the moves: Copy path is 67 px under the pointer), and the
  two Copies give `  "b": 2` and `  "b": 3`.
- **023** — a double click on `b` of Left puts a caret in the line. Its menu is a box's, with **Copy path** under
  it and no moves; Select All in it does not end the typing ("Editing line" is still said), and `"b": 7`
  typed then takes the place of all the line: Copy patch says what is left, `replace /b with 3`.
- **024** — the Changes list: the menu of the row of `b` has Copy path (`/b`, and the status bar says "Copied the
  path") and Copy line (`Changed /b  2 → 3`).
- **025** — Validate: `{"age":"old"}` against a schema that wants an integer; the menu of the problem has Copy
  path (`/age`), Copy message (the sentence, without the path) and Copy problem (`/age: <message> [type]`).

### The About window (TC-SAT-049 to 051)

In `suites/satellites/`: **049** the version (`jsonquery gui v0.5.1`, read from `Cargo.toml`) is copied; **050**
each of the four links copies its address (GitHub, the licence, the site, the policy of privacy), and
nothing is handed to the browser; **051** the line about modules, in the list of known issues, copies the
text that the page `docs/known-issues.md` has in bold for it.

## Mutation checks

One thing broken at a time in a build of the app (a scratch copy; `text_menu.rs`, `app.rs`, `tools/*.rs`), and the
cases that should see it, run on that build. 33 faults: all 33 are killed, each by the cases meant for it (the
cases run alone for a fault, so a case that fails is the one that saw it).

| Mutant | What is broken | Killed by |
|---|---|---|
| T1 | Paste does nothing | TC-TXM-002, 007, 008, 015, 018 |
| T2 | Cut copies and leaves the text | TC-TXM-004, 019 |
| T3 | Copy puts nothing on the clipboard | TC-TXM-003, 005, 010, 011, 013, 020 |
| T4 | Select All takes nothing | TC-TXM-003, 010, 013, 019, 020 |
| T5 | a right click inside a selection drops it | TC-TXM-005, 011 |
| T6 | a right click outside a selection keeps it | TC-TXM-006 |
| T7 | a text that is only shown has Cut | TC-TXM-009, 013, 020 |
| T8 | a text that is only shown has Paste | TC-TXM-009, 013, 020 |
| T9 | the query box has no menu | TC-TXM-001 to 006 |
| T10 | the source field has no menu | TC-TXM-007 |
| T11 | the box of the empty Source pane has no menu | TC-TXM-008 |
| T12 | the Text view of a pasted document has no menu | TC-TXM-012 |
| T13 | the Results' Text view is a label again (no menu) | TC-TXM-009, 010, 011 |
| T14 | the Text view of a file is a label again | TC-TXM-013 |
| T15 | a message in the status bar has no menu | TC-TXM-014 |
| T16 | the Find field has no menu | TC-TXM-015 |
| T17 | a hit of Find All copies its line for its path | TC-TXM-016 |
| T18 | the version in About has no menu | TC-SAT-049 |
| T19 | a link copies its text, not its address | TC-SAT-050 |
| T20 | a line of the known issues has no menu | TC-SAT-051 |
| T21 | a press on the menu of the field being typed in ends the typing | TC-TXM-023 |
| T22 | a line that is the same has the menu of one that differs | TC-TXM-022 |
| T23 | a changed line has no Copy line | TC-TXM-022 |
| T24 | Copy left line copies the right line | TC-TXM-022 |
| T25 | the menu of the field being typed in has no Copy path | TC-TXM-023 |
| T26 | Copy path of a change copies nothing | TC-TXM-024 |
| T27 | Copy line of a change copies nothing | TC-TXM-024 |
| T28 | Copy message copies the path | TC-TXM-025 |
| T29 | a copied problem has no keyword | TC-TXM-025 |
| T30 | the boxes of the Tools have no menu | TC-TXM-017, 018, 019 |
| T31 | the result of a tool is a label again | TC-TXM-020 |
| T32 | the error of a tool is a label again | TC-TXM-021 |
| T33 | the error of a tool is set in the monospace font | TC-FMT-012 (an old case: it is how the fault was found) |

The app's own tests (`crates/app/src/text_menu.rs`, `tools/widgets.rs` and `layout_tests.rs`) kill 43 of 44 faults
of the menu at the unit level; the one that lives there is equivalent (a selection that is stored a frame
later instead of at once).

## Lessons from writing them

- **A right click on the second word of a row finds the whole row.** `Find Text In Region` looks for a
  single word first and, failing that, for the words of a line joined; "Privacy policy" is two words, and a
  row "Privacy: Privacy policy" holds them, so what came back was the middle of the row, between the label
  and the link: a right click on nothing (TC-SAT-050 found it). Ask for the last word of a link ("policy").
- **A menu with one item is narrow.** A click on the item at the pointer's own x lands on the menu's edge, not on
  the button: click 20 px to the right of it.
- **A click on a dim item closes the menu and does nothing.** TC-TXM-006 relies on it: the clipboard stays
  what it was set to.
- **Nothing to copy is read by the marker.** A box with nothing in it copies nothing, so "the box is empty"
  is: set the clipboard to a marker, take all of the box and copy, and the marker is still there.
- **The old cases found two faults of the change itself.** The error of a tool, a label before the change, was made a
  read-only text box and, by a slip, set in the monospace font: it is wider than the window's own, broke one
  word earlier ("...at line" and "1 column 5" on two lines) and TC-FMT-012, which reads "line 1", failed. The fix
  is a message that has its own font (`text_menu::read_message`), and a unit test of the app pins the family.
  And the menu of a changed side-by-side line grew (a Copy for each side) and no longer fits under a line near
  the foot of the window, so it opens above the pointer: TC-DIF-010 clicked Copy path 67 px under a pointer at
  y = 490 and hit nothing; it finds the item by OCR there now.
- **The list at the foot of the window is anchored to it**, so the docked run does not move it: the case
  reads its first row from a variable (`${HIT_ROW_1_Y}`) that `resources/docked_main.py` overrides, as
  search.robot does.

## Not reachable

Native Wayland: Paste and Cut are answered by the window system with the event of the key, and the test
display is X. The route is the one Ctrl+V takes in every window, so a desktop where Ctrl+V works has it,
but that is not seen here. Windows and macOS are not tested ([00_test_strategy.md](00_test_strategy.md)); the
app's layout tests check that the keys are written `Cmd+X` there.
