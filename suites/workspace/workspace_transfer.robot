*** Settings ***
Documentation     The windows of the pane that make a folder, export the workspace, import one, and the menu's
...               other items: another folder as the workspace, showing it in the file manager, reading it again
...               -- see docs/25_workspace.md. An export or an import is a copy of files: the cases read both
...               folders afterwards, and that the ids and SHA-256s that the workspace keeps travel with the items.
...               (The Export window offers a folder in the home of whoever runs the cases: no case presses
...               Export before it has typed a folder of its own.)
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace    transfer
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Close Jsonquery App

*** Test Cases ***
TC-WSP-130 The Folder Button Opens The Window That Makes A Folder
    [Documentation]    A Name box with the focus, the folder it goes inside (the top), and Make it, which is dim until
    ...    there is a name.
    [Tags]    p1
    Open New Folder Form
    Form Should Show    Name    Inside
    Press Key    enter
    Sleep    0.5s
    Form Should Be Open    Inside
    Workspace Folders Should Be    Logs    Logs/Errors    Services

TC-WSP-131 A Folder Is Made By Typing Its Name And Enter And It Is Open And Picked
    [Tags]    p1
    Open New Folder Form
    Type Text    Fresh
    Press Key    enter
    Sleep    0.8s
    Form Should Not Be Open    Inside
    ${fresh}=    Workspace Folder    Fresh
    Directory Should Exist    ${fresh}
    Workspace Folders Should Be    Fresh    Logs    Logs/Errors    Services
    List Should Show    Fresh
    # Rows: Fresh, Logs, ... the new folder is the first and is the one that is picked.
    Row Should Be Selected    0
    Workspace File Should Not Exist    Fresh/anything

TC-WSP-132 The Make It Button Makes The Folder
    [Tags]    p2
    Open New Folder Form
    Type Text    Clicked
    Click In Form    ${NEWFOLDER_MAKE_X}    ${NEWFOLDER_BUTTONS_Y}
    Sleep    0.8s
    Workspace Folders Should Be    Clicked    Logs    Logs/Errors    Services

TC-WSP-133 A Folder Is Made Inside The Folder That Is Picked
    [Tags]    p1
    Click Row    ${ROW_SERVICES}
    Open New Folder Form
    Type Text    Billing
    Press Key    enter
    Sleep    0.8s
    Workspace Folders Should Be    Logs    Logs/Errors    Services    Services/Billing
    List Should Show    Billing

TC-WSP-134 The Menu Of The Three Dots Makes A Folder Too
    [Tags]    p2
    Set Form Kind    newfolder
    Open Pane Form    New folder    Inside
    Type Text    FromMenu
    Press Key    enter
    Sleep    0.8s
    Workspace Folders Should Be    FromMenu    Logs    Logs/Errors    Services

TC-WSP-135 The Menu Of A Folder Makes A Folder Inside It
    [Tags]    p2
    Right Click Row    ${ROW_LOGS}
    ${y}=    Row Y    ${ROW_LOGS}
    ${top}=    Evaluate    max(${y} - 20, 0)
    Click Text In Region    ${WS_ROW_X}    ${top}    200    330    New folder
    Sleep    0.7s
    Set Form Kind    newfolder
    Form Should Be Open    Inside
    Type Text    Archive
    Press Key    enter
    Sleep    0.8s
    Workspace Folders Should Be    Logs    Logs/Archive    Logs/Errors    Services

TC-WSP-136 A Folder Is Made Inside A Folder That Is Chosen In The Window
    [Tags]    p2
    Open New Folder Form
    Type Text    Chosen
    Click In Form    470    188
    ${y}=    Form Y    200
    Click Text In Region    430    ${y}    260    170    Services
    Sleep    0.5s
    Click In Form    ${NEWFOLDER_MAKE_X}    ${NEWFOLDER_BUTTONS_Y}
    Sleep    0.8s
    Workspace Folders Should Be    Logs    Logs/Errors    Services    Services/Chosen

TC-WSP-137 A Name That A Folder Cannot Have Is Said And No Folder Is Made
    [Tags]    p1
    Open New Folder Form
    Type Text    a:b
    Form Should Show    have any of
    Press Key    enter
    Sleep    0.5s
    Form Should Show    have any of
    Workspace Folders Should Be    Logs    Logs/Errors    Services

