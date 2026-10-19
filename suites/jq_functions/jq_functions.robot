*** Settings ***
Documentation     The jq functions jsonquery adds to its jq engine -- see
...               docs/17_jq_functions.md. The engine underneath (jaq) lacks `IN`, `INDEX`,
...               `JOIN`, `tostream`, `fromstream`, `truncate_stream`, `@csv` and `@tsv`;
...               the app defines them itself (crates/query/src/jq_ext), and these cases
...               run each through the real window: the query is pasted in, run with
...               Ctrl+Enter, and every result is read back exactly -- the Results root's
...               "Copy to Clipboard" -- and compared as JSON.
...
...               The expected values are what jq 1.8.1 prints for the same query over the
...               same document (`jq -c '[ QUERY ]'`), written out here so that the suite
...               needs no jq. A backslash is written twice in a Robot cell, so a jq
...               string's own backslash-n takes two in a query and four in an expected
...               JSON text.
Resource          ../../resources/results.resource
Force Tags        jq_functions
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Keywords ***
Give
    [Documentation]    Loads `fixture`, runs `query` (pasted) and checks every result against
    ...    the JSON array `expected`.
    [Arguments]    ${fixture}    ${query}    ${expected}
    Load Fixture    ${fixture}
    Run Query By Paste    ${query}
    Results Should Be Json    ${expected}

Give Rows
    [Documentation]    Loads `fixture`, runs `query`, which ends in @csv or @tsv, and checks the
    ...    rows it makes: the results are text, not JSON, and "Copy to Clipboard" on the
    ...    Results root gives them a row to a line (see output_formats).
    [Arguments]    ${fixture}    ${query}    ${expected}
    Load Fixture    ${fixture}
    Run Query By Paste    ${query}
    Results Should Be Text    ${expected}

Give One String Containing
    [Documentation]    The query has exactly one result, a string, and it contains `needle`
    ...    -- for an error message, whose wording is not what is under test.
    [Arguments]    ${fixture}    ${query}    ${needle}
    Load Fixture    ${fixture}
    Run Query By Paste    ${query}
    ${text}=    Copy All Results
    ${results}=    Evaluate    json.loads($text)    modules=json
    Length Should Be    ${results}    1
    Should Be True    isinstance($results[0], str)
    Should Contain    ${results}[0]    ${needle}

*** Test Cases ***
# --- IN ------------------------------------------------------------------------------------

TC-JQX-001 IN Keeps The Members Whose Value Is One Of Several
    [Documentation]    `select(.role | IN("engineer", "intern"))`: the first form, a value
    ...    checked against a list.
    [Tags]    p1
    Give    people.json    .[] | select(.role | IN("engineer", "intern")) | .name    ["Alice", "Bob"]

TC-JQX-002 IN Gives A Boolean For Each Input
    [Tags]    p1
    Give    people.json    .[] | .age | IN(19, 45)    [false, true, true]

TC-JQX-003 IN Over A Source Asks Whether Any Output Is In The Set
    [Documentation]    `IN(source; set)`: true when some output of the source is one of the
    ...    values.
    [Tags]    p1
    Give    people.json    IN(.[].role; "manager")    [true]

TC-JQX-004 IN Over A Source Is False When Nothing Matches
    [Tags]    p2
    Give    people.json    IN(.[].role; "ceo", "cto")    [false]

TC-JQX-005 Not IN Keeps What Is Not In The List
    [Tags]    p1
    Give    people.json    [.[] | select(.name | IN("Bob") | not) | .name]    [["Alice", "Carol"]]

TC-JQX-006 IN Compares Whole Values
    [Documentation]    An object is in the list when an equal object is.
    [Tags]    p2
    Give    people.json    {"a":1} | IN({"a":1}, {"b":2})    [true]

TC-JQX-007 IN An Empty Source Is False
    [Tags]    p3
    Give    people.json    IN(empty; 1)    [false]

TC-JQX-008 IN A Generated Source
    [Tags]    p3
    Give    people.json    IN(range(10); 3, 4)    [true]

TC-JQX-009 IN Does Not Equate A Number And A String
    [Tags]    p2
    Give    people.json    1 | IN("1")    [false]

