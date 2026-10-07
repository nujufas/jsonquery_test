"""The files the scenarios run on: made here, the same every time, kept out of the repository.

Each dataset is a JSON file and a sidecar `<id>.meta.json` that says what is in it (how many
records, which text is in the middle of it and which is nowhere) so that a scenario can ask for
something that is there, or is not, however big the file is. The sidecar also holds the file's
SHA-256, which goes into every result: two runs are only comparable on the same bytes.

The shapes (`kind`):

records  one list of flat records, about 135 bytes each: the usual big file
ndjson   the same records, one to a line, with no list around them (the app wraps them in one)
wide     one object with millions of members: a key is looked up by a walk where it is kept on disk
strings  a list of long strings (190,000 characters), some with escapes
numbers  a list of numbers, ints and floats
nested   a catalog: categories, their products, the products' variants (seven levels deep)
tiny     a document of a few dozen bytes
"""

from __future__ import annotations

import hashlib
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Dict, List, Optional

#: Changes whenever a generator would make other bytes (every dataset is made again).
GENERATOR_VERSION = "1"

MIB = 1024 * 1024


@dataclass(frozen=True)
class Spec:
    id: str
    kind: str
    #: How big the file is to be, in bytes (it ends at the first record boundary after).
    target_bytes: int
    #: About how many times its size a parsed document takes in memory (the heap of opening it, as
    #: measured on the app before the documents were kept on disk: 22 for these records, which have
    #: nested objects, against the 12 to 17 of flatter ones): used to tell what a machine can hold.
    parsed_factor: float
    description: str


def _spec(id: str, kind: str, mib: float, factor: float, description: str) -> Spec:
    return Spec(id, kind, int(mib * MIB), factor, description)


#: Every dataset. The name says the shape and the size.
SPECS: Dict[str, Spec] = {
    s.id: s
    for s in [
        _spec("tiny", "tiny", 0, 1, "a document of a few dozen bytes"),
        _spec("rec-1m", "records", 1, 22, "1 MiB of records"),
        _spec("nd-1m", "ndjson", 1, 22, "1 MiB of records, one to a line"),
        _spec("obj-1m", "wide", 1, 14, "one object, 1 MiB of members"),
        _spec("str-2m", "strings", 2, 1.2, "a list of long strings, 2 MiB"),
        _spec("num-1m", "numbers", 1, 15, "1 MiB of numbers"),
        _spec("tree-1m", "nested", 1, 15.5, "a catalog, 1 MiB"),
        _spec("rec-2m", "records", 2, 22, "2 MiB of records"),
        _spec("rec-4m", "records", 4, 22, "4 MiB of records"),
        _spec("rec-8m", "records", 8, 22, "8 MiB of records"),
        _spec("rec-16m", "records", 16, 22, "16 MiB of records"),
        _spec("nd-16m", "ndjson", 16, 22, "16 MiB of records, one to a line"),
        _spec("obj-16m", "wide", 16, 14, "one object, 16 MiB of members"),
        _spec("tree-16m", "nested", 16, 15.5, "a catalog, 16 MiB"),
        _spec("rec-100m", "records", 100, 22, "100 MiB of records: below the size from which the app keeps a file on disk"),
        _spec("tree-100m", "nested", 100, 15.5, "a catalog, 100 MiB"),
        _spec("tree-300m", "nested", 300, 15.5, "a catalog, 300 MiB: kept on disk, not parsed"),
        _spec("rec-300m", "records", 300, 22, "300 MiB of records: kept on disk, not parsed"),
        _spec("nd-300m", "ndjson", 300, 22, "300 MiB of records, one to a line"),
        _spec("obj-300m", "wide", 300, 14, "one object, 300 MiB of members"),
        _spec("str-300m", "strings", 300, 1.2, "a list of long strings, 300 MiB"),
        _spec("num-300m", "numbers", 300, 15, "300 MiB of numbers"),
        _spec("rec-1g", "records", 1024, 22, "1 GiB of records"),
    ]
}

