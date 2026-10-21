*** Settings ***
Documentation     The tutorial window (📖) and the About window (ⓘ) -- see
...               docs/14_tutorial_and_about_windows.md. Both are native
...               windows of their own (titled "JsonQuery — Tutorial" and
...               "JsonQuery — About"), like the Tools window: eframe redraws
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
${TUTORIAL_WINDOW}     JsonQuery — Tutorial
${ABOUT_WINDOW}        JsonQuery — About
${TOOLS_WINDOW}        JsonQuery — Tools
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
# The About window (380x330 when it opens, 320x330 at the least): the whole of it, the row of
# the website (between the source and the issues), the foot with the last link (at 320 wide
# the text above wraps further, so the foot is lower) and, under it, the header of the known
# issues.
@{ABOUT_TEXT}          0      0      380    330
@{ABOUT_WEBSITE_ROW}   0      80     380    28
@{ABOUT_FOOT}          0      250    380    30
@{ABOUT_FOOT_NARROW}   0      265    320    30
@{ABOUT_HEADER}        0      278    380    30
@{ABOUT_HEADER_NARROW}  0     294    320    34
# Opening the list makes the window this wide, and not taller than 9/10 of the test display (900).
${LIST_WIDTH}          640
${LIST_MOST_HIGH}      810
# Where the window is put before the list is opened: the window manager puts it at the corner of
# the screen the pointer was at, and a window made bigger there would be partly off the display.
${ABOUT_HOME_X}        100
${ABOUT_HOME_Y}        40
# What a click on a link to the site hands to the browser (the app's browser crate writes the slash).
${WEBSITE_ADDRESS}     https://jsonquery.dev/
# ... and on the link under the list, to the page of the issues that are not in the window.
${ISSUES_ADDRESS}      https://github.com/nujufas/jsonquery_gui/blob/master/docs/known-issues.md

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

Get Window Size For
    [Documentation]    The size of the named window, from wherever the test is; the window
    ...    the test was in is current again afterwards.
    [Arguments]    ${title}
    Switch To Window    ${title}
    ${width}    ${height}=    Get Window Size
    Switch To Main Window
    RETURN    ${width}    ${height}

Window Should Be Size
    [Arguments]    ${title}    ${width}    ${height}
    ${w}    ${h}=    Get Window Size For    ${title}
    Should Be Equal As Integers    ${w}    ${width}
    Should Be Equal As Integers    ${h}    ${height}

Window Should Become Size
    [Documentation]    The named window is this size within a few seconds (a window manager
    ...    answers a request for another size when it gets to it).
    [Arguments]    ${title}    ${width}    ${height}
    Wait Until Keyword Succeeds    12x    0.5s    Window Should Be Size    ${title}    ${width}    ${height}

Known Issues Count
    [Documentation]    How many issues the app's list has: docs/known-issues.md is made from it (a
    ...    test in the app keeps it so), a line in bold for each.
    ${page}=    Get File    ${APP_DIR}/docs/known-issues.md
    ${count}=    Evaluate    len(re.findall(r'^\\*\\*.+\\*\\*$', $page, re.M))    modules=re
    RETURN    ${count}

Known Issue Groups
    [Documentation]    The titles of the groups the window shows, in order: the page's headings, but
    ...    the last, which is about what jq does not have either.
    ${page}=    Get File    ${APP_DIR}/docs/known-issues.md
    @{titles}=    Evaluate    [t for t in re.findall(r'^## (.+)$', $page, re.M) if not t.startswith('Not in jq')]    modules=re
    RETURN    @{titles}

Open About Up In The Corner
    [Documentation]    About, moved to where it has room to grow.
    Open About
    Move Window    ${ABOUT_WINDOW}    ${ABOUT_HOME_X}    ${ABOUT_HOME_Y}

About Region
    [Documentation]    The whole of the About window as it is now: its width, and its height.
    Switch To Window    ${ABOUT_WINDOW}
    ${width}    ${height}=    Get Window Size
    RETURN    0    0    ${width}    ${height}

