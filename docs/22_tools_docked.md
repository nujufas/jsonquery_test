# Tools docked in the main window — test requirements

Source: `crates/app/src/tools.rs` (`Place`, `Tools::main_tabs`, `request_place` / `apply_place_request`,
`page_in_front`, `show_query`, the `dock_button` and `undock_button`), `App::tab_strip`, `App::status_bar`
and `App::show_with` in `crates/app/src/app.rs` (the row of tabs, the source row, the page in front),
`handle_shortcuts` (Ctrl+Enter, Ctrl+F, Ctrl+S) and `handle_drag_and_drop`, the Tools' branch of
`App::satellite_frame` in `crates/app/src/app/satellites.rs`, and the place in
`crates/app/src/settings/interface.rs`. How the move works is in the app's `docs/architecture.md`, and what a
person sees of it in its `docs/tools.md` ("In a window, or docked in the main window").

The Tools open in a window of their own ("JsonQuery — Tools", see [13_tools_window.md](13_tools_window.md)),
and that is how the app starts: the app is for the query, and its window is as it has always been. They can
also be **docked**: the **⚓** button at the right end of the Tools window's row of tabs puts the same pages
in the **main** window as tabs —

- the row of tabs is the top row of the window: **Json Query**, which is the main view (its first row, under
  the tabs, is the source field, then the query, then Source and Results), then **Merge JSON**, **Format
  JSON**, **Diff JSON**, **Patch JSON** and **Validate Schema**; at its right end the theme and the tutorial
  (the 🛠 button has gone: the tabs are the Tools);
