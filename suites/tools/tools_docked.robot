*** Settings ***
Documentation     The Tools docked in the main window as tabs -- see docs/22_tools_docked.md.
...               The Tools open in a window of their own (the default: the app is for the
...               query, and the window is as it has always been). The ⚓ button at the
...               right end of that window's row of tabs docks them: the window goes and the
...               main window has a row of tabs on top -- Json Query, which is the main view
...               (its source field is the first row under the tabs), then a tab for each tool
...               -- with the theme and the tutorial at its right end. The 🗗 button in the
...               status bar, beside the ⚙, takes them out into a window again, and where they
...               are is kept in settings.json.
...
...               Everything here is read and clicked in the MAIN window, 1200x800, Dark
...               theme. The pages of the tools are the window's own, wider (two panes of 600),
...               and their points are `DT_*` below; the Json Query tab is the main view moved
...               down by the row of tabs, which the library does for the suites' coordinates
...               while `Set Layout Shift` says so (resources/docked_main.py: why, and the points
...               that are not just moved). `Show Docked Tab` is the way to a tab, and it sets
...               the shift for the tab it goes to. The same pages run in the same cases of
...               suites/tools/ with the Tools docked (run with resources/docked_tools.py), and
...               the main view's suites run docked too (resources/docked_main.py); what is here
...               is what only the dock does: the move, the buttons, the places, the keys and
...               the drops, and the things a tool and the Json Query tab do for each other.
Resource          ../../resources/docked.resource
Resource          ../../resources/tools.resource
Library           OperatingSystem
Force Tags        tools    docked
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# Where a button of the row of tabs could be, and is not: the 🛠 of the window, and the place
# the 🗗 had in the row before it was only in the status bar.
${NO_TOOLS_X}        1094
${NO_UNDOCK_X}       1122
# The page of a tool in the main window: the window's page, in two panes of 600. Rows are the
# window's (the command row at y 34, the headers at y 63); the left pane's header buttons are
# at x 591 less what is to their right, the result's at the window's right edge.
${DT_COMMAND_Y}      34
${DT_HEADER_Y}       63
@{DT_COMMAND_ROW}    0      23     640    22
@{DT_LEFT_HEADER}    8      54     220    26
@{DT_INPUT_BOX}      8      76     583    693
@{DT_INPUT_TOP}      8      76     430    24
${DT_BOX_X}          300
${DT_INPUT_Y}        400
${DT_OPEN_DOCUMENT_X}    493
${DT_FORMAT_COPY_X}      1117
${DT_PATCH_COPY_X}       976
${DT_FIRST_Y}        240
${DT_SECOND_Y}       600
${DT_RIGHT_BOX_X}    900
${DT_OPEN_IN_MAIN_X}     1125
${DT_SHOW_IN_MAIN_X}     1125
@{DT_RESULT}         608    74     584    695
# Where the Search dialog is, in the window's own coordinates (on a tool's tab); on the Json Query tab it
# is `POPUP_DIALOG_AREA`, which docked_main.py gives in the suites' coordinates.
@{DT_POPUP_AREA}     15     15     345    150
${DT_DIFF_HEADER_Y}  71
@{DT_DIFF_LEFT_TOP}  16     84     430    24
@{DT_STATUS}         36     779    964    20
${SETTINGS_WINDOW}   JsonQuery — Settings
${ABOUT_WINDOW}      JsonQuery — About
# What the 🌐 hands to the browser: the website's address, as the app's browser crate writes it
# (it adds the slash).
${WEBSITE_ADDRESS}   https://jsonquery.dev/
${MEMBERS_JSON}      {"members":[{"name":"Ann","age":31},{"name":"Bob","age":25}],"team":"platypus"}
${FIXTURES}          ${CURDIR}/../../resources/fixtures

*** Test Cases ***
TC-DOCK-001 The Tools Window Has A Button That Docks It In The Main Window
    [Documentation]    The ⚓ at the right end of the window's row of tabs moves the Tools
    ...    into the main window: the window is gone, and the main window has a row of tabs.
    [Tags]    p1
    Open Tools Window
    Switch To Window    ${TOOLS_WINDOW}
    Icon Should Be At    ${WINDOW_DOCK_X}    ${WINDOW_DOCK_Y}
    Click At    ${WINDOW_DOCK_X}    ${WINDOW_DOCK_Y}
    Wait Until Window Closes    ${TOOLS_WINDOW}    timeout=8
    Switch To Main Window
    Row Of Tabs Should Be There
    ${windows}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${windows}    0

