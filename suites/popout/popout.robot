*** Settings ***
Documentation     Pop-out panes -- see docs/12_popout_panes.md. The Query,
...               Source and Results panes each have a button in their header
...               that opens the pane in a window of its own (a second native
...               window of the app); the same button there, or closing the
...               window, docks it back.
...
...               The windows are real X windows, so these tests need the
...               `Switch To Window` keywords: after one, every click and read
...               is relative to that window's top-left until `Switch To Main
...               Window`. The windows are undecorated, like the main one (the
...               fluxbox rule matches the app's class), so a window is closed
...               through the window manager (`Close Window`), not by a title
...               bar button. The titles are "jsonquery — Query", "jsonquery —
...               Source" and "jsonquery — Results" (an em dash, which
...               `xdotool` can't match literally -- AppLibrary handles that).
Resource          ../../resources/keywords.resource
Force Tags        popout
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${QUERY_WINDOW}      jsonquery — Query
${SOURCE_WINDOW}     jsonquery — Source
${RESULTS_WINDOW}    jsonquery — Results
# "team" holds a string long enough to read: string values are drawn in colour,
# which OCR reads, unlike the dim grey of the keys and counts.
${MEMBERS_JSON}      {"members":[{"name":"Ann","age":31},{"name":"Bob","age":25}],"team":"platypus"}
# The pop-out icons in the main window, at the default layout: a small icon in
# the far right corner of each pane's header (icon only, so fixed points). They
# don't depend on whether a document is loaded -- "Save..." sits left of it.
${QUERY_POP_X}       1184
${QUERY_POP_Y}       39
${SOURCE_POP_X}      583
${RESULTS_POP_X}     1184
${HEADER_POP_Y}      144
# The same buttons once the Query pane has left and everything has moved up.
${HEADER_POP_Y_UP}   42
# The toolbar's "bring everything back" button -- there only while a pane is out.
${DOCK_ALL_X}        1066
${DOCK_ALL_Y}        11
# The dock-back icons inside each window (window-relative), in the far right
# corner of the window's header: a window is its pane's size when docked, 760
# wide for Query and 600 for Source and Results, and the icon's centre is 16px
# in from the right edge.
${QUERY_DOCK_X}      744
${QUERY_DOCK_Y}      15
${PANE_DOCK_X}       584
${PANE_DOCK_Y}       18
# The Source window has a source-field row on top, so its header (and its dock
# icon, in the far right corner of it) is lower than the other windows' (y=41).
${SOURCE_DOCK_Y}     41
# Where the "Source" and "Results" headings are in the main window.
@{SOURCE_HEADER}     0      135    300    22
@{SOURCE_HEADER_UP}  0      33     300    22
# With Source gone, Results' heading is at the left edge.
@{RESULTS_HEADER_LEFT}    0    135    300    22
# A window's own header row.
@{WINDOW_HEADER}     0      4      300    28
${FIXTURES}          ${CURDIR}/../../resources/fixtures
# The source field's row along the top of the Source window (window-relative):
# "Source:" (x 8-50), the field (x 60-292 -- it gives room to the buttons and to
# what is loaded), "..." (x 310), Load (x 347), Clear (x 391), then what is loaded
# ("(pasted JSON)", its size), in a row 24px high. Measured on screenshots.
@{WINDOW_SOURCE_ROW}    0    0      600    24
@{WINDOW_ROW_INFO}   425    0      175    24
${WINDOW_FIELD_X}    200
${WINDOW_ROW_Y}      12
# With something loaded the row makes room for what it says about it, so the buttons
# are where they were just listed; with nothing loaded the field takes that room and
# "..." is at x 480, Load at x 517 and Clear at x 562.
${WINDOW_LOAD_X}     347
${WINDOW_CLEAR_X}    391
${WINDOW_LOAD_EMPTY_X}    517
# Under the row: a failed load says so in red ("Load error: ...").
@{WINDOW_ROW_ERROR}  0      24     600    26
# What the Source window's pane shows under the row and its header.
@{WINDOW_CONTENT}    0      52     600    160

*** Keywords ***
Load Members
    Load Fixture Via Paste    ${MEMBERS_JSON}

Wait For Main Layout
    [Documentation]    The Source heading is back at its default place -- the
    ...    layout a fresh launch has, with every pane docked.
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_HEADER}    Source

Pop Out Query
    Click At    ${QUERY_POP_X}    ${QUERY_POP_Y}
    Wait Until Window Exists    ${QUERY_WINDOW}

Pop Out Source
    [Arguments]    ${y}=${HEADER_POP_Y}
    Click At    ${SOURCE_POP_X}    ${y}
    Wait Until Window Exists    ${SOURCE_WINDOW}

Pop Out Results
    [Arguments]    ${y}=${HEADER_POP_Y}
    Click At    ${RESULTS_POP_X}    ${y}
    Wait Until Window Exists    ${RESULTS_WINDOW}

Window Should Read
    [Documentation]    OCR of a region of the named window (retried).
    [Arguments]    ${title}    ${text}    @{region}
    Switch To Window    ${title}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{region}    ${text}    flatten_tints=${True}
    Switch To Main Window

*** Test Cases ***
TC-POP-001 The Query Pane Opens In A Window Of Its Own
    [Documentation]    The pop-out button in the query header opens a window
    ...    titled "jsonquery - Query" holding the pane, and the panes it left
    ...    behind move up into its room: the Source heading is at the top of
    ...    the main window, no longer 100px down.
    [Tags]    p1
    Wait For Main Layout
    Pop Out Query
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_HEADER_UP}    Source
    Window Should Read    ${QUERY_WINDOW}    Query    @{WINDOW_HEADER}

TC-POP-002 A Query Run From Its Window Shows Its Results In The Main Window
    [Documentation]    The pane in its window is the same pane: type a query in
    ...    it and run it with Ctrl+Enter, and the results appear in the Results
    ...    pane of the main window, and the status bar there says so.
    [Tags]    p1
    Load Members
    Pop Out Query
    Switch To Window    ${QUERY_WINDOW}
    Click At    100    100
    Sleep    0.3s
    Type Text    .members[] | .name
    Press Keys    ctrl    enter
    Switch To Main Window
    # ("result(s)", as OCR reads it: the brackets come back as braces too.)
    Wait Until Region Matches    @{STATUS_BAR}    result.s.    timeout=8
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    608    60    592    80    Ann

TC-POP-003 The Button In The Window Docks The Pane Back
    [Documentation]    The pop-in button in the window's header closes the
    ...    window and the pane is back in the main window, which looks as it
    ...    did before.
    [Tags]    p1
    Pop Out Query
    Switch To Window    ${QUERY_WINDOW}
    Click At    ${QUERY_DOCK_X}    ${QUERY_DOCK_Y}
    Switch To Main Window
    Wait Until Window Closes    ${QUERY_WINDOW}
    Wait For Main Layout

TC-POP-004 Closing The Window Docks The Pane Back
    [Documentation]    There is nowhere else for the pane to go, so closing its
    ...    window (as its title bar's close button would) docks it.
    [Tags]    p1
    Pop Out Query
    Close Window    ${QUERY_WINDOW}
    Wait Until Window Closes    ${QUERY_WINDOW}
    Wait For Main Layout

TC-POP-005 Source In Its Own Window Gives Results The Whole Width
    [Documentation]    The Source window holds the document's tree. In the main
    ...    window the Results heading moves to the left edge, where Source's
    ...    was.
    [Tags]    p1
    Load Members
    Pop Out Source
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{RESULTS_HEADER_LEFT}    Results
    Window Should Read    ${SOURCE_WINDOW}    platypus    0    40    500    80

TC-POP-006 Results In Its Own Window Gives Source The Whole Width
    [Documentation]    The Results window holds the query's results; the main
    ...    window's Source pane takes the full width, its Save button at the
    ...    far right.
    [Tags]    p1
    Load Members
    Run Query    .members[] | .name
    Pop Out Results
    Window Should Read    ${RESULTS_WINDOW}    Ann    0    40    400    80
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    1100    135    76    22    Save

TC-POP-007 With Source And Results Both Out The Main Window Says So
    [Documentation]    Nothing is left under the query bar, so it says where the
    ...    panes went; the toolbar's button brings every window back.
    [Tags]    p1
    Load Members
    Pop Out Source
    Pop Out Results    ${HEADER_POP_Y}
    # Out of the way, so they don't cover the main window's note.
    Move Window    ${SOURCE_WINDOW}    1200    500
    Move Window    ${RESULTS_WINDOW}    1200    500
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    0    100    1200    300    own windows
    Click At    ${DOCK_ALL_X}    ${DOCK_ALL_Y}
    Wait Until Window Closes    ${SOURCE_WINDOW}
    Wait Until Window Closes    ${RESULTS_WINDOW}
    Wait For Main Layout

TC-POP-008 The Toolbar Button Docks Every Window At Once
    [Documentation]    The button is there only while something is out; one
    ...    click docks the Query, Source and Results windows together.
    [Tags]    p2
    Load Members
    Pop Out Query
    Pop Out Source    ${HEADER_POP_Y_UP}
    Click At    ${DOCK_ALL_X}    ${DOCK_ALL_Y}
    Wait Until Window Closes    ${QUERY_WINDOW}
    Wait Until Window Closes    ${SOURCE_WINDOW}
    Wait For Main Layout

TC-POP-009 Find Opens In The Window Of The Tree It Searches
    [Documentation]    Ctrl+F in the Source window opens the Search dialog in
    ...    that window, not in the main one.
    [Tags]    p1
    Load Members
    Pop Out Source
    Switch To Window    ${SOURCE_WINDOW}
    Click At    200    300
    Press Keys    ctrl    f
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    0    16    340    36    Search
    Switch To Main Window
    Region Should Not Contain Text    @{POPUP_DIALOG_AREA}    Search

TC-POP-010 Autocomplete Works In The Query Window
    [Documentation]    The suggestion list is drawn in the query's own window,
    ...    under the cursor.
    [Tags]    p2
    Load Members
    Toggle Autocomplete
    Pop Out Query
    Switch To Window    ${QUERY_WINDOW}
    Click At    100    100
    Sleep    0.3s
    Type Text    .members[].
    # The second row: the selected first one is white on blue, which OCR drops.
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    0    250    480    100    age
    Switch To Main Window

TC-POP-011 A Window Reopens Where It Was Left
    [Documentation]    Move the Source window and dock it; popped out again it
    ...    opens at the position and size it had.
    [Tags]    p2
    Load Members
    Pop Out Source
    Move Window    ${SOURCE_WINDOW}    300    200
    Sleep    1s
    ${before}=    Get Window Geometry    ${SOURCE_WINDOW}
    Switch To Window    ${SOURCE_WINDOW}
    Click At    ${PANE_DOCK_X}    ${SOURCE_DOCK_Y}
    Switch To Main Window
    Wait Until Window Closes    ${SOURCE_WINDOW}
    Wait For Main Layout
    Pop Out Source
    Sleep    1s
    ${after}=    Get Window Geometry    ${SOURCE_WINDOW}
    Should Be Equal    ${after}    ${before}

TC-POP-012 Closing The Main Window Closes The Pop-Out Windows Too
    [Documentation]    The app is one process: quitting from the main window
    ...    takes the others with it.
    [Tags]    p2
    Pop Out Query
    Close Window    jsonquery
    Wait Until Window Closes    ${QUERY_WINDOW}    timeout=8

TC-POP-013 A Click In The Main Window Still Decides What Ctrl+F Searches
    [Documentation]    With Source in its own window, click Results in the main
    ...    window and press Ctrl+F there: the dialog is for Results, in the
    ...    main window. (A popped window's own pass must not claim "the pane
    ...    last clicked" every frame -- that overwrote the click the moment
    ...    the main window had made it.)
    [Tags]    p1
    Load Members
    Pop Out Source
    Click At    900    400
    Sleep    0.3s
    Press Keys    ctrl    f
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{POPUP_DIALOG_AREA}    Results

TC-POP-014 A Maximized Pane Window Still Responds And Docks Back
    [Documentation]    Maximize the Query window -- it now covers the whole
    ...    screen, the main window under it -- and use it: click in the box,
    ...    type a query, run it, then dock the pane with the icon in the window's
    ...    corner. The window is redrawn by itself, not as a part of the main
    ...    window's frame (on GNOME/Wayland a window that is completely covered
    ...    gets no redraw callbacks, so a pane window maximized over the main
    ...    window used to stop responding: that cannot be seen under X, but this
    ...    is the flow it broke -- see "Not covered" in 12_popout_panes.md).
    [Tags]    p1
    Load Members
    Pop Out Query
    Maximize Window    ${QUERY_WINDOW}
    Switch To Window    ${QUERY_WINDOW}
    ${width}    ${height}=    Get Window Size
    Should Be True    ${width} > 1200
    Click At    100    100
    Sleep    0.3s
    Type Text    .members[] | .name
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    0    30    600    60    name    flatten_tints=${True}
    Press Keys    ctrl    enter
    Sleep    1s
    ${dock_x}=    Evaluate    ${width} - 16
    Click At    ${dock_x}    ${QUERY_DOCK_Y}
    Switch To Main Window
    Wait Until Window Closes    ${QUERY_WINDOW}
    Wait For Main Layout
    # ("result(s)", as OCR reads it: the brackets come back as braces too.)
    Wait Until Region Matches    @{STATUS_BAR}    result.s.    timeout=8
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    608    162    592    80    Ann

TC-POP-015 Closing A Maximized Pane Window Docks Its Pane
    [Documentation]    A maximized window's close button docks the pane like any
    ...    other window's: the window gives up the screen and the main window is
    ...    as it was.
    [Tags]    p1
    Pop Out Query
    Maximize Window    ${QUERY_WINDOW}
    Close Window    ${QUERY_WINDOW}
    Wait Until Window Closes    ${QUERY_WINDOW}    timeout=8
    Wait For Main Layout

TC-POP-016 The Source Window Has A Source Field Of Its Own
    [Documentation]    The toolbar's source field is in the main window, which
    ...    the Source pane has left, so its window has a field of its own along
    ...    the top ("Source:", the field, "...", Load, Clear). A path typed into
    ...    it and submitted with Enter opens that file in the window's own pane,
    ...    and the toolbar's field in the main window shows the same text.
    [Tags]    p1
    Pop Out Source
    Switch To Window    ${SOURCE_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{WINDOW_SOURCE_ROW}    Source:
    Click At    ${WINDOW_FIELD_X}    ${WINDOW_ROW_Y}
    Sleep    0.2s
    Type Text    ${FIXTURES}/people.json
    Sleep    0.3s
    Press Key    enter
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{WINDOW_CONTENT}    3 items
    Switch To Main Window
    Region Should Contain Text    @{SOURCE_FIELD}    people.json

TC-POP-017 The Load Button In The Source Window Loads
    [Documentation]    A path typed into the Source window's field is loaded by its
    ...    Load button as well as by Enter.
    [Tags]    p1
    Pop Out Source
    Switch To Window    ${SOURCE_WINDOW}
    Click At    ${WINDOW_FIELD_X}    ${WINDOW_ROW_Y}
    Sleep    0.2s
    Type Text    ${FIXTURES}/people.json
    Sleep    0.4s
    Click At    ${WINDOW_LOAD_EMPTY_X}    ${WINDOW_ROW_Y}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{WINDOW_CONTENT}    3 items

TC-POP-018 Clear In The Source Window Unloads The Document
    [Documentation]    Clear in the window's row empties the field and unloads the
    ...    document: the pane has nothing again, and the main window's toolbar
    ...    field is empty too (one text, shown in both).
    [Tags]    p1
    Pop Out Source
    Switch To Window    ${SOURCE_WINDOW}
    Click At    ${WINDOW_FIELD_X}    ${WINDOW_ROW_Y}
    Sleep    0.2s
    Type Text    ${FIXTURES}/people.json
    Sleep    0.3s
    Press Key    enter
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{WINDOW_CONTENT}    3 items
    Click At    ${WINDOW_CLEAR_X}    ${WINDOW_ROW_Y}
    Sleep    0.8s
    Region Should Not Contain Text    @{WINDOW_SOURCE_ROW}    people.json
    Region Should Not Contain Text    @{WINDOW_CONTENT}    3 items
    Switch To Main Window
    Region Should Not Contain Text    @{SOURCE_FIELD}    people.json

TC-POP-019 The Two Source Fields Are One Text
    [Documentation]    What is typed in the main window's toolbar field shows in the
    ...    Source window's field, as it is the same text.
    [Tags]    p2
    Pop Out Source
    Click At    ${SOURCE_FIELD_X}    ${TOOLBAR_Y}
    Sleep    0.2s
    Type Text    some-file-name
    Sleep    0.6s
    Switch To Window    ${SOURCE_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{WINDOW_SOURCE_ROW}    some-file-name

TC-POP-020 A Failed Load Is Said In The Source Window
    [Documentation]    The window has no status bar, so a load that fails says so
    ...    in red under its row ("Load error: ...").
    [Tags]    p1
    Pop Out Source
    Switch To Window    ${SOURCE_WINDOW}
    Click At    ${WINDOW_FIELD_X}    ${WINDOW_ROW_Y}
    Sleep    0.2s
    Type Text    /no/such/dir/missing.json
    Sleep    0.3s
    Press Key    enter
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{WINDOW_ROW_ERROR}    Load error

TC-POP-021 Only The Source Window Has A Source Row
    [Documentation]    The Results window has no "Source:" field -- it is the
    ...    Source pane's window that has one -- and starts with its own header.
    [Tags]    p2
    Pop Out Results
    Window Should Read    ${RESULTS_WINDOW}    Results    @{WINDOW_HEADER}
    Switch To Window    ${RESULTS_WINDOW}
    Region Should Not Contain Text    @{WINDOW_SOURCE_ROW}    Source:
    Switch To Main Window

TC-POP-022 The Source Window's Row Says What Is Loaded
    [Documentation]    With a pasted document loaded, the row shows "(pasted JSON)"
    ...    and its size, as the toolbar does.
    [Tags]    p2
    Load Members
    Pop Out Source
    Switch To Window    ${SOURCE_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{WINDOW_ROW_INFO}    pasted

TC-POP-023 The Toolbar Keeps Its Source Field While Source Is Out
    [Documentation]    The main window's toolbar still has its "Source:" field (with
    ...    its hint) while the pane is in a window: the field is the same text,
    ...    in two places. (Its Load and Clear buttons are dim with nothing typed,
    ...    which OCR cannot read.)
    [Tags]    p2
    Pop Out Source
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{TOOLBAR_ROW}    Source:
    Region Should Contain Text    @{TOOLBAR_ROW}    local path

TC-POP-024 A File Loaded From The Toolbar Shows In The Source Window
    [Documentation]    With the pane in its window, a path entered in the main
    ...    window's toolbar field opens in that window.
    [Tags]    p1
    Pop Out Source
    Load Via Url    ${FIXTURES}/people.json
    Switch To Window    ${SOURCE_WINDOW}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{WINDOW_CONTENT}    3 items

TC-POP-025 Docking The Source Pane Takes The Row With It
    [Documentation]    Back in the main window the pane has its header under the
    ...    panes' line as before, the window is gone, and the toolbar is the only
    ...    source field.
    [Tags]    p2
    Load Members
    Pop Out Source
    Switch To Window    ${SOURCE_WINDOW}
    Click At    ${PANE_DOCK_X}    ${SOURCE_DOCK_Y}
    Switch To Main Window
    Wait Until Window Closes    ${SOURCE_WINDOW}
    Wait For Main Layout
    Region Should Contain Text    @{TOOLBAR_ROW}    Source:
