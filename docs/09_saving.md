# Saving — test requirements

Source: `crates/app/src/app.rs` (§Saving: `save_source`, `save_source_node`, `save_results`,
`save_results_node`), `crates/app/src/worker.rs` (the write: `Command::SaveFile`,
`Command::SaveResults`) and `crates/query/src/output.rs` (`write_rows`).

Every save asks for a file name with a native `rfd` dialog. Since 2026-10-06 the harness can answer
it: a stand-in for the desktop's file-chooser portal (`resources/fake_portal.py`, see
[writing_tests.md](writing_tests.md)) says what the person chooses and records what the app asked
for — the suggested name and the file types — and the test then reads the file the worker wrote.
That is what turned the cases that used to be **Blocked** into the ones below
(`suites/saving/saving_dialogs.robot`). Saving *rows* — a query that ends in `@csv` or `@tsv` —
is in [18_output_formats.md](18_output_formats.md); here it is the document, its rows and JSON
results. A save of JSON is pretty-printed, two spaces.

## Test cases, one per trigger

### TC-SAVE-001 — Source panel header "Save…": saves the whole document, default filename
Priority: P1
Steps: (a) load via file (the source field takes a path), click Source's `Save…`, read the dialog's
suggested name; (b) via paste; (c) via URL. Accept as suggested.
Expected default names: (a) the file's own name (`people.json`); (b) `data.json`; (c) the URL's
last path segment (`valid.json`). The file written is the whole document, pretty-printed, and the
dialog offers one file type, `JSON` (`*.json`). **Passing** as TC-SAVE-001a/b/c.

