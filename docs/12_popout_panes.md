# Pop-out panes — test requirements

Source: `crates/app/src/dock.rs` (state and layout decisions, unit-tested) and
`App::show`, `App::show_popped_panes`, `App::popped_pane_ui`,
`App::pop_button` in `crates/app/src/app.rs`.

The Query, Source and Results panes each have a small, dim **⬈** icon in the
top right corner of their header (at the far right: right of `Save…` for
Source/Results, right of the engine picker for Query; it lights up under the
pointer) that opens the pane in a **window of its own** — a second native
window of the app, an egui viewport that eframe redraws on its own (so it keeps
working when the main window is hidden behind it). In that window the same icon
reads **⬋** and docks the pane back; closing the window does the same. The main
window gives the room to whatever is
left: the panes below the query bar move up when it leaves; Results fills the
width when Source leaves, and vice versa; with both gone it shows a note and a
button. While any pane is out the toolbar has an extra **🗖** button (left of
the 🛠 Tools button) that docks every window at once — the way back for a
window lost behind others.

The Source pane's window has a **source field of its own** in a row along its
top — the toolbar's `Source:` label, field, `…`, `Load` and `Clear` (and what is
loaded: "(pasted JSON)", the size, an NDJSON note; a failed load is said in red
under the row, since the status bar is in the main window) — since the toolbar's
is in the main window, which the pane has left. It is the same field: one text,
the same loading, so what is typed in one is shown by the other. The toolbar
keeps its field. (The Query and Results windows have no such row.)

The panes' headers — Source's and Results' (and each box's in the Tools window)
— are a small, strong title with its buttons and nothing drawn under them: the
line above the panes is the only divider (a heading would be bigger than the
buttons; the title is smaller).

A pane is the same pane wherever it is shown: its state (the query text, the
trees, scroll positions, the engine choice) is the app's, not the window's, and
its widget ids don't depend on where it is drawn, so scroll positions survive a
move. Keyboard shortcuts work in every window: `Ctrl+Enter` runs the query
from any of them, `Ctrl+F`/`Ctrl+S` act on the tree in the window they are
pressed in, `F1` opens the tutorial. The Find dialog is drawn in the window of
the tree it searches, and a row revealed in a tree that is in its own window
brings that window forward. A file dropped on any window opens.

