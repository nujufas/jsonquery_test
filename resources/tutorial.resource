*** Settings ***
Documentation     The tutorial window (the 📖 button), for the suites that read its pages:
...               tutorial_pages (the lessons that teach the jq functions the app adds) and
...               any other that needs a lesson open. The window is a native window of its
...               own, titled "jsonquery — Tutorial"; once `Switch To Window` has made it
...               current, every coordinate here is relative to it. (satellites.robot has
...               the same constants for the cases about the window itself.)
...
...               The window opens 1040x720: its language tabs along the top, the lesson
...               list down the left with a filter box over it, and the lesson at the right.
...               A lesson is found by typing a word of its title in the filter box, which
...               leaves only the matching lessons in the list (with their topics opened),
...               and clicking it.
Resource          keywords.resource

*** Variables ***
${TUTORIAL_WINDOW}     jsonquery — Tutorial
${TUTORIAL_BUTTON_X}   1122
${TUTORIAL_BUTTON_Y}   11
@{LANGUAGE_TABS}       0      6      420    32
${TAB_Y}               22
${TAB_JQ_X}            28
${TAB_POINTER_X}       115
${TAB_JSONPATH_X}      229
${TAB_JMESPATH_X}      346
${FILTER_X}            130
${FILTER_Y}            84
@{LESSON_LIST}         8      98     255    300
@{LESSON_HEADING}      278    96     500    28
@{LESSON_BODY}         278    130    750    570
# The upper part of the body: an example whose caption is read here has its buttons
# (about 66px under the caption) on screen too.
@{LESSON_UPPER}        278    130    750    400
# The line above the heading ("jq › Tables & lookups"): which topic the lesson is in.
@{LESSON_TOPIC}        278    78     500    22
# With the list filtered, the first topic's header is at y 110 and the first lesson under
# it at y 131 (a row is 21px).
${FIRST_LESSON_X}      36
${FIRST_LESSON_Y}      131
# Each example has a row of buttons: "▶ Try it" (filled with the selection colour, which
# is how it is found) and, at fixed distances to the right of its centre, Load query,
# Load data and Copy query.
${TRY_IT_R}            0
${TRY_IT_G}            92
${TRY_IT_B}            128
${LOAD_QUERY_DX}       71
${LOAD_DATA_DX}        148
${COPY_QUERY_DX}       226
# At the bottom of a lesson the pager has the previous lesson's title on the left and
# the next one's on the right, each in a button that starts or ends at a fixed place.
${PAGER_Y}             672
${PREVIOUS_X}          292
${NEXT_X}              1018
# A cheat sheet row has its own ▶ at the left of the row.
${CHEAT_PLAY_X}        294

*** Keywords ***
Open Tutorial
    [Documentation]    Presses 📖 in the main window and waits for the window.
    Switch To Main Window
    Click At    ${TUTORIAL_BUTTON_X}    ${TUTORIAL_BUTTON_Y}
    Wait Until Window Exists    ${TUTORIAL_WINDOW}    timeout=8

Close Tutorial
    Close Window    ${TUTORIAL_WINDOW}
    Wait Until Window Closes    ${TUTORIAL_WINDOW}    timeout=8
    Switch To Main Window

