*** Settings ***
Documentation     What an assistant allowed to Edit changes of what is kept -- the workspace, files, the Source from a
...               web address -- and the questions the app asks the user first, over the main window: Allow, Always
...               allow, Don't allow (Escape too). See docs/26_mcp_server.md.
...
...               Every app here starts its server with it and allows Edit (mcp.json), unless a case says otherwise,
...               with a workspace of three items, and an assistant has made its handshake. A call that asks is made on
...               a thread of its own (`Start Mcp Call`), as it waits for the answer. A question is found by its
...               buttons' fill (`Question Buttons`: OCR does not read their small labels on the dimmed window), and
...               read by OCR above them.
Resource          ../../resources/mcp.resource
Resource          ../../resources/tools.resource
Force Tags        mcp    undocked-only
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Mcp App Serving    workspace=${WORKSPACE}
Test Teardown     Run Keywords    Stop Fixture Server    AND    Close Jsonquery App

*** Variables ***
&{WORKSPACE}      old.jq=.a    orders/late.jq=.[] | select(.late)    orders/late.sample.json=[{"late": true}]

*** Test Cases ***
TC-MCP-080 Deleting From The Workspace Is Asked First, And Don't Allow Keeps The Item
    [Documentation]    workspace_delete puts a question over the main window -- what the assistant would delete, and
    ...    what it is -- and the call waits. Don't allow: the question goes, the call says it was not done, the file
    ...    is there, and the panel lists the call in red.
    [Tags]    p1
    ${call}=    Start Mcp Call    workspace_delete    {"path": "old.jq"}
    Question Should Ask    An assistant asks    Delete from the workspace    old.jq
    Answer The Question    Don't allow
    ${result}=    Wait For Mcp Call    ${call}
    Should Be True    ${result}[error]
    Should Contain    ${result}[text]    did not allow
    No Question Should Be Shown
    Workspace File Should Exist    old.jq
    Open Mcp Panel
    Call Row Should Say    1    delete
    Call Row Should Be Red    1

TC-MCP-081 Allow Deletes It: A Folder With What Is In It
    [Documentation]    The question says how much a folder holds; Allow deletes the folder and all in it.
    [Tags]    p1
    ${call}=    Start Mcp Call    workspace_delete    {"path": "orders"}
    Question Should Ask    Delete from the workspace    orders    1 item
    Answer The Question    Allow
    ${result}=    Wait For Mcp Call    ${call}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Should Be Equal As Integers    ${result}[value][items]    1
    No Question Should Be Shown
    Workspace File Should Not Exist    orders/late.jq
    Workspace File Should Not Exist    orders/late.sample.json
    Workspace File Should Exist    old.jq

TC-MCP-082 Escape Is Don't Allow
    [Tags]    p2
    ${call}=    Start Mcp Call    workspace_delete    {"path": "old.jq"}
    Question Should Ask    old.jq
    Press Keys    escape
    ${result}=    Wait For Mcp Call    ${call}
    Should Contain    ${result}[text]    did not allow
    No Question Should Be Shown
    Workspace File Should Exist    old.jq

TC-MCP-083 Always Allow In The Question Does It, Ticks The Panel's Box, And Nothing Is Asked After
    [Documentation]    Always allow: this call is done, mcp.json keeps it, the panel's box is ticked, and the next
    ...    delete is done without a question.
    [Tags]    p1
    ${call}=    Start Mcp Call    workspace_delete    {"path": "old.jq"}
    Question Should Ask    old.jq
    Answer The Question    Always allow
    ${result}=    Wait For Mcp Call    ${call}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Workspace File Should Not Exist    old.jq
    Wait Until Mcp Setting Is    always_allow    ${True}
    ${result}=    Call Mcp Tool    workspace_delete    {"path": "orders/late.jq"}    timeout=10
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Workspace File Should Not Exist    orders/late.jq
    Open Mcp Panel
    Always Allow Should Be Ticked

