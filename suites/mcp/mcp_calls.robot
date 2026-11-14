*** Settings ***
Documentation     What an assistant does through the MCP server, seen in the window -- see docs/26_mcp_server.md.
...
...               Every app here starts its server with it and allows Edit (mcp.json), unless a case says
...               otherwise, and an assistant has made its handshake (`Launch Mcp App Serving`). The assistant's calls
...               go over HTTP as a real one's do (resources/mcp_client.py); what the window shows is read as in the
...               other suites. The answers' own details (paging, shapes, errors of each tool) are the app's unit tests
...               (crates/mcp, crates/app/src/app/mcp/tests.rs): these cases are the whole path, the window included.
Resource          ../../resources/mcp.resource
Force Tags        mcp    undocked-only
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Mcp App Serving
Test Teardown     Close Jsonquery App

*** Variables ***
# The status line, short of the 🔌 and of the spinner at its left (an icon in a region makes OCR misread the text beside it).
@{MCP_STATUS_TEXT}        36     705    1020    95

*** Test Cases ***
TC-MCP-040 get_state Says What The Window Shows: The Document, The Query And Its Results
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    Run Query    .[].name
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Be Equal    ${state}[document][source]    pasted
    Should Be Equal    ${state}[query][text]    .[].name
    Should Be Equal    ${state}[query][language]    jq
    Should Be Equal As Integers    ${state}[query][results][count]    3
    Should Be Equal    ${state}[in_front]    Json Query
    Should Be Equal    ${state}[tools]    closed
    Should Be Equal    ${state}[access]    edit

TC-MCP-041 run_query Answers The Assistant And Changes Nothing In The Window
    [Documentation]    The assistant's own query runs over the document the window has, on a worker of its own: the
    ...    answer is the assistant's, and the query box and the results stay the user's.
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    Run Query    .[0].name
    ${answer}=    Mcp Tool Should Succeed    run_query    {"query": ".[].age"}
    Should Be Equal As Integers    ${answer}[count]    3
    ${ages}=    Evaluate    [int(v) for v in $answer['items']]
    Should Be Equal    ${ages}    ${{ [34, 19, 45] }}
    Should Be True    ${answer}[complete]
    Query Text Should Be    .[0].name
    Region Should Contain Text    @{RESULTS_PANEL}    Alice
    Region Should Not Contain Text    @{RESULTS_PANEL}    45

TC-MCP-042 set_query Puts The Query In The Box And Runs It, And get_results Gives What The Window Shows
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${done}=    Mcp Tool Should Succeed    set_query    {"query": ".[] | select(.age > 30) | .name"}
    Should Be Equal As Integers    ${done}[count]    2
    Wait Until Region Contains Text    @{RESULTS_PANEL}    Carol    timeout=5
    Region Should Contain Text    @{RESULTS_PANEL}    Alice
    Region Should Not Contain Text    @{RESULTS_PANEL}    Bob
    Query Text Should Be    .[] | select(.age > 30) | .name
    ${results}=    Mcp Tool Should Succeed    get_results
    Should Be Equal    ${results}[items]    ${{ ["Alice", "Carol"] }}

TC-MCP-043 set_query In JSONPath Picks JSONPath In The Window
    [Tags]    p2
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    Mcp Tool Should Succeed    set_query    {"query": "$[*].role", "language": "jsonpath"}
    Wait Until Region Contains Text    @{RESULTS_PANEL}    manager    timeout=5
    Wait Until Region Contains Text    @{MCP_STATUS_TEXT}    JSONPath    timeout=3
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Be Equal    ${state}[query][language]    jsonpath
    Should Be True    ${state}[query][language_chosen]

TC-MCP-044 open_document Opens A File As The Source, And The Window Shows It
    [Tags]    p1
    ${path}=    Fixture Path    people.json
    ${opened}=    Mcp Tool Should Succeed    open_document    {"path": "${path}"}
    Should Be True    ${opened}[opened]
    Should Be Equal    ${opened}[document][source]    file
    Should Be Equal    ${opened}[document][from]    ${path}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=5
    Wait Until Region Contains Text    @{TOOLBAR_ROW}    people.json    timeout=3

TC-MCP-045 open_document With JSON Text Shows It As The Source
    [Tags]    p2
    ${opened}=    Mcp Tool Should Succeed    open_document    {"text": "{\\"fruit\\": \\"mango\\", \\"count\\": 7}"}
    Should Be True    ${opened}[opened]
    Wait Until Region Contains Text    @{SOURCE_PANEL}    mango    timeout=5
    ${answer}=    Mcp Tool Should Succeed    run_query    {"query": ".count"}
    Should Be Equal As Integers    ${answer}[items][0]    7

