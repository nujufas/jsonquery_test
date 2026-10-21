*** Settings ***
Documentation     A query carried out of the list of the pane and put down on the Query pane is opened, as a double click on it opens
...               it -- see docs/25_workspace.md. While it is carried over the pane the pane has the bright outline that a folder
...               has while a row would go into it, and the label beside the pointer says what letting go would do; a schema, a
...               patch, a document and a folder are not opened that way, the Escape key puts the carried row down where
...               it was, and a row that is taken back over the list is moved as it always was. The mouse is the real one (the
...               left button pressed on a row, the pointer taken to the place over half a second), as in workspace_move.robot.
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace    carry
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Release And Close

*** Variables ***
# Where the label of what is carried is, beside the pointer: to the right of it and a little below.
${GHOST_WIDTH}            340
${GHOST_HEIGHT}           60

*** Test Cases ***
TC-WSP-271 A Query Carried Onto The Query Pane Lights It, Says What It Opens As, And Is Opened When It Is Let Go
    [Documentation]    The pane is outlined and the label says `Open “logins” as the query` while the button is down; when it is let go
    ...    the box has the text of the item and its engine (JMESPath: the name ends .jmespath), the item is picked, the Query row says
    ...    where the box came from, what was in the box is gone, and the file has not moved.
    [Tags]    p1
    Type In Query Box    .old
    ${index}=    Workspace Index
    Query Pane Should Not Be Lit
    Carry Row To    ${ROW_LOGINS}    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Query Pane Should Be Lit
    ${top}=    Evaluate    ${WS_QUERY_Y} + 6
    Wait Until Region Matches    ${WS_QUERY_X}    ${top}    ${GHOST_WIDTH}    ${GHOST_HEIGHT}    Open .{0,2}[lI|1]ogins.{0,2} ?as ?the ?query    timeout=5
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Query Pane Should Not Be Lit
    Region Should Not Contain Text    ${WS_QUERY_X}    ${top}    ${GHOST_WIDTH}    ${GHOST_HEIGHT}    as the query
    Query Box Should Hold    ${LOGINS_TEXT}
    Engine Chip Should Be Selected    jmespath
    Row Should Be Selected    ${ROW_LOGINS}
    Wait Until Region Matches    @{WS_QUERY_ROW}    Logs +/ +logins\\.jm    timeout=4
    Workspace File Should Exist    Logs/logins.jmespath
    Workspace Files Should Not Have Changed    ${index}

TC-WSP-272 Each Language Is Opened In Its Own Engine, As A Double Click Opens It
    [Documentation]    A name that ends .jsonpath is a JSONPath query and one that ends .jsonptr is a JSON Pointer.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${ENGINES}
    # Rows: Logs, Errors, logins, Services, orders, update, paths, ptr, scratch.
    Carry Row To    6    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Query Box Should Hold    $.a
    Engine Chip Should Be Selected    jsonpath
    Carry Row To    7    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Query Box Should Hold    /a
    Engine Chip Should Be Selected    pointer
    Engine Chip Should Not Be Selected    jsonpath

TC-WSP-273 A Schema Or A Patch Carried Onto The Query Pane Is Not Lit And Is Not Opened
    [Documentation]    Only a query is opened as the query: over the pane a schema and a patch are carried as over any place that
    ...    takes nothing, and let go there they stay where they are.
    [Tags]    p1
    Type In Query Box    .keep
    ${index}=    Workspace Index
    Carry Row To    ${ROW_ORDERS}    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Query Pane Should Not Be Lit
    ${top}=    Evaluate    ${WS_QUERY_Y} + 6
    Region Should Not Contain Text    ${WS_QUERY_X}    ${top}    ${GHOST_WIDTH}    ${GHOST_HEIGHT}    as the query
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Query Box Should Hold    .keep
    Carry Row To    ${ROW_UPDATE}    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Query Pane Should Not Be Lit
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Query Box Should Hold    .keep
    Workspace Files Should Not Have Changed    ${index}

TC-WSP-274 A Folder Carried Onto The Query Pane Is Not Lit And Is Not Opened
    [Tags]    p2
    Type In Query Box    .keep
    ${index}=    Workspace Index
    Carry Row To    ${ROW_LOGS}    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Query Pane Should Not Be Lit
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Query Box Should Hold    .keep
    Workspace Files Should Not Have Changed    ${index}

TC-WSP-275 A Document Carried Onto The Query Pane Is Not Lit And Is Not Opened
    [Documentation]    A document is opened as the Source, by a double click or the menu: not by being put down on the Query pane.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${WITH_DOCUMENT}
    Type In Query Box    .keep
    # Rows: Logs, Errors, logins, Services, orders, update, people, scratch.
    Carry Row To    6    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Query Pane Should Not Be Lit
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Query Box Should Hold    .keep
    Region Should Contain Text    @{WS_SOURCE_PANEL}    Paste JSON here

TC-WSP-276 Escape While A Query Is Over The Query Pane Opens Nothing
    [Documentation]    The key puts what is carried down: the outline goes at once, and the button let go afterwards opens nothing.
    [Tags]    p1
    Type In Query Box    .keep
    Carry Row To    ${ROW_LOGINS}    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Query Pane Should Be Lit
    Press Key    escape
    Sleep    0.6s
    Query Pane Should Not Be Lit
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Query Box Should Hold    .keep
    Workspace File Should Exist    Logs/logins.jmespath

TC-WSP-277 A Query Taken Over The Query Pane And Back Over A Folder Is Moved As Before
    [Documentation]    The Query pane is only one of the places that the row passes: over a folder again the folder is lit and the
    ...    pane is not, and the row goes into the folder.
    [Tags]    p1
    Type In Query Box    .keep
    Carry Row To    ${ROW_SCRATCH}    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Query Pane Should Be Lit
    ${y}=    Row Y    ${ROW_SERVICES}
    Move Mouse Slowly To    ${WS_ROW_X}    ${y}    duration=0.6
    Query Pane Should Not Be Lit
    Row Should Be Lit    ${ROW_SERVICES}
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Workspace File Should Be    Services/scratch.jq    ${SCRATCH_TEXT}
    Workspace File Should Not Exist    scratch.jq
    Query Box Should Hold    .keep

TC-WSP-278 A Press That Is Not Carried Anywhere Opens Nothing
    [Documentation]    A click on a query only picks it (TC-WSP-096), and a press that moves a little is a click: neither opens
    ...    the query, nor puts it on the Query pane.
    [Tags]    p3
    Type In Query Box    .keep
    ${y}=    Row Y    ${ROW_LOGINS}
    Click With Wobble    ${WS_ROW_X}    ${y}    3    2
    Move Mouse To    600    400
    Query Pane Should Not Be Lit
    Row Should Be Selected    ${ROW_LOGINS}
    Query Box Should Hold    .keep

TC-WSP-290 A Query That Has A Sample Is Opened Without It When It Is Carried Onto The Query Pane
    [Documentation]    The sample is the other way to open a query (the button under the list): carried onto the Query pane the query
    ...    goes in the box and the Source is left as it was, empty, and nothing is run.
    [Tags]    p2
    Click Row    ${ROW_ERRORS}
    # Rows: Logs, Errors, failures, logins, Services, orders, update, scratch.
    Carry Row To    2    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Query Box Should Hold    ${FAILURES_TEXT}
    Region Should Contain Text    @{WS_SOURCE_PANEL}    Paste JSON here
    Region Should Not Contain Text    @{WS_STATUS_LINE}    result(s)