- the page of the tab in front fills the rest, and the status bar says what that page has to say (the
  query's, on the Json Query tab);
- the window is gone, and the page that was in front in it is the one in front now; a page keeps what it
  holds;
- the **🗗** button in the status bar, beside the ⚙ (the status bar reads, from the right, ⓘ 🌐 ⚙ 🗗 — and
  nothing of the four on the row of tabs; the 🌐 is the website's, [23_website.md](23_website.md)), takes the
  Tools out into a window again, on the page that was in front, and is on every tab while the Tools are docked
  and never when they are a window;
- where the Tools are is kept in `settings.json` (`"tools": "docked"`; the window is the default, so nothing
  is written for it), and a docked start has the Json Query tab in front.

Docked, the keys and the drops are the tab in front's: **Ctrl+Enter** runs a tool's page (and the query on the
Json Query tab, as ever), Ctrl+F and Ctrl+S are about a tree and do nothing on a tool's page; a file dropped
on the window goes into the box of the page in front — one file on the Json Query tab is the document,
several go to Merge, and Merge's tab comes to the front. What a tool hands to the main window — a merged or
patched document ("Open in main window"), a problem ("Show in main window"), a tutorial example's data and
query — goes to the Json Query tab, which comes to the front.

## Cases (`suites/tools/tools_docked.robot` and `tools_docked_tutorial.robot`)

Everything is read and clicked in the **main** window, 1200 × 800, Dark theme. The pages of the tools are the
window's pages, in two panes of 600 (the points are `DT_*` in the suite); the Json Query tab is the main view
moved down by the row of tabs, which the test library allows for while `Set Layout Shift` says so (see
[the other suites, docked](#the-other-suites-docked)); `Show Docked Tab` is the way to a tab and sets that
shift for the tab it goes to. The row, the buttons and the status bar are read by their pixels (an icon is
"something bright there", `Icon Should Be At`) and by OCR for the words of the tabs.

| ID | Title | Priority |
|---|---|---|
| TC-DOCK-001 | The Tools Window Has A Button That Docks It In The Main Window | P1 |
| TC-DOCK-002 | The Row Of Tabs Has Json Query First And A Tab For Each Tool | P1 |
| TC-DOCK-003 | The Tool That Was In Front In The Window Is In Front Docked | P1 |
| TC-DOCK-004 | What Was Typed In A Page Is Still There Docked | P1 |
| TC-DOCK-005 | The Theme And The Tutorial Are At The Right End Of The Row Of Tabs | P1 |
| TC-DOCK-006 | The Status Bar Has The Info, The Website, The Settings And The Undock Buttons | P1 |
| TC-DOCK-007 | The Undock Button Is In The Status Bar Whichever Tab Is In Front | P1 |
| TC-DOCK-008 | The Window Has No Undock Button | P1 |
| TC-DOCK-009 | The Undock Button Takes The Tools Out Into A Window | P1 |
| TC-DOCK-010 | Docking And Undocking Again Leaves A Page As It Was | P1 |
| TC-DOCK-011 | The Tools Start As A Window | P1 |
| TC-DOCK-012 | Docked Is Kept For The Next Start | P1 |
| TC-DOCK-013 | A Window Again Is Kept Too | P1 |
| TC-DOCK-014 | A Place The App Does Not Know Starts The Tools As A Window | P2 |
| TC-DOCK-015 | Started Docked The Json Query Tab Is In Front | P1 |
| TC-DOCK-016 | The Json Query Tab Is The Main View With The Source Field Under The Row Of Tabs | P1 |
| TC-DOCK-017 | A Document Is Loaded And Queried In The Json Query Tab | P1 |
| TC-DOCK-018 | The Source Field Loads A File In The Json Query Tab | P1 |
| TC-DOCK-019 | A Visit To A Tool And Back Leaves The Json Query Tab As It Was | P1 |
| TC-DOCK-020 | Each Tool's Tab Shows Its Page | P1 |
| TC-DOCK-021 | Ctrl+Enter On A Tool's Tab Runs The Tool, Not The Query | P1 |
| TC-DOCK-022 | Ctrl+F And Ctrl+S Do Nothing On A Tool's Tab | P2 |
| TC-DOCK-023 | The Status Bar Says What The Tab In Front Has To Say | P1 |
| TC-DOCK-024 | Format Takes The Document Open In The Json Query Tab | P1 |
| TC-DOCK-025 | A Merged Document Opened In The Main Window Is Shown In The Json Query Tab | P1 |
| TC-DOCK-026 | A Patched Document Opened In The Main Window Is Shown In The Json Query Tab | P1 |
| TC-DOCK-027 | A Problem Shown In The Main Window Is Shown In The Json Query Tab | P1 |
| TC-DOCK-028 | A File Dropped On The Json Query Tab Is Opened As The Document | P1 |
| TC-DOCK-029 | A File Dropped On A Tool's Tab Goes Into That Tool's Box | P1 |
| TC-DOCK-030 | Several Files Dropped On The Json Query Tab Go To Merge's Tab | P1 |
| TC-DOCK-031 | The Theme Button In The Row Of Tabs Changes The Theme Of The Page In Front | P2 |
| TC-DOCK-032 | The Settings And The Info Buttons Open Their Windows From A Tool's Tab | P2 |
| TC-DOCK-033 | A Tools Window Maximized Over The Main Window Docks Into It | P1 |
| TC-DOCK-034 | A Docked Diff Compares Two Documents | P2 |
| TC-DOCK-035 | The Tutorial Button In The Row Of Tabs Opens The Tutorial | P1 |
| TC-DOCK-036 | An Example Tried From A Tool's Tab Runs In The Json Query Tab | P1 |
| TC-DOCK-037 | Diff Takes The Document Open In The Json Query Tab As One Of The Two | P1 |
| TC-DOCK-038 | The Document Open In The Json Query Tab Is Patched | P1 |
| TC-DOCK-039 | A Double-Click On A Problem Shows It In The Json Query Tab | P1 |
| TC-DOCK-040 | A Big Merge Result Opened In The Main Window Is A File In The Json Query Tab | P1 |
| TC-DOCK-041 | The Website Button Opens The Site From Whichever Tab Is In Front | P2 |
| TC-DOCK-042 | Use In Validate Docked Shows The Validate Tab | P1 |
| TC-DOCK-043 | Create Schema Takes The Document Open In The Json Query Tab | P2 |
| TC-DOCK-044 | At Its Smallest The Main Window Has Room For Every Tab | P2 |
| TC-DOCK-045 | An Example Of The Tools Tab Is Tried In The Tool's Tab | P1 |

The row has a seventh tab since 2026-10-29, **Create Schema** (centre x = 586 docked, 505 in the Tools
window), and the main window cannot be made narrower than 700 (it was 640), which is what the row of tabs
needs with the theme and the tutorial beside it: TC-DOCK-002 and 020 take the new tab in, TC-DOCK-044 opens
a window kept at 600 wide (it is 700, and Create Schema is whole in it), TC-DOCK-042 and 043 are the page's
links to the others (Use in Validate, Open document) and TC-DOCK-045 is the docked counterpart of the
tutorial's Try it on a tool's lesson (`tutorial_tools.robot`, tagged `window-only`).

## The other suites, docked

The cases above are what only the dock does: the move, the buttons, the places, the keys and the drops, and
what a tool and the Json Query tab do for each other. That every tool still works in a tab, and the main view
still works with a row of tabs over it, is checked by running the other suites **docked**: `./run_docked.sh`
runs two passes (each through `run_parallel.sh`, so a pass has lanes and a merged report), the ordinary
`./run_parallel.sh` being the other half.

| Pass | What runs | How |
|---|---|---|
| **tools** | the cases of the Tools suites (`suites/tools/`), and the few cases of other suites that use the Tools (tag `uses-tools`) | `JQ_TOOLS_PLACE=docked` starts every app with `"tools": "docked"` in its settings, and `JQ_WINDOW_SIZE=900x580` gives the main window the Tools window's size, so a docked page is the window's own **pixel for pixel** (measured: no differing pixel between y 23 and 557, on any of the five pages); `resources/docked_tools.py` gives the tab positions, the title the cases look for (the main window's) and the status line without the four buttons at its right end |
| **main view** | every other suite, with the Json Query tab in front | `JQ_DOCKED_DY=23` has the library move what the suites place under the toolbar down by the row of tabs (`AppLibrary._profile_y`: a point or region that reaches the foot of the window, the status bar and what is anchored to it, stays), and `resources/docked_main.py` says what the move does not make right: the row of tabs is *above* the suites' origin (so its y is negative), the 📖 and 🌙 are in it, the 💡 is in the source row, the source row's buttons are 90 px to the right, the search dialog and the list of hits are where they were (so DY *higher* in the suites' coordinates) |

Of the 648 cases that are not the dock's own, **619 run docked** (151 in the tools pass, 468 in the main-view pass;
`./run_docked.sh --dryrun` prints the counts), and 29 are tagged and left out, each for a stated reason:

- **`window-only`**: the case is about the Tools *window* — the 🛠 button, closing or maximizing the window,
  its default size, several windows open together, a drop on the main window that opens the window (7 cases of
  `tools.robot`, `TC-DND-007`, `TC-SAT-030`, `TC-SAT-031`, `TC-WF-009`). Docked, the same things are
  `TC-DOCK-001` to `TC-DOCK-015`, `TC-DOCK-030`, `TC-DOCK-033`;
- **`main-layout`**: the case reads the main window's own layout (Source, the toolbar's status area) in the
  middle of a tool's case — "Open in main window", "Show in main window", the open document, a single file
  dropped on the main window (13 cases of the Tools suites, `TC-DND-006`, `TC-DND-015`). They are
  `TC-DOCK-024` to `TC-DOCK-030` and `TC-DOCK-037` to `TC-DOCK-039` docked;
- **`uses-tools`** is not a reason to leave a case out but a way to find the cases of other suites that the
  tools pass runs (`TC-DND-006` to `TC-DND-015`, `TC-HDR-010`);
- **`undocked-only`**: the case is about the toolbar, the status bar or the settings file as they are with no tabs
  (3 cases: TC-SET-003 and TC-SET-005 read that no settings file is written by a start, which a docked start does:
  it writes `"tools": "docked"`; TC-WEB-001 reads that nothing is left of the ⚙, which docked is the 🗗's place —
  TC-DOCK-006 reads the docked bar; the pane's button is at the other end of the bar, at the left, in both). Added where
  a docked pass showed it.

## What these cases do not reach

The cases are the whole path through the real window: the click on a real icon, a real window leaving and the
row of tabs appearing in the main window, real keys, a real drop (XDND), a real restart. What is not worth a
case here is covered headlessly in `cargo test` (`crates/app/src/app/layout_tests.rs`, "the Tools, docked in
the main window", and the unit tests of `tools.rs` and `settings/interface.rs`): the exact geometry (the row
of tabs, the source row, the status bar's order of buttons at every window size, the smallest window), that a
page is never drawn in two places in one frame (egui's own debug assertion aborts the test run if it is),
that scroll positions and carets survive a move, Ctrl+Enter and the Alt+arrows by the key events themselves,
and the settings read from a file that has something wrong in it.

## Mutation checks

The cases were checked by breaking the app, one place at a time: each change below is a one-place edit of
`tools.rs` or `app.rs` (a condition, a call removed, two lines swapped), built into a binary of its own
(`target/jq-test-bin/mut-*`, deleted again) and run against the cases meant to notice it; the source was put back
and its hash checked after each. All twenty were killed, each by a failure that shows the difference the change
makes (the window still open, the tab not marked, the setting `None`, the typed query run, the dialog asked for…),
never by an environment error.

| # | The app is changed so that | Killed by |
|---|---|---|
| E01 | the ⚓ does nothing | TC-DOCK-001, 003, 004, 010 |
| E02 | the 🗗 does nothing | TC-DOCK-009, 010, 013 |
| E03 | the place is not kept in `settings.json` | TC-DOCK-012 |
| E04 | a docked start opens on a tool's tab, not Json Query | TC-DOCK-012, 015 |
| E05 | Ctrl+Enter on a tool's tab also runs the query | TC-DOCK-021 |
| E06 | Ctrl+F on a tool's tab opens the search | TC-DOCK-022 (it **survived** the first time: the case looked for the dialog in the Json Query tab's coordinates, which on a tool's tab are partly above the window; it looks where the dialog is now, and has the Json Query tab as its control) |
| E07 | Ctrl+S on a tool's tab asks for a file | TC-DOCK-022 |
| E08 | a file dropped on a tool's tab is the main window's | TC-DOCK-029 |
| E09 | "Open in main window" does not bring the Json Query tab | TC-DOCK-025, 026 |
| E10 | "Show in main window" does not bring the Json Query tab | TC-DOCK-027 |
| E11 | a tutorial example's "Try it" does not bring the Json Query tab | TC-DOCK-036 |
| E12 | a tool's tab shows the query's status text | TC-DOCK-023 |
| E13 | docking from the window brings the Json Query tab, not the tool that was in front | TC-DOCK-003, 004 |
| E14 | the 🗗 is in the status bar of the window too | TC-DOCK-008 |
| E15 | the 🗗 is on the row of tabs as well | TC-DOCK-005 |
| E16 | the row of tabs has no theme button | TC-DOCK-005, 031 |
| E17 | Json Query is the last tab, not the first | TC-DOCK-002 |
| E18 | a tool's tab shows the Json Query tab's panes in place of its page | TC-DOCK-020 |
| E19 | several files dropped on the Json Query tab do not bring Merge's tab to the front | TC-DOCK-025, 030 |
| E20 | a settings file that says docked starts the Tools as a window | TC-DOCK-006, 012, 015 |

## What the runs found

No defect of the app, in the docked suite or in the suites run docked: the five pages are the window's pages
to the pixel, and every case that is not about the window itself passes in a tab (the three runs are in the
matrix's coverage summary). Two things about the app's behaviour are worth knowing, and were left alone:

- the line of the status bar that says what a query did wraps at the full width of the window and the buttons
  at the right end (ⓘ 🌐 ⚙, and docked the 🗗) are drawn over the end of a long message (a refused `to_entries`
  on a file of 270 MB: the error runs under the icons). It is as it was with two icons: the status text
  is laid out first so that it wraps as it always did, and the 🗗 widens the covered corner by 28 px (the 🌐
  by 29);
- docking from the window keeps the position of the line between the two panes that the window had (450 from
  the left: half of the Tools window), while a docked start has two panes of 600; the pages of a docked start
  are as `DT_*` says and those of a window docked while the app runs are the window's, until the line is
  dragged.

What the suites learned: `xdotool` matches a window's title without regard to the case, so after the titles
became `JsonQuery` and `JsonQuery — …` the cases that find a window by its title passed whatever the spelling;
the one that compares the names exactly (TC-SAT-030) failed, and the spelling is now pinned in four cases
(`Window Names Should Include`: TC-WIN-001, TC-POP-001, TC-SAT-030, TC-SET-001). And the Settings window's
footer, which names the file the settings are kept in, wraps when the path is longer than about 58 characters,
so TC-SET-001 and TC-SET-011 read the wrong line when the settings folder was made under a lane's `TMPDIR`
(60 characters or more, under the results folder). The library now makes each launch's settings folder with a
short path, in `/tmp` (`JQ_TEST_HOME_ROOT` names another place), so the cases pass in a lane at any depth.

