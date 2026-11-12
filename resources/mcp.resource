*** Settings ***
Documentation     The 🔌 of the build with the MCP server, its panel, the questions an assistant asks the user, and an
...               assistant of the server (resources/mcp_client.py): the points and keywords the suites of suites/mcp/
...               share. See docs/26_mcp_server.md.
...
...               The panel hangs above the 🔌 and keeps one size and the same rows whatever happens (the app's
...               layout test `the_plug_comes_last_in_the_status_bar_and_opens_the_mcp_panel` holds it to that), so its
...               points are fixed. They are the points of the window with no row of tabs: the panel hangs from the
...               status bar, which the docked profile does not move, so the suites are tagged `undocked-only` and
...               dock the app themselves where it matters (TC-MCP-031).
Resource          keywords.resource
Library           OperatingSystem
Library           mcp_client.py

*** Variables ***
# The status bar, from the right: ⓘ 1181, 🌐 1152, ⚙ 1123, then the 🔌, the last of them (with the Tools docked it is
# left of the 🗗, at 1066). The spinner of a call that runs is at the plug's left.
${MCP_BAR_Y}              789
${MCP_PLUG_X}             1095
${MCP_LEFT_OF_PLUG_X}     1066
${MCP_PLUG_DOCKED_X}      1066
# What the 🔌 is drawn in while the server runs (the app's ON_COLOR), and the panel's red (tools' ERROR_COLOR).
@{MCP_ON_COLOR}           46     160    67
@{MCP_ERROR_COLOR}        220    80     80
# The plug's own square, to look for its colour in.
@{MCP_PLUG_BOX}           1086   781    20     16
# Its tooltip: above the status bar, its right end near the plug's; and a strip above that, which a tooltip of more
# than its two lines would reach.
@{MCP_PLUG_TIP}           780    726    330    50
@{MCP_ABOVE_TIP}          600    600    600    120
# The panel (394 x 332), and its rows.
@{MCP_PANEL}              712    448    394    332
@{MCP_TITLE_ROW}          712    453    394    24
${MCP_START_X}            1081
${MCP_START_Y}            465
@{MCP_ADDRESS_ROW}        712    474    394    24
${MCP_PORT_X}             940
${MCP_PORT_Y}             486
# Allow: the radio buttons Read and Edit, then the box "Always allow" (which Read greys out).
@{MCP_ALLOW_ROW}          712    498    394    24
${MCP_ALLOW_Y}            510
${MCP_READ_X}             782
${MCP_EDIT_X}             838
${MCP_ALWAYS_X}           895
@{MCP_ALWAYS_BOX}         889    504    12     12
# Answers: the sizes of a page, in KB, the one chosen filled with the selection's blue, then "≈ N tokens".
@{MCP_ANSWERS_ROW}        712    522    394    24
${MCP_ANSWERS_Y}          534
&{MCP_PAGE_X}             4=783    8=800    16=822    24=846    64=871    200=900
@{MCP_TOKENS_AREA}        930    522    176    24
@{MCP_CHOSEN_COLOR}       0      92     128
# The "Add to" buttons, in two rows, and the end of the second row, where "✔ Copied" is said.
@{MCP_ADD_ROWS}           712    546    394    48
${MCP_ADD_Y}              558
${MCP_ADD_Y2}             582
${MCP_CLAUDE_CODE_X}      815
${MCP_CLAUDE_DESKTOP_X}   913
${MCP_VS_CODE_X}          998
${MCP_QUICKAI_X}          800
${MCP_JSON_X}             854
@{MCP_COPIED_AREA}        860    572    246    22
${MCP_START_WITH_X}       726
${MCP_START_WITH_Y}       603
@{MCP_START_WITH_ROW}     712    592    394    22
# What the server is doing: the first line (an error, Not running, who is connected), the count of calls, the last
# five calls (18 px apart, the newest at the top).
@{MCP_STATUS_LINE}        712    620    394    22
@{MCP_CALLS_LINE}         712    638    394    22
@{MCP_STATUS_LINES}       712    620    394    40
@{MCP_CALL_ROWS}          712    656    394    96
${MCP_FIRST_CALL_Y}       657
${MCP_NEW_TOKEN_X}        755
${MCP_NEW_TOKEN_Y}        766
# Somewhere outside the panel that a click there does nothing to: the Results pane, empty.
${MCP_OUTSIDE_X}          900
${MCP_OUTSIDE_Y}          300
${PEOPLE_FIXTURE}         ${CURDIR}/fixtures/people.json
${NESTED_FIXTURE}         ${CURDIR}/fixtures/nested.json
${NUMBERS_FIXTURE}        ${CURDIR}/fixtures/many_numbers.json

