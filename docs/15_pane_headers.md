# Pane headers — test requirements

Source: `crates/app/src/pane_header.rs` (the title and the right-pinned controls
every header is made of), `App::source_pane` / `results_panel` in
`crates/app/src/app.rs`, and `tools/widgets.rs::header` (the same pieces in the
Tools window).

Since 2026-10-04 a pane's header is compact:

- the title ("Source", "Results", and the Tools window's "Input", "Result", …) is
  **14px strong text**, not an 18px heading, so the header row is as tall as its
  buttons (18px, y 134–152 in the main window) instead of 21.5px;
- **nothing is drawn under a header**: the line above the panes (the query panel's
  edge, y=125) is the only divider, so what is under a header — the tree, the
  empty pane's hint — starts 12px higher than it did (y=155 instead of 167);
- the Source pane's own window has a **source field row** on top, so its header
  is lower than the Results window's (y=41; see [12_popout_panes.md](12_popout_panes.md)).

OCR cannot say how big text is, or whether a line is drawn, so these cases look
at pixels (`Get Ink Bounds`, `Region Should Be Plain`, `Region Should Contain
Color` in AppLibrary), measured on screenshots of the 1200×800 window:

| What | Measured |
|---|---|
| "Source" title glyphs | x 8–49, y 138–147 (10px tall; the old heading: 12px) |
| "Results" title glyphs | x 609–652, y 137–147 (11px; the old heading: 14px) |
| strip under each header | bare background (the old layout had a line at y=160) |
| first line of the Source tree | text starts at y=159 (6px under y=153; the old layout: 18px) |
| first line of the empty hint | text starts at y=157 (4px under y=153; the old layout: 16px) |

## Cases (`suites/pane_headers/`)

| ID | Title | Priority |
|---|---|---|
| TC-HDR-001 | The panes' titles are small | P1 |
| TC-HDR-002 | There is no line under the headers | P1 |
| TC-HDR-003 | There is no line under the headers of empty panes either | P1 |
| TC-HDR-004 | The panel's edge is the one divider | P1 |
| TC-HDR-005 | The tree starts right under the header | P1 |
| TC-HDR-006 | The empty Source pane's hint is right under its title | P2 |
| TC-HDR-007 | The headers still have their controls | P1 |
| TC-HDR-008 | No line under a header in the Light theme | P2 |
| TC-HDR-009 | The Source window has the same small title and no line | P1 |
| TC-HDR-010 | The Tools window's panes have the same titles | P1 |

**Mutation-checked** against the build of the commit before the change (18px
headings, a line under each header, no source row): TC-HDR-001, 002, 003, 005,
006, 008 and 009 fail there, and pass on the new layout. TC-HDR-004 (the one
divider is still there), 007 (the controls are all there) and 010 (the Tools
window's title) guard against the change going too far rather than against the
old layout.

The headless tests in `crates/app/src/app/layout_tests.rs`
(`a_panes_title_is_smaller_than_a_heading_and_has_no_line_under_it`,
`the_empty_source_panes_hint_comes_straight_under_its_header`,
`the_tools_boxes_have_the_same_small_titles_and_no_line_under_their_headers`,
…) pin the same things numerically; the Robot cases are the check on real windows,
real fonts and real pixels.