TC-WSP-138 A Folder That Is There Already Is Said And Nothing Is Made
    [Tags]    p2
    Open New Folder Form
    Type Text    services
    Press Key    enter
    Sleep    0.6s
    Form Should Be Open    Inside
    Form Should Match    already a folder called
    Workspace Folders Should Be    Logs    Logs/Errors    Services

TC-WSP-139 Escape And Cancel Make Nothing
    [Tags]    p2
    Open New Folder Form
    Type Text    Nothing
    Press Key    escape
    Sleep    0.5s
    Form Should Not Be Open    Inside
    Open New Folder Form
    Click In Form    ${NEWFOLDER_CANCEL_X}    ${NEWFOLDER_BUTTONS_Y}
    Sleep    0.5s
    Form Should Not Be Open    Inside
    Workspace Folders Should Be    Logs    Logs/Errors    Services

TC-WSP-140 The Export Window Says What Is Exported And Where To
    [Tags]    p1
    Open Export Form
    Form Should Show    Everything    To the folder    include the samples
    Form Should Have Buttons    Export    Cancel
    Form Should Match    5 items in 3 folders
    Form Should Match    2 files
    # The folder offered is a new one in the home, named for the day.
    Form Should Match    jsonquery-workspace-20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]

TC-WSP-141 Export Makes A Copy Of The Workspace With The Ids It Kept
    [Documentation]    Every item and every sample is in the new folder, as it is here, and so is the index that
    ...    holds each item's id and SHA-256: an item that is imported again is the item that was exported.
    [Tags]    p1
    ${out}=    Make Export Folder
    Open Export Form
    Export To    ${out}
    Form Should Not Be Open    To the folder
    ${files}=    Files In Folder    ${out}
    Lists Should Be Equal    ${files}    ${STANDARD_FILES}
    ${mine}=    Workspace Index
    ${theirs}=    Index Of Folder    ${out}
    Compare Indexes    ${mine}    ${theirs}
    File Should Exist    ${out}${/}scratch.jq
    ${text}=    Get File    ${out}${/}Logs${/}Errors${/}failures.jq
    Should Be Equal    ${text}    ${FAILURES_TEXT}
    # (not just the word: the folder that was made is called exported, and the message ends with where it is)
    Notice Should Say    Exported +[^ ]{1,3} +ite

TC-WSP-142 Without The Samples Only The Items Are Copied
    [Tags]    p1
    ${out}=    Make Export Folder
    Open Export Form
    # The tick is under the folder box.
    Click In Form    380    192
    Export To    ${out}
    ${files}=    Files In Folder    ${out}
    Should Not Contain    ${files}    Logs/Errors/failures.sample.json
    Should Not Contain    ${files}    Services/orders.sample.json
    Should Contain    ${files}    Logs/Errors/failures.jq
    Should Contain    ${files}    Services/orders.schema.json
    Should Contain    ${files}    scratch.jq

TC-WSP-143 A Folder Is Exported Alone
    [Documentation]    With a folder picked, the window offers the whole workspace or only that folder.
    [Tags]    p1
    Click Row    ${ROW_SERVICES}
    ${out}=    Make Export Folder
    Open Export Form
    Form Should Show    What    everything    only the folder
    Press In Form    only
    Sleep    0.4s
    Export To    ${out}    214
    ${files}=    Files In Folder    ${out}
    # What is in the folder is what is in the copy: the folder itself is not.
    Should Contain    ${files}    orders.schema.json
    Should Contain    ${files}    orders.sample.json
    Should Contain    ${files}    update.patch.json
    Should Not Contain    ${files}    scratch.jq
    Should Not Contain    ${files}    logins.jmespath

TC-WSP-144 The Menu Of A Folder Exports That Folder
    [Tags]    p2
    Right Click Row    ${ROW_LOGS}
    ${y}=    Row Y    ${ROW_LOGS}
    ${top}=    Evaluate    max(${y} - 20, 0)
    Click Text In Region    ${WS_ROW_X}    ${top}    200    330    Export this
    Sleep    0.8s
    Set Form Kind    export
    Form Should Be Open    To the folder
    Form Should Show    only the folder
    ${out}=    Make Export Folder
    Press In Form    only
    Sleep    0.4s
    Export To    ${out}    214
    ${files}=    Files In Folder    ${out}
    Should Contain    ${files}    logins.jmespath
    Should Contain    ${files}    Errors/failures.jq
    Should Not Contain    ${files}    scratch.jq

