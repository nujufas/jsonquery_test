"""A comparison of two runs as Markdown: what was compared, on what, and what changed."""

from __future__ import annotations

from typing import Dict, List, Optional

from . import sysinfo
from .compare import Agg, Result, Row, Run

GROUP_TITLES = {
    "load": "Opening a document",
    "rows": "Rows of the tree",
    "tree": "Finding things in the tree",
    "search": "Search and Find in Source",
    "query": "Queries",
    "output": "Text view, Copy and Save",
    "tools": "The Tools window",
    "suggest": "Autocomplete",
    "workflow": "Open, look, ask (end to end)",
}


def fmt_ms(ms: Optional[float]) -> str:
    if ms is None:
        return "–"
    if ms >= 10_000:
        return f"{ms / 1000:.1f} s"
    if ms >= 1000:
        return f"{ms / 1000:.2f} s"
    if ms >= 100:
        return f"{ms:.0f} ms"
    if ms >= 10:
        return f"{ms:.1f} ms"
    if ms >= 1:
        return f"{ms:.2f} ms"
    if ms >= 0.001:
        return f"{ms * 1000:.0f} µs"
    return f"{ms * 1e6:.0f} ns"


def fmt_mib(kib: Optional[int]) -> str:
    if not kib:
        return "–"
    mib = kib / 1024
    if mib >= 1024:
        return f"{mib / 1024:.1f} GiB"
    if mib >= 100:
        return f"{mib:.0f} MiB"
    if mib >= 10:
        return f"{mib:.1f} MiB"
    return f"{mib:.1f} MiB"


def fmt_size(nbytes: int) -> str:
    if nbytes < 1024:
        return f"{nbytes} B"
    if nbytes < 1024 * 1024:
        return f"{nbytes / 1024:.1f} KiB"
    mib = nbytes / (1024 * 1024)
    return f"{mib / 1024:.2f} GiB" if mib >= 1024 else f"{mib:.1f} MiB"


def fmt_duration(seconds: float) -> str:
    seconds = int(seconds or 0)
    if seconds < 90:
        return f"{seconds} s"
    if seconds < 5400:
        return f"{seconds / 60:.0f} min"
    return f"{seconds / 3600:.1f} h"


def fmt_x(q: float) -> str:
    """A multiplier a person reads: 2.4, 12, 1,870 (never 1.87e+03)."""
    if q >= 100:
        return f"{q:,.0f}"
    if q >= 10:
        return f"{q:.0f}"
    return f"{q:.1f}"


def fmt_change(ratio: Optional[float], verdict: str) -> str:
    """`2.4× faster`, `1.3× slower`, `≈ same`."""
    if ratio is None or ratio <= 0:
        return "–"
    if verdict == "same":
        return "≈"
    if ratio < 1:
        q = 1 / ratio
        return f"**{fmt_x(q)}× faster**" if q >= 2 else f"{q:.2f}× faster"
    return f"**{fmt_x(ratio)}× slower**" if ratio >= 2 else f"{ratio:.2f}× slower"


def fmt_mem_change(ratio: Optional[float], verdict: str) -> str:
    if ratio is None or verdict in ("", "same"):
        return "≈" if verdict == "same" else "–"
    if ratio < 1:
        return f"{fmt_x(1 / ratio)}× less"
    return f"{fmt_x(ratio)}× more"


def _how(agg: Optional[Agg]) -> str:
    if agg is None or agg.lazy is None:
        return ""
    return "on disk" if agg.lazy else "parsed"


def _escape(text: object) -> str:
    return str(text).replace("|", "\\|").replace("\n", " ")


def _status_text(agg: Optional[Agg]) -> str:
    if agg is None:
        return "not run"
    if agg.status == "ok":
        return ""
    reason = (agg.error or "").strip()
    if reason.lower().startswith(agg.status):
        return reason[:160]
    return f"{agg.status}" + (f": {reason[:160]}" if reason else "")


def _run_line(run: Run) -> str:
    rev = run.doc.get("revision", {})
    dirty = " (uncommitted changes)" if rev.get("dirty") else ""
    method = run.doc.get("method", {})
    complete = "" if run.doc.get("complete") else " — **incomplete**"
    return (f"| {run.label} | `{rev.get('short')}`{dirty} {rev.get('subject', '')} | {run.doc.get('harness', {}).get('api')} "
            f"| {run.doc.get('started_utc', '')[:10]} | {method.get('profile')} × {method.get('passes')} "
            f"| {fmt_duration(run.doc.get('duration_s', 0))}{complete} |")