TC-DOCK-002 The Row Of Tabs Has Json Query First And A Tab For Each Tool
    [Documentation]    Json Query, Merge JSON, Format JSON, Diff JSON, Patch JSON and
    ...    Validate Schema, in that order, left to right.
    [Tags]    p1
    Dock From The Window
    ${json}=    Tab Centre    Query
    ${merge}=    Tab Centre    Merge
    ${format}=    Tab Centre    Format
    ${diff}=    Tab Centre    Diff
    ${patch}=    Tab Centre    Patch
    ${validate}=    Tab Centre    Validate
    Should Be True    ${json} < ${merge} < ${format} < ${diff} < ${patch} < ${validate}
    ...    msg=The tabs are not in order: ${json} ${merge} ${format} ${diff} ${patch} ${validate}

TC-DOCK-003 The Tool That Was In Front In The Window Is In Front Docked
    [Documentation]    The window was on Diff; docked, the Diff tab is the one marked and the
    ...    page is Diff's (its Documents / Side by side views in the command row).
    [Tags]    p1
    Open Tool    diff
    Switch To Window    ${TOOLS_WINDOW}
    Click At    ${WINDOW_DOCK_X}    ${WINDOW_DOCK_Y}
    Wait Until Window Closes    ${TOOLS_WINDOW}    timeout=8
    Switch To Main Window
    Docked Tab Should Be Selected    diff
    Docked Tab Should Not Be Selected    json
    Docked Tab Should Not Be Selected    merge
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{DT_COMMAND_ROW}    Side by side

TC-DOCK-004 What Was Typed In A Page Is Still There Docked
    [Documentation]    The pages are the same pages: what was typed into Format's box in the
    ...    window is in its box in the tab.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"keep":"platypus"}
    Switch To Window    ${TOOLS_WINDOW}
    Click At    ${WINDOW_DOCK_X}    ${WINDOW_DOCK_Y}
    Wait Until Window Closes    ${TOOLS_WINDOW}    timeout=8
    Switch To Main Window
    Docked Tab Should Be Selected    format
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{DT_INPUT_TOP}    platypus

TC-DOCK-005 The Theme And The Tutorial Are At The Right End Of The Row Of Tabs
    [Documentation]    The 🌙 in the corner and the 📖 beside it; there is no 🛠 (the tabs are
    ...    the Tools) and no 🗗 in the row: the one way out is in the status bar.
    [Tags]    p1
    [Setup]    Launch Docked
    Icon Should Be At    ${THEME_TOGGLE_X}    ${DT_TAB_Y}
    Icon Should Be At    ${TUTORIAL_BUTTON_X}    ${DT_TAB_Y}
    Nothing Should Be At    ${NO_TOOLS_X}    ${DT_TAB_Y}
    Nothing Should Be At    ${NO_UNDOCK_X}    ${DT_TAB_Y}

TC-DOCK-006 The Status Bar Has The Info, The Website, The Settings And The Undock Buttons
    [Documentation]    From the right: ⓘ, 🌐, ⚙, then 🗗, and nothing left of that; the workspace's button is at the other end
    ...    of the bar, the first thing at its left.
    [Tags]    p1
    [Setup]    Launch Docked
    Icon Should Be At    ${SB_INFO_X}    ${SB_Y}
    Icon Should Be At    ${SB_WEBSITE_X}    ${SB_Y}
    Icon Should Be At    ${SB_SETTINGS_X}    ${SB_Y}
    Icon Should Be At    ${SB_UNDOCK_X}    ${SB_Y}
    Nothing Should Be At    ${SB_LEFT_OF_UNDOCK_X}    ${SB_Y}
    Icon Should Be At    ${SB_WORKSPACE_X}    ${SB_Y}

