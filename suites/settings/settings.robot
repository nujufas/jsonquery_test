*** Settings ***
Documentation     The Settings window (the ⚙ at the right end of the status bar) and
...               what the app remembers of how it was left -- see docs/21_settings.md.
...               A window of its own, titled "jsonquery — Settings", with the limits on
...               the size of files, each with its default; and one small file,
...               settings.json in the folder .jsonquery of the home (here a
...               folder of its own for each launch, JSONQUERY_HOME: see
...               `Launch Jsonquery App`), which the cases read to see what was kept.
...
...               The small grey explanations under each limit are too small for OCR;
...               the cases read the names, the sizes and the complaints, and the
...               file.
Resource          ../../resources/keywords.resource
Library           OperatingSystem
Force Tags        settings
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${SETTINGS_WINDOW}     jsonquery — Settings
${MAIN_WINDOW}         jsonquery
# The ⚙ in the status bar, just left of the ⓘ (icon only: a fixed point).
${GEAR_X}              1152
${GEAR_Y}              789
# The Settings window (660x680 when it opens): the heading, then a row for each limit
# -- its name, the box, Reset and the default -- with its explanation under it.
@{HEADING}             0      8      660    32
@{FOOTER}              0      650    660    28
# The footer when it has a complaint of its own over the line that names the file.
@{NOTES}               0      610    660    70
# The strip of the pane headers where Results has its title once the edge between the
# panes has been dragged to x=380 -- and where only the Source header is otherwise.
@{LEFT_OF_RESULTS}     360    135    160    20
${BOX_X}               290
${RESET_X}             360
${RESTORE_X}           600
${HEADING_Y}           22
# The rows (y), as they are with no complaint under any of them.
${KEEP_Y}              112
${DOWNLOAD_Y}          163
${TOOLS_Y}             232
${COPY_Y}              311
${PARSE_Y}             413
${VALUE_Y}             464
${RESULT_Y}            505
${GATHER_Y}            546
${KEYS_Y}              587

*** Keywords ***
Open Settings
    Switch To Main Window
    Click At    ${GEAR_X}    ${GEAR_Y}
    Wait Until Window Exists    ${SETTINGS_WINDOW}    timeout=8
    Switch To Window    ${SETTINGS_WINDOW}

Row
    [Documentation]    The region of the row of a limit whose boxes are at y.
    [Arguments]    ${y}
    ${top}=    Evaluate    int(${y}) - 11
    RETURN    ${top}

Row Should Read
    [Arguments]    ${y}    ${text}
    ${top}=    Row    ${y}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    0    ${top}    660    24    ${text}

