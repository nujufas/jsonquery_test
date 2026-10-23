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



# ---- web addresses: a `.url` file is a Windows "Internet Shortcut" ----------------------------------------------

def _shortcut(address, eol="\r\n"):
    """The file that holds a web address: what the app writes (CR LF, no byte-order mark) and what Windows writes."""
    return f"[InternetShortcut]{eol}URL={address}{eol}"


RATES_ADDRESS = "https://example.com/data/rates.json"
WEATHER_ADDRESS = "http://example.org/weather.json"
ORDERS_ADDRESS = "https://example.com/v1/orders.json"

# `STANDARD` with a folder that has a web address in it, a document, and a web address at the top. Drawn with the pane
# open, the list is (row 0 at the top):
#
#     0  Logs ... 5 update            as in STANDARD
#     6  Sources                      (open)
#     7    rates                      url
#     8  data                         json
#     9  scratch                      jq
#    10  weather                      url
WITH_URLS = dict(
    STANDARD,
    **{
        "Sources/rates.url": _shortcut(RATES_ADDRESS),
        "data.json": '{"a": 1}',
        "weather.url": _shortcut(WEATHER_ADDRESS),
    },
)
ROW_SOURCES = 6
ROW_RATES = 7
ROW_DATA = 8
ROW_SCRATCH_WITH_URLS = 9
ROW_WEATHER = 10

# A web address with a sample file beside it that is nobody's (no query, schema or patch of that name): the address has no
# sample, whatever file is called after it. Rows: 0 Feeds, 1 orders (url), 2 scratch.
URL_BESIDE_SAMPLE = {
    "Feeds/orders.url": _shortcut(ORDERS_ADDRESS),
    "Feeds/orders.sample.json": '[{"id": 1}, {"id": 2}]',
    "scratch.jq": ".",
}

# A query and a web address of one name, in one folder, with the sample that the query has, and a folder to move into.
# Rows: 0 Archive (open), 1 notes, 2 Data (open), 3 orders (the query, jq), 4 orders (the web address).
URL_AND_QUERY = {
    "Archive/notes.jq": ".",
    "Data/orders.jq": ".[0]",
    "Data/orders.sample.json": '[{"id": 1}, {"id": 2}]',
    "Data/orders.url": _shortcut(ORDERS_ADDRESS),
}

# The same, with another sample file in the folder to move into, which is nobody's.
URL_AND_QUERY_WITH_OTHER_SAMPLE = dict(URL_AND_QUERY, **{"Archive/orders.sample.json": "[]"})

# The ways a `.url` file is written by the programs that write one, and the address that is read from each (the first `URL`
# line, whatever the case of its key and the section it is in, with white space round it; a file that is one line and no
# more is that address; a byte-order mark (in front of the section or of a bare address) and either line end are in no
# one's way; the scheme is kept as it was written).
# The names begin with a letter each so that the list has them in this order.
SHAPES = {
    "a bare.url": ("https://example.com/bare.json\n", "https://example.com/bare.json"),
    "b bom.url": ("\ufeff[InternetShortcut]\r\nURL=https://example.com/bom.json\r\n", "https://example.com/bom.json"),
    "c crlf.url": (_shortcut("https://example.com/crlf.json"), "https://example.com/crlf.json"),
    "d extras.url": (
        "[InternetShortcut]\r\nIconIndex=0\r\nURL=https://example.com/extras.json\r\nHotKey=0\r\n"
        "[{000214A0-0000-0000-C000-000000000046}]\r\nProp3=19,2\r\n",
        "https://example.com/extras.json",
    ),
    "e first.url": (
        "[InternetShortcut]\r\nURL=https://example.com/first.json\r\nURL=https://example.com/second.json\r\n",
        "https://example.com/first.json",
    ),
    "f lf.url": (_shortcut("https://example.com/lf.json", "\n"), "https://example.com/lf.json"),
    "g lower.url": ("[InternetShortcut]\r\nurl=https://example.com/lower.json\r\n", "https://example.com/lower.json"),
    "h other section.url": ("[Bookmark]\r\nURL=https://example.com/section.json\r\n", "https://example.com/section.json"),
    "i spaces.url": ("[InternetShortcut]\r\nURL = https://example.com/spaces.json  \r\n", "https://example.com/spaces.json"),
    "j upper.URL": ("[InternetShortcut]\r\nURL=HTTPS://Example.com/Upper.json\r\n", "HTTPS://Example.com/Upper.json"),
    "k bom bare.url": ("\ufeffhttps://example.com/bombare.json\r\n", "https://example.com/bombare.json"),
}
SHAPE_FILES = {name: text for name, (text, _) in SHAPES.items()}

# `.url` files that hold no web address: nothing at all, words, a scheme that is not http or https, no scheme, a space in it, no
# host, a section with no `URL` line in it, and one that is one character too long (4097: an address has 4096 at the most).
_LONG = "https://example.com/" + "a" * (4097 - len("https://example.com/"))
_EDGE = "https://example.com/" + "a" * (4096 - len("https://example.com/"))
NO_ADDRESS = {
    "a empty.url": "",
    "b words.url": "not an address\r\nat all\r\n",
    "c ftp.url": _shortcut("ftp://example.com/a.json"),
    "d no scheme.url": _shortcut("example.com/a.json"),
    "e spaced.url": _shortcut("https://exa mple.com/a b.json"),
    "f no host.url": _shortcut("https:///x"),
    "g no key.url": "[InternetShortcut]\r\nIconIndex=0\r\n",
    "h too long.url": _shortcut(_LONG),
}
# The address of 4096 characters, which is one, and the one of 4097, which is not; and a folder that has a file of each.
EDGE_ADDRESS = _EDGE
OVER_ADDRESS = _LONG
EDGE_FILES = {"a edge.url": _shortcut(_EDGE), "b over.url": _shortcut(_LONG)}

# A folder to import that has web addresses in it: two in a folder, with a sample file that is nobody's, and a query.
INCOMING_URLS = {
    "Feeds/rates.url": _shortcut(RATES_ADDRESS),
    "Feeds/weather.url": _shortcut(WEATHER_ADDRESS),
    "Feeds/rates.sample.json": "[1]",
    "checks.jq": ".checks",
}

# What a server serves for the cases that load an address.
SERVED = {
    "valid.json": '[\n  {"name": "Alice", "age": 34},\n  {"name": "Bob", "age": 19},\n  {"name": "Carol", "age": 45}\n]\n',
    "v1/orders.json": '{"orders": [{"id": 1}, {"id": 2}]}',
    "other.json": '{"alpha": 1, "beta": 2}',
    "invalid.txt": "this is not json",
}
