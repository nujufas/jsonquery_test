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

**Status as of 2026-10-06: 22 suites, 593 test cases** — the 369 of the evening
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
| TC-CTX-007 | No context menu outside tree rows | P3 | **Passing** | `suites/context_menus/` |

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
| TC-DIF-010 | Clicking A Difference Copies Its Path | P1 | **Passing** | `suites/tools/` |
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

## Coverage summary

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
