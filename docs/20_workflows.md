# Workflows — test requirements

The other suites check one feature at a time. These cases are whole journeys, from where a person
starts to what they came for, crossing the features: a file chosen in the dialog, a lesson of
the tutorial or a pasted document → a query with the jq functions the app adds
([17_jq_functions.md](17_jq_functions.md)) → rows or JSON ([18_output_formats.md](18_output_formats.md))
→ a file on disk or text on the clipboard. They were written to find what falls between the areas,
and they are how a release can be told to work "end to end".

Every step is real: the file dialog is answered by the stand-in portal
(`resources/fake_portal.py`, see [writing_tests.md](writing_tests.md)), the app writes the file, and
the test reads it. What the person would see is read as in the other suites: exact text through the
clipboard and the files, OCR for words, pixels for the CSV/TSV note.

## Cases (`suites/workflows/`)

| ID | Title | Priority |
|---|---|---|
| TC-WF-001 | From A File To A CSV File | P1 |
| TC-WF-002 | From A Line-Delimited File To CSV | P2 |
| TC-WF-003 | From A Lesson To Your Own Query And A File | P1 |
| TC-WF-004 | Joining Two Tables And Saving The Result As JSON | P1 |
| TC-WF-005 | Taking A Document Apart And Putting It Back | P2 |
| TC-WF-006 | The Format Follows The Query Through A Change Of Engine | P2 |
| TC-WF-007 | A Large Document Becomes A Large CSV File | P2 |
| TC-WF-008 | Saved JSON Can Be Opened Again | P1 |
| TC-WF-009 | Every Window Open And A Save Still Works | P2 |
| TC-WF-010 | Rows Copied As CSV Are Not A JSON Document | P3 |

## Notes

- TC-WF-007 runs a 25,000-element array through the HTTP fixture server and writes 25,000 rows. It
  waits for the file by *progress* (`Wait Until File Has Lines`), not for a fixed time: in an early run
  with nine lanes and a build going on at once the file grew by only about 600 lines a second and a
  20 s budget ran out at 11,629 lines (run alone, the whole case takes 11 s; the same wait is used by
  TC-FMT-058 and, as `Wait Until File Holds Json`, by TC-SAVE-006).
- TC-WF-009 opens the Tools window, the tutorial and About beside the main window before saving:
  the file dialog is asked from the main window while three other windows are open.
- TC-WF-010 is a negative case on purpose: rows copied as CSV are text for a spreadsheet, not JSON,
  and pasting them back into the app is a load error. If the app one day reads CSV, this is the case
  to change.
