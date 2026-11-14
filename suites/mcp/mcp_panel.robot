*** Settings ***
Documentation     The 🔌 of the MCP server and the panel it opens -- see docs/26_mcp_server.md.
...
...               The app (every build but those named _nomcp, made with --no-default-features) has a 🔌
...               at the right of the status bar, the last of its buttons there, so the others stay where they are in
...               both builds. A click on it opens a panel that keeps one size: Start/Stop, the address, what the
...               assistant may do (Read or Edit, and Always allow), how big an answer may be, buttons that copy what
...               adds the server to an assistant, whether the server starts with the app, who is connected and the
...               last calls, and a new token. The server listens on 127.0.0.1
...               only, and keeps its port and token in mcp.json beside settings.json.
...
...               Every app here starts with an mcp.json of its own giving the server a free port (`Launch Mcp App`),
...               so that a run never meets the JsonQuery of whoever runs it on 7457; TC-MCP-004 starts without one.
...               What the server answers is asked as an assistant does (resources/mcp_client.py).
Resource          ../../resources/mcp.resource
Force Tags        mcp    undocked-only
Suite Setup       Start Test Display
Suite Teardown    Run Keywords    Release Ports    AND    Remove Lonely Builds    AND    Stop Test Display
Test Setup        Launch Mcp App
Test Teardown     Run Keywords    Release Ports    AND    Close Jsonquery App

*** Variables ***
${ABOUT_WINDOW}       JsonQuery — About
${SETTINGS_WINDOW}    JsonQuery — Settings
# The tooltip of the green button, whose first line is longer than the grey one's; and the tooltip of QuickAI's button,
# near the second row of Add to.
@{WORKING_TIP}        560    720    640    60
@{QUICKAI_TIP}        440    560    760    110

*** Test Cases ***
TC-MCP-001 The MCP Button Is Beside The Settings Button At The Right Of The Status Bar
    [Documentation]    From the right: ⓘ, 🌐, ⚙ where they are in the build without MCP, then the MCP button (a plug with
    ...    "AI"), grey, and nothing left of it with the Tools in a window; the workspace's button is at the other end of
    ...    the bar.
    [Tags]    p1
    # The first app on a display that has just started draws its first frames late.
    Wait Until Keyword Succeeds    10x    0.3s    Something Should Be Drawn At    1181
    Something Should Be Drawn At    1152
    Something Should Be Drawn At    1123
    Something Should Be Drawn At    ${MCP_PLUG_X}
    Something Should Be Drawn At    20
    Nothing Should Be Drawn At    ${MCP_LEFT_OF_PLUG_X}
    Plug Should Not Be Green

TC-MCP-002 Hovering The Plug Says What It Is For And That A Click Sets It Up
    [Documentation]    Held still under the pointer, the 🔌 says two short lines: what the server does, and what a click
    ...    does. Nothing more, and the server does not start by being looked at.
    [Tags]    p1
    Move Mouse To    ${MCP_PLUG_X}    ${MCP_BAR_Y}
    Sleep    1.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{MCP_PLUG_TIP}    assistant work with the app
    Region Should Contain Text    @{MCP_PLUG_TIP}    MCP server
    Region Should Contain Text    @{MCP_PLUG_TIP}    Click to set it up
    Region Should Not Contain Text    @{MCP_ABOVE_TIP}    MCP
    Mcp Server Should Not Answer    port=${MCP_PORT}

TC-MCP-003 A Click On The Plug Opens Its Panel And A Click Elsewhere Closes It
    [Documentation]    The panel opens above the 🔌 and stays open while it is used; a click outside it closes it, and
    ...    neither click opens a window or starts the server.
    [Tags]    p1
    Region Should Not Contain Text    @{MCP_TITLE_ROW}    MCP server
    Open Mcp Panel
    Region Should Contain Text    @{MCP_TITLE_ROW}    Start
    # Inside the panel, where nothing is (under the status lines): it stays open.
    Click At    900    700
    Sleep    0.3s
    Region Should Contain Text    @{MCP_TITLE_ROW}    MCP server
    Close Mcp Panel
    ${about}=    Count Windows    ${ABOUT_WINDOW}
    ${settings}=    Count Windows    ${SETTINGS_WINDOW}
    Should Be Equal As Integers    ${about}    0
    Should Be Equal As Integers    ${settings}    0
    Mcp Server Should Not Answer    port=${MCP_PORT}
    Nothing Should Have Been Opened    settle=0.3