TC-JQX-010 IN Finds Null
    [Tags]    p3
    Give    people.json    null | IN(null)    [true]

# --- INDEX ----------------------------------------------------------------------------------

TC-JQX-020 INDEX Keys An Array By A Field
    [Documentation]    `INDEX(.name)`: an object with one entry per element, under its name.
    [Tags]    p1
    Give    people.json    INDEX(.name) | keys    [["Alice", "Bob", "Carol"]]

TC-JQX-021 INDEX Over A Stream Makes A Lookup Table
    [Tags]    p1
    Give    people.json    INDEX(.[]; .name) | .Bob.age    [19]

TC-JQX-022 INDEX Turns Numeric Keys Into Strings
    [Documentation]    Object keys are strings, so the ages 19, 34, 45 become "19", "34", "45".
    [Tags]    p1
    Give    people.json    INDEX(.age) | keys    [["19", "34", "45"]]

TC-JQX-023 INDEX Keeps The Last Of Several With One Key
    [Tags]    p1
    Give    people.json    [{"k":"a","v":1},{"k":"a","v":2}] | INDEX(.k) | .a.v    [2]

TC-JQX-024 INDEX Of An Empty Array Is An Empty Object
    [Tags]    p2
    Give    people.json    [] | INDEX(.k)    [{}]

TC-JQX-025 INDEX Files A Missing Key Under null
    [Tags]    p3
    Give    people.json    [{"a":1}] | INDEX(.k) | keys    [["null"]]

TC-JQX-026 INDEX Then map_values Projects The Table
    [Tags]    p2
    Give    people.json    INDEX(.name) | map_values(.age)    [{"Alice": 34, "Bob": 19, "Carol": 45}]

TC-JQX-027 INDEX Of The Customers By Code
    [Documentation]    The tutorial's first INDEX example, over the shop document.
    [Tags]    p1
    Give    shop.json    .customers | INDEX(.code) | map_values(.city)
    ...    [{"ADA": "London", "LIN": "Helsinki", "GRA": "New York"}]

# --- JOIN -----------------------------------------------------------------------------------

TC-JQX-030 JOIN Pairs Each Order With Its Customer
    [Documentation]    The four-argument form: a lookup table, a stream, the key of each
    ...    element, and what to make of each pair.
    [Tags]    p1
    Give    shop.json
    ...    INDEX(.customers[]; .code) as $c | JOIN($c; .orders[]; .customer; {order: .[0].no, city: .[1].city})
    ...    [{"order": 101, "city": "London"}, {"order": 102, "city": "New York"}, {"order": 103, "city": "London"}, {"order": 104, "city": "Helsinki"}]

TC-JQX-031 JOIN Without A Join Expression Gives The Pairs
    [Tags]    p2
    Give    shop.json
    ...    INDEX(.customers[]; .code) as $c | [JOIN($c; .orders[]; .customer)] | .[0] | [.[0].no, .[1].name]
    ...    [[101, "Ada"]]

TC-JQX-032 JOIN Over An Array Makes An Array Of Pairs
    [Documentation]    `.orders | JOIN($c; .customer)`: the two-argument form, one pair per
    ...    element of the input.
    [Tags]    p2
    Give    shop.json
    ...    INDEX(.customers[]; .code) as $c | .orders | JOIN($c; .customer) | length
    ...    [4]

TC-JQX-033 JOIN Pairs An Unmatched Element With null
    [Tags]    p3
    Give    shop.json    [{"c":"X"}] | JOIN({}; .c)    [[[{"c": "X"}, null]]]

# --- tostream, fromstream, truncate_stream --------------------------------------------------

TC-JQX-040 tostream Gives A Path And A Leaf For Each Scalar And A Closing Event
    [Documentation]    `.a | tostream`: [path, leaf] for every scalar, and [path] where an
    ...    array or object ends.
    [Tags]    p1
    Give    nested.json    .a | tostream
    ...    [[["b", 0], 1], [["b", 1], 2], [["b", 1]], [["c"], "x"], [["c"]]]

TC-JQX-041 tostream Of The Whole Document Has Seven Events
    [Tags]    p2
    Give    nested.json    [tostream] | length    [7]

TC-JQX-042 tostream Of A Scalar Is One Event With An Empty Path
    [Tags]    p2
    Give    nested.json    3 | tostream    [[[], 3]]

