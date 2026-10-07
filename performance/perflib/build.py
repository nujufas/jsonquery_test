"""Building the harness against a revision of the app.

The harness is not built in this repository: its sources are copied into an export of the app at the
revision to test, as a member of that workspace (`crates/perf-bench`), and built there in release
mode. So it links the revision's own `jsonquery-core` and `jsonquery-query`, resolves its
dependencies from that revision's Cargo.lock, and is optimized as that revision's release profile
says: what it times is what that revision of the app would do.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Dict, List, Optional

from . import say
from .paths import BENCH_DIR, work_dir

#: The name of a "revision" that is the working tree as it is, uncommitted changes and all.
WORKTREE = "WORKTREE"


@dataclass
class Build:
    label: str
    rev: str
    sha: str
    short: str
    describe: str
    subject: str
    committed: str
    dirty: bool
    binary: Path
    info: Dict[str, object] = field(default_factory=dict)
    source_hash: str = ""

    def revision_json(self) -> Dict[str, object]:
        return {
            "rev": self.rev,
            "sha": self.sha,
            "short": self.short,
            "describe": self.describe,
            "subject": self.subject,
            "committed": self.committed,
            "dirty": self.dirty,
        }


def _git(app: Path, *args: str) -> str:
    out = subprocess.run(["git", "-C", str(app), *args], capture_output=True, text=True)
    if out.returncode != 0:
        raise SystemExit(f"perf.py: git {' '.join(args)} failed in {app}: {out.stderr.strip()}")
    return out.stdout.strip()


def bench_source_hash() -> str:
    """A hash of the harness's sources: a binary built from other sources is not reused."""
    digest = hashlib.sha256()
    for path in sorted(BENCH_DIR.rglob("*")):
        if path.is_file() and "target" not in path.relative_to(BENCH_DIR).parts:
            digest.update(str(path.relative_to(BENCH_DIR)).encode())
            digest.update(path.read_bytes())
    return digest.hexdigest()[:12]


def resolve(app: Path, rev: str) -> Dict[str, object]:
    """What `rev` is, as a commit (or the working tree)."""
    if rev == WORKTREE:
        head = _git(app, "rev-parse", "HEAD")
        status = _git(app, "status", "--porcelain")
        stamp = time.strftime("%Y%m%d%H%M%S")
        return {
            "sha": head,
            "short": f"wt-{head[:7]}-{stamp}",
            "describe": _git(app, "describe", "--tags", "--always", "--dirty") + "+worktree",
            "subject": "(the working tree, as it is)",
            "committed": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
            "dirty": bool(status),
        }
    sha = _git(app, "rev-parse", "--verify", f"{rev}^{{commit}}")
    return {
        "sha": sha,
        "short": sha[:7],
        "describe": _git(app, "describe", "--tags", "--always", sha),
        "subject": _git(app, "log", "-1", "--format=%s", sha),
        "committed": _git(app, "log", "-1", "--format=%cI", sha),
        "dirty": False,
    }