TC-MCP-004 The Panel Of A First Start: Off, On Port 7457, Read, Answers Of 24 KB, And Nothing Written
    [Documentation]    A user who has never set it up: the server is not running, its address would be port 7457, the
    ...    assistant would be allowed to read (Always allow not ticked), an answer would be at most 24 KB (about
    ...    6,000 tokens), it would not start with the app, and looking at the panel writes no mcp.json (the token in
    ...    it is made when it is first needed).
    [Tags]    p1
    [Setup]    Launch Jsonquery App
    ${exists}=    Mcp Settings File Exists
    Should Not Be True    ${exists}    msg=mcp.json is there before anything was done
    Open Mcp Panel
    Region Should Contain Text    @{MCP_TITLE_ROW}    Start
    Region Should Contain Text    @{MCP_ADDRESS_ROW}    7457
    Region Should Contain Text    @{MCP_ADDRESS_ROW}    /mcp
    Panel Line Should Say    Not running
    Radio Should Be Chosen    ${MCP_READ_X}
    Radio Should Not Be Chosen    ${MCP_EDIT_X}
    Region Should Contain Text    @{MCP_ALLOW_ROW}    Always allow
    Always Allow Should Not Be Ticked
    Answer Size Should Be Chosen    24
    Tokens Should Say    6
    Region Should Contain Text    @{MCP_START_WITH_ROW}    Start it with JsonQuery
    Close Mcp Panel
    ${exists}=    Mcp Settings File Exists
    Should Not Be True    ${exists}    msg=Looking at the panel wrote mcp.json

TC-MCP-005 Start Makes The Server Answer On Its Address And Writes mcp.json For Its Owner, The Button Still Grey
    [Documentation]    Start: the server listens on the port the address shows, the panel says that no assistant has
    ...    connected yet, and mcp.json has the port, a token of 64 hex digits and the access, and can be read by its
    ...    owner only. The button stays grey: no assistant works with the app yet, and a handshake is no work.
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    Region Should Contain Text    @{MCP_ADDRESS_ROW}    127.0.0.1:${MCP_PORT}/mcp
    Panel Line Should Say    No assistant has connected yet
    Panel Line Should Say    No calls yet
    Plug Should Not Be Green
    ${kept}=    Mcp Settings
    Should Be Equal As Integers    ${kept}[port]    ${MCP_PORT}
    Should Match Regexp    ${kept}[token]    ^[0-9a-f]{64}$
    Should Be Equal    ${kept}[access]    read
    ${mode}=    Mcp Settings File Mode
    Should Be Equal    ${mode}    600
    ${answer}=    Mcp Initialize
    Should Be Equal    ${answer}[serverInfo][name]    jsonquery
    Plug Should Not Be Green

TC-MCP-006 Stop Stops The Server, Greys The Button At Once And Says Not Running
    [Documentation]    Stop: nothing listens on the port any more, the button that an assistant's call had turned green
    ...    is grey at once (not a minute later), the panel says Not running and offers Start again, in the same place;
    ...    started again, it stays grey until an assistant calls.
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    Make An Assistant Call
    Plug Should Be Green
    Stop Mcp Server From Panel
    Panel Line Should Say    Not running
    Plug Should Not Be Green
    Mcp Server Should Not Answer    port=${MCP_PORT}
    Start Mcp Server From Panel
    Plug Should Not Be Green

TC-MCP-007 Hovering The Plug While The Server Runs Gives Its Address
    [Tags]    p2
    Start Mcp Server
    Move Mouse To    ${MCP_PLUG_X}    ${MCP_BAR_Y}
    Sleep    1.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{MCP_PLUG_TIP}    127.0.0.1:${MCP_PORT}/mcp
    Region Should Contain Text    @{MCP_PLUG_TIP}    Click for its settings
    Region Should Not Contain Text    @{MCP_ABOVE_TIP}    MCP

TC-MCP-008 The Port Is Changed While The Server Is Stopped, Kept, And Listened On
    [Documentation]    The port box takes another port; leaving it keeps it in mcp.json, and Start listens there and not
    ...    on the old one.
    [Tags]    p1
    ${new}=    Free Port
    Open Mcp Panel
    Click At    ${MCP_PORT_X}    ${MCP_PORT_Y}
    Press Keys    ctrl    a
    Type Text    ${new}
    Click At    740    488
    Wait Until Mcp Setting Is    port    ${new}
    Region Should Contain Text    @{MCP_ADDRESS_ROW}    ${new}
    ${old}=    Set Variable    ${MCP_PORT}
    Set Test Variable    ${MCP_PORT}    ${new}
    Start Mcp Server From Panel
    Mcp Server Should Not Answer    port=${old}
    Region Should Contain Text    @{MCP_ADDRESS_ROW}    127.0.0.1:${new}/mcp