TC-JQX-043 tostream Of Empty Containers Is Their Own Leaf
    [Tags]    p2
    Give    nested.json    ([] | tostream), ({} | tostream)    [[[], []], [[], {}]]

TC-JQX-044 The Events Make A Listing Of Every Leaf
    [Documentation]    The tutorial's listing: each path joined with dots, its value after.
    [Tags]    p1
    Give    nested.json
    ...    tostream | select(length == 2) | "\\(.[0] | map(tostring) | join(".")) = \\(.[1])"
    ...    ["a.b.0 = 1", "a.b.1 = 2", "a.c = x", "d = 3"]

TC-JQX-045 The Last Event Closes The Top Level
    [Tags]    p3
    Give    nested.json    [tostream] | last    [[["d"]]]

TC-JQX-046 fromstream Rebuilds What tostream Took Apart
    [Documentation]    The round trip over the loaded document: the same value comes back.
    [Tags]    p1
    Give    nested.json    fromstream(tostream)    [{"a": {"b": [1, 2], "c": "x"}, "d": 3}]

TC-JQX-047 fromstream Builds A Value From Hand-Written Events
    [Tags]    p1
    Give    nested.json    fromstream([["a"], 1], [["b"], 2], [["b"]])    [{"a": 1, "b": 2}]

TC-JQX-048 fromstream Of A Truncated Stream Makes The Inner Values
    [Tags]    p2
    Give    nested.json    fromstream(1|truncate_stream([[0],1],[[1,0],2],[[1,0]],[[1]]))    [[2]]

TC-JQX-049 truncate_stream Drops The First Path Level
    [Documentation]    From the jq manual: `1|truncate_stream(events)` removes one level from
    ...    every path and drops what had none.
    [Tags]    p1
    Give    nested.json    1 | truncate_stream([[0],1],[[1,0],2],[[1,0]],[[1]])    [[[0], 2], [[0]]]

TC-JQX-050 fromstream Over A Filtered Stream Drops A Field From Every Record
    [Documentation]    The tutorial's second stream example: the events about a "city" are
    ...    left out and the rest rebuilt, so every customer comes back without one.
    [Tags]    p1
    Give    shop.json
    ...    .customers | fromstream(tostream | select(length == 1 or all(.[0][]; . != "city")))
    ...    [[{"code": "ADA", "name": "Ada"}, {"code": "LIN", "name": "Linus"}, {"code": "GRA", "name": "Grace"}]]

TC-JQX-051 fromstream Of A Truncated Stream Gives One Result Per Element
    [Documentation]    `fromstream(1 | truncate_stream($o | tostream))` over an array: each
    ...    element on its own.
    [Tags]    p1
    Give    shop.json    .orders as $o | fromstream(1 | truncate_stream($o | tostream))
    ...    [{"no": 101, "customer": "ADA", "item": "keyboard", "qty": 2}, {"no": 102, "customer": "GRA", "item": "monitor", "qty": 1}, {"no": 103, "customer": "ADA", "item": "mouse", "qty": 3}, {"no": 104, "customer": "LIN", "item": "cable", "qty": 10}]

TC-JQX-052 fromstream Makes One Value Per Complete Top-Level Value
    [Tags]    p2
    Give    nested.json    fromstream(([1,2] | tostream), ({"a":3} | tostream))    [[1, 2], {"a": 3}]

TC-JQX-053 tostream Of A Large Array Is Fast Enough To Use
    [Documentation]    100,000 numbers give 100,001 events (every number, then the closing
    ...    one) -- the native tostream, which a definition in jq itself would take an
    ...    order of magnitude longer to run.
    [Tags]    p2
    Give    nested.json    [range(100000)] | [tostream] | length    [100001]

# --- @csv and @tsv, as values ---------------------------------------------------------------

TC-JQX-060 @csv Writes Numbers Bare Strings Quoted And null Empty
    [Tags]    p1
    Give Rows    people.json    [1,"a",null,true] | @csv    1,"a",,true

