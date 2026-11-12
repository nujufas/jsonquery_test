*** Settings ***
Documentation     `jsonquery-mcp`, the program beside the app in the build with MCP -- see docs/26_mcp_server.md.
...
...               Claude Desktop and llama-server (QuickAI) start their MCP servers themselves and talk to them over
...               stdin and stdout. `jsonquery-mcp` is that program: it answers the handshake and the list of tools by
...               itself, and takes every other message to the app's server, with the port and the token of the app's
...               mcp.json (in JSONQUERY_HOME, as the app has it), so that what those assistants are given holds no
...               token. It is started here as they start it: with no arguments, the app's folder in JSONQUERY_HOME,
...               one JSON-RPC message to a line (`Bridge Exchange`, `Bridge Tool Call` in resources/mcp_client.py).
Resource          ../../resources/mcp.resource
Library           Process
Force Tags        mcp    undocked-only
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Mcp App
Test Teardown     Close Jsonquery App

*** Variables ***
@{TOOLS}    get_state    document_info    describe    read_value    search    run_query    get_results    query_help    workspace_list
...         workspace_read    format_json    diff_documents    apply_patch    merge_documents    validate_json    create_schema
...         open_document    set_query    reveal    workspace_open    show_in_tool    workspace_save    workspace_new_folder
...         workspace_move    workspace_delete    save_file    open_url

*** Test Cases ***
TC-MCP-070 jsonquery-mcp Answers The Handshake And Lists The Tools While The App Is Closed
    [Documentation]    An assistant starts its servers when it starts, often before JsonQuery: the handshake and the
    ...    list of tools are answered all the same, the same as the app's own.
    [Tags]    p1
    Start Mcp Server
    ${home}=    App Home
    Close Jsonquery App    keep_home=${True}
    ${init}=    Bridge Initialize Message    id=1
    ${replies}=    Bridge Exchange    ${init}    {"jsonrpc": "2.0", "method": "notifications/initialized"}
    ...    {"jsonrpc": "2.0", "id": 2, "method": "tools/list"}    home=${home}
    Length Should Be    ${replies}    2
    Should Be Equal    ${replies}[0][result][serverInfo][name]    jsonquery
    ${names}=    Evaluate    [tool['name'] for tool in $replies[1]['result']['tools']]
    Should Be Equal    ${names}    ${TOOLS}

TC-MCP-071 A Call Before The Server Was Ever Set Up Says How To Set It Up
    [Documentation]    No mcp.json at all (the server was never started on this computer): a call is answered with
    ...    what to do, for the assistant to tell the user.
    [Tags]    p1
    [Setup]    No Operation
    ${empty}=    Make Temp Directory
    ${result}=    Bridge Tool Call    get_state    home=${empty}
    Should Be True    ${result}[error]
    Should Contain    ${result}[text]    has not been set up
    Should Contain    ${result}[text]    click the 🔌
    [Teardown]    No Operation

TC-MCP-072 A Call While The App Is Closed Says That JsonQuery Is Not Running
    [Tags]    p1
    Start Mcp Server
    ${home}=    App Home
    Close Jsonquery App    keep_home=${True}
    ${result}=    Bridge Tool Call    get_state    home=${home}
    Should Be True    ${result}[error]
    Should Contain    ${result}[text]    is not running

TC-MCP-073 A Call Through jsonquery-mcp Reaches The Running App, Which Shows It And Names The Assistant
    [Documentation]    set_query through the program: the window shows the query and its results, and the panel names
    ...    the assistant that made the handshake with the program (which tells the app before each call) and lists
    ...    the call.
    [Tags]    p1
    [Setup]    Launch Mcp App    access=edit    start_with_app=${True}
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${result}=    Bridge Tool Call    set_query    {"query": ".[0].role"}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Wait Until Region Contains Text    @{RESULTS_PANEL}    engineer    timeout=5
    Query Text Should Be    .[0].role
    Open Mcp Panel
    Panel Line Should Say    Connected: Robot over stdio 1.0
    Panel Line Should Say    1 call
    Call Row Should Say    1    set_query

TC-MCP-074 jsonquery-mcp Follows A New Token And A New Port By Itself
    [Documentation]    The program reads mcp.json for every call: after New token, and after the server was moved to
    ...    another port, a call through it still reaches the app, with nothing changed in the assistant.
    [Tags]    p2
    Open Mcp Panel
    Start Mcp Server From Panel
    ${result}=    Bridge Tool Call    get_state
    Should Not Be True    ${result}[error]    msg=${result}[text]
    ${before}=    Mcp Settings
    Click At    ${MCP_NEW_TOKEN_X}    ${MCP_NEW_TOKEN_Y}
    Wait Until Keyword Succeeds    10x    0.3s    Token Should Differ From    ${before}[token]
    Wait Until Mcp Server Answers    timeout=5    port=${MCP_PORT}
    ${result}=    Bridge Tool Call    get_state
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Stop Mcp Server From Panel
    ${new}=    Free Port
    Click At    ${MCP_PORT_X}    ${MCP_PORT_Y}
    Press Keys    ctrl    a
    Type Text    ${new}
    Set Test Variable    ${MCP_PORT}    ${new}
    Start Mcp Server From Panel
    Wait Until Mcp Setting Is    port    ${new}
    ${result}=    Bridge Tool Call    get_state
    Should Not Be True    ${result}[error]    msg=${result}[text]

TC-MCP-075 jsonquery-mcp Says What It Is When Run By Hand
    [Documentation]    Run in a terminal, the program gives its version or what it is for, and refuses what it does not
    ...    know with a usage line; it never waits on a terminal without saying so (that is not checked here).
    [Tags]    p3
    [Setup]    No Operation
    ${bridge}=    Bridge Path
    ${r}=    Run Process    ${bridge}    --version    timeout=10s
    Should Be Equal As Integers    ${r.rc}    0
    Should Match Regexp    ${r.stdout}    ^jsonquery-mcp \\d+\\.\\d+\\.\\d+
    ${r}=    Run Process    ${bridge}    --help    timeout=10s
    Should Be Equal As Integers    ${r.rc}    0
    Should Contain    ${r.stdout}    usage: jsonquery-mcp
    ${r}=    Run Process    ${bridge}    --listen    timeout=10s
    Should Be Equal As Integers    ${r.rc}    2
    Should Contain    ${r.stderr}    unknown argument
    [Teardown]    No Operation

TC-MCP-076 Through jsonquery-mcp An Answer Is Kept To The Size Of Page The User Set
    [Documentation]    The page is the app's, whoever calls: through the program, as QuickAI's llama-server calls, with
    ...    Answers at 4 KB a long read is a page of at most 4 KB that says where the next starts.
    [Tags]    p2
    [Setup]    Launch Mcp App    access=read    start_with_app=${True}    answer_kb=4
    Load Fixture Via Paste    ${{ json.dumps([{"id": i, "note": "x" * 40} for i in range(300)]) }}
    ${result}=    Bridge Tool Call    read_value    {"limit": 1000}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    ${bytes}=    Get Length    ${result}[text]
    Should Be True    2000 < ${bytes} <= 4000    msg=The page is ${bytes} bytes
    Should Be True    0 < ${result}[value][next_offset] < 300    msg=${result}[value]

*** Keywords ***
Token Should Differ From
    [Arguments]    ${before}
    ${now}=    Mcp Settings
    Should Not Be Equal    ${now}[token]    ${before}
