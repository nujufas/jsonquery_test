# The jq functions the app adds — test requirements

Source: `crates/query/src/jq_ext.rs` and `jq_ext/{prelude.jq,tabular.rs,tostream.rs}` in
[jsonquery_gui](https://github.com/nujufas/jsonquery_gui); `run_query_with_vars` in
`crates/query/src/lib.rs` is the one place a jq program is compiled, and chains the
definitions in.

The jq engine of the app is [jaq](https://github.com/01mf02/jaq), which lacks `IN`, `INDEX`,
`JOIN`, `tostream`, `fromstream`, `truncate_stream`, `@csv` and `@tsv`. The app defines them
itself: the first six in jq (`prelude.jq`) or natively (`tostream`, for speed: 3.6 million
events in under a second where the definition in jq takes 15), `@csv` and `@tsv` natively. They
are meant to behave as in jq 1.8.1, and the Rust crate tests them against 123 cases ported from
jq's own test suite. These cases check the same thing from the other end: through the real
window, with the query pasted in and run, and every result read back exactly.

## How a case checks

1. `Load Fixture` pastes a document (`people.json`, `shop.json`, `nested.json`).
2. `Run Query By Paste` puts the query in the box and runs it with Ctrl+Enter. The engine is
   left on auto-detect, as a person leaves it: these queries start with a dot, a bracket or a
   function name, none of which is another engine's marker.
3. `Results Should Be Json` presses **Copy to Clipboard** on the Results root, which copies
   every result as one pretty-printed JSON array, and compares it, as JSON, with the expected
   array. Nothing is read by OCR.

The expected values are what **jq 1.8.1** prints for `jq -c '[ QUERY ]'` over the same
document, written into the cases so that the suite does not need jq.

One thing that is *not* JSON: a query whose last step is `@csv` or `@tsv` makes **rows of
text**, and Copy to Clipboard then gives the rows, not JSON (see
[18_output_formats.md](18_output_formats.md)). The cases for those two (TC-JQX-060 to 066) compare
the rows as text. The error cases wrap the call in `try … catch .`, which ends the query in
`catch .` and so gives JSON again.

## Cases (`suites/jq_functions/`)

| ID | Title | Priority |
|---|---|---|
| TC-JQX-001 | `IN` keeps the members whose value is one of several (`select(.role \| IN("engineer", "intern"))`) | P1 |
| TC-JQX-002 | `IN` gives a boolean for each input | P1 |
| TC-JQX-003 | `IN(source; set)` asks whether any output is in the set | P1 |
| TC-JQX-004 | `IN(source; set)` is false when nothing matches | P2 |
| TC-JQX-005 | `not IN` keeps what is not in the list | P1 |
| TC-JQX-006 | `IN` compares whole values (an equal object) | P2 |
| TC-JQX-007 | `IN` over an empty source is false | P3 |
| TC-JQX-008 | `IN` over a generated source | P3 |
| TC-JQX-009 | `IN` does not equate a number and a string | P2 |
| TC-JQX-010 | `IN` finds `null` | P3 |
| TC-JQX-020 | `INDEX(.name)` keys an array by a field | P1 |
| TC-JQX-021 | `INDEX(stream; f)` makes a lookup table | P1 |
| TC-JQX-022 | `INDEX` turns numeric keys into strings | P1 |
| TC-JQX-023 | `INDEX` keeps the last of several elements with one key | P1 |
| TC-JQX-024 | `INDEX` of an empty array is an empty object | P2 |
| TC-JQX-025 | `INDEX` files a missing key under `"null"` | P3 |
| TC-JQX-026 | `INDEX` then `map_values` projects the table | P2 |
| TC-JQX-027 | `INDEX` of the customers by code (the tutorial's first example) | P1 |
| TC-JQX-030 | `JOIN` pairs each order with its customer (four arguments) | P1 |
| TC-JQX-031 | `JOIN` without a join expression gives the pairs | P2 |
| TC-JQX-032 | `JOIN` over an array makes an array of pairs | P2 |
| TC-JQX-033 | `JOIN` pairs an unmatched element with `null` | P3 |
| TC-JQX-040 | `tostream` gives a path and a leaf for each scalar, and a closing event | P1 |
| TC-JQX-041 | `tostream` of the whole document has seven events | P2 |
| TC-JQX-042 | `tostream` of a scalar is one event with an empty path | P2 |
| TC-JQX-043 | `tostream` of empty containers is their own leaf | P2 |
| TC-JQX-044 | The events make a listing of every leaf (`path = value`) | P1 |
| TC-JQX-045 | The last event closes the top level | P3 |
| TC-JQX-046 | `fromstream(tostream)` rebuilds the document | P1 |
| TC-JQX-047 | `fromstream` builds a value from hand-written events | P1 |
| TC-JQX-048 | `fromstream` of a truncated stream makes the inner values | P2 |
| TC-JQX-049 | `truncate_stream` drops the first path level (the example of jq's manual) | P1 |
| TC-JQX-050 | `fromstream` over a filtered stream drops a field from every record | P1 |
| TC-JQX-051 | `fromstream(1 \| truncate_stream(...))` gives one result per element | P1 |
| TC-JQX-052 | `fromstream` makes one value per complete top-level value | P2 |
| TC-JQX-053 | `tostream` of 100,000 numbers (100,001 events) is fast enough to use | P2 |
| TC-JQX-060 | `@csv` writes numbers bare, strings quoted, `null` empty | P1 |
| TC-JQX-061 | `@csv` doubles a quote inside a string | P1 |
| TC-JQX-062 | `@csv` leaves a comma or a line break inside the quotes | P1 |
| TC-JQX-063 | `@tsv` escapes tab, backslash, line break and carriage return | P1 |
| TC-JQX-064 | `@tsv` writes `null` as nothing and booleans as words | P2 |
| TC-JQX-065 | `@csv` and `@tsv` of an empty array are empty strings | P2 |
| TC-JQX-066 | `@csv` quotes a lone string | P3 |
| TC-JQX-067 | `@csv` of an object is an error that names the value | P1 |
| TC-JQX-068 | `@csv` of a nested array is an error | P2 |
| TC-JQX-069 | `@tsv` of a string is an error | P2 |
| TC-JQX-080 | An error raised in the query shows its text plainly (`boom`, not `"boom"`) | P2 |
| TC-JQX-081 | `try … catch` hands over the error text | P2 |
| TC-JQX-082 | An unknown variable (`$ENV`) is a query error | P2 |

## Related

The autocomplete popup offers these functions and the `@` format names (suite file
`suites/autocomplete/autocomplete.robot`, no document of its own):

| ID | Title | Priority |
|---|---|---|
| TC-AC-070 | The stream functions are offered (`tostream`, `fromstream`, `truncate_stream`) | P2 |
| TC-AC-071 | `INDEX` and `JOIN` are offered in capitals | P2 |
| TC-AC-072 | After an `@` jq offers its format names, `@csv` and `@tsv` among them | P1 |
| TC-AC-073 | Accepting a format name makes a query that writes rows | P1 |
| TC-AC-074 | JSONPath has no format names after an `@` | P2 |
| TC-AC-075 | An `@` inside a string offers nothing | P3 |

## Mutation checks

One thing broken at a time in a build of the app; each mutant fails the cases that should see it.

| Mutant | What is broken | Killed by |
|---|---|---|
| M6 | `@csv` does not double a quote inside a string | TC-JQX-061 |
| M7 | `IN` asks the opposite question (`!=` for `==`) | TC-JQX-001, 002, 005, 009, 010 |
| M8 | `tostream` leaves out its closing events | TC-JQX-040, 041, 045, 046, 050, 051, 052, 053 |
| M9 | `INDEX` keeps the first of several elements with one key | TC-JQX-023 (and nothing else: no other example repeats a key) |
| M17 | after an `@`, no `@tsv` is offered | TC-AC-072 |

## Findings

- **The wording of an error differs between jq versions**, so the cases for the wrong-input
  errors (TC-JQX-067, 069) check that the message contains `cannot be csv-formatted`, and not the
  words after it: jq 1.7 ends "only an array can be", jq 1.8.1 "only array", and the app has the
  older text. The nested-array message, which is the same in both, is compared whole
  (TC-JQX-068).
- **A query that ends in `@csv` is not JSON.** The first version of TC-JQX-060 to 066 compared
  Copy to Clipboard with a JSON array of strings and failed in six places: the app, as designed
  since the CSV change, copies the rows. The cases were wrong, not the app.
- `$ENV` and `input` are still unknown to the engine (TC-JQX-082): the tutorial's page "jq here vs
  jq 1.7" lists them.