def _open_memory_table(a: Run, b: Run, result: Result, w) -> None:
    """What an open document costs in memory: the headline of keeping a file on disk."""
    rows = [r for r in result.rows if r.key[0] == "load.open" and r.a and r.b]
    if not rows:
        return
    w("## Memory of an open document\n")
    w("Resident memory of the process right after a file is opened, with the document still open. "
      "*Heap* is anonymous memory: what a parsed tree takes, and what has to be paid for out of the "
      "machine's RAM and swap. *Mapped file* is the file's own pages, which belong to the page cache "
      "and are given back whenever memory is wanted. *Peak heap* is the highest heap during the open itself.\n")
    w(f"| Dataset | File | {a.label}: how | heap | mapped file | peak heap | {b.label}: how | heap | mapped file | peak heap | Heap |")
    w("|---|---:|---|---:|---:|---:|---|---:|---:|---:|---|")
    datasets = {**a.doc.get("datasets", {}), **b.doc.get("datasets", {})}

    def cells(agg: Agg) -> str:
        if agg.status != "ok":
            return f"{_escape(_status_text(agg))} | | |"
        return f"{_how(agg)} | {fmt_mib(agg.end_anon_kib)} | {fmt_mib(agg.end_file_kib)} | {fmt_mib(agg.peak_anon_kib)}"

    for r in sorted(rows, key=lambda r: datasets.get(r.key[1], {}).get("bytes", 0)):
        ra, rb = r.a, r.b
        assert ra and rb
        size = fmt_size(datasets.get(r.key[1], {}).get("bytes", 0))
        ratio = ""
        if ra.status == "ok" and rb.status == "ok" and ra.end_anon_kib and rb.end_anon_kib:
            q = ra.end_anon_kib / rb.end_anon_kib
            ratio = f"**{fmt_x(q)}× less**" if q >= 1.5 else (f"{fmt_x(1 / q)}× more" if q < 0.8 else "≈")
        w(f"| {r.key[1]}{'' if r.key[2] == 'auto' else '/' + r.key[2]} | {size} | {cells(ra)} | {cells(rb)} | {ratio} |")
    w("")


#: The scenarios whose behaviour over the size of the file tells the story, and what is shown of each.
SCALING = [
    ("load.open", "Opening a file"),
    ("load.release", "Letting go of the open document"),
    ("rows.initial", "The first rows of the tree"),
    ("tree.resolve_random", "Finding nodes by their place (2000 lookups)"),
    ("query.jq.index_mid", "jq: one element from the middle"),
    ("query.jq.select_one", "jq: filter the whole list for one record"),
    ("query.jq.sort_by_head", "jq: sort_by and take three"),
    ("search.value_absent", "Search for a text that is not there"),
    ("save.document", "Save the whole document"),
]


def _scaling_tables(a: Run, b: Run, result: Result, w) -> None:
    """For the shape with most sizes, how the time and the heap of a few scenarios grow with the file."""
    datasets = {**a.doc.get("datasets", {}), **b.doc.get("datasets", {})}
    by_key = {r.key: r for r in result.rows}
    kinds: Dict[str, List[str]] = {}
    for dataset_id, d in datasets.items():
        kinds.setdefault(d.get("kind", ""), []).append(dataset_id)
    kind = max(kinds, key=lambda k: len(kinds[k])) if kinds else None
    if not kind:
        return
    ids = sorted(kinds[kind], key=lambda i: datasets[i].get("bytes", 0))
    if len(ids) < 3:
        return
    w(f"## Scaling with the size of the file ({kind})\n")
    w("How a few scenarios grow with the file. The change comes at 256 MiB, where the new build stops "
      "parsing: the columns up to 100 MiB are parsed by both. Times are medians (one run where a scenario "
      "is too slow to repeat); *heap* is the highest anonymous memory in the first run.\n")
    head = "| Scenario | |" + "".join(f" {fmt_size(datasets[i]['bytes'])} |" for i in ids)
    sep = "|---|---|" + "---:|" * len(ids)
    for what, key_text in (("time", "Time"), ("heap", "Heap")):
        w(f"### {key_text}\n")
        w(head)
        w(sep)
        for scenario, title in SCALING:
            cells: Dict[str, List[str]] = {a.label: [], b.label: []}
            seen = False
            for i in ids:
                row = by_key.get((scenario, i, "auto"))
                for run, agg in ((a, row.a if row else None), (b, row.b if row else None)):
                    if agg is None:
                        cells[run.label].append("")
                    elif agg.status != "ok":
                        cells[run.label].append(f"*{agg.status}*")
                        seen = True
                    else:
                        seen = True
                        single = row is not None and row.single_run
                        cells[run.label].append(fmt_ms(agg.first_ms if single else agg.median_ms)
                                                if what == "time" else fmt_mib(agg.peak_anon_kib))
            if not seen:
                continue
            w(f"| {title} | {a.label} |" + "".join(f" {c} |" for c in cells[a.label]))
            w(f"| | {b.label} |" + "".join(f" {c} |" for c in cells[b.label]))
        w("")


