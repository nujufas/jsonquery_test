# CSV and TSV output — test requirements

Source: `crates/query/src/output.rs` (`OutputFormat`, `rows`, `rows_text`, `rows_bounded`,
`write_rows`), `crates/app/src/app.rs` (`results_format`, `results_panel`, `format_note`,
`save_results`, `save_results_node`, `copy_results_node`) and `crates/app/src/worker.rs`
(`Command::{SaveResults, CopyNode, RenderText}`, which carry the format) in
[jsonquery_gui](https://github.com/nujufas/jsonquery_gui).

## What the app does

A jq query whose **last top-level step is `@csv` or `@tsv`** makes one string per result, each a
row of a table. Written as JSON, that is `"\"Ada\",36"`: quoted, escaped, no use in a spreadsheet.
So the app writes such results as the rows they are, one to a line:

- **Copy to Clipboard** on the Results root copies every row, joined by line breaks (none after
  the last); on one result it copies that row;
- the Results **Text view** shows the rows;
- **Save…** (the header button, the root's and a row's menu, Ctrl+S) writes the rows, each ending
  in a line break, to a file whose suggested name is `results.csv` / `results.tsv` (a row:
  `item_N.csv`) and whose file type is `CSV` / `TSV`;
- a dim note, **CSV** or **TSV**, stands beside the Tree and Text toggles, and its tooltip says
  why ("The query ends in @csv, so each result is a row of CSV text. …"). Save…'s tooltip says
  "Save the results as CSV: one row to a line." — only while the results are rows.

What decides it is `OutputFormat::detect(engine, query)`, read when the query *runs*: only jq
queries; only the last step (what follows the final `|` outside brackets, strings and `if … end`),
so `map(… | @csv) | length` is JSON and so is `[ … | @csv ]`; a parenthesised last step is read
inside; a `?` after `@csv` and a trailing comment are ignored. Anything it cannot read is JSON,
which is always a correct way to write a result. The Source pane is always JSON.

## How a case checks

Exact text, not OCR:

- **The clipboard.** `Copy All Results` right-clicks the Results root and chooses *Copy to
  Clipboard*; `Copy Result Row n` does it on a row. The clipboard is set to a marker first, so a
  menu item that does nothing fails. (The menu's items are clicked by their distance from the
  pointer: OCR cannot read a menu laid over a row of backslashes.)
- **The Text view.** `Copy Results Text View` presses on the first character of the view's text
  (it is a selectable label), drags to the far corner and presses Ctrl+C — what a person does.
- **Files.** The file dialog is answered by a stand-in for the desktop's file-chooser portal
  (`resources/fake_portal.py`, see [writing_tests.md](writing_tests.md)): the test says what the
  person chooses (`Portal Will Save To`, `Portal Will Accept Suggested Name In`, `Portal Will
  Cancel`), reads back what the app asked for (`current_name`, `filters`) and then reads the file
  the app wrote.
- **The note.** It is dim text (about 95 of 255 on a 27 background), too dim for OCR: its
  presence is a pixel probe (`Get Ink Bounds`, `Region Should Be Plain` for its absence) and
  what it says is read from its tooltip, which is plain text.

Fixtures: `people.json`, `team.json`, `awkward_text.json` (a comma, doubled quotes, a line break,
a tab and a backslash in values — the file the tutorial's quoting page uses too) and
`unicode.json` (accents, Chinese characters, a ring).

## Cases (`suites/output_formats/`)

| ID | Title | Priority |
|---|---|---|
| TC-FMT-001 | A JSON result has no format note | P1 |
| TC-FMT-002 | A query ending in @csv shows the CSV note (and its tooltip) | P1 |
| TC-FMT-003 | A query ending in @tsv shows the TSV note | P1 |
| TC-FMT-004 | The note follows the last query that ran (CSV, JSON, TSV) | P1 |
| TC-FMT-005 | Editing the query without running it leaves the note alone | P2 |
| TC-FMT-006 | @csv before the last stage does not make rows | P1 |
| TC-FMT-007 | A query wrapped in brackets is JSON | P1 |
| TC-FMT-008 | A parenthesised last stage still counts | P2 |
| TC-FMT-009 | A trailing comment does not hide the format | P2 |
| TC-FMT-010 | The try operator after @csv is still CSV | P3 |
| TC-FMT-011 | Another engine never writes rows | P2 |
| TC-FMT-012 | Clear removes the note | P2 |
| TC-FMT-013 | Loading another document removes the note | P2 |
| TC-FMT-014 | Save says which format it will write | P2 |
| TC-FMT-020 | The Tree lists one row per result | P2 |
| TC-FMT-021 | The Text view shows the rows | P1 |
| TC-FMT-022 | The Text view of TSV keeps its tabs and escapes | P1 |
| TC-FMT-023 | The Text view of CSV keeps a line break inside a field | P2 |
| TC-FMT-024 | The Text view of JSON results is pretty JSON | P1 |
| TC-FMT-025 | Switching between Tree and Text keeps the rows | P2 |
| TC-FMT-026 | A long list of rows is cut short in the Text view, and Expand All shows them all | P2 |
| TC-FMT-030 | Copying all CSV results gives the rows | P1 |
| TC-FMT-031 | Copying one CSV row gives that row | P1 |
| TC-FMT-032 | Copying all TSV results gives tabbed rows | P1 |
| TC-FMT-033 | Copying one TSV row gives that row | P1 |
| TC-FMT-034 | CSV quoting is exact | P1 |
| TC-FMT-035 | TSV escaping is exact | P1 |
| TC-FMT-036 | Non-ASCII text survives | P1 |
| TC-FMT-037 | JSON results still copy as JSON | P1 |
| TC-FMT-038 | A wrapped @csv query copies JSON strings | P1 |
| TC-FMT-039 | The Source pane still copies JSON | P1 |
| TC-FMT-040 | A single row has no line break after it | P2 |
| TC-FMT-041 | A header row and then the data rows | P1 |
| TC-FMT-042 | Numbers, booleans and null in a row | P1 |
| TC-FMT-043 | An empty result has no rows and nothing to save | P2 |
| TC-FMT-044 | A row that cannot be made is an item error; the others survive | P1 |
| TC-FMT-045 | Copying a long list of rows (25,000) gives every row | P2 |
| TC-FMT-050 | Saving CSV results writes the rows (name `results.csv`, type CSV) | P1 |
| TC-FMT-051 | Saving TSV results writes tabbed rows (name `results.tsv`, type TSV) | P1 |
| TC-FMT-052 | Saving JSON results still writes pretty JSON (`results.json`, type JSON) | P1 |
| TC-FMT-053 | Cancelling the dialog writes nothing | P1 |
| TC-FMT-054 | A row saved from its menu is written as that row (`item_1.csv`) | P1 |
| TC-FMT-055 | The root saved from its menu is every row | P2 |
| TC-FMT-056 | Awkward rows are saved exactly | P1 |
| TC-FMT-057 | Non-ASCII text is saved as UTF-8 without a byte order mark | P1 |
| TC-FMT-058 | A result past the live preview is saved whole (60,000 rows) | P2 |
| TC-FMT-059 | The file follows the latest query | P1 |
| TC-FMT-060 | Ctrl+S in the Results pane saves the rows | P2 |
| TC-FMT-061 | A name the person chose is used as given | P2 |
| TC-FMT-062 | Saving into a missing folder says so | P2 |
| TC-FMT-063 | The Source pane saves JSON whatever the results are | P1 |
| TC-FMT-070 | The popped-out Results pane has the note | P2 |
| TC-FMT-071 | The popped-out Results pane has no note for JSON | P2 |
| TC-FMT-072 | Copying from the popped-out pane gives rows | P1 |
| TC-FMT-073 | Saving from the popped-out pane writes the rows | P1 |

## Findings

- **The Results Tree still shows each row as a JSON string** (`"\"Ada\",36"`): only Copy, Save and
  the Text view write rows. The note beside Tree and Text, and its tooltip, are what say so
  (TC-FMT-020 checks only that there is one row per result). Left alone deliberately in the app.
- **`@csv, @tsv` and `a | @csv, b` are not read as rows**: the last stage is the whole comma
  expression, which the detector does not look into, so the results are JSON. TC-JQX-065 relies on
  it; wrapping the call in parentheses, as TC-FMT-008 does, makes it a row.
- **Rows past the live preview.** The Results pane keeps the first 50,000 results; Save… runs the
  query again without the cap first, and writes all of them (TC-FMT-058 for CSV, TC-SAVE-006 for
  JSON). `09_saving.md` used to say a save only held the preview.
- **The Text view is capped at 20,000 rows** and says so in a dim notice ("Showing the first 20000
  nodes — use Tree view, or Save… for the full results."), which OCR cannot read; what TC-FMT-026
  checks is the bright **Expand All** button beside it (present for 25,000 rows, absent for 30, gone
  after pressing it). OCR reads the button as `Expand/All`, so the case looks for its first word.
  The notice says "nodes" for rows too; that is the app's wording, left alone. Copy to Clipboard
  does not depend on the view (TC-FMT-045: all 25,000 rows, first and last right).

## Mutation checks

Each case was run against builds of the app with one thing broken (a one-place source change); a
case that cannot fail checks nothing. Every mutant below was killed, and not by accident: each fails
at the intended assertion (the failure message is the difference the mutant makes).

| Mutant | What is broken | Killed by |
|---|---|---|
| M1 | the format is never detected (rows are never made) | 39 cases: every one that looks for the note, the rows, a copy or a save as rows |
| M2 | Copy to Clipboard on the Results ignores the format | 14: TC-FMT-009, 025, 030–036, 040–042, 044, 072 |
| M3 | the header Save writes JSON whatever the format | 8: TC-FMT-050, 051, 056, 057, 059, 060, 061, 073 |
| M4 | the header Save always suggests `results.json` | 8: TC-FMT-050, 051, 056, 057, 058, 059, 060, 073 |
| M5 | the Text view ignores the format | 3: TC-FMT-021, 022, 023 |
| M6 | `@csv` does not double a quote inside a string | TC-FMT-034, 056 (and TC-JQX-061, TC-TUT-026) |
| M11 | the note is drawn for JSON results too | 8 of the 14 note cases: TC-FMT-001, 004, 005, 006, 007, 011, 012, 013 |
| M12 | Ctrl+S in the Results pane saves nothing | TC-FMT-060 |
| M14 | a save past the live preview writes only the preview | TC-FMT-058 (and TC-SAVE-006) |
| M23 | the Text view of rows never says it is cut short | TC-FMT-026 |
| M24 | copying rows stops at 20,000 | TC-FMT-045 |

Two failures in the first runs of M2 and M4 (TC-FMT-003/004 and 003) were `Disk quota exceeded` from
a full `/tmp` and not kills; they pass under both mutants when re-run with the temporary files on disk.
