"""PLAN.md says what is measured; the harness is what measures it. This keeps them from drifting
apart: every scenario of the harness is named in the plan, and every scenario the plan names is
there."""

from __future__ import annotations

import re
from typing import Dict, List, Set

from .paths import PERF_DIR

PLAN = PERF_DIR / "PLAN.md"


def mentioned(text: str, prefixes: Set[str]) -> Set[str]:
    """The scenario ids written in backticks in `text`."""
    found: Set[str] = set()
    for token in re.findall(r"`([a-z0-9_.*]+)`", text):
        if "*" in token or "." not in token:
            continue
        if token.split(".")[0] in prefixes:
            found.add(token)
    return found


def check(catalogue: List[Dict[str, object]]) -> List[str]:
    ids = {str(s["id"]) for s in catalogue}
    prefixes = {i.split(".")[0] for i in ids}
    text = PLAN.read_text()
    named = mentioned(text, prefixes)
    problems = []
    for missing in sorted(ids - named):
        problems.append(f"PLAN.md does not mention the scenario `{missing}`")
    for unknown in sorted(named - ids):
        problems.append(f"PLAN.md mentions `{unknown}`, which the harness does not have")
    return problems