TC-MCP-009 What Is Not A Port Is Not Taken
    [Documentation]    70000, letters and 0 are not ports: leaving the box puts the port back, and that is what is
    ...    kept (70000 is not 7000, which it went through as it was typed).
    [Tags]    p2
    Open Mcp Panel
    FOR    ${typed}    IN    70000    abc    0
        Click At    ${MCP_PORT_X}    ${MCP_PORT_Y}
        Press Keys    ctrl    a
        Type Text    ${typed}
        Click At    740    488
        Wait Until Region Contains Text    @{MCP_ADDRESS_ROW}    ${MCP_PORT}    timeout=2
        Wait Until Mcp Setting Is    port    ${MCP_PORT}
    END
    Start Mcp Server From Panel

TC-MCP-010 A Port Another Program Holds Is Said In Red, And The Plug Stays Grey
    [Documentation]    When the port is taken, Start says so in red and does nothing else; once it is free, Start works
    ...    and the message is gone.
    [Tags]    p1
    Hold Port    ${MCP_PORT}
    Open Mcp Panel
    Click At    ${MCP_START_X}    ${MCP_START_Y}
    Move Mouse To    ${MCP_OUTSIDE_X}    ${MCP_OUTSIDE_Y}
    Panel Line Should Say    is taken    region=${MCP_STATUS_LINE}
    Region Should Contain Color    @{MCP_STATUS_LINE}    @{MCP_ERROR_COLOR}    tolerance=30
    Region Should Contain Text    @{MCP_TITLE_ROW}    Start
    Plug Should Not Be Green
    Release Ports
    Start Mcp Server From Panel
    Panel Line Should Say    No assistant has connected yet
    Region Should Not Contain Color    @{MCP_STATUS_LINE}    @{MCP_ERROR_COLOR}    tolerance=30
    Plug Should Not Be Green

TC-MCP-011 Read, The Default, Lets The Assistant Look But Not Change What The Window Shows
    [Documentation]    With Read an assistant reads the state, but its set_query is refused with a message that says
    ...    what to ask for, and the query box keeps the user's query.
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    Run Query    .[0].name
    Start Mcp Server
    Mcp Initialize
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Be Equal    ${state}[query][text]    .[0].name
    Should Be Equal    ${state}[access]    read
    ${said}=    Mcp Tool Should Fail    set_query    {"query": ".[1].name"}
    Should Contain    ${said}    allow "Edit"
    Query Text Should Be    .[0].name

TC-MCP-012 Edit, Chosen While The Server Runs, Works From The Next Call And Is Kept
    [Documentation]    Allow → Edit while the server runs: no restart, the next set_query puts the query in the box,
    ...    and mcp.json keeps the choice.
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    Open Mcp Panel
    Start Mcp Server From Panel
    Mcp Initialize
    Choose Access    edit
    Radio Should Be Chosen    ${MCP_EDIT_X}
    Radio Should Not Be Chosen    ${MCP_READ_X}
    Close Mcp Panel
    ${done}=    Mcp Tool Should Succeed    set_query    {"query": ".[2].name"}
    Should Be Equal    ${done}[query]    .[2].name
    Should Be Equal    ${done}[items]    ${{ ["Carol"] }}
    Query Text Should Be    .[2].name

TC-MCP-013 Going Back To Read Refuses The Next Call That Would Show
    [Tags]    p2
    [Setup]    Launch Mcp App Serving    access=edit
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    Mcp Tool Should Succeed    set_query    {"query": ".[0].age"}
    Open Mcp Panel
    Radio Should Be Chosen    ${MCP_EDIT_X}
    Choose Access    read
    Close Mcp Panel
    Mcp Tool Should Fail    set_query    {"query": ".[1].age"}    expected=allow "Edit"
    Query Text Should Be    .[0].age

TC-MCP-014 Claude Code's Button Copies The Command That Adds The Server, With Its Token
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    ${kept}=    Mcp Settings
    ${text}=    Copy Configuration    ${MCP_CLAUDE_CODE_X}
    Should Be Equal    ${text}
    ...    claude mcp add --transport http jsonquery http://127.0.0.1:${MCP_PORT}/mcp --header "Authorization: Bearer ${kept}[token]"