def _export(app: Path, rev: str, sha: str, dest: Path) -> None:
    """The app as it was at `rev` (or is, for the working tree), into `dest`."""
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)
    if rev == WORKTREE:
        listing = subprocess.run(
            ["git", "-C", str(app), "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
            capture_output=True, check=True,
        ).stdout.split(b"\0")
        for raw in listing:
            if not raw:
                continue
            rel = raw.decode()
            source = app / rel
            if not source.is_file():
                continue
            target = dest / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
        return
    archive = subprocess.Popen(["git", "-C", str(app), "archive", "--format=tar", sha], stdout=subprocess.PIPE)
    untar = subprocess.run(["tar", "-x", "-C", str(dest)], stdin=archive.stdout)
    if archive.stdout:
        archive.stdout.close()
    if archive.wait() != 0 or untar.returncode != 0:
        raise SystemExit(f"perf.py: exporting {sha} with git archive and tar failed")


def _add_harness(tree: Path) -> None:
    """Put the harness in the export as a member of its workspace."""
    target = tree / "crates" / "perf-bench"
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(BENCH_DIR, target, ignore=shutil.ignore_patterns("target", "*.lock"))
    manifest = tree / "Cargo.toml"
    text = manifest.read_text()
    if "crates/perf-bench" not in text:
        new, count = re.subn(r"members\s*=\s*\[", 'members = [\n    "crates/perf-bench",', text, count=1)
        if not count:
            raise SystemExit(f"perf.py: no `members = [` in {manifest}: the harness cannot be added to it")
        manifest.write_text(new)


def build(
    app: Path,
    rev: str,
    label: str,
    rebuild: bool = False,
    log: Callable[[str], None] = say,
) -> Build:
    work = work_dir()
    meta = resolve(app, rev)
    source_hash = bench_source_hash()
    short = str(meta["short"])
    binary = work / "bin" / f"{short}-{source_hash}" / "jq-perf"

    if rebuild or not binary.exists():
        tree = work / "src" / short
        log(f"[build] exporting {rev} ({short}) to {tree}")
        _export(app, rev, str(meta["sha"]), tree)
        _add_harness(tree)
        env = dict(os.environ)
        tmp = work / "tmp"
        tmp.mkdir(parents=True, exist_ok=True)
        # A shared target dir keeps the dependencies that revisions have in common; TMPDIR is on disk
        # because a C compiler's temporary files in a full or RAM-backed /tmp are a way for a build to fail.
        env.update(CARGO_TARGET_DIR=str(work / "target"), TMPDIR=str(tmp), CARGO_TERM_COLOR="never")
        started = time.time()
        for offline in (True, False):
            cmd = ["cargo", "build", "--release", "-p", "jq-perf-bench"] + (["--offline"] if offline else [])
            log(f"[build] {' '.join(cmd)}")
            result = subprocess.run(cmd, cwd=tree, env=env, capture_output=True, text=True)
            if result.returncode == 0:
                break
            if not offline:
                raise SystemExit(f"perf.py: the harness did not build at {rev}:\n{result.stderr[-6000:]}")
        log(f"[build] built in {time.time() - started:.0f} s")
        binary.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(work / "target" / "release" / "jq-perf", binary)

    info = json.loads(subprocess.run([str(binary), "info"], capture_output=True, text=True, check=True).stdout)
    return Build(
        label=label,
        rev=rev,
        sha=str(meta["sha"]),
        short=short,
        describe=str(meta["describe"]),
        subject=str(meta["subject"]),
        committed=str(meta["committed"]),
        dirty=bool(meta["dirty"]),
        binary=binary,
        info=info,
        source_hash=source_hash,
    )


def catalogue(b: Build) -> List[Dict[str, object]]:
    """The scenarios the harness has."""
    out = subprocess.run([str(b.binary), "list"], capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def selftest(app: Path, rev: str, log: Callable[[str], None] = say) -> int:
    """The harness's own unit tests (the statistics, the fingerprint, the measuring loop), run in an
    export of the app at `rev` where the harness can be built."""
    work = work_dir()
    meta = resolve(app, rev)
    tree = work / "src" / f"selftest-{meta['short']}"
    log(f"[selftest] exporting {rev} to {tree}")
    _export(app, rev, str(meta["sha"]), tree)
    _add_harness(tree)
    env = dict(os.environ)
    tmp = work / "tmp"
    tmp.mkdir(parents=True, exist_ok=True)
    env.update(CARGO_TARGET_DIR=str(work / "target-test"), TMPDIR=str(tmp), CARGO_TERM_COLOR="never")
    result = subprocess.run(["cargo", "test", "--offline", "-p", "jq-perf-bench"], cwd=tree, env=env)
    if result.returncode != 0:
        result = subprocess.run(["cargo", "test", "-p", "jq-perf-bench"], cwd=tree, env=env)
    return result.returncode