Click The Known Issues Header
    Switch To Window    ${ABOUT_WINDOW}
    @{region}=    About Region
    ${x}    ${y}=    Find Text In Region    @{region}    Known issues
    Click At    ${x}    ${y}

Window Should Be As Big As The List Makes It
    ${width}    ${height}=    Get Window Size For    ${ABOUT_WINDOW}
    Should Be Equal As Integers    ${width}    ${LIST_WIDTH}
    Should Be True    330 < ${height} <= ${LIST_MOST_HIGH}
    ...    msg=The window is ${width} by ${height}: taller than it was and not taller than the display has room for

Open The Known Issues
    [Documentation]    About, up in the corner, with the list opened and the window as big as it makes itself.
    Open About Up In The Corner
    Click The Known Issues Header
    Wait Until Keyword Succeeds    12x    0.5s    Window Should Be As Big As The List Makes It

About Should Be 800 Wide And Taller Than It Was
    ${width}    ${height}=    Get Window Size For    ${ABOUT_WINDOW}
    Should Be Equal As Integers    ${width}    800
    Should Be True    ${height} > 330 and ${height} <= ${LIST_MOST_HIGH}

About Should Show
    [Arguments]    ${text}
    Switch To Window    ${ABOUT_WINDOW}
    @{region}=    About Region
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{region}    ${text}
    Switch To Main Window

About Should Not Show
    [Arguments]    ${text}
    Switch To Window    ${ABOUT_WINDOW}
    @{region}=    About Region
    Region Should Not Contain Text    @{region}    ${text}
    Switch To Main Window

Clipboard Should Be
    [Arguments]    ${expected}
    ${text}=    Get Clipboard
    Should Be Equal    ${text}    ${expected}

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
    [Documentation]    One click on 📖 opens a window titled "JsonQuery — Tutorial"
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
    ...    titled "JsonQuery — About": the name and version, the license, and the
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

TC-SAT-024 About Has A Website Row And Nothing More About The Site
    [Documentation]    A "Website:" row with the name of the site, jsonquery.dev, between the
    ...    source and the issues, and no text about the site under the rows (what is there is
    ...    said by the hover of the 🌐).
    [Tags]    p1
    Open About
    Window Should Read    ${ABOUT_WINDOW}    Website:    @{ABOUT_WEBSITE_ROW}
    Window Should Read    ${ABOUT_WINDOW}    jsonquery.dev    @{ABOUT_WEBSITE_ROW}
    Switch To Window    ${ABOUT_WINDOW}
    Region Should Not Contain Text    @{ABOUT_TEXT}    nothing to install
    Region Should Not Contain Text    @{ABOUT_TEXT}    query engine
    ${x}    ${source}=    Find Text In Region    @{ABOUT_TEXT}    Source:
    ${x}    ${website}=    Find Text In Region    @{ABOUT_TEXT}    Website:
    ${x}    ${issues}=    Find Text In Region    @{ABOUT_TEXT}    Issues
    Should Be True    ${source} < ${website} < ${issues}
    ...    msg=The rows are not in order, Source ${source}, Website ${website}, Issues ${issues}

TC-SAT-025 The Website In About Is A Link That Opens The Site
    [Documentation]    A click on "jsonquery.dev" in the Website row hands the address of the
    ...    site to the browser (a stand-in, which writes it down), once.
    [Tags]    p1
    Open About
    Switch To Window    ${ABOUT_WINDOW}
    Nothing Should Have Been Opened    settle=0.3
    ${x}    ${y}=    Find Text In Region    @{ABOUT_WEBSITE_ROW}    jsonquery.dev
    Click At    ${x}    ${y}
    Opened Addresses Should Be    ${WEBSITE_ADDRESS}

