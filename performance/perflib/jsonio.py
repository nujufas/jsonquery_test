"""How the JSON files of this suite are written: the header indented, so that it can be read, and a long
list (the results of a run, the rows of a comparison) one item to a line, so that a file is small and a
change to it is a change to a line."""

from __future__ import annotations

import json
from typing import Any, Dict


def dumps(doc: Dict[str, Any], list_key: str) -> str:
    """`doc` as JSON, with the list at `list_key` (which is written last) one item to a line."""
    items = doc.get(list_key, [])
    head = {k: v for k, v in doc.items() if k != list_key}
    text = json.dumps(head, indent=1, ensure_ascii=False)
    lines = ",\n".join("  " + json.dumps(item, separators=(",", ":"), ensure_ascii=False) for item in items)
    body = f',\n "{list_key}": [\n{lines}\n ]' if items else f',\n "{list_key}": []'
    return text[:-2] + body + "\n}\n" if text.endswith("\n}") else text[:-1] + body + "\n}\n"
