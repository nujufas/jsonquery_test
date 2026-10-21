*** Settings ***
Documentation     The workspace pane: the button at the left end of the status bar that shows it, the strip it folds
...               to, the list of folders and items, the filter and the chips, the item that is picked --
...               see docs/25_workspace.md. The workspace is an ordinary folder (`workspace` in the folder
...               the app keeps its settings in), and the cases make the files that are in it before the
...               app starts (`STANDARD`, workspace_fixture.py) and read the folder afterwards.
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Close Jsonquery App

*** Variables ***
# The status bar: the pane's button at the left end, and at the right the ⚙, the 🌐 and the ⓘ from the left.
${GEAR_X}                 1123
${GLOBE_X}                1152
${INFO_X}                 1181

*** Test Cases ***
TC-WSP-001 The Workspace Is Not There Until It Is Asked For
    [Documentation]    A new user's window is as it always was: no pane, no strip, the Source label at the
    ...    left, and nothing made on disk for a workspace. (The pane is hidden until the button in the status bar is
    ...    pressed: the window the older cases were calibrated on.)
    [Tags]    p1
    Close Jsonquery App
    Launch Jsonquery App
    Pane Should Not Be Shown
    Region Should Contain Text    0    0    70    24    Source
    Region Should Contain Text    @{QUERY_ROW}    Run
    Region Should Not Contain Text    @{QUERY_ROW}    Save
    ${folder}=    Workspace Folder
    Directory Should Not Exist    ${folder}

TC-WSP-002 The Button In The Status Bar Shows The Pane And Hides It Again
    [Documentation]    One button, at the left end of the status bar: a click shows the pane at the left of the window, the
    ...    next one takes it away, and neither moves the button, the ⚙, the 🌐 or the ⓘ.
    [Tags]    p1
    Close Jsonquery App
    Launch Jsonquery App
    Icon Should Be At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Icon Should Be At    ${GEAR_X}    ${WS_STATUS_Y}
    Click At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Pane Should Be Open
    Icon Should Be At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Icon Should Be At    ${GEAR_X}    ${WS_STATUS_Y}
    Icon Should Be At    ${GLOBE_X}    ${WS_STATUS_Y}
    Icon Should Be At    ${INFO_X}    ${WS_STATUS_Y}
    Region Should Contain Text    @{WS_QUERY_ROW}    Save
    Click At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Pane Should Not Be Shown
    Icon Should Be At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Icon Should Be At    ${GEAR_X}    ${WS_STATUS_Y}
    Region Should Not Contain Text    @{QUERY_ROW}    Save

TC-WSP-003 The Button Is A Window With Its Left Column Filled, Dim While The Pane Is Not Shown
    [Documentation]    The picture is a window with the column at its left filled, 14 by 12 points: the pane is that column, and
    ...    the rest of the window is what is beside it. Read as the pixels it is drawn in; bright while the pane is shown,
    ...    dim while it is not.
    [Tags]    p1
    Close Jsonquery App
    Launch Jsonquery App
    Move Mouse To    600    400
    Side Panel Icon Should Be At    ${WS_STATUS_ICON_LEFT}    ${WS_STATUS_ICON_TOP}    hidden
    Click At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Pane Should Be Open
    Move Mouse To    600    400
    Side Panel Icon Should Be At    ${WS_STATUS_ICON_LEFT}    ${WS_STATUS_ICON_TOP}    shown

TC-WSP-004 The Button That Makes A Folder Is A Folder With A Plus In It
    [Documentation]    The header's buttons are the three of a pane: save, a new folder and a menu, and the one
    ...    that folds the pane. The new folder's is a folder with a plus left out of it, 15 by 11 points, in the colour of
    ...    the folders in the list (the folders in the list have no plus).
    [Tags]    p1
    New Folder Icon Should Be At    ${WS_NEWFOLDER_ICON_LEFT}    ${WS_NEWFOLDER_ICON_TOP}
    Icon Should Be At    ${WS_SAVE_X}    ${WS_HEADER_Y}
    Icon Should Be At    ${WS_MENU_X}    ${WS_HEADER_Y}
    Icon Should Be At    ${WS_FOLD_X}    ${WS_HEADER_Y}

TC-WSP-005 A Folder In The List Is The Same Plain Folder Whether It Is Open Or Shut
    [Tags]    p2
    ${open_row}=    Row Y    ${ROW_LOGS}
    ${shut_row}=    Row Y    ${ROW_ERRORS}
    ${a}=    Folder Should Be A Plain Folder At    33    ${open_row}
    ${b}=    Folder Should Be A Plain Folder At    47    ${shut_row}
    Should Be Equal As Integers    ${a}    ${b}    msg=An open and a shut folder differ in colour

