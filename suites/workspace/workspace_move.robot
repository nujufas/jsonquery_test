*** Settings ***
Documentation     Moving what is in the workspace: a row dragged with the mouse onto a folder (or an item, or the
...               empty part of the list), what is lit and said while it is carried, what is not done, and the
...               Move to of the menu of a row -- see docs/25_workspace.md. The mouse is the real one (the left
...               button pressed on a row, the pointer taken to the place over half a second, the button let
...               go), and the cases read the folder afterwards: where the files are, and that the item is the
...               same one (its id and SHA-256 in the hidden index) and brought its sample along.
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace    move
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Release And Close

*** Variables ***
# Where the label of what is carried is, beside the pointer: to the right of it and a little below.
${GHOST_WIDTH}            340
${GHOST_HEIGHT}           60

*** Test Cases ***
TC-WSP-100 A Row Dragged Onto A Folder Goes Into It And Is The Same Item Afterwards
    [Documentation]    The file is in the folder and not where it was, its id and its SHA-256 are what they were, the
    ...    item is picked in its new place, and the app says what was done.
    [Tags]    p1
    ${before}=    Workspace Item    scratch.jq
    Drag Row    ${ROW_SCRATCH}    ${ROW_LOGS}
    Workspace File Should Be    Logs/scratch.jq    ${SCRATCH_TEXT}
    Workspace File Should Not Exist    scratch.jq
    ${after}=    Workspace Item    Logs/scratch.jq
    Should Be Equal    ${after}[id]    ${before}[id]
    Should Be Equal    ${after}[sha256]    ${before}[sha256]
    ${index}=    Workspace Index
    Dictionary Should Not Contain Key    ${index}[items]    scratch.jq
    # Rows now: Logs, Errors, logins, scratch, Services, orders, update.
    List Should Show    scratch    logins    Services
    Row Should Be Selected    3
    Notice Should Say    Moved .{0,2}scratch.{0,2} into .{0,2}Logs

TC-WSP-101 While A Row Is Carried The Folder It Would Go Into Is Lit And The Label Says Where
    [Tags]    p1
    Nothing Should Be Lit
    Pick Up Row    ${ROW_SCRATCH}    ${ROW_SERVICES}
    Row Should Be Lit    ${ROW_SERVICES}
    Row Should Not Be Lit    ${ROW_LOGS}
    ${y}=    Row Y    ${ROW_SERVICES}
    ${top}=    Evaluate    ${y} - 6
    Wait Until Region Matches    ${WS_ROW_X}    ${top}    ${GHOST_WIDTH}    ${GHOST_HEIGHT}    Move .{0,2}scratch.{0,2} into .{0,2}Services    timeout=5
    # Nothing has been moved yet.
    Workspace File Should Exist    scratch.jq
    Mouse Up
    Sleep    0.6s
    Move Mouse To    600    400
    Nothing Should Be Lit
    Region Should Not Contain Text    ${WS_ROW_X}    ${top}    ${GHOST_WIDTH}    ${GHOST_HEIGHT}    Move
    Workspace File Should Exist    Services/scratch.jq

TC-WSP-102 A Row Takes Its Sample With It
    [Tags]    p1
    Click Row    ${ROW_ERRORS}
    # Rows: Logs, Errors, failures, logins, Services, orders, update, scratch.
    ${sample}=    Workspace Item    Logs/Errors/failures.jq
    Drag Row    2    4
    Workspace File Should Be    Services/failures.jq    ${FAILURES_TEXT}
    Workspace File Should Be    Services/failures.sample.json    ${FAILURES_SAMPLE}
    Workspace File Should Not Exist    Logs/Errors/failures.jq
    Workspace File Should Not Exist    Logs/Errors/failures.sample.json
    ${moved}=    Workspace Item    Services/failures.jq
    Should Be Equal    ${moved}[sample][sha256]    ${sample}[sample][sha256]