TC-SAT-026 About Shows All It Says Down To The Last Link
    [Documentation]    The window opens 380 by 330 with the last link, "More in the README", at
    ...    its foot and the header of the known issues under it; at 320 by 330, the least the
    ...    app lets it be, both are still there. (The window manager keeps a window from being
    ...    dragged smaller; `xdotool` does not ask it, so the case sets the smallest size itself
    ...    and does not try for a smaller one.)
    [Tags]    p2
    Open About
    Window Should Be Size    ${ABOUT_WINDOW}    380    330
    Window Should Read    ${ABOUT_WINDOW}    More in the README    @{ABOUT_FOOT}
    Window Should Read    ${ABOUT_WINDOW}    Known issues    @{ABOUT_HEADER}
    Resize Window    ${ABOUT_WINDOW}    320    330
    Sleep    0.8s
    Window Should Be Size    ${ABOUT_WINDOW}    320    330
    Window Should Read    ${ABOUT_WINDOW}    More in the README    @{ABOUT_FOOT_NARROW}
    Window Should Read    ${ABOUT_WINDOW}    Known issues    @{ABOUT_HEADER_NARROW}
    Window Should Read    ${ABOUT_WINDOW}    Known limitations    @{ABOUT_TEXT}

TC-SAT-040 About Has A Known Issues Header, Shut, With The Number Of Issues
    [Documentation]    Under the last link a header, "Known issues (N)", with N the number of issues
    ...    in the app's list (the page docs/known-issues.md is made from the list and has a line in
    ...    bold for each). The list is shut: nothing of it is shown, and the window has the size it
    ...    always had.
    [Tags]    p1
    ${count}=    Known Issues Count
    Open About
    Window Should Read    ${ABOUT_WINDOW}    Known issues (${count})    @{ABOUT_HEADER}
    Window Should Be Size    ${ABOUT_WINDOW}    380    330
    About Should Not Show    Programs that run differently
    About Should Not Show    Not available

TC-SAT-041 Opening The Known Issues Shows The List And Makes The Window Bigger
    [Documentation]    A click on the header opens the list and makes the window wider (640) and as tall
    ...    as the list needs (not taller than 9/10 of the display): the line about the list, the
    ...    title of each group (those of the page), some of the issues, and, at the foot, the link
    ...    to the others, which is only to be read if the window holds the whole list.
    [Tags]    p1
    @{groups}=    Known Issue Groups
    Open The Known Issues
    About Should Show    Programs that run differently here than in jq
    FOR    ${group}    IN    @{groups}
        About Should Show    ${group}
    END
    About Should Show    Modules
    About Should Show    Regex
    About Should Show    smaller ones, and more examples, in the full list

TC-SAT-042 Closing The List Shuts It And The Window Goes Back To Its Size
    [Documentation]    A second click on the header closes the list, and the window is 380 by 330 again
    ...    with the header under the link, as it was.
    [Tags]    p1
    ${count}=    Known Issues Count
    Open The Known Issues
    Click The Known Issues Header
    Window Should Become Size    ${ABOUT_WINDOW}    380    330
    About Should Not Show    Programs that run differently
    About Should Not Show    Not available
    Window Should Read    ${ABOUT_WINDOW}    Known issues (${count})    @{ABOUT_HEADER}

TC-SAT-043 The List Can Be Opened Again After It Was Shut
    [Documentation]    Open, shut and open again: the window is as big as the list makes it the second
    ...    time too, and has the list in it.
    [Tags]    p2
    Open The Known Issues
    Click The Known Issues Header
    Window Should Become Size    ${ABOUT_WINDOW}    380    330
    Click The Known Issues Header
    Wait Until Keyword Succeeds    12x    0.5s    Window Should Be As Big As The List Makes It
    About Should Show    Programs that run differently here than in jq
    About Should Show    smaller ones, and more examples, in the full list