TC-WSP-006 The List Has The Top Folders Open And The Rest Shut
    [Documentation]    The folders at the top of the workspace start open, the ones inside them shut, and every
    ...    folder is before the items that are beside it.
    [Tags]    p1
    List Should Show    Logs    Errors    logins    Services    update    orders    scratch
    List Should Not Show    failures
    Row Should Not Be Selected    ${ROW_LOGS}
    Row Should Not Be Selected    ${ROW_SCRATCH}

TC-WSP-007 A Click On A Folder Opens It And A Click On It Again Shuts It
    [Tags]    p1
    Click Row    ${ROW_ERRORS}
    List Should Show    failures
    Click Row    ${ROW_ERRORS}
    List Should Not Show    failures
    Click Row    ${ROW_LOGS}
    List Should Not Show    logins    Errors
    List Should Show    Logs    Services    scratch
    Click Row    ${ROW_LOGS}
    List Should Show    logins    Errors

TC-WSP-008 A Click Picks A Row And The Details Under The List Say What It Is
    [Tags]    p1
    Details Should Show    Pick an item
    Click Row    ${ROW_SCRATCH}
    Row Should Be Selected    ${ROW_SCRATCH}
    Row Should Not Be Selected    ${ROW_UPDATE}
    Details Should Show    scratch    scratch.jq    Open
    Details Should Match    No sam
    Click Row    ${ROW_ORDERS}
    Row Should Be Selected    ${ROW_ORDERS}
    Row Should Not Be Selected    ${ROW_SCRATCH}
    Details Should Show    orders    Services/orders.schema.json    Use as schema
    Details Should Match    Sam[pq]le: orders

TC-WSP-009 What A Folder Holds Is Said Under The List When It Is Picked
    [Tags]    p2
    Click Row    ${ROW_SERVICES}
    Row Should Be Selected    ${ROW_SERVICES}
    Details Should Show    Services
    Details Should Not Show    scratch.jq
    Click Row    ${ROW_LOGS}
    Details Should Show    Logs

TC-WSP-010 What Is Typed In The Filter Narrows The List By Name
    [Tags]    p1
    Type In Filter    ord
    List Should Show    orders    Services
    List Should Not Show    scratch    logins    update    Logs
    Clear The Filter
    List Should Show    Logs    logins    update    scratch

TC-WSP-011 The Filter Looks At The Name Of The Folder As Well As The Name Of The Item
    [Tags]    p2
    Type In Filter    servi
    List Should Show    orders    update
    List Should Not Show    logins    scratch

TC-WSP-012 The Filter Does Not Mind The Case
    [Documentation]    What is typed in capitals finds a name in small letters, and what is typed in small letters
    ...    finds a name that has capitals.
    [Tags]    p2
    Close Jsonquery App
    ${files}=    Evaluate    {**$STANDARD, "Weekly Report.jq": "."}
    Launch Workspace App    files=${files}
    Type In Filter    ORDE
    List Should Show    orders
    List Should Not Show    scratch    update    Weekly
    Type In Filter    weekly
    List Should Show    Weekly
    List Should Not Show    orders    scratch

TC-WSP-013 A Filter That Matches Nothing Says So And Shows Nothing
    [Tags]    p2
    Type In Filter    zzz
    List Should Not Show    Logs    Services    scratch    orders
    Wait Until Region Matches    @{WS_LIST}    Nothing here    timeout=4

TC-WSP-014 The Chips Narrow The List To One Sort Of Item
    [Documentation]    Queries, Schemas, Patches and Docs: the folders that have none of that sort are left out,
    ...    the ones that have some are open, and All brings everything back.
    [Tags]    p1
    Click Chip    queries
    List Should Show    logins    scratch    failures
    List Should Not Show    orders    update    Services
    Click Chip    schemas
    List Should Show    orders
    List Should Not Show    logins    scratch    update    failures
    Click Chip    patches
    List Should Show    update
    List Should Not Show    orders    logins    scratch
    Click Chip    all
    List Should Show    logins    scratch    orders    update

TC-WSP-015 The Docs Chip Shows The JSON And NDJSON Files And Not The Other Sorts
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${MIXED}
    Click Chip    docs
    List Should Show    data    events
    List Should Not Show    orders    scratch    logins    update