TC-DOCK-007 The Undock Button Is In The Status Bar Whichever Tab Is In Front
    [Documentation]    The Json Query tab and each tool's tab have it, in the same place,
    ...    with the 🌐 and the ⚙ between it and the ⓘ.
    [Tags]    p1
    [Setup]    Launch Docked
    FOR    ${tab}    IN    json    merge    format    diff    patch    validate
        Show Docked Tab    ${tab}
        Icon Should Be At    ${SB_UNDOCK_X}    ${SB_Y}
        Icon Should Be At    ${SB_SETTINGS_X}    ${SB_Y}
        Icon Should Be At    ${SB_WEBSITE_X}    ${SB_Y}
    END

TC-DOCK-008 The Window Has No Undock Button
    [Documentation]    With the Tools in a window of their own there is nothing to undock:
    ...    the status bar has the ⚙, the 🌐 and the ⓘ, and nothing where the 🗗 would be; the workspace's button is at the
    ...    left end, as it is with the Tools docked.
    [Tags]    p1
    Icon Should Be At    ${SB_INFO_X}    ${SB_Y}
    Icon Should Be At    ${SB_WEBSITE_X}    ${SB_Y}
    Icon Should Be At    ${SB_SETTINGS_X}    ${SB_Y}
    Icon Should Be At    ${SB_WORKSPACE_X}    ${SB_Y}
    Nothing Should Be At    ${SB_UNDOCK_X}    ${SB_Y}
    Open Tools Window
    Switch To Main Window
    Icon Should Be At    ${SB_WORKSPACE_X}    ${SB_Y}
    Nothing Should Be At    ${SB_UNDOCK_X}    ${SB_Y}

TC-DOCK-009 The Undock Button Takes The Tools Out Into A Window
    [Documentation]    The window opens on the page that was in front (Diff's); the main
    ...    window is as it is without the Tools docked: its toolbar, not a row of tabs, with
    ...    the 🛠 button back.
    [Tags]    p1
    Open Tool    diff
    Switch To Window    ${TOOLS_WINDOW}
    Click At    ${WINDOW_DOCK_X}    ${WINDOW_DOCK_Y}
    Wait Until Window Closes    ${TOOLS_WINDOW}    timeout=8
    Switch To Main Window
    Click At    ${SB_UNDOCK_X}    ${SB_Y}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Main Window
    Row Of Tabs Should Not Be There
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{TOOLBAR_ROW}    Source
    Icon Should Be At    ${NO_TOOLS_X}    ${DT_TAB_Y}
    Icon Should Be At    ${SB_WORKSPACE_X}    ${SB_Y}
    Nothing Should Be At    ${SB_UNDOCK_X}    ${SB_Y}
    Switch To Window    ${TOOLS_WINDOW}
    Page Should Show    Left    @{LEFT_HEADER}
    Tab Should Be Selected    diff

TC-DOCK-010 Docking And Undocking Again Leaves A Page As It Was
    [Documentation]    Text typed into Format's box in the window is in it after the Tools
    ...    went into the main window and out again, and is in the one window there is.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"keep":"platypus"}
    Switch To Window    ${TOOLS_WINDOW}
    Click At    ${WINDOW_DOCK_X}    ${WINDOW_DOCK_Y}
    Wait Until Window Closes    ${TOOLS_WINDOW}    timeout=8
    Switch To Main Window
    Row Of Tabs Should Be There
    Click At    ${SB_UNDOCK_X}    ${SB_Y}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{INPUT_BOX}    platypus
    ${windows}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${windows}    1

TC-DOCK-011 The Tools Start As A Window
    [Documentation]    A fresh start has the toolbar, not a row of tabs, no window of the
    ...    Tools open, and nothing in the settings about them.
    [Tags]    p1
    Row Of Tabs Should Not Be There
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{TOOLBAR_ROW}    Source
    ${windows}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${windows}    0
    Settings Value Should Be    tools    None

TC-DOCK-012 Docked Is Kept For The Next Start
    [Documentation]    Docked, then the app is closed and started again as the same person:
    ...    settings.json says so, and the app starts with the tabs, on the Json Query tab.
    [Tags]    p1
    Dock From The Window
    ${ended}=    Quit Jsonquery App
    Should Be True    ${ended}
    Settings Value Should Be    tools    docked
    Close Jsonquery App    keep_home=${TRUE}
    Launch Jsonquery App    keep_home=${TRUE}
    Row Of Tabs Should Be There
    Docked Tab Should Be Selected    json
    ${windows}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${windows}    0

