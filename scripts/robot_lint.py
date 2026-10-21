#!/usr/bin/env python3
"""Looks for damage that a slice of a Robot file can leave: a section header twice, a case id twice (in a suite or across
the suites of a folder), a keyword defined twice in one file or in a file and the resources it imports, a keyword whose
name line has arguments in it. Prints what it finds; prints nothing else.

    scripts/robot_lint.py DIR_OF_SUITES [RESOURCE...]
"""
import collections
import os
import re
import sys

suite_dir, resources = sys.argv[1], sys.argv[2:]
files = sorted(os.path.join(suite_dir, f) for f in os.listdir(suite_dir) if f.endswith(".robot")) + resources
ids = collections.defaultdict(list)
defined = {}
for path in files:
    section = None
    headers = collections.Counter()
    names = collections.Counter()
    for number, line in enumerate(open(path, encoding="utf-8"), 1):
        line = line.rstrip("\n")
        m = re.match(r"^\*+\s*(.*?)\s*\**\s*$", line)
        if m:
            section = m.group(1).lower()
            headers[section] += 1
            continue
        if section in ("test cases", "test case") and re.match(r"^TC-", line):
            ids[line.split()[0]].append(f"{os.path.basename(path)}:{number}")
        if section in ("keywords", "keyword") and line and not line[0].isspace() and not line.startswith("#"):
            if re.search(r"\s{2,}", line.strip()):
                print(f"{path}:{number}: a keyword name with more than one cell: {line[:80]!r}")
            names[line.strip()] += 1
            defined.setdefault(line.strip().lower(), []).append(f"{os.path.basename(path)}:{number}")
    for header, count in headers.items():
        if count > 1:
            print(f"{path}: section {header!r} appears {count} times")
    for name, count in names.items():
        if count > 1:
            print(f"{path}: keyword {name!r} defined {count} times")
for ident, places in ids.items():
    if len(places) > 1:
        print(f"case {ident} is at {', '.join(places)}")
for name, places in defined.items():
    if len(places) > 1 and len({p.split(":")[0] for p in places}) > 1:
        print(f"keyword {name!r} is in several files: {', '.join(places)}")
