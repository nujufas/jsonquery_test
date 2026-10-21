*** Settings ***
Documentation     The pane in the other states the window can be in: the light theme (its own colours for what is picked, lit
...               and tagged, and a folder that is dark ink on a light button), a window that is shorter, a pane that was
...               made wider, the widest it can be, settings that are wrong or out of range, a workspace that is under the
...               home (`~`), a row under the pointer -- see docs/25_workspace.md.
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace    variants
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Close Jsonquery App

*** Variables ***
${LIGHT_OPEN}             {"theme": "light", "workspace": {"pane": "open"}}
${LIGHT_NO_PANE}          {"theme": "light"}
# The light theme: the colour of the pane, of a row that is picked (the selection's blue, half translucent), and of a row
# under the pointer; the tags are the light fills of the sorts (jq, JMESPath, schema, patch).
${LIGHT_PLAIN}            ${{ (248, 248, 248) }}
${LIGHT_PICKED}           ${{ (196, 228, 255) }}
${LIGHT_HOVER}            ${{ (220, 220, 220) }}
# The dark theme's row under the pointer (egui's grey 70 for what is under the pointer).
${DARK_HOVER}             ${{ (70, 70, 70) }}
${LIGHT_BORDER}           ${{ (0, 83, 125) }}

*** Test Cases ***
TC-WSP-220 In The Light Theme A Picked Row Has The Colour Of A Selection There
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    settings=${LIGHT_OPEN}
    Click Row    ${ROW_SCRATCH}
    ${y}=    Row Y    ${ROW_SCRATCH}
    ${picked}=    Get Pixel Color    ${WS_ROW_X}    ${y}
    ${other}=    Get Pixel Color    ${WS_ROW_X}    ${{ ${y} - 40 }}
    Colors Should Match    ${picked}    ${LIGHT_PICKED}    tolerance=14    msg=A picked row is ${picked}
    Colors Should Match    ${other}    ${LIGHT_PLAIN}    tolerance=14    msg=A row that is not picked is ${other}

TC-WSP-221 In The Light Theme Every Sort Of Item Has Its Light Tag
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    settings=${LIGHT_OPEN}
    Row Should Have Tag Colour    ${ROW_LOGINS}    251    231    204
    Row Should Have Tag Colour    ${ROW_ORDERS}    211    238    238
    Row Should Have Tag Colour    ${ROW_UPDATE}    250    219    228
    Row Should Have Tag Colour    ${ROW_SCRATCH}    219    232    251
    Row Should Not Have Tag Colour    ${ROW_SCRATCH}    31    53    85

TC-WSP-222 In The Light Theme The Icons Are In Dark Ink
    [Documentation]    The header's button that makes a folder, a folder in the list and the pane's button in the status bar are
    ...    drawn in dark ink, as pictures: the folder with the plus left out, the plain folder, the window with its left column
    ...    filled.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    settings=${LIGHT_OPEN}
    Move Mouse To    600    400
    New Folder Icon Should Be At    ${WS_NEWFOLDER_ICON_LEFT}    ${WS_NEWFOLDER_ICON_TOP}    ${TRUE}
    Dark Folder Should Be A Plain Folder At    33    ${{ ${WS_LIST_TOP} + 10 }}
    Side Panel Icon Should Be At    ${WS_STATUS_ICON_LEFT}    ${WS_STATUS_ICON_TOP}    shown    ${TRUE}

TC-WSP-223 In The Light Theme A Row That Is Carried Lights The Folder With The Light Border
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    settings=${LIGHT_OPEN}
    Pick Up Row    ${ROW_SCRATCH}    ${ROW_SERVICES}
    ${y}=    Row Y    ${ROW_SERVICES}
    Region Should Contain Color    4    ${{ ${y} - 9 }}    248    18    0    83    125    tolerance=14
    ...    msg=The folder under the carried row has no border
    Region Should Not Contain Color    4    ${{ ${WS_LIST_TOP} }}    248    18    0    83    125    tolerance=14
    Mouse Up
    Sleep    0.6s
    Workspace File Should Exist    Services/scratch.jq

TC-WSP-285 In The Light Theme A Query Carried Onto The Query Pane Lights It With The Light Border
    [Documentation]    The pane is outlined in the colour of a selection of that theme (0, 83, 125), as the folder is in TC-WSP-223, and
    ...    the outline is gone when the query has been let go and opened.
    [Tags]    p3
    [Teardown]    Release And Close
    Close Jsonquery App
    Launch Workspace App    settings=${LIGHT_OPEN}
    Carry Row To    ${ROW_LOGINS}    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Region Should Contain Color    256    23    944    5    0    83    125    tolerance=14    msg=The Query pane has no border above
    Region Should Contain Color    255    30    6    90    0    83    125    tolerance=14    msg=The Query pane has no border at the left
    Mouse Up
    Sleep    0.8s
    Move Mouse To    600    400
    Region Should Not Contain Color    256    23    944    5    0    83    125    tolerance=14    msg=The border stays
    Query Box Should Hold    ${LOGINS_TEXT}

