*** Settings ***
Documentation     The look of the panes' headers -- see docs/15_pane_headers.md.
...               The titles ("Source", "Results") are 14px strong text, not 18px
...               headings; there is no line under a header (the one divider is the
...               panel's edge above the panes), so what is under it starts 12px
...               higher than it did; and the Tools window's boxes have the same
...               small titles and no line under theirs.
...
...               OCR cannot say how big text is or whether a line is drawn, so
...               these cases look at pixels: the bounds of the title's glyphs
...               (a 14px "Source" is 10px tall, the old 18px heading was 12), a
...               strip between header and content that must be bare background,
...               and where the first line of content starts. Measured on
...               screenshots of the 1200x800 window in the Dark theme.
Resource          ../../resources/tools.resource
Force Tags        pane_headers
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${PEOPLE}            [{"name":"Alice","age":34},{"name":"Bob","age":19}]
${SOURCE_WINDOW}     jsonquery — Source
# The titles: the glyphs of "Source" at x 8-49, y 138-147 and of "Results" at x 609-652,
# y 137-147. A box just around each, clear of the Tree/Text tabs that follow them.
@{SOURCE_TITLE}      0      128    64     28
@{RESULTS_TITLE}     604    128    60     28
# The strips between a header (which ends at y=152) and what is under it: across the
# pane, right of where the first tree row's text ends (x 127) and left of the header's
# buttons -- bare background if there is no line. (The old layout had a line at y=160.)
@{UNDER_SOURCE_HEADER}     150    153    340    12
@{UNDER_RESULTS_HEADER}    760    153    340    12
# The same where the pane is empty and its hint is showing (up to x=342).
@{UNDER_EMPTY_SOURCE_HEADER}    400    153    190    12
# The gap above the headers, under the panel's edge at y=125 (the one divider).
@{ABOVE_HEADERS}     0      127    592    6
@{PANEL_EDGE}        0      124    592    3
# The first line of the Source tree: where its text starts.
@{FIRST_TREE_ROW}    8      153    122    24
@{FIRST_HINT_ROW}    0      153    592    22
# In the Source window (window-relative): its header is under the row of the source
# field, at y=41.
@{WINDOW_TITLE}      0      30     64     26
@{UNDER_WINDOW_HEADER}    160    50    330    8
# In the Tools window: the Result pane's title.
@{TOOLS_RESULT_TITLE}    452    52     64     24

*** Keywords ***
Ink Height Should Be At Most
    [Documentation]    The glyphs in the region are at most this many pixels tall.
    [Arguments]    ${limit}    @{region}
    ${left}    ${top}    ${right}    ${bottom}=    Get Ink Bounds    @{region}
    ${height}=    Evaluate    ${bottom} - ${top} + 1
    Should Be True    ${height} <= ${limit}    msg=The text is ${height}px tall, expected at most ${limit}
    Should Be True    ${height} >= 7    msg=The text is only ${height}px tall: is it text?

Ink Should Start Within
    [Documentation]    The first bright pixel of the region is within `limit` pixels
    ...    of its top: the content starts close under the header.
    [Arguments]    ${limit}    ${threshold}    @{region}
    ${left}    ${top}    ${right}    ${bottom}=    Get Ink Bounds    @{region}    threshold=${threshold}
    Should Be True    ${top} <= ${limit}    msg=Content starts ${top}px under the header, expected within ${limit}

Load People
    Load Fixture Via Paste    ${PEOPLE}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    2 items

*** Test Cases ***
TC-HDR-001 The Panes' Titles Are Small
    [Documentation]    "Source" and "Results" are 14px strong text: at most 11 pixels
    ...    tall (an 18px heading was 12 to 14), where the glyphs of the old heading
    ...    would not fit.
    [Tags]    p1
    Load People
    Ink Height Should Be At Most    11    @{SOURCE_TITLE}
    Ink Height Should Be At Most    11    @{RESULTS_TITLE}

TC-HDR-002 There Is No Line Under The Headers
    [Documentation]    With a document loaded, the strips between each header and
    ...    its tree are bare background: no divider is drawn under a header.
    [Tags]    p1
    Load People
    Region Should Be Plain    @{UNDER_SOURCE_HEADER}
    Region Should Be Plain    @{UNDER_RESULTS_HEADER}

TC-HDR-003 There Is No Line Under The Headers Of Empty Panes Either
    [Documentation]    The same with nothing loaded: the empty Source pane's hint
    ...    follows its title and no line is between them.
    [Tags]    p1
    Region Should Be Plain    @{UNDER_EMPTY_SOURCE_HEADER}
    Region Should Be Plain    @{UNDER_RESULTS_HEADER}

TC-HDR-004 The Panel's Edge Is The One Divider
    [Documentation]    The line above the panes (the query panel's edge, y=125) is
    ...    there, and nothing is drawn between it and the headers.
    [Tags]    p1
    Region Should Contain Color    @{PANEL_EDGE}    60    60    60    tolerance=4
    Region Should Be Plain    @{ABOVE_HEADERS}

TC-HDR-005 The Tree Starts Right Under The Header
    [Documentation]    The first line of a tree starts within a few pixels of the
    ...    header's bottom edge, not a header's height and a line's lower (the old
    ...    layout started it 12px later).
    [Tags]    p1
    Load People
    Ink Should Start Within    9    70    @{FIRST_TREE_ROW}

TC-HDR-006 The Empty Source Pane's Hint Is Right Under Its Title
    [Documentation]    "Drag & drop a file anywhere ..." is the first thing under
    ...    "Source" with nothing between them.
    [Tags]    p2
    Ink Should Start Within    8    70    @{FIRST_HINT_ROW}

TC-HDR-007 The Headers Still Have Their Controls
    [Documentation]    Smaller titles took nothing away: each header has its
    ...    title, the Tree and Text tabs and the Save button, and the pop-out
    ...    icon at the far right.
    [Tags]    p1
    Load People
    Region Should Contain Text    @{SOURCE_HEADER}    Source
    Region Should Contain Text    @{SOURCE_HEADER}    Tree
    Region Should Contain Text    @{SOURCE_HEADER}    Text
    Region Should Contain Text    @{RESULTS_HEADER}    Results
    Region Should Contain Text    @{RESULTS_HEADER}    Tree
    Region Should Contain Text    @{RESULTS_HEADER}    Text
    Region Should Contain Text    @{RESULTS_SAVE_BUTTON}    Save
    ${left}    ${top}    ${right}    ${bottom}=    Get Ink Bounds    570    134    24    20    threshold=60
    Should Be True    ${top} >= 0

TC-HDR-008 No Line Under A Header In The Light Theme
    [Documentation]    Likewise with the Light theme: the strips under the headers
    ...    are bare background.
    [Tags]    p2
    Load People
    Click At    ${THEME_TOGGLE_X}    ${THEME_TOGGLE_Y}
    Sleep    0.8s
    Region Should Be Plain    @{UNDER_SOURCE_HEADER}
    Region Should Be Plain    @{UNDER_RESULTS_HEADER}

TC-HDR-009 The Source Window Has The Same Small Title And No Line
    [Documentation]    The Source pane in its own window: the title is as small and
    ...    no line is under the header (which is under the window's source row).
    [Tags]    p1
    Load People
    Click At    583    144
    Wait Until Window Exists    ${SOURCE_WINDOW}
    Switch To Window    ${SOURCE_WINDOW}
    Sleep    0.5s
    Ink Height Should Be At Most    11    @{WINDOW_TITLE}
    Region Should Be Plain    @{UNDER_WINDOW_HEADER}

TC-HDR-010 The Tools Window's Panes Have The Same Titles
    [Documentation]    The Tools window's headers are built from the same parts as
    ...    the main window's: its "Result" title is as small.
    [Tags]    p1
    Open Tool    format
    Ink Height Should Be At Most    11    @{TOOLS_RESULT_TITLE}
