*** Settings ***
Documentation     A file dropped on the window can be the query -- see docs/25_workspace.md and docs/16_drag_and_drop.md. One
...               whose name ends .jq, .jsonpath, .jmespath or .jsonptr goes in the query box, in its language; any other
...               file is opened as the Source, as it always was; several go to Merge. The window is not told where in it a file
...               is let go (the toolkit under the app drops the position that X11 sends), so no pane can be picked by the
...               pointer and the name of the file is what says where it goes: the cases let go in the middle of the window.
...
...               The files are dropped for real: an XDND source (resources/xdnd.py) plays the part of the file manager, as in
...               suites/drag_and_drop. What is held over the window and not yet let go (`Start Hovering Files`) is what the
...               window shows while the file is carried: the query box outlined in the link colour, and the empty Source
...               saying what the file would be.
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace    query-drop
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${FIXTURES}               ${CURDIR}/../../resources/fixtures
# Where the file is let go: the middle of the window (it does not matter where).
${DROP_X}                 600
${DROP_Y}                 400
# The words in the middle of the empty Source pane while a file is held over the window.
@{DROP_OVERLAY}           100    190    400    36
# The outline of the query box (x 8-1191, y 51-115, with the pane hidden) while a query file is over the window: the link
# colour, 1.5 points, drawn on the box's own edge.
${OUTLINE_R}              90
${OUTLINE_G}              170
${OUTLINE_B}              255
# One mebibyte, which is as much as a file may hold to be a query.
${A_MEBIBYTE}             1048576
${TOOLS_WINDOW}           JsonQuery — Tools
@{MERGE_LEFT_HEADER}      8      110    220    24

*** Test Cases ***
TC-WSP-249 A File From Anywhere Else Is Nobody's And The Row Forgets The Item It Had
    [Documentation]    A query opened from the pane says so in the Query row; a file from another folder, let go after it, takes the
    ...    box and the row says no item any more.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App
    Double Click Row    ${ROW_SCRATCH}
    Wait Until Region Matches    @{WS_QUERY_ROW}    scratch\\.jq    timeout=4
    ${other}=    A Query File    other.jq    .other
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${other}
    Query Box Should Hold    .other
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Not Contain Text    @{WS_QUERY_ROW}    scratch

TC-WSP-250 A File That Ends .jq Dropped On The Window Is A jq Query In The Query Box
    [Documentation]    The text of the file is in the box, the jq engine is picked, and the Source is left as it was (empty):
    ...    nothing is loaded and nothing is said to have gone wrong.
    [Tags]    p1
    ${file}=    A Query File    mine.jq    .items[] | .name
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${file}
    Query Box Should Hold    .items[] | .name
    Engine Chip Should Be Selected    jq
    Engine Chip Should Not Be Selected    jmespath
    Source Should Still Be Empty
    Nothing Should Be Said In The Status Bar About The Load

TC-WSP-251 A File That Ends .jsonpath Is A JSONPath Query, .jmespath A JMESPath Query And .jsonptr A JSON Pointer
    [Documentation]    Each language that the workspace tells by the end of a name is picked by the same: the text is in the box
    ...    and the engine chip of that language is the one that is picked, one drop after the other.
    [Tags]    p1
    ${paths}=    A Query File    paths.jsonpath    $.shop.items[0].price
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${paths}
    Query Box Should Hold    $.shop.items[0].price
    Engine Chip Should Be Selected    jsonpath
    Engine Chip Should Not Be Selected    jq
    ${map}=    A Query File    ok.jmespath    [?ok].name
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${map}
    Query Box Should Hold    [?ok].name
    Engine Chip Should Be Selected    jmespath
    Engine Chip Should Not Be Selected    jsonpath
    ${pointer}=    A Query File    first.jsonptr    /items/0/name
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${pointer}
    Query Box Should Hold    /items/0/name
    Engine Chip Should Be Selected    pointer
    Engine Chip Should Not Be Selected    jmespath

TC-WSP-252 The End Of The Name Is All That Says It Is A Query, Whatever Its Case Or Where It Is Hidden
    [Documentation]    Capitals do not matter, nor a dot at the start of the name (a hidden file), nor dots in the middle of it.
    [Tags]    p2
    ${upper}=    A Query File    UPPER.JQ    .upper
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${upper}
    Query Box Should Hold    .upper
    Engine Chip Should Be Selected    jq
    ${hidden}=    A Query File    .hidden.jmespath    hidden_one
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${hidden}
    Query Box Should Hold    hidden_one
    Engine Chip Should Be Selected    jmespath
    ${dots}=    A Query File    many.dots.in.it.jsonpath    $..dots
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${dots}
    Query Box Should Hold    $..dots
    Engine Chip Should Be Selected    jsonpath