TC-WSP-103 A Folder Dragged Onto A Folder Takes Everything In It With The Ids Unchanged
    [Tags]    p1
    ${before}=    Workspace Item    Logs/Errors/failures.jq
    Drag Row    ${ROW_ERRORS}    ${ROW_SERVICES}
    Workspace File Should Be    Services/Errors/failures.jq    ${FAILURES_TEXT}
    Workspace File Should Be    Services/Errors/failures.sample.json    ${FAILURES_SAMPLE}
    Workspace File Should Not Exist    Logs/Errors
    Workspace File Should Exist    Logs/logins.jmespath
    ${after}=    Workspace Item    Services/Errors/failures.jq
    Should Be Equal    ${after}[id]    ${before}[id]
    Details Should Show    Errors

TC-WSP-104 A Row Put Down On An Item Goes Into The Folder That Item Is In
    [Tags]    p1
    Drag Row    ${ROW_SCRATCH}    ${ROW_UPDATE}
    Workspace File Should Be    Services/scratch.jq    ${SCRATCH_TEXT}
    Workspace File Should Not Exist    scratch.jq

TC-WSP-105 A Row Put Down On The Empty Part Of The List Goes To The Top
    [Tags]    p1
    Drag Row To    ${ROW_LOGINS}    ${WS_ROW_X}    ${WS_EMPTY_Y}
    Workspace File Should Be    logins.jmespath    ${LOGINS_TEXT}
    Workspace File Should Not Exist    Logs/logins.jmespath
    Notice Should Say    Moved .{0,2}logins.{0,2} to the top

TC-WSP-106 The Empty Part Of The List Is Lit As The Place Where A Row Would Go To The Top
    [Tags]    p2
    ${y}=    Row Y    ${ROW_LOGINS}
    Mouse Down At    ${WS_ROW_X}    ${y}
    Move Mouse Slowly To    ${WS_ROW_X}    ${WS_EMPTY_Y}    duration=0.6
    Region Should Contain Color    6    300    8    100    192    222    255    tolerance=10    msg=The list is not outlined
    # And the label says so.
    ${top}=    Evaluate    ${WS_EMPTY_Y} - 6
    Wait Until Region Matches    ${WS_ROW_X}    ${top}    ${GHOST_WIDTH}    ${GHOST_HEIGHT}    Move .{0,2}logins.{0,2} to the top    timeout=5
    Mouse Up
    Sleep    0.6s

TC-WSP-107 A Row Put Down On The Folder It Is In Stays Where It Is
    [Tags]    p1
    ${index}=    Workspace Index
    Drag Row    ${ROW_LOGINS}    ${ROW_LOGS}
    Workspace File Should Exist    Logs/logins.jmespath
    Workspace Files Should Not Have Changed    ${index}
    Details Should Not Show    Moved

TC-WSP-108 A Row That Is Not Over Anything It Can Go Into Is Not Lit
    [Tags]    p2
    Pick Up Row    ${ROW_LOGINS}    ${ROW_LOGS}
    Row Should Not Be Lit    ${ROW_LOGS}
    Nothing Should Be Lit
    Mouse Up
    Sleep    0.5s

TC-WSP-109 A Folder Is Not Put Into A Folder In It
    [Tags]    p1
    Pick Up Row    ${ROW_LOGS}    ${ROW_ERRORS}
    Row Should Not Be Lit    ${ROW_ERRORS}
    Nothing Should Be Lit
    Mouse Up
    Sleep    0.6s
    Move Mouse To    600    400
    Workspace File Should Exist    Logs/Errors/failures.jq
    Workspace File Should Exist    Logs/logins.jmespath
    Workspace File Should Not Exist    Logs/Errors/Logs
    Details Should Not Show    into itself
    Details Should Not Show    Moved

