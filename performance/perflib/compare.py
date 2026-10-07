"""Comparing two runs: what is faster, what is slower, what is heavier, what works that did not (or
stopped working), and whether they gave the same answers.

A scenario is "the same" in both runs when its time differs by less than the tolerance (10% unless
told otherwise) and by less than a few times how much its own runs differed from each other, so that
noise is not reported as a change. Memory is judged the same way, with a floor of a few MiB.
"""

from __future__ import annotations

import fnmatch
import json
import statistics
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from . import SCHEMA
from .paths import PERF_DIR

Key = Tuple[str, str, str]

#: A difference in time under this many milliseconds is not one: below it a timer is the noise.
TIME_FLOOR_MS = 0.02
#: ... and in memory, under this many KiB.
MEMORY_FLOOR_KIB = 4096


@dataclass
class Agg:
    """What one scenario on one dataset came to in one run, over its passes."""

    status: str
    error: Optional[str] = None
    median_ms: float = 0.0
    first_ms: float = 0.0
    min_ms: float = 0.0
    noise: float = 0.0
    samples: int = 0
    cpu_ms: float = 0.0
    ops: int = 1
    peak_anon_kib: int = 0
    peak_rss_kib: int = 0
    peak_file_kib: int = 0
    doc_anon_kib: int = 0
    #: Resident memory right after the first run, with its document still open: heap and mapped file.
    end_anon_kib: int = 0
    end_file_kib: int = 0
    lazy: Optional[bool] = None
    fingerprint: Optional[dict] = None
    passes: int = 0
    wall_s: float = 0.0
    #: How many of what a query made were errors, and what the first said. A query that made nothing but
    #: errors is `refused`: the app shows the error where an answer would be.
    item_errors: int = 0
    first_item_error: Optional[str] = None


def _median(values: List[float]) -> float:
    return statistics.median(values) if values else 0.0


def aggregate(records: List[dict]) -> Agg:
    ok = [r for r in records if r.get("status") == "ok"]
    if not ok:
        first = records[0]
        return Agg(status=str(first.get("status")), error=first.get("error"), passes=len(records))
    medians, firsts, mins, noises, cpus = [], [], [], [], []
    anon, rss, doc_anon, file_peak, end_anon, end_file = [], [], [], [], [], []
    samples = 0
    for r in ok:
        stats = r.get("stats")
        first = r.get("first_ms") or 0.0
        medians.append(stats["median"] if stats else first)
        firsts.append(first)
        mins.append(stats["min"] if stats else first)
        noises.append(stats["rel_mad"] if stats and stats["n"] > 2 else 0.0)
        samples += stats["n"] if stats else 0
        cpu = r.get("cpu_stats")
        cpus.append(cpu["median"] if cpu else (r.get("first_cpu_ms") or 0.0))
        mem = r.get("memory_kib", {})
        anon.append(mem.get("first_peak_anon", 0))
        rss.append(mem.get("first_peak_rss", 0))
        file_peak.append(mem.get("first_peak_file", 0))
        held = mem.get("after_first") or mem.get("end", {})
        end_anon.append(held.get("anon", 0))
        end_file.append(held.get("file", 0))
        start = mem.get("start", {}).get("anon", 0)
        doc_anon.append(max(0, mem.get("after_setup", {}).get("anon", 0) - start))
    spread = (max(medians) - min(medians)) / _median(medians) if len(medians) > 1 and _median(medians) else 0.0
    doc = ok[0].get("extra", {}).get("doc", {})
    extra = ok[0].get("extra", {})
    item_errors = int(extra.get("item_errors") or 0)
    made = (ok[0].get("fingerprint") or {}).get("count", 0)
    return Agg(
        status="refused" if item_errors and not made else "ok",
        error=extra.get("first_item_error") if item_errors and not made else None,
        item_errors=item_errors,
        first_item_error=extra.get("first_item_error"),
        median_ms=_median(medians),
        first_ms=_median(firsts),
        min_ms=min(mins),
        noise=max(max(noises), spread),
        samples=samples,
        cpu_ms=_median(cpus),
        ops=int(ok[0].get("ops", 1)),
        peak_anon_kib=int(_median(anon)),
        peak_rss_kib=int(_median(rss)),
        peak_file_kib=int(_median(file_peak)),
        doc_anon_kib=int(_median(doc_anon)),
        end_anon_kib=int(_median(end_anon)),
        end_file_kib=int(_median(end_file)),
        lazy=doc.get("lazy"),
        fingerprint=ok[0].get("fingerprint"),
        passes=len(ok),
        wall_s=_median([r.get("process", {}).get("wall_s", 0.0) for r in ok]),
    )