TC-MCP-015 VS Code's And JSON's Buttons Copy Entries Of Type http With The Address And The Token
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    ${kept}=    Mcp Settings
    ${text}=    Copy Configuration    ${MCP_VS_CODE_X}
    ${entry}=    Evaluate    json.loads($text)['servers']['jsonquery']    modules=json
    Should Be Equal    ${entry}[type]    http
    Should Be Equal    ${entry}[url]    http://127.0.0.1:${MCP_PORT}/mcp
    Should Be Equal    ${entry}[headers][Authorization]    Bearer ${kept}[token]
    ${text}=    Copy Configuration    ${MCP_JSON_X}    ${MCP_ADD_Y2}
    ${entry}=    Evaluate    json.loads($text)['mcpServers']['jsonquery']    modules=json
    Should Be Equal    ${entry}[type]    http
    Should Be Equal    ${entry}[url]    http://127.0.0.1:${MCP_PORT}/mcp
    Should Be Equal    ${entry}[headers][Authorization]    Bearer ${kept}[token]

TC-MCP-016 Claude Desktop's And QuickAI's Buttons Copy What Starts jsonquery-mcp, With No Token
    [Documentation]    The assistants that start their servers themselves are given `jsonquery-mcp`, beside the app,
    ...    which reads the token from mcp.json: what is copied for them has none. QuickAI's is the same mcpServers
    ...    entry, which its MCP servers take as "the JSON of a server's instructions".
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    ${kept}=    Mcp Settings
    ${bridge}=    Bridge Path
    ${text}=    Copy Configuration    ${MCP_CLAUDE_DESKTOP_X}
    ${entry}=    Evaluate    json.loads($text)['mcpServers']['jsonquery']    modules=json
    Should Be Equal    ${entry}[command]    ${bridge}
    Should Be Empty    ${entry}[args]
    Should Not Contain    ${text}    ${kept}[token]
    ${desktop}=    Set Variable    ${text}
    ${text}=    Copy Configuration    ${MCP_QUICKAI_X}    ${MCP_ADD_Y2}
    Should Be Equal    ${text}    ${desktop}
    ${entry}=    Evaluate    json.loads($text)['mcpServers']['jsonquery']    modules=json
    Should Be Equal    ${entry}[command]    ${bridge}
    Should Be Empty    ${entry}[args]
    Should Not Contain    ${text}    ${kept}[token]
    Should Not Contain    ${text}    --mcp-servers-json

TC-MCP-017 What Claude Code's Command Holds Reaches The Server
    [Documentation]    The address and the header of the copied command are the server's: an assistant that uses them
    ...    is answered.
    [Tags]    p2
    Open Mcp Panel
    Start Mcp Server From Panel
    ${text}=    Copy Configuration    ${MCP_CLAUDE_CODE_X}
    ${url}=    Evaluate    re.search(r'(http://127\\.0\\.0\\.1:\\d+/mcp)', $text).group(1)    modules=re
    ${token}=    Evaluate    re.search(r'Bearer ([0-9a-f]+)', $text).group(1)    modules=re
    ${port}=    Evaluate    int($url.split(':')[2].split('/')[0])
    ${answer}=    Mcp Initialize    port=${port}    token=${token}
    Should Be Equal    ${answer}[serverInfo][name]    jsonquery

TC-MCP-018 Copied Is Said At The End Of The Last Row For A Few Seconds, And Nothing Moves
    [Documentation]    "✔ Copied" comes after a copy at the end of the second row of buttons, where it moves nothing:
    ...    Stop is where it was, and so are the rows; four seconds later it is gone.
    [Tags]    p2
    Open Mcp Panel
    Start Mcp Server From Panel
    Region Should Not Contain Text    @{MCP_COPIED_AREA}    Copied
    Copy Configuration    ${MCP_CLAUDE_CODE_X}
    Move Mouse To    ${MCP_OUTSIDE_X}    ${MCP_OUTSIDE_Y}
    Wait Until Region Contains Text    @{MCP_COPIED_AREA}    Copied    timeout=2
    Region Should Contain Text    @{MCP_TITLE_ROW}    Stop
    Region Should Contain Text    @{MCP_START_WITH_ROW}    Start it with JsonQuery
    Panel Line Should Say    No assistant has connected yet
    Sleep    4.5s
    Region Should Not Contain Text    @{MCP_COPIED_AREA}    Copied
    Region Should Contain Text    @{MCP_TITLE_ROW}    Stop