TC-SAT-044 A Window Opened Afresh Has The List Shut
    [Documentation]    The list was open when the window was closed: the next one is 380 by 330 with
    ...    the list shut, not the size and the state the last one had.
    [Tags]    p1
    ${count}=    Known Issues Count
    Open The Known Issues
    Close Window    ${ABOUT_WINDOW}
    Wait Until Window Closes    ${ABOUT_WINDOW}    timeout=8
    Open About
    Window Should Be Size    ${ABOUT_WINDOW}    380    330
    Window Should Read    ${ABOUT_WINDOW}    Known issues (${count})    @{ABOUT_HEADER}
    About Should Not Show    Programs that run differently

TC-SAT-045 A Window Wider Than The List Needs Keeps Its Width And Gets Its Size Back
    [Documentation]    The window was made 800 wide before the list was opened: it stays 800 wide (it is
    ...    not made narrower to 640), grows taller, and when the list is shut it is 800 by 330 again,
    ...    not 380 by 330.
    [Tags]    p2
    Open About Up In The Corner
    Resize Window    ${ABOUT_WINDOW}    800    330
    Window Should Become Size    ${ABOUT_WINDOW}    800    330
    Click The Known Issues Header
    Wait Until Keyword Succeeds    12x    0.5s    About Should Be 800 Wide And Taller Than It Was
    About Should Show    Programs that run differently here than in jq
    Click The Known Issues Header
    Window Should Become Size    ${ABOUT_WINDOW}    800    330

TC-SAT-046 A Line Of The List Shows An Example While The Pointer Rests On It
    [Documentation]    On the line about modules, a hover gives a tip with the program of the issue's first
    ...    example and what jq and the app give for it; it goes when the pointer does.
    [Tags]    p2
    Open The Known Issues
    Switch To Window    ${ABOUT_WINDOW}
    @{region}=    About Region
    ${x}    ${y}=    Find Text In Region    @{region}    Modules:
    About Should Not Show    loads the module file
    Switch To Window    ${ABOUT_WINDOW}
    Move Mouse To    ${x}    ${y}
    About Should Show    loads the module file
    About Should Show    here: an error
    Switch To Window    ${ABOUT_WINDOW}
    Move Mouse To    200    30
    Wait Until Keyword Succeeds    8x    0.5s    About Should Not Show    loads the module file

TC-SAT-047 The Link Under The List Opens The Page With All The Issues
    [Documentation]    A click on "N smaller ones, and more examples, in the full list" hands the address
    ...    of docs/known-issues.md in the app's repository to the browser (a stand-in, which writes
    ...    it down), once.
    [Tags]    p1
    Open The Known Issues
    Switch To Window    ${ABOUT_WINDOW}
    Nothing Should Have Been Opened    settle=0.3
    @{region}=    About Region
    ${x}    ${y}=    Find Text In Region    @{region}    smaller ones
    Click At    ${x}    ${y}
    Opened Addresses Should Be    ${ISSUES_ADDRESS}

TC-SAT-048 A Window Too Small For The List Scrolls To Its End
    [Documentation]    The list opened, the window made 400 high: the link at the foot is out of sight, and
    ...    a turn of the wheel brings it into view.
    [Tags]    p2
    Open The Known Issues
    Resize Window    ${ABOUT_WINDOW}    ${LIST_WIDTH}    400
    Window Should Become Size    ${ABOUT_WINDOW}    ${LIST_WIDTH}    400
    About Should Not Show    smaller ones, and more examples
    Switch To Window    ${ABOUT_WINDOW}
    Scroll At    300    200    -30
    About Should Show    smaller ones, and more examples, in the full list