@dataclass
class Run:
    path: Path
    doc: dict
    index: Dict[Key, Agg] = field(default_factory=dict)

    @property
    def label(self) -> str:
        return str(self.doc.get("label"))


def load(path: Path, mode: Optional[str] = None) -> Run:
    """A run from its file. With `mode`, only the results made in that mode (`parsed` or `lazy`: a file
    forced one way or the other), which are then taken for the usual `auto` ones, so that the two ways of
    keeping a file in one run (the `threshold` profile) can be compared as if they were two runs."""
    doc = json.loads(Path(path).read_text())
    if doc.get("schema") != SCHEMA:
        raise SystemExit(f"{path} is not a {SCHEMA} file")
    grouped: Dict[Key, List[dict]] = {}
    for r in doc["results"]:
        if mode is not None:
            if r["mode"] != mode:
                continue
            r = {**r, "mode": "auto"}
        grouped.setdefault((r["scenario"], r["dataset"], r["mode"]), []).append(r)
    if mode is not None:
        if not grouped:
            raise SystemExit(f"{path} has no results made in mode {mode!r}")
        doc = {**doc, "label": f"{doc.get('label')} ({mode})"}
    run = Run(Path(path), doc)
    run.index = {key: aggregate(records) for key, records in grouped.items()}
    return run


def load_expected() -> List[dict]:
    path = PERF_DIR / "expected_differences.json"
    try:
        return json.loads(path.read_text())
    except OSError:
        return []


@dataclass
class Row:
    key: Key
    group: str
    kind: str
    a: Optional[Agg]
    b: Optional[Agg]
    #: "faster", "slower", "same", or "" when there is nothing to compare
    time: str = ""
    time_ratio: Optional[float] = None
    #: One of the runs was too slow to be repeated, so the first run of both is what is compared.
    single_run: bool = False
    #: "lighter", "heavier", "same", or ""
    memory: str = ""
    memory_ratio: Optional[float] = None
    #: "newly working", "newly failing", "both failing", "" when both ran
    status: str = ""
    #: "same", "differs", "expected", "not comparable" or ""
    answers: str = ""
    expected_reason: str = ""


@dataclass
class Result:
    rows: List[Row]

    def counts(self) -> Dict[str, int]:
        """How many rows are what: faster, slower, lighter, heavier, same, newly working, failing (ran
        in the first run, does not in the second), differs (gave other answers)."""
        counts: Dict[str, int] = {}

        def bump(name: str) -> None:
            counts[name] = counts.get(name, 0) + 1

        for r in self.rows:
            if r.time:
                bump(r.time)
            if r.memory in ("lighter", "heavier"):
                bump(r.memory)
            if r.status == "newly working":
                bump("newly working")
            if r.status == "newly failing":
                bump("failing")
            if r.answers == "differs":
                bump("differs")
        return counts


def _judge_time(ma: float, mb: float, noise_a: float, noise_b: float,
                tolerance: float, noise: float) -> Tuple[str, Optional[float]]:
    if ma <= 0 and mb <= 0:
        return "same", 1.0
    if abs(mb - ma) < TIME_FLOOR_MS:
        return "same", (mb / ma if ma else None)
    ratio = mb / ma if ma else float("inf")
    limit = max(tolerance, noise * max(noise_a, noise_b))
    if ratio > 1 + limit:
        return "slower", ratio
    if ratio < 1 / (1 + limit):
        return "faster", ratio
    return "same", ratio


def _judge_memory(a: Agg, b: Agg, tolerance: float) -> Tuple[str, Optional[float]]:
    pa, pb = a.peak_anon_kib, b.peak_anon_kib
    if pa <= 0 or pb <= 0:
        return "", None
    ratio = pb / pa
    if abs(pb - pa) < MEMORY_FLOOR_KIB:
        return "same", ratio
    if ratio > 1 + tolerance:
        return "heavier", ratio
    if ratio < 1 / (1 + tolerance):
        return "lighter", ratio
    return "same", ratio


