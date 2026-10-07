"""Running the scenarios and keeping what they measured.

Every scenario on every dataset is one process of the harness (`jq-perf run`), so that what one does
to the memory or to the allocator is not in the next one's figures and a scenario that runs out of
memory ends only itself. Each process runs in its own cgroup with a ceiling on its memory (when
`systemd-run` is there), and is the first to be killed if the machine runs short.

When two or more builds are given they take turns: the same scenario on each in a row, the order
swapped every time, so that whatever the rest of the machine is doing hits all of them alike.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Dict, List, Optional, Tuple

from . import SCHEMA, datasets, jsonio, say, sysinfo
from .build import Build, catalogue
from .paths import work_dir

MIB = 1024 * 1024
#: The app keeps a file of this many bytes or more on disk (jsonquery_core::LAZY_THRESHOLD).
LAZY_THRESHOLD = 256 * MIB
#: Memory to leave to the rest of the machine, in MiB.
RESERVE_MIB = 2048
#: A scenario whose estimated need is more than this many times the ceiling is not even tried (a smaller
#: excess is: the estimate is rough, and a process that passes the ceiling is a result).
SKIP_BEYOND = 2.5
#: What `--resume --retry` runs again: not an answer of the revision's, but something that stopped it.
RETRYABLE = ("killed", "skipped", "timeout", "failed")


@dataclass
class Options:
    profile: str = "standard"
    only: Optional[str] = None
    exclude: Optional[str] = None
    passes: int = 1
    #: Datasets bigger than this (MiB, nominal) are run in the first pass only: their scenarios take
    #: seconds, so a single run is steady enough, and repeating them would take hours.
    passes_up_to_mib: int = 16
    min_reps: int = 5
    max_reps: int = 50
    min_time_ms: int = 500
    max_time_s: int = 90
    #: Ceiling on the memory of one process, in MiB (None: only what the machine has to give).
    memory_cap_mib: Optional[int] = None
    timeout_s: int = 1200
    machine_label: Optional[str] = None
    out_dir: Path = Path(".")
    resume: bool = False
    #: With `resume`: run again what was killed, skipped, timed out or failed (not what ran and said no).
    retry: bool = False
    #: Add results to a run that is finished (scenarios the harness did not have then, or datasets the
    #: profile did not have): its header stays as it was and says what was added, and when.
    add: bool = False
    #: With `add`: results of the scenarios this regular expression matches are dropped from the run and
    #: measured again (a scenario that was measured before the harness could tell what it can now).
    replace: Optional[str] = None
    dry_run: bool = False


@dataclass
class Item:
    dataset: str
    mode: str
    scenario: Dict[str, object]


def plan(profile: str, cat: List[Dict[str, object]], only: Optional[str], exclude: Optional[str]) -> List[Item]:
    """The (dataset, mode, scenario) triples a profile runs: each scenario on the datasets of the
    kinds it is for, within the sizes it is for."""
    if profile not in datasets.PROFILES:
        raise SystemExit(f"perf.py: no profile {profile!r} (there are {', '.join(datasets.PROFILES)})")
    include = re.compile(only) if only else None
    skip = re.compile(exclude) if exclude else None
    items: List[Item] = []
    for dataset_id, mode in datasets.PROFILES[profile]:
        spec = datasets.SPECS[dataset_id]
        mib = spec.target_bytes // MIB
        for scenario in cat:
            if spec.kind not in scenario["kinds"]:  # type: ignore[operator]
                continue
            if mib < int(scenario["min_mib"]):  # type: ignore[arg-type]
                continue
            top = scenario["max_mib"]
            if top is not None and mib > int(top):  # type: ignore[arg-type]
                continue
            sid = str(scenario["id"])
            if include and not include.search(sid) and not include.search(dataset_id):
                continue
            if skip and (skip.search(sid) or skip.search(dataset_id)):
                continue
            # `parsed` and `lazy` compare the two ways in: only what depends on the way is worth a run.
            if mode != "auto" and scenario["group"] in ("tools",) and sid != "tools.format_stream":
                continue
            items.append(Item(dataset_id, mode, scenario))
    return items


def estimate_mib(build: Build, meta: dict, mode: str, scenario: Dict[str, object]) -> float:
    """Roughly how much memory a scenario takes, to tell what a machine cannot hold (a gigabyte
    parsed takes some seventeen). The ceiling is what protects the machine; this only saves running
    what is sure to be killed."""
    size = meta["bytes"] / MIB
    kept_on_disk = bool(build.info.get("lazy_documents")) and (
        mode == "lazy" or (mode == "auto" and meta["bytes"] >= LAZY_THRESHOLD)
    )
    if kept_on_disk:
        return 800 + size * 0.15
    factor = float(meta.get("parsed_factor", 17))
    sid = str(scenario["id"])
    if sid.startswith(("query.jq", "query.jmespath")) or sid.startswith("tools."):
        extra = 2.4
    elif sid.startswith(("copy.", "save.document", "text.", "search.", "rows.")):
        extra = 1.5
    else:
        extra = 1.15
    return size * factor * extra


def cgroup_command(cap_mib: Optional[int], cmd: List[str]) -> List[str]:
    """`cmd` in a scope of its own with a ceiling on its memory (and none on swap use)."""
    if cap_mib and shutil.which("systemd-run"):
        return ["systemd-run", "--user", "--scope", "--quiet", "-p", f"MemoryMax={cap_mib}M",
                "-p", "MemorySwapMax=0", "--"] + cmd
    return cmd


def _first_to_die() -> None:
    """Called in the child before it starts: if the machine runs out of memory, it is this that the
    kernel ends, not somebody's editor."""
    try:
        with open("/proc/self/oom_score_adj", "w") as f:
            f.write("1000")
    except OSError:
        pass