TC-WSP-286 In The Light Theme A Query File Held Over The Window Outlines The Query Box In The Link Colour Of That Theme
    [Documentation]    The outline is the colour of a link in the light theme (0, 155, 255) and is gone when the file is taken away.
    [Tags]    p3
    Close Jsonquery App
    Launch Jsonquery App    settings=${LIGHT_NO_PANE}
    ${folder}=    Make Temp Directory
    Create File    ${folder}${/}held.jq    .held
    Region Should Not Contain Color    8    49    1184    5    0    155    255    tolerance=14    msg=Outlined before anything is held
    Start Hovering Files    600    400    ${folder}${/}held.jq
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Color    8    49    1184    5    0    155    255    tolerance=14
    ...    msg=The query box has no outline above
    Region Should Contain Color    6    60    5    40    0    155    255    tolerance=14    msg=The query box has no outline at the left
    Stop Hovering Files
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Not Contain Color    8    49    1184    5    0    155    255    tolerance=14
    ...    msg=The outline stays

TC-WSP-224 In The Light Theme A Query Is Saved From The Window
    [Tags]    p3
    Close Jsonquery App
    Launch Workspace App    settings=${LIGHT_OPEN}
    Type In Query Box    .light
    Save Query As    bright
    Workspace File Should Be    bright.jq    .light
    List Should Show    bright

TC-WSP-225 A Shorter Window Has A Shorter List And The Details Stay At Its Foot
    [Documentation]    The pane goes from the top to the status bar whatever the height: in a window 600 high the details of
    ...    the item that is picked are in the foot of the pane, 200 higher than they are in a window of 800.
    [Tags]    p2
    Resize Window    JsonQuery    1200    600
    Sleep    1.0s
    Pane Should Be Open
    List Should Show    Logs    scratch
    Click Row    ${ROW_SCRATCH}
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Contain Text    0    410    256    170    scratch.jq

TC-WSP-226 A Pane That Was Made Wider Has Rows As Wide
    [Tags]    p2
    Drag Mouse    ${WS_PANE_WIDTH}    400    400    400
    Sleep    0.6s
    Click Row    ${ROW_SCRATCH}
    ${y}=    Row Y    ${ROW_SCRATCH}
    ${picked}=    Get Pixel Color    390    ${y}
    Colors Should Match    ${picked}    ${WS_SELECTED_COLOR}    tolerance=8    msg=The picked row ends before the pane does: ${picked}
    ${beyond}=    Get Pixel Color    420    ${y}
    Colors Should Not Match    ${beyond}    ${WS_SELECTED_COLOR}    tolerance=8

TC-WSP-227 The Pane Is At Most Half As Wide As The Window
    [Tags]    p3
    Drag Mouse    ${WS_PANE_WIDTH}    400    900    400
    Sleep    0.8s
    Pane Should Be This Wide    600

TC-WSP-228 A Setting That Says Nothing The App Knows Shows No Pane
    [Tags]    p2
    Close Jsonquery App
    Launch Jsonquery App    settings={"workspace": {"pane": "wide"}}    workspace=${STANDARD}
    Pane Should Not Be Shown
    Region Should Contain Text    0    0    70    24    Source

TC-WSP-229 A Width In The Settings Is Brought Into What The Pane Can Be
    [Documentation]    A number that is not a width (5000: the settings take 120 to 2000) is left out, and the pane is as wide as
    ...    it is without one (256); 1500 is a width but more than half the window, which is the most that the pane takes; 130
    ...    is less than the least (208, the room that the title and the four buttons of the header need).
    [Tags]    p3
    Close Jsonquery App
    Launch Jsonquery App    settings={"workspace": {"pane": "open", "width": 5000}}    workspace=${STANDARD}
    Pane Should Be Open
    Pane Should Be This Wide    256
    Close Jsonquery App
    Launch Jsonquery App    settings={"workspace": {"pane": "open", "width": 1500}}    workspace=${STANDARD}
    Pane Should Be Open
    Pane Should Be This Wide    600
    Close Jsonquery App
    Launch Jsonquery App    settings={"workspace": {"pane": "open", "width": 130}}    workspace=${STANDARD}
    Pane Should Be Open
    Pane Should Be This Wide    208
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Contain Text    @{WS_TITLE_AT_LEAST}    Workspace