def _expected(expected: List[dict], key: Key, kind: str, mib: float, what: str) -> str:
    scenario, dataset, _ = key
    for entry in expected:
        if entry.get("what", "answers") != what:
            continue
        if not fnmatch.fnmatch(scenario, entry.get("scenario", "*")):
            continue
        if not fnmatch.fnmatch(kind, entry.get("kind", "*")):
            continue
        if mib < entry.get("min_mib", 0):
            continue
        return str(entry.get("reason", "by design"))
    return ""


def compare(a: Run, b: Run, tolerance: float = 0.10, noise: float = 3.0) -> Result:
    expected = load_expected()
    rows: List[Row] = []
    datasets = {**a.doc.get("datasets", {}), **b.doc.get("datasets", {})}
    for key in sorted(set(a.index) | set(b.index), key=lambda k: (k[1], k[0], k[2])):
        ra, rb = a.index.get(key), b.index.get(key)
        group = key[0].split(".")[0]
        info = datasets.get(key[1], {})
        row = Row(key=key, group=group, kind=str(info.get("kind", "")), a=ra, b=rb)
        mib = float(info.get("bytes", 0)) / (1024 * 1024)
        if ra is None or rb is None:
            rows.append(row)
            continue
        a_ok, b_ok = ra.status == "ok", rb.status == "ok"
        if a_ok and b_ok:
            # A scenario too slow to repeat has only its first run; then the first run of both is compared.
            row.single_run = ra.samples == 0 or rb.samples == 0
            if row.single_run:
                row.time, row.time_ratio = _judge_time(ra.first_ms, rb.first_ms, 0.0, 0.0, tolerance, noise)
            else:
                row.time, row.time_ratio = _judge_time(ra.median_ms, rb.median_ms, ra.noise, rb.noise,
                                                       tolerance, noise)
            row.memory, row.memory_ratio = _judge_memory(ra, rb, tolerance)
            fa, fb = ra.fingerprint or {}, rb.fingerprint or {}
            if fa.get("basis") != fb.get("basis"):
                row.answers = "not comparable"
            elif (fa.get("count"), fa.get("hash")) == (fb.get("count"), fb.get("hash")):
                row.answers = "same"
            else:
                reason = _expected(expected, key, row.kind, mib, "answers")
                row.answers = "expected" if reason else "differs"
                row.expected_reason = reason
        elif a_ok and not b_ok:
            row.status = "newly failing"
            row.expected_reason = _expected(expected, key, row.kind, mib, "failing")
        elif b_ok and not a_ok:
            row.status = "newly working"
        else:
            row.status = "both failing"
        rows.append(row)
    return Result(rows)


def to_json(a: Run, b: Run, result: Result) -> dict:
    def agg(x: Optional[Agg]) -> Optional[dict]:
        if x is None:
            return None
        return {
            "status": x.status,
            "error": x.error,
            "median_ms": x.median_ms,
            "first_ms": x.first_ms,
            "min_ms": x.min_ms,
            "noise": x.noise,
            "samples": x.samples,
            "cpu_ms": x.cpu_ms,
            "peak_anon_kib": x.peak_anon_kib,
            "peak_rss_kib": x.peak_rss_kib,
            "doc_anon_kib": x.doc_anon_kib,
            "end_anon_kib": x.end_anon_kib,
            "end_file_kib": x.end_file_kib,
            "kept_on_disk": x.lazy,
        }

    return {
        "schema": SCHEMA,
        "kind": "comparison",
        "from": {"label": a.label, "file": a.path.name, "revision": a.doc.get("revision")},
        "to": {"label": b.label, "file": b.path.name, "revision": b.doc.get("revision")},
        "counts": result.counts(),
        "rows": [
            {
                "scenario": r.key[0],
                "dataset": r.key[1],
                "mode": r.key[2],
                "from": agg(r.a),
                "to": agg(r.b),
                "time": r.time,
                "time_ratio": r.time_ratio,
                "single_run": r.single_run,
                "memory": r.memory,
                "memory_ratio": r.memory_ratio,
                "status": r.status,
                "answers": r.answers,
                "expected": r.expected_reason or None,
            }
            for r in result.rows
        ],
    }
