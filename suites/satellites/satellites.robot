*** Settings ***
Documentation     The tutorial window (📖) and the About window (ⓘ) -- see
...               docs/14_tutorial_and_about_windows.md. Both are native
...               windows of their own (titled "jsonquery — Tutorial" and
...               "jsonquery — About"), like the Tools window: eframe redraws
...               each by itself and the app answers through a lock, so they keep
...               working when the main window is not being redrawn (see "Not
...               reachable" in 13_tools_window.md for the Wayland bug that
...               motivated that, which cannot be seen under X).
...
...               Under X these cases drive what a person does: open the window,
...               read it, use it, hand an example to the main window, close it
...               (through the window manager -- the windows are undecorated, like
...               the others), maximize it and use it again.
Resource          ../../resources/keywords.resource
Library           OperatingSystem
Force Tags        satellites
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The app is its own repository (jsonquery_gui), beside this one; run.sh exports JQ_APP_DIR.
${APP_DIR}             %{JQ_APP_DIR=${CURDIR}/../../../jsonquery_gui}
${TUTORIAL_WINDOW}     jsonquery — Tutorial
${ABOUT_WINDOW}        jsonquery — About
${TOOLS_WINDOW}        jsonquery — Tools
# The icon buttons of the main window's toolbar (icon only, so fixed points).
${TUTORIAL_X}          1122
${TUTORIAL_Y}          11
${TOOLS_X}             1094
${ABOUT_X}             1181
${ABOUT_Y}             789
# The tutorial window (1040x720 when it opens): its language tabs along the top,
# the lesson list down the left (a filter box over it) and the lesson at the right.
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
# Lessons of the first group, "Getting started", as the list shows them when it opens.
${LESSON_NESTING_X}    95
${LESSON_NESTING_Y}    152
${LESSON_SLICE_X}      82
${LESSON_SLICE_Y}      173
# The first lesson has two examples; each has a row of buttons: ▶ Try it, Load query,
# Load data, Copy query.
${TRY_IT_X}            317
${LOAD_QUERY_X}        388
${LOAD_DATA_X}         465
${COPY_QUERY_X}        543
${FIRST_EXAMPLE_Y}     321
${SECOND_EXAMPLE_Y}    552
# The About window.
@{ABOUT_TEXT}          0      0      380    230

*** Keywords ***
Open Tutorial
    Switch To Main Window
    Click At    ${TUTORIAL_X}    ${TUTORIAL_Y}
    Wait Until Window Exists    ${TUTORIAL_WINDOW}    timeout=8

Open About
    Switch To Main Window
    Click At    ${ABOUT_X}    ${ABOUT_Y}
    Wait Until Window Exists    ${ABOUT_WINDOW}    timeout=8

Window Should Read
    [Documentation]    OCR of a region of the named window (retried), from
    ...    wherever the test is; the window the test was in is current again
    ...    afterwards.
    [Arguments]    ${title}    ${text}    @{region}
    Switch To Window    ${title}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{region}    ${text}
    Switch To Main Window

Pick Language
    [Arguments]    ${x}
    Click At    ${x}    ${TAB_Y}
    Sleep    0.6s

Cargo Version
    [Documentation]    The version the workspace says it is, from Cargo.toml.
    ${toml}=    Get File    ${APP_DIR}/Cargo.toml
    ${version}=    Evaluate    re.search(r'^version\\s*=\\s*"([^"]+)"', $toml, re.M).group(1)    modules=re
    RETURN    ${version}

*** Test Cases ***
TC-SAT-001 The Tutorial Button Opens The Tutorial Window
    [Documentation]    One click on 📖 opens a window titled "jsonquery — Tutorial"
    ...    with a tab for each query language and the lessons of the first.
    [Tags]    p1
    Open Tutorial
    Window Should Read    ${TUTORIAL_WINDOW}    JSON Pointer    @{LANGUAGE_TABS}
    Window Should Read    ${TUTORIAL_WINDOW}    JMESPath    @{LANGUAGE_TABS}
    Window Should Read    ${TUTORIAL_WINDOW}    Getting started    @{LESSON_LIST}
    Window Should Read    ${TUTORIAL_WINDOW}    Filtering    @{LESSON_LIST}

TC-SAT-002 The Tutorial Opens On The First Lesson
    [Documentation]    The first lesson of the jq tab, "Identity & fields", is
    ...    showing, with its sample data and its examples.
    [Tags]    p1
    Open Tutorial
    Window Should Read    ${TUTORIAL_WINDOW}    Identity    @{LESSON_HEADING}
    Window Should Read    ${TUTORIAL_WINDOW}    Sample data    @{LESSON_BODY}
    Window Should Read    ${TUTORIAL_WINDOW}    Try it    @{LESSON_BODY}
    Window Should Read    ${TUTORIAL_WINDOW}    Result    @{LESSON_BODY}