*** Keywords ***
Launch Mcp App
    [Documentation]    Starts the build with the MCP server, as a first start of a new user but for its `mcp.json`, which
    ...    gives the server a port nothing listens on (so that two lanes of a run, and the JsonQuery of whoever runs
    ...    the suite, never meet on 7457) and, if asked, an access and whether it starts with the app. Sets
    ...    `${MCP_PORT}` for the case.
    [Arguments]    ${access}=${None}    ${start_with_app}=${None}    ${settings}=${None}    ${workspace}=${None}
    ...    ${build}=mcp    ${always_allow}=${None}    ${answer_kb}=${None}
    ${port}=    Free Port
    ${text}=    Mcp Json    port=${port}    access=${access}    start_with_app=${start_with_app}
    ...    always_allow=${always_allow}    answer_kb=${answer_kb}
    &{files}=    Create Dictionary    mcp.json=${text}
    Launch Jsonquery App    build=${build}    home_files=${files}    settings=${settings}    workspace=${workspace}
    Set Test Variable    ${MCP_PORT}    ${port}
    IF    $start_with_app is not None and $start_with_app    Wait Until Mcp Server Answers    timeout=8

Launch Mcp App Serving
    [Documentation]    The build with the MCP server, which starts its server with the app and allows `access`, and an
    ...    assistant that has made its handshake with it.
    [Arguments]    ${access}=edit    ${settings}=${None}    ${workspace}=${None}    ${always_allow}=${None}
    ...    ${answer_kb}=${None}
    Launch Mcp App    access=${access}    start_with_app=${True}    settings=${settings}    workspace=${workspace}
    ...    always_allow=${always_allow}    answer_kb=${answer_kb}
    Mcp Initialize    client=Robot assistant

Open Mcp Panel
    [Documentation]    Clicks the 🔌 and waits for its panel, then takes the pointer off the plug (the panel hangs a
    ...    pixel higher while the plug is hovered).
    Wait Until Keyword Succeeds    3x    0.5s    Click Plug And See The Panel
    Move Mouse To    ${MCP_OUTSIDE_X}    ${MCP_OUTSIDE_Y}
    Sleep    0.3s

Click Plug And See The Panel
    Click At    ${MCP_PLUG_X}    ${MCP_BAR_Y}
    Wait Until Region Contains Text    @{MCP_TITLE_ROW}    MCP server    timeout=2

Close Mcp Panel
    Click At    ${MCP_OUTSIDE_X}    ${MCP_OUTSIDE_Y}
    Sleep    0.4s
    Region Should Not Contain Text    @{MCP_TITLE_ROW}    MCP server

Start Mcp Server From Panel
    [Documentation]    In the open panel: Start, and waits for the server to answer on its port. The pointer is taken off
    ...    the button (a hovered button is lit, and OCR does not read its label).
    Click At    ${MCP_START_X}    ${MCP_START_Y}
    Move Mouse To    ${MCP_OUTSIDE_X}    ${MCP_OUTSIDE_Y}
    Wait Until Mcp Server Answers    timeout=5    port=${MCP_PORT}
    Wait Until Region Contains Text    @{MCP_TITLE_ROW}    Stop    timeout=3

Stop Mcp Server From Panel
    Click At    ${MCP_START_X}    ${MCP_START_Y}
    Move Mouse To    ${MCP_OUTSIDE_X}    ${MCP_OUTSIDE_Y}
    Wait Until Region Contains Text    @{MCP_TITLE_ROW}    Start    timeout=3
    Mcp Server Should Not Answer    port=${MCP_PORT}