TC-MCP-084 With Always Allow Ticked Nothing Is Asked, And Unticking It Brings The Questions Back
    [Tags]    p2
    [Setup]    Launch Mcp App Serving    workspace=${WORKSPACE}    always_allow=${True}
    ${result}=    Call Mcp Tool    workspace_delete    {"path": "old.jq"}    timeout=10
    Should Not Be True    ${result}[error]    msg=${result}[text]
    No Question Should Be Shown
    Workspace File Should Not Exist    old.jq
    Open Mcp Panel
    Always Allow Should Be Ticked
    Click Always Allow
    Wait Until Mcp Setting Is    always_allow    ${False}
    Close Mcp Panel
    ${call}=    Start Mcp Call    workspace_delete    {"path": "orders/late.jq"}
    Question Should Ask    orders/late.jq
    Answer The Question    Don't allow
    Wait For Mcp Call    ${call}
    Workspace File Should Exist    orders/late.jq

TC-MCP-085 A New Item Is Saved Without A Question, And Replacing One Is Asked First
    [Documentation]    workspace_save makes a query with its sample in a folder it makes, asking nothing; the same name
    ...    again is refused without `replace`, and with it the user is asked, and Allow replaces it.
    [Tags]    p1
    ${saved}=    Mcp Tool Should Succeed    workspace_save
    ...    {"path": "reports/adults", "kind": "query", "content": ".[] | select(.age > 21)", "sample": {"json": [{"age": 30}]}}
    Should Be Equal    ${saved}[saved]    reports/adults.jq
    No Question Should Be Shown    settle=0.2
    Workspace File Should Be    reports/adults.jq    .[] | select(.age > 21)
    Workspace File Should Exist    reports/adults.sample.json
    Mcp Tool Should Fail    workspace_save    {"path": "reports/adults", "kind": "query", "content": ".[0]"}
    ...    expected=replace true
    ${call}=    Start Mcp Call    workspace_save
    ...    {"path": "reports/adults", "kind": "query", "content": ".[0]", "replace": true}
    Question Should Ask    Replace in the workspace    reports/adults.jq
    Answer The Question    Allow
    ${result}=    Wait For Mcp Call    ${call}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Workspace File Should Be    reports/adults.jq    .[0]

TC-MCP-086 Folders Are Made, And Items Moved And Renamed, Without A Question
    [Tags]    p2
    ${made}=    Mcp Tool Should Succeed    workspace_new_folder    {"path": "archive/2026"}
    Should Be Equal    ${made}[made]    ${{ ["archive", "archive/2026"] }}
    ${moved}=    Mcp Tool Should Succeed    workspace_move    {"path": "old.jq", "to": "archive/2026", "name": "first"}
    Should Be Equal    ${moved}[now]    archive/2026/first.jq
    No Question Should Be Shown
    Workspace File Should Be    archive/2026/first.jq    .a
    Workspace File Should Not Exist    old.jq