#: Scenarios shown in the matrix of what changed for files that are parsed by both.
MATRIX = [
    "load.open", "load.release", "rows.initial", "rows.reveal_middle", "tree.resolve_random",
    "tree.iterate_children", "search.value_absent", "search.regex_absent", "search.value_once",
    "search.locate_equal", "query.jq.length", "query.jq.select_one", "query.jq.sort_by_head",
    "query.jsonpath.filter", "query.jmespath.filter_count", "text.render_source", "copy.document",
    "save.document", "suggest.field_of_all", "tools.format_parsed", "tools.diff", "tools.validate",
    "tools.merge", "tools.patch",
]


def _parsed_matrix(a: Run, b: Run, result: Result, w) -> None:
    """For the files that both runs parsed: the time of the second run over that of the first, per scenario
    and file. Where it is 1.00 nothing changed; a figure beyond the tolerance and the noise has a star."""
    datasets = {**a.doc.get("datasets", {}), **b.doc.get("datasets", {})}
    by_key = {r.key: r for r in result.rows}
    columns = []
    for dataset_id, d in sorted(datasets.items(), key=lambda kv: (kv[1].get("kind", ""), kv[1].get("bytes", 0))):
        cells = [by_key.get((scenario, dataset_id, "auto")) for scenario in MATRIX]
        parsed = [r for r in cells if r and r.a and r.b and r.a.status == "ok" and r.b.status == "ok"
                  and r.a.lazy is False and r.b.lazy is False]
        if len(parsed) >= 3 and dataset_id != "tiny":
            columns.append(dataset_id)
    if not columns:
        return
    w("## Files that both builds parse\n")
    w(f"The time of `{b.label}` over the time of `{a.label}`, for each scenario and file that neither kept on disk: "
      "1.00 is no change, 2.00 is twice as long. A star marks a change beyond the tolerance and the noise. "
      "These are the functions that were changed underneath rather than replaced.\n")
    w("| Scenario |" + "".join(f" {c} |" for c in columns))
    w("|---|" + "---:|" * len(columns))
    for scenario in MATRIX:
        cells = []
        seen = False
        for dataset_id in columns:
            r = by_key.get((scenario, dataset_id, "auto"))
            if (r and r.a and r.b and r.a.status == "ok" and r.b.status == "ok"
                    and r.a.lazy is False and r.b.lazy is False and r.time_ratio):
                seen = True
                star = "\\*" if r.time in ("slower", "faster") else ""
                text = f"{r.time_ratio:.2f}{star}"
                cells.append(f"**{text}**" if r.time == "slower" else text)
            else:
                cells.append("")
        if seen:
            w(f"| `{scenario}` |" + "".join(f" {c} |" for c in cells))
    w("")


