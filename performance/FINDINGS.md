# Findings: the app before and after files of 256 MiB or more were memory-mapped

Measured on 2026-10-07 with the plan in [PLAN.md](PLAN.md). **Before** is `65ae0d3`, where every file is parsed into a
tree. **After** is `950c9ab`, the commit that keeps a file of 256 MiB or more on disk, memory-mapped and indexed. The two
builds took turns, scenario by scenario, on one machine: an Intel Core i9-10850K (10 cores, 20 threads), 60 GiB of RAM (about
22 GiB of it free, the rest in use by other work, with the swap full), a Samsung 980 PRO NVMe disk, Ubuntu 26.04, kernel 7.0,
Rust 1.99, release builds with LTO.

The data is in [runs/](runs/): `2026-10-07_before-mmap_65ae0d3.json` and `2026-10-07_after-mmap_950c9ab.json` (every sample, the
machine, the SHA-256 of every file). The full comparison, 578 scenario × dataset pairs, is
[reports/before-after-mmap.md](reports/before-after-mmap.md) ([as JSON](reports/before-after-mmap.json)). The same files kept
parsed and kept on disk, on the head at the time (`56aa08a`, where that is a setting), are in
[runs/2026-10-07_current_56aa08a.json](runs/2026-10-07_current_56aa08a.json) and
[reports/threshold-parsed-vs-lazy.md](reports/threshold-parsed-vs-lazy.md).

## In short

- **A file of 256 MiB or more is a different thing to open.** A 300 MiB list of 2.24 million records opens in 0.40 s instead of
  3.76 s and takes 1 MiB of heap instead of 6.3 GiB (a parsed tree took 22 times the file). A gigabyte (7.6 million records) opens in
  1.35 s and takes 2 MiB. The old build, with a ceiling of 14 GiB, was killed opening the same gigabyte: it needs about 21 GiB.
  The index is 0.56 MB for the 300 MiB of records, and the check of the file runs at about 790 MB/s.
- **What a person waits for is 40 times shorter.** Choosing a 300 MiB file, getting the first rows of its tree and the answers to
  two first queries takes 17.9 s before and 0.45 s after. A query that looks for a place or stops early (`.[n]`, `length`,
  `first(...)`, `limit(...)`, a slice, JMESPath `length(@)`) went from 5–7 s to under 2 ms. Queries that read the whole list are 3.5
  to 12 times faster (a filter 8.0 s → 1.1 s, `sort_by` 15.1 s → 1.3 s, `group_by` 12.3 s → 2.2 s, a regular expression over every
  record 14.1 s → 2.1 s) and use 5 MiB to 1 GiB of heap where they used 11 GiB. Cancelling a running query takes 0.14 ms where
  it took 8.2 s: a parsed document is converted for jq whole, which cannot be stopped half way.
- **The price is every operation that works on one node at a time, and the writing out.** Finding a node by its place takes 4.4 µs where it took
  0.15 µs (30 times); walking all the children of the list is 25 times slower (0.27 s for 2.24 million); a member of a huge
  object found by its key takes 250 ms (it was a hash lookup); Find in Source is 2.4 times slower and the Text view 3.5 times (2 ms);
  Save of the whole document is 2.3 times slower (3.0 s against 1.3 s), written from the file a piece at a time in 2 MiB instead of
  6 GiB. Search is about as fast (10–20% faster for the records, 10–90% slower for long strings and the catalog), not faster.
- **A few things are refused on a file kept on disk**, each with a message that says what to do instead: `add` or `map(...) | add` over
  tens of millions of numbers, anything that gathers more than 1 GiB (`[.[]]` over an object of 6.3 million members; `map(select(...))`
  over a gigabyte), JMESPath `max_by` over the whole list, jq `.. | .x? // empty` on a 300 MiB catalog, and Copy to Clipboard of more than 64 MiB.
  Those measured at 300 MiB worked before, with 6 to 11 GiB of memory.
- **A file below 256 MiB is the same to within 10% for almost everything** (345 of 372 comparisons; queries, search, Save, Copy,
  Format, Diff, Patch, Validate and Merge are between 0.88 and 1.07 times what they were). The differences that are measurable are
  small and consistent: walking all the children of a list 1.5–3.2 times slower (microseconds to milliseconds), Find in Source
  1.2–1.35 times, opening up to 16% slower, the first rows of a 100 MiB list 17% slower, JMESPath 5–7%, and a peak of memory while
  opening that is higher by about the size of the file (the file is read into a buffer before it is parsed). What stays in memory is the
  same; what no longer stays is the mapped file (104 MiB for a 100 MiB file).