def scrub(value: object) -> object:
    """A result as it is kept: the paths of this machine taken out of its texts (a run is kept in a
    repository, and an error that names a file should not name where somebody's home is) and its numbers
    rounded to what a clock can tell."""
    if isinstance(value, str):
        text = value
        for path, name in ((str(work_dir()), "$JQ_PERF_WORK"), (str(Path.home()), "~")):
            text = text.replace(path, name)
        return text
    if isinstance(value, float):
        # Milliseconds to a nanosecond: what a clock can tell, and a file a third the size.
        return round(value, 6)
    if isinstance(value, list):
        return [scrub(v) for v in value]
    if isinstance(value, dict):
        return {k: scrub(v) for k, v in value.items()}
    return value


def run_one(
    build: Build,
    item: Item,
    meta: dict,
    opts: Options,
    scratch: Path,
    pass_no: int,
) -> Dict[str, object]:
    """One scenario on one dataset, as one record."""
    data_dir = work_dir() / "data"
    scenario = item.scenario
    sid = str(scenario["id"])
    base: Dict[str, object] = {
        "scenario": sid,
        "group": scenario["group"],
        "dataset": item.dataset,
        "kind": meta["kind"],
        "mode": item.mode,
        "pass": pass_no,
        "api": build.info.get("api"),
    }
    if scenario.get("needs_lazy") and not build.info.get("lazy_documents"):
        return {**base, "status": "unsupported",
                "error": "this revision has no documents kept on disk"}

    state = sysinfo.memory_state()
    available = int(state.get("mem_available_mib") or 0)
    need = estimate_mib(build, meta, item.mode, scenario)
    cap = available - RESERVE_MIB
    if opts.memory_cap_mib:
        cap = min(cap, opts.memory_cap_mib)
    process: Dict[str, object] = {
        "loadavg_1m": (state.get("loadavg") or [None])[0],  # type: ignore[index]
        "mem_available_mib": available,
        "memory_cap_mib": cap if shutil.which("systemd-run") else None,
        "estimated_need_mib": round(need),
    }
    if need > cap * SKIP_BEYOND:
        return {**base, "status": "skipped", "process": process,
                "error": f"would take about {round(need)} MiB, and no more than {cap} MiB may be used"}

    cmd = [
        str(build.binary), "run",
        "--scenario", sid,
        "--file", str(data_dir / f"{item.dataset}.json"),
        "--meta", str(data_dir / f"{item.dataset}.meta.json"),
        "--mode", item.mode,
        "--work-dir", str(scratch),
        "--min-reps", str(opts.min_reps),
        "--max-reps", str(opts.max_reps),
        "--min-time-ms", str(opts.min_time_ms),
        "--max-time-s", str(opts.max_time_s),
    ]
    started = time.time()
    try:
        done = subprocess.run(
            cgroup_command(cap if cap > 0 else None, cmd),
            capture_output=True, text=True, timeout=opts.timeout_s, preexec_fn=_first_to_die,
        )
    except subprocess.TimeoutExpired:
        process["wall_s"] = round(time.time() - started, 2)
        return {**base, "status": "timeout", "process": process,
                "error": f"no answer in {opts.timeout_s} s"}
    process["wall_s"] = round(time.time() - started, 2)
    process["exit_code"] = done.returncode

    line = next((l for l in reversed(done.stdout.splitlines()) if l.startswith("{")), None)
    if done.returncode != 0 or line is None:
        killed = done.returncode in (137, -9)
        tail = (done.stderr or "").strip().splitlines()[-3:]
        return {**base, "status": "killed" if killed else "failed", "process": process,
                "error": ("killed, most likely for passing the memory ceiling of "
                          f"{process['memory_cap_mib']} MiB" if killed else " | ".join(tail) or "no output")}
    try:
        record = json.loads(line)
    except ValueError as e:
        return {**base, "status": "failed", "process": process, "error": f"unreadable output: {e}"}
    record.update({k: v for k, v in base.items() if k not in record})
    record["pass"] = pass_no
    record["process"] = process
    return record


