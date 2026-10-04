*** Settings ***
Documentation     Tools window, its shell and the Merge page -- see
...               docs/13_tools_window.md. The dim 🛠 button beside the 📖
...               tutorial button opens the Tools window (a second native window,
...               titled "jsonquery — Tools") with a tab for each tool: Merge
...               JSON, Format JSON, Diff JSON, Patch JSON and Validate schema.
...               The pages other than Merge are in tools_format.robot,
...               tools_diff.robot, tools_patch.robot and tools_validate.robot;
...               every layout constant is in resources/tools.resource.
...
...               What these tests cannot reach: adding files. Dropping files
...               needs X drag-and-drop, which `xdotool` can't do, and "Add
...               files…" and "Open file…" open a native dialog, which is blocked
...               here (see 00_test_strategy.md). The merge itself -- the list,
...               the presets run against files, opening and saving the result,
...               the multi-file drop on the main window -- is covered headlessly
...               in `cargo test` (crates/query/src/merge.rs, crates/app/src/tools
...               and the window tests in crates/app/src/app/layout_tests.rs).
Resource          ../../resources/tools.resource
Force Tags        tools
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The Merge page: the dropdown's current preset (its label), and the text of the
# filter box under the command row.
@{PRESET_LABEL}      120    24     225    20
@{MERGE_STATUS_BAR}    0    560    900    18
# The strip between the Result pane's header and its content: nothing is drawn
# there (no line under a header).
@{UNDER_RESULT_HEADER}    520    73     270    3
# The Merge button of the Merge page, whose label is dim until there is a file.
@{MERGE_BUTTON}      8      24     44     20

*** Test Cases ***
TC-TWIN-001 The Tools Button Opens A Window Of Its Own
    [Documentation]    One click on 🛠 opens the window with a tab for each tool
    ...    and the Merge tool's page under them: its "Merge as" choice, the
    ...    files and the Result.
    [Tags]    p1
    Open Tools Window
    Tools Window Should Read    Format JSON    @{TAB_ROW}
    Tools Window Should Read    Merge as    @{COMMAND_ROW}
    Tools Window Should Read    Files    @{MERGE_LEFT_HEADER}
    Tools Window Should Read    Add files    350    110    100    24
    Tools Window Should Read    Result    @{MERGE_RESULT_HEADER}

TC-TWIN-002 The Main Window Keeps Working With The Tools Window Open
    [Documentation]    The Tools window is separate from the main window: with
    ...    it open, a document still loads in the main window.
    [Tags]    p1
    Open Tools Window
    Load Fixture Via Paste    {"members":[{"name":"Ann"}],"team":"platypus"}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    platypus    flatten_tints=${True}

TC-TWIN-003 Closing The Window And Pressing The Button Again Reopens It
    [Documentation]    Closing the window (through the window manager -- it is
    ...    undecorated, like the others) and pressing 🛠 again gives a fresh
    ...    one.
    [Tags]    p1
    Open Tools Window
    Close Window    ${TOOLS_WINDOW}
    Wait Until Window Closes    ${TOOLS_WINDOW}
    Open Tools Window
    Tools Window Should Read    Files    @{MERGE_LEFT_HEADER}

TC-TWIN-004 Pressing The Button With The Window Open Brings It Forward
    [Documentation]    A second press doesn't open a second window: the one
    ...    window is still there, and still shows its content.
    [Tags]    p2
    Open Tools Window
    Click At    ${TOOLS_X}    ${TOOLS_Y}
    Sleep    0.5s
    ${windows}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${windows}    1
    Tools Window Should Read    Merge as    @{COMMAND_ROW}

TC-TWIN-005 Every Tool Is In The List And Opens Its Page
    [Documentation]    The tabs are Merge, Format, Diff, Patch and Validate
    ...    schema; picking one shows its page, whose first box has a title of
    ...    its own.
    [Tags]    p1
    Open Tool    format
    Page Should Show    Input    @{LEFT_HEADER}
    Pick Tool    diff
    Page Should Show    Left    @{LEFT_HEADER}
    Pick Tool    patch
    Page Should Show    Document    @{LEFT_HEADER}
    Pick Tool    validate
    Page Should Show    Document    @{LEFT_HEADER}
    Pick Tool    merge
    Page Should Show    Files    @{MERGE_LEFT_HEADER}