TC-WSP-253 A Document Is Opened As The Source And The Query Box Is Left Alone
    [Documentation]    A file that does not end like a query is what it was before: the Source. What was typed in the query
    ...    box stays.
    [Tags]    p1
    Type In Query Box    .keep
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${FIXTURES}/people.json
    Source Should Show    3 items
    Query Box Should Hold    .keep

TC-WSP-254 A Text File Is Not A Query Whatever Is In It
    [Documentation]    A .txt file does not end like a query, whatever it holds: it is opened as the Source, is not JSON, and is
    ...    said so; the box keeps what was in it.
    [Tags]    p2
    Type In Query Box    .keep
    ${file}=    A Query File    maybe.txt    .name
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${file}
    Wait Until Keyword Succeeds    8x    0.5s    Region Should Contain Text    @{STATUS_BAR}    Load error
    Query Box Should Hold    .keep

TC-WSP-255 A Schema Or A Patch Is A Document Here, Not A Query
    [Documentation]    The workspace has items that are schemas and patches (their names end .schema.json and .patch.json), but
    ...    only a query goes in the query box: a file of either is opened as the Source.
    [Tags]    p2
    Type In Query Box    .keep
    ${patch}=    A Query File    bump.patch.json    [{"op": "add", "path": "/platypus", "value": 1}]
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${patch}
    Source Should Show    1 items
    Query Box Should Hold    .keep

TC-WSP-256 A Query File Takes The Place Of What Was In The Box
    [Documentation]    The text that was there is gone and the engine that was picked is not the one that is picked now.
    [Tags]    p1
    Type In Query Box    /old/path
    Pick Engine    pointer
    Engine Chip Should Be Selected    pointer
    ${file}=    A Query File    new.jmespath    [?new]
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${file}
    Query Box Should Hold    [?new]
    Engine Chip Should Be Selected    jmespath
    Engine Chip Should Not Be Selected    pointer

TC-WSP-257 A Byte-Order Mark At The Start Of The File Is Not In The Box
    [Documentation]    Some editors write the three bytes that say a file is UTF-8 in front of its text: they are not a part of
    ...    the query.
    [Tags]    p2
    ${folder}=    Make Temp Directory
    ${bytes}=    Evaluate    bytes([0xEF, 0xBB, 0xBF]) + b'.name'
    Create Binary File    ${folder}${/}marked.jq    ${bytes}
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${folder}${/}marked.jq
    Query Box Should Hold    .name

TC-WSP-258 A Query File Of More Than A Mebibyte Is Said To Be Too Big And The Box Is Left Alone
    [Documentation]    A query is a line or a page: a file this big is not one. The status bar says so and the box keeps what
    ...    it had. (What is exactly a mebibyte is still a query: a case of the app's own, not of a window that would have
    ...    to draw a line of a million dots.)
    [Tags]    p1
    Type In Query Box    .keep
    ${big}=    A Query File Of Dots    big.jq    ${{ ${A_MEBIBYTE} + 1 }}
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${big}
    Wait Until Region Matches    @{STATUS_BAR}    Load error.{0,3} ?big\\.? ?jq is too big to put in a ?box    timeout=8
    Query Box Should Hold    .keep
    Source Should Still Be Empty

TC-WSP-260 A Query File That Is Not Text Is Said Not To Be Readable And The Box Is Left Alone
    [Tags]    p2
    Type In Query Box    .keep
    ${folder}=    Make Temp Directory
    ${bytes}=    Evaluate    bytes([0xFF, 0xFE, 0x00, 0x80])
    Create Binary File    ${folder}${/}binary.jq    ${bytes}
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${folder}${/}binary.jq
    Wait Until Region Matches    @{STATUS_BAR}    Load error.{0,3} ?binary\\.? ?jq could not be read    timeout=8
    Query Box Should Hold    .keep