def markdown(a: Run, b: Run, result: Result) -> str:
    out: List[str] = []
    w = out.append
    w(f"# Performance: {a.label} → {b.label}\n")
    w("Generated by `perf.py compare`. Times are medians of the timed runs of one scenario; memory is the "
      "anonymous (heap) memory of the process at its highest during the first run (what a parsed "
      "document costs and a mapped one does not). \"Same\" means within the tolerance and the noise of the runs.\n")

    w("## The runs\n")
    w("| Label | Revision | API | Started (UTC) | Profile | Took |")
    w("|---|---|---|---|---|---|")
    w(_run_line(a))
    w(_run_line(b))
    w("")
    ma, mb = a.doc["system"]["machine"], b.doc["system"]["machine"]
    if ma.get("fingerprint") != mb.get("fingerprint"):
        w("> **Warning: the two runs were made on different machines**; their times are not comparable.\n")
    w(f"Machine of `{a.label}`: {sysinfo.describe(a.doc['system'])}.  ")
    if ma.get("fingerprint") == mb.get("fingerprint"):
        w(f"Machine of `{b.label}`: the same hardware.\n")
    else:
        w(f"Machine of `{b.label}`: {sysinfo.describe(b.doc['system'])}.\n")
    for run in (a, b):
        st = run.doc["system"].get("state_at_start", {})
        w(f"- `{run.label}` started with load average {st.get('loadavg')}, "
          f"{st.get('mem_available_mib')} MiB available, {st.get('swap_used_mib')} MiB of swap in use.")
    w("")

    counts = result.counts()
    w("## Summary\n")
    w(f"{len(result.rows)} scenario × dataset pairs: "
      + ", ".join(f"**{n}** {name}" for name, n in sorted(counts.items(), key=lambda kv: -kv[1])) + ".\n")

    _open_memory_table(a, b, result, w)
    _parsed_matrix(a, b, result, w)
    _scaling_tables(a, b, result, w)

    datasets = {**a.doc.get("datasets", {}), **b.doc.get("datasets", {})}
    w("## Datasets\n")
    w("| Id | Shape | Size | SHA-256 |")
    w("|---|---|---|---|")
    for key, d in sorted(datasets.items(), key=lambda kv: kv[1].get("bytes", 0)):
        w(f"| {key} | {d.get('kind')} | {fmt_size(d.get('bytes', 0))} | `{str(d.get('sha256', ''))[:16]}…` |")
    w("")

    def table(rows: List[Row], heading: str, note: str = "") -> None:
        if not rows:
            return
        w(f"### {heading}\n")
        if note:
            w(note + "\n")
        w(f"| Scenario | Dataset | {a.label} | {b.label} | Time | Memory {a.label} | Memory {b.label} | Notes |")
        w("|---|---|---:|---:|---|---:|---:|---|")
        for r in rows:
            ra, rb = r.a, r.b
            notes = []
            if ra and rb and ra.status == "ok" and rb.status == "ok":
                if ra.lazy != rb.lazy and ra.lazy is not None:
                    notes.append(f"{_how(ra)} → {_how(rb)}")
                if r.answers == "differs":
                    notes.append("**other answers**")
                elif r.answers == "expected":
                    notes.append(f"other answers, by design: {r.expected_reason}")
                elif r.answers == "not comparable":
                    notes.append("answers not comparable (other row layout)")
                if ra.ops > 1:
                    notes.append(f"{ra.ops} operations per run")
            else:
                if ra and ra.status != "ok":
                    notes.append(f"{a.label}: {_status_text(ra)}")
                if rb and rb.status != "ok":
                    notes.append(f"{b.label}: {_status_text(rb)}")
                if r.expected_reason:
                    notes.append(f"by design: {r.expected_reason}")
            pick = (lambda x: x.first_ms) if r.single_run else (lambda x: x.median_ms)
            shown = ("ok", "refused")
            time_a = fmt_ms(pick(ra)) if ra and ra.status in shown else "–"
            time_b = fmt_ms(pick(rb)) if rb and rb.status in shown else "–"
            if r.single_run:
                notes.append("one run each (too slow to repeat)")
            mem_a = fmt_mib(ra.peak_anon_kib) if ra and ra.status in shown else "–"
            mem_b = fmt_mib(rb.peak_anon_kib) if rb and rb.status in shown else "–"
            change = fmt_change(r.time_ratio, r.time) if r.time else ""
            mem = fmt_mem_change(r.memory_ratio, r.memory)
            mem_cell_b = mem_b + (f" ({mem})" if mem not in ("–", "≈", "") else "")
            w(f"| `{r.key[0]}` | {r.key[1]}{'' if r.key[2] == 'auto' else '/' + r.key[2]} | {time_a} | {time_b} | "
              f"{change} | {mem_a} | {mem_cell_b} | {_escape('; '.join(notes))} |")
        w("")

    w("## What changed\n")
    refused = [r for r in result.rows if r.status == "newly failing"]
    table(refused, "Stopped working",
          "Scenarios that worked in the first run and are refused (or fail) in the second: a limit on what a file kept "
          "on disk can answer, with the message the app gives.")
    gained = [r for r in result.rows if r.status == "newly working"]
    table(gained, "Newly working",
          "Scenarios that could not be run in the first run (not supported there, killed for passing the memory "
          "ceiling, or not tried because they would take far more memory than the ceiling) and work in the second.")
    neither = [r for r in result.rows if r.status == "both failing"]
    table(neither, "Not working in either",
          "Scenarios that did not work in either run.")
    faster = sorted((r for r in result.rows if r.time == "faster"), key=lambda r: (r.time_ratio or 0))
    table(faster[:30], "Biggest improvements",
          f"The {min(30, len(faster))} largest speed-ups of {len(faster)} scenarios that are faster in the second run.")
    slower = sorted((r for r in result.rows if r.time == "slower"), key=lambda r: -(r.time_ratio or 0))
    table(slower, "Slower", "Scenarios that take longer in the second run.")
    heavier = sorted((r for r in result.rows if r.memory == "heavier" and r.time != "slower"),
                     key=lambda r: -(r.memory_ratio or 0))
    table(heavier, "Heavier", "Scenarios that take more memory in the second run (and are not slower).")
    differs = [r for r in result.rows if r.answers == "differs"]
    table(differs, "Other answers", "Scenarios whose results are not what they were. Each is to be looked at.")

    w("## Every scenario\n")
    groups: Dict[str, List[Row]] = {}
    for r in result.rows:
        groups.setdefault(r.group, []).append(r)
    for group in GROUP_TITLES:
        rows = groups.get(group)
        if rows:
            table(rows, GROUP_TITLES[group])
    return "\n".join(out) + "\n"