TC-TWIN-012 A Maximized Tools Window Still Responds And Closes
    [Documentation]    Maximize the Tools window -- it now covers the whole
    ...    screen, the main window under it -- and use it: paste JSON, run
    ...    Format and read the answer. Then close it through the window
    ...    manager: the window goes and the main window works as before. The
    ...    window is redrawn by itself, not as a part of the main window's
    ...    frame (on GNOME/Wayland a window that is completely covered gets no
    ...    redraw callbacks, so a Tools window maximized over the main window
    ...    used to stop responding: that cannot be seen under X, but this is the
    ...    flow it broke -- see "Not reachable" in 13_tools_window.md).
    [Tags]    p1
    Open Tool    format
    Maximize Window    ${TOOLS_WINDOW}
    Switch To Window    ${TOOLS_WINDOW}
    ${width}    ${height}=    Get Window Size
    Should Be True    ${width} > 1200
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"b":1,"a":[1,2,{"c":null}],"d":{}}
    Press Main Button
    # The answer is drawn where the result area is: the left pane keeps its width
    # when the window grows, so the right pane's top left stays where it was.
    Result Should Read    1,\n2
    Close Window    ${TOOLS_WINDOW}
    Wait Until Window Closes    ${TOOLS_WINDOW}    timeout=8
    Switch To Main Window
    Load Fixture Via Paste    {"members":[{"name":"Ann"}],"team":"platypus"}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    platypus    flatten_tints=${True}

TC-TWIN-013 Each Page Keeps What Was Typed In It
    [Documentation]    Picking another tab and coming back leaves the page as it
    ...    was: the text typed into the Format box is still there (the pages
    ...    are all alive at once, only one is shown).
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"keep":"platypus"}
    Pick Tool    diff
    Page Should Show    Left    @{LEFT_HEADER}
    Pick Tool    format
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{INPUT_BOX}    platypus

TC-TWIN-014 The Selected Tab Is Marked
    [Documentation]    The tab of the page showing is drawn selected (white on
    ...    the selection blue), the others are not: Merge when the window
    ...    opens, then whichever is picked.
    [Tags]    p2
    Open Tools Window
    Switch To Window    ${TOOLS_WINDOW}
    Tab Should Be Selected    merge
    Tab Should Not Be Selected    format
    Pick Tool    format
    Tab Should Be Selected    format
    Tab Should Not Be Selected    merge
    Pick Tool    validate
    Tab Should Be Selected    validate
    Tab Should Not Be Selected    format

TC-TWIN-015 The Window Opens At Its Default Size
    [Documentation]    900 by 580 -- the size every region of these suites is
    ...    measured at, and room for the two panes side by side.
    [Tags]    p2
    Open Tools Window
    ${x}    ${y}    ${width}    ${height}=    Get Window Geometry    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${width}    900
    Should Be Equal As Integers    ${height}    580

TC-TWIN-016 The Tools Window Follows The Main Window's Theme
    [Documentation]    One theme for all the windows: with the Tools window open,
    ...    the main window's ☀ button turns it light too (and its pane
    ...    backgrounds from dark to light).
    [Tags]    p2
    Open Tool    format
    ${dark}=    Get Pixel Color    600    300
    Should Be True    max(${dark}) < 80    msg=Expected the dark theme to start with: ${dark}
    Switch To Main Window
    Click At    ${THEME_TOGGLE_X}    ${THEME_TOGGLE_Y}
    Sleep    0.8s
    Switch To Window    ${TOOLS_WINDOW}
    ${light}=    Get Pixel Color    600    300
    Should Be True    min(${light}) > 180    msg=Expected the light theme in the Tools window: ${light}

TC-TWIN-017 No Line Under A Pane's Header
    [Documentation]    The headers of the panes have no line under them, as in
    ...    the main window (the one divider is the line above the panes): the
    ...    strip between the Result header and its content is bare background.
    [Tags]    p2
    Open Tool    format
    Region Should Be Plain    @{UNDER_RESULT_HEADER}