TC-MCP-046 open_document Refuses A Web Address And A Relative Path, And The Window Keeps Its Document
    [Documentation]    The server never loads a web address, and takes only whole paths (a relative one would be the
    ...    app's folder's): both are refused with what to give instead, and the window still shows the user's
    ...    document; nothing was handed to a browser either.
    [Tags]    p2
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    Mcp Tool Should Fail    open_document    {"path": "https://example.com/data.json"}    expected=web address
    Mcp Tool Should Fail    open_document    {"path": "people.json"}    expected=not a full path
    Region Should Contain Text    @{SOURCE_PANEL}    3 items
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Be Equal    ${state}[document][source]    pasted
    Nothing Should Have Been Opened    settle=0.3

TC-MCP-047 reveal Opens The Source Tree Down To A Value
    [Documentation]    A value deep in the Source tree, folded away: reveal opens the tree down to it and shows it.
    [Tags]    p1
    Load Fixture Via Paste    {"outer": {"inner": {"deep": "treasure-trove"}}, "other": 1}
    Region Should Not Contain Text    @{SOURCE_PANEL}    treasure
    ${shown}=    Mcp Tool Should Succeed    reveal    {"target": "source", "pointer": "/outer/inner/deep"}
    Should Be Equal    ${shown}[revealed]    /outer/inner/deep
    Wait Until Region Contains Text    @{SOURCE_PANEL}    treasure    timeout=4

TC-MCP-048 workspace_list Gives The Saved Queries, And workspace_open Opens One In The Query Box
    [Tags]    p1
    [Setup]    Launch Mcp App Serving    workspace=${{ {"people/adults.jq": ".[] | select(.age >= 21) | .name"} }}
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${listed}=    Mcp Tool Should Succeed    workspace_list
    ${paths}=    Evaluate    [item['path'] for item in $listed['items']]
    Should Contain    ${paths}    people/adults.jq
    ${opened}=    Mcp Tool Should Succeed    workspace_open    {"path": "people/adults.jq"}
    Query Text Should Be    .[] | select(.age >= 21) | .name
    ${read}=    Mcp Tool Should Succeed    workspace_read    {"path": "people/adults.jq"}
    Should Contain    ${read}[text]    select(.age >= 21)

TC-MCP-049 workspace_open Never Loads A Web Address, And workspace_read Gives It
    [Documentation]    A web address kept in the workspace (a .url item) is not loaded by the server: the assistant
    ...    is told so, and can read the address; the server it points at is never asked, and no browser is.
    [Tags]    p1
    [Setup]    Launch With A Web Address
    Mcp Tool Should Fail    workspace_open    {"path": "data/site.url"}    expected=web address
    ${read}=    Mcp Tool Should Succeed    workspace_read    {"path": "data/site.url"}
    Should Be Equal    ${read}[url]    ${SERVED}/people.json
    Sleep    1s
    ${asked}=    Fixture Server Requests
    Should Be Empty    ${asked}
    Nothing Should Have Been Opened    settle=0.3
    [Teardown]    Run Keywords    Stop Fixture Server    AND    Close Jsonquery App

TC-MCP-050 A Call That Shows Something Works While The Window Is Minimized
    [Documentation]    A minimized window gets no frames, yet set_query is done and answered at once; restored, the
    ...    window shows it.
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    Minimize Main Window
    ${started}=    Evaluate    time.monotonic()    modules=time
    ${done}=    Mcp Tool Should Succeed    set_query    {"query": ".[1].name"}
    ${took}=    Evaluate    time.monotonic() - ${started}    modules=time
    Should Be True    ${took} < 5    msg=set_query took ${took} s with the window minimized
    Should Be Equal    ${done}[items]    ${{ ["Bob"] }}
    ${visible}=    Main Window Is Viewable
    Should Not Be True    ${visible}
    Restore Main Window
    Wait Until Region Contains Text    @{RESULTS_PANEL}    Bob    timeout=4
    Query Text Should Be    .[1].name

TC-MCP-051 The User's Own Query Runs While The Assistant's Long Query Runs
    [Documentation]    The assistant's run_query has a worker of its own: the user's query is not queued behind it, and
    ...    the assistant's answer is whole when it comes.
    [Tags]    p2
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${long}=    Long Query
    ${call}=    Start Mcp Call    run_query    {"query": "${long}", "timeout_ms": 120000}
    Sleep    0.5s
    Run Query    .[2].name
    Wait Until Region Contains Text    @{RESULTS_PANEL}    Carol    timeout=5
    ${out}=    Evaluate    $call.thread.is_alive()
    Should Be True    ${out}    msg=The assistant's query was over before the user's ran: make Long Query longer
    ${result}=    Wait For Mcp Call    ${call}    timeout=150
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Should Be True    ${result}[value][complete]
    Should Be Equal As Integers    ${result}[value][count]    1

