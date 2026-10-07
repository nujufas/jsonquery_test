"""The plan as data: the scenarios the harness has, the datasets and the profiles, written to
`catalogue.json` so that what is measured can be read (and diffed) without building anything."""

from __future__ import annotations

import json
from typing import Dict, List

from . import SCHEMA, datasets
from .paths import PERF_DIR

PATH = PERF_DIR / "catalogue.json"


def build(scenarios: List[Dict[str, object]], harness_version: object) -> Dict[str, object]:
    return {
        "schema": SCHEMA,
        "kind": "catalogue",
        "harness_version": harness_version,
        "generator_version": datasets.GENERATOR_VERSION,
        "scenarios": sorted(scenarios, key=lambda s: str(s["id"])),
        "datasets": [
            {"id": s.id, "kind": s.kind, "target_bytes": s.target_bytes, "parsed_factor": s.parsed_factor,
             "description": s.description}
            for s in datasets.SPECS.values()
        ],
        "profiles": {name: [list(entry) for entry in entries] for name, entries in datasets.PROFILES.items()},
    }


def render(doc: Dict[str, object]) -> str:
    return json.dumps(doc, indent=1, ensure_ascii=False) + "\n"


def problems(scenarios: List[Dict[str, object]], harness_version: object) -> List[str]:
    """What is wrong with the file in the repository: it is not there, or it is not what the harness says."""
    expected = render(build(scenarios, harness_version))
    try:
        actual = PATH.read_text()
    except OSError:
        return [f"{PATH.name} is missing: `perf.py catalogue` writes it"]
    if actual != expected:
        return [f"{PATH.name} is not what the harness and the datasets say: `perf.py catalogue` writes it again"]
    return []