TC-SAT-003 Picking Another Lesson Shows It
    [Documentation]    A click on "Nesting & missing keys" in the list puts that
    ...    lesson on the right in place of the first.
    [Tags]    p1
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Click At    ${LESSON_NESTING_X}    ${LESSON_NESTING_Y}
    Sleep    0.6s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{LESSON_HEADING}    Nesting
    Region Should Not Contain Text    @{LESSON_HEADING}    Identity

TC-SAT-004 Another Language Has Lessons Of Its Own
    [Documentation]    The JSON Pointer tab lists the lessons of that language, not
    ...    the jq ones: jq's "Pipes & building output" is not among them, and its
    ...    first group is "Basics".
    [Tags]    p1
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Region Should Contain Text    @{LESSON_LIST}    Pipes
    Pick Language    ${TAB_POINTER_X}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Not Contain Text    @{LESSON_LIST}    Pipes
    Region Should Contain Text    @{LESSON_LIST}    Basics

TC-SAT-005 Typing In The Filter Narrows The Lessons
    [Documentation]    The filter box over the list keeps the lessons that match
    ...    ("slice"): "Array index & slice" stays and "Identity & fields" goes.
    [Tags]    p1
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Click At    ${FILTER_X}    ${FILTER_Y}
    Sleep    0.2s
    Type Text    slice
    Sleep    0.8s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{LESSON_LIST}    slice
    Region Should Not Contain Text    @{LESSON_LIST}    Identity

TC-SAT-006 Try It Hands The Example To The Main Window
    [Documentation]    "▶ Try it" on the first example loads its sample data and its
    ...    query into the main window and runs it: the status bar there says one
    ...    result, and the Source pane shows the sample ("Ada").
    [Tags]    p1
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Click At    ${TRY_IT_X}    ${FIRST_EXAMPLE_Y}
    Switch To Main Window
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_BAR}    1 result
    Region Should Contain Text    @{SOURCE_PANEL}    Ada    flatten_tints=${True}

TC-SAT-007 Load Query Puts Only The Query In The Main Window
    [Documentation]    "Load query" on the second example (".name") writes the
    ...    query into the main window's query box and loads nothing: no document
    ...    is loaded, so the Source pane still waits for one.
    [Tags]    p1
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Click At    ${LOAD_QUERY_X}    ${SECOND_EXAMPLE_Y}
    Switch To Main Window
    Sleep    0.8s
    Query Text Should Be    .name
    Region Should Contain Text    @{SOURCE_PANEL}    Paste JSON here

TC-SAT-008 Load Data Puts Only The Sample In The Main Window
    [Documentation]    "Load data" loads the example's sample document and leaves
    ...    the query box as it was: empty.
    [Tags]    p1
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Click At    ${LOAD_DATA_X}    ${FIRST_EXAMPLE_Y}
    Switch To Main Window
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    Ada    flatten_tints=${True}
    Region Should Contain Text    @{QUERY_TEXTBOX}    e.g.

TC-SAT-009 Copy Query Copies The Query
    [Documentation]    "Copy query" on the second example puts ".name" on the
    ...    clipboard.
    [Tags]    p2
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Set Clipboard    nothing was copied
    Click At    ${COPY_QUERY_X}    ${SECOND_EXAMPLE_Y}
    Sleep    0.5s
    ${copied}=    Get Clipboard
    Should Be Equal    ${copied}    .name

TC-SAT-010 Closing The Tutorial And Pressing The Button Again Reopens It
    [Documentation]    Closing the window (through the window manager) and
    ...    pressing 📖 again gives a fresh tutorial, on its first lesson.
    [Tags]    p1
    Open Tutorial
    Close Window    ${TUTORIAL_WINDOW}
    Wait Until Window Closes    ${TUTORIAL_WINDOW}    timeout=8
    Open Tutorial
    Window Should Read    ${TUTORIAL_WINDOW}    Identity    @{LESSON_HEADING}

TC-SAT-011 A Second Press Does Not Open A Second Tutorial
    [Documentation]    With the window open, pressing 📖 brings it forward: there
    ...    is still one window of that name.
    [Tags]    p2
    Open Tutorial
    Switch To Main Window
    Click At    ${TUTORIAL_X}    ${TUTORIAL_Y}
    Sleep    0.8s
    ${windows}=    Count Windows    ${TUTORIAL_WINDOW}
    Should Be Equal As Integers    ${windows}    1

TC-SAT-012 A Maximized Tutorial Still Responds And Closes
    [Documentation]    Maximized, the tutorial covers the whole screen, the main
    ...    window under it: it is still redrawn and answers a click on a lesson
    ...    (not drawn as a part of the main window's frame, which GNOME stops
    ...    redrawing then -- that cannot be seen under X). Closing it leaves the
    ...    main window working.
    [Tags]    p1
    Open Tutorial
    Maximize Window    ${TUTORIAL_WINDOW}
    Switch To Window    ${TUTORIAL_WINDOW}
    ${width}    ${height}=    Get Window Size
    Should Be True    ${width} > 1100
    Click At    ${LESSON_NESTING_X}    ${LESSON_NESTING_Y}
    Sleep    0.8s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{LESSON_HEADING}    Nesting
    Close Window    ${TUTORIAL_WINDOW}
    Wait Until Window Closes    ${TUTORIAL_WINDOW}    timeout=8
    Switch To Main Window
    Load Fixture Via Paste    {"members":[{"name":"Ann"}],"team":"platypus"}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    platypus    flatten_tints=${True}