TC-WSP-230 A Workspace Under The Home Is Written With A Tilde
    [Documentation]    The line under the title writes the home as ~ (the hover has the whole path). The folder is made in
    ...    the home of whoever runs the cases, in ~/tmp, and goes when the case ends.
    [Tags]    p3
    ${home}=    Get Environment Variable    HOME
    ${folder}=    Set Variable    ${home}${/}tmp${/}jq-ws-tilde-case
    Remove Directory    ${folder}    recursive=${TRUE}
    Create Directory    ${folder}
    Create File    ${folder}${/}one.jq    .one
    TRY
        Close Jsonquery App
        ${settings}=    Evaluate    json.dumps({"workspace": {"pane": "open", "folder": $folder}})    modules=json
        Launch Jsonquery App    settings=${settings}
        Pane Should Be Open
        Wait Until Region Matches    @{WS_PATH_LINE}    .{0,2}/tmp/jq.ws.tilde    timeout=6
        Region Should Not Contain Text    @{WS_PATH_LINE}    ${home}
    FINALLY
        Remove Directory    ${folder}    recursive=${TRUE}
    END

TC-WSP-231 A Row Under The Pointer Is Lit Grey
    [Tags]    p3
    ${y}=    Row Y    ${ROW_SCRATCH}
    Move Mouse To    ${WS_ROW_X}    ${y}
    Sleep    0.4s
    ${under}=    Get Pixel Color    ${WS_ROW_X}    ${y}
    Colors Should Match    ${under}    ${DARK_HOVER}    tolerance=6    msg=The row under the pointer is ${under}
    Move Mouse To    600    400
    Sleep    0.4s
    ${away}=    Get Pixel Color    ${WS_ROW_X}    ${y}
    Colors Should Match    ${away}    ${WS_PLAIN_COLOR}    tolerance=8

TC-WSP-232 In The Light Theme A Row Under The Pointer Is Lit Light Grey
    [Tags]    p3
    Close Jsonquery App
    Launch Workspace App    settings=${LIGHT_OPEN}
    ${y}=    Row Y    ${ROW_SCRATCH}
    Move Mouse To    ${WS_ROW_X}    ${y}
    Sleep    0.4s
    ${under}=    Get Pixel Color    ${WS_ROW_X}    ${y}
    Colors Should Match    ${under}    ${LIGHT_HOVER}    tolerance=8    msg=The row under the pointer is ${under}
    Move Mouse To    600    400
    Sleep    0.4s
    ${away}=    Get Pixel Color    ${WS_ROW_X}    ${y}
    Colors Should Match    ${away}    ${LIGHT_PLAIN}    tolerance=8

TC-WSP-233 Folders Nested Eight Deep Are Each Indented And The Item At The Bottom Still Has Its Tag
    [Documentation]    Each folder opens with a click, and the name of what is in it starts 14 points further right: the
    ...    item eight folders in is at the right place, has its tag and opens; the folder at the top shuts it all.
    [Tags]    p3
    Close Jsonquery App
    ${files}=    Evaluate    {"one/two/three/four/five/six/seven/eight/deep.jq": ".deep"}
    Launch Workspace App    files=${files}
    # Rows: one (open), two (shut) ... as each is opened the next is under it.
    FOR    ${row}    IN RANGE    1    8
        Click Row    ${row}
    END
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Show Text    @{WS_LIST}    deep
    ${y}=    Row Y    8
    ${start}=    Evaluate    46 + 14 * 8
    ${l}    ${t}    ${r}    ${b}=    Get Ink Bounds    ${{ ${start} - 4 }}    ${{ ${y} - 8 }}    60    16    threshold=90
    ${first}=    Evaluate    ${start} - 4 + ${l}
    Should Be True    ${start} <= ${first} <= ${start} + 6    msg=The name starts at ${first}, not at ${start}
    Row Should Have Tag Colour    8    31    53    85
    Double Click Row    8
    Query Box Should Hold    .deep
    Click Row    0
    Wait Until Keyword Succeeds    4x    0.5s    Region Should Not Show Text    @{WS_LIST}    deep

TC-WSP-234 A Taller Window Has A Taller List And The Details Stay At Its Foot
    [Documentation]    The pane goes from the top to the status bar whatever the height (the display is 900 high): in a
    ...    window 900 high the list has rows 100 lower than in one of 800, and the details of the item that is picked
    ...    are in the foot of the pane, 100 lower than they are in a window of 800.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${MANY}
    Resize Window    JsonQuery    1200    900
    Sleep    1.0s
    Pane Should Be Open
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Show Text    0    760    256    80    item
    Click Row    2
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Contain Text    0    710    256    170    logins