class RunWriter:
    """One run's JSON file, written after every result so that a run that is stopped keeps what it has."""

    def __init__(self, path: Path, header: Dict[str, object]):
        self.path = path
        self.header = header
        self.results: List[Dict[str, object]] = []

    def load_existing(self, keep_header: bool = False) -> None:
        if self.path.exists():
            previous = json.loads(self.path.read_text())
            self.results = previous.get("results", [])
            if keep_header:
                skip = {"results", "summary", "complete"}
                extensions = list(previous.get("extensions", []))
                extensions.append({k: v for k, v in self.header.items()
                                   if k in ("method", "harness", "system")})
                extensions[-1]["added_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                self.header = {k: v for k, v in previous.items() if k not in skip}
                self.header["extensions"] = extensions

    def done(self, rec: Dict[str, object]) -> bool:
        key = (rec["scenario"], rec["dataset"], rec["mode"], rec["pass"])
        return any((r["scenario"], r["dataset"], r["mode"], r["pass"]) == key for r in self.results)

    def has(self, scenario: str, dataset: str, mode: str, pass_no: int) -> bool:
        return any(
            (r["scenario"], r["dataset"], r["mode"], r["pass"]) == (scenario, dataset, mode, pass_no)
            for r in self.results
        )

    def add(self, rec: Dict[str, object]) -> None:
        self.results.append(rec)
        self.save(complete=False)

    def summary(self) -> Dict[str, int]:
        counts: Dict[str, int] = {}
        for r in self.results:
            counts[str(r["status"])] = counts.get(str(r["status"]), 0) + 1
        counts["total"] = len(self.results)
        return counts

    def save(self, complete: bool, extra: Optional[Dict[str, object]] = None) -> None:
        doc = dict(self.header)
        doc["complete"] = complete
        doc["summary"] = self.summary()
        if extra:
            doc.update(extra)
        doc["results"] = self.results
        tmp = self.path.with_suffix(".json.tmp")
        tmp.write_text(jsonio.dumps(doc, "results"))
        os.replace(tmp, self.path)


def dataset_summary(meta: dict) -> Dict[str, object]:
    keep = ("id", "kind", "bytes", "sha256", "description", "generator", "count", "members",
            "categories", "products_per_category", "parsed_factor")
    return {k: meta[k] for k in keep if k in meta}


def run(
    builds: List[Build],
    app: Path,
    opts: Options,
    log: Callable[[str], None] = say,
) -> List[Path]:
    work = work_dir()
    data_dir = work / "data"
    scratch = work / "scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    cat = catalogue(builds[0])
    items = plan(opts.profile, cat, opts.only, opts.exclude)
    if not items:
        raise SystemExit("perf.py: nothing to run (the profile and the filters leave no scenario)")

    if opts.dry_run:
        by_dataset: Dict[str, int] = {}
        for it in items:
            by_dataset[f"{it.dataset}/{it.mode}"] = by_dataset.get(f"{it.dataset}/{it.mode}", 0) + 1
        for key, n in by_dataset.items():
            log(f"  {key:22s} {n:3d} scenarios")
        small = sum(1 for it in items if datasets.SPECS[it.dataset].target_bytes // MIB <= opts.passes_up_to_mib)
        runs = (len(items) + small * (opts.passes - 1)) * len(builds)
        log(f"  {'total':22s} {len(items):3d} per build and pass, {runs} runs in all")
        return []

    # Datasets first: a run should not stop half way for a file to be made.
    metas: Dict[str, dict] = {}
    for dataset_id, _ in datasets.PROFILES[opts.profile]:
        if dataset_id not in metas:
            metas[dataset_id] = datasets.ensure(data_dir, datasets.SPECS[dataset_id], log=log)

    system = sysinfo.collect(data_dir, opts.machine_label)
    started_utc = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    day = time.strftime("%Y-%m-%d")
    opts.out_dir.mkdir(parents=True, exist_ok=True)

    writers: Dict[str, RunWriter] = {}
    for b in builds:
        name = f"{day}_{b.label}_{b.short}.json"
        path = opts.out_dir / name
        if opts.resume or opts.add:
            found = sorted(opts.out_dir.glob(f"*_{b.label}_{b.short}.json"))
            if not opts.add:
                found = [p for p in found if not json.loads(p.read_text()).get("complete")]
            if found:
                path = found[-1]
        header = {
            "schema": SCHEMA,
            "kind": "run",
            "label": b.label,
            "started_utc": started_utc,
            "revision": b.revision_json(),
            "harness": {**b.info, "source_hash": b.source_hash},
            "system": system,
            "method": {
                "profile": opts.profile,
                "filters": {"only": opts.only, "exclude": opts.exclude},
                "passes": opts.passes,
                "min_reps": opts.min_reps,
                "max_reps": opts.max_reps,
                "min_time_ms": opts.min_time_ms,
                "max_time_s": opts.max_time_s,
                "memory_cap_mib": opts.memory_cap_mib,
                "isolation": "one process per scenario and dataset; each in its own cgroup with a "
                             "memory ceiling where systemd-run is available",
                "taking_turns_with": [o.label for o in builds if o is not b],
            },
            "datasets": {k: dataset_summary(v) for k, v in metas.items()},
        }
        writer = RunWriter(path, header)
        if opts.resume or opts.add:
            writer.load_existing(keep_header=opts.add)
            if opts.add:
                # Datasets the profile has that the run did not: they are part of it now.
                writer.header["datasets"] = {**writer.header.get("datasets", {}), **header["datasets"]}
            if opts.add and opts.replace:
                pattern = re.compile(opts.replace)
                kept = [r for r in writer.results if not pattern.search(str(r["scenario"]))]
                dropped = len(writer.results) - len(kept)
                writer.results = kept
                if writer.header.get("extensions"):
                    writer.header["extensions"][-1]["replaced"] = {"matching": opts.replace, "results": dropped}
            if opts.retry:
                writer.results = [r for r in writer.results if r["status"] not in RETRYABLE]
        writers[b.label] = writer

    per_pass = [sum(1 for it in items if pass_no == 1 or datasets.SPECS[it.dataset].target_bytes // MIB <= opts.passes_up_to_mib)
                for pass_no in range(1, opts.passes + 1)]
    total = sum(per_pass) * len(builds)
    count = 0
    t0 = time.time()
    for pass_no in range(1, opts.passes + 1):
        for index, item in enumerate(items):
            if pass_no > 1 and datasets.SPECS[item.dataset].target_bytes // MIB > opts.passes_up_to_mib:
                continue
            order = builds if (index + pass_no) % 2 == 0 else list(reversed(builds))
            for b in order:
                count += 1
                writer = writers[b.label]
                sid = str(item.scenario["id"])
                if writer.has(sid, item.dataset, item.mode, pass_no):
                    continue
                rec = scrub(run_one(b, item, metas[item.dataset], opts, scratch, pass_no))
                writer.add(rec)  # type: ignore[arg-type]
                med = (rec.get("stats") or {}).get("median") if isinstance(rec.get("stats"), dict) else None
                shown = f"{med:.3g} ms" if isinstance(med, (int, float)) else str(rec.get("error") or "")[:60]
                log(f"[{count}/{total}] {b.label:12s} {sid:34s} {item.dataset:9s} {item.mode:6s} "
                    f"{str(rec['status']):11s} {shown}")
    finished = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    out = []
    for b in builds:
        writer = writers[b.label]
        timing = {
            "finished_utc": finished,
            "duration_s": round(time.time() - t0),
            "state_at_end": sysinfo.memory_state(),
        }
        if opts.add and writer.header.get("extensions"):
            # An addition to a run that was finished says when it was made and how long it took, in its own
            # place: the header goes on describing the run it was.
            writer.header["extensions"][-1].update(timing)
            writer.save(complete=True)
        else:
            writer.save(complete=True, extra=timing)
        out.append(writer.path)
    return out