TC-MCP-052 search Finds A Value With Its Pointer
    [Tags]    p2
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${found}=    Mcp Tool Should Succeed    search    {"text": "Carol"}
    Should Be Equal As Integers    ${found}[count]    1
    Should Be Equal    ${found}[matches][0][pointer]    /2/name

TC-MCP-053 describe Gives The Shape Of The Document Without Its Data
    [Tags]    p2
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${shape}=    Mcp Tool Should Succeed    describe
    ${text}=    Evaluate    json.dumps($shape)    modules=json
    Should Contain    ${text}    array
    Should Contain    ${text}    "name"
    Should Contain    ${text}    "age"
    Should Contain    ${text}    "role"

TC-MCP-054 query_help Gives The App's Lessons And Where Its jq Differs From jq
    [Tags]    p3
    ${lesson}=    Mcp Tool Should Succeed    query_help    {"language": "jq", "topic": "select"}
    Should Contain    ${lesson}    select
    ${issues}=    Mcp Tool Should Succeed    query_help    {"topic": "known issues"}
    Should Contain    ${issues}    Known issues

TC-MCP-055 Read Refuses Every Call That Would Change The Window, And The Panel Lists Them In Red
    [Documentation]    With Read, open_document, set_query, reveal, workspace_open and a run_query on a file are refused
    ...    with a message that says to ask the user for Edit; the window keeps what it had, and the panel lists the
    ...    refused calls in red.
    [Tags]    p1
    [Setup]    Launch Mcp App Serving    access=read    workspace=${{ {"q.jq": ".[0].role"} }}
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    Run Query    .[0].name
    ${path}=    Fixture Path    nested.json
    Mcp Tool Should Fail    open_document    {"text": "[1, 2, 3]"}    expected=allow "Edit"
    Mcp Tool Should Fail    set_query    {"query": ".[1].name"}    expected=allow "Edit"
    Mcp Tool Should Fail    reveal    {"pointer": "/1"}    expected=allow "Edit"
    Mcp Tool Should Fail    workspace_open    {"path": "q.jq"}    expected=allow "Edit"
    Mcp Tool Should Fail    run_query    {"query": ".", "input": {"file": "${path}"}}    expected=allow "Edit"
    Query Text Should Be    .[0].name
    Region Should Contain Text    @{SOURCE_PANEL}    3 items
    Open Mcp Panel
    Panel Line Should Say    5 calls
    FOR    ${row}    IN RANGE    1    6
        Call Row Should Be Red    ${row}
    END

TC-MCP-056 A Long Answer Comes A Page At A Time
    [Tags]    p3
    Load Fixture Via Paste    ${{ open($NUMBERS_FIXTURE).read() }}
    ${first}=    Mcp Tool Should Succeed    run_query    {"query": ".[]", "limit": 5}
    Should Be Equal    ${first}[items]    ${{ [0, 1, 2, 3, 4] }}
    Should Be Equal As Integers    ${first}[next_offset]    5
    ${second}=    Mcp Tool Should Succeed    run_query    {"query": ".[]", "limit": 5, "offset": 5}
    Should Be Equal    ${second}[items]    ${{ [5, 6, 7, 8, 9] }}

*** Keywords ***
Long Query
    [Documentation]    A jq query that keeps the worker busy for about ${seconds} s with little memory, on the build
    ...    under test: a release build runs it ten times as fast as a debug one (twelve million steps took 10 s in
    ...    a debug build and under 3 s in the release build of 0.6.0), so a million steps are timed first.
    [Arguments]    ${seconds}=10
    ${start}=    Evaluate    time.monotonic()    modules=time
    Mcp Tool Should Succeed    run_query    {"query": "reduce range(1000000) as $i (0; . + $i)"}
    ${took}=    Evaluate    time.monotonic() - ${start}    modules=time
    ${steps}=    Evaluate    max(1000000, int(1000000 * ${seconds} / max(${took}, 0.01)))
    Log    A million steps took ${took} s: ${steps} steps for ${seconds} s.
    RETURN    reduce range(${steps}) as $i (0; . + $i)

Launch With A Web Address
    ${served}=    Make Folder With Files    served    ${{ {"people.json": open($PEOPLE_FIXTURE).read()} }}
    ${base}=    Start Fixture Server    ${served}
    Set Test Variable    ${SERVED}    ${base}
    ${shortcut}=    Evaluate    "[InternetShortcut]\\r\\nURL=" + $base + "/people.json\\r\\n"
    Launch Mcp App Serving    workspace=${{ {"data/site.url": $shortcut} }}