### TC-SAVE-002 — Source panel header "Save…" is always available once a document is loaded
Priority: P3
Steps: with a document loaded and no query ever run, click Source's `Save…`.
Expected: the dialog opens (this button is not gated on query state). Passing: the colour of the
label (saving.robot's TC-SAVE-002) and the dialog opening (TC-SAVE-002a).

### TC-SAVE-003 — Source tree row context menu "Save…": saves just that node, default filename by kind
Priority: P1
Steps: right-click (a) a row with a key, (b) an element of the root array, (c) the root row →
`Save…`.
Expected default names: (a) `{key}.json` (`members.json` for team.json), (b) `item_{index}.json`,
(c) `data.json`. The file is just that node's value. **Passing** as TC-SAVE-003a/b/c.

### TC-SAVE-004 — Results tree row context menu "Save…": the same scheme, `results.json` fallback
Priority: P2
Steps: the three sub-cases on Results rows (a: a result, b: the root, c: a key inside a result,
opened first with its arrow).
Expected: `item_{index}.json` (a), `results.json` (b — not `data.json`: the one difference from
TC-SAVE-003), `{key}.json` (c). **Passing** as TC-SAVE-004a/b/c.

### TC-SAVE-005 — Results panel header "Save…": disabled when results are empty, saves the results otherwise
Priority: P1
Expected: (a) `results.json` and the results array, pretty-printed; (b) with no results the button
is disabled and no dialog opens (the colour of the label is in saving.robot's TC-SAVE-005).
**Passing** as TC-SAVE-005a/b.

### TC-SAVE-006 — A result larger than the live preview is saved whole
Priority: P2
Steps: run `range(60000)`: the Results pane keeps the first 50,000, and the status bar says so
("live preview capped at 50000"). Save….
Expected: the file holds **all 60,000** numbers. (The first version of this document said a save
only held the capped preview; the app has fetched everything again before saving for as long as
this test has existed: `save_results` runs the query without the cap and defers the write until it
finishes — `expand_results`, `pending_save_results`.) **Passing** (TC-SAVE-006 for JSON,
TC-FMT-058 for CSV rows).

### TC-SAVE-007 — Save destination unwritable surfaces a save error
Priority: P2
Expected: the status bar shows red `Save error: …` and the results are still on screen. **Passing**:
(a) a folder that does not exist, (b) a read-only folder (skipped when the tests run as root, who can
write anywhere).

### TC-SAVE-008 — Saving a row whose value no longer exists (race) reports the specific error
Priority: P3
A genuine race (a row resolved from a stale path after the document changed); needs timing control
the harness does not have. **Not implemented.** The text is `Save error: that value is no longer part
of the document`.

### TC-SAVE-009 — A successful save updates the status bar; a later load clears it
Priority: P3
Steps: save (`Saved to {path}` appears), then load something (here a failing load).
Expected: the confirmation is gone. The text is dim, which OCR reads only from a crop one line high
with the single-line page mode (`@{STATUS_LINE}`, `psm=7`). **Passing.**

### TC-SAVE-010 — The save file type follows the format
Priority: P2
Expected: for JSON — the Source header and rows, the Results header and rows — one file type, `JSON`
with `*.json`. (Before the CSV/TSV output it was *always* that; for a query ending in `@csv` or `@tsv`
the Results saves offer `CSV`/`TSV` and `*.csv`/`*.tsv`, TC-FMT-050/051; the Source's stays JSON,
TC-FMT-063.) **Passing** as TC-SAVE-010a.

### TC-SAVE-011 — Save… while the query is still running
Priority: P2
Steps: run a query that gives its results slowly and press the Results header's `Save…` once the
first has arrived, while the status bar still says `Query running…`.
Expected: **undecided — a finding, no case yet.** The app writes a file with only the results
that had arrived when the button was pressed, after the query has finished, and says `Saved to …`
(see Findings). **Not implemented**: a case would pin one behaviour (the button dimmed while the
query runs, or the full results saved when it ends) that is the app owner's to choose.

## Related

| ID | Title | Priority | Status |
|---|---|---|---|
| TC-KEY-003a/b/c | Ctrl+S saves the focused pane: Source (`data.json`), Results (`results.json`), nothing for empty results | P2 | **Passing** |
| TC-TOOL-006 | A save error replaces the save confirmation, never both | P2 | **Passing** |

## The cases (`suites/saving/saving_dialogs.robot`)

The generated list is in [99_traceability_matrix.md](99_traceability_matrix.md).

## Mutation checks

One thing broken at a time in a build of the app, each killed by the cases that should see it:

| Mutant | What is broken | Killed by |
|---|---|---|
| M13 | a pasted document's Save suggests `document.json` instead of `data.json` | TC-SAVE-001b, TC-KEY-003a |
| M14 | a save past the live preview writes only the preview | TC-SAVE-006 (and TC-FMT-058) |
| M3, M4 | the Results Save writes JSON / always suggests `results.json` for rows | see [18_output_formats.md](18_output_formats.md) |

A first run of three of these under heavy load failed with `Disk quota exceeded` (`/tmp` full) and
not at an assertion; those failures are not counted, see "Troubleshooting" in `README.md`.
## Findings

- **The dialog hangs the app when its answer comes too fast.** `rfd` 0.17 sends the portal call, reads
  the reply, and only then waits for the `Response` signal; a signal that libdbus has already read
  together with the reply is in a queue nobody looks at, and the UI thread waits for ever. A real
  portal answers after the person has chosen, seconds later, so it does not happen on a desktop; the
  first stand-in answered at once and froze about one dialog in ten under load (the window stuck
  on the frame of the click). The stand-in now waits 0.4 s, as a person would
  (`FakePortal.ANSWER_DELAY`). Not an app defect.
- **Save… pressed while the query is still running writes a partial file, late.** Found with a
  throwaway experiment, not a case: `range(6000000) | select(. % 500000 == 0)` gives 12 results, one
  every half-million steps, over about 30 s in a debug build; Save… was pressed 2 s in. The header
  button is enabled as soon as the first result is on screen and the dialog opens as usual, but the
  save is a command to the one worker thread, which is busy with the query, so it runs when the
  query ends (29 s later) and writes the results *as they were when the button was pressed*: `[0]`,
  one of twelve. The status bar then says `Query ran in 31.4s — 12 result(s)` and `Saved to …`;
  nothing says that the file is partial. (Run for the header button only. From the code, the root
  row's Save… takes the same snapshot and uses the same worker, and so does Copy to Clipboard.)
  `Expand All` is dimmed while a query runs; Save… is not. Not
  changed here: dimming it too, or saving the full results when the query ends, is a choice for the
  app's owner (TC-SAVE-011).
- A dialog answered with a cancel, or not answered with a file, leaves everything as it was
  (TC-FMT-053, TC-OPEN-022).