TC-WSP-110 A Name That Is Taken In The Folder Is Said And Nothing Moves
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${TAKEN}
    # Rows: Logs, Errors, logins, scratch, Services, orders, update, scratch.
    Drag Row    7    ${ROW_LOGS}
    Workspace File Should Be    scratch.jq    ${SCRATCH_TEXT}
    Workspace File Should Be    Logs/scratch.jq    .other
    Notice Should Say    already a query called

TC-WSP-111 A Folder Of The Same Name In The Folder Is Said And Nothing Moves
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${TAKEN_FOLDER}
    # Rows: Logs, Errors, logins, Services, Errors, orders, update, scratch.
    Drag Row    ${ROW_ERRORS}    ${ROW_SERVICES}
    Workspace File Should Exist    Logs/Errors/failures.jq
    Workspace File Should Exist    Services/Errors/x.jq
    Notice Should Say    already a folder called

TC-WSP-112 Escape Puts The Row Back
    [Tags]    p1
    Pick Up Row    ${ROW_SCRATCH}    ${ROW_SERVICES}
    Row Should Be Lit    ${ROW_SERVICES}
    Press Key    escape
    Sleep    0.4s
    Mouse Up
    Sleep    0.6s
    Move Mouse To    600    400
    Workspace File Should Exist    scratch.jq
    Workspace File Should Not Exist    Services/scratch.jq
    Nothing Should Be Lit

TC-WSP-113 A Row Let Go Outside The List Stays Where It Is
    [Documentation]    An item that is in a folder is not taken out of it to the top (as it would be on the empty part of
    ...    the list), and one that is at the top is not put anywhere: let go over the Results. (Over the query box a query is
    ...    opened, which is another case: TC-WSP-271.)
    [Tags]    p1
    Drag Row To    ${ROW_LOGINS}    ${WS_RESULTS_X}    ${WS_RESULTS_Y}
    Workspace File Should Exist    Logs/logins.jmespath
    Workspace File Should Not Exist    logins.jmespath
    Drag Row To    ${ROW_SCRATCH}    ${WS_RESULTS_X}    ${WS_RESULTS_Y}
    Workspace File Should Exist    scratch.jq
    Query Box Should Be Empty
    Nothing Should Be Lit

TC-WSP-114 A Press That Moves A Little Is A Click And Carries Nothing
    [Tags]    p2
    ${y}=    Row Y    ${ROW_LOGS}
    Click With Wobble    ${WS_ROW_X}    ${y}    3    2
    Move Mouse To    600    400
    Row Should Be Selected    ${ROW_LOGS}
    List Should Not Show    logins
    Workspace File Should Exist    Logs/logins.jmespath

TC-WSP-115 A Shut Folder That A Row Rests On Opens After A Moment
    [Documentation]    Errors is shut: the row that is carried over it for a while opens it, so that what is in it can be
    ...    the place the row is put down. (The pointer is then taken to the empty part of the list, where the label of
    ...    the row does not hide the rows.)
    [Tags]    p2
    Pick Up Row    ${ROW_SCRATCH}    ${ROW_ERRORS}
    Sleep    1.6s
    Move Mouse Slowly To    ${WS_ROW_X}    ${WS_EMPTY_Y}    duration=0.4
    List Should Show    failures
    Press Key    escape
    Sleep    0.4s
    Mouse Up
    Sleep    0.5s
    Workspace File Should Exist    scratch.jq

TC-WSP-116 A Shut Folder That A Row Only Passes Over Does Not Open
    [Tags]    p2
    Pick Up Row    ${ROW_SCRATCH}    ${ROW_ERRORS}
    Move Mouse Slowly To    ${WS_ROW_X}    ${WS_EMPTY_Y}    duration=0.3
    Sleep    1.6s
    List Should Not Show    failures
    Press Key    escape
    Mouse Up
    Sleep    0.5s
    Workspace File Should Exist    scratch.jq