TC-WSP-016 A Chip That Has Nothing Under It Says So
    [Tags]    p3
    Click Chip    docs
    List Should Not Show    orders    scratch    logins    update    Logs
    Wait Until Region Matches    @{WS_LIST}    Nothing here    timeout=4

TC-WSP-017 A Chip And A Filter Narrow The List Together
    [Tags]    p2
    Click Chip    queries
    Type In Filter    log
    List Should Show    logins    failures
    List Should Not Show    scratch    orders    update

TC-WSP-018 The Fold Button Folds The Pane To A Strip And The Strip's Button Opens It Again
    [Tags]    p1
    Click Header Button    fold
    Pane Should Not Be Shown
    Region Should Contain Text    @{WS_SOURCE_LABEL_FOLDED}    Source
    Region Should Contain Text    @{WS_QUERY_ROW_FOLDED}    Save
    Click At    ${WS_RAIL_X}    ${WS_RAIL_UNFOLD_Y}
    Pane Should Be Open
    List Should Show    Logs    scratch

TC-WSP-019 The Strip Has A Button And The Pane's Icon, And The Window Takes The Room
    [Documentation]    The strip is the pane folded: the button that opens it, and under it the same window with its left
    ...    column filled as the status bar's button has, dim as the pane is not shown.
    [Tags]    p2
    Click Header Button    fold
    Pane Should Not Be Shown
    Move Mouse To    600    400
    Icon Should Be At    ${WS_RAIL_X}    ${WS_RAIL_UNFOLD_Y}
    Side Panel Icon Should Be At    ${WS_RAIL_ICON_LEFT}    ${WS_RAIL_ICON_TOP}    hidden
    # The main view starts at the strip, not at the pane's edge.
    Region Should Contain Text    @{WS_SOURCE_LABEL_FOLDED}    Source
    Region Should Not Contain Text    0    90    256    300    scratch

TC-WSP-020 The Menu Has An Item That Hides The Workspace
    [Tags]    p1
    Pick Pane Menu Item    Hide the
    Pane Should Not Be Shown
    Region Should Not Contain Text    0    22    260    24    Save
    Move Mouse To    600    400
    Side Panel Icon Should Be At    ${WS_STATUS_ICON_LEFT}    ${WS_STATUS_ICON_TOP}    hidden

TC-WSP-021 How Much Of The Pane Is Shown Is Kept
    [Documentation]    Open, folded and hidden are each what the next start shows (workspace.pane in settings.json).
    [Tags]    p1
    Click Header Button    fold
    Quit And Start Again
    Region Should Contain Text    @{WS_SOURCE_LABEL_FOLDED}    Source
    Region Should Not Contain Text    @{WS_TITLE}    Workspace
    Settings Value Should Be    workspace.pane    collapsed
    Click At    ${WS_RAIL_X}    ${WS_RAIL_UNFOLD_Y}
    Pane Should Be Open
    Quit And Start Again
    Pane Should Be Open
    Settings Value Should Be    workspace.pane    open
    Click At    ${WS_STATUS_X}    ${WS_STATUS_Y}
    Pane Should Not Be Shown
    Quit And Start Again
    Pane Should Not Be Shown
    Region Should Contain Text    0    0    70    24    Source

TC-WSP-022 The Pane Is As Wide As It Was Dragged To And That Is Kept
    [Tags]    p2
    ${before}=    Get Pixel Color    300    400
    Colors Should Match    ${before}    ${{ (10, 10, 10) }}    tolerance=6    msg=Main view at 300: ${before}
    Drag Mouse    ${WS_PANE_WIDTH}    400    330    400
    Sleep    0.6s
    ${after}=    Get Pixel Color    300    400
    Colors Should Match    ${after}    ${WS_PLAIN_COLOR}    tolerance=6    msg=The pane did not widen: ${after}
    Quit And Start Again
    ${again}=    Get Pixel Color    300    400
    Colors Should Match    ${again}    ${WS_PLAIN_COLOR}    tolerance=6    msg=The width was not kept: ${again}
    ${width}=    Settings Value    workspace.width
    Should Be True    325 <= ${width} <= 335    msg=workspace.width is ${width}

