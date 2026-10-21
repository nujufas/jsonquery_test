*** Settings ***
Documentation     The pane with another pane of the window in a window of its own: the Query pane out of the main window has
...               the button beside Run as well, and what the pane opens goes to the pane where it is now -- see
...               docs/25_workspace.md. The windows are real X windows: after `Switch To Window` every click and read is
...               relative to that window until `Switch To Main Window` (suites/popout has the details).
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace    panes
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Close Jsonquery App

*** Variables ***
${MAIN_WINDOW}            JsonQuery
${QUERY_WINDOW}           JsonQuery — Query
${SOURCE_WINDOW}          JsonQuery — Source
# The pop-out icons in the main window with the pane open: the Query's is at the right end of the window, the Source's
# at the right end of its own pane (the pane takes 256 of the left).
${QUERY_POP_X}            1184
${QUERY_POP_Y}            39
${SOURCE_POP_X}           711
${SOURCE_POP_Y}           143
# The header row of the Query window, and its box (window-relative).
@{QUERY_WINDOW_HEADER}    0      4      420    28
@{QUERY_WINDOW_BOX}       0      24     760    60
# What the Source window shows under its header, and the arrow of the first row of a loaded array's first member
# (window-relative): a click on it opens the member, which has a name in it.
@{SOURCE_WINDOW_CONTENT}    0    52     600    160
${SOURCE_MEMBER_X}        28
${SOURCE_MEMBER_Y}        83

*** Test Cases ***
TC-WSP-240 The Button Beside Run Saves The Query From The Pane In Its Own Window
    [Documentation]    The Query pane in a window of its own has the button too. The window that saves is the main
    ...    window's, and the app brings that window in front of the other one by itself (without that nothing seems
    ...    to happen: the window that saves is behind the one that was clicked): what was typed in the window is what
    ...    is saved.
    [Tags]    p2
    Click At    ${QUERY_POP_X}    ${QUERY_POP_Y}
    Wait Until Window Exists    ${QUERY_WINDOW}
    Switch To Window    ${QUERY_WINDOW}
    Click At    100    100
    Sleep    0.3s
    Type Text    .popped
    Wait Until Keyword Succeeds    6x    0.5s    Click Text In Region    @{QUERY_WINDOW_HEADER}    Save
    Wait Until Keyword Succeeds    6x    0.5s    Active Window Title Should Be    ${MAIN_WINDOW}
    Switch To Main Window
    Set Form Kind    save
    Form Should Be Open    new folder in it
    Type Name In Form    fromwindow
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    fromwindow.jq    .popped
    List Should Show    fromwindow

TC-WSP-241 An Item Opened From The Pane Goes To The Query Pane That Is In Its Own Window
    [Documentation]    Double click on a query: the Query pane is in its window now, and the text is in the box there.
    [Tags]    p2
    Close Jsonquery App
    ${files}=    Evaluate    {**$STANDARD, "probe.jq": ".platypus_count"}
    Launch Workspace App    files=${files}
    Click At    ${QUERY_POP_X}    ${QUERY_POP_Y}
    Wait Until Window Exists    ${QUERY_WINDOW}
    # Rows: Logs, Errors, logins, Services, orders, update, probe, scratch.
    Double Click Row    6
    Switch To Window    ${QUERY_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{QUERY_WINDOW_BOX}    platypus
    ...    flatten_tints=${True}
    Switch To Main Window
    Region Should Not Contain Text    264    60    400    40    platypus

TC-WSP-242 A Document Opened From The Pane Goes To The Source Pane That Is In Its Own Window
    [Documentation]    Open as Source in the menu of a document: the Source pane is in a window of its own, and the
    ...    document is loaded there.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${WITH_DOCUMENT}
    Click At    ${SOURCE_POP_X}    ${SOURCE_POP_Y}
    Wait Until Window Exists    ${SOURCE_WINDOW}
    # Rows: Logs, Errors, logins, Services, orders, update, people, scratch.
    Pick Row Menu Item    6    Open as Source
    Switch To Window    ${SOURCE_WINDOW}
    Sleep    1.0s
    Click At    ${SOURCE_MEMBER_X}    ${SOURCE_MEMBER_Y}
    Wait Until Keyword Succeeds    8x    0.6s    Region Should Contain Text    @{SOURCE_WINDOW_CONTENT}    Ana
    ...    flatten_tints=${True}
    Switch To Main Window

TC-WSP-283 A Query File Dropped On The Query Pane That Is In Its Own Window Goes In The Box There
    [Documentation]    The pane is a window of its own now, and it takes the file let go on it as the main window does: the name of the
    ...    file says that it is a query, so the text is in the box of that window and not in the main window's.
    [Tags]    p2
    Click At    ${QUERY_POP_X}    ${QUERY_POP_Y}
    Wait Until Window Exists    ${QUERY_WINDOW}
    ${folder}=    Make Temp Directory
    Create File    ${folder}${/}probe.jq    .platypus_count
    Switch To Window    ${QUERY_WINDOW}
    Drop Files On Window    300    60    ${folder}${/}probe.jq
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{QUERY_WINDOW_BOX}    platypus
    ...    flatten_tints=${True}
    Switch To Main Window
    Region Should Not Contain Text    264    60    400    40    platypus

TC-WSP-284 A Query Carried Out Of The List Opens Nothing While The Query Pane Is In A Window Of Its Own
    [Documentation]    The pane that a query would be put down on is not in the main window: where it was, the window shows the Source
    ...    and the Results, which take nothing, so the row is not opened there and not opened in the window either.
    [Tags]    p2
    Close Jsonquery App
    ${files}=    Evaluate    {**$STANDARD, "probe.jq": ".platypus_count"}
    Launch Workspace App    files=${files}
    Click At    ${QUERY_POP_X}    ${QUERY_POP_Y}
    Wait Until Window Exists    ${QUERY_WINDOW}
    Switch To Main Window
    ${index}=    Workspace Index
    # Rows: Logs, Errors, logins, Services, orders, update, probe, scratch.
    Carry Row To    6    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Region Should Not Contain Color    256    23    944    5    192    222    255    tolerance=10    msg=Something is outlined where the pane was
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Workspace Files Should Not Have Changed    ${index}
    Switch To Window    ${QUERY_WINDOW}
    Region Should Not Contain Text    @{QUERY_WINDOW_BOX}    platypus    flatten_tints=${True}
    Switch To Main Window

*** Keywords ***
Active Window Title Should Be
    [Documentation]    The window that has the focus on the test display is this one (the app brought it forward by
    ...    itself: no `Switch To Window` has been made).
    [Arguments]    ${title}
    ${active}=    Active Window Title
    Should Be Equal    ${active}    ${title}    msg=The window in front is "${active}"