TC-WSP-127 A Folder Is Not Put Into Itself
    [Documentation]    A folder that is carried over its own row is not lit, the label does not say it would go
    ...    there, and letting go does nothing (and says nothing).
    [Tags]    p1
    ${y}=    Row Y    ${ROW_LOGS}
    Mouse Down At    60    ${y}
    Move Mouse Slowly To    ${WS_ROW_X}    ${y}    duration=0.6
    Row Should Not Be Lit    ${ROW_LOGS}
    Nothing Should Be Lit
    ${top}=    Evaluate    ${y} - 6
    Region Should Not Contain Text    ${WS_ROW_X}    ${top}    ${GHOST_WIDTH}    ${GHOST_HEIGHT}    Move
    Mouse Up
    Sleep    0.6s
    Move Mouse To    600    400
    Workspace File Should Exist    Logs/logins.jmespath
    Workspace File Should Not Exist    Logs/Logs
    Details Should Not Show    into itself
    Details Should Not Show    Moved

TC-WSP-128 The Label Says The Way To A Folder That Is In Another
    [Documentation]    The name of a folder in a folder has the folder it is in before it, with a slash between.
    [Tags]    p2
    Pick Up Row    ${ROW_SCRATCH}    ${ROW_ERRORS}
    ${y}=    Row Y    ${ROW_ERRORS}
    ${top}=    Evaluate    ${y} - 6
    Wait Until Region Matches    ${WS_ROW_X}    ${top}    ${GHOST_WIDTH}    ${GHOST_HEIGHT}    Move .{0,2}scratch.{0,2} into .{0,2}Logs +[/|Il1] +Errors    timeout=5
    Mouse Up
    Sleep    0.6s
    Move Mouse To    600    400
    Workspace File Should Exist    Logs/Errors/scratch.jq

TC-WSP-129 A Row Held Below The List Does Not Scroll It
    [Documentation]    The list scrolls while a row is held near its top or its foot, and not while the row is held
    ...    outside it (here over what is said under the list).
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${MANY}
    ${y}=    Row Y    ${ROW_LOGS}
    Mouse Down At    ${WS_ROW_X}    ${y}
    Move Mouse Slowly To    ${WS_ROW_X}    ${WS_BELOW_LIST_Y}    duration=0.6
    Sleep    3.0s
    # (The row that is carried is dimmed where it was: the others are what is read.)
    Region Should Show Text    @{WS_LIST}    Services
    Region Should Show Text    @{WS_LIST}    orders
    Region Should Not Show Text    @{WS_LIST}    scratch
    Press Key    escape
    Sleep    0.3s
    Mouse Up
    Sleep    0.5s
    Workspace File Should Exist    Logs/logins.jmespath

TC-WSP-117 The List Scrolls While A Row Is Held Near Its Foot
    [Documentation]    A long list has rows out of view: a row that is carried to the foot of the list brings them
    ...    into view, and Escape puts it back.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${MANY}
    Region Should Not Show Text    @{WS_LIST}    scratch
    ${y}=    Row Y    ${ROW_LOGS}
    Mouse Down At    ${WS_ROW_X}    ${y}
    Move Mouse Slowly To    ${WS_ROW_X}    ${WS_LIST_FOOT_Y}    duration=0.6
    Sleep    4.0s
    Region Should Show Text    @{WS_LIST}    scratch
    Region Should Not Show Text    @{WS_LIST}    Services
    Press Key    escape
    Sleep    0.3s
    Mouse Up
    Sleep    0.5s
    Workspace File Should Exist    Logs/logins.jmespath
    Workspace File Should Exist    scratch.jq

TC-WSP-118 An Item That Was Opened Is Still Said To Be Where The Box Came From After It Is Moved
    [Tags]    p2
    Double Click Row    ${ROW_SCRATCH}
    Query Box Should Hold    ${SCRATCH_TEXT}
    Drag Row    ${ROW_SCRATCH}    ${ROW_LOGS}
    Wait Until Region Matches    @{WS_QUERY_ROW}    Logs +/ +scratch    timeout=5