TC-WSP-023 The Pane Cannot Be Made Narrower Than A Least Width
    [Documentation]    The least is 208: the room that the title of the pane and the four buttons beside it need (narrower, a
    ...    button would be drawn over the end of the title). At that width the title is still read whole, and each of
    ...    the four buttons is drawn, 48 points to the left of where it is in a pane of 256.
    [Tags]    p3
    Drag Mouse    ${WS_PANE_WIDTH}    400    90    400
    Sleep    0.6s
    Pane Should Be This Wide    208
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Contain Text    @{WS_TITLE_AT_LEAST}    Workspace
    FOR    ${x}    IN    ${WS_SAVE_X}    ${WS_FOLDER_X}    ${WS_MENU_X}    ${WS_FOLD_X}
        ${at}=    Evaluate    ${x} - (${WS_PANE_WIDTH} - 208)
        Get Ink Bounds    ${{ ${at} - 9 }}    ${{ ${WS_HEADER_Y} - 9 }}    18    18    threshold=100
    END

TC-WSP-024 In A Window Too Narrow For It Only The Strip Is Shown
    [Documentation]    The pane needs room beside what the window holds: in a window narrower than 900 points
    ...    it is the strip, and the window wide again has the pane back.
    [Tags]    p2
    Resize Window    JsonQuery    800    600
    Sleep    1.0s
    Pane Should Not Be Shown
    Region Should Not Contain Text    0    60    256    300    scratch
    # The strip's button has no room to open the pane into: a click on it does nothing.
    Click At    ${WS_RAIL_X}    ${WS_RAIL_UNFOLD_Y}
    Sleep    0.8s
    Pane Should Not Be Shown
    Resize Window    JsonQuery    1200    800
    Sleep    1.0s
    Pane Should Be Open
    List Should Show    scratch

TC-WSP-025 A Workspace With Nothing In It Says So
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${NO_FILES}
    Wait Until Region Matches    @{WS_LIST}    Nothing is saved    timeout=5
    Wait Until Region Matches    @{WS_PATH_LINE}    [0OQ][ ]?.{0,3}ms    timeout=4

TC-WSP-026 A Folder That Was Chosen And Is Gone Is Said And Is Not Made Again
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    settings={"workspace": {"pane": "open", "folder": "/tmp/jq-no-such-folder-x7"}}
    Wait Until Region Matches    @{WS_LIST}    folder is not there    timeout=5
    Region Should Contain Text    @{WS_LIST}    Choose another
    Region Should Contain Text    @{WS_LIST}    usual one
    Directory Should Not Exist    /tmp/jq-no-such-folder-x7

TC-WSP-027 Use The Usual One Goes Back To The Usual Workspace
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    settings={"workspace": {"pane": "open", "folder": "/tmp/jq-no-such-folder-x7"}}
    Wait Until Region Matches    @{WS_LIST}    folder is not there    timeout=5
    Click Text In Region    @{WS_LIST}    usual
    Sleep    0.8s
    # The usual workspace is the one the case made its files in.
    List Should Show    scratch    orders
    Region Should Not Contain Text    @{WS_LIST}    folder is not there
    Quit And Start Again
    List Should Show    scratch
    Settings Value Should Be    workspace.folder    None

TC-WSP-028 The Line Under The Title Says Where The Workspace Is And How Much Is In It
    [Tags]    p2
    Wait Until Region Matches    @{WS_PATH_LINE}    orkspace.{1,6}[5S][^0-9]{0,3}[a-z]{3,6}    timeout=5

TC-WSP-029 Every Sort Of Item Has Its Own Tag
    [Documentation]    A query by the language it is in (jq, JMESPath, JSONPath, JSON Pointer), a schema, a patch, a
    ...    document: a coloured tag at the right of the row.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${MIXED}
    # Rows: Logs, Errors, logins, Services, orders, update, data, events, scratch.
    Row Should Have Tag Colour    ${ROW_LOGINS}    74    48    18
    Row Should Have Tag Colour    ${ROW_ORDERS}    23    72    75
    Row Should Have Tag Colour    ${ROW_UPDATE}    82    32    47
    Row Should Have Tag Colour    6    56    56    56
    Row Should Have Tag Colour    7    56    56    56
    Row Should Have Tag Colour    8    31    53    85
    Row Should Not Have Tag Colour    ${ROW_LOGINS}    31    53    85

TC-WSP-030 What Is Not An Item Is Not Shown
    [Documentation]    A text file, a markdown file, a name that starts with a dot and a folder that does, with what is in
    ...    it, are not items; nor are the samples, which belong to the items.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${MIXED}
    List Should Show    data    events    orders
    List Should Not Show    notes    readme    hidden    secret    inside    sample
    Wait Until Region Matches    @{WS_PATH_LINE}    [7T] ?.{0,3}ms    timeout=4