TC-MCP-019 Without jsonquery-mcp Beside The App, Claude Desktop And QuickAI Are Greyed Out And Say Why
    [Documentation]    An app whose folder has no `jsonquery-mcp` cannot hand it to the assistants that start it: their
    ...    buttons are dim, copy nothing, and say on hover where the program comes from; the others still copy.
    [Tags]    p1
    [Setup]    Launch Lonely Mcp App
    Open Mcp Panel
    Start Mcp Server From Panel
    Set Clipboard    nothing was copied
    Click At    ${MCP_CLAUDE_DESKTOP_X}    ${MCP_ADD_Y}
    Click At    ${MCP_QUICKAI_X}    ${MCP_ADD_Y2}
    Sleep    0.5s
    ${text}=    Get Clipboard
    Should Be Equal    ${text}    nothing was copied
    Move Mouse To    ${MCP_CLAUDE_DESKTOP_X}    ${MCP_ADD_Y}
    Sleep    1.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    440    540    760    80    is not beside JsonQuery
    Region Should Contain Text    440    540    760    80    each release
    ${text}=    Copy Configuration    ${MCP_CLAUDE_CODE_X}
    Should Start With    ${text}    claude mcp add

TC-MCP-020 Start It With JsonQuery Is Kept, And The Next Start Of The App Starts The Server
    [Tags]    p1
    Open Mcp Panel
    Click At    ${MCP_START_WITH_X}    ${MCP_START_WITH_Y}
    Wait Until Mcp Setting Is    start_with_app    true
    Close Mcp Panel
    Mcp Server Should Not Answer    port=${MCP_PORT}
    Close Jsonquery App    keep_home=${True}
    Launch Jsonquery App    keep_home=${True}
    Wait Until Mcp Server Answers    timeout=8    port=${MCP_PORT}
    Plug Should Not Be Green
    Make An Assistant Call
    Plug Should Be Green

TC-MCP-021 Without It, The Next Start Leaves The Server Off, Even If It Ran When The App Was Closed
    [Tags]    p1
    Start Mcp Server
    Close Jsonquery App    keep_home=${True}
    Launch Jsonquery App    keep_home=${True}
    Sleep    1.5s
    Mcp Server Should Not Answer    port=${MCP_PORT}
    Plug Should Not Be Green
    Open Mcp Panel
    Panel Line Should Say    Not running

TC-MCP-022 The Panel Names The Assistant That Connected And Counts Its Calls
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    Panel Line Should Say    No assistant has connected yet
    Mcp Initialize    client=Robot assistant    version=2.5
    Panel Line Should Say    Connected: Robot assistant 2.5
    Panel Line Should Say    No calls yet
    Mcp Tool Should Succeed    get_state
    Panel Line Should Say    1 call
    Mcp Tool Should Succeed    query_help    {"language": "jq", "topic": "select"}
    Mcp Tool Should Succeed    get_state
    Panel Line Should Say    3 calls
    Mcp Initialize    client=Second helper    version=1.0
    Panel Line Should Say    Connected: Second helper 1.0
    Panel Line Should Say    Robot assistant 2.5

TC-MCP-023 The Last Calls Are Listed Newest First, A Refused One In Red
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    Mcp Initialize
    Mcp Tool Should Succeed    get_state
    Mcp Tool Should Fail    set_query    {"query": "."}
    Mcp Tool Should Succeed    workspace_list
    # OCR reads "workspace_list" without its underscore.
    Call Row Should Say    1    workspace
    Call Row Should Say    2    set_query
    Call Row Should Say    3    get_state
    Call Row Should Not Be Red    1
    Call Row Should Be Red    2
    Call Row Should Not Be Red    3
    Region Should Not Contain Text    712    711    394    40    get_state

TC-MCP-024 Only The Last Five Calls Are Listed, All Of Them Counted
    [Tags]    p3
    Open Mcp Panel
    Start Mcp Server From Panel
    Mcp Initialize
    Mcp Tool Should Succeed    workspace_list
    Mcp Tool Should Succeed    workspace_list
    FOR    ${i}    IN RANGE    5
        Mcp Tool Should Succeed    get_state
    END
    Panel Line Should Say    7 calls
    Call Row Should Say    5    get_state
    Region Should Not Contain Text    @{MCP_CALL_ROWS}    workspace