TC-JQX-061 @csv Doubles A Quote Inside A String
    [Tags]    p1
    Give Rows    people.json    [1.5, "x\\"y"] | @csv    1.5,"x""y"

TC-JQX-062 @csv Leaves A Comma Or A Line Break Inside The Quotes
    [Tags]    p1
    Give Rows    people.json    ["a,b", "c\\nd"] | @csv    "a,b","c\nd"

TC-JQX-063 @tsv Escapes Tab Backslash Line Break And Carriage Return
    [Documentation]    Each becomes a two-character sequence, \\t \\\\ \\n \\r, so a field
    ...    never contains the separator.
    [Tags]    p1
    Give Rows    people.json    ["a\\tb", "c\\\\d", "e\\nf", "g\\rh"] | @tsv    a\\tb\tc\\\\d\te\\nf\tg\\rh

TC-JQX-064 @tsv Writes null As Nothing And Booleans As Words
    [Tags]    p2
    Give Rows    people.json    [null, true, false, 0] | @tsv    \ttrue\tfalse\t0

TC-JQX-065 @csv And @tsv Of An Empty Array Are Empty Strings
    [Tags]    p2
    Give    people.json    ([] | @csv), ([] | @tsv)    ["", ""]

TC-JQX-066 @csv Quotes A Lone String
    [Tags]    p3
    Give Rows    people.json    ["x"] | @csv    "x"

TC-JQX-067 @csv Of An Object Is An Error That Names The Value
    [Documentation]    Caught with try ... catch, the message names the kind and the value.
    [Tags]    p1
    Give One String Containing    people.json    try ({"a":1} | @csv) catch .    cannot be csv-formatted

TC-JQX-068 @csv Of A Nested Array Is An Error
    [Tags]    p2
    Give    people.json    try ([[1]] | @csv) catch .    ["array ([1]) is not valid in a csv row"]

TC-JQX-069 @tsv Of A String Is An Error
    [Tags]    p2
    Give One String Containing    people.json    try ("x" | @tsv) catch .    cannot be tsv-formatted

# --- errors reach the status bar ------------------------------------------------------------

TC-JQX-080 An Error Raised In The Query Shows Its Text Plainly
    [Documentation]    `error("boom")` is an item error, shown as boom -- the text -- and not
    ...    as the JSON string "boom" with its quotes.
    [Tags]    p2
    Load Fixture    people.json
    Run Query By Paste    error("boom")
    Status Bar Should Say    item error
    Status Bar Should Say    boom
    Region Should Not Contain Text    @{STATUS_BAR}    "boom"

TC-JQX-081 try catch Hands Over The Error Text
    [Tags]    p2
    Give    people.json    try error("boom") catch .    ["boom"]

TC-JQX-082 An Unknown Variable Is A Query Error
    [Documentation]    What the engine does not define is still unknown ($ENV, input): a query
    ...    error, with no results.
    [Tags]    p2
    Load Fixture    people.json
    Run Query By Paste    $ENV | length
    Status Bar Should Say    error

# --- text that is not a number or JSON, and values nested very deep -------------------------

TC-JQX-090 tonumber Of Text That Is Not A Number Is One Error And The Window Answers The Next Query
    [Documentation]    `"abc" | tonumber` never finished: jaq's `fromjson` answered with an error
    ...    and, reading the same place again, with another, for ever, and the worker thread
    ...    (one thread, which every query waits on) was busy with them while the memory grew.
    ...    Now it is one error, worded as jq words it, and the next query is answered.
    [Tags]    p0
    Load Fixture    people.json
    Run Query By Paste    "abc" | tonumber
    Status Bar Should Say    item error
    Status Bar Should Say    cannot be parsed as a number
    Run Query By Paste    "12" | tonumber + 1
    Results Should Be Json    [13]

TC-JQX-091 fromjson Of Text That Is Not JSON Is One Error And The Window Answers The Next Query
    [Tags]    p0
    Load Fixture    people.json
    Run Query By Paste    "N/A" | fromjson
    Status Bar Should Say    item error
    Status Bar Should Say    while parsing
    Run Query By Paste    "[1,2]" | fromjson | add
    Results Should Be Json    [3]

TC-JQX-092 tonumber With A Question Mark Skips What Is Not A Number
    [Documentation]    The way people get round bad numbers in jq. It did not get round this one:
    ...    the stream of errors never ended, so nothing was ever skipped.
    [Tags]    p0
    Give    people.json    ["1", "x", "2"] | map(tonumber?)    [[1, 2]]

TC-JQX-093 tonumber Reads What jq Reads
    [Documentation]    Leading zeros, a plus sign, a point with nothing before or after it, an
    ...    exponent, a trailing zero kept (from jq 1.8.1).
    [Tags]    p1
    Give    people.json    ["007", "+5", ".5", "5.", "-1e2", "1.50"] | map(tonumber)    [[7, 5, 0.5, 5, -100, 1.50]]

TC-JQX-094 tonumber Refuses A Space Around A Number
    [Documentation]    jaq read the text as JSON, and took " 5". jq's does not.
    [Tags]    p2
    Give    people.json    [" 5", "5 ", "", "0x10", "1_000"] | map(try tonumber catch "no")    [["no", "no", "no", "no", "no"]]

TC-JQX-095 fromjson Reads One Value And Not Two
    [Tags]    p2
    Give    people.json    ("1 2" | try fromjson catch "no"), ("[1,2]" | fromjson | length)    ["no", 2]

TC-JQX-096 A Result Nested Very Deep Is Cut Where It Gets Too Deep And The Window Stays
    [Documentation]    5,000 arrays one in the next: the app closed at about 1,800. The result is shown
    ...    down to 127 levels, the deepest a document can be, and `<skipped: too deep>` is
    ...    what stands for the rest, as in jq.
    [Tags]    p0
    Load Fixture    people.json
    Run Query By Paste    reduce range(5000) as $i ([]; [.])
    ${text}=    Copy All Results
    Should Contain    ${text}    <skipped: too deep>
    Run Query By Paste    .[0].name
    Results Should Be Json    ["Alice"]

TC-JQX-097 tojson Stops Where jq Stops
    [Documentation]    256 arrays round a number are written in full, a deeper value is cut with
    ...    `<skipped: too deep>` (the lengths are those of jq 1.8.1).
    [Tags]    p1
    Give    people.json    (reduce range(256) as $i (1; [.]) | tojson | length), (reduce range(300) as $i ([]; [.]) | tojson | length)    [513, 533]

TC-JQX-098 A Value Nested Far Deeper Than An Ordinary Thread Can Write Is Written Without The App Closing
    [Documentation]    50,000 arrays one in the next, written as text by string interpolation, which
    ...    jaq does by recursion, a kilobyte of stack for each level: the thread that runs queries
    ...    has the room.
    [Tags]    p1
    Give    people.json    reduce range(50000) as $i ([]; [.]) | "\\(.)" | length    [100002]

# --- writes, deletes, scan, join, from_entries and @base64d, as jq has them -------------------

TC-JQX-099 Assigning Into A Key That Is Not There Makes The Objects
    [Documentation]    `.metadata.labels.env = "prod"` where `labels` is not there: the usual way to add a field. jaq failed on the `null` under
    ...    the missing key; jq makes the objects, and so does the app now.
    [Tags]    p0
    Give    people.json    {"metadata": {"name": "web"}} | .metadata.labels.env = "prod"    [{"metadata":{"name":"web","labels":{"env":"prod"}}}]
    Give    people.json    null | .a.b.c = 1    [{"a":{"b":{"c":1}}}]
    Give    people.json    {"name": "a"} | .counts[.name] += 1    [{"name":"a","counts":{"a":1}}]

TC-JQX-100 A reduce That Starts From null Builds An Object Or An Array
    [Documentation]    Counting words, and filling an array by index, from `null`: both failed before.
    [Tags]    p0
    Give    people.json    reduce ("a", "b", "a") as $w (null; .[$w] += 1)    [{"a":2,"b":1}]
    Give    people.json    reduce range(3) as $i (null; .[$i] = $i * 2)    [[0,2,4]]
    Give    people.json    reduce range(5) as $i ([]; .[$i * 2] = $i)    [[0,null,1,null,2,null,3,null,4]]

TC-JQX-101 An Index Past The End Makes The Array Longer With nulls
    [Documentation]    `[0] | .[2] = 1` is `[0,null,1]`; with nothing to put (`|= empty`) the array stays.
    [Tags]    p1
    Give    people.json    [0] | .[2] = 1    [[0,null,1]]
    Give    people.json    [1, 2, 3] | .[5] = 9    [[1,2,3,null,null,9]]
    Give    people.json    [] | .[1] = 9    [[null,9]]
    Give    people.json    [0, 1] | .[2] = 5    [[0,1,5]]
    Give    people.json    [1, 2, 3] | .[5] |= empty    [[1,2,3]]

TC-JQX-102 setpath And pick Go Through null
    [Documentation]    `setpath` makes the levels (it did not); `pick`, which jq writes with it, gives an array for the indexes of an array.
    [Tags]    p1
    Give    people.json    null | setpath(["a", "b"]; 1)    [{"a":{"b":1}}]
    Give    people.json    [0] | setpath([2]; 1)    [[0,null,1]]
    Give    people.json    [1, 2, 3] | pick(.[0])    [[1]]
    Give    people.json    {"a": {"b": 1, "c": 2}, "d": 3} | pick(.a.b)    [{"a":{"b":1}}]

TC-JQX-103 An Index Far Past The End Is An Error And The Window Answers The Next Query
    [Documentation]    An index meant as a key (a timestamp, an id) must not make an array of that many items and use up the memory:
    ...    from 16,777,216 on it is an error (jq: 536,870,912).
    [Tags]    p0
    Load Fixture    people.json
    Run Query By Paste    [] | .[1700000000] = 1
    Status Bar Should Say    item error
    Status Bar Should Say    Array index too large
    Run Query By Paste    [1, 2] | length
    Results Should Be Json    [2]

TC-JQX-104 del Takes Several Items Of An Array At Once
    [Documentation]    `del(.[1,2])` failed on the item that was no longer there; `del(.a[0], .a[1])` took the wrong item (`[2]`, jq: `[3]`).
    [Tags]    p0
    Give    people.json    [1, 2, 3] | del(.[1, 2])    [[1]]
    Give    people.json    {"a": [1, 2, 3]} | del(.a[0], .a[1])    [{"a":[3]}]
    Give    people.json    [1, 2, 3] | del(.[0, 2])    [[2]]
    Give    people.json    [1, 2, 3] | del(.[5])    [[1,2,3]]
    Give    people.json    [1, 2, 3] | del(.[-1])    [[1,2]]

TC-JQX-105 delpaths Takes All The Paths As The Value Was
    [Documentation]    The paths are not taken one after the other: `[[0],[0]]` is the first item, once, and the paths may come in any order (`[[3],[0],[2]]`).
    [Tags]    p1
    Give    people.json    [1, 2, 3] | delpaths([[0], [0]])    [[2,3]]
    Give    people.json    [1, 2, 3] | delpaths([[0], [1]])    [[3]]
    Give    people.json    [1, 2, 3, 4] | delpaths([[3], [0], [2]])    [[2]]
    Give    people.json    {"a": [1, 2, 3]} | delpaths([["a", 2], ["a", 0]])    [{"a":[2]}]
    Give    people.json    {"a": [1, 2, 3], "b": 1} | delpaths([["a", 0], ["b"], ["a", 1]])    [{"a":[3]}]
    Give    people.json    [1] | del(.)    [null]
    Give    people.json    [1] | delpaths([])    [[1]]

TC-JQX-106 del Keeps The Other Keys In Their Order
    [Documentation]    jaq took a key out by moving the last one into its place: `{a,b,c}` without `a` was `{c,b}`.
    [Tags]    p1
    Give    people.json    {"a": 1, "b": 2, "c": 3, "d": 4} | del(.a) | keys_unsorted    [["b","c","d"]]
    Give    people.json    {"a": 1, "b": 2, "c": 3, "d": 4} | del(.b, .c) | keys_unsorted    [["a","d"]]
    Give    people.json    {"a": 1, "b": 2, "c": 3} | .a |= empty | keys_unsorted    [["b","c"]]

TC-JQX-107 del Of What A Condition Selects
    [Tags]    p1
    Give    people.json    [1, 2, 3, 4, 5] | del(.[] | select(. % 2 == 0))    [[1,3,5]]
    Give    people.json    [1, 2, 3] | del(first(.[] | select(. > 1)))    [[1,3]]
    Give    people.json    [1, 2, 3] | del(limit(2; .[]))    [[3]]
    Give    people.json    {"a": 1, "b": {"c": 2, "d": 3}} | del(.b.c)    [{"a":1,"b":{"d":3}}]
    Give    people.json    {"x": 1} | del(.a.b)    [{"x":1}]

TC-JQX-108 scan Finds Every Match
    [Documentation]    `scan` found the first match only (jaq's `scan` had no `g` flag).
    [Tags]    p0
    Give    people.json    "a1b22c333" | [scan("[0-9]+")]    [["1","22","333"]]
    Give    people.json    "hello world" | [scan("[a-z]+")]    [["hello","world"]]
    Give    people.json    "aA" | [scan("a"; "i")]    [["a","A"]]

TC-JQX-109 scan Gives The Groups Of Each Match As An Array
    [Tags]    p1
    Give    people.json    "ab ab" | [scan("(a)(b)")]    [[["a","b"],["a","b"]]]
    Give    people.json    "1a 2b" | [scan("([0-9])([a-z])")]    [[["1","a"],["2","b"]]]

TC-JQX-110 join Writes null As Nothing
    [Documentation]    jaq wrote `null` as the text null: `["a",null,"b"] | join(",")` was `a,null,b`.
    [Tags]    p0
    Give    people.json    ["a", null, "b"] | join(",")    ["a,,b"]
    Give    people.json    [1, true, false, null, "x"] | join("-")    ["1-true-false--x"]
    Give    people.json    [] | join(",")    [""]

TC-JQX-111 join Refuses An Array Or An Object
    [Tags]    p2
    Give    people.json    [[1]] | try join(",") catch "no"    ["no"]
    Give    people.json    [{"a": 1}] | try join(",") catch "no"    ["no"]

TC-JQX-112 from_entries Reads The Names AWS Tags And Kubernetes Lists Have
    [Documentation]    `{"Key": ..., "Value": ...}` and `{"name": ..., "value": ...}`: jaq knew only `key` and `value`, and gave an object with the key null.
    [Tags]    p0
    Give    people.json    [{"Key": "env", "Value": "prod"}, {"Key": "team", "Value": "x"}] | from_entries    [{"env":"prod","team":"x"}]
    Give    people.json    [{"name": "A", "value": "1"}, {"name": "B", "value": "2"}] | from_entries    [{"A":"1","B":"2"}]
    Give    people.json    [{"key": "a", "value": 1}, {"Name": "b", "Value": 2}] | from_entries    [{"a":1,"b":2}]

TC-JQX-113 with_entries Uses The Same Names
    [Tags]    p2
    Give    people.json    {"a": 1} | with_entries(.Key = .key | del(.key))    [{"a":1}]
    Give    people.json    {"a": 1, "b": 2} | with_entries(.value += 1)    [{"a":2,"b":3}]

TC-JQX-114 from_entries Refuses A Key That Is Not Text
    [Documentation]    jaq made an object with the key 1 and showed it as text.
    [Tags]    p2
    Give    people.json    [{"key": 1, "value": 2}] | try from_entries catch "no"    ["no"]
    Give    people.json    [{"value": 2}] | try from_entries catch "no"    ["no"]

TC-JQX-115 @base64d Decodes A JWT Segment Without Padding
    [Documentation]    The payload of a JWT has no `=` at the end, and jaq refused it.
    [Tags]    p0
    Give    people.json    "eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4ifQ" | @base64d | fromjson | .name    ["John"]
    Give    people.json    "aGVsbG8" | @base64d    ["hello"]
    Give    people.json    "aGVsbG8=" | @base64d    ["hello"]
    Give    people.json    "YQ" | @base64d    ["a"]

TC-JQX-116 @base64d Refuses What Is Not Base64 And Replaces Bytes That Are Not Text
    [Documentation]    A lone character left over, and a character outside the alphabet (a URL-safe `-` or `_`) are errors; bytes that are not UTF-8 become U+FFFD.
    [Tags]    p2
    Give    people.json    "a" | try @base64d catch "no"    ["no"]
    Give    people.json    "a-b_" | try @base64d catch "no"    ["no"]
    Give    people.json    "/w==" | @base64d | explode    [[65533]]
