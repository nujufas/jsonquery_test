*** Settings ***
Documentation     The button that shows and hides the workspace pane, at the left end of the status bar, and what the bar does
...               around it -- see docs/25_workspace.md. The status text begins after the button (from x 41, the button is
...               at x 8-31), a message that is too long for one line wraps beside it and leaves it where it is, and the buttons
...               at the right end of the bar (the ⚙, the 🌐 and the ⓘ) are where they were before there was a pane. Which
...               picture the button is, and the strip's, is TC-WSP-003 and 019.
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace    status-bar
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The status bar's buttons at the right, from the left: the ⚙, the 🌐 and the ⓘ (and, with the Tools docked, the 🗗 at 1095).
${GEAR_X}                 1123
${GLOBE_X}                1152
${INFO_X}                 1181
# Where the pane's button was when it was the last of the status bar's buttons from the right (it is no longer: nothing is there).
${OLD_PLACE_X}            1094
# The text of the bar is read from here on, the left edge of the first letter of it being at 41.
${TEXT_FROM_X}            33
# Where the tooltip of the button is when the pointer rests on it: over the bar, at the left.
@{BUTTON_TIP}             0      725    420    60
# A path that is not there and is long enough to wrap in the status bar: fourteen folders of a long name.
${LONG_FOLDER}            a-very-long-folder-name
${PATH_NOT_THERE}         /${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/${LONG_FOLDER}/missing.json

*** Test Cases ***
TC-WSP-243 The Button Is The First Thing At The Left End Of The Status Bar And The Text Begins After It
    [Documentation]    The button is at x 8-31, level with the status text, which begins at x 41: the first letter is not under the
    ...    button and nothing of the text is left of it.
    [Tags]    p1
    Load Fixture Via Paste    {"a": 1}
    Wait Until Region Matches    @{STATUS_BAR}    Parsed    timeout=6
    Move Mouse To    600    400
    Icon Should Be At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    # The first letter of the text: 8 points on from the edge of the region that begins where the button ends.
    ${left}=    Where The Status Text Begins
    Should Be True    41 <= ${left} <= 44    msg=The text begins at ${left}, not at 41
    # And the button has the room that it was given: nothing is drawn between the button and the text.
    Nothing Should Be Drawn At    36    ${WS_STATUS_Y}    4

TC-WSP-244 The Button Is Where It Is Whether The Pane Is Shown, Folded Or Hidden
    [Documentation]    Hidden, open, folded to its strip and hidden again: the button is at the left end each time, and the text of
    ...    the bar does not move with the pane.
    [Tags]    p1
    Load Fixture Via Paste    {"a": 1}
    Wait Until Region Matches    @{STATUS_BAR}    Parsed    timeout=6
    Move Mouse To    600    400
    ${hidden}=    Where The Status Text Begins
    Icon Should Be At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Click At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Pane Should Be Open
    Move Mouse To    600    400
    Icon Should Be At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    ${open}=    Where The Status Text Begins
    Click Header Button    fold
    Pane Should Not Be Shown
    Move Mouse To    600    400
    Icon Should Be At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    ${folded}=    Where The Status Text Begins
    # The button of the status bar hides what is folded to the strip, too.
    Click At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Contain Text    0    0    70    24    Source
    Move Mouse To    600    400
    Icon Should Be At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    ${again}=    Where The Status Text Begins
    Should Be Equal As Integers    ${open}    ${hidden}    msg=The text moved when the pane was opened
    Should Be Equal As Integers    ${folded}    ${hidden}    msg=The text moved when the pane was folded
    Should Be Equal As Integers    ${again}    ${hidden}    msg=The text moved when the pane was hidden

TC-WSP-245 Held Still Under The Pointer The Button Says What It Is And What A Click Does
    [Documentation]    Two lines: the name and what it is for, and what a click does now (it shows the pane while it is hidden and
    ...    hides it while it is shown).
    [Tags]    p2
    Move Mouse To    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Sleep    1.5s
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{BUTTON_TIP}    your saved queries, schemas and samples
    Region Should Contain Text    @{BUTTON_TIP}    Click to show it
    Region Should Not Contain Text    @{BUTTON_TIP}    Click to hide
    Click At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Pane Should Be Open
    Move Mouse To    600    400
    Sleep    0.6s
    Move Mouse To    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Sleep    1.5s
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{BUTTON_TIP}    Click to hide
    Region Should Not Contain Text    @{BUTTON_TIP}    Click to show

TC-WSP-246 A Message Too Long For One Line Wraps Beside The Button And Leaves It At The Left End
    [Documentation]    The status bar grows upward as the message takes lines: the button stays in its column, level with the
    ...    first line, and the lines under the first begin where it does (after the button's column) and not under it; the buttons
    ...    at the other end are still at the end of the first line. It is where a click is still the click that shows the pane.
    [Tags]    p1
    Submit Source By Paste    ${PATH_NOT_THERE}
    Wait Until Region Matches    @{STATUS_BAR}    Load error    timeout=8
    Move Mouse To    300    400
    # What follows is read and clicked where the window has it: the bar has grown, and its buttons are above the last 30 points of
    # the window, which the docked profile leaves where they are and moves everything over them down by the row of tabs.
    ${shift}=    Get Layout Shift
    Set Layout Shift    0
    # The picture on the button (14 by 12, at x 13-26): the only thing in the button's column in the lowest 70 points of the
    # window (the button's own fill is not as bright, and the text is from x 41). The bar is about 67 high with this message.
    ${il}    ${it}    ${ir}    ${ib}=    Get Ink Bounds    4    730    32    70    threshold=90
    Should Be Equal As Integers    ${il}    9    msg=The button is not at the left end: its picture begins at ${il} + 4
    Should Be Equal As Integers    ${ir}    22    msg=The picture is not 14 points wide: it ends at ${ir} + 4
    ${icon_top}=    Evaluate    730 + ${it}
    ${icon_bottom}=    Evaluate    730 + ${ib}
    Should Be True    ${icon_top} < 770    msg=The bar did not grow: the button is still at ${icon_top}
    # The text (red: a channel of 220) begins after the button and its first line is level with it.
    ${tl}    ${tt}    ${tr}    ${tb}=    Get Ink Bounds    ${TEXT_FROM_X}    730    550    70    threshold=150
    ${text_top}=    Evaluate    730 + ${tt}
    Should Be True    7 <= ${tl} <= 11    msg=The message begins ${tl} points on from ${TEXT_FROM_X}
    Should Be True    abs(${text_top} - ${icon_top}) <= 8    msg=The first line (${text_top}) is not level with the button (${icon_top})
    # The lines under the first keep clear of the button's column: nothing is drawn under the button (which is 21 high).
    ${under}=    Evaluate    ${icon_bottom} + 8
    ${rest}=    Evaluate    799 - ${under}
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    4    ${under}    32    ${rest}    threshold=100
    # The buttons at the right end have not been pushed off by it: they are on the first line, where they were along it.
    ${middle}=    Evaluate    (${icon_top} + ${icon_bottom}) // 2
    Icon Should Be At    ${GEAR_X}    ${middle}
    Icon Should Be At    ${GLOBE_X}    ${middle}
    Icon Should Be At    ${INFO_X}    ${middle}
    # A click on the button, where it is now, shows the pane.
    Click At    ${WS_STATUS_X}    ${middle}
    Set Layout Shift    ${shift}
    Pane Should Be Open

TC-WSP-247 The Buttons At The Right End Are Where They Were Before There Was A Pane
    [Documentation]    The ⚙, the 🌐 and the ⓘ, and nothing at the place where the pane's button was when it was the last of them
    ...    (x 1094): that button is at the other end now.
    [Tags]    p1    undocked-only
    Icon Should Be At    ${GEAR_X}    ${WS_STATUS_Y}
    Icon Should Be At    ${GLOBE_X}    ${WS_STATUS_Y}
    Icon Should Be At    ${INFO_X}    ${WS_STATUS_Y}
    Nothing Should Be Drawn At    ${OLD_PLACE_X}    ${WS_STATUS_Y}    10
    Click At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Pane Should Be Open
    Icon Should Be At    ${GEAR_X}    ${WS_STATUS_Y}
    Icon Should Be At    ${GLOBE_X}    ${WS_STATUS_Y}
    Icon Should Be At    ${INFO_X}    ${WS_STATUS_Y}
    Nothing Should Be Drawn At    ${OLD_PLACE_X}    ${WS_STATUS_Y}    10

*** Keywords ***
Nothing Should Be Drawn At
    [Documentation]    Nothing is drawn within `reach` points of the point, left and right and over the height of a button (in the
    ...    ink of a button: any channel under 60 is the bar's).
    [Arguments]    ${x}    ${y}    ${reach}=10
    ${left}=    Evaluate    int(${x}) - int(${reach})
    ${top}=    Evaluate    int(${y}) - 8
    ${width}=    Evaluate    2 * int(${reach})
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    ${left}    ${top}    ${width}    16    threshold=60

Where The Status Text Begins
    [Documentation]    The x (in the window) of the left edge of the first letter of the text in the bar, read from the column that
    ...    is after the button's, on the line that the button is in.
    ${left}    ${top}    ${right}    ${bottom}=    Get Ink Bounds    ${TEXT_FROM_X}    779    300    18    threshold=100
    ${at}=    Evaluate    ${TEXT_FROM_X} + ${left}
    RETURN    ${at}

Submit Source By Paste
    [Documentation]    The source field holds this text (pasted: a long path is typed in half a minute) and Enter is pressed.
    [Arguments]    ${text}
    Set Clipboard    ${text}
    Click At    ${SOURCE_FIELD_X}    ${TOOLBAR_Y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Press Keys    ctrl    v
    Sleep    0.4s
    Press Key    enter
    Sleep    0.5s