TC-MCP-025 New Token: The Old One Is Refused, The New One Taken, And The Server Goes On
    [Documentation]    New token makes another, keeps it in mcp.json, and the running server takes only that one from
    ...    then on; it stays running on the same port.
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    ${before}=    Mcp Settings
    Click At    ${MCP_NEW_TOKEN_X}    ${MCP_NEW_TOKEN_Y}
    Wait Until Keyword Succeeds    10x    0.3s    Token Should Have Changed    ${before}[token]
    Wait Until Mcp Server Answers    timeout=5    port=${MCP_PORT}
    ${old}=    Mcp Post    {"jsonrpc": "2.0", "id": 1, "method": "ping"}    token=${before}[token]
    Should Be Equal As Integers    ${old}[status]    401
    ${now}=    Mcp Settings
    ${new}=    Mcp Post    {"jsonrpc": "2.0", "id": 2, "method": "ping"}    token=${now}[token]
    Should Be Equal As Integers    ${new}[status]    200
    Region Should Contain Text    @{MCP_TITLE_ROW}    Stop
    Make An Assistant Call    token=${now}[token]
    Plug Should Be Green

TC-MCP-026 The Token Is Kept Between Starts Of The App
    [Tags]    p2
    Start Mcp Server
    ${before}=    Mcp Settings
    Close Jsonquery App    keep_home=${True}
    Launch Jsonquery App    keep_home=${True}
    Start Mcp Server
    ${after}=    Mcp Settings
    Should Be Equal    ${after}[token]    ${before}[token]
    Mcp Initialize    token=${before}[token]

TC-MCP-027 A Request Without The Token, From A Web Page Or For Another Host Is Refused
    [Documentation]    What keeps other programs and web pages from the server, seen from outside: no token is 401, an
    ...    Origin that is not the server's own is 403 and a Host that is not 127.0.0.1 is 403; with all of it right
    ...    the same request is answered.
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    ${ping}=    Set Variable    {"jsonrpc": "2.0", "id": 1, "method": "ping"}
    ${r}=    Mcp Post    ${ping}    send_token=${False}
    Should Be Equal As Integers    ${r}[status]    401
    ${r}=    Mcp Post    ${ping}    token=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
    Should Be Equal As Integers    ${r}[status]    401
    &{origin}=    Create Dictionary    Origin=https://example.com
    ${r}=    Mcp Post    ${ping}    headers=${origin}
    Should Be Equal As Integers    ${r}[status]    403
    &{host}=    Create Dictionary    Host=example.com
    ${r}=    Mcp Post    ${ping}    headers=${host}
    Should Be Equal As Integers    ${r}[status]    403
    ${r}=    Mcp Post    ${ping}
    Should Be Equal As Integers    ${r}[status]    200
    Panel Line Should Say    No calls yet

TC-MCP-028 A Spinner Turns Beside The Plug While An Assistant's Call Runs
    [Documentation]    While a call is being answered something turns at the left of the 🔌 (where nothing is drawn
    ...    otherwise), and it is gone when the answer has gone back.
    [Tags]    p2
    [Setup]    Launch Mcp App Serving    access=read
    Load Fixture Via Paste    [1]
    Nothing Should Be Drawn At    ${MCP_LEFT_OF_PLUG_X}
    ${call}=    Start Mcp Call    run_query    {"query": "[range(40000000)] | length", "timeout_ms": 60000}
    Wait Until Keyword Succeeds    20x    0.25s    Something Should Be Drawn At    ${MCP_LEFT_OF_PLUG_X}
    Plug Should Be Green
    ${result}=    Wait For Mcp Call    ${call}    timeout=90
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Wait Until Keyword Succeeds    10x    0.3s    Nothing Should Be Drawn At    ${MCP_LEFT_OF_PLUG_X}

TC-MCP-029 Closing The App Stops The Server
    [Tags]    p2
    Start Mcp Server
    ${quit}=    Quit Jsonquery App
    Should Be True    ${quit}
    Mcp Server Should Not Answer    port=${MCP_PORT}

TC-MCP-030 An mcp.json That Cannot Be Used Is Said In The Panel, And The Defaults Stand In
    [Documentation]    A port that is not a number and an access that is not one: the panel says, in red, which could
    ...    not be used; the defaults are used for them (port 7457, Read), and a start on another port clears
    ...    the message.
    [Tags]    p2
    [Setup]    Launch With Damaged Mcp Json
    Open Mcp Panel
    Panel Line Should Say    port, access could not be used    region=${MCP_STATUS_LINE}
    Region Should Contain Color    @{MCP_STATUS_LINE}    @{MCP_ERROR_COLOR}    tolerance=30
    Radio Should Be Chosen    ${MCP_READ_X}
    Region Should Contain Text    @{MCP_ADDRESS_ROW}    7457
    ${port}=    Free Port
    Click At    ${MCP_PORT_X}    ${MCP_PORT_Y}
    Press Keys    ctrl    a
    Type Text    ${port}
    Set Test Variable    ${MCP_PORT}    ${port}
    Start Mcp Server From Panel
    Panel Line Should Say    No assistant has connected yet    region=${MCP_STATUS_LINE}
    Region Should Not Contain Color    @{MCP_STATUS_LINE}    @{MCP_ERROR_COLOR}    tolerance=30
    Wait Until Mcp Setting Is    port    ${port}
    Wait Until Mcp Setting Is    access    read