Filter Lessons
    [Documentation]    Types `text` in the tutorial's filter box, replacing what was there.
    [Arguments]    ${text}
    Switch To Window    ${TUTORIAL_WINDOW}
    Click At    ${FILTER_X}    ${FILTER_Y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Type Text    ${text}
    Sleep    1.0s

Lesson List Should Show
    [Arguments]    ${text}
    Switch To Window    ${TUTORIAL_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{LESSON_LIST}    ${text}

Lesson List Should Not Show
    [Arguments]    ${text}
    Switch To Window    ${TUTORIAL_WINDOW}
    Region Should Not Contain Text    @{LESSON_LIST}    ${text}

Show Lesson
    [Documentation]    Opens a lesson: types `filter` in the filter box, which leaves only the
    ...    lessons that mention it, and clicks the first row of the list. Pick a filter that
    ...    only one lesson mentions (a word of its title, or of an example's caption). `check`
    ...    is then looked for in the lesson's big title line, or, with `where=body`, in the
    ...    body (a two-letter title such as IN is not read reliably); so a wrong pick fails
    ...    here.
    [Arguments]    ${filter}    ${check}    ${where}=heading
    Filter Lessons    ${filter}
    Click At    ${FIRST_LESSON_X}    ${FIRST_LESSON_Y}
    Sleep    0.8s
    IF    '${where}' == 'heading'
        Lesson Heading Should Be    ${check}
    ELSE
        Lesson Should Read    ${check}
    END

Lesson Heading Should Be
    [Documentation]    The lesson on show has this heading (OCR of the big title line).
    [Arguments]    ${heading}
    Switch To Window    ${TUTORIAL_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{LESSON_HEADING}    ${heading}

Lesson Should Read
    [Documentation]    The body of the lesson shows `text` somewhere in the window's visible
    ...    part (retried).
    [Arguments]    ${text}
    Switch To Window    ${TUTORIAL_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{LESSON_BODY}    ${text}

Scroll Lesson
    [Documentation]    Scrolls the lesson down (a positive count) or up (a negative one).
    [Arguments]    ${clicks}
    Switch To Window    ${TUTORIAL_WINDOW}
    ${down}=    Evaluate    -int(${clicks})
    Scroll At    650    450    ${down}
    Sleep    0.5s

Scroll To Example
    [Documentation]    Scrolls the lesson down, three notches at a time, until the example's
    ...    caption (a distinctive phrase of it) is read in the upper part of the body.
    [Arguments]    ${caption}
    Switch To Window    ${TUTORIAL_WINDOW}
    FOR    ${i}    IN RANGE    16
        ${seen}=    Run Keyword And Return Status
        ...    Region Should Contain Text    @{LESSON_UPPER}    ${caption}
        Exit For Loop If    ${seen}
        Scroll Lesson    3
    END
    Region Should Contain Text    @{LESSON_UPPER}    ${caption}

Example Button Centre
    [Documentation]    Where the "Try it" button of the example whose caption contains `caption`
    ...    is: (x, y) in the tutorial window, after scrolling to it. The button is the
    ...    first one under the caption, found by its fill colour -- the buttons move with
    ...    the length of every lesson, and OCR reads the white-on-blue label badly.
    [Arguments]    ${caption}
    Scroll To Example    ${caption}
    ${cx}    ${cy}=    Find Text In Region    @{LESSON_BODY}    ${caption}
    ${blocks}=    Find Color Blocks    @{LESSON_BODY}    ${TRY_IT_R}    ${TRY_IT_G}    ${TRY_IT_B}
    ${x}    ${y}=    First Block Below    ${blocks}    ${cy}
    RETURN    ${x}    ${y}

Click Example Button
    [Documentation]    Presses `button` (Try it, Load query, Load data or Copy query) of the
    ...    example whose caption contains `caption`.
    [Arguments]    ${button}    ${caption}
    ${x}    ${y}=    Example Button Centre    ${caption}
    ${dx}=    Set Variable If
    ...    '${button}' == 'Try it'    0
    ...    '${button}' == 'Load query'    ${LOAD_QUERY_DX}
    ...    '${button}' == 'Load data'    ${LOAD_DATA_DX}
    ...    '${button}' == 'Copy query'    ${COPY_QUERY_DX}
    ${click_x}=    Evaluate    ${x} + ${dx}
    Click At    ${click_x}    ${y}

Try Example
    [Documentation]    Presses "Try it" on the example whose caption contains `caption`, then
    ...    waits in the main window until the query has run there (a fresh app has no
    ...    "Query ran" line before it, so the line is the proof).
    [Arguments]    ${caption}
    Click Example Button    Try it    ${caption}
    Switch To Main Window
    Wait Until Region Matches    @{STATUS_BAR}    result\\(s\\)|error    timeout=12

Go To Next Lesson
    [Documentation]    Scrolls to the bottom of the lesson and presses the button of the next
    ...    lesson, in the pager's right corner.
    Scroll Lesson    80
    Click At    ${NEXT_X}    ${PAGER_Y}
    Sleep    0.8s

Go To Previous Lesson
    Scroll Lesson    80
    Click At    ${PREVIOUS_X}    ${PAGER_Y}
    Sleep    0.8s

Try Cheat Sheet Row
    [Documentation]    Presses the ▶ of the cheat sheet row whose description contains
    ...    `phrase`, then waits until the query has run in the main window. The row is
    ...    found by its description, the plain words at the right of the row.
    [Arguments]    ${phrase}
    Switch To Window    ${TUTORIAL_WINDOW}
    Scroll Lesson    10
    ${x}    ${y}=    Find Text In Region    @{LESSON_BODY}    ${phrase}
    Click At    ${CHEAT_PLAY_X}    ${y}
    Switch To Main Window
    Wait Until Region Matches    @{STATUS_BAR}    result\\(s\\)|error    timeout=12