TC-MCP-087 A File Is Saved After The User Allows It, As Indented As Asked, And Replaced Only With replace
    [Documentation]    save_file asks (the path, and that it is a new file); Allow writes it, four spaces a level.
    ...    One that is there is refused without `replace`; with it the question says it replaces the file.
    [Tags]    p1
    Load Fixture Via Paste    ${{ open($PEOPLE_FIXTURE).read() }}
    ${folder}=    Make Folder With Files    out
    ${path}=    Set Variable    ${folder}/people.json
    ${call}=    Start Mcp Call    save_file    {"input": "document", "path": "${path}", "indent": "4"}
    Question Should Ask    Save a file    people.json    A new file
    Answer The Question    Allow
    ${result}=    Wait For Mcp Call    ${call}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    ${text}=    Get File    ${path}
    Should Start With    ${text}    [\n    {\n        "name": "Alice",
    Mcp Tool Should Fail    save_file    {"input": "document", "path": "${path}"}    expected=replace true
    ${call}=    Start Mcp Call    save_file
    ...    {"input": {"json": [1]}, "path": "${path}", "indent": "minified", "replace": true}
    Question Should Ask    replaces the file that is there
    Answer The Question    Allow
    ${result}=    Wait For Mcp Call    ${call}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    ${text}=    Get File    ${path}
    Should Be Equal    ${text}    [1]

TC-MCP-088 A Web Address Is Loaded As The Source Only When The User Allows It
    [Documentation]    open_url asks; Don't allow fetches nothing; Allow fetches it and it is the Source.
    [Tags]    p1
    ${served}=    Make Folder With Files    served    ${{ {"people.json": open($PEOPLE_FIXTURE).read()} }}
    ${base}=    Start Fixture Server    ${served}
    ${call}=    Start Mcp Call    open_url    {"url": "${base}/people.json"}
    Question Should Ask    Load a web address    people.json
    Answer The Question    Don't allow
    ${result}=    Wait For Mcp Call    ${call}
    Should Be True    ${result}[error]
    Fixture Server Should Have Been Asked For
    ${call}=    Start Mcp Call    open_url    {"url": "${base}/people.json"}
    Answer The Question    Allow
    ${result}=    Wait For Mcp Call    ${call}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Fixture Server Should Have Been Asked For    /people.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=5

TC-MCP-089 A Page Of The Tools Is Shown With The Assistant's Values In Its Boxes, Run
    [Documentation]    show_in_tool on Format: the Tools window shows the page with the value in its box, run, four
    ...    spaces a level.
    [Tags]    p1
    ${shown}=    Mcp Tool Should Succeed    show_in_tool
    ...    {"tool": "format", "inputs": [{"json": {"shown": "by the assistant"}}], "options": {"indent": "4"}}
    Should Contain    ${shown}[shown]    Format
    Wait Until Window Exists    ${TOOLS_WINDOW}
    Tools Window Should Read    by the assistant    @{TOOL_RESULT}

TC-MCP-090 With Read Nothing Is Written, Moved, Deleted, Fetched Or Shown, And Nothing Is Asked
    [Documentation]    Every call that changes what is kept, fetches or shows is refused with a message that says to ask
    ...    the user for Edit; no question comes, and the workspace and the files are as they were.
    [Tags]    p1
    [Setup]    Launch Mcp App Serving    access=read    workspace=${WORKSPACE}
    ${folder}=    Make Folder With Files    out
    Mcp Tool Should Fail    workspace_save    {"path": "x", "kind": "query", "content": "."}    expected=allow "Edit"
    Mcp Tool Should Fail    workspace_new_folder    {"path": "x"}    expected=allow "Edit"
    Mcp Tool Should Fail    workspace_move    {"path": "old.jq", "name": "new"}    expected=allow "Edit"
    Mcp Tool Should Fail    workspace_delete    {"path": "old.jq"}    expected=allow "Edit"
    Mcp Tool Should Fail    save_file    {"input": {"json": 1}, "path": "${folder}/a.json"}    expected=allow "Edit"
    Mcp Tool Should Fail    open_url    {"url": "http://127.0.0.1:9/a.json"}    expected=allow "Edit"
    Mcp Tool Should Fail    show_in_tool    {"tool": "format", "inputs": [{"json": 1}]}    expected=allow "Edit"
    No Question Should Be Shown
    Workspace File Should Exist    old.jq
    Workspace File Should Not Exist    x.jq
    File Should Not Exist    ${folder}/a.json

TC-MCP-091 While A Question Waits The Panel Says So
    [Documentation]    The panel, open when the question comes, says in its first line that an assistant waits for the
    ...    user's answer (the click on the question's button closes the panel, as any click outside it does); once
    ...    the question is answered it says who is connected again.
    [Tags]    p2
    Open Mcp Panel
    ${call}=    Start Mcp Call    workspace_delete    {"path": "old.jq"}
    Panel Line Should Say    An assistant waits for your answer    region=${MCP_STATUS_LINE}
    Answer The Question    Don't allow
    Wait For Mcp Call    ${call}
    Open Mcp Panel
    Panel Line Should Say    Connected: Robot assistant    region=${MCP_STATUS_LINE}