TC-DOCK-013 A Window Again Is Kept Too
    [Documentation]    Started docked and undocked with the 🗗, the app is closed: the file
    ...    no longer says docked, and the next start has the toolbar and the 🛠 button.
    [Tags]    p1
    [Setup]    Launch Docked
    Click At    ${SB_UNDOCK_X}    ${SB_Y}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Main Window
    ${ended}=    Quit Jsonquery App
    Should Be True    ${ended}
    Settings Value Should Be    tools    None
    Close Jsonquery App    keep_home=${TRUE}
    Launch Jsonquery App    keep_home=${TRUE}
    Row Of Tabs Should Not Be There
    Icon Should Be At    ${NO_TOOLS_X}    ${DT_TAB_Y}

TC-DOCK-014 A Place The App Does Not Know Starts The Tools As A Window
    [Documentation]    settings.json says the Tools are "sideways": the app starts, with the
    ...    Tools in a window, as it does with nothing said.
    [Tags]    p2
    [Setup]    Launch Jsonquery App    settings={"tools": "sideways"}
    Row Of Tabs Should Not Be There
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{TOOLBAR_ROW}    Source
    Icon Should Be At    ${NO_TOOLS_X}    ${DT_TAB_Y}

TC-DOCK-015 Started Docked The Json Query Tab Is In Front
    [Documentation]    The main view is what the app is for, so it is what shows first:
    ...    the Json Query tab is the one marked and its source field is under the row.
    [Tags]    p1
    [Setup]    Launch Docked
    Row Of Tabs Should Be There
    Docked Tab Should Be Selected    json
    Docked Tab Should Not Be Selected    merge
    Show Docked Tab    json
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{TOOLBAR_ROW}    Source

TC-DOCK-016 The Json Query Tab Is The Main View With The Source Field Under The Row Of Tabs
    [Documentation]    The first row under the tabs is the source field, then the query, then
    ...    Source and Results: the main window as ever, moved down by the row of tabs.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{TOOLBAR_ROW}    Source
    Region Should Contain Text    @{QUERY_ROW}    Run
    Region Should Contain Text    @{SOURCE_HEADER}    Source
    Region Should Contain Text    @{RESULTS_HEADER}    Results
    Region Should Contain Text    @{SOURCE_HINT_ROW}    Drag
    Region Should Contain Text    @{ENGINE_PICKER_ROW}    JMESPath

TC-DOCK-017 A Document Is Loaded And Queried In The Json Query Tab
    [Documentation]    Paste a document, run a query: the answer is in Results and the status
    ...    bar says the query ran, as in the window without tabs.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    ${MEMBERS_JSON}
    Run Query    .members[].name
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{RESULTS_PANEL}    Ann    flatten_tints=${True}
    Region Should Contain Text    @{STATUS_BAR}    result(s)

TC-DOCK-018 The Source Field Loads A File In The Json Query Tab
    [Documentation]    A path typed into the source field (the first row under the tabs) and
    ...    Enter: the file is the document.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Via Url    ${FIXTURES}/people.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    items
    Source Field Should Be    ${FIXTURES}/people.json

TC-DOCK-019 A Visit To A Tool And Back Leaves The Json Query Tab As It Was
    [Documentation]    The document, the query and its answer are where they were: the main
    ...    view is not reset by a visit to a tool's tab.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    ${MEMBERS_JSON}
    Run Query    .members[].name
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{RESULTS_PANEL}    Ann    flatten_tints=${True}
    Show Docked Tab    format
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{DT_COMMAND_ROW}    Indent
    Show Docked Tab    json
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{RESULTS_PANEL}    Ann    flatten_tints=${True}
    Query Text Should Be    .members[].name

TC-DOCK-020 Each Tool's Tab Shows Its Page
    [Documentation]    A click on a tab makes it the marked one and shows the page of its tool:
    ...    Merge's "Merge as", Format's "Indent", Diff's "Side by side", Patch's "Kind" and
    ...    Validate's "Check formats".
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    merge
    Docked Tab Should Be Selected    merge
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{DT_COMMAND_ROW}    Merge as
    Show Docked Tab    format
    Docked Tab Should Be Selected    format
    Docked Tab Should Not Be Selected    merge
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{DT_COMMAND_ROW}    Indent
    Show Docked Tab    diff
    Docked Tab Should Be Selected    diff
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{DT_COMMAND_ROW}    Side by side
    Show Docked Tab    patch
    Docked Tab Should Be Selected    patch
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{DT_COMMAND_ROW}    Kind
    Show Docked Tab    validate
    Docked Tab Should Be Selected    validate
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{DT_COMMAND_ROW}    Check formats
    Show Docked Tab    json
    Docked Tab Should Be Selected    json
    Docked Tab Should Not Be Selected    validate

