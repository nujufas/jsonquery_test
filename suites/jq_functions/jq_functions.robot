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