TC-SAT-013 The Main Window Works With The Tutorial Open
    [Documentation]    A query typed and run in the main window with the tutorial
    ...    open gives its result there.
    [Tags]    p2
    Open Tutorial
    Switch To Main Window
    Load Fixture Via Paste    {"members":[{"name":"Ann"}],"team":"platypus"}
    Run Query    .team
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{RESULTS_PANEL}    platypus    flatten_tints=${True}

TC-SAT-014 The Tutorial Follows The Main Window's Theme
    [Documentation]    The ☀ button turns the tutorial light too: its background
    ...    goes from dark to light.
    [Tags]    p2
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    ${dark}=    Get Pixel Color    700    700
    Should Be True    max(${dark}) < 80    msg=Expected the dark theme to start with: ${dark}
    Switch To Main Window
    Click At    ${THEME_TOGGLE_X}    ${THEME_TOGGLE_Y}
    Sleep    0.8s
    Switch To Window    ${TUTORIAL_WINDOW}
    ${light}=    Get Pixel Color    700    700
    Should Be True    min(${light}) > 150    msg=Expected the light theme in the tutorial: ${light}

TC-SAT-020 The Info Button Opens The About Window
    [Documentation]    The ⓘ button at the right end of the status bar opens a window
    ...    titled "jsonquery — About": the name and version, the license, and the
    ...    links.
    [Tags]    p1
    Open About
    Window Should Read    ${ABOUT_WINDOW}    jsonquery gui    @{ABOUT_TEXT}
    Window Should Read    ${ABOUT_WINDOW}    License    @{ABOUT_TEXT}
    Window Should Read    ${ABOUT_WINDOW}    MIT    @{ABOUT_TEXT}
    Window Should Read    ${ABOUT_WINDOW}    Privacy policy    @{ABOUT_TEXT}
    Window Should Read    ${ABOUT_WINDOW}    Known limitations    @{ABOUT_TEXT}

TC-SAT-021 About Says The Version Of The Build
    [Documentation]    The version in the window is the workspace's (Cargo.toml's).
    [Tags]    p1
    ${version}=    Cargo Version
    Open About
    Window Should Read    ${ABOUT_WINDOW}    v${version}    @{ABOUT_TEXT}

TC-SAT-022 Closing About And Pressing The Button Again Reopens It
    [Documentation]    Closed through the window manager, the window goes; the
    ...    button gives another.
    [Tags]    p1
    Open About
    Close Window    ${ABOUT_WINDOW}
    Wait Until Window Closes    ${ABOUT_WINDOW}    timeout=8
    Open About
    Window Should Read    ${ABOUT_WINDOW}    License    @{ABOUT_TEXT}

TC-SAT-023 The Main Window Works With About Open
    [Documentation]    With About open, a document still loads in the main window.
    [Tags]    p2
    Open About
    Switch To Main Window
    Load Fixture Via Paste    {"members":[{"name":"Ann"}],"team":"platypus"}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    platypus    flatten_tints=${True}

TC-SAT-030 All The Windows Can Be Open Together
    [Documentation]    The Tools window, the tutorial and About open at once, each
    ...    a window of its own, and the main window still takes a query and
    ...    shows its result.
    [Tags]    p1
    Click At    ${TOOLS_X}    ${TUTORIAL_Y}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Open Tutorial
    Open About
    Switch To Main Window
    ${windows}=    List Windows
    ${names}=    Evaluate    [w[1] for w in $windows]
    Should Contain    ${names}    ${TOOLS_WINDOW}
    Should Contain    ${names}    ${TUTORIAL_WINDOW}
    Should Contain    ${names}    ${ABOUT_WINDOW}
    Load Fixture Via Paste    {"members":[{"name":"Ann"}],"team":"platypus"}
    Run Query    .team
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{RESULTS_PANEL}    platypus    flatten_tints=${True}

TC-SAT-031 Closing One Window Leaves The Others
    [Documentation]    Closing the tutorial leaves About and the Tools window as
    ...    they were.
    [Tags]    p2
    Click At    ${TOOLS_X}    ${TUTORIAL_Y}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Open Tutorial
    Open About
    Close Window    ${TUTORIAL_WINDOW}
    Wait Until Window Closes    ${TUTORIAL_WINDOW}    timeout=8
    Window Should Read    ${ABOUT_WINDOW}    License    @{ABOUT_TEXT}
    ${tools}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${tools}    1