TC-DOCK-021 Ctrl+Enter On A Tool's Tab Runs The Tool, Not The Query
    [Documentation]    A query is typed and not run; on Format's tab Ctrl+Enter formats (the
    ...    status bar says so) and the query is left alone; back on the Json Query tab
    ...    Ctrl+Enter is the query's again and the typed query runs.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    ${MEMBERS_JSON}
    Run Query    .members[].name
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{RESULTS_PANEL}    Ann    flatten_tints=${True}
    Click At    100    58
    Press Keys    ctrl    a
    Type Text    .team
    Show Docked Tab    format
    Paste Into Box    ${DT_BOX_X}    ${DT_INPUT_Y}    {"b":1,"a":2}
    Press Keys    ctrl    enter
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_STATUS}    Formatted in
    Show Docked Tab    json
    Region Should Contain Text    @{RESULTS_PANEL}    Ann    flatten_tints=${True}
    Region Should Not Contain Text    @{RESULTS_PANEL}    platypus
    Click At    100    58
    Press Keys    ctrl    enter
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{RESULTS_PANEL}    platypus    flatten_tints=${True}

TC-DOCK-022 Ctrl+F And Ctrl+S Do Nothing On A Tool's Tab
    [Documentation]    There is no tree on a tool's page for them to be about: Ctrl+F opens no
    ...    search and Ctrl+S asks for no file; on the Json Query tab, with the same document
    ...    open, Ctrl+S asks and Ctrl+F opens the search.
    [Tags]    p2
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    ${MEMBERS_JSON}
    Click At    300    300
    Show Docked Tab    format
    Press Keys    ctrl    f
    Sleep    0.8s
    Region Should Not Contain Text    @{DT_POPUP_AREA}    Find All
    Region Should Not Contain Text    @{DT_POPUP_AREA}    Regex
    Press Keys    ctrl    s
    Sleep    1.0s
    ${asked}=    Get Portal Requests
    Length Should Be    ${asked}    0
    Show Docked Tab    json
    Click At    300    300
    Portal Will Cancel
    Press Keys    ctrl    s
    ${asked}=    Wait Until Portal Is Asked    1    timeout=8
    Length Should Be    ${asked}    1
    Press Keys    ctrl    f
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{POPUP_DIALOG_AREA}    Find All

TC-DOCK-023 The Status Bar Says What The Tab In Front Has To Say
    [Documentation]    On the Json Query tab it is the query's ("result(s)"); on Format's tab it is
    ...    Format's ("Formatted in"), and the query's is back when the tab is.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    ${MEMBERS_JSON}
    Run Query    .members[].name
    Region Should Contain Text    @{STATUS_BAR}    result(s)
    Show Docked Tab    format
    Paste Into Box    ${DT_BOX_X}    ${DT_INPUT_Y}    {"b":1,"a":2}
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_STATUS}    Formatted in
    Region Should Not Contain Text    @{DT_STATUS}    result(s)
    Show Docked Tab    json
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{STATUS_BAR}    result(s)
    Region Should Not Contain Text    @{STATUS_BAR}    Formatted in

TC-DOCK-024 Format Takes The Document Open In The Json Query Tab
    [Documentation]    "Open document" on Format's page puts the document of the Json Query tab
    ...    in its box; Format formats it and Copy gives exactly the formatted text.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    ${MEMBERS_JSON}
    Show Docked Tab    format
    Click At    ${DT_OPEN_DOCUMENT_X}    ${DT_HEADER_Y}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{DT_INPUT_TOP}    open document
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_STATUS}    Formatted in
    ${pretty}=    Evaluate    json.dumps(json.loads($MEMBERS_JSON), indent=2)    modules=json
    Copy Should Give    ${DT_FORMAT_COPY_X}    ${DT_HEADER_Y}    ${pretty}