#: What each run covers. A profile is a list of dataset ids, each with the modes it is opened in:
#: `auto` is the app's own choice (parsed below 256 MiB, kept on disk from there); `parsed` and
#: `lazy` force one way, to compare the two on the same bytes (only where a revision can).
PROFILES: Dict[str, List[tuple]] = {
    # Everything once, small: to see that every scenario works.
    "smoke": [(i, "auto") for i in ("tiny", "rec-1m", "nd-1m", "obj-1m", "str-2m", "num-1m", "tree-1m")],
    # Small and medium files, which both revisions parse.
    "quick": [(i, "auto") for i in ("tiny", "rec-1m", "nd-1m", "obj-1m", "str-2m", "num-1m", "tree-1m",
                                      "rec-16m", "nd-16m", "obj-16m", "tree-16m")],
    # The comparison: small to 100 MiB (parsed by both) and 300 MiB (kept on disk by the new one).
    "standard": [(i, "auto") for i in ("tiny", "rec-1m", "nd-1m", "obj-1m", "str-2m", "num-1m", "tree-1m",
                                         "rec-16m", "nd-16m", "obj-16m", "tree-16m",
                                         "rec-100m", "tree-100m",
                                         "rec-300m", "nd-300m", "obj-300m", "str-300m", "num-300m", "tree-300m")],
    # Standard, and a gigabyte of records.
    "full": [(i, "auto") for i in ("tiny", "rec-1m", "nd-1m", "obj-1m", "str-2m", "num-1m", "tree-1m",
                                     "rec-16m", "nd-16m", "obj-16m", "tree-16m",
                                     "rec-100m", "tree-100m",
                                     "rec-300m", "nd-300m", "obj-300m", "str-300m", "num-300m", "tree-300m",
                                     "rec-1g")],
    # Where is the right size to keep a file on disk? The same files, parsed and kept on disk.
    "threshold": [(i, m) for i in ("rec-1m", "rec-16m", "rec-100m", "obj-16m", "tree-16m")
                  for m in ("parsed", "lazy")],
    # ... and between 1 and 16 MiB, where the two cross.
    "crossover": [(i, m) for i in ("rec-1m", "rec-2m", "rec-4m", "rec-8m", "rec-16m")
                  for m in ("parsed", "lazy")],
}


# ---- the generators -------------------------------------------------------------------------


class _Writer:
    """A file written in pieces, hashed as it goes."""

    def __init__(self, path: Path):
        self.path = path
        self.file = open(path, "wb", buffering=4 * MIB)
        self.sha = hashlib.sha256()
        self.size = 0

    def write(self, text: str) -> None:
        data = text.encode("utf-8")
        self.file.write(data)
        self.sha.update(data)
        self.size += len(data)

    def close(self) -> None:
        self.file.flush()
        # So that the page cache can be told to forget the file (only clean pages are forgotten).
        os.fsync(self.file.fileno())
        self.file.close()


def record_text(i: int) -> str:
    """Record number `i`: the same text on any machine."""
    score = (i * 7919) % 100000
    lat = ((i * 13) % 18000 - 9000) / 100
    lon = ((i * 17) % 36000 - 18000) / 100
    return (
        '{"id":%d,"name":"user-%d","k":"cat-%03d","score":%d.%02d,"qty":%d,"active":%s,'
        '"tags":["t%d","t%d"],"geo":{"lat":%.2f,"lon":%.2f}}'
        % (i, i, i % 200, score // 100, score % 100, (i * 31) % 100,
           "true" if i % 3 else "false", i % 7, i % 11, lat, lon)
    )