TC-WSP-145 A Folder That Has Something In It Is Not Exported To
    [Tags]    p1
    ${full}=    Make Folder With Files    full    ${{ {"keep.txt": "mine"} }}
    Open Export Form
    Export To    ${full}
    Form Should Be Open    To the folder
    Form Should Match    not empty
    ${files}=    Files In Folder    ${full}
    Lists Should Be Equal    ${files}    ${{ ["keep.txt"] }}

TC-WSP-146 The Workspace Is Not Exported Into Itself
    [Tags]    p1
    ${inside}=    Workspace Folder    Services
    Open Export Form
    Export To    ${inside}
    Form Should Be Open    To the folder
    Form Should Match    Choose a folder
    Workspace File Should Not Exist    Services/scratch.jq

TC-WSP-147 Cancel Exports Nothing
    [Tags]    p3
    ${out}=    Make Export Folder
    Open Export Form
    Type In Export Folder    ${out}
    Press Cancel Button
    Sleep    0.5s
    Form Should Not Be Open    To the folder
    Directory Should Not Exist    ${out}

TC-WSP-150 The Import Window Asks For A Folder And Where To Put What Is In It
    [Tags]    p1
    Open Import Form
    Form Should Show    From the folder    Put them    new folder    among what is in
    Form Should Show    keep both    replace the one    leave the new one out
    # The buttons, in a strip of their own (a button is read badly among the lines of the window).
    ${y}=    Form Y    305
    Wait Until Keyword Succeeds    4x    0.4s    Region Should Contain Text    380    ${y}    140    24    Cancel    psm=7

TC-WSP-151 A Folder That Is Typed Is Looked At When The Box Is Left
    [Documentation]    What it holds is said under the box: how many items and folders, of what sorts, how many have a
    ...    sample; and the new folder that they go in is named for the folder.
    [Tags]    p1
    ${incoming}=    Make Folder With Files    incoming    ${INCOMING}
    Open Import Form
    Type In Import Folder    ${incoming}
    Form Should Match    2 items in 1 folder
    Form Should Match    1 query, 1 schema
    Form Should Show    incoming

TC-WSP-152 Import Brings The Items In A New Folder Named For The Folder They Came In
    [Tags]    p1
    ${incoming}=    Make Folder With Files    incoming    ${INCOMING}
    Open Import Form
    Type In Import Folder    ${incoming}
    Press Primary Button
    Sleep    1.2s
    Form Should Not Be Open    From the folder
    Workspace File Should Be    incoming/Reports/daily.jq    .daily
    Workspace File Should Be    incoming/Reports/daily.sample.json    {"d": 1}
    Workspace File Should Be    incoming/checks.schema.json    {"type": "object"}
    Workspace File Should Not Exist    incoming/notes.txt
    # (Reports is a folder in the new folder: shut)
    List Should Show    incoming    Reports    checks
    Notice Should Say    Imported
    ${item}=    Workspace Item    incoming/Reports/daily.jq
    Should Match Regexp    ${item}[id]    ^[0-9a-f-]{36}$

TC-WSP-153 The Ids That Were Kept In The Folder Are The Ids Of The Items After The Import
    [Documentation]    A folder that was exported has its index: the items come in with the ids they had there, and the
    ...    SHA-256 of what they hold.
    [Tags]    p1
    ${incoming}=    Make Folder With Files    exported    ${INCOMING_WITH_IDS}
    Open Import Form
    Type In Import Folder    ${incoming}
    Press Primary Button
    Sleep    1.2s
    ${daily}=    Workspace Item    exported/Reports/daily.jq
    ${checks}=    Workspace Item    exported/checks.schema.json
    Should Be Equal    ${daily}[id]    ${DAILY_ID}
    Should Be Equal    ${checks}[id]    ${CHECKS_ID}
    ${sha}=    Sha256 Of Text    .daily
    Should Be Equal    ${daily}[sha256]    ${sha}