TC-MCP-031 With The Tools Docked The Button Stays Beside The Settings Button, The Undock Button Left Of It
    [Documentation]    Docked, the 🗗 that undocks the Tools comes left of the MCP button, which stays where it is with the
    ...    Tools in a window, beside the ⚙: its panel opens where it always does, and works, and an assistant's call
    ...    turns the button green there.
    [Tags]    p2
    [Setup]    Launch Mcp App    settings={"tools": "docked"}    start_with_app=${True}
    Wait Until Mcp Server Answers    timeout=8    port=${MCP_PORT}
    Something Should Be Drawn At    ${MCP_PLUG_X}
    Something Should Be Drawn At    ${MCP_UNDOCK_X}
    Nothing Should Be Drawn At    ${MCP_LEFT_OF_UNDOCK_X}
    # Which is which, before anything is clicked (a click on the 🗗 would undock the Tools): an assistant's call turns
    # the button beside the ⚙ green, and the one left of it stays as it was.
    Make An Assistant Call
    Plug Should Be Green
    ${left}=    Evaluate    int(${MCP_UNDOCK_X}) - 10
    Region Should Not Contain Color    ${left}    781    20    16    @{MCP_ON_COLOR}    tolerance=40
    Open Mcp Panel
    Region Should Contain Text    @{MCP_TITLE_ROW}    Stop
    Close Mcp Panel
    Something Should Be Drawn At    ${MCP_UNDOCK_X}

TC-MCP-032 Answers: A Size Chosen Is Said In Tokens, Kept, And Used From The Next Call
    [Documentation]    Answers → 8 while the server runs: the row fills 8 and says about 2,000 tokens, mcp.json keeps it,
    ...    and the next answer that has more than that is a page of at most 8 KB that says where the next starts;
    ...    the next start of the app has 8 too.
    [Tags]    p1
    [Setup]    Launch Mcp App Serving    access=read
    Load Fixture Via Paste    ${{ json.dumps([{"id": i, "name": "name %d" % i, "note": "x" * 40} for i in range(400)]) }}
    Open Mcp Panel
    Choose Answer Size    8
    Answer Size Should Be Chosen    8
    Tokens Should Say    2
    Close Mcp Panel
    ${page}=    Call Mcp Tool    read_value    {"limit": 1000}
    Should Not Be True    ${page}[error]    msg=${page}[text]
    ${bytes}=    Get Length    ${page}[text]
    Should Be True    4000 < ${bytes} <= 8000    msg=The page is ${bytes} bytes
    Should Be True    0 < ${page}[value][next_offset] < 400    msg=${page}[value]
    Close Jsonquery App    keep_home=${True}
    Launch Jsonquery App    keep_home=${True}
    Open Mcp Panel
    Answer Size Should Be Chosen    8

TC-MCP-033 Always Allow Is Greyed Out With Read, Is Ticked With Edit, And Is Kept
    [Documentation]    With Read a click on "Always allow" does nothing (Read asks nothing); with Edit it ticks the box,
    ...    and mcp.json keeps it; a second click unticks it.
    [Tags]    p1
    Open Mcp Panel
    Start Mcp Server From Panel
    Click Always Allow
    Always Allow Should Not Be Ticked
    ${kept}=    Mcp Settings
    Should Not Be True    ${kept}[always_allow]
    Choose Access    edit
    Click Always Allow
    Always Allow Should Be Ticked
    Wait Until Mcp Setting Is    always_allow    ${True}
    Click Always Allow
    Always Allow Should Not Be Ticked
    Wait Until Mcp Setting Is    always_allow    ${False}

TC-MCP-034 An Assistant's Call Turns The Button Green, Not The Server Or The Handshake
    [Documentation]    The server running, and an assistant's handshake made, the button is grey: no assistant works with
    ...    the app yet. The call of a tool turns it green (through jsonquery-mcp too, TC-MCP-077).
    [Tags]    p1
    [Setup]    Launch Mcp App    access=read    start_with_app=${True}
    Wait Until Mcp Server Answers    timeout=8    port=${MCP_PORT}
    Plug Should Not Be Green
    Mcp Initialize
    Sleep    1s
    Plug Should Not Be Green
    ${result}=    Call Mcp Tool    get_state
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Plug Should Be Green

