# Performance tests: the plan

What this is: a plan for measuring what the memory-mapped, indexed documents of jsonquery gui did to
the speed and the memory of everything that works on a document, and the tests that carry it out.
[README.md](README.md) says how to run them and how to read the results; this says what is measured
and why. [FINDINGS.md](FINDINGS.md) says what came of the first run.

## 1. The question

Until the change, the app read every JSON file into a tree (`serde_json::Value`) whatever its size.
A parsed document takes twelve to seventeen times its file (1.7 GB of memory for 100 MB of records), so
a file of a gigabyte wanted more memory than a machine has. The change keeps a file of 256 MiB or more
where it is: it is memory-mapped, checked once by a scan, and indexed (where the children of its big
lists are, a few bytes per thousand); everything that looks at the document afterwards asks the file.
A file below 256 MiB is still parsed, but is read and parsed instead of being mapped and parsed, and
the mapping is not kept.

So three things can have happened to each function that touches a document:

1. **It is a different function for a big file** (open, rows of the tree, queries, search, save, copy,
   format, suggestions). It was a walk of a tree in memory; it is now a walk of the file. Its time and
   its memory have to be measured on a big file, on the old build and on the new one.
2. **It is the same function with new things under it** (the parsed path: `Document` is now an `enum`,
   the tree walks go through `Root` and `ValueView`, the loader reads where it mapped, JMESPath is built
   with `Arc`, jq's `run_query` was split into `Program`). These must not have got slower or heavier,
   and the only way to know is to measure them on files that are still parsed.
3. **It does not care** (the algorithms of the Tools window, a query's text, highlighting). These are
   controls: if one of them changes, the measurement is not to be trusted.

And a fourth, which is not a comparison: some things now work that could not (a gigabyte file opens;
Format streams a document it could not hold), and some are now refused on purpose (a query that needs
a whole list in memory, a copy of more than 64 MiB). Those are listed, not timed against anything.

## 2. The revisions

| | Revision | What it is |
|---|---|---|
| **before** | `65ae0d3` | the parent of the mapping commit: every file is parsed, the mapping of a file is kept while it is open |
| **after** | `950c9ab` | the mapping commit: a file of 256 MiB or more is kept on disk and indexed |
| current | the head at the time (`56aa08a` for the first run) | the mapping commit and what came after it (the Settings window, which makes the 256 MiB a setting: `load_with`) |

Runs can be made at any commit, tag or branch of the app, or at the working tree as it is (`WORKTREE`),
so the same plan serves for every later change: the runs of this one are kept in [runs/](runs/) as the
baseline to compare them with.

## 3. The functions that may be affected

What a person does, the library function that does it (the app's worker thread and tree widget are thin:
they call these), how the change touched it, and the scenarios that measure it. Scenario ids are written
in backticks; `perf.py check-plan` fails if one of them is not in the harness, or the harness has one
that is not here.

**A** = a different function for a big file; **B** = the same function with new things under it
(parsed documents must not suffer); **C** = control, which should not change; **N** = new, nothing to
compare with.

### 3.1 Opening a document

| Function | Before | After | Class | Scenarios |
|---|---|---|---|---|
| `load(path)`: a file of 256 MiB or more | mapped whole, parsed into a tree, mapping kept | mapped, scanned once, indexed, never parsed; no tree | A | `load.open`, `load.open_cold` |
| `load(path)`: a file below 256 MiB | mapped, parsed, mapping kept while open | read into a buffer, parsed, buffer dropped | B | `load.open`, `load.open_cold`, `load.open_tiny` |
| `load_text(text)`: pasted JSON | parsed | the same | C | `load.open_text` |
| a document that is let go (another file is opened) | a tree freed, node by node | a mapping dropped | A | `load.release` |
| a file of several top-level values (NDJSON) | wrapped in an array while parsing | the same, or counted by the scan | A/B | the `nd-*` datasets, in all of the above |

Not measured here: `load_bytes` and `load_open_file` (a download, which is parsed in memory below 256 MiB
and written to a nameless temporary file above it: it needs a network and lives in the app's worker, not
in the library; the parse it ends in is `load.open_text` and `load.open`), reading from a pipe (it used to
load as an empty array, so there is nothing to compare), and the SIGBUS guard (its price is in
`load.open`).

### 3.2 The rows of the tree

| Function | Before | After | Class | Scenarios |
|---|---|---|---|---|
| `flatten_visible`: the rows of a parsed document | a row for every child of an open container | the same walk, through `push_children` and `iter_children_from` | B | `rows.initial`, `rows.reveal_middle`, `rows.deep_expand` |
| `flatten_grouped`, `group_size`, `groups_containing`: rows of a document kept on disk | (none) | children in runs of 1,000; only open runs are looked at | A | the same three |
| `resolve`, `child_at`, `child_by_key`, `scalar_preview` | on `&Value`: an index or a hash lookup | through `Root`: the same, or the index of the file and then the file | A/B | `tree.resolve_random`, `tree.resolve_by_key` |
| `iter_children`: every child in turn (search, rows, locate stand on it) | a slice or map iterator, boxed | the same, wrapped in `Root` | B | `tree.iterate_children` |

### 3.3 Search and Find in Source

| Function | Before | After | Class | Scenarios |
|---|---|---|---|---|
| `search`: a text or a regular expression through all keys and values | a walk of the tree; every string lower-cased to be compared | parsed: the same walk; kept on disk: `memchr` on the bytes of a key or a string where they are in the file | A/B | `search.key_common`, `search.value_once`, `search.key_once`, `search.value_absent`, `search.regex_once`, `search.regex_absent` |
| `locate`: where a result came from | a walk comparing every node to the result | the same, through `Root` | A/B | `search.locate_equal` |

### 3.4 Queries

A query on a parsed document first turns the whole document into jq's own values (`to_val`), which takes
time in proportion to the document whatever the query is. A query on a document kept on disk is planned:
the stages that only look for something are walked in the file, the elements of a long list are shared
out to threads, and what is left is run by jq on one piece of the file at a time.

| Function | Before | After | Class | Scenarios |
|---|---|---|---|---|
| jq: a place in a list, a length, a slice | convert all, run | walked in the file | A | `query.jq.index_mid`, `query.jq.index_last`, `query.jq.length`, `query.jq.slice_head`, `query.jq.first_keys`, `query.jq.tree_path`, `query.jq.num_index_mid`, `query.jq.num_length`, `query.jq.str_length_one`, `query.jq.str_slice`, `query.jq.obj_key_mid` |
| jq: `first(...)`, `limit(...)` (they stop early) | convert all, run | walked until enough | A | `query.jq.first_early`, `query.jq.first_mid`, `query.jq.limit_active` |
| jq: a filter, a map, a sum, a count over the whole list | convert all, run | elements shared out to threads | A | `query.jq.select_one`, `query.jq.select_count`, `query.jq.map_len`, `query.jq.sum`, `query.jq.regex_count`, `query.jq.stream_names`, `query.jq.object_compose`, `query.jq.num_add`, `query.jq.num_max`, `query.jq.num_map_add`, `query.jq.str_lengths_sum`, `query.jq.str_select_needle`, `query.jq.obj_keys_len`, `query.jq.obj_values_count`, `query.jq.tree_prices_over` |
| jq: `sort_by`, `group_by`, `unique`, `min_by` | convert all, run | the key of each element and its place in the file are made, by threads | A | `query.jq.sort_by_head`, `query.jq.group_by_count`, `query.jq.unique_count`, `query.jq.min_by` |
| jq: `..`, recursive descent | convert all, run | walked | A | `query.jq.recursive_find`, `query.jq.tree_all_skus` |
| JSON Pointer | `Value::pointer` | walked to the place | A | `query.pointer.record`, `query.pointer.member`, `query.pointer.deep` |
| JSONPath | jsonpath-rust on the value | its parsed model is walked; what is small goes to the engine | A | `query.jsonpath.index_field`, `query.jsonpath.filter`, `query.jsonpath.wildcard`, `query.jsonpath.descendants`, `query.jsonpath.deep` |
| JMESPath | the value turned into `Rc` variables | built with `Arc` (`sync`); on a big file its AST is walked | A/B | `query.jmespath.index_field`, `query.jmespath.length`, `query.jmespath.filter_count`, `query.jmespath.project`, `query.jmespath.max_by`, `query.jmespath.deep` |
| `Program` (jq compile and run, split out of `run_query_with_vars`) | one function | compile once, run many | B | every `query.jq.*` below 256 MiB |
| Cancel, for a query that is taking long | the document is first turned into jq's values, which cannot be stopped half way: Cancel is seen when that is done | looked for between pieces of the file, and between elements | A | `query.cancel_latency` |

`query.jmespath.max_by` needs the whole list at once, which a big file cannot give: on a document kept on
disk it is expected to be refused, with a message that says so. It is in the plan to find that out and say so.

### 3.5 Text view, Copy and Save

| Function | Before | After | Class | Scenarios |
|---|---|---|---|---|
| the Text view: the first 20,000 nodes as text | `pretty_print_bounded` | the same; for a file kept on disk, cut by nodes, by 4 MiB and by 4 KiB of a string | A/B | `text.render_source` |
| "Copy to Clipboard" of a node or the document | `to_string_pretty` | the same; for a file kept on disk, written from the file, refused above 64 MiB | A/B | `copy.row`, `copy.document` |
| "Save…" of a node or the document | `to_writer_pretty` | the same; for a file kept on disk, written from the file a piece at a time | A/B | `save.row`, `save.document` |
| "Save…" of query results (at most 50,000 are kept) | `to_writer_pretty` | the same | C | `save.results` |

### 3.6 Autocomplete

| Function | Before | After | Class | Scenarios |
|---|---|---|---|---|
| `suggest`: the names and indexes the query box offers | looks into the document's value | a parsed document: the same; a file kept on disk: a small sample of itself | A/B | `suggest.field_of_element`, `suggest.field_of_all`, `suggest.object_keys`, `suggest.nested_path` |

### 3.7 The Tools window

| Function | Before | After | Class | Scenarios |
|---|---|---|---|---|
| Format: lay a parsed document out | `reformat::render` | the same | C | `tools.format_parsed`, `tools.format_sorted` |
| Format of a document kept on disk | (refused above 128 MB) | laid out from the file and written a piece at a time | N | `tools.format_stream` |
| Diff, Patch, Validate, Merge | work on whole values | the same | C | `tools.diff`, `tools.patch`, `tools.validate`, `tools.merge` |

### 3.8 Together

| What | Before | After | Class | Scenarios |
|---|---|---|---|---|
| Open a file, the first rows of its tree and two first queries (what a person waits for) | parse, a row for every child, convert the document twice | scan, three rows, two walks | A | `workflow.open_browse_query` |

### 3.9 What is not measured

| What | Why | Where it is looked at |
|---|---|---|
| a download (`worker::download`) | needs a network; it lives in the app's worker thread, not in the libraries | the Robot suite, `suites/opening_sources/` |
| the Tools window's job runner and operand pickers | in the app's binary, not reachable by a library harness; the algorithms are measured | `suites/tools/` |
| the time of a frame with a big document open, window start and end | needs a display; the tree's data layer, which is what changed, is measured | `suites/tree_view/`, `suites/opening_sources/heavy_files.robot` |
| Windows and macOS | the harness reads `/proc` and uses cgroups | the app's CI |
| the Settings window and `settings.json` | nothing on a hot path | `suites/settings/` |

## 4. The datasets

Made by `perf.py data`, the same bytes every time (each file has a SHA-256 that goes into every result),
kept out of the repository. Each has a sidecar that says what is in it, so that a scenario can ask for
what is there and for what is not.

| Shape | What it is | Sizes | What it is for |
|---|---|---|---|
| `records` | one list of records of about 135 bytes (`id`, `name`, `k`, `score`, `qty`, `active`, `tags`, `geo`: a list and an object in each) | 1 to 16 MiB (and 2, 4, 8), 100 MiB, **300 MiB**, **1 GiB** | the usual big file |
| `ndjson` | the same records, one to a line | 1, 16, **300** MiB | a file that is not one value |
| `wide` | one object of millions of members | 1, 16, **300** MiB | a key is found by a walk where the file is kept on disk |
| `strings` | a list of strings of 190,000 characters, a tenth of them with escapes | 2 MiB, **300 MiB** | few, big values; what a row may show of one |
| `numbers` | a list of integers and floats | 1, **300** MiB | millions of tiny values |
| `nested` | a catalog: categories, products, variants (seven levels) | 1, 16, 100 MiB, **300 MiB** | paths, descent, filters, branches opened a few clicks deep |
| `tiny` | 68 bytes | | what opening costs besides the bytes |

Sizes in bold are of 256 MiB or more: the new build keeps those on disk. The 100 MiB files are the
largest that both builds parse. The profiles (`perf.py plan`) are `smoke` (everything, small: does it
work), `quick` (up to 16 MiB), `standard` (up to 300 MiB: the comparison), `full` (adds a gigabyte) and
two that compare the two ways of keeping the *same* file on the new build, once forced to be parsed and once
forced to be kept on disk: `threshold` (1, 16 and 100 MiB) and `crossover` (1 to 16 MiB in steps): where is the
right size to switch? (A gigabyte of these records takes some 22 GiB parsed, which is more than the machine of the
first run could be asked for: the old build is run at that size under a ceiling and is expected to be killed
by it; the jq queries that would convert the whole document are not tried.)

## 5. What is measured

Per scenario and dataset:

- **Time**: the wall time of the one thing the scenario measures (not of its set-up, which is the
  document being opened). The first run is kept apart (it is what a person gets the first time they ask);
  the runs after it are the steady state, of which the median, the minimum, the 90th percentile and the
  spread (median absolute deviation over the median) are kept, with every sample. A scenario that is
  too slow to be repeated has its first run only. CPU time of the whole process is kept too: the new
  build uses threads, so a faster wall time is not a cheaper one.
- **Memory**, from `/proc/self/status`: the highest *heap* (anonymous resident memory, sampled every 4 ms)
  and the highest resident set (exact, `VmHWM`) during the first run; the heap and the *mapped file*
  pages resident right after the first run, with the document open. The heap is the number that
  matters: it is what has to fit in RAM and swap. A mapped file's pages are the page cache's, and are given
  back when memory is wanted.
- **Answers**: a fingerprint of what the scenario made (how many results, and a hash of what they are),
  so that a comparison can say whether two revisions gave the same answers. A scenario whose answer is
  different by design (rows of a document kept on disk are runs, not nodes) says which kind of answer it is,
  and only the same kinds are compared. [expected_differences.json](expected_differences.json) lists the
  differences that are known and why; any other is reported as a problem. A query that makes nothing but an error
  (the app shows it where an answer would be: a file kept on disk refuses what needs a whole list in memory) is
  *refused*, which the comparison counts as having stopped working, with the message.

## 6. The method

- **One process for one scenario on one dataset**, so that what one does to memory or the allocator is not
  in the next one's figures, and one that runs out of memory ends only itself. Each runs in its own cgroup
  with a ceiling on memory (`systemd-run --user --scope`, the lower of what the machine has free minus 2 GiB
  and `--memory-cap`) and is the first for the kernel to end if the machine runs short. A process the ceiling
  ends is a result too (`killed`).
- **The harness is built inside the revision under test**, as a member of its workspace, in its release
  profile (LTO, one codegen unit), against its own `Cargo.lock`. It calls what the app's worker thread and
  tree widget call, with the same arguments (`bench/src/api_before.rs` and `api_after.rs` are those few lines for
  each of the two shapes of the API). What it cannot reach is in section 3.9.
- **Warm page cache**: the datasets have just been written or read, and are in memory. `load.open_cold`
  empties the page cache for the file first (`posix_fadvise`), which is the only scenario that reads the disk.
- **Builds take turns**: the same scenario on each build in a row, the order swapped every time, so that
  whatever else the machine is doing hits them alike. Files up to 16 MiB are run in three passes; bigger ones
  once, because their scenarios take seconds, differ by factors, and would take hours.
- **Noise**: a difference is a change only if it is more than the tolerance (10%) and more than three times
  how much the runs of the scenario differ among themselves, and more than a few microseconds. Memory has a
  floor of 4 MiB. These are options of `perf.py compare`.
- **The machine is described in every result** (CPU, cores, RAM, swap, kernel, file system, governor, load and
  free memory when the run started), and a comparison across machines says so. The machine this was
  developed on is shared with other work and runs with its swap full; the load average at the start of each
  process is kept so that an odd figure can be explained.

## 7. What was expected

Written from the code and the commit message, after a smoke run on 1 MiB files and 16 MiB files and a first
look at some jq queries on 300 MiB, and before the full run. [FINDINGS.md](FINDINGS.md) says which held.

| # | Expectation |
|---|---|
| E1 | Opening a file of 256 MiB or more is several times faster, and takes a thousandth of the heap (a few tens of MiB for an index, against gigabytes of tree). |
| E2 | Opening a file below 256 MiB takes as long as it did (±10%): it is the same parser. The heap at its highest is higher by about the size of the file (it is read into a buffer first), and the memory that stays is lower by about the size of the file (the mapping is not kept). |
| E3 | Letting go of a big document is instant (a mapping dropped, not millions of allocations freed); below 256 MiB it is as it was. |
| E4 | The first rows of a 300 MiB list take milliseconds (three rows, in runs), where they took seconds and gigabytes (a row for every child). Below 256 MiB they are as they were. |
| E5 | Finding a node by its place or its key is slower per lookup in a document kept on disk (microseconds for an index and a walk, where a tree answers in nanoseconds), and a member of a huge object found by its key is much slower (a walk, where the tree has a hash). Neither matters to a person; both are measured. |
| E6 | Walking every child of a parsed list is a little slower (the `Root` wrapper adds a step to each child), by a small factor and never by enough to be seen in a search. |
| E7 | Search of a document kept on disk is faster (the commit says 4.0 s to 1.6 s on 300 MB for a text that is not there); below 256 MiB it is as it was. |
| E8 | A jq query that looks for a place, or stops early (`.[n]`, `first`, `limit`, a slice, a length) answers in milliseconds on a big file where it took seconds (the whole document no longer has to be converted for each query). Queries that read the whole list are several times faster (threads), and sorts and groups are about as fast or faster. Below 256 MiB all are as they were. |
| E9 | A few queries are not faster, or are slower, on a big file: ones that need a whole list in memory, or a regular expression over every record. This is to be found, not hidden. |
| E10 | JMESPath and JSONPath behave like jq: place and filter queries are much faster on a big file; JMESPath on a parsed document is a few percent slower (`Arc` for `Rc`). `max_by` over a whole big list is refused. |
| E11 | Save of a big document streams it from the file: faster, and the heap does not grow. Copy of more than 64 MiB is refused. Below 256 MiB both are as they were. |
| E12 | Autocomplete on a huge object is much faster on a big file (a sample instead of all the keys). |
| E13 | The algorithms of the Tools window are as they were (controls). Format of a document kept on disk works, and is limited by the disk. |
| E14 | A cold open of a big file is limited by the disk in both builds: the new one has to read all of it once to check it. |
| E15 | Cancelling a query that reads the whole list stops it within milliseconds on a file kept on disk; on a parsed document it stops only when the document has been converted, which takes as long as a query takes (hundreds of milliseconds at 16 to 100 MiB, seconds at 300 MiB). |
| E16 | Together: from choosing a 300 MiB file to having its rows and the answers to two first queries takes a few seconds before (a parse, a conversion for each query) and well under one second after. |

## 8. Where the results are, and how to compare with them

Every run is one JSON file in [runs/](runs/), named `<date>_<label>_<commit>.json`, with the machine, the
revision (full commit, subject, whether the tree was modified), the harness's version and API, the method,
the datasets (size, SHA-256) and every result with its samples. `perf.py compare A B` reads two and writes a
Markdown report (and JSON) into [reports/](reports/); with `--fail-on slower,heavier,failing,differs` it exits 1
if there is any, which is how a later change is checked against the baseline. [README.md](README.md) has the
format, the commands and what makes two runs comparable.

## 9. What is left

- Timing in the real window (a frame with a big document open, the time to the first row): it needs the
  Robot suite's display and OCR, and says little about the data layer, which is what changed. The Robot suite
  checks that big documents open and work, with timeouts.
- The download path, with a local HTTP server.
- Windows and macOS: `/proc`, cgroups and `posix_fadvise` are Linux.
- The harness could be run by CI on a dedicated machine; a shared runner is too noisy for 10%.