TC-WSP-031 A Row That Has A Sample Has A Paperclip And Its Tag Is Moved Over For It
    [Documentation]    The sample is shown by a paperclip at the right end of the row; the tag that says what the item
    ...    is is then that much further left than the tag of an item of the same sort that has no sample.
    [Tags]    p2
    Click Row    ${ROW_ERRORS}
    # Rows now: Logs, Errors, failures (a query with a sample), logins, Services, orders, update, scratch.
    ${with}=    Tag Right Edge    2    31    53    85
    ${without}=    Tag Right Edge    7    31    53    85
    Should Be True    ${without} - ${with} >= 8    msg=The tags end at ${with} (sample) and ${without} (none)
    ${y}=    Row Y    2
    Icon Should Be At    ${PAPERCLIP_X}    ${y}
    ${y}=    Row Y    7
    ${left}=    Evaluate    ${without} + 6 + 170
    ${top}=    Evaluate    ${y} - 8
    Run Keyword And Expect Error    Nothing as bright as*    Get Ink Bounds    ${left}    ${top}    10    16    threshold=60

TC-WSP-032 Folders Come Before Items And Every One Is In Alphabetical Order
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${MIXED}
    ${logs}=    Row Name Y    Logs
    ${services}=    Row Name Y    Services
    ${data}=    Row Name Y    data
    ${events}=    Row Name Y    events
    ${scratch}=    Row Name Y    scratch
    Should Be True    ${logs} < ${services} < ${data} < ${events} < ${scratch}

TC-WSP-033 A List Longer Than The Pane Scrolls
    [Documentation]    Sixty queries and the seven of STANDARD: the end of the list (the last query, and scratch
    ...    after it) is out of view until the list is scrolled, and the head is out of view then.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${MANY}
    Wait Until Region Matches    @{WS_LIST}    item[0o][1l]    timeout=4
    Region Should Not Show Text    @{WS_LIST}    scratch
    Scroll At    ${WS_ROW_X}    300    -120
    Sleep    0.6s
    Wait Until Region Matches    @{WS_LIST}    item[5S][89]    timeout=4
    Region Should Show Text    @{WS_LIST}    scratch
    Region Should Not Show Text    @{WS_LIST}    Services
    Scroll At    ${WS_ROW_X}    300    120
    Sleep    0.6s
    List Should Show    Logs    Services

TC-WSP-034 The Arrow Of A Folder Points Right When It Is Shut And Down When It Is Open
    [Documentation]    The little triangle before a folder's picture: a shut one is taller than wide, an open one wider than
    ...    tall (it is drawn with shapes, as the fonts of the window have no glyph for an arrow).
    [Tags]    p2
    # Logs is open, Errors is shut.
    ${open_w}    ${open_h}=    Arrow Size    ${ROW_LOGS}    1
    ${shut_w}    ${shut_h}=    Arrow Size    ${ROW_ERRORS}    2
    Should Be True    ${open_w} > ${open_h}    msg=An open folder's arrow is ${open_w} wide and ${open_h} high
    Should Be True    ${shut_h} > ${shut_w}    msg=A shut folder's arrow is ${shut_w} wide and ${shut_h} high
    Click Row    ${ROW_ERRORS}
    # (what is picked has a fill of its own: the pick is moved to another row, scratch, for the measure)
    Click Row    7
    ${now_w}    ${now_h}=    Arrow Size    ${ROW_ERRORS}    2
    Should Be True    ${now_w} > ${now_h}    msg=Errors was opened and its arrow is ${now_w} wide and ${now_h} high

TC-WSP-035 The Button That Folds The Pane Points Left And The One That Opens It Points Right
    [Documentation]    A triangle: the base is a wall at one side and the tip is at the other, on the middle line.
    [Tags]    p2
    ${x}=    Set Variable    ${WS_FOLD_X}
    ${y}=    Set Variable    ${WS_HEADER_Y}
    ${wall}=    Get Pixel Color    ${{ ${x} + 2 }}    ${{ ${y} - 2 }}
    ${tip}=    Get Pixel Color    ${{ ${x} - 2 }}    ${y}
    ${corner}=    Get Pixel Color    ${{ ${x} - 3 }}    ${{ ${y} - 3 }}
    Should Be True    max($wall) >= 100    msg=No wall at the right of the fold button: ${wall}
    Should Be True    max($tip) >= 100    msg=No tip at the left of the fold button: ${tip}
    Should Be True    max($corner) < 100    msg=The fold button does not point left: ${corner} at its top left
    Click Header Button    fold
    Pane Should Not Be Shown
    ${x}=    Set Variable    ${WS_RAIL_X}
    ${y}=    Set Variable    ${WS_RAIL_UNFOLD_Y}
    ${wall}=    Get Pixel Color    ${{ ${x} - 3 }}    ${{ ${y} - 2 }}
    ${tip}=    Get Pixel Color    ${{ ${x} + 1 }}    ${y}
    ${far}=    Get Pixel Color    ${{ ${x} + 2 }}    ${{ ${y} - 3 }}
    Should Be True    max($wall) >= 100    msg=No wall at the left of the unfold button: ${wall}
    Should Be True    max($tip) >= 100    msg=No tip at the right of the unfold button: ${tip}
    Should Be True    max($far) < 100    msg=The unfold button does not point right: ${far} at its top right