TC-MCP-035 Hovering The Green Button Says That An Assistant Is Working With The App
    [Documentation]    While it is green the tooltip says so, and where the server is: still two lines.
    [Tags]    p2
    [Setup]    Launch Mcp App    access=read    start_with_app=${True}
    Wait Until Mcp Server Answers    timeout=8    port=${MCP_PORT}
    Make An Assistant Call
    Plug Should Be Green
    Move Mouse To    ${MCP_PLUG_X}    ${MCP_BAR_Y}
    Sleep    1.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{WORKING_TIP}    is working with the app
    # The address up to its port: OCR reads the /mcp: after some ports as /mcep: (the same address, whole, is
    # read in the panel in TC-MCP-005).
    Region Should Contain Text    @{WORKING_TIP}    127.0.0.1:${MCP_PORT}/m
    Region Should Contain Text    @{WORKING_TIP}    click for its settings
    Region Should Not Contain Text    @{MCP_ABOVE_TIP}    MCP

TC-MCP-036 A Minute After The Last Call The Button Is Grey Again, And The Next Call Turns It Green
    [Documentation]    Green while the assistant works: its calls come seconds or a minute apart. A minute after the last
    ...    one the button is grey, with the server still on; another call turns it green again.
    [Tags]    p3    slow
    [Setup]    Launch Mcp App    access=read    start_with_app=${True}
    Wait Until Mcp Server Answers    timeout=8    port=${MCP_PORT}
    Make An Assistant Call
    Plug Should Be Green
    Sleep    45s
    Plug Should Be Green
    Wait Until Plug Is Grey    timeout=25
    Wait Until Mcp Server Answers    timeout=3    port=${MCP_PORT}
    ${result}=    Call Mcp Tool    get_state
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Plug Should Be Green

TC-MCP-037 QuickAI's Button Says Where Its Entry Goes And Where QuickAI Is
    [Documentation]    On hover: the entry is pasted in QuickAI's MCP servers, and QuickAI is at quickai.everybodyai.dev.
    [Tags]    p2
    Open Mcp Panel
    Start Mcp Server From Panel
    Move Mouse To    ${MCP_QUICKAI_X}    ${MCP_ADD_Y2}
    Sleep    1.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{QUICKAI_TIP}    paste in
    # (OCR reads the I of "QuickAI's" as an l: the words around it are read.)
    Region Should Contain Text    @{QUICKAI_TIP}    MCP servers
    Region Should Contain Text    @{QUICKAI_TIP}    quickai.everybodyai.dev

TC-MCP-038 The Build Without MCP Has No MCP Button, And The Others Are Where They Always Are
    [Documentation]    The build of the _nomcp downloads (--no-default-features): ⓘ, 🌐 and ⚙ where they are in every build,
    ...    nothing beside the ⚙, a click there opens nothing, and no mcp.json is written.
    [Tags]    p1
    [Setup]    Launch Jsonquery App    build=nomcp
    Wait Until Keyword Succeeds    10x    0.3s    Something Should Be Drawn At    1181
    Something Should Be Drawn At    1152
    Something Should Be Drawn At    1123
    Nothing Should Be Drawn At    ${MCP_PLUG_X}
    Nothing Should Be Drawn At    ${MCP_LEFT_OF_PLUG_X}
    Click At    ${MCP_PLUG_X}    ${MCP_BAR_Y}
    Sleep    0.6s
    Region Should Not Contain Text    @{MCP_TITLE_ROW}    MCP server
    ${home}=    App Home
    File Should Not Exist    ${home}${/}mcp.json

*** Keywords ***
Token Should Have Changed
    [Arguments]    ${before}
    ${now}=    Mcp Settings
    Should Not Be Equal    ${now}[token]    ${before}
    Should Match Regexp    ${now}[token]    ^[0-9a-f]{64}$

Launch Lonely Mcp App
    ${binary}=    Mcp Build Without Bridge
    Launch Mcp App    build=${binary}

Launch With Damaged Mcp Json
    &{files}=    Create Dictionary    mcp.json={"port": "seven", "access": "everything"}
    Launch Jsonquery App    home_files=${files}
    Set Test Variable    ${MCP_PORT}    7457
