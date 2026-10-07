# Performance tests

How long the functions of [jsonquery gui](https://github.com/nujufas/jsonquery_gui) take and how much
memory they use, on files of a few kilobytes to a gigabyte, at any revision of the app, with the results
kept as JSON so that a later revision can be compared with an earlier one. It sits beside the Robot suite
(`../suites/`), which checks that the app *works*; this checks how *fast* it works, and does not need
a display.

The first thing it was made for is to compare the app before and after files of 256 MiB or more were
memory-mapped and indexed instead of being parsed. [PLAN.md](PLAN.md) says what is measured and why,
[FINDINGS.md](FINDINGS.md) what came of that comparison, and [runs/](runs/) and [reports/](reports/)
hold its data.

## Quick start

You need Linux, `git`, `tar`, a Rust toolchain (the harness is built with the app's own), Python 3.10 or
later (the tooling uses only its standard library, not the `.venv` of the Robot suite) and, to keep a
runaway process from taking the machine, `systemd-run` (used if it is there). Give the checkout of the app with
`--app` or `$JQ_APP_DIR`; as for the Robot suite, `../jsonquery_gui` and `../jsonquery` are looked at otherwise.

```sh
cd performance
python3 perf.py plan --profile standard                 # what a run would do, and how many runs
python3 perf.py run --rev before=65ae0d3 --rev after=950c9ab --profile standard --passes 3
python3 perf.py compare runs/<before>.json runs/<after>.json --md reports/before-after.md
```

A run builds the harness at each revision, makes the datasets it needs (once), and measures every
scenario on every dataset, the revisions taking turns. The `standard` profile with `--passes 3` took an hour and
three quarters for two revisions on the machine it was developed on (the old build spends most of it parsing
300 MiB files again and again); `--profile quick` takes about twenty minutes and `--profile smoke` two. Use a machine that is doing nothing else, and say so in
`--machine-label`.

Everything big goes into `$JQ_PERF_WORK` (default `~/.cache/jsonquery-perf`: exports of the app, the build,
the datasets, about 3 GB of them and 1 GB for each revision), never into this repository and never into
`/tmp`, which may be a RAM disk that would take memory from what is measured.

## Commands

| Command | What it does |
|---|---|
| `perf.py run --rev [LABEL=]REV ...` | build the harness at each revision (a commit, tag or branch, or `WORKTREE`, the checkout as it is), make the datasets, measure, and write one JSON file per revision into `runs/` |
| `perf.py compare A.json B.json` | what is faster, slower, heavier, newly working, newly failing, or gives other answers; `--md` and `--json` write it down; `--fail-on slower,heavier,failing,differs` exits 1 if there is any |
| `perf.py plan` | the scenarios and datasets of a profile, and how many runs they come to |
| `perf.py data` | make the datasets of a profile |
| `perf.py build` | build the harness at a revision |
| `perf.py list` | the scenarios the harness has |
| `perf.py system` | what is known about this machine (what goes into every result) |
| `perf.py check-plan` | see that [PLAN.md](PLAN.md), `catalogue.json` and the scenarios agree |
| `perf.py catalogue` | write `catalogue.json`: the scenarios, datasets and profiles as data |
| `perf.py selftest` | the tooling's unit tests (`tests/`) and the harness's own (cargo test, in an export of the app) |

Options of `run` worth knowing: `--only REGEX` and `--exclude REGEX` (on scenario ids and dataset ids),
`--passes N` (the whole list N times; only datasets up to `--passes-up-to-mib`, 16, are repeated),
`--memory-cap 20G` (the most one process may take), `--resume` (carry on a run that was stopped: results are
saved after every scenario; `--retry` also runs again what was killed or skipped), `--add` (add results to
a run that is finished, for scenarios or datasets it did not have: its header stays as it was and says what was added and
when; `--replace REGEX` drops the results of some scenarios first and measures them again), `--machine-label`,
`--out-dir`. `perf.py compare A.json A.json --a-mode parsed --b-mode lazy` compares the two ways of keeping a file in one run.

### Profiles

| Profile | Datasets | Runs per revision | For |
|---|---|---|---|
| `smoke` | one of each shape, 1 to 2 MiB | 163 | does everything work |
| `quick` | and 16 MiB files | 290 | a change to the parsed path |
| `standard` | and 100 MiB and 300 MiB files | 527 | the comparison of before and after the mapping |
| `full` | and 1 GiB of records | 578 | where the old build runs out of memory |
| `threshold` | 1, 16 and 100 MiB files, once forced to be parsed and once kept on disk (needs `load_with`: the Settings commit or later) | 388 | where is the right size to switch |
| `crossover` | the same, 1 to 16 MiB in steps | 512 | where, to the MiB |

## Reading a comparison

`perf.py compare` prints a Markdown report: the two runs and machines, a summary, the memory of an open
document, then tables of what works differently, what is slower, what is heavier and what gave other
answers, and at the end every scenario by area. Times are medians of the timed runs; memory is the highest
*heap* (anonymous memory) during the first run. A change is a change only if it is beyond the tolerance
(10%), beyond three times how much the runs of that scenario differed among themselves, and beyond the
timer's floor (so noise is not reported); `--tolerance` and `--noise` change them. A scenario too slow to be repeated has one run, and then the
first run of both sides is compared. "Other answers" means the fingerprint of what the scenario made is
not the same: see [expected_differences.json](expected_differences.json) for the ones that are by design.

Two runs are comparable when they were made on the same machine (the report warns when not), with the
same profile and datasets (their SHA-256 is in the file), on a machine that was as quiet. Look at the
load average and the free memory a run started with before believing a surprising figure.

## Layout

```
performance/
  PLAN.md                  what is measured and why; checked against the harness by `check-plan`
  FINDINGS.md              what the first comparison found
  catalogue.json           the plan as data: scenarios (id, group, kinds, sizes), datasets, profiles
  README.md                this
  perf.py                  the command line
  perflib/                 the tooling: build, datasets, runner, compare, report, JSON writing (standard library only)
  bench/                   the harness, in Rust: `jq-perf run --scenario ... --file ...`
    build.rs                 finds out which API the revision under test has
    src/api_before.rs        what the app calls, for a revision where a document is a parsed value
    src/api_after.rs         ... for one that has documents kept on disk
    src/scenarios/*.rs       the scenarios (load, rows, tree, search, query, output, tools, suggest)
  expected_differences.json  answers that differ by design, and why
  tests/                   unit tests of the tooling: `python3 -m unittest discover -s tests`
  runs/                    one JSON file for every run kept as a baseline
  reports/                 comparisons of them, as Markdown and JSON
```

`bench/` is not built where it is: its `Cargo.toml` points at `../core` and `../query`, which are
the app's crates. `perf.py build` copies it into an export of the app at the revision under test
(`crates/perf-bench`), adds it to that workspace and builds it there in release mode, so it links that
revision's own libraries, resolves their dependencies from that revision's `Cargo.lock`, and is optimized as that
revision's release profile says. The binary is kept in `$JQ_PERF_WORK/bin/<commit>-<hash of bench/>/`,
and is built again when the harness's sources change.

## What is in a run (`runs/*.json`)

```jsonc
{
  "schema": "jsonquery-perf/1", "kind": "run", "label": "after-mmap", "complete": true,
  "started_utc": "...", "finished_utc": "...", "duration_s": 7000,
  "revision": { "rev": "950c9ab", "sha": "<40 hex>", "short": "950c9ab", "describe": "v0.5.0-3-g950c9ab",
                "subject": "feat: a file of 256 MiB or more is ...", "committed": "...", "dirty": false },
  "harness":  { "harness_version": 1, "api": "after", "lazy_documents": true, "load_with": false,
                "threads_available": 20, "source_hash": "..." },
  "system":   { "machine": { "cpu_model": "...", "cpu_threads": 20, "ram_total_mib": 61912, "cpu_governor": "...",
                             "fingerprint": "..." },
                "os": { "distro": "...", "kernel": "..." }, "storage": { "fs": "ext4", "rotational": false, ... },
                "toolchain": { "rustc": "...", ... }, "state_at_start": { "loadavg": [...], "mem_available_mib": ... } },
  "method":   { "profile": "standard", "passes": 3, "min_reps": 5, "max_reps": 50, "min_time_ms": 500,
                "max_time_s": 90, "memory_cap_mib": null, "isolation": "...", "taking_turns_with": ["before-mmap"] },
  "datasets": { "rec-300m": { "kind": "records", "bytes": 314579247, "sha256": "...", "count": 2330000, ... } },
  "summary":  { "ok": 480, "error": 6, "killed": 0, "unsupported": 0, "skipped": 0, "total": 493 },
  "extensions": [ { "added_utc": "...", "duration_s": 537, "finished_utc": "...", "method": {...},
                    "harness": { "source_hash": "..." }, "replaced": { "matching": "<regex>", "results": 15 } } ],
  "results":  [ { /* one per scenario, dataset, mode and pass: below */ } ]
}
```

`extensions` is there when results were added to a finished run (`perf.py run --add`): scenarios the harness did not have when
it was made, datasets the profile did not have, or results measured again (`--replace`). The header above it goes on describing the
run it was; each extension says when it was made, how long it took, with which harness and which filters.

A result:

```jsonc
{
  "scenario": "query.jq.select_one", "group": "query", "dataset": "rec-300m", "kind": "records",
  "mode": "auto",                      // auto: as the app does it; parsed / lazy: forced
  "api": "after", "pass": 1,
  "status": "ok",                      // ok | error | unsupported | skipped | killed | timeout | failed
  "error": null,                       // why, when it is not ok
  "setup_ms": 412.3,                   // the document opened, not part of the timing
  "first_ms": 1212.0, "first_cpu_ms": 9400.1,   // the first run: what a person gets the first time
  "samples_ms": [1103.2, 1120.9, ...], "cpu_ms": [...],   // the runs after it
  "stats": { "n": 5, "min": 1098.0, "median": 1116.6, "mean": 1121.0, "p90": 1140.2, "max": 1150.0,
             "stdev": 18.2, "rel_mad": 0.011 },
  "ops": 1,                            // operations one run stands for (2000 lookups: 2000)
  "memory_kib": {                      // KiB, from /proc/self/status
    "start":       { "rss": 4132, "anon": 404, "file": 3728 },
    "after_setup": { "rss": ..., "anon": ..., "file": ... },   // with the document open
    "first_peak_anon": 41200, "first_peak_rss": 335000, "first_peak_file": 294000,   // highest, in the first run
    "after_first": { "anon": ..., "file": ... },               // right after the first run
    "end": { ... }                                             // after the last run
  },
  "fingerprint": { "basis": "query", "unit": "results", "count": 1, "hash": "5ba2..." },
  "extra": { "doc": { "lazy": true, "bytes": 314579247, "loader_ms": 395.0, "index_bytes": 559784 },
             "query": ".[] | select(.id == 1165000) | .name",
             "item_errors": 1, "first_item_error": "..." },   // when the query made errors: a refusal comes as one
  "process": { "wall_s": 9.1, "exit_code": 0, "loadavg_1m": 3.1, "mem_available_mib": 21000, "memory_cap_mib": 19000 }
}
```

Times are milliseconds, memory is KiB, and a field that does not apply is `null`. *Heap* is `anon`;
`file` is the pages of the mapped file that are in memory. A query that made nothing but errors (`item_errors` above 0 and a
fingerprint count of 0) is *refused*: the app shows the error where an answer would be, and `perf.py compare` counts it as having
stopped working, with the message.

## Adding a scenario

A scenario is a function in `bench/src/scenarios/` that opens what it needs with `m.setup(|| ctx.load())`
(which is not timed), and gives the one thing it measures to `m.time(|| ...)`, then boils what that made
down to a `Fingerprint` (`fp_query`, `fp_rows`, `fp_paths`, `fp_text`...). It names the kinds of dataset it is
for, and a range of sizes if it needs one. Then:

1. Say what it measures in [PLAN.md](PLAN.md), with its id in backticks (`perf.py check-plan` fails until you do).
2. If it needs something the revisions call differently, put it in both `api_before.rs` and `api_after.rs`.
3. If it needs a value from the dataset, have `perflib/datasets.py` write it into the sidecar (a unit test
   checks that every key a scenario reads is written).
4. Run it on a small dataset on two revisions (`perf.py run --only <id> --profile smoke ...`) and see that the
   fingerprints agree: if they do not, it is either a difference worth knowing about or a scenario that is
   not measuring what you think.

A change to what or how the harness measures should raise `HARNESS_VERSION` in `bench/src/main.rs`: results
of different versions are not to be compared without a look. A change to what a generator makes should raise
`GENERATOR_VERSION` in `perflib/datasets.py`.

## When something goes wrong

- *The build fails at a revision*: the API of the library changed. Fix the adapter for that API in
  `api_before.rs` or `api_after.rs` (they are a few lines for each thing the app calls); `build.rs` chooses
  between them by whether `jsonquery-core` has a `lazy` module.
- *A process was `killed`*: it passed the ceiling on memory. That is a result (a parsed gigabyte takes some seventeen),
  and the machine is no worse for it. Raise `--memory-cap` if the machine has the memory.
- *`Disk quota exceeded` while building or running*: `$TMPDIR` or `/tmp` is a small or shared file system. The build
  puts its temporary files in `$JQ_PERF_WORK/tmp`; set `JQ_PERF_WORK` to a disk with room.
- *Timings that do not repeat*: look at `state_at_start` and `process.loadavg_1m`: something else was using the machine.
  `--passes 3` (and a quiet machine) is the remedy.
