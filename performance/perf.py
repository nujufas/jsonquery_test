#!/usr/bin/env python3
"""The performance suite of jsonquery gui: how long the app's functions take, and how much memory they
use, on files of a few kilobytes to a gigabyte, at any revision of the app. Standard library only.

    perf.py run --rev before=65ae0d3 --rev after=950c9ab      measure two revisions, taking turns
    perf.py compare runs/<before>.json runs/<after>.json      what changed between two runs
    perf.py data --profile standard                           make the files the runs use
    perf.py plan --profile standard                           what a run would run, without running it

See README.md for the rest, PLAN.md for what is measured and why.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import List, Optional, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent))

from perflib import build as buildmod  # noqa: E402
from perflib import datasets, jsonio, paths, runner, say, sysinfo  # noqa: E402


def parse_size_mib(text: str) -> Optional[int]:
    """`20G`, `18000M`, `20` (GiB) or `none`."""
    text = text.strip().lower()
    if text in ("none", "off", "0", ""):
        return None
    match = re.fullmatch(r"(\d+(?:\.\d+)?)\s*([mg]?)i?b?", text)
    if not match:
        raise argparse.ArgumentTypeError(f"not a size: {text!r} (try 20G or 18000M)")
    number = float(match.group(1))
    return int(number * (1 if match.group(2) == "m" else 1024))


def split_rev(text: str) -> Tuple[str, str]:
    """`label=rev` or `rev`."""
    if "=" in text:
        label, _, rev = text.partition("=")
        return label, rev
    return text, text


def cmd_system(args: argparse.Namespace) -> None:
    print(json.dumps(sysinfo.collect(paths.work_dir() / "data", args.machine_label), indent=2))


def cmd_data(args: argparse.Namespace) -> None:
    data_dir = paths.work_dir() / "data"
    for dataset_id, _ in datasets.PROFILES[args.profile]:
        meta = datasets.ensure(data_dir, datasets.SPECS[dataset_id], log=say)
        say(f"  {dataset_id:10s} {meta['bytes']:>14,d} bytes  sha256 {meta['sha256'][:16]}")
    print(f"datasets are in {data_dir}")


def builds_from(args: argparse.Namespace) -> List[buildmod.Build]:
    app = paths.find_app(args.app)
    if not args.rev:
        raise SystemExit("perf.py: say which revision with --rev (a commit, a tag, a branch or WORKTREE)")
    out = []
    for text in args.rev:
        label, rev = split_rev(text)
        out.append(buildmod.build(app, rev, label, rebuild=args.rebuild))
    return out


def cmd_build(args: argparse.Namespace) -> None:
    for b in builds_from(args):
        print(f"{b.label}: {b.short} ({b.describe}) -> {b.binary}")
        print(f"   {json.dumps(b.info)}")


def cmd_list(args: argparse.Namespace) -> None:
    args.rev = args.rev or ["HEAD"]
    b = builds_from(args)[0]
    for s in buildmod.catalogue(b):
        sizes = f"{s['min_mib']}-{s['max_mib'] or '*'} MiB"
        print(f"{s['id']:34s} {s['group']:8s} {','.join(s['kinds']):52s} {sizes:12s} {s['title']}")


def cmd_plan(args: argparse.Namespace) -> None:
    args.rev = args.rev or ["HEAD"]
    builds = builds_from(args)
    opts = runner.Options(profile=args.profile, only=args.only, exclude=args.exclude, passes=1, dry_run=True)
    runner.run(builds, paths.find_app(args.app), opts)


def cmd_run(args: argparse.Namespace) -> None:
    builds = builds_from(args)
    opts = runner.Options(
        profile=args.profile,
        only=args.only,
        exclude=args.exclude,
        passes=args.passes,
        passes_up_to_mib=args.passes_up_to_mib,
        min_reps=args.min_reps,
        max_reps=args.max_reps,
        min_time_ms=args.min_time_ms,
        max_time_s=args.max_time_s,
        memory_cap_mib=args.memory_cap,
        timeout_s=args.timeout,
        machine_label=args.machine_label,
        out_dir=Path(args.out_dir),
        resume=args.resume,
        retry=args.retry,
        add=args.add,
        replace=args.replace,
        dry_run=args.dry_run,
    )
    written = runner.run(builds, paths.find_app(args.app), opts)
    for path in written:
        print(f"wrote {path}")


def cmd_compare(args: argparse.Namespace) -> None:
    from perflib import compare, report

    a = compare.load(Path(args.a), args.a_mode)
    b = compare.load(Path(args.b), args.b_mode)
    result = compare.compare(a, b, tolerance=args.tolerance, noise=args.noise)
    text = report.markdown(a, b, result)
    if args.md:
        Path(args.md).write_text(text)
        print(f"wrote {args.md}")
    else:
        print(text)
    if args.json:
        Path(args.json).write_text(jsonio.dumps(compare.to_json(a, b, result), "rows"))
        print(f"wrote {args.json}")
    counts = result.counts()
    print(
        "\n" + ", ".join(f"{n} {k}" for k, n in sorted(counts.items())),
        file=sys.stderr,
    )
    fail = {x.strip() for x in args.fail_on.split(",") if x.strip()}
    if any(counts.get(k, 0) for k in fail):
        raise SystemExit(1)


def cmd_selftest(args: argparse.Namespace) -> None:
    import subprocess

    here = Path(__file__).resolve().parent
    python = subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", str(here / "tests")])
    app = paths.find_app(args.app)
    rust = buildmod.selftest(app, (args.rev or ["HEAD"])[0].split("=")[-1])
    if python.returncode or rust:
        raise SystemExit(1)


def cmd_catalogue(args: argparse.Namespace) -> None:
    from perflib import catalogue

    args.rev = args.rev or ["HEAD"]
    b = builds_from(args)[0]
    doc = catalogue.build(buildmod.catalogue(b), b.info.get("harness_version"))
    catalogue.PATH.write_text(catalogue.render(doc))
    say(f"wrote {catalogue.PATH} ({len(doc['scenarios'])} scenarios, {len(doc['datasets'])} datasets)")  # type: ignore[arg-type]


def cmd_check_plan(args: argparse.Namespace) -> None:
    from perflib import catalogue, plancheck

    args.rev = args.rev or ["HEAD"]
    b = builds_from(args)[0]
    scenarios = buildmod.catalogue(b)
    problems = plancheck.check(scenarios) + catalogue.problems(scenarios, b.info.get("harness_version"))
    for problem in problems:
        print(problem)
    if problems:
        raise SystemExit(1)
    print("PLAN.md, catalogue.json and the harness's scenarios agree")


def main(argv: Optional[List[str]] = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)

    def add_app(p: argparse.ArgumentParser) -> None:
        p.add_argument("--app", help="the app's checkout (default: $JQ_APP_DIR, ../jsonquery_gui, ../jsonquery)")

    def add_rev(p: argparse.ArgumentParser) -> None:
        p.add_argument("--rev", action="append", metavar="[LABEL=]REV",
                       help="a revision of the app: a commit, tag or branch, or WORKTREE for the checkout as it is "
                            "(more than one: they take turns)")
        p.add_argument("--rebuild", action="store_true", help="build the harness again even if it is built")
        add_app(p)

    p = sub.add_parser("system", help="print what is known about this machine")
    p.add_argument("--machine-label", help="a name for this machine, kept with the results")
    p.set_defaults(func=cmd_system)

    p = sub.add_parser("data", help="make the files that runs use")
    p.add_argument("--profile", default="standard", choices=sorted(datasets.PROFILES))
    p.set_defaults(func=cmd_data)

    p = sub.add_parser("build", help="build the harness against revisions")
    add_rev(p)
    p.set_defaults(func=cmd_build)

    p = sub.add_parser("list", help="list the scenarios")
    add_rev(p)
    p.set_defaults(func=cmd_list)

    p = sub.add_parser("plan", help="show what a run would run")
    add_rev(p)
    p.add_argument("--profile", default="standard", choices=sorted(datasets.PROFILES))
    p.add_argument("--only", help="a regular expression: only the scenarios (or datasets) it matches")
    p.add_argument("--exclude", help="a regular expression: not the scenarios (or datasets) it matches")
    p.set_defaults(func=cmd_plan)

    p = sub.add_parser("run", help="measure one or more revisions")
    add_rev(p)
    p.add_argument("--profile", default="standard", choices=sorted(datasets.PROFILES))
    p.add_argument("--only", help="a regular expression: only the scenarios (or datasets) it matches")
    p.add_argument("--exclude", help="a regular expression: not the scenarios (or datasets) it matches")
    p.add_argument("--passes", type=int, default=1, help="how many times the list is run (default 1)")
    p.add_argument("--passes-up-to-mib", type=int, default=16,
                   help="only datasets up to this size are run more than once (default 16)")
    p.add_argument("--min-reps", type=int, default=5, help="timed runs of a scenario, at least (default 5)")
    p.add_argument("--max-reps", type=int, default=50, help="timed runs of a scenario, at most (default 50)")
    p.add_argument("--min-time-ms", type=int, default=500, help="keep timing until this long (default 500)")
    p.add_argument("--max-time-s", type=int, default=90, help="stop timing a scenario after this long (default 90)")
    p.add_argument("--memory-cap", type=parse_size_mib, default=None, metavar="SIZE",
                   help="the most memory one process may take, e.g. 20G (default: what the machine has free)")
    p.add_argument("--timeout", type=int, default=1200, help="seconds before a process is given up on")
    p.add_argument("--machine-label", help="a name for this machine, kept with the results")
    p.add_argument("--out-dir", default=str(paths.RUNS_DIR), help="where the results go (default: runs/)")
    p.add_argument("--resume", action="store_true", help="carry on a run that was stopped")
    p.add_argument("--retry", action="store_true",
                   help="with --resume: also run again what was killed, skipped, timed out or failed")
    p.add_argument("--add", action="store_true",
                   help="add results to the finished run of the same label and revision (new scenarios): "
                        "its header is kept, and the addition is noted in it")
    p.add_argument("--replace", metavar="REGEX",
                   help="with --add: drop the results of the scenarios REGEX matches from the run and measure them again")
    p.add_argument("--dry-run", action="store_true", help="only show what would run")
    p.set_defaults(func=cmd_run)

    p = sub.add_parser("compare", help="what changed between two runs")
    p.add_argument("a", help="the run to compare from (a JSON file of runs/)")
    p.add_argument("b", help="the run to compare to")
    p.add_argument("--a-mode", choices=("parsed", "lazy"),
                   help="only the results of A that were made with files forced to be parsed (or kept on disk)")
    p.add_argument("--b-mode", choices=("parsed", "lazy"), help="the same for B (to compare the two ways in one run)")
    p.add_argument("--md", help="write the report to this file (default: print it)")
    p.add_argument("--json", help="also write the comparison as JSON to this file")
    p.add_argument("--tolerance", type=float, default=0.10,
                   help="a change smaller than this fraction is not a change (default 0.10)")
    p.add_argument("--noise", type=float, default=3.0,
                   help="nor is one smaller than this many times how much a scenario's runs differ (default 3)")
    p.add_argument("--fail-on", default="", metavar="LIST",
                   help="exit 1 if there is any of these: slower, heavier, failing, differs")
    p.set_defaults(func=cmd_compare)

    p = sub.add_parser("selftest", help="run the tooling's unit tests and the harness's")
    add_rev(p)
    p.set_defaults(func=cmd_selftest)

    p = sub.add_parser("catalogue", help="write catalogue.json: the scenarios, datasets and profiles as data")
    add_rev(p)
    p.set_defaults(func=cmd_catalogue)

    p = sub.add_parser("check-plan", help="see that PLAN.md, catalogue.json and the scenarios agree")
    add_rev(p)
    p.set_defaults(func=cmd_check_plan)

    args = parser.parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    main()