TC-WSP-235 A Wider Window Gives The Room To What Is Beside The Pane And Not To The Pane
    [Documentation]    The display is 1280 wide: the window is made as wide as that (80 more than usual).
    [Tags]    p3
    Resize Window    JsonQuery    1280    800
    Sleep    1.0s
    Pane Should Be Open
    Pane Should Be This Wide    256
    List Should Show    Logs    scratch

TC-WSP-236 A Click On The Strip's Button In A Window Too Narrow For The Pane Does Not Open It For Later
    [Documentation]    A pane that was folded stays folded: the button of the strip has no room to open the pane into
    ...    in a window of 800, and it must not leave the pane open for when the window is wide again.
    [Tags]    p3
    Close Jsonquery App
    Launch Jsonquery App    settings=${PANE_FOLDED}    workspace=${STANDARD}
    Resize Window    JsonQuery    800    600
    Sleep    1.0s
    Click At    ${WS_RAIL_X}    ${WS_RAIL_UNFOLD_Y}
    Sleep    0.8s
    Resize Window    JsonQuery    1200    800
    Sleep    1.0s
    Pane Should Not Be Shown
    Region Should Not Contain Text    0    60    256    300    scratch

TC-WSP-237 The Theme Button Changes The Pane Too While The App Runs
    [Documentation]    The pane is in the theme of the window: a click on the theme button makes the picked row, the
    ...    ground of the list and the tags light, and another click makes them dark again.
    [Tags]    p2
    Click Row    ${ROW_SCRATCH}
    ${y}=    Row Y    ${ROW_SCRATCH}
    Row Should Be Selected    ${ROW_SCRATCH}
    Click At    ${THEME_TOGGLE_X}    ${THEME_TOGGLE_Y}
    Sleep    0.8s
    Move Mouse To    600    400
    Sleep    0.4s
    ${picked}=    Get Pixel Color    ${WS_ROW_X}    ${y}
    ${other}=    Get Pixel Color    ${WS_ROW_X}    ${{ ${y} - 40 }}
    Colors Should Match    ${picked}    ${LIGHT_PICKED}    tolerance=14    msg=A picked row is ${picked} in the light theme
    Colors Should Match    ${other}    ${LIGHT_PLAIN}    tolerance=14    msg=A row that is not picked is ${other}
    Row Should Have Tag Colour    ${ROW_LOGINS}    251    231    204
    Click At    ${THEME_TOGGLE_X}    ${THEME_TOGGLE_Y}
    Sleep    0.8s
    Move Mouse To    600    400
    Sleep    0.4s
    Row Should Be Selected    ${ROW_SCRATCH}
    Row Should Have Tag Colour    ${ROW_LOGINS}    74    48    18

TC-WSP-238 The Pane Is Shown In A Window Of 900 Points And Only The Strip In One Of 899
    [Documentation]    The least width of a window that has room for the pane beside what it holds is 900 points.
    [Tags]    p3
    Resize Window    JsonQuery    900    700
    Sleep    1.0s
    Pane Should Be Open
    Resize Window    JsonQuery    899    700
    Sleep    1.0s
    Pane Should Not Be Shown
    Resize Window    JsonQuery    900    700
    Sleep    1.0s
    Pane Should Be Open

*** Keywords ***
Dark Folder Should Be A Plain Folder At
    [Documentation]    The picture on the point is a folder of dark ink on a light ground: 14 by 11 points, a tab at the top left
    ...    and nothing at the top right.
    [Arguments]    ${x}    ${y}
    ${left}=    Evaluate    int(${x}) - 12
    ${top}=    Evaluate    int(${y}) - 9
    ${l}    ${t}    ${r}    ${b}=    Get Dark Ink Bounds    ${left}    ${top}    24    18    threshold=150
    ${width}=    Evaluate    ${r} - ${l} + 1
    ${height}=    Evaluate    ${b} - ${t} + 1
    Should Be True    13 <= ${width} <= 15    msg=A folder is 14 wide, this is ${width}
    Should Be True    10 <= ${height} <= 12    msg=A folder is 11 high, this is ${height}
    ${tab}=    Get Pixel Color    ${{ ${left} + ${l} + 2 }}    ${{ ${top} + ${t} + 1 }}
    ${corner}=    Get Pixel Color    ${{ ${left} + ${r} - 2 }}    ${{ ${top} + ${t} + 1 }}
    ${body}=    Get Pixel Color    ${{ ${left} + ${l} + 7 }}    ${{ ${top} + ${t} + 7 }}
    Should Be True    max($tab) <= 150    msg=No tab at the top left: ${tab}
    Should Be True    max($corner) > 150    msg=Ink at the top right, where there is no tab: ${corner}
    Should Be True    max($body) <= 150    msg=The body is not solid: ${body}