Type In Box
    [Documentation]    Types over what is in the box of the row at y, and presses Enter.
    [Arguments]    ${y}    ${text}
    Click At    ${BOX_X}    ${y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Type Text    ${text}
    Sleep    0.2s
    Press Key    enter
    Sleep    0.5s

Setting Should Be
    [Documentation]    The settings file says `expected` at the path (retried: it is
    ...    written a moment after what was done; "None" is "nothing there").
    [Arguments]    ${path}    ${expected}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Settings Value Should Be    ${path}    ${expected}

Close Settings
    Close Window    ${SETTINGS_WINDOW}
    Wait Until Window Closes    ${SETTINGS_WINDOW}    timeout=8
    Switch To Main Window

Start Again As The Same User
    [Documentation]    The app ends as a person ends it (what it has to write it writes
    ...    as it does) and starts again with the settings it kept.
    ${ended}=    Quit Jsonquery App
    Should Be True    ${ended}    The app did not end when its window was closed
    Close Jsonquery App    keep_home=${TRUE}
    Launch Jsonquery App    keep_home=${TRUE}

Source Share Should Be Below
    [Arguments]    ${limit}
    ${share}=    Settings Value    panes.source_share
    Should Not Be Equal    ${share}    ${None}    No share was written
    Should Be True    ${share} < ${limit}    Source has ${share} of the width

Window Should Be Wider Than
    [Arguments]    ${width}
    ${now}    ${height}=    Get Window Size
    Should Be True    ${now} > ${width}    The window is ${now} wide

Make Small File
    [Documentation]    A file of 3 KB of JSON; its path.
    ${dir}=    Make Temp Directory
    ${text}=    Evaluate    '[1, 2, 3]' + ' ' * 3000
    Create File    ${dir}/small.json    ${text}
    RETURN    ${dir}/small.json

*** Test Cases ***
TC-SET-001 The Gear Opens The Settings Window
    [Documentation]    One click on ⚙ in the status bar opens a window titled
    ...    "jsonquery — Settings" with the limits on file sizes; the file they are
    ...    kept in is named at its foot.
    [Tags]    p1
    Open Settings
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{HEADING}    File size limits
    Row Should Read    ${KEEP_Y}    Keep a file on disk from
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{FOOTER}    Kept in
    # The dot of the name is often lost to OCR in a path this small: each part on its own.
    Region Should Contain Text    @{FOOTER}    settings
    Region Should Contain Text    @{FOOTER}    json

TC-SET-002 Every Limit Is There With Its Default
    [Documentation]    The nine limits, each with the size it has (the one the app has
    ...    always used) and, beside it, the default.
    [Tags]    p1
    Open Settings
    Row Should Read    ${KEEP_Y}    256 MB
    Row Should Read    ${DOWNLOAD_Y}    4 GB
    Row Should Read    ${TOOLS_Y}    128 MB
    Row Should Read    ${COPY_Y}    64 MB
    Row Should Read    ${PARSE_Y}    List or object parsed whole
    Row Should Read    ${VALUE_Y}    String or other value
    Row Should Read    ${RESULT_Y}    16 MB
    Row Should Read    ${GATHER_Y}    Gathered into a list
    Row Should Read    ${KEYS_Y}    Keys of a sort or group
    Row Should Read    ${KEEP_Y}    default 256 MB

TC-SET-003 Nothing Is Written Until Something Is Changed
    [Documentation]    Starting the app, and looking at the settings, writes no file.
    [Tags]    p1
    Sleep    1.5s
    ${exists}=    Settings File Exists
    Should Not Be True    ${exists}    The settings file was written by the app starting
    Open Settings
    Sleep    1.5s
    ${exists}=    Settings File Exists
    Should Not Be True    ${exists}    The settings file was written by looking at the settings

TC-SET-004 A Limit Typed And Confirmed Is Kept In The File
    [Documentation]    512 MB over the first limit and Enter: the box shows it, and the
    ...    file has it, and only it.
    [Tags]    p1
    Open Settings
    Type In Box    ${KEEP_Y}    512 MB
    Row Should Read    ${KEEP_Y}    512 MB
    Setting Should Be    limits.keep_on_disk_from    512 MB
    Setting Should Be    limits.tools    None
    Setting Should Be    theme    None

TC-SET-005 What Is Not A Size Is Said So And Not Kept
    [Documentation]    "banana" over the Tools limit: a complaint under it, in words,
    ...    the limit stays what it was, and nothing is written.
    [Tags]    p1
    Open Settings
    Type In Box    ${TOOLS_Y}    banana
    ${top}=    Row    ${TOOLS_Y}
    ${below}=    Evaluate    ${top} + 22
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    0    ${below}    660    24    Not a size
    Region Should Contain Text    0    ${below}    660    24    stays 128 MB
    ${exists}=    Settings File Exists
    Should Not Be True    ${exists}    Something was written for what is no size

TC-SET-006 Reset Puts One Limit Back
    [Documentation]    After a change, Reset in its row puts the default back in the box
    ...    and takes the limit out of the file.
    [Tags]    p1
    Open Settings
    Type In Box    ${KEEP_Y}    512 MB
    Setting Should Be    limits.keep_on_disk_from    512 MB
    Click At    ${RESET_X}    ${KEEP_Y}
    Row Should Read    ${KEEP_Y}    256 MB
    Setting Should Be    limits.keep_on_disk_from    None

TC-SET-007 Restore Defaults Puts Every Limit Back
    [Documentation]    Two limits changed, and one press on Restore defaults puts both
    ...    back.
    [Tags]    p1
    Open Settings
    Type In Box    ${KEEP_Y}    512 MB
    Type In Box    ${COPY_Y}    8 MB
    Setting Should Be    limits.copy    8 MB
    Click At    ${RESTORE_X}    ${HEADING_Y}
    Row Should Read    ${KEEP_Y}    256 MB
    Row Should Read    ${COPY_Y}    64 MB
    Setting Should Be    limits.keep_on_disk_from    None
    Setting Should Be    limits.copy    None

TC-SET-008 A Limit Is Kept For The Next Start
    [Documentation]    The next start of the app, as the same user, has the limit that
    ...    was set.
    [Tags]    p1
    Open Settings
    Type In Box    ${KEEP_Y}    512 MB
    Setting Should Be    limits.keep_on_disk_from    512 MB
    Start Again As The Same User
    Open Settings
    Row Should Read    ${KEEP_Y}    512 MB
    Row Should Read    ${KEEP_Y}    default 256 MB

TC-SET-009 A Limit That Was Typed But Not Confirmed Is Kept When The Window Is Closed
    [Documentation]    Typed, and the window closed without Enter or a click away:
    ...    what was typed is taken.
    [Tags]    p2
    Open Settings
    Click At    ${BOX_X}    ${COPY_Y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Type Text    8 MB
    Sleep    0.3s
    Close Settings
    Setting Should Be    limits.copy    8 MB

TC-SET-010 The Limit On Keeping A File On Disk Decides How A File Opens
    [Documentation]    A file of 3 KB is parsed, as always; with the limit at 1 KB it is
    ...    kept on disk and indexed, and the status bar says so.
    [Tags]    p1
    ${file}=    Make Small File
    Load Via Url    ${file}
    Wait Until Region Contains Text    @{STATUS_BAR}    Parsed in    timeout=10
    Close Jsonquery App
    Launch Jsonquery App    settings={"limits": {"keep_on_disk_from": "1 KB"}}
    Load Via Url    ${file}
    Wait Until Region Contains Text    @{STATUS_BAR}    Indexed in    timeout=10

TC-SET-011 A Settings File With Something Wrong In It Does Not Stop The App
    [Documentation]    A limit that is no size and a theme that is none: the app starts, in
    ...    the defaults for what is wrong and with what is fine, and the Settings window
    ...    says what it left out.
    [Tags]    p1
    Close Jsonquery App
    Launch Jsonquery App    settings={"limits": {"download": "banana", "copy": "8 MB"}, "theme": "purple"}
    Open Settings
    Row Should Read    ${COPY_Y}    8 MB
    Row Should Read    ${DOWNLOAD_Y}    4 GB
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{NOTES}    download: not a size

TC-SET-012 A File That Is Not JSON Does Not Stop The App Either
    [Documentation]    The app starts with the defaults, says so in the Settings window,
    ...    and leaves the file alone until something is changed.
    [Tags]    p2
    Close Jsonquery App
    Launch Jsonquery App    settings=this is { not JSON
    Open Settings
    Row Should Read    ${KEEP_Y}    256 MB
    # The warning is in amber (small text of a colour OCR does not read well, with a
    # long path in it): its colour over the line that names the file is what is read.
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Color    @{NOTES}    255    143    0    tolerance=40
    ...    msg=No warning in the footer of the Settings window
    # And the file is as it was left: reading it does not touch it.
    ${home}=    App Home
    ${text}=    Get File    ${home}/settings.json
    Should Be Equal    ${text}    this is { not JSON

TC-SET-020 The Theme Is Kept For The Next Start
    [Documentation]    The theme chosen with the toolbar button is what the app starts in
    ...    the next time; dark is what it starts in the first time and is not written.
    [Tags]    p1
    ${dark}=    Get Pixel Color    300    110
    Click At    ${THEME_TOGGLE_X}    ${THEME_TOGGLE_Y}
    Setting Should Be    theme    light
    Start Again As The Same User
    ${started}=    Get Pixel Color    300    110
    Colors Should Not Match    ${dark}    ${started}
    ...    msg=The app did not start in the light theme it was left in
    # And back to dark: nothing left to keep.
    Click At    ${THEME_TOGGLE_X}    ${THEME_TOGGLE_Y}
    Setting Should Be    theme    None
    ${again}=    Get Pixel Color    300    110
    Colors Should Match    ${dark}    ${again}

TC-SET-021 The Theme Is Kept Though The App Ends At Once
    [Documentation]    Chosen and the window closed in the same moment: what the app
    ...    writes as it ends is the theme.
    [Tags]    p2
    Click At    ${THEME_TOGGLE_X}    ${THEME_TOGGLE_Y}
    ${ended}=    Quit Jsonquery App
    Should Be True    ${ended}
    Settings Value Should Be    theme    light

TC-SET-022 Autocomplete On Is Kept For The Next Start
    [Documentation]    The 💡 button is off the first time; on, it is on the next time.
    [Tags]    p2
    Toggle Autocomplete
    Setting Should Be    autocomplete    true
    ${on}=    Get Pixel Color    ${AUTOCOMPLETE_ICON_PROBE_X}    ${AUTOCOMPLETE_ICON_PROBE_Y}
    Start Again As The Same User
    ${started}=    Get Pixel Color    ${AUTOCOMPLETE_ICON_PROBE_X}    ${AUTOCOMPLETE_ICON_PROBE_Y}
    Colors Should Match    ${on}    ${started}
    ...    msg=The 💡 button was not on after the app started again

TC-SET-023 The Size Of The Window Is Kept For The Next Start
    [Documentation]    The window made 1000 x 700 is 1000 x 700 the next time; the size it
    ...    has when the app starts for the first time (1200 x 800) is not written.
    [Tags]    p1
    ${width}    ${height}=    Get Window Size
    Should Be Equal As Integers    ${width}    1200
    # Long enough for a write of that usual size to have happened (see TC-SET-003).
    Sleep    1.5s
    Setting Should Be    window    None
    Resize Window    ${MAIN_WINDOW}    1000    700
    Setting Should Be    window.width    1000
    Setting Should Be    window.height    700
    Start Again As The Same User
    ${width}    ${height}=    Get Window Size
    Should Be Equal As Integers    ${width}    1000
    Should Be Equal As Integers    ${height}    700

TC-SET-024 A Maximized Window Is Maximized The Next Time
    [Documentation]    Maximized, the window is kept as maximized, with the size it
    ...    had before; the next start is maximized.
    [Tags]    p2
    Resize Window    ${MAIN_WINDOW}    1000    700
    Setting Should Be    window.width    1000
    Maximize Window    ${MAIN_WINDOW}
    Setting Should Be    window.maximized    true
    Setting Should Be    window.width    1000
    ${maximized_width}    ${maximized_height}=    Get Window Size
    Start Again As The Same User
    Wait Until Keyword Succeeds    10x    0.5s
    ...    Window Should Be Wider Than    1000

TC-SET-025 The Size Of The Panes Is Kept
    [Documentation]    The edge between Source and Results dragged to the left is
    ...    kept as how much of the width Source has.
    [Tags]    p2
    # Panes in the middle, as they start, are not written (as long as a wrong write takes).
    Sleep    1.5s
    Setting Should Be    panes    None
    Drag Mouse    599    400    380    400
    Sleep    0.5s
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Source Share Should Be Below    0.4

TC-SET-026 The Panes Are As They Were Left
    [Documentation]    The edge between Source and Results dragged to the left: the next
    ...    start has it there, so the Results pane (and its title) begins where Source
    ...    used to have its middle.
    [Tags]    p2
    Region Should Not Contain Text    @{LEFT_OF_RESULTS}    Results
    Drag Mouse    599    400    380    400
    Sleep    0.5s
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Source Share Should Be Below    0.4
    Start Again As The Same User
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{LEFT_OF_RESULTS}    Results
