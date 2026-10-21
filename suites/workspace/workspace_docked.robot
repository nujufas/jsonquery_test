*** Settings ***
Documentation     The workspace pane with the Tools docked in the main window as tabs: the pane is under the row of
...               tabs, and its chips follow the page that is in front (Validate narrows the list to the schemas,
...               Patch to the patches, Json Query to everything) -- see docs/25_workspace.md and
...               docs/22_tools_docked.md.
Resource          ../../resources/workspace.resource
Resource          ../../resources/docked.resource
Library           OperatingSystem
Force Tags        workspace    docked
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Docked Workspace
Test Teardown     Close Jsonquery App

*** Variables ***
# The chips are at y=81 of the pane, which is under the row of tabs (23 high): 104 in the window.
${CHIPS_Y_DOCKED}         104
${DOCKED_AND_OPEN}        {"tools": "docked", "workspace": {"pane": "open"}}
# The page of a tool in the main window with the pane open: the box of the Format page is at the right of the pane (the first
# line of what is in it is at the top left of the box), and the status line of the page is at the foot of the window.
${PAGE_BOX_X}             500
${PAGE_BOX_Y}             400
@{PAGE_BOX_TOP}           264    76     430    24
@{PAGE_STATUS}            36     779    964    20
# The window the pane is in front of, with the page of a tool: where a query carried out of the list could be put down if the
# Query pane were there. The pane's rows are under the row of tabs, as ever, so the library's move of 23 is on while they are used.
${QUERY_PANE_X}           600
${QUERY_PANE_Y}           80

*** Test Cases ***
TC-WSP-210 With The Tools Docked The Pane Is Under The Row Of Tabs
    [Tags]    p1
    Row Of Tabs Should Be There
    Without Layout Shift    Region Should Contain Text    0    31    140    20    Workspace
    Without Layout Shift    New Folder Icon Should Be At    ${WS_NEWFOLDER_ICON_LEFT}    35

TC-WSP-211 The Chips Follow The Page That Is In Front
    [Documentation]    The Validate page uses schemas and the Patch page patches: the list is narrowed to them when the page
    ...    comes to the front, once; the Json Query tab brings everything back.
    [Tags]    p1
    Without Layout Shift    Chip Should Be Picked    ${WS_CHIP_ALL_X}
    Show Docked Tab    validate
    Without Layout Shift    Chip Should Be Picked    ${WS_CHIP_SCHEMAS_X}
    Without Layout Shift    Chip Should Not Be Picked    ${WS_CHIP_ALL_X}
    Show Docked Tab    patch
    Without Layout Shift    Chip Should Be Picked    ${WS_CHIP_PATCHES_X}
    Show Docked Tab    json
    Without Layout Shift    Chip Should Be Picked    ${WS_CHIP_ALL_X}

TC-WSP-212 A Chip That Was Picked By Hand Stays While The Same Page Is In Front
    [Tags]    p2
    Show Docked Tab    validate
    Without Layout Shift    Click At    ${WS_CHIP_QUERIES_X}    ${CHIPS_Y_DOCKED}
    Sleep    0.6s
    Without Layout Shift    Chip Should Be Picked    ${WS_CHIP_QUERIES_X}
    Sleep    1.0s
    Without Layout Shift    Chip Should Be Picked    ${WS_CHIP_QUERIES_X}

TC-WSP-279 With The Page Of A Tool In Front The Status Bar Has The Button First And The Text Of The Page After It
    [Documentation]    The Format page says how long it took, in the status bar, as the Json Query tab says its own there: after the
    ...    button, which is where it is with every tab in front.
    [Tags]    p1
    Show Docked Tab    format
    Paste In Page Box    {"b":1,"a":2}
    Press Keys    ctrl    enter
    Wait Until Keyword Succeeds    8x    0.5s    Region Should Contain Text    @{PAGE_STATUS}    Formatted in
    Move Mouse To    600    300
    docked.Icon Should Be At    ${SB_WORKSPACE_X}    ${SB_Y}
    ${left}    ${top}    ${right}    ${bottom}=    Without Layout Shift    Get Ink Bounds    33    779    300    18    threshold=100
    Should Be True    7 <= ${left} <= 11    msg=The text of the page begins ${left} points on from 33, not at 41
    Show Docked Tab    json
    docked.Icon Should Be At    ${SB_WORKSPACE_X}    ${SB_Y}