- **256 MiB looks a conservative place to switch.** Keeping the *same* file on disk (on the head, where that is a setting) opens it
  ten times faster at every size from 1 MiB, and from **4 MiB** up it also answers queries 2 to 850 times faster (to 4,900 at 100 MiB) and goes from open to
  answer 36 to 51 times faster, in under a hundredth of the memory, at the cost of the per-node operations and the writing out above: 2 to 4 times
  slower, which at 16 MiB is 80–100 ms on Save, Copy and Find in Source. See [the threshold](#is-256-mib-the-right-size).

## A 300 MiB list of 2.24 million records

Medians of the timed runs; *heap* is the highest anonymous memory in the first run. `rec-300m` is 314,579,247 bytes. "Faster" and
"slower" are the verdicts of the comparison (beyond 10% and beyond the noise of the scenario).

| | before | after | | heap before | heap after |
|---|---:|---:|---|---:|---:|
| Open the file | 3.76 s | 400 ms | 9.4× faster | 6.3 GiB | 1.0 MiB |
| Let go of it (open another) | 2.03 s | 2.5 ms | 797× faster | 6.3 GiB | 0.5 MiB |
| Open, first rows, two first queries | 17.9 s | 453 ms | 40× faster | 11.4 GiB | 1.3 MiB |
| First rows of the tree | 194 ms | 139 ns | 3 rows in runs, not 2.24 million | 6.6 GiB | 1.0 MiB |
| Cancel a running query: time to stop | 8.23 s | 144 µs | 57,208× faster | 11.2 GiB | 5.3 MiB |
| jq `.[1165000]` | 6.66 s | 450 µs | 14,809× faster | 11.2 GiB | 1.2 MiB |
| jq `length` | 6.05 s | 446 µs | 13,562× faster | 11.2 GiB | 1.2 MiB |
| jq `first(.[] \| select(...))` | 5.99 s | 1.1 ms | 5,510× faster | 11.2 GiB | 1.3 MiB |
| jq `limit(100; ...)` | 6.00 s | 1.9 ms | 3,202× faster | 11.2 GiB | 1.4 MiB |
| jq `{count: length, first: .[0].id, last: .[-1].id}` | 6.07 s | 872 µs | 6,960× faster | 11.2 GiB | 1.3 MiB |
| jq `first(...)` found in the middle | 6.90 s | 579 ms | 12× faster | 11.2 GiB | 5.3 MiB |
| jq filter the whole list for one record | 8.04 s | 1.14 s | 7.1× faster | 11.2 GiB | 5.3 MiB |
| jq `map(.id) \| length` | 6.94 s | 1.32 s | 5.3× faster | 11.2 GiB | 265 MiB |
| jq `map(.score) \| add` | 7.75 s | 1.98 s | 3.9× faster | 11.2 GiB | 469 MiB |
| jq `map(select(.qty > 90)) \| length` | 8.03 s | 2.06 s | 3.9× faster | 11.2 GiB | 1.0 GiB |
| jq `min_by(.score) \| .id` | 7.46 s | 906 ms | 8.2× faster | 11.2 GiB | 5.5 MiB |
| jq `sort_by(.score) \| .[0:3]` | 15.1 s | 1.34 s | 11× faster | 11.4 GiB | 185 MiB |
| jq `group_by(.k) \| length` | 12.3 s | 2.15 s | 5.7× faster | 11.6 GiB | 254 MiB |
| jq `map(.k) \| unique \| length` | 14.5 s | 4.09 s | 3.5× faster | 11.3 GiB | 872 MiB |
| jq regular expression over a field | 14.1 s | 2.05 s | 6.9× faster | 11.2 GiB | 5.3 MiB |
| jq `first(.. \| select(...))` | 46.4 s | 5.86 s | 8.0× faster | 11.2 GiB | 5.4 MiB |
| JSONPath filter over the list | 975 ms | 514 ms | 1.9× faster | 6.3 GiB | 4.4 MiB |
| JMESPath filter and count | 6.03 s | 633 ms | 9.5× faster | 11.4 GiB | 5.9 MiB |
| JMESPath `length(@)` | 5.39 s | 22 µs | 243,373× faster | 11.4 GiB | 1.0 MiB |
| JMESPath `max_by` over the whole list | 5.98 s | refused |  | 11.4 GiB | – |
| Search: a text that is there once | 2.51 s | 2.18 s | 1.2× faster | 6.3 GiB | 1.0 MiB |
| Search: a text that is not there | 2.46 s | 2.21 s | 1.1× faster | 6.3 GiB | 1.0 MiB |
| Search: a regex that matches nothing | 2.00 s | 2.16 s | ≈ | 6.3 GiB | 1.0 MiB |
| Find in Source for a whole record | 1.39 s | 3.38 s | 2.4× slower | 6.3 GiB | 1.0 MiB |
| 2000 lookups of a node by its place | 296 µs | 8.9 ms | 30× slower | 6.3 GiB | 1.2 MiB |
| Walk every child of the root | 11 ms | 266 ms | 25× slower | 6.3 GiB | 1.0 MiB |
| JSON Pointer to a field | 202 ns | 24 µs | 117× slower | 6.3 GiB | 1.0 MiB |
| Text view (first 20,000 nodes) | 581 µs | 2.0 ms | 3.5× slower | 6.3 GiB | 1.6 MiB |
| Copy one record | 254 ns | 3.0 µs | 12× slower (microseconds) | 6.3 GiB | 1.0 MiB |
| Copy the whole document | 1.25 s | refused (over 64 MiB) |  | 6.8 GiB | – |
| Save one record | 10 µs | 14 µs | 1.4× slower (microseconds) | 6.3 GiB | 1.0 MiB |
| Save the whole document | 1.29 s | 3.01 s | 2.3× slower | 6.3 GiB | 1.9 MiB |
| Format from the file (Tools window) | not possible (over 128 MB) | 2.87 s | new | – | 1.9 MiB |
| Autocomplete after `.[].` | 5.0 ms | 13 µs | 385× faster | 6.3 GiB | 1.1 MiB |

The same pattern holds for `nd-300m`, the same records one to a line, within a few percent: the same scenario on the two files, measured
minutes apart, differs by a median of 1% (after) to 2% (before) and 4% at the 90th percentile, which also says how repeatable the
single-pass figures at this size are. Copying or saving *one* record is microseconds on both builds (254 ns → 3.0 µs and 10 µs → 14 µs).
For the other shapes at 300 MiB (opening, before → after): the catalog 2.97 s → 0.38 s; the object of 6.3 million members 4.06 s → 0.52 s;
the 44.8 million numbers 3.39 s → 0.37 s; the long strings 146 ms → 68 ms.

## Memory of an open document

What the process holds right after it opened a file, with the document open ([the full table](reports/before-after-mmap.md#memory-of-an-open-document)).
*Heap* is what has to fit in RAM and swap. *Mapped file* is the file's own pages, which are the page cache's and are given back when the
machine wants memory.

| File | before: heap | mapped file | after: heap | mapped file | |
|---|---:|---:|---:|---:|---|
| 16 MiB of records (parsed by both) | 352 MiB | 19.6 MiB | 352 MiB | 3.8 MiB | the file's pages are no longer kept; the peak while opening is 364 MiB (the buffer) |
| 100 MiB of records (parsed by both) | 2.1 GiB | 104 MiB | 2.1 GiB | 4.0 MiB | the peak while opening is 2.2 GiB |
| 300 MiB of records | 6.3 GiB | 304 MiB | 1.0 MiB | 304 MiB | 6,300 times less |
| 300 MiB of records, one to a line | 6.3 GiB | 303 MiB | 1.0 MiB | 304 MiB | |
| 300 MiB catalog (nested) | 4.4 GiB | 304 MiB | 0.9 MiB | 304 MiB | 5,000 times less |
| 300 MiB of numbers | 4.3 GiB | 303 MiB | 11 MiB | 304 MiB | 400 times less |
| 300 MiB, one object of 6.3 million members | 3.9 GiB | 304 MiB | 2.1 MiB (196 MiB at the peak) | 304 MiB | 1,900 times less |
| 300 MiB, long strings | 305 MiB | 304 MiB | 0.4 MiB | 304 MiB | 720 times less |
| 1 GiB of records | killed at the 14 GiB ceiling | | 2.3 MiB | 1.0 GiB | |

A parsed document took 22 times the file for these records (a list and an object in each), 15 for the catalog and the numbers and 13 for
the big object (the commit's own figure was 12 to 17 times, for flatter records). The new build's index is 0.56 MB for the
records, 1.6 MB for the big object, 11 MB for the 44.8 million numbers. Opening the big object holds 196 MiB of heap for a moment (the
check for a key that is written twice, which holds the 6.3 million keys) and gives it back.

## A gigabyte

The old build was run with a ceiling of 14 GiB for one process. Of the 51 scenarios that apply to 1 GiB of records, 25 (all of those
that have to open the file) were killed by the ceiling; 25 (the jq and JMESPath queries, which convert the whole document as well, an estimated
53 GiB each) were not tried; one (Format from the file) does not exist there. A gigabyte of these records is some 21 GiB parsed.
The new build ran 49 of the 51 and refused two: `max_by` over the whole list, and `map(select(...)) | length`, which gathers more than 1 GiB.

| After, 1 GiB of records | |
|---|---:|
| Open (the check of the file, 790 MB/s) | 1.35 s, 2.3 MiB of heap |
| First rows of the tree; open, first rows and two first queries | 286 ns; 1.36 s |
| jq `.[n]`, `length`, `first(...)`, `limit(...)`, `{count: length, ...}` | 0.46 to 1.9 ms |
| jq a filter for one record; `min_by`; `sort_by \| .[0:3]` | 4.0 s; 3.7 s; 5.5 s (6.5 MiB; 7 MiB; 616 MiB) |
| jq `group_by`; `map(.id)`; `map(.score) \| add`; `unique` | 10.6 s; 4.4 s; 6.7 s; 19.4 s (856 MiB; 887 MiB; 1.5 GiB; 2.9 GiB) |
| Search for a text; Find in Source | 7.5 s; 11.5 s |
| Save the whole document; Format from the file | 10.2 s; 10.1 s (3 MiB) |
| 2000 lookups of a node by its place; walk every child | 9.3 ms; 0.90 s |

## What costs more on a file kept on disk

All on files of 256 MiB or more. Of the 140 pairs compared there, 84 are faster, 39 slower and 17 the same.

| What | Before | After | Likely cause (from the code) |
|---|---:|---:|---|
| A node by its place (a list of 2.24 million) | 0.15 µs | 4.4 µs | the child's number is found among the index's checkpoints and a short walk |
| ... in a list of 44.8 million numbers | 47 ns | 0.6 µs | |
| A member of an object of 6.3 million members by its key | 0.07 µs | 250 ms | the members are walked; there is no hash |
| Every child of the list in turn | 10.5 ms | 266 ms | the children are walked (44.8 million numbers: 0.21 s → 0.83 s) |
| JSON Pointer to a field of a record | 0.2 µs | 24 µs | the same two steps |
| Find in Source (every node equal to a whole record) | 1.39 s | 3.38 s | every node is compared through the index |
| Text view (first 20,000 nodes) | 0.58 ms | 2.0 ms | read from the file |
| Save the whole document | 1.29 s | 3.01 s (2.3×; 3.6× for the numbers) | written as it is read: the writer makes a few small strings for each key and each number with a fraction (`core/src/lazy/write.rs`) |
| Search of long strings, or of the catalog | 96–1740 ms | 185–1990 ms (1.1–1.9×) | looking at the bytes does not beat walking a tree by much |
| Copy of the whole document | 1.25 s | refused above 64 MiB | |

None of these is a delay a person sees; Save and Find in Source are the same job done in a thousandth of the memory.

## What is refused

Each of these was answered before (with 6 to 11 GiB of memory for it) and gives an error in the place of the answer now, with a message that says
what to do instead. The harness records them as results: a query that made nothing but an error is *refused*, and `perf.py compare` lists it
as having stopped working.

| On a file of 256 MiB or more | Message |
|---|---|
| jq `add` over 44.8 million numbers (11.0 s before) | ``add` needs all of an array of 44755000 items (300.0 MB) in memory, which is too much for this: look at a part of it with a slice such as .[0:100], or work on one element at a time with .[] \| …, map(…), […] or first(…)` |
| `map(. * 2) \| add` over them (16.6 s); `[.[]] \| length` over the object of 6.3 million members (5.4 s); `map(select(...)) \| length` over a gigabyte of records | `what this gathers is over 1.0 GB — too much to hold in memory; narrow it, or run it over one part of the file at a time` |
| JMESPath `max_by(@, &score).id` over the whole list (6.0 s) | `an array of 2239000 items (300.0 MB) is too big to be a part of an expression (over 16.0 MB): narrow it with a slice such as .[0:100]` |
| jq `[.. \| .sku? // empty] \| length` over a 300 MiB catalog (29.6 s, 8.8 GiB) | ``empty` needs all of an object of 1 keys (300.1 MB) in memory, which is too much for this: …` |
| Copy to Clipboard of the document (0.2 to 1.3 s) | `that value is 314579247 bytes, too big to copy: use Save… to write it to a file` |

## Files that are still parsed

Files below 256 MiB take the same code path as before, with new things under it. The time after over the time before, per scenario and
file ([the whole matrix](reports/before-after-mmap.md#files-that-both-builds-parse) has them all; each small file is three passes of the
scenario on each build, the 100 MiB one a single pass):

| | 1 MiB | 16 MiB | 100 MiB |
|---|---:|---:|---:|
| open | 1.00 | 1.10 | 1.07 |
| rows of the tree | 1.13 | 1.03 | 1.17 |
| a node by its place (2000) | 1.08 | 1.17 | 1.11 |
| **walk every child** | **3.22** | **1.65** | **1.76** |
| **Find in Source** | **1.27** | **1.35** | **1.30** |
| search a text / a regex that is not there | 0.96 / 0.95 | 0.95 / 0.99 | 0.97 / 0.96 |
| jq `length` / a filter / `sort_by` | 0.97 / 1.01 / 1.00 | 1.00 / 1.00 / 0.97 | 1.00 / 0.99 / 1.00 |
| JMESPath filter | 1.05 | 1.07 | 1.05 |
| Save / Copy / Text view | 1.05 / 0.92 / 0.94 | 0.97 / 0.98 / 0.95 | 1.00 / 1.02 / 1.02 |
| Format / Diff / Validate / Merge / Patch | 0.99 / 1.01 / 0.88 / 1.01 / 1.01 | 1.04 / 1.03 / 0.98 / 1.01 / 1.02 | 0.99 / – / – / – / – |

- **Walking children** (what search, Find in Source and the rows stand on) takes about 6.6 ns a child where it took 2 ns (8,000 children: 16 µs → 53 µs).
  The code that matches it: a parsed value's `iter_children` is now the value's own boxed iterator wrapped in a second boxed iterator that turns each child into a `Root`
  (`core/src/document.rs`). It is the likeliest cause of Find in Source being 1.2–1.35 times slower on parsed files too, since that walks every node; a search is not slower,
  because it spends its time on the strings.
- **Opening** is up to 16% slower (24% for a 1 MiB object): the file is read into a buffer where it was mapped, which is consistent with the figures. The memory at its highest
  while opening is higher by about the size of the file (352 → 364 MiB for 16 MiB; 2.1 → 2.2 GiB for 100 MiB), what the open document holds is the same, and the mapped pages of the file,
  which stayed as long as the document did (104 MiB for a 100 MiB file), are gone. Opening a document of a few dozen bytes is faster (2.6 µs where it took 6.1 µs).
- **JMESPath** is 5–7% slower (the variables are `Arc` where they were `Rc`), as expected.
- Everything else, the Tools window's algorithms included, is as it was: those are the controls, and they are within 12% of 1.00 (a run's noise is 1–3%).

## Is 256 MiB the right size?

The Settings commit that came after this change made the 256 MiB a setting, which makes it possible to keep the *same* file parsed or on disk and compare them.
[reports/threshold-parsed-vs-lazy.md](reports/threshold-parsed-vs-lazy.md) does that on the head (`56aa08a`) for 1, 2, 4, 8, 16 and 100 MiB of records (and 16 MiB of
the big object and of the catalog). Each cell is the time parsed → the time kept on disk, in bold where kept on disk is more than twice as fast:

| parsed → kept on disk | 1 MiB | 2 MiB | 4 MiB | 8 MiB | 16 MiB | 100 MiB |
|---|---:|---:|---:|---:|---:|---:|
| **Opening, and what a person waits for** | | | | | | |
| open the file | **15 ms → 1.4 ms** | **28 ms → 2.8 ms** | **53 ms → 5.5 ms** | **111 ms → 11 ms** | **242 ms → 23 ms** | **1.42 s → 136 ms** |
| let go of it | **7.3 ms → 18 µs** | **14 ms → 7.2 µs** | **28 ms → 48 µs** | **56 ms → 53 µs** | **117 ms → 231 µs** | **702 ms → 537 µs** |
| first rows of the tree | **529 µs → 302 ns** | **1.0 ms → 427 ns** | **1.9 ms → 692 ns** | **3.8 ms → 1.2 µs** | **8.3 ms → 2.2 µs** | **72 ms → 13 µs** |
| open, first rows, two first queries | 65 ms → 99 ms | 120 ms → 187 ms | **235 ms → 6.5 ms** | **455 ms → 12 ms** | **993 ms → 23 ms** | **6.84 s → 135 ms** |
| cancel a running query: time to stop |  |  |  |  | **412 ms → 179 µs** | **2.70 s → 110 µs** |
| **Queries (jq unless said)** | | | | | | |
| `.[n]` from the middle | 26 ms → 49 ms | 49 ms → 94 ms | **93 ms → 461 µs** | **186 ms → 467 µs** | **393 ms → 464 µs** | **2.28 s → 464 µs** |
| `length` | 23 ms → 49 ms | 44 ms → 86 ms | **84 ms → 452 µs** | **172 ms → 455 µs** | **354 ms → 454 µs** | **2.06 s → 452 µs** |
| filter the list for one record | 30 ms → 56 ms | 58 ms → 101 ms | **113 ms → 47 ms** | **220 ms → 60 ms** | **486 ms → 98 ms** | **2.70 s → 368 ms** |
| `map(.id) \| length` | 27 ms → 51 ms | 51 ms → 93 ms | **97 ms → 46 ms** | **193 ms → 64 ms** | **430 ms → 112 ms** | **2.37 s → 426 ms** |
| `sort_by(.score) \| .[0:3]` | 36 ms → 58 ms | 69 ms → 114 ms | **138 ms → 44 ms** | **295 ms → 61 ms** | **740 ms → 106 ms** | **4.86 s → 435 ms** |
| `group_by(.k) \| length` | 32 ms → 54 ms | 60 ms → 106 ms | **119 ms → 48 ms** | **262 ms → 68 ms** | **593 ms → 119 ms** | **3.88 s → 603 ms** |
| a regex over a field | 52 ms → 77 ms | 99 ms → 140 ms | **192 ms → 86 ms** | **385 ms → 118 ms** | **799 ms → 195 ms** | **4.89 s → 759 ms** |
| JMESPath filter and count | 24 ms → 45 ms | 47 ms → 88 ms | **90 ms → 29 ms** | **178 ms → 38 ms** | **382 ms → 68 ms** | **2.14 s → 268 ms** |
| JSONPath filter | 1.8 ms → 27 ms | 6.1 ms → 49 ms | 14 ms → 20 ms | 27 ms → 27 ms | 58 ms → 45 ms | 342 ms → 189 ms |
| **Search and autocomplete** | | | | | | |
| search for a text that is not there | 9.3 ms → 8.8 ms | 17 ms → 16 ms | 34 ms → 31 ms | 68 ms → 62 ms | 145 ms → 133 ms | 837 ms → 751 ms |
| autocomplete after `.[].` | **53 µs → 12 µs** | **59 µs → 12 µs** | **71 µs → 12 µs** | **113 µs → 12 µs** | **137 µs → 12 µs** | **952 µs → 13 µs** |
| **Per node, and writing out** | | | | | | |
| 2000 lookups of a node by its place | 371 µs → 8.4 ms | 279 µs → 8.1 ms | 277 µs → 8.1 ms | 298 µs → 8.2 ms | 308 µs → 9.0 ms | 324 µs → 8.3 ms |
| walk every child | 53 µs → 958 µs | 104 µs → 1.9 ms | 204 µs → 3.6 ms | 411 µs → 7.2 ms | 1.0 ms → 15 ms | 6.5 ms → 91 ms |
| Find in Source | 6.7 ms → 13 ms | 12 ms → 24 ms | 24 ms → 46 ms | 48 ms → 92 ms | 103 ms → 195 ms | 620 ms → 1.14 s |
| Text view | 532 µs → 2.1 ms | 553 µs → 2.0 ms | 529 µs → 2.0 ms | 532 µs → 2.0 ms | 670 µs → 2.1 ms | 542 µs → 2.0 ms |
| Save the whole document | 4.5 ms → 14 ms | 9.8 ms → 21 ms | 19 ms → 42 ms | 37 ms → 82 ms | 88 ms → 169 ms | 471 ms → 1.02 s |
| Copy the whole document | 3.7 ms → 12 ms | 8.2 ms → 22 ms | 17 ms → 42 ms | 32 ms → 85 ms | 78 ms → 181 ms | 499 ms → refused |
| **Heap of the open document** | 23 MiB → 0.4 MiB | 47 MiB → 0.4 MiB | 90 MiB → 0.4 MiB | 179 MiB → 0.4 MiB | 352 MiB → 0.5 MiB | 2.1 GiB → 0.7 MiB |

- **Opening** is ten times faster at every size from 1 MiB, and letting go of the document is instant; the heap of an open 16 MiB file goes from 352 MiB to 0.5 MiB.
- **Queries** are the surprise below 4 MiB: kept on disk they are 1.5 to 2 times *slower* up to 2 MiB, and from 4 MiB on they are faster (`.[n]` 93 ms → 0.46 ms, a filter 2.4 times,
  `sort_by` 3.1 times, and at 100 MiB 1.8 to 4,900 times). The reason is in the code: a document of up to 4 MiB (`materialize_bytes`) is parsed whole by the evaluator, so below that
  it does the work twice. The end-to-end figure follows (open, first rows, two first queries: slower at 1 and 2 MiB, 36 times faster at 4 MiB, 51 times at 100 MiB). JSONPath filters
  are the last to cross, at about 8 MiB.
- **The per-node operations and the writing out** are 2 to 4 times slower at every size. In absolute terms, for a 16 MiB file: Save +81 ms, Copy +103 ms, Find in Source +92 ms,
  walking every child +14 ms, the Text view +1.4 ms, a lookup 4 µs; for a 100 MiB file: Save +0.55 s, Find in Source +0.52 s, Copy refused (over 64 MiB).
- **Search** is the same either way (0.9 times), and autocomplete is faster kept on disk at every size.

On these measures the break-even is nearer 4 MiB than 256 MiB. Where it should be set depends on how much the second group weighs against the first.

## Expectations, and what happened

[PLAN.md](PLAN.md) §7 lists what was expected before the full run.

| | Expected | Result |
|---|---|---|
| E1 | open of 256 MiB or more several times faster, a thousandth of the heap | **held**: 7.8 to 9.4 times faster for the lists, 2.1 for the long strings; heap 400 to 6,300 times less (the big object 1,900 times, with a 196 MiB peak) |
| E2 | open below 256 MiB as it was (±10%), peak heap +file, kept memory −file | **mostly held**: +0 to +10% for the records, the catalog and the lines, +16% (16 MiB) to +24% (1 MiB) for the big object; the peak is +3 to +7%; the mapped pages are gone |
| E3 | letting go of a big document is instant; as it was below | **held**: 2.03 s → 2.5 ms; 6.1 → 6.4 ms, 109 → 108 ms, 680 → 685 ms |
| E4 | the first rows of a 300 MiB list take milliseconds, where they took seconds and gigabytes | **held in part**: 139 ns against 194 ms (not seconds), and 3 rows against 2.24 million (0.3 GiB of rows) |
| E5 | a lookup slower on disk; a key in a huge object much slower | **held**: 30 times (4.4 µs); 250 ms for a key among 6.3 million |
| E6 | walking the children of a parsed list a little slower | **held**: 1.5 to 3.2 times, never enough to see in a search |
| E7 | search faster on disk (the commit says 4.0 s → 1.6 s) | **not held**: 10–20% faster for the records, 10–90% slower for long strings and the catalog. As far as the commit's text says, its figure is the search of a file kept on disk before and after it stopped making strings of what it looks at, not parsed against kept on disk |
| E8 | place and early-stop queries in milliseconds; whole-list queries several times faster; sorts and groups as fast or faster | **held, and more**: 6–7 s → under 2 ms; 3.5 to 12 times; `sort_by` 11 times, `group_by` 5.7 times |
| E9 | a few queries not faster, or slower, or refused | **held**: the JSONPath filter is 1.9 times faster, `keys \| length` of the big object is 1.1 times (5.5 s against 6.2 s, with 1.2 GiB against 7.6 GiB), and the refusals above |
| E10 | JMESPath like jq; a few percent slower parsed; `max_by` refused | **held**: a filter 9.5 times faster, `length(@)` 243,000 times; +5–7% parsed; `max_by` refused |
| E11 | Save streams: faster, no heap; Copy refused above 64 MiB | **held in part**: no heap (2 MiB for 6.3 GiB) but **2.3 times slower**; Copy refused |
| E12 | autocomplete on a huge object much faster | **not measurable**: 11 µs on both (it was already fast); after `.[].` it is 385 times faster |
| E13 | the Tools' algorithms as they were; Format from the file works | **held**: within 12% of 1.00; Format of 300 MiB in 2.9 s (1.9 MiB), of 1 GiB in 10.1 s |
| E14 | a cold open of a big file limited by the disk | **inconclusive on this disk**: cold equals warm to within 4% (the NVMe reads 300 MiB in about 80 ms), except for the long strings, where nothing else takes time (146 → 190 ms before, 68 → 109 ms after) |
| E15 | cancel stops a query within milliseconds on disk, after the conversion on a parsed document | **held**: 8.23 s → 0.14 ms at 300 MiB; 0.39 s and 2.6 s on a parsed 16 and 100 MiB, both builds |
| E16 | open, rows and two queries of 300 MiB in a few seconds before, well under one after | **held**: 17.9 s (more than a few seconds) → 0.45 s |

## How far to trust it

- **The machine** is shared with other work (a load average of 3 to 5 before a run began, 22 GiB free, the swap full), with a `powersave` governor and turbo. Everything is in the JSON,
  with the load average and the free memory at the start of every process. The two builds alternate, scenario by scenario and the order swaps each time, which is what makes a
  comparison fair; the absolute times are only this machine's.
- **Repeats.** Files up to 16 MiB: three passes of 5 to 50 runs each, aggregated by the median of the passes; the noise of a scenario (median absolute deviation over the median)
  is usually 1–3%. 100 MiB and above: one pass of a few runs of seconds each, because three would take hours; the 300 MiB records, measured on two files, agree to 1–2%
  (above). A difference counts as a change only beyond 10% and beyond three times the noise of the scenario; sub-20 µs differences are ignored as timer noise.
- **What the harness calls is what the app calls**, in the same order and with the same limits, but it is not the app: not the window, not a download, not the Tools' job runner
  (PLAN.md §3.9). The time of a frame with a big document open is not measured.
- **Page cache.** The files are in memory, as they would be for someone who opened them a moment ago. A cold open reads the disk, which is fast here (4 GB/s) and would not be on a slower one.
- **Memory** is the heap (anonymous memory) read from `/proc` every 4 ms in the first run of a scenario, so a peak shorter than that can be missed. The resident size of the *new* build is
  dominated by the mapped pages of the file (304 MiB for a 300 MiB file), which the kernel can drop and which are not heap.
- **A refusal is a result, not a failed measurement:** its time is the time to refuse.
- **The old build at 1 GiB** is a ceiling (14 GiB), not a measurement of what it needs: the 21 GiB is the 22-fold of the smaller files.
- **The first run of the plan was made before** the cancel and workflow scenarios existed, and before the harness kept the text of a refusal; those were measured afterwards with a harness
  that differs only in those additions, and the three scenarios whose answer was an error (`add`, `map(...) | add`, `[.[]] | length`) were measured again. The run files say so in `extensions`.

## What the numbers point at

These are observations about the code the figures came from, not changes made.

1. **The default.** A file of 4 MiB or more is already opened and queried two to several hundred times faster (and cancelled, measured from 16 MiB, a thousand times faster), and takes a hundredth of the memory or less, when kept on disk;
   what it gives up is 2 to 4 times on Save, Copy, Find in Source and the Text view (about a hundred milliseconds at 16 MiB), and microseconds on each node. The setting exists now, so the
   default is a matter of weighing those two.
2. **`Root::iter_children` for a parsed value** wraps the value's own boxed iterator in a `map` and boxes that: two virtual calls a child, where there was one. That fits the whole of the
   1.5–3.2× on walking children, and most likely the 1.2–1.35× on Find in Source for parsed files.
3. **The lazy writer** (`core/src/lazy/write.rs`) allocates for every key (`key.to_string()`, then `serde_json::to_vec`) and for every number that is not a plain integer (`number_text`), while the path for
   a string with no escape already writes the bytes as they are. The same for keys, and for numbers with a fraction, is where the 2.3–3.6× on Save and Format of a file kept on disk would go first.
4. **A huge object has no index of its keys:** a key is found by a walk, 250 ms among 6.3 million. If objects of that size matter, the scan, which already visits every key for the check of repeated keys,
   could keep a sample or a hash of them.
5. **Below 4 MiB a kept-on-disk document is parsed whole for each query** (`materialize_bytes`), so forcing a small file to be kept on disk makes queries 1.5–2 times slower than parsing it.
   That does not matter at the default.
6. **A query on a parsed document converts the whole document to jq's values first**, whatever the query is (0.39 s for `.[n]` of 16 MiB, 2.3 s of 100 MiB, 6.7 s of 300 MiB). That is what the
   kept-on-disk path avoids, and it is as true of the new build below 256 MiB as it was of the old.

## Reproducing

```sh
python3 perf.py run --rev before-mmap=65ae0d3 --rev after-mmap=950c9ab --profile standard --passes 3 --max-time-s 25
python3 perf.py run --rev before-mmap=65ae0d3 --rev after-mmap=950c9ab --profile standard --only 'query\.cancel_latency|workflow\.open_browse_query' --passes 3 --add
python3 perf.py run --rev before-mmap=65ae0d3 --rev after-mmap=950c9ab --profile full --only rec-1g --memory-cap 14G --add
python3 perf.py run --rev before-mmap=65ae0d3 --rev after-mmap=950c9ab --profile standard --only tree-300m --add
python3 perf.py run --rev current=56aa08a --profile threshold --passes 3 --max-time-s 25
python3 perf.py run --rev current=56aa08a --profile crossover --passes 3 --max-time-s 25 --add
python3 perf.py compare runs/2026-10-07_before-mmap_65ae0d3.json runs/2026-10-07_after-mmap_950c9ab.json --md reports/before-after-mmap.md --json reports/before-after-mmap.json
python3 perf.py compare runs/2026-10-07_current_56aa08a.json runs/2026-10-07_current_56aa08a.json --a-mode parsed --b-mode lazy --md reports/threshold-parsed-vs-lazy.md --json reports/threshold-parsed-vs-lazy.json
```
