"""Where things are."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Optional

#: test/performance
PERF_DIR = Path(__file__).resolve().parent.parent
#: The test repository.
TEST_DIR = PERF_DIR.parent
BENCH_DIR = PERF_DIR / "bench"
RUNS_DIR = PERF_DIR / "runs"
REPORTS_DIR = PERF_DIR / "reports"


def work_dir() -> Path:
    """Where exports of the app, the build and the datasets live: big, not part of the repository,
    and on a disk (not a RAM-backed /tmp, which would take memory from the measurements). Set
    `JQ_PERF_WORK` to put it elsewhere."""
    env = os.environ.get("JQ_PERF_WORK")
    if env:
        return Path(env).expanduser().resolve()
    cache = os.environ.get("XDG_CACHE_HOME") or str(Path.home() / ".cache")
    return Path(cache) / "jsonquery-perf"


def find_app(explicit: Optional[str] = None) -> Path:
    """The checkout of the app: the argument, `$JQ_APP_DIR`, or the one beside this repository
    (`../jsonquery_gui`, where `git clone` puts it, or `../jsonquery`), as `run.sh` finds it."""
    candidates = []
    if explicit:
        candidates.append(Path(explicit))
    if os.environ.get("JQ_APP_DIR"):
        candidates.append(Path(os.environ["JQ_APP_DIR"]))
    candidates += [TEST_DIR.parent / "jsonquery_gui", TEST_DIR.parent / "jsonquery"]
    for candidate in candidates:
        candidate = candidate.expanduser()
        if (candidate / "crates" / "core" / "Cargo.toml").is_file():
            return candidate.resolve()
    raise SystemExit(
        "perf.py: the app's checkout was not found. Give it with --app or $JQ_APP_DIR "
        "(it has crates/core/Cargo.toml), or clone jsonquery_gui beside this repository."
    )
