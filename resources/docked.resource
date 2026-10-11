*** Settings ***
Documentation     What the suites of the Tools docked in the main window share: the main
...               window's row of tabs and status bar as they are with the Tools docked
...               (1200x800, Dark theme), and the keywords that go to a tab and read the row.
...               The Json Query tab is the main view moved down by the row, which the library
...               allows for while `Set Layout Shift` says so -- `Show Docked Tab` is the way to
...               a tab and sets the shift for the tab it goes to; the points that the move does
...               not make right are in docked_main.py, which is imported first so that its
...               values are the ones the suites see. The pages of the tools, in a main window
...               of this size, have the window's rows and panes of 600: their points are in the
...               suites that use them.
Variables         docked_main.py
Resource          keywords.resource

*** Variables ***
${DOCKED}            {"tools": "docked"}
# The row of tabs (y 0-22): Json Query, the five tools; the 🗗 is not here but in the status bar.
@{DT_TAB_ROW}        0      0      640    22
${DT_TAB_Y}          11
# The status bar, y 778-800: the buttons from the right are the info, the settings and the
# undock; the text of the page in front is at the left.
${SB_Y}              789
${SB_INFO_X}         1181
${SB_SETTINGS_X}     1152
${SB_UNDOCK_X}       1124

*** Keywords ***
Without Layout Shift
    [Documentation]    Runs a keyword with the main window's layout as the window has it (the
    ...    row of tabs and the status bar are not moved by the Json Query tab's shift), and puts
    ...    the shift back.
    [Arguments]    ${keyword}    @{args}    &{named}
    ${shift}=    Get Layout Shift
    Set Layout Shift    0
    TRY
        ${result}=    Run Keyword    ${keyword}    @{args}    &{named}
    FINALLY
        Set Layout Shift    ${shift}
    END
    RETURN    ${result}

Row Of Tabs Should Be There
    [Documentation]    The main window's top row is the row of tabs: it says Validate Schema
    ...    (the last tab, never the marked one at the start).
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Without Layout Shift    Region Should Contain Text    @{DT_TAB_ROW}    Validate Schema

Row Of Tabs Should Not Be There
    Without Layout Shift    Region Should Not Contain Text    @{DT_TAB_ROW}    Validate Schema

Tab Centre
    [Documentation]    The x of a word of a tab's label in the row, where OCR reads it (one
    ...    word: it reads "Format JSON" as one, and the rounded corner of the first tab
    ...    takes the J of Json off, so that tab is "Query").
    [Arguments]    ${label}
    ${x}    ${y}=    Without Layout Shift    Find Text In Region    @{DT_TAB_ROW}    ${label}
    RETURN    ${x}

Docked Tab Should Be Selected
    [Documentation]    The tab (json, merge, format, diff, patch or validate) is the one
    ...    marked: its fill, the selection blue, is somewhere in a strip across it.
    [Arguments]    ${tab}
    ${x}=    Evaluate    int(${DOCKED_TAB_X}[${tab}]) - 30
    Without Layout Shift    Region Should Contain Color    ${x}    5    60    12    0    92    128    tolerance=10

Docked Tab Should Not Be Selected
    [Arguments]    ${tab}
    ${x}=    Evaluate    int(${DOCKED_TAB_X}[${tab}]) - 30
    Without Layout Shift    Region Should Not Contain Color    ${x}    5    60    12    0    92    128    tolerance=10

Show Docked Tab
    [Documentation]    Clicks a tab of the row (json, merge, format, diff, patch or validate)
    ...    in the main window. From then on the layout is the Json Query tab's (the suites'
    ...    own, `DY` lower) or a page's (the window's), whichever the tab is.
    [Arguments]    ${tab}
    Set Layout Shift    0
    Click At    ${DOCKED_TAB_X}[${tab}]    ${DT_TAB_Y}
    Sleep    0.5s
    IF    '${tab}' == 'json'
        Set Layout Shift    ${DY}
    END

Launch Docked
    [Documentation]    The app started with the Tools docked, which shows the Json Query tab.
    ...    The layout is the window's until a case says it is the Json Query tab's (`Show
    ...    Docked Tab    json`).
    Launch Jsonquery App    settings=${DOCKED}

Icon Should Be At
    [Documentation]    Something is drawn on the point: a button's icon, which OCR cannot read
    ...    (the dimmest of them, the 🗗 of a button that is only lit by the pointer, is 108).
    [Arguments]    ${x}    ${y}
    ${left}=    Evaluate    int(${x}) - 10
    ${top}=    Evaluate    int(${y}) - 8
    Without Layout Shift    Get Ink Bounds    ${left}    ${top}    20    16    threshold=60

Nothing Should Be At
    [Arguments]    ${x}    ${y}
    ${left}=    Evaluate    int(${x}) - 10
    ${top}=    Evaluate    int(${y}) - 8
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Without Layout Shift    Get Ink Bounds    ${left}    ${top}    20    16    threshold=60
