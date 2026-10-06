#!/usr/bin/env python3
"""List the test cases of Robot files as Markdown table rows, for the documents in docs/.

    scripts/robot_cases.py FILE.robot...                    | ID | Title | Priority |
    scripts/robot_cases.py --matrix SUITEPATH FILE.robot... | ID | Title | Priority | Status | Suite |

The first form is the case table of a feature document (docs/NN_<area>.md); the second the rows for
docs/99_traceability_matrix.md, every case marked **Passing** (edit the ones that are not) and
SUITEPATH, the suite's directory, in the last column. Only cases that have a `[Tags]` line with a
priority (p1, p2 or p3) are listed. Needs nothing but Python: it reads the files as text.
"""
import re
import sys


def main(argv):
    args = list(argv)
    matrix_suite = None
    if args and args[0] == "--matrix":
        args.pop(0)
        if not args:
            sys.exit(__doc__)
        matrix_suite = args.pop(0)
    if not args or args[0] in ("-h", "--help"):
        sys.exit(__doc__)
    for path in args:
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
        if "*** Test Cases ***" not in text:
            continue
        body = text.split("*** Test Cases ***", 1)[1]
        case = None
        for line in body.splitlines():
            named = re.match(r"^(TC-[A-Z]+-\d+[a-z]?)\s+(.*)$", line)
            if named:
                case = [named.group(1), named.group(2).strip(), None]
                continue
            tagged = re.match(r"^\s+\[Tags\]\s+(\w+)", line)
            if tagged and case and case[2] is None:
                case[2] = tagged.group(1).upper()
                row = f"| {case[0]} | {case[1]} | {case[2]} |"
                if matrix_suite is not None:
                    row += f" **Passing** | `{matrix_suite}` |"
                print(row)


if __name__ == "__main__":
    main(sys.argv[1:])