TC-DOCK-025 A Merged Document Opened In The Main Window Is Shown In The Json Query Tab
    [Documentation]    Two files dropped on the window go to Merge's tab; the merge is run and
    ...    "Open in main window" brings the Json Query tab to the front with the merged document
    ...    in it, named in the source row.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Drop Files On Window    600    300    ${FIXTURES}/merge/platypus.json    ${FIXTURES}/merge/echidna.json
    Docked Tab Should Be Selected    merge
    Set Layout Shift    0
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{MERGE_LEFT_HEADER}    Files (2
    Press Main Button
    Wait Until Keyword Succeeds    12x    1s
    ...    Region Should Contain Text    @{DT_STATUS}    Merged
    Click At    ${DT_OPEN_IN_MAIN_X}    ${MERGE_HEADER_Y}
    Set Layout Shift    ${DY}
    Docked Tab Should Be Selected    json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_AREA}    merged
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    2 items

TC-DOCK-026 A Patched Document Opened In The Main Window Is Shown In The Json Query Tab
    [Documentation]    Patch's "Open in main window" does the same: the Json Query tab, with
    ...    the patched document (the array has three items now).
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    patch
    Paste Into Box    ${DT_BOX_X}    ${DT_FIRST_Y}    {"a":1,"b":[1,2]}
    Paste Into Box    ${DT_BOX_X}    ${DT_SECOND_Y}    [{"op":"replace","path":"/a","value":2},{"op":"add","path":"/b/-","value":3}]
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_STATUS}    Patched in
    Click At    ${DT_OPEN_IN_MAIN_X}    ${DT_HEADER_Y}
    Set Layout Shift    ${DY}
    Docked Tab Should Be Selected    json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_AREA}    patched
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    3 items

TC-DOCK-027 A Problem Shown In The Main Window Is Shown In The Json Query Tab
    [Documentation]    With a document open in the Json Query tab used as the one to check, a
    ...    problem picked and "Show in main window" pressed: the Json Query tab comes to the
    ...    front and runs the problem's JSON Pointer, so the value at fault is what Results show.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    {"age": -1, "name": "Ann"}
    Show Docked Tab    validate
    Click At    ${DT_OPEN_DOCUMENT_X}    ${DT_HEADER_Y}
    Sleep    0.3s
    Paste Into Box    ${DT_BOX_X}    ${DT_SECOND_Y}    {"properties":{"age":{"minimum":0}}}
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_RESULT}    /age
    Click At    640    ${FIRST_ROW_Y}
    Sleep    0.3s
    Click At    ${DT_SHOW_IN_MAIN_X}    ${DT_HEADER_Y}
    Set Layout Shift    ${DY}
    Docked Tab Should Be Selected    json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_BAR}    1 result(s) [Pointer]

TC-DOCK-028 A File Dropped On The Json Query Tab Is Opened As The Document
    [Documentation]    One file dropped on the window while the Json Query tab is in front is
    ...    the document, as it is without tabs.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Drop Files On Window    300    300    ${FIXTURES}/people.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    3 items

TC-DOCK-029 A File Dropped On A Tool's Tab Goes Into That Tool's Box
    [Documentation]    With Format's tab in front a dropped file is Format's: it is read into
    ...    its box, and the document of the Json Query tab is not touched.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    format
    Drop Files On Window    ${DT_BOX_X}    ${DT_INPUT_Y}    ${FIXTURES}/people.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_INPUT_BOX}    Alice
    Show Docked Tab    json
    Region Should Contain Text    @{SOURCE_PANEL}    Paste JSON