TC-WSP-261 A File That Is Gone When It Is Let Go Is Not Seen At All
    [Documentation]    The toolkit under the app resolves the path of a dropped file before it hands it over, and drops the whole drop
    ...    when it cannot (the file was taken away while it was carried): the window never hears of it, so nothing is said
    ...    and nothing is changed. (The app's own message for a file that cannot be read is a case of the app's, fed the path
    ...    directly: `a_query_file_that_cannot_be_used_is_said_and_the_box_is_left_alone`.)
    [Tags]    p3
    Type In Query Box    .keep
    ${folder}=    Make Temp Directory
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${folder}${/}gone.jq
    Sleep    1.0s
    Query Box Should Hold    .keep
    Nothing Should Be Said In The Status Bar About The Load

TC-WSP-262 A Good Query File After One That Could Not Be Used Is Used And Takes The Message Away
    [Documentation]    The message about the first one is not a lock: the next file is read, its text is in the box, and the status
    ...    bar does not say any more that the first could not be read.
    [Tags]    p2
    ${folder}=    Make Temp Directory
    ${bytes}=    Evaluate    bytes([0xFF, 0xFE, 0x00, 0x80])
    Create Binary File    ${folder}${/}binary.jq    ${bytes}
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${folder}${/}binary.jq
    Wait Until Region Matches    @{STATUS_BAR}    could not be read    timeout=8
    ${good}=    A Query File    good.jq    .good
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${good}
    Query Box Should Hold    .good
    Engine Chip Should Be Selected    jq
    Wait Until Keyword Succeeds    6x    0.5s    Nothing Should Be Said In The Status Bar About The Load

TC-WSP-263 A Dropped Query File Is Not Run And Does Not Touch The Source, And Run Uses It
    [Documentation]    The document stays and the results stay until Run is pressed: then the query that was dropped is the one
    ...    that runs.
    [Tags]    p1
    Load Fixture Via Paste    [{"name": "Ana"}, {"name": "Bo"}]
    Source Should Show    2 items
    ${file}=    A Query File    names.jq    .[] | .name
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${file}
    Query Box Should Hold    .[] | .name
    Source Should Show    2 items
    Region Should Not Contain Text    @{RESULTS_PANEL}    Ana
    Click At    100    39
    Wait Until Region Matches    @{STATUS_BAR}    result\\(s\\)|Query ?ran ?in    timeout=8
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{RESULTS_PANEL}    Ana