TC-MRG-001 Merge Has Nothing To Run Until There Are Files
    [Documentation]    With no file listed the Merge button is dim and pressing
    ...    it (or Ctrl+Enter) does nothing: the status bar stays empty and the
    ...    Result pane keeps its hint.
    [Tags]    p1
    Open Tool    merge
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    @{MERGE_BUTTON}    threshold=150
    Press Main Button
    Press Keys    ctrl    enter
    Sleep    0.5s
    Region Should Be Plain    @{MERGE_STATUS_BAR}

TC-MRG-002 The Presets Are Listed
    [Documentation]    The "Merge as" dropdown lists the four ready-made
    ...    filters: Append arrays, Append sorted and de-duplicated,
    ...    Deep-merge objects and Bundle by file name.
    [Tags]    p1
    Open Tool    merge
    Click At    ${MERGE_AS_X}    ${COMMAND_Y}
    Sleep    0.5s
    Region Should Contain Text    120    46    225    90    Append arrays
    Region Should Contain Text    120    46    225    90    de-duplicated
    Region Should Contain Text    120    46    225    90    Deep-merge
    Region Should Contain Text    120    46    225    90    Bundle by file name

TC-MRG-003 Picking A Preset Puts Its Filter In The Box
    [Documentation]    The filter box starts as `add` (Append arrays); picking
    ...    Deep-merge objects writes the `reduce` filter into it and names the
    ...    preset in the dropdown, and Bundle by file name writes the one that
    ...    uses `$files`.
    [Tags]    p1
    Open Tool    merge
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{FILTER_BOX}    add
    Click At    ${MERGE_AS_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${MERGE_ITEM_X}    ${MERGE_ITEM_Y}[deep]
    Sleep    0.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{FILTER_BOX}    reduce
    Region Should Contain Text    @{PRESET_LABEL}    Deep-merge
    Click At    ${MERGE_AS_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${MERGE_ITEM_X}    ${MERGE_ITEM_Y}[bundle]
    Sleep    0.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{FILTER_BOX}    files
    Region Should Contain Text    @{PRESET_LABEL}    Bundle

TC-MRG-004 A Filter Of One's Own Is Called Custom
    [Documentation]    The filter box is always editable; once its text matches
    ...    no preset the dropdown says "Custom jq filter".
    [Tags]    p1
    Open Tool    merge
    Click At    ${FILTER_BOX_X}    ${FILTER_BOX_Y}
    Sleep    0.2s
    Press Keys    ctrl    a
    Type Text    add | length
    Sleep    0.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{PRESET_LABEL}    Custom

TC-MRG-005 Picking A Preset Replaces A Custom Filter
    [Documentation]    After a custom filter has been typed, picking a preset
    ...    puts the preset's filter back in the box and its name in the
    ...    dropdown.
    [Tags]    p2
    Open Tool    merge
    Click At    ${FILTER_BOX_X}    ${FILTER_BOX_Y}
    Sleep    0.2s
    Press Keys    ctrl    a
    Type Text    add | length
    Sleep    0.5s
    Click At    ${MERGE_AS_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${MERGE_ITEM_X}    ${MERGE_ITEM_Y}[unique]
    Sleep    0.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{FILTER_BOX}    unique
    Region Should Not Contain Text    @{FILTER_BOX}    length
    Region Should Contain Text    @{PRESET_LABEL}    sorted

TC-TWIN-018 The Line Between The Panes Can Be Dragged
    [Documentation]    The two panes have a line between them (x=449) that moves: drag
    ...    it to the right and the Result pane's title, which began at x=459, begins
    ...    well to the right of that.
    [Tags]    p2
    Open Tool    format
    ${before}    ${y}=    Find Text In Region    452    54    120    24    Result
    Should Be True    ${before} < 520
    Drag Mouse    449    300    599    300
    Sleep    0.8s
    ${after}    ${y}=    Find Text In Region    452    54    260    24    Result
    Should Be True    ${after} > 580    msg=The Result title is still at x=${after}