TC-DOCK-030 Several Files Dropped On The Json Query Tab Go To Merge's Tab
    [Documentation]    Dropped several at a time, files are put in Merge's list as ever, and
    ...    Merge's tab comes to the front (not a window).
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Drop Files On Window    600    300    ${FIXTURES}/merge/dups_a.json    ${FIXTURES}/merge/dups_b.json
    Docked Tab Should Be Selected    merge
    Set Layout Shift    0
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{MERGE_LEFT_HEADER}    Files (2
    ${windows}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${windows}    0
    Show Docked Tab    json
    Region Should Contain Text    @{SOURCE_PANEL}    Paste JSON

TC-DOCK-031 The Theme Button In The Row Of Tabs Changes The Theme Of The Page In Front
    [Documentation]    The 🌙 at the right end of the row turns the page of a tool light, as the
    ...    one in the toolbar does the window: the right pane's background goes from dark to
    ...    light.
    [Tags]    p2
    [Setup]    Launch Docked
    Show Docked Tab    format
    ${dark}=    Get Pixel Color    900    300
    Should Be True    max(${dark}) < 80    msg=Expected the dark theme to start with: ${dark}
    Click At    ${THEME_TOGGLE_X}    ${DT_TAB_Y}
    Sleep    0.8s
    ${light}=    Get Pixel Color    900    300
    Should Be True    min(${light}) > 180    msg=Expected the light theme: ${light}

TC-DOCK-032 The Settings And The Info Buttons Open Their Windows From A Tool's Tab
    [Documentation]    The ⚙ and the ⓘ at the right end of the status bar work with a tool's
    ...    page in front: the Settings window and the About window open.
    [Tags]    p2
    [Setup]    Launch Docked
    Show Docked Tab    diff
    Click At    ${SB_SETTINGS_X}    ${SB_Y}
    Wait Until Window Exists    ${SETTINGS_WINDOW}    timeout=8
    Close Window    ${SETTINGS_WINDOW}
    Wait Until Window Closes    ${SETTINGS_WINDOW}    timeout=8
    Switch To Main Window
    Click At    ${SB_INFO_X}    ${SB_Y}
    Wait Until Window Exists    ${ABOUT_WINDOW}    timeout=8

TC-DOCK-033 A Tools Window Maximized Over The Main Window Docks Into It
    [Documentation]    The Tools window is maximized -- it covers the screen, the main window
    ...    under it -- and its ⚓ is pressed: the window goes (it gives up covering the main
    ...    window) and the row of tabs is in the main window.
    [Tags]    p1
    Open Tools Window
    Maximize Window    ${TOOLS_WINDOW}
    Switch To Window    ${TOOLS_WINDOW}
    ${width}    ${height}=    Get Window Size
    Should Be True    ${width} > 1200
    ${x}=    Evaluate    ${width} - 19
    Click At    ${x}    ${WINDOW_DOCK_Y}
    Wait Until Window Closes    ${TOOLS_WINDOW}    timeout=10
    Switch To Main Window
    Row Of Tabs Should Be There

TC-DOCK-034 A Docked Diff Compares Two Documents
    [Documentation]    The Diff page, the most involved, works in a tab: two documents pasted
    ...    in, Compare, and the status bar says what differs.
    [Tags]    p2
    [Setup]    Launch Docked
    Show Docked Tab    diff
    Paste Into Box    ${DT_BOX_X}    ${DT_INPUT_Y}    {"a":1,"b":2}
    Paste Into Box    ${DT_RIGHT_BOX_X}    ${DT_INPUT_Y}    {"a":1,"b":3}
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_STATUS}    1 changed

TC-DOCK-037 Diff Takes The Document Open In The Json Query Tab As One Of The Two
    [Documentation]    "Open document" in Left's header takes the document of the Json Query tab
    ...    as Left; the other is typed in, and the comparison runs on them.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    {"x":1,"y":"platypus"}
    Show Docked Tab    diff
    Click At    ${DT_OPEN_DOCUMENT_X}    ${DT_DIFF_HEADER_Y}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{DT_DIFF_LEFT_TOP}    open document
    Paste Into Box    ${DT_RIGHT_BOX_X}    ${DT_INPUT_Y}    {"x":2,"y":"platypus"}
    Press Main Button
    Tab Row Should Offer Changes    1
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_STATUS}    1 changed

TC-DOCK-038 The Document Open In The Json Query Tab Is Patched
    [Documentation]    "Open document" in Patch's Document header uses the document of the Json
    ...    Query tab; the operations typed under it are applied to it.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    {"x":"platypus"}
    Show Docked Tab    patch
    Click At    ${DT_OPEN_DOCUMENT_X}    ${DT_HEADER_Y}
    Sleep    0.5s
    Paste Into Box    ${DT_BOX_X}    ${DT_SECOND_Y}    [{"op":"add","path":"/y","value":2}]
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_STATUS}    operation
    ${patched}=    Evaluate    json.dumps({"x": "platypus", "y": 2}, indent=2)    modules=json
    Copy Should Give    ${DT_PATCH_COPY_X}    ${DT_HEADER_Y}    ${patched}

