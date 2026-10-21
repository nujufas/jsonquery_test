"""What the workspace cases start with: the files that are in the workspace before the app starts.

A variables file (`Variables ../../resources/workspace_fixture.py`): every name in capitals is a
variable of the suites that read it. The workspace is an ordinary folder, and the fixture is the
files of it, by their path with `/`, and what each holds.

`STANDARD` is what most cases use: two folders, one with a folder in it (shut when the list is drawn:
only the folders at the top start open), a query with a sample, a JMESPath query, a schema with a sample,
a patch, and a query by itself. Drawn with the pane open, the list is (row 0 at the top):

    0  Logs                        (open)
    1    Errors                    (shut: failures is inside)
    2    logins                    JM
    3  Services                    (open)
    4    orders                    schema, with a sample
    5    update                    patch
    6  scratch                     jq

so a case clicks a row by its number (`${ROW_...}` in resources/workspace.resource).
"""

STANDARD = {
    "Logs/Errors/failures.jq": "map(select(.duration > 500))",
    "Logs/Errors/failures.sample.json": '[{"duration": 900}, {"duration": 10}]',
    "Logs/logins.jmespath": "[?ok]",
    "Services/orders.schema.json": '{"type": "object", "required": ["id"]}',
    "Services/orders.sample.json": "{}",
    "Services/update.patch.json": '[{"op": "add", "path": "/x", "value": 1}]',
    "scratch.jq": ".",
}

# The same, as the texts the cases compare with.
SCRATCH_TEXT = "."
FAILURES_TEXT = "map(select(.duration > 500))"
FAILURES_SAMPLE = '[{"duration": 900}, {"duration": 10}]'
LOGINS_TEXT = "[?ok]"
SCHEMA_TEXT = '{"type": "object", "required": ["id"]}'
PATCH_TEXT = '[{"op": "add", "path": "/x", "value": 1}]'

# The settings that show the pane, and that fold it to its strip.
PANE_OPEN = '{"workspace": {"pane": "open"}}'
PANE_FOLDED = '{"workspace": {"pane": "collapsed"}}'

# No files at all: a workspace that has nothing in it yet.
NO_FILES = {}

# `STANDARD` and what the workspace ignores or shows as a document: a JSON file and an NDJSON file are
# documents, a text file and anything whose name starts with a dot (a file, or a folder and what is in it)
# are not items.
MIXED = dict(
    STANDARD,
    **{
        "data.json": '{"a": 1}',
        "events.ndjson": '{"a": 1}\n{"a": 2}\n',
        "notes.txt": "not an item",
        ".hidden.jq": ".",
        "Services/.secret/inside.jq": ".",
        "readme.md": "# not an item",
    },
)

# A workspace with more rows than the list has room for: sixty queries at the top.
MANY = dict(STANDARD, **{f"item{n:02d}.jq": "." for n in range(60)})

# `STANDARD` with a JSONPath and a JSON Pointer query, one of each language the workspace tells by the end of the name.
ENGINES = dict(STANDARD, **{"paths.jsonpath": "$.a", "ptr.jsonptr": "/a"})

# `STANDARD` with a second query at the top, for a name that is taken.
WITH_OTHER = dict(STANDARD, **{"other.jq": ".other"})

# A document in the workspace: a JSON file that can be opened as the Source.
WITH_DOCUMENT = dict(STANDARD, **{"people.json": '[{"name": "Ana"}, {"name": "Bo"}]'})

# The files of `STANDARD` as the folder lists them (sorted, samples included).
STANDARD_FILES = sorted(STANDARD)

# `STANDARD` with a query at the top of Logs that has the name of the one at the top of the workspace: moving
# `scratch` into Logs would put two of the same name in one folder.
TAKEN = dict(STANDARD, **{"Logs/scratch.jq": ".other"})

# `STANDARD` with a folder of the same name as Errors in Services.
TAKEN_FOLDER = dict(STANDARD, **{"Services/Errors/x.jq": "."})

# A folder to import: a folder with a query and its sample in it, a schema, and a file the workspace does not use.
INCOMING = {
    "Reports/daily.jq": ".daily",
    "Reports/daily.sample.json": '{"d": 1}',
    "checks.schema.json": '{"type": "object"}',
    "notes.txt": "not an item",
}

# The same, as a workspace that was exported (it has its index, with the ids the items were given).
import hashlib
import json as _json

DAILY_ID = "11111111-1111-4111-8111-111111111111"
CHECKS_ID = "22222222-2222-4222-8222-222222222222"


def _sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


INCOMING_WITH_IDS = dict(
    INCOMING,
    **{
        ".jsonquery/index.json": _json.dumps(
            {
                "format": "jsonquery-workspace",
                "version": 1,
                "items": {
                    "Reports/daily.jq": {
                        "id": DAILY_ID,
                        "sha256": _sha(".daily"),
                        "bytes": 6,
                        "modified": 1,
                        "sample": {"sha256": _sha('{"d": 1}'), "bytes": 8, "modified": 1},
                    },
                    "checks.schema.json": {
                        "id": CHECKS_ID,
                        "sha256": _sha('{"type": "object"}'),
                        "bytes": 18,
                        "modified": 1,
                    },
                },
            }
        )
    },
)

# Nothing in it that the workspace can use.
NOTHING_USEFUL = {"notes.txt": "not an item", "readme.md": "# nothing"}

# A folder that has a query of the name of one of the workspace's, with other text in it.
CLASHING = {"scratch.jq": ".different", "orders.schema.json": '{"type": "string"}'}

# `STANDARD` with a second item of the name of the schema, a patch, which shares its sample.
SHARED_SAMPLE = dict(STANDARD, **{"Services/orders.patch.json": '[{"op": "remove", "path": "/x"}]'})

# `STANDARD` with two items that hold the same text.
TWINS = dict(STANDARD, **{"twin one.jq": ".twin", "twin two.jq": ".twin"})
