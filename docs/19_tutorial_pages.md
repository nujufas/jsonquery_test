# Tutorial pages for the jq functions — test requirements

Source: `crates/query/src/tutorial/jq.rs` (the lessons) and `crates/app/src/tutorial.rs` (the
window) in [jsonquery_gui](https://github.com/nujufas/jsonquery_gui). The window itself — opening,
closing, tabs, the buttons' hand-off, themes — is covered by `satellites`
([14_tutorial_and_about_windows.md](14_tutorial_and_about_windows.md)); this document is about the
**lessons** that teach the functions the app adds ([17_jq_functions.md](17_jq_functions.md),
[18_output_formats.md](18_output_formats.md)).

## The pages

The jq tab has two topics for them, one page per feature, and two cheat-sheet rows:

| Topic | Pages |
|---|---|
| **Tables & lookups** | CSV & TSV · Records to a table · Quoting & escaping · Copy & save as CSV or TSV · IN · INDEX & JOIN |
| **Event streams** | tostream · fromstream & truncate_stream |
| *Reference* | the **Cheat sheet** has rows for `@csv`, `INDEX`, `IN` and `tostream`; **jq here vs jq 1.7** says jsonquery adds the functions jaq lacks and lists what is still missing |

Each page has a short summary, one to three examples (a caption, the query with its explained
fragments tinted, four buttons — ▶ Try it, Load query, Load data, Copy query — the live result
and an explanation) and a few *Good to know* tips. The examples run on the real engine, so the
result on the page is not a pasted copy; the app's own test `every_filter_jsonquery_adds_has_a_lesson`
fails if one of the functions loses its page.

## How a case checks

- **Finding a page.** The filter box leaves only the lessons that mention the typed text (title,
  summary, an example's query or caption, a cheat-sheet row). `Show Lesson` types a text that only
  one lesson has and clicks the first row. The row's click point is at x=36: a selectable label is
  only as wide as its title, and "IN" ends at x=43.
- **What OCR reads.** The big title and the example captions are read. A two-letter title (`IN`)
  is not read reliably, nor is the jq/iq label, nor the small grey summary: for those the body is
  checked instead.
- **Every example is run in the main window, exactly.** `Try Example` finds the example by its
  caption, scrolls to it, presses its ▶ Try it, waits until the query has run in the main window
  and `Results Should Be Json` / `Results Should Be Text` read the results back through
  Copy to Clipboard. The expected values are what jq 1.8.1 prints for the same query over the
  tutorial's data.
- **The buttons are found by colour.** ▶ Try it is the only control filled with the selection
  blue; OCR reads its white-on-blue label as "Tryit" or not at all. The other three buttons are at
  fixed distances to its right.
- **A cheat-sheet row** is found by its description and its own ▶ (at the row's left, x=294) is
  pressed.

## Cases (`suites/tutorial_pages/`)

| ID | Title | Priority |
|---|---|---|
| TC-TUT-001 | The @csv Filter Lists The Four Table Pages | P1 |
| TC-TUT-002 | The tostream Filter Lists The Event Stream Pages | P1 |
| TC-TUT-003 | The INDEX Filter Finds The Page And The Cheat Sheet | P2 |
| TC-TUT-004 | Another Language Has No Table Pages | P2 |
| TC-TUT-005 | Both Topics Are In The List | P1 |
| TC-TUT-006 | Next Goes From CSV & TSV To Records To A Table | P1 |
| TC-TUT-007 | Next Goes On From The Last Table Page Into The Next Topic | P2 |
| TC-TUT-008 | Previous Goes Back From The First Event Stream Page | P2 |
| TC-TUT-009 | The Last Event Stream Page Leads On To Errors | P3 |
| TC-TUT-010 | CSV & TSV Opens With Its Examples And Tips | P1 |
| TC-TUT-011 | Records To A Table Opens With Its Examples And Tips | P1 |
| TC-TUT-012 | Quoting & Escaping Opens With Its Examples And Tips | P1 |
| TC-TUT-013 | Copy & Save As CSV Or TSV Opens With Its Examples And Tips | P1 |
| TC-TUT-014 | IN Opens With Its Examples And Tips | P1 |
| TC-TUT-015 | INDEX & JOIN Opens With Its Examples And Tips | P1 |
| TC-TUT-016 | tostream Opens With Its Examples And Tips | P1 |
| TC-TUT-017 | fromstream & truncate_stream Opens With Its Examples And Tips | P1 |
| TC-TUT-018 | The Compatibility Page Says The Functions Are Added | P2 |
| TC-TUT-020 | CSV & TSV: One CSV Row Per Member | P1 |
| TC-TUT-021 | CSV & TSV: A Header Row First Tab-Separated | P1 |
| TC-TUT-022 | CSV & TSV: Missing Values Are Empty Fields | P1 |
| TC-TUT-023 | Records: Header And Rows From One List Of Columns | P1 |
| TC-TUT-024 | Records: A List In One Cell | P1 |
| TC-TUT-025 | Records: An Object As Two Columns | P2 |
| TC-TUT-026 | Quoting: CSV Quotes Strings And Doubles The Quotes Inside | P1 |
| TC-TUT-027 | Quoting: TSV Quotes Nothing And Escapes Instead | P1 |
| TC-TUT-028 | Quoting: Only An Array Makes A Row | P2 |
| TC-TUT-029 | Copy & Save: The Last Step @csv Makes Rows | P1 |
| TC-TUT-030 | Copy & Save: Not The Last Step Is Still JSON | P1 |
| TC-TUT-031 | IN: Members Whose Role Is One Of Several | P1 |
| TC-TUT-032 | IN: Is Any Member In QA | P1 |
| TC-TUT-033 | IN: Skills That Are Not On A List | P1 |
| TC-TUT-034 | INDEX: A Lookup Table By Code | P1 |
| TC-TUT-035 | INDEX: Look Up The Customer Of Every Order | P1 |
| TC-TUT-036 | INDEX: JOIN Does The Matching | P1 |
| TC-TUT-037 | tostream: The Events Of A Small Value | P1 |
| TC-TUT-038 | tostream: Every Leaf As Path = Value | P1 |
| TC-TUT-039 | tostream: Where Is A Value | P1 |
| TC-TUT-040 | fromstream: Events Written By Hand | P1 |
| TC-TUT-041 | fromstream: Drop A Field From Every Record | P1 |
| TC-TUT-042 | fromstream: One Result Per Order | P1 |
| TC-TUT-050 | Load Query Puts The CSV Query In The Main Window And Nothing Else | P1 |
| TC-TUT-051 | Load Data Opens The Sample Document | P1 |
| TC-TUT-052 | Copy Query Copies The Query Exactly | P1 |
| TC-TUT-053 | Try It Replaces The Open Document And Query | P1 |
| TC-TUT-054 | A Page's Rows Can Be Saved As They Are | P1 |
| TC-TUT-060 | Cheat Sheet: One CSV Row Per Member | P1 |
| TC-TUT-061 | Cheat Sheet: A Lookup Table Keyed By Name | P1 |
| TC-TUT-062 | Cheat Sheet: Keep When The Value Is One Of Several | P1 |
| TC-TUT-063 | Cheat Sheet: The Value As Events | P1 |

## Findings

- **Two lessons mention the same words.** The first filter for the Copy & save page was "save as
  csv", which the CSV & TSV page also contains (it names the other page in its summary), so the
  first row was the wrong lesson; the heading check caught it. The filters now are phrases of an
  example caption that no other lesson has.
- **The tutorial lists `IN` as the only title narrower than its own click target.** A click at
  the middle of the row missed it, so no page opened. See the click point above.
- The pager's *Next* and *Previous* buttons cross the topic boundaries as the doc says
  (TC-TUT-006 to 009).

## Mutation checks

| Mutant | What is broken | Killed by |
|---|---|---|
| M6 | `@csv` does not double a quote | TC-TUT-026 |
| M7 | `IN` asks the opposite question | TC-TUT-031, 033, 062 |
| M8 | `tostream` leaves out its closing events | TC-TUT-037, 041, 042, 063 |
| M9 | `INDEX` keeps the first of several elements with one key | **survives**: every example of the page has distinct keys (TC-JQX-023 kills it) |
| M10 | the page "INDEX & JOIN" is called "INDEX and JOIN" | TC-TUT-003, 007, 015, 034, 035, 036 |