TC-DOCK-039 A Double-Click On A Problem Shows It In The Json Query Tab
    [Documentation]    A double-click on a row of the report does what "Show in main window"
    ...    does: the Json Query tab comes to the front and runs the problem's JSON Pointer.
    [Tags]    p1
    [Setup]    Launch Docked
    Show Docked Tab    json
    Load Fixture Via Paste    {"age": -1, "name": "Ann"}
    Show Docked Tab    validate
    Click At    ${DT_OPEN_DOCUMENT_X}    ${DT_HEADER_Y}
    Sleep    0.3s
    Paste Into Box    ${DT_BOX_X}    ${DT_SECOND_Y}    {"properties":{"age":{"minimum":0}}}
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DT_RESULT}    /age
    Double Click At    640    ${FIRST_ROW_Y}
    Set Layout Shift    ${DY}
    Docked Tab Should Be Selected    json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_BAR}    1 result(s) [Pointer]

TC-DOCK-040 A Big Merge Result Opened In The Main Window Is A File In The Json Query Tab
    [Documentation]    Kept on disk from 1 KB, two merged lists of words (1.4 KB, 120 items) are a
    ...    file that has no name; "Open in main window" brings the Json Query tab with all of it, and
    ...    its status bar says Indexed, not Parsed, as for a file of that size opened from disk; the
    ...    temporary file is still mapped and still has no name.
    [Tags]    p1
    [Setup]    Launch Docked With A Low Limit
    @{paths}=    Make Lists Of Words    2    60
    Show Docked Tab    json
    Drop Files On Window    600    300    @{paths}
    Docked Tab Should Be Selected    merge
    Set Layout Shift    0
    Press Main Button
    Wait Until Keyword Succeeds    12x    1s
    ...    Region Should Contain Text    @{DT_STATUS}    120 items
    Region Should Contain Text    @{DT_STATUS}    kept in a temporary file
    Click At    ${DT_OPEN_IN_MAIN_X}    ${MERGE_HEADER_Y}
    Set Layout Shift    ${DY}
    Docked Tab Should Be Selected    json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    120 items
    Region Should Contain Text    @{STATUS_BAR}    Indexed in
    App Should Have Mapped A Deleted File    merged.json
    ${names}=    List Directory    ${TMP}    pattern=*merged.json
    Should Be Empty    ${names}

TC-DOCK-041 The Website Button Opens The Site From Whichever Tab Is In Front
    [Documentation]    The 🌐 in the status bar, between the ⓘ and the ⚙, works with the Json
    ...    Query tab in front and with each tool's tab: every click hands the address of the site
    ...    to the browser (a stand-in, which writes it down) once.
    [Tags]    p2
    [Setup]    Launch Docked
    Nothing Should Have Been Opened    settle=0.3
    ${clicks}=    Set Variable    ${0}
    FOR    ${tab}    IN    json    merge    format    diff    patch    validate
        Show Docked Tab    ${tab}
        Click At    ${SB_WEBSITE_X}    ${SB_Y}
        ${clicks}=    Evaluate    ${clicks} + 1
        ${expected}=    Evaluate    ['${WEBSITE_ADDRESS}'] * ${clicks}
        Opened Addresses Should Be    @{expected}
    END
    ${windows}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${windows}    0

*** Keywords ***
Launch Docked With A Low Limit
    [Documentation]    The app started docked, with files kept on disk from 1 KB (the least the
    ...    Settings window allows, so a few lines are "big"), and a TMPDIR of its own (`${TMP}`).
    ${tmp}=    Make Temp Directory
    Set Test Variable    ${TMP}    ${tmp}
    Launch Jsonquery App    settings={"tools": "docked", "limits": {"keep_on_disk_from": "1 KB"}}    temp_dir=${TMP}

Dock From The Window
    [Documentation]    Opens the Tools window and presses its ⚓, as a person does; waits for
    ...    the window to go and the row of tabs to be there. The page that was in front in
    ...    the window (Merge's) is in front.
    Open Tools Window
    Switch To Window    ${TOOLS_WINDOW}
    Click At    ${WINDOW_DOCK_X}    ${WINDOW_DOCK_Y}
    Wait Until Window Closes    ${TOOLS_WINDOW}    timeout=8
    Switch To Main Window
    Row Of Tabs Should Be There