TC-WSP-280 With The Page Of A Tool In Front A Query File Dropped On The Window Is The Page's And Not The Query Box's
    [Documentation]    The page has its own boxes, which take the files dropped on the window; the query box, which is behind it, does
    ...    not. (The name of the file is the same as for the Json Query tab: .jq.)
    [Tags]    p1
    Show Docked Tab    format
    ${folder}=    Make Temp Directory
    Create File    ${folder}${/}platypus.jq    .platypus_count
    Drop Files On Window    600    400    ${folder}${/}platypus.jq
    Wait Until Keyword Succeeds    8x    0.5s    Without Layout Shift    Region Should Contain Text    @{PAGE_BOX_TOP}    platypus
    Show Docked Tab    json
    Query Box Should Be Empty

TC-WSP-281 With The Page Of A Tool In Front A Query Carried Out Of The List Has No Query Pane To Go On
    [Documentation]    The Query pane is the Json Query tab's: with a page in front there is none to put a query down on, so the row
    ...    is not opened, nothing is said that it would be, and it stays where it is.
    [Tags]    p1
    Show Docked Tab    format
    Set Layout Shift    ${DY}
    ${index}=    Workspace Index
    Carry Row To    ${ROW_LOGINS}    ${QUERY_PANE_X}    ${QUERY_PANE_Y}
    ${top}=    Evaluate    ${QUERY_PANE_Y} + 6
    Region Should Not Contain Text    ${QUERY_PANE_X}    ${top}    340    60    as the query
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Workspace Files Should Not Have Changed    ${index}
    Show Docked Tab    json
    Query Box Should Be Empty

TC-WSP-282 A Query Opened From The List While The Page Of A Tool Is In Front Brings The Json Query Tab Forward
    [Documentation]    The Query pane is the Json Query tab's: a double click on a query shows that tab and puts the query in its
    ...    box, in its language.
    [Tags]    p1
    Show Docked Tab    format
    Set Layout Shift    ${DY}
    Double Click Row    ${ROW_LOGINS}
    Docked Tab Should Be Selected    json
    Query Box Should Hold    ${LOGINS_TEXT}
    Engine Chip Should Be Selected    jmespath

*** Keywords ***
Paste In Page Box
    [Documentation]    The box of the page that is in front holds `text` (pasted).
    [Arguments]    ${text}
    Set Clipboard    ${text}
    Without Layout Shift    Click At    ${PAGE_BOX_X}    ${PAGE_BOX_Y}
    Sleep    0.2s
    Press Keys    ctrl    a
    Press Keys    ctrl    v
    Sleep    0.3s

Launch Docked Workspace
    Launch Jsonquery App    settings=${DOCKED_AND_OPEN}    workspace=${STANDARD}
    Sleep    0.8s

Chip Should Be Picked
    [Arguments]    ${x}
    ${left}=    Evaluate    int(${x}) - 18
    Region Should Contain Color    ${left}    ${{ ${CHIPS_Y_DOCKED} - 8 }}    36    16    0    92    128    tolerance=10
    ...    msg=The chip at ${x} is not picked

Chip Should Not Be Picked
    [Arguments]    ${x}
    ${left}=    Evaluate    int(${x}) - 18
    Region Should Not Contain Color    ${left}    ${{ ${CHIPS_Y_DOCKED} - 8 }}    36    16    0    92    128    tolerance=10
    ...    msg=The chip at ${x} is picked