TC-WSP-154 The Name Of The New Folder Can Be Typed
    [Tags]    p2
    ${incoming}=    Make Folder With Files    incoming    ${INCOMING}
    Open Import Form
    Type In Import Folder    ${incoming}
    Click Import Name Field
    Press Keys    ctrl    a
    Type Text    mine
    Press Primary Button
    Sleep    1.2s
    Workspace File Should Be    mine/Reports/daily.jq    .daily
    Workspace File Should Not Exist    incoming

TC-WSP-155 A Folder That Is Not One Is Said In Red And Nothing Is Imported
    [Tags]    p1
    Open Import Form
    Type In Import Folder    /tmp/jq-nowhere-x7
    Form Should Match    not a folder
    Press Primary Button
    Sleep    0.6s
    Form Should Be Open    From the folder
    Workspace Files Should Be    ${STANDARD_FILES}

TC-WSP-156 A Folder With Nothing In It That The Workspace Can Use Is Said
    [Tags]    p2
    ${nothing}=    Make Folder With Files    useless    ${NOTHING_USEFUL}
    Open Import Form
    Type In Import Folder    ${nothing}
    Form Should Match    items in [09O©] ?[Ff]olders
    Press Primary Button
    Sleep    0.6s
    Form Should Match    nothing in that folder
    Workspace Files Should Be    ${STANDARD_FILES}

TC-WSP-157 Import Among What Is In A Folder Keeps Both When A Name Is Taken
    [Documentation]    Into Services, which has the schema orders: the one that comes in with that name and other text
    ...    gets a number, and the one that was there is as it was.
    [Tags]    p1
    ${incoming}=    Make Folder With Files    incoming    ${CLASHING}
    Right Click Row    ${ROW_SERVICES}
    ${y}=    Row Y    ${ROW_SERVICES}
    ${top}=    Evaluate    max(${y} - 20, 0)
    Click Text In Region    ${WS_ROW_X}    ${top}    200    330    Import into
    Sleep    0.8s
    Set Form Kind    import
    Form Should Be Open    From the folder
    Type In Import Folder    ${incoming}
    # (keep both is the choice that is made until another is)
    Press In Form    among
    Press Primary Button
    Sleep    1.2s
    Workspace File Should Be    Services/orders.schema.json    ${SCHEMA_TEXT}
    Workspace File Should Be    Services/orders (2).schema.json    {"type": "string"}
    Workspace File Should Be    Services/scratch.jq    .different
    Workspace File Should Be    scratch.jq    ${SCRATCH_TEXT}

TC-WSP-158 Import With Replace Puts The New Text Over The Old
    [Tags]    p1
    ${incoming}=    Make Folder With Files    incoming    ${{ {"scratch.jq": ".different"} }}
    ${before}=    Workspace Item    scratch.jq
    Open Import Form
    Type In Import Folder    ${incoming}
    Press In Form    among
    Press In Form    replace
    Press Primary Button
    Sleep    1.2s
    Workspace File Should Be    scratch.jq    .different
    Workspace File Should Not Exist    scratch (2).jq

TC-WSP-159 Import With Leave Out Keeps What Is There
    [Tags]    p2
    ${incoming}=    Make Folder With Files    incoming    ${{ {"scratch.jq": ".different"} }}
    Open Import Form
    Type In Import Folder    ${incoming}
    Press In Form    among
    Press In Form    leave
    Press Primary Button
    Sleep    1.2s
    Workspace File Should Be    scratch.jq    ${SCRATCH_TEXT}
    Workspace File Should Not Exist    scratch (2).jq

TC-WSP-160 An Item That Is The Same As The One There Is Not Brought In Again
    [Tags]    p2
    ${incoming}=    Make Folder With Files    incoming    ${{ {"scratch.jq": "."} }}
    Open Import Form
    Type In Import Folder    ${incoming}
    Press In Form    among
    Press Primary Button
    Sleep    1.2s
    Workspace Files Should Be    ${STANDARD_FILES}
    Notice Should Say    already

TC-WSP-161 Choose Folder Fills In The Folder From The File Dialog
    [Tags]    p2
    ${incoming}=    Make Folder With Files    incoming    ${INCOMING}
    Open Import Form
    Portal Will Pick    ${incoming}
    Click In Form    ${IMPORT_CHOOSE_X}    ${IMPORT_CHOOSE_Y}
    Wait Until Portal Is Asked
    Form Should Match    2 items in 1 folder
    ${requests}=    Get Portal Requests
    Should Be True    ${requests}[0][directory]    msg=The dialog asked for a folder: ${requests}[0]

