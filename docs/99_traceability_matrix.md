# Traceability matrix

Single index of every test case ID defined across `docs/`. Status legend:
`Passing` (implemented, run for real, currently green), `Blocked` (can't be
automated for a confirmed, documented reason — see the note on each), `Not
implemented` (everything else — still just a requirement, usually with a
reason noted).

Full steps/expected-results live in the linked doc — this table is for
coverage tracking, not the source of truth for behavior. Status as of the
third implementation pass (2026-09-05): **10 suites, 91 test cases, all
passing** — `suites/{launch_and_window,opening_sources,query_engines,
toolbar_and_status,tree_view,text_view,context_menus,search,
keyboard_shortcuts,saving}/`. Run any of them, or all of them, via
`run.sh [path]`. (The second pass added the initial 10-suite/74-test
baseline; the third pass added 17 more query-correctness cases to
`query_engines`, below.)

**Status as of 2026-10-20 (last): 29 suites, 760 test cases** — a text has a right-click menu: Cut, Copy, Paste and Select All in a box that can be typed in (the query box, the source field, the box of the empty Source pane, the Find field, every box of the Tools, the field of a line being typed over), Copy and Select All in a text that is only shown (the Text views, the result and the error of a tool), Copy on a message, a link and the lines of a list ([24_text_menus.md](24_text_menus.md)). `suites/text_menus/text_menus.robot` (TC-TXM-001 to 016 and 026), `suites/tools/tools_menus.robot` (TC-TXM-017 to 025) and TC-SAT-049 to 051 are the new cases (29), TC-CTX-007 says what it says now (the query box has a menu), and TC-DIF-010 finds an item of the menu of a line by OCR (the menu grew and opens above the pointer near the foot of the window). The runs, on the debug build: `run_parallel.sh -j 6`, 759 of 760 (TC-DOCK-023, an OCR misreading of `result(s)` as `resulkt{s)`, passes 3 of 3 alone); `run_docked.sh -j 6`, the tools pass 164 of 164 and the main-view pass 524 of 524. 33 faults put into the app one at a time (T1 to T33, in [24_text_menus.md](24_text_menus.md)) were all killed by the case meant for them. **The old cases found a fault in the change**: the error text of a tool had been made a read-only text box in the monospace font (it was a label in the window's own font), which broke the line one word earlier, and TC-FMT-012 failed on it (T33); the app is fixed and a unit test pins the font.

**Status as of 2026-10-20 (later): 27 suites, 731 test cases** — a key that an object has more than once (valid JSON) is compared member by member in Diff JSON, the first with the first and the second with the second, and every member is a line of its column (nujufas/jsonquery_gui#1; the owner chose "pair them in order"): `suites/tools/tools_diff.robot`, TC-DIF-042 to 047 added ([13_tools_window.md](13_tools_window.md)). They pass, in a window of their own (the whole Diff file: 48 of 48, on the second run; on the first three cases failed to start their comparison under load and passed alone) and docked (the Diff cases that do not need the main window: 44 of 44); 9 faults put into the app one at a time were all killed by the case meant for them (G1 to G9). The other Tools suites (tools, format, patch, validate, merge, docked, dialogs: 155 cases) were run whole after the change and pass.

**Status as of 2026-10-20: 27 suites, 725 test cases** — the About window has a **Known issues (N)** header that opens the list of the jq programs that run differently here and makes the window bigger (640 wide, as tall as the list needs), and closing it puts the window back. TC-SAT-040 to 048 (`suites/satellites/`, [14_tutorial_and_about_windows.md](14_tutorial_and_about_windows.md)) are the new cases, and TC-SAT-026 reads the window at 380×330 and 320×330 now (it was 300 high); 10 of 10 passed on the debug build, and 16 mutants of the list and its window were made: 12 are killed, 4 are not, each with its reason in that document (the height cap and the least size cannot be seen on a 900-high display with `xdotool`).

**Status as of 2026-10-19 (later): 27 suites, 716 test cases** — a write into a place that is not there (`.a.b.c = 1` over `{}`), `del`, `scan`, `join`, `from_entries` and `@base64d` answer as jq 1.8.1 does. TC-JQX-099 to 116 (`suites/jq_functions/`, [17_jq_functions.md](17_jq_functions.md)) are the new cases: 18 of 18 passed on the debug build, and 13 mutants of the app (M18 to M30 in that document) are each caught by their cases (the other suites were not run again).

**Status as of 2026-10-19: 27 suites, 698 test cases** — `tonumber`, `fromjson` and `tojson` are the app's own now: text that
is not a number or JSON is one error and no longer a run that never ends, and a result nested thousands of levels deep no longer
closes the app. TC-JQX-090 to 098 (`suites/jq_functions/`, [17_jq_functions.md](17_jq_functions.md)) are the new cases. They were
run on the debug build with the fix, with the other suites that use these functions (`jq_functions`, `query_engines`,
`output_formats`): 152 of 152. The whole suite was not run again, and neither was it run docked.

**Status as of 2026-10-11 (night): 27 suites, 689 test cases, run two ways** — the status bar has a 🌐 between the ⓘ and
the ⚙ that opens https://jsonquery.dev, and the About window has a Website row with a link to it. `suites/website/website.robot`
(TC-WEB-001 to 005, [23_website.md](23_website.md)), TC-SAT-024 to 026 and TC-DOCK-041 are the new cases; the ones that were
there moved with the icons (the ⚙ is at x = 1123 now, the 🗗 at 1095, and the status line that OCR reads stops at 1100). The test
library starts every app with a stand-in for the browser and fails a case whose app handed it an address the case did not ask
about, so no case can reach the browser of whoever runs the suite.

**Status as of 2026-10-11: 26 suites, 680 test cases, run two ways** — the Tools can be docked in the main window as tabs
(Json Query first, then the five tools; ⚓ in the Tools window docks them, 🗗 in the status bar undocks them), and the whole
suite is run with them in their window (the default) and with them docked. `suites/tools/tools_docked.robot` (38 cases)
and `tools_docked_tutorial.robot` (2) are the dock's own, TC-DOCK-001 to 040 ([22_tools_docked.md](22_tools_docked.md)); the
other suites run docked through `./run_docked.sh` without a case changed: the Tools suites with their pages in the tabs of
a main window of the Tools window's size, and every suite of the main view with the Json Query tab in front, the
library moving the points under the toolbar down by the row of tabs. The window titles are `JsonQuery` and `JsonQuery — …`
now (TC-WIN-001, TC-POP-001, TC-SAT-030 and TC-SET-001 pin the spelling), and the five Tools pictures of the app's README
show the ⚓.

**Status as of 2026-10-09 (night): 24 suites, 640 test cases** — a line of the Diff page's side-by-side view is typed over with a
double click now (a single click only picks, so that several lines can be picked), and after a move the view stays where it
was and picks nothing, as it does after a line was typed over: `suites/tools/tools_diff.robot`, TC-DIF-040 and 041 added,
`Type Over Line` and the cases that put a caret in a line double-click ([13_tools_window.md](13_tools_window.md)). The Diff file
passes (42 cases); four more faults put into the app one at a time (J1 to J4) were killed by the case meant for them, and
eleven more by the window tests of the app.

**Status as of 2026-10-09 (later still): 24 suites, 638 test cases** — either column of the Diff page's side-by-side view can be typed
over (a click puts a caret in the line; Enter puts in what was typed, Esc puts the line back; what is not JSON is said and
stays to be put right), and the two arrows of a difference are one over the other in a narrower gutter:
`suites/tools/tools_diff.robot`, TC-DIF-033 to 039 added, the constants and the arrow cases of 026 to 032 moved to the new
gutter, TC-DIF-021 reads a band of the left column ([13_tools_window.md](13_tools_window.md)). The Diff file passes (40 cases);
ten faults put into the app one at a time (H1 to H10) and eight of the old ones were killed by the case meant for them, and
twenty-five more by the unit and window tests of the app.

**Status as of 2026-10-09 (later): 24 suites, 631 test cases** — the Diff page of the Tools window now compares by itself when
the tab of a view is pressed, has two arrows between the columns at every difference, lets lines be picked so that only
they are moved, and has a Save… over each column for the document that a move changed: `suites/tools/tools_diff.robot`,
TC-DIF-024 to 032 added, TC-DIF-010 rewritten (a click picks a line now; its menu copies the path), TC-TWIN-007 reads
the columns apart ([13_tools_window.md](13_tools_window.md)). The Diff file passes (33 cases); thirteen faults put into the
app one at a time were each killed by the case meant for it (one needed its case changed first), and twenty more by the unit
and window tests of the app.

**Status as of 2026-10-09: 24 suites, 622 test cases** — a Merge whose result is as big as a file is
kept on disk from is written to a temporary file that has no name and kept there (the app, not the
website): `suites/tools/tools_merge_big.robot`, TC-MRG-040 to TC-MRG-045 ([13_tools_window.md](13_tools_window.md)).
All six passed at the first run of the debug build. Two faults put into the app on purpose (a result never
written to a file, a result always written to one) were each caught by the cases for them, the second only after
TC-MRG-041 was given a temporary folder that is not there: it survived all six at first (table in
[13_tools_window.md](13_tools_window.md)). The rest of `suites/tools/` was run again with them (146 of 146 passed,
a debug build); of the other suites only the case that reads the tooltip of the limit the merge now shares
(TC-SET-014) was.

**Status as of 2026-10-07: 23 suites, 616 test cases** — the Settings window was made small: one limit
shown (from what size a file is kept on disk), the other eight under an Advanced header that opens inside the
window (which grows to hold them), the explanations as tooltips. `suites/settings/` was recalibrated for it
(TC-SET-001 to 012) and gained TC-SET-013 to 016 (Advanced shut at first and the window following it; a
tooltip read by OCR; the count of limits changed under Advanced; a window opened with many complaints in it).
The last run of the suite (23 cases, the debug build): **23 of 23 passed**, as did the unit tests of the
app (372), clippy and fmt. The first run of the recalibrated suite had passed 13 of 22, for two reasons found
in the saved screenshots, both of the cases and not of the app: fluxbox opens a window at the pointer, here the
corner of the screen, so a window that had grown had its lower rows off the display (the suite now moves the
window clear of the corner); and a box 78 px wide left too little room for OCR to read a value with the
outline a hovered box has (the box is 90 px again, and the suite takes the pointer off it after typing).
Nine one-place mutants of the new behaviour were each killed by the case meant for it (table in
[21_settings.md](21_settings.md)); one of them, a window that does not grow for the complaints it opens with,
survived TC-SET-011 (two complaints are too few to hide the header) and is why TC-SET-016 exists. The rest
of the suites were not run again: none of them opens the Settings window.

**Status as of 2026-10-06, late: 23 suites, 612 test cases** — the 593 below plus the 19 of the new
suite `settings` (the ⚙ Settings window and what the app keeps between runs, in
[21_settings.md](21_settings.md)); each case starts the app with a settings folder of its own, so none
sees what another left, nor the settings of whoever runs the suite (`JSONQUERY_HOME`, see "Isolation"
in [00_test_strategy.md](00_test_strategy.md)). The new suite was mutation-checked with 16 source
mutants, every one killed by the cases meant for it, which also showed a check that was too early
(TC-SET-023) and a half of the behaviour no case covered (the panes coming back, now TC-SET-026).
The last full run (`run_parallel.sh`, four lanes, 22 minutes, the debug build of the app with the
Settings): **611 of 612 passed**; the one failure was an OCR misread of the URL typed into the source
field (TC-OPEN-003, `vaLlid. json`), which passed five times in a row when run on its own. The run
before it, on the same build, passed 610: TC-DIF-007 (a torn repaint under load; passed twice on its
own) and TC-QRY-012, which was the app's doing — the ⚙ added beside the ⓘ in the status bar made
Tesseract read `[JSONPath` as `SSONPath` in the full-width status region (either icon alone was
harmless, found by replaying the saved screenshot), so `@{STATUS_BAR}` now stops short of the icons;
TC-QRY-012 then passed five of five.

**Status as of 2026-10-06, before that: 22 suites, 593 test cases** — the 369 of the evening
before plus 224: the new suites `jq_functions` (49), `output_formats` (55), `tutorial_pages`
(50) and `workflows` (10), and cases added to `opening_sources` (+9 for the file dialogs, +14 for heavy files, pipes, downloads and files kept on disk, in `heavy_files.robot`), `saving` (+21), `tools`
(+9, `tools_dialogs`, +1 for Format on a file kept on disk) and `autocomplete` (+6). The last full run (`run_parallel.sh`, four lanes, 21 minutes, a fresh build of the app) passed: 593 of 593. (The one before that, 588 of 588, was before the sorting, the guard against a file cut short, JSONPath and JMESPath, repeated keys and Format on disk; the one before the cases for the files that are kept on disk, five lanes and 18 minutes, had passed 578 of 578; the run before that had passed 577, the one failure being an OCR misread of a URL in TC-TOOL-001, which now reads the field through the clipboard.) Nothing is **Blocked** any more:
the file dialogs are answered by a stand-in for the desktop's file-chooser portal
(`resources/fake_portal.py`, see "Native OS dialogs" in
[00_test_strategy.md](00_test_strategy.md)), which turned the 13 rows that were Blocked into
Passing (TC-SAVE-008, a race, stays Not implemented). The new areas were mutation-checked with
23 source mutants, every one killed by the cases meant for it; see each feature doc. One finding
is open, as TC-SAVE-011 (Save… pressed while a query is still running writes only the results
that had arrived; see [09_saving.md](09_saving.md)).

**Status as of 2026-10-04 (evening): 18 suites, 369 test cases** (the original ten
and `autocomplete`, `query_highlight`, `query_box_layout`, `popout`, then the new
`tools` (130), `satellites` (20), `pane_headers` (10) and `drag_and_drop` (18)),
365 passed in the last full run — five parallel lanes on a frozen copy of the
binary, see `README.md`; the other four passed when run on their own right
after (TC-AC-058, whose OCR read was fixed that afternoon, and TC-DND-016/017/018,
added while the run was going). After the Tools window was redesigned, the panes'
headers made smaller (everything under them 12px higher; the hit-list panel 9px)
and the Source window given a row, every fixed region and click point was
recalibrated from screenshots (`keywords.resource`, `tools.resource`,
`suites/{search,tree_view,text_view,context_menus,popout}`), and TC-AC-058 reads
its popup with `--psm 4` (the page layout analysis read the selected row as "a"
once the tree's rows sat right under the popup). New areas were mutation-checked
(11 source mutants plus the build of the commit before the change); see each
feature doc.

## Launch and window — [01_launch_and_window.md](01_launch_and_window.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-WIN-001 | Default launch state | P1 | **Passing** | `suites/launch_and_window/` |
| TC-WIN-002 | Theme toggle Dark↔Light | P2 | **Passing** | `suites/launch_and_window/` |
| TC-WIN-003 | Empty-state placeholder text | P2 | **Passing** (partial — see note) | `suites/launch_and_window/` |
| TC-WIN-004 | Minimum window size enforced | P3 | Not implemented — no window border to drag under fluxbox's `Deco: NONE` (required elsewhere for accurate window-origin coordinates), and a direct `xdotool windowsize` bypasses winit's advisory min-size hint rather than exercising it (confirmed: shrank the window to 200x100 with no pushback) | `suites/launch_and_window/` |
| TC-WIN-005 | No About/Help/menu bar exists | P3 | **Passing** | `suites/launch_and_window/` |

TC-WIN-003 note: only checks the placeholder text, not the full hint sentence
above it — that line is styled in the app's dim "weak" gray, which OCR
couldn't reliably read even with contrast/inversion preprocessing (confirmed
during implementation; see 00_test_strategy.md's OCR limitations note).

## Opening sources — [02_opening_sources.md](02_opening_sources.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-OPEN-001 | Open valid file via dialog | P1 | **Passing** — the dialog is answered by the stand-in portal (`resources/fake_portal.py`) | `suites/opening_sources/` |
| TC-OPEN-002 | File dialog extension filter | P2 | **Passing** — the filters the app sends are read back from the stand-in | `suites/opening_sources/` |
| TC-OPEN-003 | Open via URL typed into the source field | P1 | **Passing** (local fixture HTTP server, not the public internet) | `suites/opening_sources/` |
| TC-OPEN-004 | Load disabled while the source field is blank | P3 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-005 | URL: request failure | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-006 | URL: non-JSON response | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-007 | URL: oversized download rejected | P3 | Not implemented — would need serving an actual 4+ GiB response; not attempted | `suites/opening_sources/` |
| TC-OPEN-008 | Paste auto-loads on Ctrl+V | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-009 | Paste loads via Ctrl+Enter | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-010 | Drag-and-drop opens a file | P3 (skip on Wayland) | **Passing** — by cross-reference to TC-DND-001 to TC-DND-005: the harness has a real XDND source now (`resources/xdnd.py`, `Drop Files On Window`) | `suites/drag_and_drop/` |
| TC-OPEN-011 | Drop-hover overlay only when empty | P3 (skip on Wayland) | **Passing** — by cross-reference to TC-DND-016 to TC-DND-018 (`Start Hovering Files` holds a drag over the window) | `suites/drag_and_drop/` |
| TC-OPEN-012 | NDJSON wraps into one array | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-013 | Empty file loads as empty array | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-014 | Malformed JSON load error | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-015 | New source replaces old, cancels query | P2 | **Passing** (second load via the source field, not a second paste — see note below) | `suites/opening_sources/` |
| TC-OPEN-016 | Clear resets state, preserves query/engine | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-017 | Clear disabled with nothing to clear | P3 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-018 | Load button loads the source field | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-019 | Typed local path loads that file | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-020 | Missing path: load error, text kept | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-021 | Clear empties typed-but-unloaded text | P3 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-022 | Closing The Dialog Loads Nothing | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-023 | A File Chosen Replaces The Document On Show | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-024 | A Line-Delimited File Becomes One Array | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-025 | A File That Is Not JSON Shows A Load Error | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-026 | A File Chosen Can Be Queried At Once | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-027 | Choosing A File Twice Loads The Second | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-028 | Each Press Asks The Dialog Once | P3 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-029 | A File Past The Indexing Size Opens Like Any Other | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-030 | A Named Pipe Opens With What Is Written To It | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-031 | A Small Download Leaves Nothing In The Temp Folder | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-032 | A Large Download Leaves Nothing In The Temp Folder | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-033 | A File Past The Indexing Size Is Not Held In Memory | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-034 | A Long List Of A File Kept On Disk Is Shown In Runs | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-035 | A Query Reads A File Kept On Disk As It Goes | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-036 | A Query That Needs All Of A Long List As A Value Says So | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-037 | JSONPath And JMESPath Read A File Kept On Disk | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-038 | A File Below The Indexing Size Is Parsed | P2 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-039 | A File Cut Short While It Is Open Does Not Close The App | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-040 | A Long List Is Sorted And Grouped Where It Lies | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-041 | An Expression Of Parts And A Search Down Through Everything Are Run On A File Kept On Disk | P1 | **Passing** | `suites/opening_sources/` |
| TC-OPEN-042 | A Key Repeated In An Object Of A File Kept On Disk Is Shown Once | P2 | **Passing** | `suites/opening_sources/` |

**Confirmed during implementation, worth flagging for anyone extending this
suite**: pasting only loads anything while the empty-state "Paste JSON
here…" box is showing. Once a document is loaded, that box no longer exists
to paste into, and Ctrl+V does nothing — there's no global paste-to-replace
shortcut. TC-OPEN-015 and TC-TOOL-004 both need a *second* load over an
already-loaded document, so both use `Load Via Url` (the toolbar's source
field, unconditionally available) instead of a second paste.

## Toolbar and status bar — [03_toolbar_and_status_bar.md](03_toolbar_and_status_bar.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-TOOL-001 | Source label by source kind | P2 | **Passing** | `suites/toolbar_and_status/` |
| TC-TOOL-002 | Byte size human-readable | P3 | **Passing** | `suites/toolbar_and_status/` |
| TC-TOOL-003 | NDJSON suffix conditional | P3 | **Passing** | `suites/toolbar_and_status/` |
| TC-TOOL-004 | Status area mutual exclusivity | P2 | **Passing** — retitled to what's actually true: "Parsed in…" and a *new* "Load error" coexist (the still-loaded document's own state isn't clobbered by an unrelated failed reload), not "the two are mutually exclusive" (they aren't — see note below) | `suites/toolbar_and_status/` |
| TC-TOOL-005 | Parse-time text conditional | P3 | **Passing** | `suites/toolbar_and_status/` |
| TC-TOOL-006 | Save success/error mutual exclusivity | P2 | **Passing** — a save to a folder that is not there, then one that works (the dialog is answered by the stand-in portal) | `suites/saving/` |
| TC-TOOL-007a-d | Query-outcome line format variants | P1 | **Passing** (covered collectively by `query_engines`'s status-bar assertions — normal count, query error, item-error count, engine-suffix "auto" vs explicit — rather than as one dedicated data-driven case here) | `suites/toolbar_and_status/` |
| TC-TOOL-008 | Item-error count display | P2 | **Passing** (covered by TC-QRY-020) | `suites/query_engines/` |
| TC-TOOL-009 | Find-in-Source status placement | P3 | **Passing** (covered by TC-SRCH-020/021's status-bar checks) | `suites/search/` |

**Confirmed during implementation**: "Parsed in…", "Load error: …", and
"Save error: …"/"Saved to …" all render in the **bottom status bar**
(`@{STATUS_BAR}`), not the toolbar's own source-label row
(`@{STATUS_AREA}`) — an easy mix-up since both sit near text describing the
loaded document. TC-TOOL-004's original framing ("mutual exclusivity")
doesn't hold: a load error only ever describes the *attempt*, so the
previously-loaded document's own "Parsed in…" keeps showing right alongside
the new error rather than either one replacing the other — retitled and
reimplemented to assert the true (and more interesting) behavior instead of
a false expectation.

## Query bar and engines — [04_query_bar_and_engines.md](04_query_bar_and_engines.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-QRY-001 | Picker order/tooltips | P2 | **Passing** (order only — tooltip hover text not checked, low value/high flake risk for a hover-triggered popup) | `suites/query_engines/` |
| TC-QRY-002 | Explicit select/deselect toggling | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-003 | Query box hint text | P3 | **Passing** | `suites/query_engines/` |
| TC-QRY-010 | Auto-detect: `.`/empty → jq | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-011 | Auto-detect: `/` → Pointer | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-012 | Auto-detect: `$` → JSONPath | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-013 | Auto-detect: `[?`/`&&`/`\|\|`/backtick → JMESPath | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-014 | Auto-detect: bare identifier fallback to jq | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-020 | jq streams, per-item errors non-fatal | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-021 | jq parse vs. compile error text | P2 | **Passing** (split into TC-QRY-021a/021b — see note) | `suites/query_engines/` |
| TC-QRY-022 | jq Cancel + settle race | P2 | Not implemented — a genuine cancel-mid-flight race is too timing-dependent to assert reliably against real wall-clock query latency in this harness | `suites/query_engines/` |
| TC-QRY-023 | jq: select/filter/project excludes non-matches | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-024 | jq: per-item field projection streams N results | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-025 | jq: `length` reduces to one scalar result | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-026 | jq: `sort_by` then index picks the expected item | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-027 | jq: array construction + `add` aggregates a field | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-030 | Pointer: 0-or-1 result | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-031 | Pointer: malformed syntax error | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-032 | Pointer: unresolvable is query error, not empty | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-033 | Pointer: empty pointer = whole doc | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-034 | Pointer: resolves a field under a non-zero index | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-035 | Pointer: resolves a numeric field | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-036 | Pointer: can resolve to a whole object, not just a leaf | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-040 | JSONPath: 0 matches not an error | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-041 | JSONPath: multi-match + syntax error | P1 | **Passing** (split into TC-QRY-041a/041b) | `suites/query_engines/` |
| TC-QRY-042 | JSONPath: `?()` filter excludes non-matches | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-043 | JSONPath: recursive descent (`..name`) | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-044 | JSONPath: compound `&&` filter across two fields | P2 | **Passing** (rewritten to avoid a literal `<` — see note) | `suites/query_engines/` |
| TC-QRY-045 | JSONPath: index union (`[0,2]`) selects specific elements | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-050 | JMESPath: always exactly 1 result (incl. null) | P1 | **Passing** | `suites/query_engines/` |
| TC-QRY-051 | JMESPath: parse vs. runtime error text | P2 | **Passing** (parse-error half only) | `suites/query_engines/` |
| TC-QRY-052 | JMESPath: projection collects a field into one array result | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-053 | JMESPath: backtick-literal filter piped into an index | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-054 | JMESPath: raw string literals + logical OR in a filter | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-055 | JMESPath: `length()` function aggregates to a scalar | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-056 | JMESPath: `max_by` with an expression-reference argument | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-060 | Run disabled with no doc | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-061 | Ctrl+Enter global (cross-ref TC-KEY-001) | P2 | **Passing** | `suites/query_engines/` |
| TC-QRY-062 | 50,000-item cap, true vs. shown count | P3 | Not implemented — constructing and iterating a 50,000+ item fixture through OCR-paced assertions is slow and adds a lot of suite runtime for one P3 case | `suites/query_engines/` |
| TC-QRY-070 | Query highlighting: jq steps tinted in palette order | P2 | **Passing** | `suites/query_highlight/` |
| TC-QRY-071 | Query highlighting: pipes and operators stay plain | P2 | **Passing** | `suites/query_highlight/` |
| TC-QRY-072 | Query highlighting: Pointer segments each tinted | P2 | **Passing** | `suites/query_highlight/` |
| TC-QRY-073 | Query highlighting: half-typed query still tinted | P2 | **Passing** | `suites/query_highlight/` |
| TC-QRY-074 | Query highlighting: engine picker changes the split | P2 | **Passing** | `suites/query_highlight/` |
| TC-QRY-075 | Query highlighting: a call inside a call gets its own tint; closer matches opener | P2 | **Passing** | `suites/query_highlight/` |
| TC-QRY-076 | Query highlighting: a call with no sub-function stays one chip | P2 | **Passing** | `suites/query_highlight/` |
| TC-QRY-080 | Query box: a long query scrolls inside it instead of taking over the window | P1 | **Passing** | `suites/query_box_layout/` |
| TC-QRY-081 | Query box: a dragged panel height sticks for a long query (taller and shorter) | P1 | **Passing** | `suites/query_box_layout/` |
| TC-QRY-082 | Query box: the panel stops at its minimum height | P2 | **Passing** | `suites/query_box_layout/` |
| TC-QRY-083 | Query box: typing at the end of a long query keeps the cursor in view | P1 | **Passing** | `suites/query_box_layout/` |
| TC-QRY-084 | Query box: the mouse wheel scrolls a long query | P2 | **Passing** | `suites/query_box_layout/` |
| TC-QRY-085 | Query box: a short query behaves as before | P2 | **Passing** | `suites/query_box_layout/` |

**Confirmed during implementation, two OCR-specific limitations worth
knowing before touching this suite again**: Tesseract sometimes reads the
2-character "jq" label as "iq", and a leading digit `0` (as in "0 result(s)")
sometimes reads as the letter "O" — both at this font size specifically.
`AppLibrary._text_contains` now has a permissive 0/O fallback for the
latter; the former is worked around in TC-QRY-014 by ruling out the other
three engine names rather than asserting "jq" itself. TC-QRY-021 and
TC-QRY-041 were each split into an `a`/`b` pair of test cases rather than
two `Run Query` calls in one test: a second `Run Query` in the same test
risks its own `Wait Until Region Matches` trivially matching *stale* text
left over from the first run's outcome before the second one actually
finishes (the same staleness trap documented for `Load Fixture Via Paste`
below) — separate test cases sidestep it entirely by giving each a fresh
app/status bar.

**Confirmed during the third implementation pass (adding TC-QRY-023–027,
034–036, 042–045, 052–056)**: typing a literal `<` character through this
harness's synthetic-input path (`pyautogui.typewrite`, used by `Type Text`)
is unreliable in this environment — confirmed via a saved screenshot that a
query typed as `$[?(@.age > 20 && @.age < 40)].name` actually landed in the
query box as `@.age > 40` (the `<` silently became `>`), producing a
different-but-still-valid single-match result that passed the
`Wait Until Region Matches` gate without ever retrying. This is the same
general class of synthetic-input flakiness documented elsewhere in this
suite, but notable because it's a silent *content* corruption rather than a
dropped/no-op keystroke, so the existing "retry until the status bar
pattern matches" mitigation doesn't catch it. TC-QRY-044 (JSONPath compound
`&&` filter) was written to test two conditions on two different fields
(`@.age > 20 && @.role == 'engineer'`) instead of a second `<`/`>` bound on
the same field, sidestepping the problem entirely; no other new case types a
literal `<`. Worth checking for if a future case needs one.

## Tree view — [05_tree_view.md](05_tree_view.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-TREE-001 | Row rendering per value kind | P1 | **Passing** | `suites/tree_view/` |
| TC-TREE-002 | Expand/collapse (arrow + double-click) | P1 | **Passing** | `suites/tree_view/` |
| TC-TREE-003 | Root-only-expanded default on fresh load/query | P2 | **Passing** | `suites/tree_view/` |
| TC-TREE-004 | Streamed results preserve expand state | P3 | Not implemented — needs catching a query mid-stream, too timing-dependent to assert reliably | `suites/tree_view/` |
| TC-TREE-005 | Virtualized scroll correctness at scale | P2 | **Passing** (targets row 197 of a 200-row list, not literally the last row — see note) | `suites/tree_view/` |
| TC-TREE-006 | Highlight + centered scroll on reveal | P2 | **Passing** (covered by TC-SRCH-020, same underlying `TreeView::reveal` — not duplicated here) | `suites/search/` |

TC-TREE-005 note: row 199 (the true last row) is confirmed to scroll to
within a few pixels of fully visible but not quite — OCR can't read it at
that position even after the scroll area maxes out. Row 197 is the last row
confirmed to scroll fully into view, so it's the target instead; the test
still meaningfully proves scrolling works (initial viewport tops out around
row 27).

## Text view — [06_text_view.md](06_text_view.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-TXT-001 | Tree/Text toggle independent per panel | P1 | **Passing** | `suites/text_view/` |
| TC-TXT-002 | Long lines unwrapped, horizontal scroll | P3 | Not implemented — needs a scroll-position assertion, fragile against exact pixel offsets | `suites/text_view/` |
| TC-TXT-003 | "Rendering…" transient indicator | P3 | Not implemented — a genuinely sub-frame transient state, not reliably catchable | `suites/text_view/` |
| TC-TXT-004 | 20,000-node budget notice | P2 | **Passing** (25,000-element array via URL, since paste's Text view is unbounded by design) | `suites/text_view/` |
| TC-TXT-005 | No re-render on unrelated changes | P3 | Not implemented — would need to observe the *absence* of a worker round-trip, not practical from outside the process | `suites/text_view/` |
| TC-TXT-006 | Editable paste Text view: Apply | P1 | **Passing** | `suites/text_view/` |
| TC-TXT-007 | Ctrl+Enter applies | P2 | **Passing** | `suites/text_view/` |
| TC-TXT-008 | Apply with invalid JSON → load error | P2 | **Passing** | `suites/text_view/` |
| TC-TXT-009 | File/URL Text view is read-only | P2 | **Passing** | `suites/text_view/` |
| TC-TXT-010 | Apply disabled when buffer blank | P3 | **Passing** | `suites/text_view/` |

**Confirmed during implementation**: clicking the Text tab only switches
view mode — it does *not* focus the textarea itself. `Press Ctrl+Enter`
only fires when the textarea `has_focus()`, so a test needs an explicit
click *into* the textarea (not just its tab) right before pressing it, or
the shortcut silently does nothing (easy to miss since `Click Apply Button`
has no such requirement — only the Ctrl+Enter path is focus-gated this way).

## Context menus — [07_context_menus.md](07_context_menus.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-CTX-001 | Menu contents/order, Source row | P1 | **Passing** | `suites/context_menus/` |
| TC-CTX-002 | Menu contents/order, Results row | P1 | **Passing** | `suites/context_menus/` |
| TC-CTX-003 | Copy JSON Path → clipboard | P1 | **Passing** | `suites/context_menus/` |
| TC-CTX-004 | Save… (single row) — cross-ref TC-SAVE-003/004 | P1 | **Passing** (covered by TC-SAVE-003a/b/c and TC-SAVE-004a/b/c, which choose the menu item and read the file) | `suites/saving/` |
| TC-CTX-005 | Find in Source availability — cross-ref TC-SRCH-020+ | P1 | **Passing** (covered by TC-CTX-001's negative half + TC-CTX-002's positive half — no separate test needed) | `suites/context_menus/` |
| TC-CTX-006 | Search… scoping by tree | P2 | **Passing** | `suites/context_menus/` |
| TC-CTX-007 | No Row Menu Appears Outside Any Tree Row, And No Menu On A Header Or A Button | P3 | **Passing** | `suites/context_menus/` |

**Confirmed during implementation**: a right-click occasionally doesn't
register on the first attempt (the same class of synthetic-input flakiness
documented for Ctrl+Enter elsewhere) — `Open Row Context Menu` retries the
right-click itself (up to 3x) until the menu's "Save…" item is actually
visible, rather than assuming one right-click always opens it.

## Search and Find in Source — [08_search_and_find_in_source.md](08_search_and_find_in_source.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-SRCH-001 | Dialog fields/buttons (Find, Find All, Cancel) | P2 | **Passing** | `suites/search/` |
| TC-SRCH-002 | Case-insensitive substring over keys+values (found, stepped, highlighted) | P1 | **Passing** | `suites/search/` |
| TC-SRCH-003 | Regex mode + invalid-pattern error | P2 | **Passing** (split into TC-SRCH-003a/003b) | `suites/search/` |
| TC-SRCH-004 | Results panel header format/states/Close (Find All; zero-hit case checked via absence of a hit line, not the weak-styled "No matches found." text itself — see note) | P2 | **Passing** | `suites/search/` |
| TC-SRCH-005 | Hit line format + click-to-reveal | P1 | **Passing** | `suites/search/` |
| TC-SRCH-006 | 5,000-match cap, no notice shown | P3 | Not implemented — constructing a 5,000+-match fixture for one P3 case wasn't worth the added suite runtime | `suites/search/` |
| TC-SRCH-007 | Search invalidated by new load/query/Clear | P3 | **Passing** (Clear sub-case only, as TC-SRCH-007c for the list and 007d for the dialog status — the new-load/new-query sub-cases weren't implemented: distinguishing "invalidated" from "just not re-shown yet" reliably needs more than this harness's coarse OCR checks) | `suites/search/` |
| TC-SRCH-020 | Find in Source: single exact hit revealed directly | P1 | **Passing** | `suites/search/` |
| TC-SRCH-021 | Find in Source: not-found (non-error) | P1 | **Passing** | `suites/search/` |
| TC-SRCH-022 | Unavailable on Source rows — cross-ref TC-CTX-001 | P2 | **Passing** (covered by TC-CTX-001 — duplicate by design, no separate test) | `suites/context_menus/` |
| TC-SRCH-023 | Find in Source: several hits listed, best selected + revealed | P1 | **Passing** | `suites/search/` |
| TC-SRCH-024 | Find in Source: clicking another candidate moves selection + reveal | P1 | **Passing** | `suites/search/` |
| TC-SRCH-025 | Find in Source: transformed string falls back to text search, listed only | P1 | **Passing** | `suites/search/` |
| TC-SRCH-026 | A new Search (Find All) replaces a Find in Source list | P3 | **Passing** | `suites/search/` |
| TC-SRCH-027 | Find in Source: nested key/value row lists its same-key matches, nth selected | P1 | **Passing** | `suites/search/` |
| TC-SRCH-028 | Find in Source: nested row's other match picked from the list | P1 | **Passing** | `suites/search/` |
| TC-SRCH-029 | Find in Source: nested row whose key picks out one node jumps to it | P1 | **Passing** | `suites/search/` |
| TC-SRCH-030 | Ctrl+F puts the cursor in the Find field | P1 | **Passing** | `suites/search/` |
| TC-SRCH-031 | Search… from a row's context menu focuses the field too | P1 | **Passing** | `suites/search/` |
| TC-SRCH-032 | Find steps through matches one by one, and wraps | P1 | **Passing** | `suites/search/` |
| TC-SRCH-033 | Enter repeats Find, field keeps focus | P1 | **Passing** | `suites/search/` |
| TC-SRCH-034 | Changing the text starts again at the first match | P2 | **Passing** | `suites/search/` |
| TC-SRCH-035 | Escape closes the dialog | P2 | **Passing** | `suites/search/` |
| TC-SRCH-036 | Ctrl+F on an open dialog selects its text | P2 | **Passing** | `suites/search/` |
| TC-SRCH-037 | The Find in Source panel closes | P3 | **Passing** | `suites/search/` |
| TC-SRCH-038 | Enter still finds after ticking the Regex box | P2 | **Passing** | `suites/search/` |
| TC-SRCH-039 | Find with no match reported in the dialog (not an error) | P2 | **Passing** | `suites/search/` |
| TC-SRCH-040 | Find reveals the match in its tree | P1 | **Passing** | `suites/search/` |
| TC-SRCH-041 | Find leaves a Find in Source list in place | P3 | **Passing** | `suites/search/` |
| TC-SRCH-042 | Find All lists every match, dialog stays open, nothing revealed | P1 | **Passing** | `suites/search/` |
| TC-SRCH-043 | Clicking a Find All entry reveals it; Find carries on from it | P1 | **Passing** | `suites/search/` |
| TC-SRCH-044 | Find moves the highlight in a Find All list | P2 | **Passing** | `suites/search/` |
| TC-SRCH-045 | Find All over Results lists Results rows | P2 | **Passing** | `suites/search/` |
| TC-SRCH-046 | Find All with an invalid regex reported in the dialog | P2 | **Passing** | `suites/search/` |

**Confirmed during implementation, the two biggest findings in this whole
second pass**: (1) the bottom search-results panel **sizes itself to its
content** rather than staying a fixed height — a panel showing one hit renders
its header at a visibly different y-position (~609) than a bare "No matches
found." panel (~739). Every fixed-y-coordinate region/click point for this
panel was replaced with one wide `@{SEARCH_RESULTS_AREA}` region (OCR'd as a
whole) plus `Click Text In Region`-based lookups for "Close" and hit lines,
rather than coordinates calibrated against only one content size. (2) A
region cropped *too tightly* to a single line of text (the original
26px-tall header-only region) made Tesseract's layout analysis fail
outright — pure noise, not just a bad-but-legible read — confirmed by
feeding the exact same screenshot through `pytesseract` at several PSM
modes and getting garbage every time, then adding ~15px of vertical margin
and getting a clean read at every PSM mode tried. The match-count text
itself ("N match(es)") and "No matches found." are both `ui.weak()`-styled
(low contrast) and confirmed unreliable for OCR independent of region
size — assertions check hit-list content or the normal-contrast heading
text instead. TC-SRCH-005's hit-line click also can't target "Alice" by
itself: the heading above it echoes the search term in the same wide
region ("Search results — Source "Alice""), so clicking the first
OCR-found "Alice" can land on that (non-clickable) heading instead of the
hit line below it — clicking ".name" (unique to the hit line) instead.

**Find dialog (TC-SRCH-001–003, 007d, 030–040, 042–046)**: `Find` reports in the
dialog itself, so its checks read the status line under the buttons ("N of M",
"N matches", "No matches found.", "Search error") — deliberately normal-contrast,
not weak — and check *which* tree row is highlighted by pixel (a revealed row is
exactly where OCR drops text). The status crop is 22px, no taller than its one
line: a crop reaching the dialog's bottom border read "1 of 4" as "oF 4 |"
(missing digit), while the tight one reads "10f 4", which the library's 0/O and
whitespace fallbacks still match. `Search For` (Find) waits on *any digit or
word* for the same reason — a retry after a Find that had in fact registered
presses Find again and steps on to the next match. `Find All For` has no such
hazard (repeating a Find All lists the same matches again), and waits on the
panel's "Search results" heading. List-entry highlights are checked by pixel at
fixed row positions (628, 646, 664, 682 — 18px stride; 9px higher since the hit-list panel's header lost its separator, 2026-10-04) against a plain point at
y=750. Reading the Find field itself is unreliable (the text cursor after the
last character garbles it), so TC-SRCH-030/031 use the Find button un-dimming as
the sign that the text landed.

## Saving — [09_saving.md](09_saving.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-SAVE-001 | Source header Save…, default filenames by source kind | P1 | **Passing** — TC-SAVE-001a (file), 001b (paste), 001c (URL); the name the dialog offers, its file type and the file written are all read | `suites/saving/` |
| TC-SAVE-002 | Source Save… available regardless of query state | P3 | **Passing** — the label's colour (TC-SAVE-002) and the dialog opening (TC-SAVE-002a) | `suites/saving/` |
| TC-SAVE-003 | Source row Save…, per-kind default filename | P1 | **Passing** — TC-SAVE-003a (`{key}.json`), 003b (`item_N.json`), 003c (root, `data.json`) | `suites/saving/` |
| TC-SAVE-004 | Results row Save…, `results.json` fallback | P2 | **Passing** — TC-SAVE-004a/b/c | `suites/saving/` |
| TC-SAVE-005 | Results header Save…, disabled-when-empty | P1 | **Passing** — the colour of the label (TC-SAVE-005) and, with the dialog, TC-SAVE-005a (the results array is written) and 005b (no results, no dialog) | `suites/saving/` |
| TC-SAVE-006 | A result larger than the live preview is saved whole | P2 | **Passing** — 60,000 numbers come out as 60,000 (the first version of this row said a save held only the capped preview; the app has always fetched everything again first) | `suites/saving/` |
| TC-SAVE-007 | Unwritable destination → save error | P2 | **Passing** — TC-SAVE-007a (missing folder), 007b (read-only folder; skipped when run as root) | `suites/saving/` |
| TC-SAVE-008 | Save-race error text | P3 (may be unautomatable) | Not implemented — a genuine race; the harness has no timing control over the worker | `suites/saving/` |
| TC-SAVE-009 | Save confirmation cleared by next load | P3 | **Passing** | `suites/saving/` |
| TC-SAVE-010 | The save file type follows the format (JSON `*.json`; CSV/TSV for rows) | P2 | **Passing** — TC-SAVE-010a, and TC-FMT-050/051/063 for rows | `suites/saving/` |
| TC-SAVE-011 | Save… while the query is still running | P2 | Not implemented — a finding, not a case: the file written holds only the results that had arrived when the button was pressed, and is written when the query ends (see 09_saving.md); a case would pin a behaviour the app's owner has not chosen | `suites/saving/` |

## Keyboard shortcuts — [10_keyboard_shortcuts.md](10_keyboard_shortcuts.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-KEY-000 | Click sets panel focus for Ctrl+F/S | P2 | **Passing** (combined with TC-KEY-002 into one test case) | `suites/keyboard_shortcuts/` |
| TC-KEY-001 | Ctrl+Enter runs query globally | P1 | **Passing** (covered by TC-QRY-061 — not duplicated here) | `suites/query_engines/` |
| TC-KEY-002 | Ctrl+F opens Search for focused panel | P2 | **Passing** | `suites/keyboard_shortcuts/` |
| TC-KEY-003 | Ctrl+S saves focused panel's whole-panel target | P2 | **Passing** — TC-KEY-003a (Source), 003b (Results), 003c (no results: nothing opens); TC-FMT-060 for rows | `suites/saving/` |
| TC-KEY-004 | Ctrl+Enter loads paste (focus-gated) | P2 | **Passing** (both the positive case and the focus-gated negative case — Ctrl+Enter does nothing once the paste box has lost focus) | `suites/keyboard_shortcuts/` |
| TC-KEY-005 | Ctrl+Enter applies edited paste (focus-gated) | P2 | **Passing** (covered by TC-TXT-007's positive case; the focus-gated negative half isn't separately re-tested there, but TC-KEY-004 demonstrates the same focus-gating for the analogous paste-box shortcut) | `suites/text_view/` |
| TC-KEY-006 | Enter loads the source field / submits the Search popup | P3 | **Passing** (split into TC-KEY-006a/006b) | `suites/keyboard_shortcuts/` |
| TC-KEY-007 | Native text-editing keys (smoke) | P3 | Not implemented — would only re-confirm egui's own `TextEdit` behavior, not anything this app added | `suites/keyboard_shortcuts/` |

## Pop-out panes — [12_popout_panes.md](12_popout_panes.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-POP-001 | The Query Pane Opens In A Window Of Its Own | P1 | **Passing** | `suites/popout/` |
| TC-POP-002 | A Query Run From Its Window Shows Its Results In The Main Window | P1 | **Passing** | `suites/popout/` |
| TC-POP-003 | The Button In The Window Docks The Pane Back | P1 | **Passing** | `suites/popout/` |
| TC-POP-004 | Closing The Window Docks The Pane Back | P1 | **Passing** | `suites/popout/` |
| TC-POP-005 | Source In Its Own Window Gives Results The Whole Width | P1 | **Passing** | `suites/popout/` |
| TC-POP-006 | Results In Its Own Window Gives Source The Whole Width | P1 | **Passing** | `suites/popout/` |
| TC-POP-007 | With Source And Results Both Out The Main Window Says So | P1 | **Passing** | `suites/popout/` |
| TC-POP-008 | The Toolbar Button Docks Every Window At Once | P2 | **Passing** | `suites/popout/` |
| TC-POP-009 | Find Opens In The Window Of The Tree It Searches | P1 | **Passing** | `suites/popout/` |
| TC-POP-010 | Autocomplete Works In The Query Window | P2 | **Passing** | `suites/popout/` |
| TC-POP-011 | A Window Reopens Where It Was Left | P2 | **Passing** | `suites/popout/` |
| TC-POP-012 | Closing The Main Window Closes The Pop-Out Windows Too | P2 | **Passing** | `suites/popout/` |
| TC-POP-013 | A Click In The Main Window Still Decides What Ctrl+F Searches | P1 | **Passing** | `suites/popout/` |
| TC-POP-014 | A Maximized Pane Window Still Responds And Docks Back | P1 | **Passing** (the Wayland bug itself is not visible under X) | `suites/popout/` |
| TC-POP-015 | Closing A Maximized Pane Window Docks Its Pane | P1 | **Passing** | `suites/popout/` |
| TC-POP-016 | The Source Window Has A Source Field Of Its Own | P1 | **Passing** | `suites/popout/` |
| TC-POP-017 | The Load Button In The Source Window Loads | P1 | **Passing** | `suites/popout/` |
| TC-POP-018 | Clear In The Source Window Unloads The Document | P1 | **Passing** | `suites/popout/` |
| TC-POP-019 | The Two Source Fields Are One Text | P2 | **Passing** | `suites/popout/` |
| TC-POP-020 | A Failed Load Is Said In The Source Window | P1 | **Passing** | `suites/popout/` |
| TC-POP-021 | Only The Source Window Has A Source Row | P2 | **Passing** | `suites/popout/` |
| TC-POP-022 | The Source Window's Row Says What Is Loaded | P2 | **Passing** | `suites/popout/` |
| TC-POP-023 | The Toolbar Keeps Its Source Field While Source Is Out | P2 | **Passing** | `suites/popout/` |
| TC-POP-024 | A File Loaded From The Toolbar Shows In The Source Window | P1 | **Passing** | `suites/popout/` |
| TC-POP-025 | Docking The Source Pane Takes The Row With It | P2 | **Passing** | `suites/popout/` |

## Tools window — [13_tools_window.md](13_tools_window.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-TWIN-001 | The Tools Button Opens A Window Of Its Own | P1 | **Passing** | `suites/tools/` |
| TC-TWIN-002 | The Main Window Keeps Working With The Tools Window Open | P1 | **Passing** | `suites/tools/` |
| TC-TWIN-003 | Closing The Window And Pressing The Button Again Reopens It | P1 | **Passing** | `suites/tools/` |
| TC-TWIN-004 | Pressing The Button With The Window Open Brings It Forward | P2 | **Passing** | `suites/tools/` |
| TC-TWIN-005 | Every Tool Is In The List And Opens Its Page | P1 | **Passing** | `suites/tools/` |
| TC-TWIN-012 | A Maximized Tools Window Still Responds And Closes | P1 | **Passing** (under X it passes with or without the redraw-on-its-own change — the bug was Wayland's) | `suites/tools/` |
| TC-TWIN-013 | Each Page Keeps What Was Typed In It | P1 | **Passing** | `suites/tools/` |
| TC-TWIN-014 | The Selected Tab Is Marked | P2 | **Passing** | `suites/tools/` |
| TC-TWIN-015 | The Window Opens At Its Default Size | P2 | **Passing** | `suites/tools/` |
| TC-TWIN-016 | The Tools Window Follows The Main Window's Theme | P2 | **Passing** | `suites/tools/` |
| TC-TWIN-017 | No Line Under A Pane's Header | P2 | **Passing** | `suites/tools/` |
| TC-MRG-001 | Merge Has Nothing To Run Until There Are Files | P1 | **Passing** | `suites/tools/` |
| TC-MRG-002 | The Presets Are Listed | P1 | **Passing** | `suites/tools/` |
| TC-MRG-003 | Picking A Preset Puts Its Filter In The Box | P1 | **Passing** | `suites/tools/` |
| TC-MRG-004 | A Filter Of One's Own Is Called Custom | P1 | **Passing** | `suites/tools/` |
| TC-MRG-005 | Picking A Preset Replaces A Custom Filter | P2 | **Passing** | `suites/tools/` |
| TC-TWIN-018 | The Line Between The Panes Can Be Dragged | P2 | **Passing** | `suites/tools/` |
| TC-MRG-010 | Files Dropped On The Main Window Open The Merge Page | P1 | **Passing** | `suites/tools/` |
| TC-MRG-011 | One File Dropped On The Main Window Is Opened | P1 | **Passing** | `suites/tools/` |
| TC-MRG-012 | Files Dropped On The Tools Window Are Added | P1 | **Passing** | `suites/tools/` |
| TC-MRG-013 | Append Arrays Joins The Files In Order | P1 | **Passing** | `suites/tools/` |
| TC-MRG-014 | The Order Of The List Is The Order Of The Merge | P1 | **Passing** | `suites/tools/` |
| TC-MRG-015 | A File Can Be Taken Off The List | P1 | **Passing** | `suites/tools/` |
| TC-MRG-016 | Clear Empties The List | P1 | **Passing** | `suites/tools/` |
| TC-MRG-017 | Sort A-Z Puts Numbers In Order | P1 | **Passing** | `suites/tools/` |
| TC-MRG-018 | The Same File Is Listed Once | P2 | **Passing** | `suites/tools/` |
| TC-MRG-019 | Append Arrays Takes Objects Too | P2 | **Passing** | `suites/tools/` |
| TC-MRG-020 | Deep-Merge Keeps What Both Files Have Inside | P1 | **Passing** | `suites/tools/` |
| TC-MRG-021 | Sorted And De-Duplicated Gives Each Value Once | P1 | **Passing** | `suites/tools/` |
| TC-MRG-022 | Bundle By File Name Labels Each File | P1 | **Passing** | `suites/tools/` |
| TC-MRG-023 | A Filter Of One's Own Runs | P1 | **Passing** | `suites/tools/` |
| TC-MRG-024 | A Filter With Several Outputs Gives An Array Of Them | P2 | **Passing** | `suites/tools/` |
| TC-MRG-025 | Adding An Array To An Object Is An Error | P1 | **Passing** | `suites/tools/` |
| TC-MRG-026 | A File That Is Not JSON Is Named | P1 | **Passing** | `suites/tools/` |
| TC-MRG-027 | A Filter That Gives Nothing Is An Error | P2 | **Passing** | `suites/tools/` |
| TC-MRG-028 | A Filter That Never Stops Is Cut Off | P2 | **Passing** (the error says `1000000` without commas) | `suites/tools/` |
| TC-MRG-029 | Open In Main Window Makes It The Document | P1 | **Passing** | `suites/tools/` |
| TC-MRG-030 | Changing The Files Drops The Result | P1 | **Passing** | `suites/tools/` |
| TC-MRG-031 | Changing The Filter Drops The Result | P2 | **Passing** | `suites/tools/` |
| TC-MRG-032 | Ctrl+Enter Merges | P2 | **Passing** | `suites/tools/` |
| TC-MRG-033 | The Merge Button Is Bright With Files | P2 | **Passing** | `suites/tools/` |
| TC-MRG-034 | Big Numbers Keep Their Digits | P2 | **Passing** | `suites/tools/` |
| TC-MRG-040 | A Result As Big As Files Are Kept On Disk From Is Kept In A Temporary File | P1 | **Passing** | `suites/tools/tools_merge_big.robot` |
| TC-MRG-041 | A Result Under That Size Stays In Memory | P1 | **Passing** | `suites/tools/tools_merge_big.robot` |
| TC-MRG-042 | A Big Result Opens In The Main Window As A File | P1 | **Passing** | `suites/tools/tools_merge_big.robot` |
| TC-MRG-043 | A Big Result Is Saved Whole | P1 | **Passing** | `suites/tools/tools_merge_big.robot` |
| TC-MRG-044 | The Temporary File Has No Name | P1 | **Passing** | `suites/tools/tools_merge_big.robot` |
| TC-MRG-045 | The Size Is The One In The Settings | P1 | **Passing** | `suites/tools/tools_merge_big.robot` |
| TC-TWIN-006 | Format JSON Pretty-Prints Pasted Text | P1 | **Passing** | `suites/tools/` |
| TC-FMT-001 | The Layout Is Two Spaces To A Level By Default | P1 | **Passing** | `suites/tools/` |
| TC-FMT-002 | Four Spaces To A Level | P1 | **Passing** | `suites/tools/` |
| TC-FMT-003 | A Tab To A Level | P1 | **Passing** | `suites/tools/` |
| TC-FMT-004 | Minified Has No White Space | P1 | **Passing** | `suites/tools/` |
| TC-FMT-005 | Sort Keys Puts Every Object's Keys In Order | P1 | **Passing** | `suites/tools/` |
| TC-FMT-006 | Without Sort Keys The Keys Keep Their Order | P2 | **Passing** | `suites/tools/` |
| TC-FMT-007 | ASCII Only Escapes What Is Not ASCII | P1 | **Passing** | `suites/tools/` |
| TC-FMT-008 | Characters Outside ASCII Are Kept By Default | P2 | **Passing** | `suites/tools/` |
| TC-FMT-009 | Numbers Come Back As They Were Written | P1 | **Passing** | `suites/tools/` |
| TC-FMT-010 | Empty Containers Stay On One Line | P2 | **Passing** | `suites/tools/` |
| TC-FMT-011 | A Document That Is Only A Scalar Formats Too | P2 | **Passing** | `suites/tools/` |
| TC-FMT-012 | Text That Is Not JSON Is Reported With Where | P1 | **Passing** | `suites/tools/` |
| TC-FMT-013 | Several Values In A Row Are Read As One Array | P2 | **Passing** | `suites/tools/` |
| TC-FMT-023 | Text After The Document Is An Error | P2 | **Passing** | `suites/tools/` |
| TC-FMT-014 | Format Waits For Something To Format | P1 | **Passing** | `suites/tools/` |
| TC-FMT-015 | Ctrl+Enter Formats | P1 | **Passing** | `suites/tools/` |
| TC-FMT-016 | Clear Empties The Box And Drops The Result | P1 | **Passing** | `suites/tools/` |
| TC-FMT-017 | Editing The Input Drops The Result | P1 | **Passing** | `suites/tools/` |
| TC-FMT-018 | Changing An Option Drops The Result | P2 | **Passing** | `suites/tools/` |
| TC-FMT-019 | Copy Says So In The Status Bar | P2 | **Passing** | `suites/tools/` |
| TC-FMT-020 | The Status Bar Compares The Sizes | P2 | **Passing** | `suites/tools/` |
| TC-FMT-021 | The Open Document Can Be Formatted | P1 | **Passing** | `suites/tools/` |
| TC-FMT-022 | Open Document Is Dim Without A Document | P2 | **Passing** | `suites/tools/` |
| TC-FMT-080 | A Document Kept On Disk Is Formatted As It Is Saved | P2 | **Passing** | `suites/tools/` |
| TC-TWIN-007 | Diff JSON Shows The Documents Side By Side | P1 | **Passing** (reads words and the status bar; the exact patch is pinned by TC-DIF-011/012 through the clipboard) | `suites/tools/` |
| TC-DIF-001 | Compare Needs Both Documents | P1 | **Passing** | `suites/tools/` |
| TC-DIF-002 | Documents That Are The Same Are Said To Be | P1 | **Passing** | `suites/tools/` |
| TC-DIF-003 | Swap Exchanges The Two Documents | P1 | **Passing** | `suites/tools/` |
| TC-DIF-004 | Swap After A Comparison Goes Back To The Documents | P2 | **Passing** | `suites/tools/` |
| TC-DIF-005 | The Changes List Names Each Difference | P1 | **Passing** | `suites/tools/` |
| TC-DIF-006 | A Document Of Another Kind Replaces The Whole | P2 | **Passing** | `suites/tools/` |
| TC-DIF-007 | Walking The Differences | P1 | **Passing** (`Difference 2` is matched, not `2 of 5`, which OCR reads as `1o0f2`) | `suites/tools/` |
| TC-DIF-008 | The Keyboard Walks The Differences Too | P2 | **Passing** | `suites/tools/` |
| TC-DIF-009 | Differences Only Folds What Is The Same | P1 | **Passing** | `suites/tools/` |
| TC-DIF-010 | The Menu Of A Line Copies The Path Of Its Difference | P1 | **Passing** | `suites/tools/` |
| TC-DIF-011 | Copy Patch Gives The Whole Patch | P1 | **Passing** | `suites/tools/` |
| TC-DIF-012 | Copy Patch Works From Every View | P2 | **Passing** | `suites/tools/` |
| TC-DIF-013 | Copy Patch Is Dim Until There Is A Patch | P2 | **Passing** | `suites/tools/` |
| TC-DIF-014 | Editing A Document Drops The Comparison | P1 | **Passing** | `suites/tools/` |
| TC-DIF-015 | A Second Comparison Replaces The First | P1 | **Passing** | `suites/tools/` |
| TC-DIF-016 | The Marks Have Their Colours | P1 | **Passing** (marks checked by colour) | `suites/tools/` |
| TC-DIF-017 | A Change Alone Is Only Amber | P2 | **Passing** | `suites/tools/` |
| TC-DIF-018 | A Left Document That Is Not JSON Is Named | P1 | **Passing** | `suites/tools/` |
| TC-DIF-019 | A Right Document That Is Not JSON Is Named | P2 | **Passing** | `suites/tools/` |
| TC-DIF-020 | The Two Columns Scroll As One | P1 | **Passing** | `suites/tools/` |
| TC-DIF-021 | The Open Document Can Be One Of The Two | P1 | **Passing** | `suites/tools/` |
| TC-DIF-022 | Clear Empties A Box | P2 | **Passing** | `suites/tools/` |
| TC-DIF-023 | Ctrl+Enter Compares | P2 | **Passing** | `suites/tools/` |
| TC-DIF-024 | A View Compares The Documents When It Is Asked For, Without Compare | P0 | **Passing** | `suites/tools/` |
| TC-DIF-025 | A View Has Nothing To Compare Until Both Documents Are There | P1 | **Passing** | `suites/tools/` |
| TC-DIF-026 | The Arrows In The Gutter Move A Difference Into The Document They Point At | P0 | **Passing** (what is left is read from Copy patch) | `suites/tools/` |
| TC-DIF-027 | A Line That Is Picked Is Moved By Itself, And The Rest Of Its Difference Stays | P0 | **Passing** | `suites/tools/` |
| TC-DIF-028 | With Nothing Picked The Arrow Moves The Whole Difference | P1 | **Passing** | `suites/tools/` |
| TC-DIF-029 | Ctrl Adds A Line To Those Picked And Takes It Away, And Shift Picks A Run | P1 | **Passing** (the count is read loosely: OCR drops the spaces of text that small) | `suites/tools/` |
| TC-DIF-030 | A Drag Over Lines Picks Them, And Escape Lets Them Go | P1 | **Passing** | `suites/tools/` |
| TC-DIF-031 | The Menu Of A Line Moves The Lines That Are Picked, In Every Difference | P2 | **Passing** | `suites/tools/` |
| TC-DIF-032 | A Document That A Move Changed Says So, And Each Save Writes Its Own Document | P0 | **Passing** (the label that says "(changed)" is grey text OCR cannot read: its length is measured) | `suites/tools/` |
| TC-DIF-033 | A Double Click Puts A Caret In A Line, And Enter Puts What Was Typed In | P0 | **Passing** | `suites/tools/` |
| TC-DIF-034 | The Right Column Is Typed Over Too, And Escape Puts The Line Back | P0 | **Passing** | `suites/tools/` |
| TC-DIF-035 | What Is Not JSON Is Said And Stays To Be Put Right | P0 | **Passing** | `suites/tools/` |
| TC-DIF-036 | A Line Is Taken Out By Typing Nothing, And Several Are Put In By Typing Them | P1 | **Passing** | `suites/tools/` |
| TC-DIF-037 | The Name Of A Line That Opens An Object Is Changed And What Is In It Stays | P1 | **Passing** | `suites/tools/` |
| TC-DIF-038 | A Line That Closes Something Has No Caret, And A Line Cut Short Says So | P1 | **Passing** | `suites/tools/` |
| TC-DIF-039 | A Click Elsewhere Puts In What Was Typed, And An Arrow Is Not Held Up By A Caret | P1 | **Passing** | `suites/tools/` |
| TC-DIF-040 | A Single Click Only Picks, So That More Lines Can Be Picked After It | P0 | **Passing** | `suites/tools/` |
| TC-DIF-041 | After A Move The View Stays Where It Was And Picks Nothing | P0 | **Passing** | `suites/tools/` |
| TC-DIF-042 | A Key An Object Has More Than Once Is Compared Member By Member, And Each Member Is A Line | P0 | **Passing** | `suites/tools/` |
| TC-DIF-043 | A Document That Repeats Several Keys Shows Each Member As A Line, What The Other Lacks In Red | P0 | **Passing** | `suites/tools/` |
| TC-DIF-044 | A Move Into A Document Keeps Its Repeated Members | P0 | **Passing** | `suites/tools/` |
| TC-DIF-045 | A Line Typed Over Is The Member It Is, Whichever Of Its Name, And The Others Stay | P0 | **Passing** | `suites/tools/` |
| TC-DIF-046 | The Open Document Is Read Again From Its File To Have Its Repeated Members | P1 | **Passing** | `suites/tools/` |
| TC-DIF-047 | An Open Document That Cannot Be Read Again Says That Only Its Last Members Are Compared | P1 | **Passing** | `suites/tools/` |
| TC-TWIN-008 | Patch JSON Applies A Patch And Opens The Result | P1 | **Passing** | `suites/tools/` |
| TC-TWIN-009 | A Patch That Fails Names The Operation | P2 | **Passing** | `suites/tools/` |
| TC-PAT-001 | Operations Apply In Order | P1 | **Passing** | `suites/tools/` |
| TC-PAT-002 | A Merge Patch Replaces, Removes And Adds | P1 | **Passing** | `suites/tools/` |
| TC-PAT-003 | Changing The Kind Drops The Result | P2 | **Passing** | `suites/tools/` |
| TC-PAT-004 | A Patch That Is Not A List Is Explained | P1 | **Passing** | `suites/tools/` |
| TC-PAT-005 | A Document That Is Not JSON Is Named | P1 | **Passing** | `suites/tools/` |
| TC-PAT-006 | A Patch That Is Not JSON Is Named | P2 | **Passing** | `suites/tools/` |
| TC-PAT-007 | A Failed Test Changes Nothing | P1 | **Passing** | `suites/tools/` |
| TC-PAT-008 | An Array Index Out Of Range Is An Error | P2 | **Passing** | `suites/tools/` |
| TC-PAT-009 | A Pointer Reaches A Key That Has A Slash | P2 | **Passing** | `suites/tools/` |
| TC-PAT-010 | Apply Needs Both Boxes | P1 | **Passing** | `suites/tools/` |
| TC-PAT-011 | Open In Main Window Waits For A Result | P2 | **Passing** | `suites/tools/` |
| TC-PAT-012 | The Patched Document Becomes The Main Window's Document | P1 | **Passing** | `suites/tools/` |
| TC-PAT-013 | Editing A Box Drops The Result | P1 | **Passing** | `suites/tools/` |
| TC-PAT-014 | Clear Empties A Box | P2 | **Passing** | `suites/tools/` |
| TC-PAT-015 | The Open Document Is Patched | P1 | **Passing** | `suites/tools/` |
| TC-PAT-016 | Ctrl+Enter Applies | P2 | **Passing** | `suites/tools/` |
| TC-PAT-017 | Copy Says So In The Status Bar | P2 | **Passing** | `suites/tools/` |
| TC-PAT-018 | Numbers Keep Their Digits Through A Patch | P2 | **Passing** | `suites/tools/` |
| TC-TWIN-010 | Validate Schema Lists The Problems | P1 | **Passing** | `suites/tools/` |
| TC-TWIN-011 | A Problem Can Be Shown In The Main Window | P1 | **Passing** (reads the status bar, not the tinted query box) | `suites/tools/` |
| TC-VAL-001 | A Document That Fits Is Valid | P1 | **Passing** | `suites/tools/` |
| TC-VAL-002 | The Draft Comes From The Schema | P1 | **Passing** | `suites/tools/` |
| TC-VAL-003 | Formats Are Checked By Default | P1 | **Passing** | `suites/tools/` |
| TC-VAL-004 | Check Formats Can Be Turned Off | P1 | **Passing** | `suites/tools/` |
| TC-VAL-005 | A Schema That Is Not A Schema Is Explained | P1 | **Passing** | `suites/tools/` |
| TC-VAL-006 | A Reference To Somewhere Else Is Refused | P1 | **Passing** | `suites/tools/` |
| TC-VAL-007 | A Reference Inside The Schema Works | P2 | **Passing** | `suites/tools/` |
| TC-VAL-008 | A Document That Is Not JSON Is Named | P1 | **Passing** | `suites/tools/` |
| TC-VAL-009 | A Schema That Is Not JSON Is Named | P2 | **Passing** | `suites/tools/` |
| TC-VAL-010 | Validate Needs Both Boxes | P1 | **Passing** | `suites/tools/` |
| TC-VAL-011 | The Report Can Be Copied | P1 | **Passing** | `suites/tools/` |
| TC-VAL-012 | Copy Report Is Dim Without Problems | P2 | **Passing** | `suites/tools/` |
| TC-VAL-013 | Picking A Row Marks It | P1 | **Passing** | `suites/tools/` |
| TC-VAL-014 | Show In Main Window Needs The Open Document | P1 | **Passing** | `suites/tools/` |
| TC-VAL-015 | A Double-Click Shows The Problem | P1 | **Passing** | `suites/tools/` |
| TC-VAL-016 | Editing A Box Drops The Report | P1 | **Passing** | `suites/tools/` |
| TC-VAL-017 | Ctrl+Enter Validates | P2 | **Passing** | `suites/tools/` |
| TC-VAL-018 | Every Problem Is Listed | P2 | **Passing** | `suites/tools/` |
| TC-TDLG-001 | Format Saves Under formatted.json | P1 | **Passing** | `suites/tools/` |
| TC-TDLG-002 | Format Minified Saves Under min.json | P2 | **Passing** | `suites/tools/` |
| TC-TDLG-003 | A File Opened Through The Dialog Is Formatted And Saved Next To Its Name | P1 | **Passing** | `suites/tools/` |
| TC-TDLG-004 | Patch Saves Under patched.json | P1 | **Passing** | `suites/tools/` |
| TC-TDLG-005 | Merge Saves Under merged.json | P1 | **Passing** | `suites/tools/` |
| TC-TDLG-006 | Diff Saves The Patch Under patch.json | P1 | **Passing** | `suites/tools/` |
| TC-TDLG-007 | Merge Add Files Takes Several Files From The Dialog | P1 | **Passing** | `suites/tools/` |
| TC-TDLG-008 | Closing A Save Dialog Writes Nothing | P2 | **Passing** | `suites/tools/` |
| TC-TDLG-009 | Closing An Open Dialog Leaves The Box As It Was | P2 | **Passing** | `suites/tools/` |

Exact text is checked through the clipboard (Copy), state and look by pixels, and
only short plain words and the status bar by OCR — see
[13_tools_window.md](13_tools_window.md). The native dialogs (Add files…, Open file…,
Save…) are answered by the stand-in portal and checked in TC-TDLG-001 to 009; files
also go in by dropping them. The details of each tool (every error message, option and
engine edge) are covered by `cargo test`.


## Tutorial and About windows — [14_tutorial_and_about_windows.md](14_tutorial_and_about_windows.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-SAT-001 | The Tutorial Button Opens The Tutorial Window | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-002 | The Tutorial Opens On The First Lesson | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-003 | Picking Another Lesson Shows It | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-004 | Another Language Has Lessons Of Its Own | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-005 | Typing In The Filter Narrows The Lessons | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-006 | Try It Hands The Example To The Main Window | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-007 | Load Query Puts Only The Query In The Main Window | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-008 | Load Data Puts Only The Sample In The Main Window | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-009 | Copy Query Copies The Query | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-010 | Closing The Tutorial And Pressing The Button Again Reopens It | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-011 | A Second Press Does Not Open A Second Tutorial | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-012 | A Maximized Tutorial Still Responds And Closes | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-013 | The Main Window Works With The Tutorial Open | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-014 | The Tutorial Follows The Main Window's Theme | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-020 | The Info Button Opens The About Window | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-021 | About Says The Version Of The Build | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-022 | Closing About And Pressing The Button Again Reopens It | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-023 | The Main Window Works With About Open | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-024 | About Names The Website And Says What Is There | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-025 | The Website In About Is A Link That Opens The Site | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-026 | About Shows All It Says Down To The Last Link | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-040 | About Has A Known Issues Header, Shut, With The Number Of Issues | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-041 | Opening The Known Issues Shows The List And Makes The Window Bigger | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-042 | Closing The List Shuts It And The Window Goes Back To Its Size | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-043 | The List Can Be Opened Again After It Was Shut | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-044 | A Window Opened Afresh Has The List Shut | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-045 | A Window Wider Than The List Needs Keeps Its Width And Gets Its Size Back | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-046 | A Line Of The List Shows An Example While The Pointer Rests On It | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-047 | The Link Under The List Opens The Page With All The Issues | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-048 | A Window Too Small For The List Scrolls To Its End | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-049 | The Version Is Copied With A Right Click | P3 | **Passing** | `suites/satellites/` |
| TC-SAT-050 | A Link Is Copied With A Right Click | P2 | **Passing** | `suites/satellites/` |
| TC-SAT-051 | A Line Of The Known Issues Is Copied With A Right Click | P3 | **Passing** | `suites/satellites/` |
| TC-SAT-030 | All The Windows Can Be Open Together | P1 | **Passing** | `suites/satellites/` |
| TC-SAT-031 | Closing One Window Leaves The Others | P2 | **Passing** | `suites/satellites/` |

## Pane headers — [15_pane_headers.md](15_pane_headers.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-HDR-001 | The Panes' Titles Are Small | P1 | **Passing** | `suites/pane_headers/` |
| TC-HDR-002 | There Is No Line Under The Headers | P1 | **Passing** | `suites/pane_headers/` |
| TC-HDR-003 | There Is No Line Under The Headers Of Empty Panes Either | P1 | **Passing** | `suites/pane_headers/` |
| TC-HDR-004 | The Panel's Edge Is The One Divider | P1 | **Passing** (guards the change going too far; passes on the old layout too) | `suites/pane_headers/` |
| TC-HDR-005 | The Tree Starts Right Under The Header | P1 | **Passing** | `suites/pane_headers/` |
| TC-HDR-006 | The Empty Source Pane's Hint Is Right Under Its Title | P2 | **Passing** | `suites/pane_headers/` |
| TC-HDR-007 | The Headers Still Have Their Controls | P1 | **Passing** (guards the change going too far; passes on the old layout too) | `suites/pane_headers/` |
| TC-HDR-008 | No Line Under A Header In The Light Theme | P2 | **Passing** | `suites/pane_headers/` |
| TC-HDR-009 | The Source Window Has The Same Small Title And No Line | P1 | **Passing** | `suites/pane_headers/` |
| TC-HDR-010 | The Tools Window's Panes Have The Same Titles | P1 | **Passing** (guards the Tools window's title; the old commit has no such page) | `suites/pane_headers/` |

## Drag and drop — [16_drag_and_drop.md](16_drag_and_drop.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-DND-001 | A File Dropped On The Main Window Is Opened | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-002 | It Does Not Matter Where On The Window It Is Dropped | P2 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-003 | A Dropped File Replaces The Open Document | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-004 | A File That Is Not JSON Gives A Load Error | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-005 | A File With Broken JSON Gives A Load Error | P2 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-006 | Several Files Open The Tools Window On Merge | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-007 | Several Files Bring The Merge Page Up From Another Page | P2 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-008 | A File Dropped On Format Goes Into The Input Box | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-009 | A Second File Dropped On Format Replaces The First | P2 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-010 | Two Files Fill The Two Boxes Of Diff | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-011 | Two Files Fill The Document And The Patch | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-012 | Two Files Fill The Document And The Schema | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-013 | A File Dropped On The Source Window Opens In It | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-014 | A Folder Is Not Added To The Merge List | P2 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-015 | Files Dropped On The Tools Window Do Not Open In The Main Window | P2 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-016 | Files Held Over An Empty Window Show The Drop Overlay | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-017 | The Overlay Goes When The Files Leave | P1 | **Passing** | `suites/drag_and_drop/` |
| TC-DND-018 | With A Document Loaded There Is No Overlay | P2 | **Passing** | `suites/drag_and_drop/` |

## The jq functions the app adds — [17_jq_functions.md](17_jq_functions.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-JQX-001 | IN Keeps The Members Whose Value Is One Of Several | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-002 | IN Gives A Boolean For Each Input | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-003 | IN Over A Source Asks Whether Any Output Is In The Set | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-004 | IN Over A Source Is False When Nothing Matches | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-005 | Not IN Keeps What Is Not In The List | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-006 | IN Compares Whole Values | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-007 | IN An Empty Source Is False | P3 | **Passing** | `suites/jq_functions/` |
| TC-JQX-008 | IN A Generated Source | P3 | **Passing** | `suites/jq_functions/` |
| TC-JQX-009 | IN Does Not Equate A Number And A String | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-010 | IN Finds Null | P3 | **Passing** | `suites/jq_functions/` |
| TC-JQX-020 | INDEX Keys An Array By A Field | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-021 | INDEX Over A Stream Makes A Lookup Table | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-022 | INDEX Turns Numeric Keys Into Strings | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-023 | INDEX Keeps The Last Of Several With One Key | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-024 | INDEX Of An Empty Array Is An Empty Object | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-025 | INDEX Files A Missing Key Under null | P3 | **Passing** | `suites/jq_functions/` |
| TC-JQX-026 | INDEX Then map_values Projects The Table | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-027 | INDEX Of The Customers By Code | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-030 | JOIN Pairs Each Order With Its Customer | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-031 | JOIN Without A Join Expression Gives The Pairs | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-032 | JOIN Over An Array Makes An Array Of Pairs | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-033 | JOIN Pairs An Unmatched Element With null | P3 | **Passing** | `suites/jq_functions/` |
| TC-JQX-040 | tostream Gives A Path And A Leaf For Each Scalar And A Closing Event | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-041 | tostream Of The Whole Document Has Seven Events | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-042 | tostream Of A Scalar Is One Event With An Empty Path | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-043 | tostream Of Empty Containers Is Their Own Leaf | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-044 | The Events Make A Listing Of Every Leaf | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-045 | The Last Event Closes The Top Level | P3 | **Passing** | `suites/jq_functions/` |
| TC-JQX-046 | fromstream Rebuilds What tostream Took Apart | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-047 | fromstream Builds A Value From Hand-Written Events | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-048 | fromstream Of A Truncated Stream Makes The Inner Values | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-049 | truncate_stream Drops The First Path Level | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-050 | fromstream Over A Filtered Stream Drops A Field From Every Record | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-051 | fromstream Of A Truncated Stream Gives One Result Per Element | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-052 | fromstream Makes One Value Per Complete Top-Level Value | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-053 | tostream Of A Large Array Is Fast Enough To Use | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-060 | @csv Writes Numbers Bare Strings Quoted And null Empty | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-061 | @csv Doubles A Quote Inside A String | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-062 | @csv Leaves A Comma Or A Line Break Inside The Quotes | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-063 | @tsv Escapes Tab Backslash Line Break And Carriage Return | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-064 | @tsv Writes null As Nothing And Booleans As Words | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-065 | @csv And @tsv Of An Empty Array Are Empty Strings | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-066 | @csv Quotes A Lone String | P3 | **Passing** | `suites/jq_functions/` |
| TC-JQX-067 | @csv Of An Object Is An Error That Names The Value | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-068 | @csv Of A Nested Array Is An Error | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-069 | @tsv Of A String Is An Error | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-080 | An Error Raised In The Query Shows Its Text Plainly | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-081 | try catch Hands Over The Error Text | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-082 | An Unknown Variable Is A Query Error | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-090 | tonumber Of Text That Is Not A Number Is One Error And The Window Answers The Next Query | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-091 | fromjson Of Text That Is Not JSON Is One Error And The Window Answers The Next Query | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-092 | tonumber With A Question Mark Skips What Is Not A Number | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-093 | tonumber Reads What jq Reads | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-094 | tonumber Refuses A Space Around A Number | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-095 | fromjson Reads One Value And Not Two | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-096 | A Result Nested Very Deep Is Cut Where It Gets Too Deep And The Window Stays | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-097 | tojson Stops Where jq Stops | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-098 | A Value Nested Far Deeper Than An Ordinary Thread Can Write Is Written Without The App Closing | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-099 | Assigning Into A Key That Is Not There Makes The Objects | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-100 | A reduce That Starts From null Builds An Object Or An Array | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-101 | An Index Past The End Makes The Array Longer With nulls | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-102 | setpath And pick Go Through null | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-103 | An Index Far Past The End Is An Error And The Window Answers The Next Query | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-104 | del Takes Several Items Of An Array At Once | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-105 | delpaths Takes All The Paths As The Value Was | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-106 | del Keeps The Other Keys In Their Order | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-107 | del Of What A Condition Selects | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-108 | scan Finds Every Match | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-109 | scan Gives The Groups Of Each Match As An Array | P1 | **Passing** | `suites/jq_functions/` |
| TC-JQX-110 | join Writes null As Nothing | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-111 | join Refuses An Array Or An Object | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-112 | from_entries Reads The Names AWS Tags And Kubernetes Lists Have | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-113 | with_entries Uses The Same Names | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-114 | from_entries Refuses A Key That Is Not Text | P2 | **Passing** | `suites/jq_functions/` |
| TC-JQX-115 | @base64d Decodes A JWT Segment Without Padding | P0 | **Passing** | `suites/jq_functions/` |
| TC-JQX-116 | @base64d Refuses What Is Not Base64 And Replaces Bytes That Are Not Text | P2 | **Passing** | `suites/jq_functions/` |

## CSV and TSV output — [18_output_formats.md](18_output_formats.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-FMT-001 | A JSON Result Has No Format Note | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-002 | A Query Ending In @csv Shows The CSV Note | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-003 | A Query Ending In @tsv Shows The TSV Note | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-004 | The Note Follows The Last Query That Ran | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-005 | Editing The Query Without Running It Leaves The Note Alone | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-006 | @csv Before The Last Stage Does Not Make Rows | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-007 | A Query Wrapped In Brackets Is JSON | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-008 | A Parenthesised Last Stage Still Counts | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-009 | A Trailing Comment Does Not Hide The Format | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-010 | The Try Operator After @csv Is Still CSV | P3 | **Passing** | `suites/output_formats/` |
| TC-FMT-011 | Another Engine Never Writes Rows | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-012 | Clear Removes The Note | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-013 | Loading Another Document Removes The Note | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-014 | Save Says Which Format It Will Write | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-020 | The Tree Lists One Row Per Result | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-021 | The Text View Shows The Rows | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-022 | The Text View Of TSV Keeps Its Tabs And Escapes | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-023 | The Text View Of CSV Keeps A Line Break Inside A Field | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-024 | The Text View Of JSON Results Is Pretty JSON | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-025 | Switching Between Tree And Text Keeps The Rows | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-026 | A Long List Of Rows Is Cut Short In The Text View | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-030 | Copying All CSV Results Gives The Rows | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-031 | Copying One CSV Row Gives That Row | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-032 | Copying All TSV Results Gives Tabbed Rows | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-033 | Copying One TSV Row Gives That Row | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-034 | CSV Quoting Is Exact | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-035 | TSV Escaping Is Exact | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-036 | Non-ASCII Text Survives | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-037 | JSON Results Still Copy As JSON | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-038 | A Wrapped @csv Query Copies JSON Strings | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-039 | The Source Pane Still Copies JSON | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-040 | A Single Row Has No Line Break After It | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-041 | A Header Row And Then The Data Rows | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-042 | Numbers Booleans And Null In A Row | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-043 | An Empty Result Has No Rows And Nothing To Save | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-044 | A Row That Cannot Be Made Is An Item Error The Others Survive | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-045 | Copying A Long List Of Rows Gives Every Row | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-050 | Saving CSV Results Writes The Rows | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-051 | Saving TSV Results Writes Tabbed Rows | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-052 | Saving JSON Results Still Writes Pretty JSON | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-053 | Cancelling The Dialog Writes Nothing | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-054 | A Row Saved From Its Menu Is Written As That Row | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-055 | The Root Saved From Its Menu Is Every Row | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-056 | Awkward Rows Are Saved Exactly | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-057 | Non-ASCII Text Is Saved As UTF-8 Without A Byte Order Mark | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-058 | A Result Past The Live Preview Is Saved Whole | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-059 | The File Follows The Latest Query | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-060 | Ctrl+S In The Results Pane Saves The Rows | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-061 | A Name The Person Chose Is Used As Given | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-062 | Saving Into A Missing Folder Says So | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-063 | The Source Pane Saves JSON Whatever The Results Are | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-070 | The Popped-Out Results Pane Has The Note | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-071 | The Popped-Out Results Pane Has No Note For JSON | P2 | **Passing** | `suites/output_formats/` |
| TC-FMT-072 | Copying From The Popped-Out Pane Gives Rows | P1 | **Passing** | `suites/output_formats/` |
| TC-FMT-073 | Saving From The Popped-Out Pane Writes The Rows | P1 | **Passing** | `suites/output_formats/` |

## Tutorial pages for the jq functions — [19_tutorial_pages.md](19_tutorial_pages.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-TUT-001 | The @csv Filter Lists The Four Table Pages | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-002 | The tostream Filter Lists The Event Stream Pages | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-003 | The INDEX Filter Finds The Page And The Cheat Sheet | P2 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-004 | Another Language Has No Table Pages | P2 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-005 | Both Topics Are In The List | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-006 | Next Goes From CSV & TSV To Records To A Table | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-007 | Next Goes On From The Last Table Page Into The Next Topic | P2 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-008 | Previous Goes Back From The First Event Stream Page | P2 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-009 | The Last Event Stream Page Leads On To Errors | P3 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-010 | CSV & TSV Opens With Its Examples And Tips | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-011 | Records To A Table Opens With Its Examples And Tips | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-012 | Quoting & Escaping Opens With Its Examples And Tips | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-013 | Copy & Save As CSV Or TSV Opens With Its Examples And Tips | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-014 | IN Opens With Its Examples And Tips | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-015 | INDEX & JOIN Opens With Its Examples And Tips | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-016 | tostream Opens With Its Examples And Tips | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-017 | fromstream & truncate_stream Opens With Its Examples And Tips | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-018 | The Compatibility Page Says The Functions Are Added | P2 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-020 | CSV & TSV: One CSV Row Per Member | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-021 | CSV & TSV: A Header Row First Tab-Separated | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-022 | CSV & TSV: Missing Values Are Empty Fields | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-023 | Records: Header And Rows From One List Of Columns | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-024 | Records: A List In One Cell | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-025 | Records: An Object As Two Columns | P2 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-026 | Quoting: CSV Quotes Strings And Doubles The Quotes Inside | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-027 | Quoting: TSV Quotes Nothing And Escapes Instead | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-028 | Quoting: Only An Array Makes A Row | P2 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-029 | Copy & Save: The Last Step @csv Makes Rows | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-030 | Copy & Save: Not The Last Step Is Still JSON | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-031 | IN: Members Whose Role Is One Of Several | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-032 | IN: Is Any Member In QA | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-033 | IN: Skills That Are Not On A List | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-034 | INDEX: A Lookup Table By Code | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-035 | INDEX: Look Up The Customer Of Every Order | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-036 | INDEX: JOIN Does The Matching | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-037 | tostream: The Events Of A Small Value | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-038 | tostream: Every Leaf As Path = Value | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-039 | tostream: Where Is A Value | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-040 | fromstream: Events Written By Hand | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-041 | fromstream: Drop A Field From Every Record | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-042 | fromstream: One Result Per Order | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-050 | Load Query Puts The CSV Query In The Main Window And Nothing Else | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-051 | Load Data Opens The Sample Document | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-052 | Copy Query Copies The Query Exactly | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-053 | Try It Replaces The Open Document And Query | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-054 | A Page's Rows Can Be Saved As They Are | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-060 | Cheat Sheet: One CSV Row Per Member | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-061 | Cheat Sheet: A Lookup Table Keyed By Name | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-062 | Cheat Sheet: Keep When The Value Is One Of Several | P1 | **Passing** | `suites/tutorial_pages/` |
| TC-TUT-063 | Cheat Sheet: The Value As Events | P1 | **Passing** | `suites/tutorial_pages/` |

## Workflows — [20_workflows.md](20_workflows.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-WF-001 | From A File To A CSV File | P1 | **Passing** | `suites/workflows/` |
| TC-WF-002 | From A Line-Delimited File To CSV | P2 | **Passing** | `suites/workflows/` |
| TC-WF-003 | From A Lesson To Your Own Query And A File | P1 | **Passing** | `suites/workflows/` |
| TC-WF-004 | Joining Two Tables And Saving The Result As JSON | P1 | **Passing** | `suites/workflows/` |
| TC-WF-005 | Taking A Document Apart And Putting It Back | P2 | **Passing** | `suites/workflows/` |
| TC-WF-006 | The Format Follows The Query Through A Change Of Engine | P2 | **Passing** | `suites/workflows/` |
| TC-WF-007 | A Large Document Becomes A Large CSV File | P2 | **Passing** | `suites/workflows/` |
| TC-WF-008 | Saved JSON Can Be Opened Again | P1 | **Passing** | `suites/workflows/` |
| TC-WF-009 | Every Window Open And A Save Still Works | P2 | **Passing** | `suites/workflows/` |
| TC-WF-010 | Rows Copied As CSV Are Not A JSON Document | P3 | **Passing** | `suites/workflows/` |

## Settings — [21_settings.md](21_settings.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-SET-001 | The Gear Opens The Settings Window | P1 | **Passing** | `suites/settings/` |
| TC-SET-002 | Every Limit Is There With Its Default | P1 | **Passing** | `suites/settings/` |
| TC-SET-003 | Nothing Is Written Until Something Is Changed | P1 | **Passing** | `suites/settings/` |
| TC-SET-004 | A Limit Typed And Confirmed Is Kept In The File | P1 | **Passing** | `suites/settings/` |
| TC-SET-005 | What Is Not A Size Is Said So And Not Kept | P1 | **Passing** | `suites/settings/` |
| TC-SET-006 | Reset Puts One Limit Back | P1 | **Passing** | `suites/settings/` |
| TC-SET-007 | Restore Defaults Puts Every Limit Back | P1 | **Passing** | `suites/settings/` |
| TC-SET-008 | A Limit Is Kept For The Next Start | P1 | **Passing** | `suites/settings/` |
| TC-SET-009 | A Limit That Was Typed But Not Confirmed Is Kept When The Window Is Closed | P2 | **Passing** | `suites/settings/` |
| TC-SET-010 | The Limit On Keeping A File On Disk Decides How A File Opens | P1 | **Passing** | `suites/settings/` |
| TC-SET-011 | A Settings File With Something Wrong In It Does Not Stop The App | P1 | **Passing** | `suites/settings/` |
| TC-SET-012 | A File That Is Not JSON Does Not Stop The App Either | P2 | **Passing** (the warning is read by its colour, not its words — see the note in the doc) | `suites/settings/` |
| TC-SET-013 | Advanced Is Closed At First And The Window Follows It | P1 | **Passing** | `suites/settings/` |
| TC-SET-014 | Hovering The Name Of A Limit Says What It Is For | P1 | **Passing** | `suites/settings/` |
| TC-SET-015 | Advanced Says How Many Of Its Limits Are Not The Default | P1 | **Passing** | `suites/settings/` |
| TC-SET-016 | A Window Opened With Many Complaints Is Tall Enough For Them | P2 | **Passing** | `suites/settings/` |
| TC-SET-020 | The Theme Is Kept For The Next Start | P1 | **Passing** | `suites/settings/` |
| TC-SET-021 | The Theme Is Kept Though The App Ends At Once | P2 | **Passing** | `suites/settings/` |
| TC-SET-022 | Autocomplete On Is Kept For The Next Start | P2 | **Passing** | `suites/settings/` |
| TC-SET-023 | The Size Of The Window Is Kept For The Next Start | P1 | **Passing** | `suites/settings/` |
| TC-SET-024 | A Maximized Window Is Maximized The Next Time | P2 | **Passing** | `suites/settings/` |
| TC-SET-025 | The Size Of The Panes Is Kept | P2 | **Passing** | `suites/settings/` |
| TC-SET-026 | The Panes Are As They Were Left | P2 | **Passing** | `suites/settings/` |

## Tools docked — [22_tools_docked.md](22_tools_docked.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-DOCK-001 | The Tools Window Has A Button That Docks It In The Main Window | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-002 | The Row Of Tabs Has Json Query First And A Tab For Each Tool | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-003 | The Tool That Was In Front In The Window Is In Front Docked | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-004 | What Was Typed In A Page Is Still There Docked | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-005 | The Theme And The Tutorial Are At The Right End Of The Row Of Tabs | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-006 | The Status Bar Has The Info, The Website, The Settings And The Undock Buttons | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-007 | The Undock Button Is In The Status Bar Whichever Tab Is In Front | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-008 | The Window Has No Undock Button | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-009 | The Undock Button Takes The Tools Out Into A Window | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-010 | Docking And Undocking Again Leaves A Page As It Was | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-011 | The Tools Start As A Window | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-012 | Docked Is Kept For The Next Start | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-013 | A Window Again Is Kept Too | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-014 | A Place The App Does Not Know Starts The Tools As A Window | P2 | **Passing** | `suites/tools/` |
| TC-DOCK-015 | Started Docked The Json Query Tab Is In Front | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-016 | The Json Query Tab Is The Main View With The Source Field Under The Row Of Tabs | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-017 | A Document Is Loaded And Queried In The Json Query Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-018 | The Source Field Loads A File In The Json Query Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-019 | A Visit To A Tool And Back Leaves The Json Query Tab As It Was | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-020 | Each Tool's Tab Shows Its Page | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-021 | Ctrl+Enter On A Tool's Tab Runs The Tool, Not The Query | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-022 | Ctrl+F And Ctrl+S Do Nothing On A Tool's Tab | P2 | **Passing** | `suites/tools/` |
| TC-DOCK-023 | The Status Bar Says What The Tab In Front Has To Say | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-024 | Format Takes The Document Open In The Json Query Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-025 | A Merged Document Opened In The Main Window Is Shown In The Json Query Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-026 | A Patched Document Opened In The Main Window Is Shown In The Json Query Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-027 | A Problem Shown In The Main Window Is Shown In The Json Query Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-028 | A File Dropped On The Json Query Tab Is Opened As The Document | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-029 | A File Dropped On A Tool's Tab Goes Into That Tool's Box | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-030 | Several Files Dropped On The Json Query Tab Go To Merge's Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-031 | The Theme Button In The Row Of Tabs Changes The Theme Of The Page In Front | P2 | **Passing** | `suites/tools/` |
| TC-DOCK-032 | The Settings And The Info Buttons Open Their Windows From A Tool's Tab | P2 | **Passing** | `suites/tools/` |
| TC-DOCK-033 | A Tools Window Maximized Over The Main Window Docks Into It | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-034 | A Docked Diff Compares Two Documents | P2 | **Passing** | `suites/tools/` |
| TC-DOCK-035 | The Tutorial Button In The Row Of Tabs Opens The Tutorial | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-036 | An Example Tried From A Tool's Tab Runs In The Json Query Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-037 | Diff Takes The Document Open In The Json Query Tab As One Of The Two | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-038 | The Document Open In The Json Query Tab Is Patched | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-039 | A Double-Click On A Problem Shows It In The Json Query Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-040 | A Big Merge Result Opened In The Main Window Is A File In The Json Query Tab | P1 | **Passing** | `suites/tools/` |
| TC-DOCK-041 | The Website Button Opens The Site From Whichever Tab Is In Front | P2 | **Passing** | `suites/tools/` |

## The website — [23_website.md](23_website.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-WEB-001 | The Status Bar Has A Globe Between The Info And The Settings Buttons | P1 | **Passing** | `suites/website/` |
| TC-WEB-002 | Hovering The Globe Says What The Site Is And Where A Click Goes | P1 | **Passing** | `suites/website/` |
| TC-WEB-003 | Clicking The Globe Opens The Website In The Browser | P1 | **Passing** | `suites/website/` |
| TC-WEB-004 | Every Click On The Globe Opens The Site Once | P2 | **Passing** | `suites/website/` |
| TC-WEB-005 | The Info And The Settings Buttons Work Beside The Globe And Open Nothing In The Browser | P1 | **Passing** | `suites/website/` |

## Text menus — [24_text_menus.md](24_text_menus.md)

| ID | Title | Priority | Status | Suite |
|---|---|---|---|---|
| TC-TXM-001 | The Query Box Has The Menu Of A Text Box | P1 | **Passing** | `suites/text_menus/` |
| TC-TXM-002 | Paste In The Menu Of The Query Box Puts The Clipboard In It | P1 | **Passing** | `suites/text_menus/` |
| TC-TXM-003 | Select All And Copy In The Menu Put The Whole Query On The Clipboard | P1 | **Passing** | `suites/text_menus/` |
| TC-TXM-004 | Cut In The Menu Moves The Query To The Clipboard | P1 | **Passing** | `suites/text_menus/` |
| TC-TXM-005 | A Right Click Inside A Selection Keeps It, So That Copy Copies Just That | P1 | **Passing** | `suites/text_menus/` |
| TC-TXM-006 | A Right Click Outside A Selection Puts The Caret There, And Copy Is Dim | P2 | **Passing** | `suites/text_menus/` |
| TC-TXM-007 | The Menu Of The Source Field Pastes A Path | P1 | **Passing** | `suites/text_menus/` |
| TC-TXM-008 | Paste In The Menu Of The Empty Source Panel Loads The Document | P1 | **Passing** | `suites/text_menus/` |
| TC-TXM-009 | The Results' Text View Has Copy And Select All, Not Cut Or Paste | P1 | **Passing** | `suites/text_menus/` |
| TC-TXM-010 | Select All And Copy In The Results' Text View Give All Of The Text | P1 | **Passing** | `suites/text_menus/` |
| TC-TXM-011 | A Word Taken In The Results' Text View Stays Taken Under A Right Click | P2 | **Passing** | `suites/text_menus/` |
| TC-TXM-012 | The Text View Of A Pasted Document Has The Menu Of A Box | P2 | **Passing** | `suites/text_menus/` |
| TC-TXM-013 | The Text View Of A File Has Copy And Select All, Not Cut Or Paste | P2 | **Passing** | `suites/text_menus/` |
| TC-TXM-014 | An Error In The Status Bar Is Copied With A Right Click | P2 | **Passing** | `suites/text_menus/` |
| TC-TXM-015 | The Find Field Has The Menu Of A Text Box | P3 | **Passing** | `suites/text_menus/` |
| TC-TXM-016 | A Hit Of Find All Copies Its Path Or Its Line | P3 | **Passing** | `suites/text_menus/` |
| TC-TXM-017 | Every Box Of The Tools Has The Menu Of A Text Box | P1 | **Passing** | `suites/tools/` |
| TC-TXM-018 | Paste In The Menu Of A Box Of A Tool Puts The Clipboard In It | P1 | **Passing** | `suites/tools/` |
| TC-TXM-019 | Select All And Cut In The Menu Of A Box Of A Tool Empty It Into The Clipboard | P2 | **Passing** | `suites/tools/` |
| TC-TXM-020 | The Result Of A Tool Is Text With Copy And Select All, Not Cut Or Paste | P1 | **Passing** | `suites/tools/` |
| TC-TXM-021 | An Error Of A Tool Is Text That Can Be Selected And Copied | P2 | **Passing** | `suites/tools/` |
| TC-TXM-022 | A Line Of The Side By Side View Copies Its Text | P1 | **Passing** | `suites/tools/` |
| TC-TXM-023 | The Menu Of A Line Being Typed Over Is That Of A Box, And The Typing Goes On | P1 | **Passing** | `suites/tools/` |
| TC-TXM-024 | A Change In The List Copies Its Path Or Its Line | P2 | **Passing** | `suites/tools/` |
| TC-TXM-025 | A Problem In The List Copies Its Path, Its Message Or Its Line | P2 | **Passing** | `suites/tools/` |
| TC-TXM-026 | Ctrl+A In A Text View Takes All Of Its Text, As Select All In The Menu Does | P3 | **Passing** | `suites/text_menus/` |

## Coverage summary

**2026-10-20, the right-click menu of a text:** 731 → 760 cases in 29 suites (TC-TXM-001 to 026, TC-SAT-049 to 051). Before the change a text had no menu (egui gives a box its keys and nothing else), and a right click on a selection threw the selection away. The cases: Paste, Cut, Copy and Select All in the query box and the source field, a right click inside a word that was taken keeps it (and Copy gives that word), one outside it does not (001 to 007); Paste in the empty Source pane loads a document (008); the Results' Text view, a file's Text view, a message in the status bar, the Find field and the hits of Find All (009 to 016, 026); every box of the Tools, Paste and Cut in one, the result and the error of Format as text that can be copied (017 to 021); the lines of the side-by-side view copy their text, the line being typed over has a box's menu and goes on being typed over, the Changes list and Validate's problems copy their path, message or line (022 to 025); the About window's version, its links and a known issue (TC-SAT-049 to 051). Run in a window of the Tools and docked (the main-view pass has 17 of them, the tools pass 9). Thirty-three faults, one at a time, each killed ([24_text_menus.md](24_text_menus.md), T1 to T33). The whole suite found two things: the error text's font (above, a fault of the change, fixed) and the menu of a changed side-by-side line, which now opens above the pointer near the foot of the window (TC-DIF-010 found its item by distance, and now by OCR).

**2026-10-20, a key that an object has more than once, in Diff JSON:** 725 → 731 cases in 27 suites (TC-DIF-042 to 047). Before the change the last member of a key was compared and the others dropped, with nothing said (the Left box had 28 lines, the view 19). The cases: each member is a line and the one the other lacks has a blank across (red, nothing as bright as 100 in the right column), the menu of that line copies `/a#3`, the Patch view says it leaves out 2 changes and Copy patch gives `[]` (042); several repeated keys with no line over the page (043); a picked line moved into the other document and saved with both members (044); a line typed over the second of two members, saved (045); the open document read again from its file (046), and one pasted, which has none, saying that only the last member of each key is compared (047). Nine faults put into the app one at a time, each in a build of its own: see the table in [13_tools_window.md](13_tools_window.md) (G1 to G9).

**2026-10-20, the About window's known issues:** 716 → 725 cases in 27 suites (TC-SAT-040 to 048), and TC-SAT-026 at 380×330. The header, the list opened (640 wide, as tall as it needs), shut again (the size it had), opened afresh (shut), a window already wider (it stays), the example of a line, the link to the page, and a window too small (it scrolls). They were written after the window was approved by the owner and passed on the first run, so they were then run against 16 mutants of the app (S1 to S16 in the document): 12 killed; the ones that live are a header slide that lasts a fifth of a second, an equivalent mutant, and two limits (the 9/10-of-the-screen height and the least size) that this display and `xdotool` do not reach. One finding: the window manager puts About at the screen corner under the pointer, so a window made bigger there leaves the display; the cases drag it to the top left first, as a person would.

**2026-10-19, writes through `null`, `del`, `scan`, `join`, `from_entries`, `@base64d`:** 698 → 716 cases in 27 suites (TC-JQX-099 to 116). Before the change `.metadata.labels.env = "prod"` failed whenever `labels` was not there, `del(.[1, 2])` took the wrong items, `scan` found the first match only, `join` wrote `null` as text, `from_entries` knew only `key`/`value`, and `@base64d` refused a JWT segment without padding; the cases ask for jq's answers, and for an error (and a window that answers the next query) where an index is too far past the end. 18 of 18 passed; 13 app mutants (M18 to M30) are caught. The Rust crate tests the same from the inside (1,166 cases with jq 1.8.1's own answers, random documents against a model, mutants).

**2026-10-19, the hang and the crash:** 689 → 698 cases in 27 suites (TC-JQX-090 to 098). Before the fix `"abc" | tonumber` and
`"N/A" | fromjson` never ended (the one worker thread was lost with them) and a result nested about 2,000 levels deep closed the
app; the cases ask for an error, for the window to answer the next query, and for a deep result cut at 127 levels and
written as text by `tojson` and by string interpolation. The run: `jq_functions` (with the nine new cases), `query_engines` and
`output_formats` together, 152 of 152. The Rust crate tests the same from the inside (the original reports, 475,255 strings over
the characters of JSON, the depth limits).

**2026-10-11 night, the website button:** 680 → 689 cases in 27 suites (TC-WEB-001 to 005, TC-SAT-024 to 026, TC-DOCK-041).
The last full runs (the debug build): `run_parallel.sh -j 5`, 688 of 689; `run_docked.sh -j 5`, the tools pass 151 of 151 and
the main-view pass 467 of 468. The one failure, TC-OPEN-036 in both profiles, was OCR reading `0 result(s)` as `0O result{s)` in a
status line that goes on with a long error under the icons (the app did what it should); it reads the part with the count now
and passed 3 of 3 undocked and 2 of 2 docked. Twenty-three one-place faults put into the app (M01 to M21, N01 and N02,
[23_website.md](23_website.md)): the 21 meant to be seen were killed, the two that are not (N01, N02) survive as said. The
stand-in browser and the check in the teardown came out of it: the ⚙ pixel had become the 🌐's, and a stand-in that was not
executable let one click through to a real browser. The app had no defect to fix; the one thing seen is that a long status error
runs under the icons at the right end of the bar, as it did before the 🌐.
The paragraph about the site that the About window had during those runs was taken out afterwards, on request: TC-SAT-024
now fails if the paragraph is there (it did, against the build that still had it), TC-SAT-024 to 026 passed 3 of 3 on the new
build (380 × 300 when it opens, 320 × 300 the least), and M17 and M19, the two faults about the paragraph, are retired.

**2026-10-11 evening, the Tools docked, run both ways:** 640 → 680 cases in 26 suites (TC-DOCK-001 to 040, the
rest unchanged). The last full runs: `run_parallel.sh -j 5`, 679 of 680 (TC-DIF-029, a Ctrl+click that was not
delivered, failed in that run and passed three times in a row alone); `run_docked.sh`, the tools pass 151 of 151 and the
main-view pass 460 of 461 (TC-SET-001: the foot of the Settings window wrapped because the lane's folder was a long
path; the settings folder is made with a short path now, and the settings suite, run again in a lane folder that deep,
docked and not, passed 23 of 23). A first docked pass of the main view had 54 failures, every one a point that the row of
tabs moves differently or that the app places by the window (the Search dialog and its list of hits, the source row's
buttons and labels, the 🗗 in the status bar): each is named in `resources/docked_main.py`. Twenty one-place faults put into
the app (E01 to E20, [22_tools_docked.md](22_tools_docked.md)) were all killed; the one that survived at first (Ctrl+F on a
tool's tab) showed a negative check that looked outside the window, and was fixed. The app had no defect to fix.

**2026-10-06, heavy files, in two steps.** The first (a file is memory-mapped only from 64 MiB, a pipe is read,
a download leaves nothing behind): 578 → 582 cases, TC-OPEN-029 to 032 in `suites/opening_sources/heavy_files.robot`;
run against the build from before it, TC-OPEN-030, 031 and 032 fail (the pipe loads as `(0 items)`; the temp
files the download left are named in the message) and TC-OPEN-029 passed. The second (a file of 256 MiB or more
is not parsed but kept on disk, mapped and indexed; long lists are shown in runs; queries read the file as they
go): 582 → 588 cases, TC-OPEN-033 to 038 added and TC-OPEN-029 and 032 moved to files of 270 MiB. Run against a
build in which no file is ever indexed, TC-OPEN-029 and 032 fail on `Parsed in`, 033 on the memory (553.9 MiB),
034 on the missing runs, 035 on the memory (595.8 MiB), and 036 and 037 because nothing is refused; TC-OPEN-038
passes there, as it should. That run also showed that a parsed document with a string of 190,000 characters in a
row closed the window, which the preview of a row (its first kilobyte) now prevents.

**2026-10-06, heavy files, third step** (what did not work on a file kept on disk is fixed where it can be:
`sort_by`, `group_by` and `..`; JSONPath and JMESPath; a key repeated in an object; a file cut short while it
is open, which ended the app; Format in the Tools window): 588 → 593 cases. TC-OPEN-036 and 037 are rewritten
(`to_entries` is the program that is still refused; JSONPath and JMESPath are run on 4.5 million records),
TC-OPEN-039 to 042 and TC-FMT-080 are new, and the check that a query is done reads "Query ran in" as well
as "result(s)" (OCR read the latter as `resulkt{s)` for some timings). The last full run (`run_parallel.sh`,
four lanes, a release build) passed: 593 of 593. TC-OPEN-039 was run against a build in which the mapping is
not watched, and fails (the app ends with SIGBUS).

**2026-10-06 pass** (the jq functions the app adds, CSV and TSV output, the tutorial pages
for them, and the file dialogs): 369 → 578 cases in 22 suites. The last full run (`run_parallel.sh`, six lanes, about 15 minutes, a fresh build of the app) passed: 578 of 578; the run before it had passed 577, the one failure being an OCR misread of a URL in TC-TOOL-001, which now reads the field through the clipboard. The suite now answers the
native file dialogs through a stand-in portal, so every case that was **Blocked** is implemented
(13 rows: TC-OPEN-001/002, TC-TOOL-006, TC-CTX-004, TC-SAVE-001/003/004/006/007/008/009/010 and
TC-KEY-003; TC-SAVE-008 is a race and became Not implemented) and the Tools window's own dialogs
are covered too (TC-TDLG-001 to 009). It found no defect in the CSV/TSV, jq-function or tutorial
code; it found the Save… finding of TC-SAVE-011, a wrong sentence in the older version of
`09_saving.md` (a save was said to hold only the capped preview), and showed that the harness needed
a stand-in for the file portal, progress-aware waits for big files and temporary files on disk
(see [writing_tests.md](writing_tests.md)). The figures below are the older passes'.

**2026-10-04 evening pass** (after the Tools redesign, the side-by-side Diff, the
pane headers and the satellite windows): `tools` 12 → 130, `satellites`
20, `pane_headers` 10, `drag_and_drop` 18, `popout` 16 → 25 —
and TC-OPEN-010/011 (drag-and-drop) are now covered. The suite found one real bug
(Diff's Compare dropped its request) and showed that the harness needed raising of
windows, a real XDND source and pixel probes; see
[00_test_strategy.md](00_test_strategy.md). The figures below are the older passes'.

- Total test cases defined: **149** distinct IDs (counting `TC-TOOL-007a-d`
  as one row of four data-driven variants) across 10 feature areas. (107 from
  the original requirements pass, plus 17 query-correctness cases —
  TC-QRY-023–027, 034–036, 042–045, 052–056 — added in the third
  implementation pass to broaden per-engine query coverage beyond the
  original auto-detect/error-semantics focus.)
- P1 (release-blocking core correctness): 33.
- **116 test cases actually implemented and run**, across 10 suites under
  `suites/` — `launch_and_window` (4), `opening_sources` (12),
  `query_engines` (39), `toolbar_and_status` (5), `tree_view` (4),
  `text_view` (7), `context_menus` (5), `search` (34), `keyboard_shortcuts`
  (4), `saving` (2) — **all passing**, confirmed green across multiple
  consecutive full-suite runs via `run.sh` during implementation (see
  00_test_strategy.md's flakiness note for the residual, mitigated-not-
  eliminated exceptions, and this doc's own note above about `<` typing
  under TC-QRY-044). A further 8 requirement IDs are marked Passing by
  cross-reference to one of those 91 (same underlying code path, deliberately
  not re-implemented as a separate test — see each area's own note above),
  for **124 of the 149 IDs covered**.
- **Blocked: none now.** There were 12 (13 rows) until 2026-10-06 — every case needing the native
  file dialog (the `…` button) or a Save dialog to complete (TC-OPEN-001/002, TC-CTX-004,
  TC-SAVE-001/003/004/006/007/008/009/010, TC-KEY-003, TC-TOOL-006); the root cause (`rfd`'s portal
  backend hangs or errors before a dialog a test can drive) is in
  [00_test_strategy.md](00_test_strategy.md), together with the stand-in portal that answers the
  dialogs now.
- **Not implemented, changes of 2026-10-06**: TC-SAVE-008 (a race the harness cannot time) joins
  the list below, and TC-SAVE-011 (a finding, see [09_saving.md](09_saving.md)) is new; TC-OPEN-010/011 had
  left it on 2026-10-04. Its count below is the older passes'.
- **Not implemented: 12** whole IDs (TC-WIN-004, TC-OPEN-007/010/011,
  TC-QRY-022/062, TC-TREE-004, TC-TXT-002/003/005, TC-SRCH-006, TC-KEY-007),
  plus 2 of TC-SRCH-007's 3 sub-cases (only the Clear sub-case is
  implemented, as TC-SRCH-007c) — a mix of genuine gaps (P3 mostly: oversized
  download, drag-and-drop, native text-editing smoke, 50,000/5,000-item
  caps, min-window-size enforcement) and cases judged not worth the
  automation cost relative to their value (streamed-results timing, a
  sub-frame "Rendering…" transient, exact scroll-position assertions, a
  genuine query-cancellation race). None of these represent app defects —
  every one is a testing-technique or cost/benefit call, documented
  individually above with its specific reason.
- Everything else not listed as "Not implemented" above is either Passing
  or explicitly a duplicate/cross-reference of another Passing case (e.g.
  TC-CTX-005/TC-SRCH-022, TC-TREE-006, TC-KEY-001/005) — deliberately not
  re-implemented as a separate test when an existing one already exercises
  the identical code path, per each area's own doc.