def _records(out: _Writer, target: int, wrap: bool) -> dict:
    """`wrap`: a list (`[a,b,c]`); otherwise one to a line."""
    sep = "," if wrap else "\n"
    if wrap:
        out.write("[")
    count = 0
    chunk = 1000
    while out.size < target or count % chunk:
        text = sep.join(record_text(i) for i in range(count, count + chunk))
        out.write((sep if count else "") + text)
        count += chunk
    out.write("]" if wrap else "\n")
    mid = count // 2
    return {
        "count": count,
        "mid": mid,
        "last": count - 1,
        "mid_name": "user-%d" % mid,
        "absent": "zzz-absent-zzz",
        "fields": ["id", "name", "k", "score", "qty", "active", "tags", "geo"],
    }


def _gen_records(out: _Writer, target: int) -> dict:
    return _records(out, target, wrap=True)


def _gen_ndjson(out: _Writer, target: int) -> dict:
    return _records(out, target, wrap=False)


def _gen_wide(out: _Writer, target: int) -> dict:
    out.write("{")
    n = 0
    chunk = 1000
    while out.size < target or n % chunk:
        text = ",".join(
            '"key_%09d":{"v":%d,"s":"value %d"}' % (i, i, i) for i in range(n, n + chunk)
        )
        out.write(("," if n else "") + text)
        n += chunk
    out.write("}")
    return {
        "members": n,
        "mid_key": "key_%09d" % (n // 2),
        "first_key": "key_%09d" % 0,
        "last_key": "key_%09d" % (n - 1),
        "absent": "zzz-absent-zzz",
    }


def _gen_strings(out: _Writer, target: int) -> dict:
    body_len = 190000
    plain = ("The quick brown fox jumps over the lazy dog, again and again. " * 20)[:1000]
    escaped = (plain[:300] + r'\n\"quoted\" éè tab\t' + plain[300:])[:1020]
    per = body_len + 20
    count = max(3, -(-target // per))
    needle_index = count // 2
    needle = "needle-7f3a91c2"
    out.write("[")
    for i in range(count):
        base = escaped if i % 10 == 0 else plain
        shift = i % 7
        chunk = base[shift:] + base[:shift]
        body = chunk * (body_len // len(chunk) + 1)
        body = body[:body_len]
        if i == needle_index:
            half = len(body) // 2
            body = body[:half] + needle + body[half:]
        out.write(("," if i else "") + '"item-%05d-%s"' % (i, body))
    out.write("]")
    return {
        "count": count,
        "needle": needle,
        "needle_index": needle_index,
        "absent": "zzz-absent-zzz",
        "body_len": body_len,
    }


def _number(i: int) -> str:
    if i % 101 == 0:
        return "1.5e10"
    if i % 5 == 0:
        return "%.3f" % ((i % 997) / 7)
    value = (i * 7919) % 1000003
    return str(-value if i % 11 == 0 else value)


def _gen_numbers(out: _Writer, target: int) -> dict:
    out.write("[")
    n = 0
    chunk = 5000
    while out.size < target or n % chunk:
        text = ",".join(_number(i) for i in range(n, n + chunk))
        out.write(("," if n else "") + text)
        n += chunk
    out.write("]")
    return {"count": n, "mid": n // 2, "absent": "zzz-absent-zzz"}


_COLORS = ["red", "green", "blue", "black", "white"]
_SIZES = ["XS", "S", "M", "L", "XL"]


def _product(c: int, p: int) -> str:
    price = (c * 131 + p * 17) % 10000
    n = c * 10000 + p
    return (
        '{"sku":"SKU-%d-%d","title":"Product %d of category %d","price":%d.%02d,"stock":%d,'
        '"tags":["new","sale"],"attrs":{"color":"%s","size":"%s","weight":%d.%d},'
        '"variants":[{"id":%d,"size":"S","stock":%d},{"id":%d,"size":"M","stock":%d},'
        '{"id":%d,"size":"L","stock":%d}]}'
        % (c, p, p, c, price // 100, price % 100, (n * 7) % 500,
           _COLORS[n % 5], _SIZES[(n // 5) % 5], n % 20, n % 10,
           n * 3, n % 50, n * 3 + 1, (n * 5) % 50, n * 3 + 2, (n * 11) % 50)
    )


def _gen_nested(out: _Writer, target: int) -> dict:
    per_category = 1000
    out.write('{"catalog":{"name":"Test catalog","generated":"2026-10-06","categories":[')
    c = 0
    while out.size < target or c < 4:
        products = ",".join(_product(c, p) for p in range(per_category))
        out.write(("," if c else "") + '{"id":%d,"name":"Category %d","products":[%s]}' % (c, c, products))
        c += 1
    out.write("]}}")
    return {
        "categories": c,
        "products_per_category": per_category,
        "sku_mid": "SKU-%d-%d" % (c // 2, per_category // 2),
        "absent": "zzz-absent-zzz",
    }


def _gen_tiny(out: _Writer, target: int) -> dict:
    out.write('{"id":1,"name":"tiny","tags":["a","b"],"geo":{"lat":1.5,"lon":-2.5}}')
    return {"absent": "zzz-absent-zzz"}


GENERATORS: Dict[str, Callable[[_Writer, int], dict]] = {
    "records": _gen_records,
    "ndjson": _gen_ndjson,
    "wide": _gen_wide,
    "strings": _gen_strings,
    "numbers": _gen_numbers,
    "nested": _gen_nested,
    "tiny": _gen_tiny,
}


# ---- making them ----------------------------------------------------------------------------


def paths(data_dir: Path, dataset_id: str) -> tuple:
    return data_dir / f"{dataset_id}.json", data_dir / f"{dataset_id}.meta.json"


def read_meta(data_dir: Path, dataset_id: str) -> Optional[dict]:
    _, meta_path = paths(data_dir, dataset_id)
    try:
        return json.loads(meta_path.read_text())
    except (OSError, ValueError):
        return None


def is_current(data_dir: Path, spec: Spec) -> bool:
    """Whether the dataset on disk is the one this version of the generator makes."""
    file, _ = paths(data_dir, spec.id)
    meta = read_meta(data_dir, spec.id)
    if not meta or not file.exists():
        return False
    return (
        meta.get("generator") == GENERATOR_VERSION
        and meta.get("target_bytes") == spec.target_bytes
        and meta.get("bytes") == file.stat().st_size
    )


def ensure(data_dir: Path, spec: Spec, log: Callable[[str], None] = lambda text: None) -> dict:
    """The dataset's metadata, making the file first if it is not there (or is not this one)."""
    data_dir.mkdir(parents=True, exist_ok=True)
    if is_current(data_dir, spec):
        meta = read_meta(data_dir, spec.id)
        assert meta is not None
        # What the generator does not make from the bytes (an estimate, a description) is kept up to date
        # without making the file again.
        refreshed = {**meta, "parsed_factor": spec.parsed_factor, "description": spec.description}
        if refreshed != meta:
            paths(data_dir, spec.id)[1].write_text(json.dumps(refreshed, indent=2) + "\n")
        return refreshed
    file, meta_path = paths(data_dir, spec.id)
    log(f"making {spec.id} ({spec.description})")
    partial = file.with_suffix(".json.partial")
    out = _Writer(partial)
    try:
        extra = GENERATORS[spec.kind](out, spec.target_bytes)
    finally:
        out.close()
    os.replace(partial, file)
    meta = {
        "schema": 1,
        "id": spec.id,
        "kind": spec.kind,
        "description": spec.description,
        "generator": GENERATOR_VERSION,
        "target_bytes": spec.target_bytes,
        "bytes": out.size,
        "sha256": out.sha.hexdigest(),
        "parsed_factor": spec.parsed_factor,
        **extra,
    }
    meta_path.write_text(json.dumps(meta, indent=2) + "\n")
    return meta