TC-WSP-162 Another Folder Can Be The Workspace
    [Documentation]    Its own folder, chosen in the file dialog: the pane shows what is in it, the settings keep it,
    ...    and what is saved goes there.
    [Tags]    p1
    ${other}=    Make Folder With Files    elsewhere    ${{ {"Mine/first.jq": ".one", "second.jmespath": "two"} }}
    Portal Will Pick    ${other}
    Click Header Button    menu
    Click Text In Region    @{WS_MENU_AREA}    Open another
    Wait Until Portal Is Asked
    Sleep    1.0s
    List Should Show    Mine    first    second
    List Should Not Show    Logs    scratch
    Quit And Start Again
    List Should Show    Mine    second
    Settings Value Should Be    workspace.folder    ${other}

TC-WSP-163 What Is Saved Goes To The Folder That Was Chosen
    [Tags]    p2
    ${other}=    Make Folder With Files    elsewhere    ${{ {"second.jmespath": "two"} }}
    Portal Will Pick    ${other}
    Click Header Button    menu
    Click Text In Region    @{WS_MENU_AREA}    Open another
    Wait Until Portal Is Asked
    Sleep    1.0s
    Type In Query Box    .saved
    Save Query As    chosen
    ${found}=    Files In Folder    ${other}
    Should Contain    ${found}    chosen.jq
    Workspace File Should Not Exist    chosen.jq

TC-WSP-164 The Usual Workspace Comes Back From The Menu
    [Tags]    p2
    ${other}=    Make Folder With Files    elsewhere    ${{ {"second.jmespath": "two"} }}
    Portal Will Pick    ${other}
    Click Header Button    menu
    Click Text In Region    @{WS_MENU_AREA}    Open another
    Wait Until Portal Is Asked
    Sleep    1.0s
    List Should Not Show    scratch
    Pick Pane Menu Item    usual workspace
    Sleep    0.8s
    List Should Show    scratch    Logs
    Quit And Start Again
    List Should Show    scratch
    Settings Value Should Be    workspace.folder    None

TC-WSP-165 Show It In The File Manager Opens The Folder Of The Workspace
    [Tags]    p2
    Pick Pane Menu Item    file manager
    ${root}=    Workspace Folder
    Opened Addresses Should Be    ${root}

TC-WSP-166 Read It Again Shows What Another Program Did To The Folder
    [Tags]    p1
    Write Workspace File    added.jq    .added
    Delete Workspace File    scratch.jq
    List Should Show    scratch
    Pick Pane Menu Item    Read it again
    List Should Show    added
    List Should Not Show    scratch
    ${item}=    Workspace Item    added.jq
    Should Match Regexp    ${item}[id]    ^[0-9a-f-]{36}$

TC-WSP-148 With A Folder Picked The Export Window Still Offers The Whole Workspace First
    [Documentation]    Until the other choice is made the whole workspace is what is exported.
    [Tags]    p2
    Click Row    ${ROW_SERVICES}
    ${out}=    Make Export Folder
    Open Export Form
    Form Should Show    only the folder
    Export To    ${out}    214
    ${files}=    Files In Folder    ${out}
    Lists Should Be Equal    ${files}    ${STANDARD_FILES}

TC-WSP-167 The Menu Does Not Offer The Usual Workspace While It Is The One In Use
    [Tags]    p2
    Click Header Button    menu
    Region Should Contain Text    @{WS_MENU_AREA}    Read it again
    Region Should Not Contain Text    @{WS_MENU_AREA}    usual workspace
    Press Key    escape

*** Keywords ***
Workspace Folders Should Be
    [Arguments]    @{expected}
    ${found}=    Workspace Folders
    Lists Should Be Equal    ${found}    ${expected}

Click Import Name Field
    [Documentation]    The box of the name of the new folder, at the right of "in a new folder": found by that label.
    ${x}    ${y}    ${w}    ${h}=    Form Region
    ${found_x}    ${found_y}=    Find Text In Region    ${x}    ${y}    ${w}    ${h}    new
    ${at}=    Evaluate    ${found_x} + 120
    Click At    ${at}    ${found_y}
    Sleep    0.3s