TC-SAT-049 The Version Is Copied With A Right Click
    [Documentation]    A right click on the first line of the window ("jsonquery gui v" and the version) offers Copy, and
    ...    the clipboard then has the line: what a person puts in a report of a problem. The menu is the
    ...    one of a text that is only shown (docs/24_text_menus.md): its first item is 16 px under the pointer.
    [Tags]    p3
    ${version}=    Cargo Version
    Open About
    Switch To Window    ${ABOUT_WINDOW}
    ${x}    ${y}=    Find Text In Region    @{ABOUT_TEXT}    jsonquery gui
    Right Click At    ${x}    ${y}
    Sleep    0.5s
    Set Clipboard    nothing was copied
    ${item}=    Evaluate    int(${y}) + 16
    ${inside}=    Evaluate    int(${x}) + 20
    Click At    ${inside}    ${item}
    Wait Until Keyword Succeeds    8x    0.3s    Clipboard Should Be    jsonquery gui v${version}

TC-SAT-050 A Link Is Copied With A Right Click
    [Documentation]    A right click on a link offers Copy link, and the clipboard then has its address: the
    ...    repository, the licence, the site and the policy of privacy (found by its second word: a row
    ...    that begins "Privacy:" would be found by the first). A right click is not a click: the
    ...    browser is not asked to open anything.
    [Tags]    p2
    Open About
    Switch To Window    ${ABOUT_WINDOW}
    &{links}=    Create Dictionary
    ...    GitHub=https://github.com/nujufas/jsonquery_gui
    ...    MIT=https://github.com/nujufas/jsonquery_gui/blob/master/LICENSE
    ...    policy=https://github.com/nujufas/jsonquery_gui/blob/master/PRIVACY.md
    ...    jsonquery.dev=https://jsonquery.dev
    FOR    ${text}    ${address}    IN    &{links}
        ${x}    ${y}=    Find Text In Region    @{ABOUT_TEXT}    ${text}
        Right Click At    ${x}    ${y}
        Sleep    0.5s
        Set Clipboard    nothing was copied
        ${item}=    Evaluate    int(${y}) + 16
        ${inside}=    Evaluate    int(${x}) + 20
        Click At    ${inside}    ${item}
        Wait Until Keyword Succeeds    8x    0.3s    Clipboard Should Be    ${address}
    END
    Nothing Should Have Been Opened    settle=0.3

TC-SAT-051 A Line Of The Known Issues Is Copied With A Right Click
    [Documentation]    The list opened, a right click on the line about modules offers Copy, and the clipboard
    ...    has the text of the issue, as the page of the issues has it in bold.
    [Tags]    p3
    ${page}=    Get File    ${APP_DIR}/docs/known-issues.md
    ${text}=    Evaluate    re.search(r'^\\*\\*(Modules:.+)\\*\\*$', $page, re.M).group(1)    modules=re
    Open The Known Issues
    Switch To Window    ${ABOUT_WINDOW}
    @{region}=    About Region
    ${x}    ${y}=    Find Text In Region    @{region}    Modules:
    Right Click At    ${x}    ${y}
    Sleep    0.5s
    Set Clipboard    nothing was copied
    ${item}=    Evaluate    int(${y}) + 16
    ${inside}=    Evaluate    int(${x}) + 20
    Click At    ${inside}    ${item}
    Wait Until Keyword Succeeds    8x    0.3s    Clipboard Should Be    ${text}

TC-SAT-030 All The Windows Can Be Open Together
    [Documentation]    The Tools window, the tutorial and About open at once, each
    ...    a window of its own, and the main window still takes a query and
    ...    shows its result.
    [Tags]    p1    window-only
    Click At    ${TOOLS_X}    ${TUTORIAL_Y}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Open Tutorial
    Open About
    Switch To Main Window
    ${windows}=    List Windows
    ${names}=    Evaluate    [w[1] for w in $windows]
    Should Contain    ${names}    JsonQuery
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
    [Tags]    p2    window-only
    Click At    ${TOOLS_X}    ${TUTORIAL_Y}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Open Tutorial
    Open About
    Close Window    ${TUTORIAL_WINDOW}
    Wait Until Window Closes    ${TUTORIAL_WINDOW}    timeout=8
    Window Should Read    ${ABOUT_WINDOW}    License    @{ABOUT_TEXT}
    ${tools}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${tools}    1
