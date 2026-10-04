*** Settings ***
Documentation     The query box's height and scrolling -- see
...               docs/04_query_bar_and_engines.md ("Query box height and
...               scrolling"). The panel is as tall as the user drags it, and a
...               query too long for it scrolls inside it: it used to grow the
...               panel with it (taking the whole window for a long query), and
...               a drag to a shorter height was undone on the next frame.
...
...               The panel's height shows in where everything under it sits,
...               so the checks read the Source header ("Source", which
...               follows the panel's bottom edge down and up) rather than
...               the edge itself; what is in the box is read from its first
...               and last text row. The query text is `#` comment lines: plain
...               white text on black reads far more reliably than a tinted
...               query (see Query Box Should Contain Text), and the box
...               doesn't care what it holds.
Resource          ../../resources/keywords.resource
Force Tags        query_box_layout
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The panel's bottom edge at its default height, where its resize handle is:
# the handle is a few pixels either side of it.
${PANEL_EDGE_Y}          125
# The Source header's row at the default height, then after the panel's edge
# has been dragged to y=300 / y=90 / the shortest it goes. The header sits
# ~18px under the edge.
@{HEADER_DEFAULT}        0    135    300    22
@{HEADER_AT_300}         0    308    300    22
@{HEADER_AT_90}          0    98     300    22
@{HEADER_AT_SHORTEST}    0    92     300    22
# The box's first and last text rows at the default height: the box spans
# y 51-116 and holds four rows of text.
@{BOX_FIRST_ROW}         0    50     700    20
@{BOX_LAST_ROW}          0    96     700    20

*** Keywords ***
Paste Long Query
    [Documentation]    Puts a query of ${lines} comment lines into the box by
    ...    pasting it. The cursor ends up after the last line, whose text is
    ...    LASTLINE; the first line's is FIRSTLINE.
    [Arguments]    ${lines}=25
    ${text}=    Evaluate
    ...    chr(10).join(["# FIRSTLINE"] + [f"# row {i:02d} abcdef" for i in range(2, ${lines})] + ["# LASTLINE"])
    Set Clipboard    ${text}
    Click At    100    58
    Sleep    0.3s
    Press Keys    ctrl    v
    Sleep    1s

Box Row Should Contain
    [Documentation]    OCR of one row of the box, retried: a scroll is animated
    ...    and a screenshot can catch it half way.
    [Arguments]    ${text}    @{region}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{region}    ${text}    flatten_tints=${True}

Box Row Should Not Contain
    [Arguments]    ${text}    @{region}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Not Contain Text    @{region}    ${text}

Source Header Should Be At
    [Documentation]    The "Source" heading is in this region -- so the query
    ...    panel above it ends where that implies.
    [Arguments]    @{region}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{region}    Source

Drag Panel Edge
    [Arguments]    ${from_y}    ${to_y}
    Drag Mouse    600    ${from_y}    600    ${to_y}
    Sleep    0.5s

*** Test Cases ***
TC-QRY-080 A Long Query Scrolls Inside The Box Instead Of Taking Over The Window
    [Documentation]    A 25-line query leaves the panel at its default height:
    ...    the Source header is exactly where it is with an empty box. The box
    ...    shows the end of the query, where the cursor is.
    [Tags]    p1
    Source Header Should Be At    @{HEADER_DEFAULT}
    Paste Long Query    25
    Source Header Should Be At    @{HEADER_DEFAULT}
    Box Row Should Contain    LASTLINE    @{BOX_LAST_ROW}
    Box Row Should Not Contain    FIRSTLINE    @{BOX_FIRST_ROW}

TC-QRY-081 A Dragged Height Sticks For A Long Query
    [Documentation]    Drag the panel's bottom edge down and the header follows;
    ...    typing in the long query does not move it back; drag it up again --
    ...    the case that used to snap back to the query's full height -- and
    ...    it stays there too.
    [Tags]    p1
    Paste Long Query    25
    Drag Panel Edge    ${PANEL_EDGE_Y}    300
    Source Header Should Be At    @{HEADER_AT_300}
    Click At    100    200
    Type Text    typed
    Sleep    0.5s
    Source Header Should Be At    @{HEADER_AT_300}
    Drag Panel Edge    299    90
    Source Header Should Be At    @{HEADER_AT_90}
    Click At    100    70
    Type Text    more
    Sleep    0.5s
    Source Header Should Be At    @{HEADER_AT_90}

TC-QRY-082 The Panel Cannot Be Dragged Shorter Than Its Header And One Row
    [Documentation]    Dragging the edge up past the top stops at the minimum
    ...    height -- even for a query long enough that it used to hold the
    ...    panel open. (What the one-row box shows is not asserted: shrinking
    ...    keeps the top of the view where it was.)
    [Tags]    p2
    Paste Long Query    25
    Drag Panel Edge    ${PANEL_EDGE_Y}    30
    Source Header Should Be At    @{HEADER_AT_SHORTEST}

TC-QRY-083 Typing At The End Of A Long Query Keeps The Cursor In View
    [Documentation]    Each new line scrolls the box so the one being typed is
    ...    the bottom row; the panel does not grow to fit it. (Markers are
    ...    followed by another word: the caret clips the character next to
    ...    it in an OCR read.)
    [Tags]    p1
    Paste Long Query    25
    Type Text    ${SPACE}ZZTOP end
    Box Row Should Contain    ZZTOP    @{BOX_LAST_ROW}
    Press Key    enter
    Type Text    \# AFTERNEWLINE end
    Box Row Should Contain    AFTERNEWLINE    @{BOX_LAST_ROW}
    Source Header Should Be At    @{HEADER_DEFAULT}

TC-QRY-084 The Mouse Wheel Scrolls A Long Query
    [Documentation]    With the cursor sent to the top of the query the first
    ...    line is in view; the wheel then moves the box down through it.
    [Tags]    p2
    Paste Long Query    25
    Press Keys    ctrl    home
    Box Row Should Contain    FIRSTLINE    @{BOX_FIRST_ROW}
    Scroll At    300    80    -10
    Box Row Should Not Contain    FIRSTLINE    @{BOX_FIRST_ROW}
    Source Header Should Be At    @{HEADER_DEFAULT}

TC-QRY-085 A Short Query Behaves As Before
    [Documentation]    A one-line query shows at the top of the box and the
    ...    panel keeps its default height -- nothing scrolls.
    [Tags]    p2
    Click At    100    58
    Type Text    \# FIRSTLINE only
    Box Row Should Contain    FIRSTLINE    @{BOX_FIRST_ROW}
    Source Header Should Be At    @{HEADER_DEFAULT}