Start Mcp Server
    [Documentation]    Opens the panel, starts the server and closes the panel again.
    Open Mcp Panel
    Start Mcp Server From Panel
    Close Mcp Panel

Plug Should Be Green
    Wait Until Keyword Succeeds    6x    0.3s
    ...    Region Should Contain Color    @{MCP_PLUG_BOX}    @{MCP_ON_COLOR}    tolerance=40
    ...    msg=The 🔌 is not green: the server should be running

Plug Should Not Be Green
    Wait Until Keyword Succeeds    6x    0.3s
    ...    Region Should Not Contain Color    @{MCP_PLUG_BOX}    @{MCP_ON_COLOR}    tolerance=40
    ...    msg=The 🔌 is green: the server should not be running

Something Should Be Drawn At
    [Documentation]    A button of the status bar is there (an icon, which OCR cannot read: its pixels).
    [Arguments]    ${x}
    ${left}=    Evaluate    int(${x}) - 10
    ${top}=    Evaluate    ${MCP_BAR_Y} - 8
    Get Ink Bounds    ${left}    ${top}    20    16    threshold=60

Nothing Should Be Drawn At
    [Arguments]    ${x}
    ${left}=    Evaluate    int(${x}) - 10
    ${top}=    Evaluate    ${MCP_BAR_Y} - 8
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    ${left}    ${top}    20    16    threshold=60

Choose Access
    [Documentation]    Clicks one of the panel's Allow (`read`: Read, `edit`: Edit) and waits for mcp.json to have it.
    [Arguments]    ${access}
    ${x}=    Set Variable If    '${access}' == 'read'    ${MCP_READ_X}    ${MCP_EDIT_X}
    Click At    ${x}    ${MCP_ALLOW_Y}
    Wait Until Mcp Setting Is    access    ${access}

Click Always Allow
    [Documentation]    Clicks the panel's box "Always allow" and takes the pointer off it.
    Click At    ${MCP_ALWAYS_X}    ${MCP_ALLOW_Y}
    Move Mouse To    ${MCP_OUTSIDE_X}    ${MCP_OUTSIDE_Y}
    Sleep    0.3s

Always Allow Should Be Ticked
    Wait Until Keyword Succeeds    6x    0.3s    Get Ink Bounds    @{MCP_ALWAYS_BOX}    threshold=150

Always Allow Should Not Be Ticked
    Run Keyword And Expect Error    Nothing as bright as*    Get Ink Bounds    @{MCP_ALWAYS_BOX}    threshold=150

Choose Answer Size
    [Documentation]    Clicks a size of the panel's Answers (4, 8, 16, 24, 64 or 200, in KB) and waits for mcp.json to
    ...    have it.
    [Arguments]    ${kb}
    Click At    ${MCP_PAGE_X}[${kb}]    ${MCP_ANSWERS_Y}
    Move Mouse To    ${MCP_OUTSIDE_X}    ${MCP_OUTSIDE_Y}
    Wait Until Mcp Setting Is    answer_kb    ${kb}

Answer Size Should Be Chosen
    [Documentation]    The size `kb` of the Answers row is filled with the selection's blue, and the others are not.
    [Arguments]    ${kb}
    FOR    ${size}    IN    @{MCP_PAGE_X}
        ${left}=    Evaluate    int(${MCP_PAGE_X}[${size}]) - 3
        ${top}=    Evaluate    ${MCP_ANSWERS_Y} - 6
        IF    '${size}' == '${kb}'
            Wait Until Keyword Succeeds    6x    0.3s
            ...    Region Should Contain Color    ${left}    ${top}    6    12    @{MCP_CHOSEN_COLOR}    tolerance=20
        ELSE
            Region Should Not Contain Color    ${left}    ${top}    6    12    @{MCP_CHOSEN_COLOR}    tolerance=20
        END
    END

