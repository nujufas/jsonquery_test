*** Settings ***
Documentation     What an assistant does out of sight -- the six Tools as tools, documents read without being opened,
...               what is kept as "last", facts about a document, answers kept to the size of page the user set -- and
...               that the window shows none of it. See docs/26_mcp_server.md.
...
...               Every app here starts its server with it and allows Read (mcp.json), unless a case says otherwise,
...               and an assistant has made its handshake. The answers' finer details (every tool's errors, the shapes
...               of the answers) are the app's unit tests: these cases are the whole path, over HTTP, against the
...               running app.
Resource          ../../resources/mcp.resource
Resource          ../../resources/tools.resource
Library           Collections
Force Tags        mcp    undocked-only
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Mcp App Serving    access=read
Test Teardown     Close Jsonquery App

*** Test Cases ***
TC-MCP-100 format_json Gives The Document Formatted, And The Window Keeps What It Shows
    [Tags]    p2
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${out}=    Mcp Tool Should Succeed    format_json    {"input": "document", "indent": "4", "sort_keys": true}
    Should Start With    ${out}[text]    [\n    {\n        "age": 34,
    Should Be True    ${out}[complete]
    Query Box Should Be Empty
    Run Keyword And Expect Error    *    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=1

TC-MCP-101 diff_documents Gives The Differences By Pointer, And Its Patch, Kept As last, Turns The Left Into The Right
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${right}=    Evaluate    [dict(p, age=p["age"] + 1) for p in json.load(open($PEOPLE_FIXTURE))]
    ${diff}=    Mcp Tool Should Succeed    diff_documents    ${{ {"left": "document", "right": {"json": $right}, "as_patch": True} }}
    Should Be Equal As Integers    ${diff}[changed]    3
    Should Be Equal    ${diff}[changes][0][pointer]    /0/age
    Should Be Equal    ${diff}[last]    kept: give "last" as an input
    ${patched}=    Mcp Tool Should Succeed    apply_patch    {"input": "document", "patch": "last"}
    Should Be Equal    ${patched}[result]    ${right}
    Query Box Should Be Empty

TC-MCP-102 merge_documents Appends Or Merges Deep, And Keeps The Merge As last
    [Tags]    p2
    ${merged}=    Mcp Tool Should Succeed    merge_documents    {"inputs": [{"json": [1, 2]}, {"json": [3]}]}
    Should Be Equal    ${merged}[result]    ${{ [1, 2, 3] }}
    ${deep}=    Mcp Tool Should Succeed    merge_documents
    ...    {"inputs": [{"json": {"a": {"x": 1}}}, {"json": {"a": {"y": 2}}}], "how": "deep"}
    Should Be Equal    ${deep}[result]    ${{ {"a": {"x": 1, "y": 2}} }}
    ${kept}=    Mcp Tool Should Succeed    read_value    {"input": "last", "pointer": "/a"}
    Should Be Equal    ${kept}[members]    ${{ {"x": 1, "y": 2} }}

TC-MCP-103 validate_json Says What Is Wrong And Where, A Page At A Time
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${schema}=    Set Variable    {"items": {"properties": {"age": {"type": "string"}}}}
    ${first}=    Mcp Tool Should Succeed    validate_json    {"input": "document", "schema": {"json": ${schema}}, "limit": 2}
    Should Not Be True    ${first}[valid]
    Should Be Equal As Integers    ${first}[count]    3
    Should Be Equal    ${first}[problems][0][pointer]    /0/age
    Should Be Equal As Integers    ${first}[next_offset]    2
    ${second}=    Mcp Tool Should Succeed    validate_json    {"input": "document", "schema": {"json": ${schema}}, "offset": 2}
    Should Be Equal    ${second}[problems][0][pointer]    /2/age
    Dictionary Should Not Contain Key    ${second}    next_offset

TC-MCP-104 create_schema Describes The Document, And The Schema Kept As last Checks It
    [Tags]    p2
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${made}=    Mcp Tool Should Succeed    create_schema    {"input": "document"}
    Should Be Equal    ${made}[schema][type]    array
    ${checked}=    Mcp Tool Should Succeed    validate_json    {"input": "document", "schema": "last"}
    Should Be True    ${checked}[valid]
    ${wrong}=    Mcp Tool Should Succeed    validate_json    {"input": {"json": [{"name": 1}]}, "schema": "last"}
    Should Not Be True    ${wrong}[valid]

TC-MCP-105 document_info Says What The Open Document Is, Without Its Data
    [Documentation]    Where it is from, how big, what it holds of each kind and how deep, and how many pages of the
    ...    size the user set reading it whole takes.
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${info}=    Mcp Tool Should Succeed    document_info
    Should Be Equal    ${info}[source]    pasted
    Should Be Equal    ${info}[format]    JSON
    Should Be Equal    ${info}[is]    array with 3 items
    Should Be Equal    ${info}[values]    ${{ {"all": 13, "nulls": 0, "booleans": 0, "numbers": 3, "strings": 6, "arrays": 1, "objects": 3} }}
    Should Be Equal As Integers    ${info}[depth]    2
    Should Be Equal    ${info}[longest_arrays]    ${{ [{"pointer": "", "items": 3}] }}
    Should Be Equal As Integers    ${info}[to_read_whole][pages]    1
    Should Be Equal As Integers    ${info}[to_read_whole][page_bytes]    24000
    Should Not Contain    ${{ json.dumps($info) }}    Alice

TC-MCP-106 A File Is Read Out Of Sight, And The Window Keeps Its Own Document
    [Documentation]    With Edit: facts, shape, a value, a search and a query of a file that is not open, and the window
    ...    still shows its own document, with nothing in the query box.
    [Tags]    p1
    [Setup]    Launch Mcp App Serving    access=edit
    Load Fixture Via Paste    [10, 20]
    ${path}=    Fixture Path    people.json
    ${file}=    Create Dictionary    file=${path}
    ${info}=    Mcp Tool Should Succeed    document_info    ${{ {"input": $file} }}
    Should Be Equal    ${info}[source]    file
    ${size}=    Get File Size    ${path}
    Should Be Equal As Integers    ${info}[bytes]    ${size}
    Should Match Regexp    ${info}[modified]    ^\\d{4}-\\d\\d-\\d\\dT\\d\\d:\\d\\d:\\d\\dZ$
    ${shape}=    Mcp Tool Should Succeed    describe    ${{ {"input": $file} }}
    Should Be Equal As Integers    ${shape}[length]    3
    ${value}=    Mcp Tool Should Succeed    read_value    ${{ {"input": $file, "pointer": "/1/name"} }}
    Should Be Equal    ${value}[value]    Bob
    ${found}=    Mcp Tool Should Succeed    search    ${{ {"input": $file, "text": "carol"} }}
    Should Be Equal    ${found}[matches][0][pointer]    /2/name
    ${ran}=    Mcp Tool Should Succeed    run_query    ${{ {"input": $file, "query": "[.[].age] | add"} }}
    Should Be Equal    ${ran}[items]    ${{ [98] }}
    Region Should Contain Text    @{SOURCE_PANEL}    2 items
    Query Box Should Be Empty

TC-MCP-107 What run_query Gives Is Kept As last: Queried Again, And Saved Without Passing Through The Answer
    [Documentation]    A query's results, all of them though the page had one, are "last"; a query of "last", and
    ...    save_file of "last" (Always allow ticked, so nothing is asked), write what was kept.
    [Tags]    p1
    [Setup]    Launch Mcp App Serving    access=edit    always_allow=${True}
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${ran}=    Mcp Tool Should Succeed    run_query    {"query": ".[] | select(.age > 21)", "limit": 1}
    Should Be Equal As Integers    ${ran}[count]    2
    Length Should Be    ${ran}[items]    1
    Should Start With    ${ran}[last]    kept
    ${names}=    Mcp Tool Should Succeed    run_query    {"query": "map(.name)", "input": "last"}
    Should Be Equal    ${names}[items]    ${{ [["Alice", "Carol"]] }}
    ${folder}=    Make Folder With Files    out
    Mcp Tool Should Succeed    save_file    {"input": "last", "path": "${folder}/names.json", "indent": "minified"}
    ${text}=    Get File    ${folder}/names.json
    Should Be Equal    ${text}    [["Alice","Carol"]]
    No Question Should Be Shown    settle=0.2

TC-MCP-108 With Answers Of 4 KB Every Long Answer Is A Page Of 4 KB At Most, And Its Pages Give All Of It
    [Documentation]    A read of 200 rows comes in pages of at most 4 KB, each saying where the next starts, which
    ...    together are the rows; a search, a query and the help are pages of 4 KB at most too.
    [Tags]    p1
    [Setup]    Launch Mcp App Serving    access=read    answer_kb=4
    ${rows}=    Evaluate    [{"id": i, "note": "x" * 30} for i in range(200)]
    Load Fixture Via Paste    ${{ json.dumps($rows) }}
    ${offset}=    Set Variable    ${0}
    ${seen}=    Create List
    WHILE    True    limit=100
        ${page}=    Call Mcp Tool    read_value    {"limit": 1000, "offset": ${offset}}
        Answer Should Fit    ${page}    4000
        ${items}=    Set Variable    ${page}[value][items]
        Append To List    ${seen}    @{items}
        IF    'next_offset' not in $page['value']    BREAK
        ${offset}=    Set Variable    ${page}[value][next_offset]
    END
    Should Be Equal    ${seen}    ${rows}
    ${found}=    Call Mcp Tool    search    {"text": "x", "limit": 1000}
    Answer Should Fit    ${found}    4000
    Dictionary Should Contain Key    ${found}[value]    next_offset
    ${ran}=    Call Mcp Tool    run_query    {"query": ".[]", "limit": 1000}
    Answer Should Fit    ${ran}    4000
    ${help}=    Call Mcp Tool    query_help    {"language": "jq"}
    Answer Should Fit    ${help}    4000
    Should Contain    ${help}[text]    [more: query_help

TC-MCP-109 What A Model Reads Of The Tools Before It Does Anything Is Short
    [Documentation]    The descriptions and the schemas of all the tools, which a model takes in before its first call
    ...    (a small one, run on the user's computer, has little room), are under 20 KB.
    [Tags]    p3
    ${listed}=    Mcp Post    {"jsonrpc": "2.0", "id": 9, "method": "tools/list"}
    ${tools}=    Set Variable    ${listed}[json][result][tools]
    Length Should Be    ${tools}    27
    ${read}=    Evaluate    sum(len(__import__("json").dumps(t["description"])) + len(__import__("json").dumps(t["inputSchema"], separators=(",", ":"))) for t in $tools)
    Should Be True    ${read} < 20000    msg=${read} bytes

*** Keywords ***
Query Box Should Be Empty
    [Documentation]    The window's query box holds nothing and nothing was run in it (what the app says it shows, by
    ...    get_state: an empty box cannot be copied from to compare).
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Be Empty    ${state}[query][text]
    Should Be Equal    ${state}[query][results]    ${None}

Answer Should Fit
    [Documentation]    The answer `outcome` (of `Call Mcp Tool`) went well and is at most `bytes` long.
    [Arguments]    ${outcome}    ${bytes}
    Should Not Be True    ${outcome}[error]    msg=${outcome}[text]
    ${length}=    Get Length    ${outcome}[text]
    Should Be True    ${length} <= ${bytes}    msg=The answer is ${length} bytes, more than ${bytes}