TC-WSP-264 Several Files Go To Merge, Query Files Too, And The Query Box Is Left Alone
    [Documentation]    More than one file is not something to open: they are listed in the Merge page of the Tools window.
    [Tags]    p1    window-only
    Type In Query Box    .keep
    ${one}=    A Query File    one.jq    .one
    ${two}=    A Query File    two.jq    .two
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${one}    ${two}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{MERGE_LEFT_HEADER}    Files (2
    Switch To Main Window
    Query Box Should Hold    .keep

TC-WSP-265 A Query File Held Over The Window Outlines The Query Box And The Empty Source Says What It Would Be
    [Documentation]    While the file is carried and not yet let go: the box that it would go in has the link colour all round
    ...    its edge, and the Source, which would take a document, says that the file is not one.
    [Tags]    p1
    ${file}=    A Query File    held.jq    .held
    Query Box Should Not Be Outlined
    Region Should Not Contain Text    @{DROP_OVERLAY}    Drop to use
    Start Hovering Files    ${DROP_X}    ${DROP_Y}    ${file}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{DROP_OVERLAY}    Drop to use as the query
    Query Box Should Be Outlined
    Stop Hovering Files

TC-WSP-266 A Document Held Over The Window Says Drop To Open And Outlines Nothing
    [Documentation]    What is not a query is not for the box: the words are the ones that were always there.
    [Tags]    p1
    Start Hovering Files    ${DROP_X}    ${DROP_Y}    ${FIXTURES}/people.json
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{DROP_OVERLAY}    Drop to open
    Region Should Not Contain Text    @{DROP_OVERLAY}    query
    Query Box Should Not Be Outlined
    Stop Hovering Files

TC-WSP-267 The Outline And The Words Go When The File Is Taken Away
    [Tags]    p1
    ${file}=    A Query File    left.jq    .left
    Start Hovering Files    ${DROP_X}    ${DROP_Y}    ${file}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{DROP_OVERLAY}    Drop to use as the query
    Query Box Should Be Outlined
    Stop Hovering Files
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Not Contain Text    @{DROP_OVERLAY}    Drop to use
    Query Box Should Not Be Outlined
    Query Box Should Be Empty
    Source Should Still Be Empty

TC-WSP-268 Several Files Held Over The Window Are Not Outlined As A Query
    [Documentation]    Two files go to Merge whatever they are, so the query box is not what they would land on.
    [Tags]    p2
    ${one}=    A Query File    one.jq    .one
    ${two}=    A Query File    two.jq    .two
    Start Hovering Files    ${DROP_X}    ${DROP_Y}    ${one}    ${two}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{DROP_OVERLAY}    Drop to open
    Query Box Should Not Be Outlined
    Stop Hovering Files

TC-WSP-269 With A Document Loaded A Query File Held Over The Window Still Outlines The Box
    [Documentation]    The words are only for the empty Source (a document that is loaded has no overlay), but the box that the
    ...    query file would go in is outlined all the same.
    [Tags]    p2
    Load Fixture Via Paste    [{"name": "Ana"}]
    ${file}=    A Query File    held.jq    .held
    Start Hovering Files    ${DROP_X}    ${DROP_Y}    ${file}
    Wait Until Keyword Succeeds    6x    0.5s    Query Box Should Be Outlined
    Region Should Not Contain Text    @{DROP_OVERLAY}    Drop to
    Stop Hovering Files

TC-WSP-270 A File Let Go From The Workspace's Own Folder Is The Item The Box Came From
    [Documentation]    The Query row says where the box came from, as it does for a double click on the item, and marks it with a
    ...    dot once the text in the box is not the item's any more (the label is longer by the dot).
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App
    ${folder}=    Workspace Folder
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${folder}${/}Logs${/}logins.jmespath
    Query Box Should Hold    ${LOGINS_TEXT}
    Engine Chip Should Be Selected    jmespath
    Wait Until Region Matches    @{WS_QUERY_ROW}    Logs +/ +logins\\.jm    timeout=4
    Move Mouse To    600    300
    ${before}=    Origin Label Right Edge
    Type In Query Box    [?no]
    Move Mouse To    600    300
    ${after}=    Origin Label Right Edge
    Should Be True    ${after} - ${before} >= 6    msg=The label ends at ${before} unchanged and ${after} changed

TC-WSP-287 A Query File With Windows Line Ends Is Put In The Box As It Is And Runs
    [Documentation]    A query that was written on Windows has CR LF at the end of its lines: the box holds the two lines (the text
    ...    is the file's, with the line ends it has), and Run gives the answer of the query.
    [Tags]    p2
    Load Fixture Via Paste    [{"name": "Ana"}, {"name": "Bo"}]
    Source Should Show    2 items
    ${folder}=    Make Temp Directory
    ${bytes}=    Evaluate    b'.[]' + bytes([13, 10]) + b'| .name' + bytes([13, 10])
    Create Binary File    ${folder}${/}windows.jq    ${bytes}
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${folder}${/}windows.jq
    ${text}=    Evaluate    '.[]' + chr(13) + chr(10) + '| .name' + chr(13) + chr(10)
    Query Box Should Hold    ${text}
    Click At    100    39
    Wait Until Region Matches    @{STATUS_BAR}    result\\(s\\)|Query ?ran ?in    timeout=8
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{RESULTS_PANEL}    Ana

TC-WSP-288 A Name With Spaces, Brackets And Accents Is A Query All The Same
    [Documentation]    The name is carried in the file manager's own words (a URL: the spaces and the accents are escaped in it)
    ...    and the end of it is what says that it is a query.
    [Tags]    p2
    ${folder}=    Make Temp Directory
    Create File    ${folder}${/}my ünïcode query (1).jq    .name
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${folder}${/}my ünïcode query (1).jq
    Query Box Should Hold    .name
    Engine Chip Should Be Selected    jq

TC-WSP-289 A File From A Workspace That Is Reached Through A Link Is The Item All The Same
    [Documentation]    The toolkit hands the path of a dropped file over with its links resolved, which the folder that the workspace was
    ...    told to be is not: the file is still the item that the box came from, and the Query row says so.
    [Tags]    p2
    Close Jsonquery App
    ${parent}=    Make Temp Directory
    Create Directory    ${parent}${/}real
    Create File    ${parent}${/}real${/}mine.jq    .mine
    Evaluate    os.symlink($parent + '/real', $parent + '/link')    modules=os
    ${settings}=    Evaluate    json.dumps({"workspace": {"pane": "open", "folder": $parent + "/link"}})    modules=json
    Launch Jsonquery App    settings=${settings}
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Contain Text    @{WS_LIST}    mine
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${parent}${/}link${/}mine.jq
    Query Box Should Hold    .mine
    Wait Until Region Matches    @{WS_QUERY_ROW}    mine\\.j[qa]    timeout=4

TC-WSP-291 With A Document Loaded A Good Query File Takes The Message Away And The Document Stays
    [Documentation]    The message about a file that could not be used is in the status bar, after what it says of the document;
    ...    the next file that is used takes it away, and the document is still there.
    [Tags]    p2
    Load Fixture Via Paste    [{"name": "Ana"}, {"name": "Bo"}]
    Source Should Show    2 items
    ${folder}=    Make Temp Directory
    ${bytes}=    Evaluate    bytes([0xFF, 0xFE, 0x00, 0x80])
    Create Binary File    ${folder}${/}binary.jq    ${bytes}
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${folder}${/}binary.jq
    Wait Until Region Matches    @{STATUS_BAR}    could not be read    timeout=8
    Region Should Contain Text    @{STATUS_BAR}    Parsed
    ${good}=    A Query File    names.jq    .[] | .name
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${good}
    Query Box Should Hold    .[] | .name
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Not Contain Text    @{STATUS_BAR}    Load error
    Region Should Contain Text    @{STATUS_BAR}    Parsed
    Source Should Show    2 items

*** Keywords ***
A Query File
    [Documentation]    A file of this name that holds this text, in a folder of its own that is made for the case (it goes when the
    ...    display stops): what a file manager would show. Gives its path.
    [Arguments]    ${name}    ${text}
    ${folder}=    Make Temp Directory
    Create File    ${folder}${/}${name}    ${text}
    RETURN    ${folder}${/}${name}

A Query File Of Dots
    [Documentation]    A file of this name that is this many bytes of dots (a query that is only a line of dots: what is in it
    ...    does not matter, its size does). It is made without the text passing through the log.
    [Arguments]    ${name}    ${size}
    ${folder}=    Make Temp Directory
    ${path}=    Set Variable    ${folder}${/}${name}
    Evaluate    pathlib.Path($path).write_text('.' * int($size))    modules=pathlib
    RETURN    ${path}

Source Should Show
    [Documentation]    The Source reads `text` (retried; the tints of the tree are not flattened: "3 items" is dim, which that
    ...    would erase).
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    8x    0.5s    Region Should Contain Text    @{SOURCE_PANEL}    ${text}

Source Should Still Be Empty
    Region Should Contain Text    @{SOURCE_PANEL}    Paste JSON here

Nothing Should Be Said In The Status Bar About The Load
    Region Should Not Contain Text    @{STATUS_BAR}    Load error
    Region Should Not Contain Text    @{STATUS_BAR}    Parsed

Query Box Should Be Outlined
    [Documentation]    The query box has the outline of what would land on it, on its top and bottom edges and on its left.
    Region Should Contain Color    8    49    1184    5    ${OUTLINE_R}    ${OUTLINE_G}    ${OUTLINE_B}    tolerance=10
    ...    msg=No outline above the query box
    Region Should Contain Color    8    112    1184    5    ${OUTLINE_R}    ${OUTLINE_G}    ${OUTLINE_B}    tolerance=10
    ...    msg=No outline under the query box
    Region Should Contain Color    6    60    5    40    ${OUTLINE_R}    ${OUTLINE_G}    ${OUTLINE_B}    tolerance=10
    ...    msg=No outline at the left of the query box

Query Box Should Not Be Outlined
    Region Should Not Contain Color    8    49    1184    5    ${OUTLINE_R}    ${OUTLINE_G}    ${OUTLINE_B}    tolerance=10
    ...    msg=The query box is outlined above
    Region Should Not Contain Color    8    112    1184    5    ${OUTLINE_R}    ${OUTLINE_G}    ${OUTLINE_B}    tolerance=10
    ...    msg=The query box is outlined under
    Region Should Not Contain Color    6    60    5    40    ${OUTLINE_R}    ${OUTLINE_G}    ${OUTLINE_B}    tolerance=10
    ...    msg=The query box is outlined at the left