TC-WSP-036 The Three Dots Of The Menu Button Are One Over The Other
    [Tags]    p3
    ${x}=    Set Variable    ${WS_MENU_X}
    FOR    ${dy}    IN    -4    0    4
        ${y}=    Evaluate    ${WS_HEADER_Y} + ${dy}
        ${dot}=    Get Pixel Color    ${x}    ${y}
        Should Be True    max($dot) >= 120    msg=No dot at ${dy}: ${dot}
    END
    FOR    ${dy}    IN    -2    2
        ${y}=    Evaluate    ${WS_HEADER_Y} + ${dy}
        ${gap}=    Get Pixel Color    ${x}    ${y}
        Should Be True    max($gap) < 120    msg=No gap between the dots at ${dy}: ${gap}
    END

TC-WSP-037 What Is In A Folder Is Indented Under It And The Names Line Up
    [Documentation]    A name starts 14 points further right for each folder it is in, and an item's name is where a
    ...    folder's is (the item has no arrow or picture, but it leaves the room for them).
    [Tags]    p2
    Name Should Start At    ${ROW_LOGS}    0
    Name Should Start At    ${ROW_ERRORS}    1
    Name Should Start At    ${ROW_LOGINS}    1
    Name Should Start At    ${ROW_SERVICES}    0
    Name Should Start At    ${ROW_ORDERS}    1
    Name Should Start At    ${ROW_SCRATCH}    0
    Click Row    ${ROW_ERRORS}
    # failures is in Errors, which is in Logs: two folders in.
    Name Should Start At    2    2

TC-WSP-038 A Folder Says How Many Items Are In It At The Right Of Its Row
    [Documentation]    The number is small and grey: that there is one, at the right end of the row of each folder, is what
    ...    the case sees (the layout tests read the number).
    [Tags]    p3
    FOR    ${row}    IN    ${ROW_LOGS}    ${ROW_SERVICES}
        ${y}=    Row Y    ${row}
        ${top}=    Evaluate    ${y} - 8
        Get Ink Bounds    232    ${top}    18    16    threshold=60
    END

TC-WSP-039 The Details Show The First Lines Of What The Item Holds
    [Tags]    p2
    Click Row    ${ROW_ERRORS}
    Click Row    2
    Details Should Show    failures    map(select

*** Keywords ***
Arrow Size
    [Documentation]    How wide and how high the little arrow of the row is (it is at the left of the row, `level` steps in).
    [Arguments]    ${row}    ${level}
    ${y}=    Row Y    ${row}
    ${x}=    Evaluate    8 + 4 + 14 * (${level} - 1) - 2
    ${l}    ${t}    ${r}    ${b}=    Get Ink Bounds    ${x}    ${{ ${y} - 8 }}    14    16    threshold=60
    ${w}=    Evaluate    ${r} - ${l} + 1
    ${h}=    Evaluate    ${b} - ${t} + 1
    RETURN    ${w}    ${h}

Name Should Start At
    [Documentation]    The first ink of the name of the row is where the name of a row `depth` folders in starts (46, and 14
    ...    more for each folder): a letter has a little room at its left, so not before that and not more than 6 after.
    [Arguments]    ${row}    ${depth}
    ${y}=    Row Y    ${row}
    ${start}=    Evaluate    46 + 14 * int(${depth})
    ${left}=    Evaluate    ${start} - 4
    ${l}    ${t}    ${r}    ${b}=    Get Ink Bounds    ${left}    ${{ ${y} - 8 }}    60    16    threshold=90
    ${first}=    Evaluate    ${left} + ${l}
    Should Be True    ${start} <= ${first} <= ${start} + 6    msg=The name of row ${row} starts at ${first}, not at ${start} (depth ${depth})