Also covered headlessly by `crates/app/src/app/layout_tests.rs` and
`dock.rs`'s unit tests (`cargo test`): the layout of every combination, that
docking back restores the layout exactly, that a pane is drawn in exactly one
place each frame (egui asserts otherwise), that scroll position carries over,
shortcut routing, the window placement rules, and where each header's icon sits
(its top right corner, right of the header's own controls; a 16px square that
is clicked anywhere in it and nowhere beside it; a small glyph). A second
harness there (`Windows`) runs the app the way eframe does on a desktop — behind
a lock, each popped pane a deferred viewport redrawn on its own — and checks
that a window takes clicks and typing and docks its own pane without a single
frame of the main window, that the main window then leaves it out, that a click
in a window asks the main window to redraw, and that closing (or docking from)
a maximized or fullscreen window un-maximizes it so that the main window is
uncovered. The same harness checks the Source window's field: that it has one
(and the other windows don't), that text typed in it is the toolbar's text too
(the main window is asked to show it), that Enter and Load open a file and Clear
unloads it with no frame of the main window, that a load that fails is said in
the window and goes with Clear, and that its row has room for
everything it says — in every state (empty, pasted, a file, NDJSON, merged,
patched), at the width the window opens with and at its narrowest. The titles
are checked to be smaller than a heading, with no line under their headers.

**Environment notes for the suite** (`suites/popout/`): the windows are
real X windows. The fluxbox rule that strips decoration matches the app's window
class, so they are undecorated like the main window — a window is closed through
the window manager (`wmctrl -c`, the `Close Window` keyword), not a title-bar
button. `xdotool search --name` can't match the em dash in "jsonquery — Query"
literally (it reads the Latin-1 name), so the library matches it with a wildcard.
`Switch To Window` / `Switch To Main Window` retarget every click and read.

## Test cases

### TC-POP-001 — The Query pane opens in a window of its own
Priority: P1
Steps: click the ⬈ icon at the right end of the query header.
Expected: a window titled `jsonquery — Query` holds the pane (its header reads
`Query:`); in the main window the Source heading is at the top, where the query
bar was.

### TC-POP-002 — A query run from its window shows its results in the main window
Priority: P1
Steps: load a document, pop the Query out, type a query in its window and press
Ctrl+Enter there.
Expected: the main window's status bar reports the run and its Results pane
shows the results.

### TC-POP-003 — The button in the window docks the pane back
Priority: P1
Steps: pop the Query out; click ⬋ in its window.
Expected: the window closes; the main window is as at launch.

### TC-POP-004 — Closing the window docks the pane back
Priority: P1
Steps: pop the Query out; close its window through the window manager.
Expected: as TC-POP-003 — the pane is not lost.

### TC-POP-005 — Source in its own window gives Results the whole width
Priority: P1
Steps: load a document; pop Source out.
Expected: the Source window shows the document's tree; in the main window the
Results heading is at the left edge.

### TC-POP-006 — Results in its own window gives Source the whole width
Priority: P1
Steps: load a document and run a query; pop Results out.
Expected: the Results window shows the results; the main window's Source pane
spans the width, its `Save…` at the far right.

### TC-POP-007 — With Source and Results both out the main window says so
Priority: P1
Steps: pop both out and move their windows aside; read the main window; click
the toolbar's 🗖.
Expected: the main window says "Source and Results are in their own windows"
with a button to bring them back; 🗖 closes both windows and restores the layout.

### TC-POP-008 — The toolbar button docks every window at once
Priority: P2
Steps: pop the Query and Source out; click 🗖.
Expected: both windows close; the main window is as at launch. (The button is
there only while something is out.)

### TC-POP-009 — Find opens in the window of the tree it searches
Priority: P1
Steps: pop Source out; press Ctrl+F in its window.
Expected: the `Search — Source` dialog is in the Source window, not the main one.

### TC-POP-010 — Autocomplete works in the Query window
Priority: P2
Steps: turn autocomplete on, pop the Query out, type `.members[].` in its window.
Expected: the suggestion list (`name`, `age`) is drawn in that window under the
cursor.

### TC-POP-011 — A window reopens where it was left
Priority: P2
Steps: pop Source out, move its window, dock it, pop it out again.
Expected: the window is at the same position and size.

### TC-POP-012 — Closing the main window closes the pop-out windows too
Priority: P2
Steps: pop the Query out; close the main window.
Expected: the Query window goes with it (the app is one process).

### TC-POP-013 — A click in the main window still decides what Ctrl+F searches
Priority: P1
Steps: load a document; pop Source out; click inside the main window's Results
pane; press Ctrl+F there.
Expected: `Search — Results` opens in the main window. (A popped window must
not re-claim "the tree last clicked" on every frame, which would overwrite the
click.)

### TC-POP-014 — A maximized pane window still responds and docks back
Priority: P1
Steps: load a document; pop the Query out and maximize its window (it now
covers the screen, and the main window under it); click in the box, type a
query, press Ctrl+Enter, click ⬋ in the window's corner.
Expected: the typed query is drawn in the window; the window closes and the main
window is as at launch, its status bar reporting the run and its Results pane
showing the results. (Under X this passes with or without the redraw fix — the
bug was Wayland's; see below. It guards the window's own redraw path and the
dock-from-a-maximized-window path on real windows.)

### TC-POP-015 — Closing a maximized pane window docks its pane
Priority: P1
Steps: pop the Query out; maximize its window; close it through the window
manager.
Expected: the window closes and the main window is as at launch.

### TC-POP-016 — The Source window has a source field of its own
Priority: P1
Steps: pop Source out; in its window click the field along the top, type the
path of a fixture file (`people.json`) and press Enter.
Expected: the window's row reads `Source:` above the pane's own header; the file
opens in the window's pane ("3 items"); the main window's toolbar field shows the
same path.

### TC-POP-017 — The Load button in the Source window loads
Priority: P1
Steps: pop Source out; type the path of `people.json` into the window's field and
press **Load** (not Enter).
Expected: the file opens in the window's pane ("3 items").
Note: with nothing loaded the field takes the room the info would have, so the
buttons are further right (`…` x 480, Load x 517, Clear x 562); with something
loaded they are at x 310 / 347 / 391.

### TC-POP-018 — Clear in the Source window unloads the document
Priority: P1
Steps: load `people.json` from the window's field; press **Clear** in its row.
Expected: the pane has nothing again, the window's field is empty, and so is the
main window's toolbar field (one text, shown in both).

### TC-POP-019 — The two Source fields are one text
Priority: P2
Steps: with Source out, type `some-file-name` into the main window's toolbar field.
Expected: the Source window's field shows it too.

### TC-POP-020 — A failed load is said in the Source window
Priority: P1
Steps: type a path that does not exist into the window's field; press Enter.
Expected: a red "Load error: …" line appears under the row, in the window (the
window has no status bar).

### TC-POP-021 — Only the Source window has a source row
Priority: P2
Steps: pop Results out.
Expected: its window starts with its own header, and has no `Source:` row.

### TC-POP-022 — The Source window's row says what is loaded
Priority: P2
Steps: paste a document, then pop Source out.
Expected: the row has "(pasted JSON)" and the size, as the toolbar does.

### TC-POP-023 — The toolbar keeps its Source field while Source is out
Priority: P2
Steps: pop Source out.
Expected: the main window's toolbar still has `Source:` and the field's hint.

### TC-POP-024 — A file loaded from the toolbar shows in the Source window
Priority: P1
Steps: with Source out, enter the path of `people.json` in the main window's
toolbar field and press Enter.
Expected: the Source window's pane shows it ("3 items").

### TC-POP-025 — Docking the Source pane takes the row with it
Priority: P2
Steps: with a document loaded pop Source out, then dock it with the icon in its
header (x 584, y 41 — under the row).
Expected: the window closes, the main window has its layout back (the toolbar's
`Source:` field is the only one).

**Mutation-checked** against the build of the commit before the Source row existed:
TC-POP-011 (the dock icon is lower in this window), 016 to 020, 022, 024 and 025
fail there; 021 and 023 hold in both layouts (they guard against the row spreading).

## Not covered by an automated case

- Native Wayland: the compositor chooses where a popped window opens, and the
  app can't read or set window positions there (`winit`), so a window opens
  wherever the compositor puts it and is not remembered; everything else works.
  The suite runs on X11 only (isolated Xvfb).
- A pane's window maximized (or otherwise placed) over the whole main window, on
  Wayland: GNOME's compositor sends no redraw callbacks to a completely covered
  window, so the main window stops being redrawn, and the pane's window must not
  depend on that (it did while it was drawn inside the main window's frame:
  after maximizing it, nothing in it responded). Not reproducible under Xvfb;
  checked by hand against headless Mutter 50 in a container, with pointer clicks
  injected through its RemoteDesktop API — the clicks reach the covering window.
  TC-POP-014/015 run the same flow under X, and `layout_tests.rs` covers what
  a window's own frame does without the main window's (it takes input and
  applies its own dock request, un-maximizes when it docks, minimizes itself if
  it is not dropped) — but nothing in the repository sees a compositor withhold
  redraw callbacks.
- Backends without native windows: egui shows each pane in a floating window
  inside the main one. That window has no close button — the pane's own ⬋
  button and 🗖 are the way back. Exercised headlessly (the layout tests run
  this path), not in the GUI suite.