Tokens Should Say
    [Documentation]    The Answers row says about `thousands`,000 tokens (OCR reads its comma as a space, at times).
    [Arguments]    ${thousands}
    ${comma}=    Run Keyword And Return Status
    ...    Region Should Contain Text    @{MCP_TOKENS_AREA}    ${thousands},000 tokens
    IF    not ${comma}
        Region Should Contain Text    @{MCP_TOKENS_AREA}    ${thousands} 000 tokens
    END

Question Should Ask
    [Documentation]    A question of an assistant is over the main window, and says each of `texts` (by OCR, above its
    ...    buttons). Returns where its buttons are (`Question Buttons`).
    [Arguments]    @{texts}
    ${buttons}=    Wait Until Keyword Succeeds    10x    0.3s    Question Buttons
    FOR    ${text}    IN    @{texts}
        Wait Until Region Contains Text    @{buttons}[box]    ${text}    timeout=3
    END
    RETURN    ${buttons}

Answer The Question
    [Documentation]    Clicks one of the question's buttons: Allow, Always allow or Don't allow.
    [Arguments]    ${button}
    ${buttons}=    Wait Until Keyword Succeeds    10x    0.3s    Question Buttons
    Click At    ${buttons}[${button}][0]    ${buttons}[${button}][1]
    Move Mouse To    ${MCP_OUTSIDE_X}    ${MCP_OUTSIDE_Y}

Radio Should Be Chosen
    [Documentation]    The radio button at `x` of the Allow row has its dot: something bright in the middle of its ring.
    [Arguments]    ${x}
    ${left}=    Evaluate    int(${x}) - 2
    ${top}=    Evaluate    ${MCP_ALLOW_Y} - 2
    Get Ink Bounds    ${left}    ${top}    4    4    threshold=150

Radio Should Not Be Chosen
    [Arguments]    ${x}
    ${left}=    Evaluate    int(${x}) - 2
    ${top}=    Evaluate    ${MCP_ALLOW_Y} - 2
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    ${left}    ${top}    4    4    threshold=150

Copy Configuration
    [Documentation]    Clicks one of the panel's "Add to" buttons and returns what it put on the clipboard (it fails if
    ...    the button put nothing there).
    [Arguments]    ${x}    ${y}=${MCP_ADD_Y}
    Set Clipboard    nothing was copied
    Click At    ${x}    ${y}
    Wait Until Keyword Succeeds    10x    0.2s    Clipboard Should Have Changed
    ${text}=    Get Clipboard
    RETURN    ${text}

Clipboard Should Have Changed
    ${text}=    Get Clipboard
    Should Not Be Equal    ${text}    nothing was copied

Panel Line Should Say
    [Documentation]    The panel's region says `text` (its lines are weak text, which OCR reads at this size).
    [Arguments]    ${text}    ${region}=${MCP_STATUS_LINES}    ${timeout}=4
    Wait Until Region Contains Text    @{region}    ${text}    timeout=${timeout}

Call Row Should Say
    [Documentation]    The `n`th of the last calls (1: the newest) says `text`.
    [Arguments]    ${n}    ${text}
    ${y}=    Evaluate    ${MCP_FIRST_CALL_Y} + 18 * (int(${n}) - 1)
    Wait Until Region Contains Text    712    ${y}    394    20    ${text}    timeout=4

Call Row Should Be Red
    [Arguments]    ${n}
    ${y}=    Evaluate    ${MCP_FIRST_CALL_Y} + 18 * (int(${n}) - 1)
    Region Should Contain Color    712    ${y}    394    20    @{MCP_ERROR_COLOR}    tolerance=30

Call Row Should Not Be Red
    [Arguments]    ${n}
    ${y}=    Evaluate    ${MCP_FIRST_CALL_Y} + 18 * (int(${n}) - 1)
    Region Should Not Contain Color    712    ${y}    394    20    @{MCP_ERROR_COLOR}    tolerance=30

Fixture Path
    [Arguments]    ${name}
    ${path}=    Normalize Path    ${CURDIR}/fixtures/${name}
    RETURN    ${path}