TC-WSP-119 A Folder That Is Open Is Open Where It Is Put Down
    [Tags]    p2
    Click Row    ${ROW_ERRORS}
    List Should Show    failures
    Drag Row    ${ROW_LOGS}    4
    Workspace File Should Exist    Services/Logs/Errors/failures.jq
    List Should Show    Services    Logs    Errors    failures    logins

TC-WSP-120 The Menu's Move To Lists The Top And The Folders
    [Tags]    p1
    Open Move To Menu    ${ROW_SCRATCH}
    ${y}=    Row Y    ${ROW_SCRATCH}
    ${top}=    Evaluate    max(${y} - 20, 0)
    FOR    ${name}    IN    top    Logs    Errors    Services
        Region Should Contain Text    ${SUBMENU_X}    ${top}    ${SUBMENU_WIDTH}    330    ${name}
    END
    Press Key    escape

TC-WSP-121 Move To In The Menu Moves The Item Into The Folder
    [Tags]    p1
    ${before}=    Workspace Item    scratch.jq
    Move Row Through Menu    ${ROW_SCRATCH}    Services
    Workspace File Should Be    Services/scratch.jq    ${SCRATCH_TEXT}
    Workspace File Should Not Exist    scratch.jq
    ${after}=    Workspace Item    Services/scratch.jq
    Should Be Equal    ${after}[id]    ${before}[id]

TC-WSP-122 Move To The Top In The Menu Takes An Item Out Of Its Folder
    [Tags]    p2
    Move Row Through Menu    ${ROW_LOGINS}    top
    Workspace File Should Be    logins.jmespath    ${LOGINS_TEXT}
    Workspace File Should Not Exist    Logs/logins.jmespath

TC-WSP-123 Move To In The Menu Of A Folder Moves The Folder
    [Tags]    p2
    Move Row Through Menu    ${ROW_ERRORS}    Services
    Workspace File Should Be    Services/Errors/failures.jq    ${FAILURES_TEXT}
    Workspace File Should Not Exist    Logs/Errors

TC-WSP-124 The Folder An Item Is In Cannot Be Chosen In Its Move To
    [Tags]    p3
    ${index}=    Workspace Index
    Move Row Through Menu    ${ROW_SCRATCH}    top
    Workspace File Should Exist    scratch.jq
    Workspace Files Should Not Have Changed    ${index}
    Details Should Not Show    Moved

TC-WSP-125 A Folder Cannot Be Moved Into Itself In The Menu
    [Tags]    p3
    ${index}=    Workspace Index
    Move Row Through Menu    ${ROW_LOGS}    Errors
    Workspace File Should Exist    Logs/Errors/failures.jq
    Workspace Files Should Not Have Changed    ${index}
    Details Should Not Show    into itself
    Details Should Not Show    Moved

TC-WSP-126 A Row Put Down On A Shut Folder Goes In And The Folder Opens To Show It
    [Tags]    p1
    List Should Not Show    failures
    Drag Row    ${ROW_SCRATCH}    ${ROW_ERRORS}
    Workspace File Should Be    Logs/Errors/scratch.jq    ${SCRATCH_TEXT}
    Workspace File Should Not Exist    scratch.jq
    List Should Show    failures    scratch

*** Keywords ***
Open Move To Menu
    [Documentation]    The menu of the row, and its Move to, which opens the list of the places at its right.
    [Arguments]    ${row}
    Right Click Row    ${row}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    max(int(${y}) - 20, 0)
    Click Text In Region    ${WS_ROW_X}    ${top}    200    330    Move to
    Sleep    0.7s

Move Row Through Menu
    [Arguments]    ${row}    ${target}
    Open Move To Menu    ${row}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    max(int(${y}) - 20, 0)
    Click Text In Region    ${SUBMENU_X}    ${top}    ${SUBMENU_WIDTH}    330    ${target}
    Sleep    0.8s
    Move Mouse To    600    400
