*** Settings ***
Documentation     What is done with an item of the workspace: opening it (a double click, the button under the
...               list, with its sample), the menu of a row (rename, copy, delete, show in the file manager), and
...               saving what is in the query box -- see docs/25_workspace.md. The cases read the folder after
...               each: the files, and the ids and SHA-256s that the workspace keeps of them in its hidden
...               index.
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Close Jsonquery App

*** Variables ***
# The Save window.
${SAVE_TITLE}             Save in the workspace

*** Test Cases ***
TC-WSP-040 A Double Click On A Query Opens It In The Query Box In Its Language
    [Documentation]    A name that ends .jq is a jq query: its text is in the box, the jq engine is picked, and the
    ...    Query row says which item the box came from.
    [Tags]    p1
    Double Click Row    ${ROW_SCRATCH}
    Query Box Should Hold    ${SCRATCH_TEXT}
    Row Should Be Selected    ${ROW_SCRATCH}
    Engine Chip Should Be Selected    jq
    Engine Chip Should Not Be Selected    jmespath
    Wait Until Region Matches    @{WS_QUERY_ROW}    scratch\\.jq    timeout=4

TC-WSP-041 A Query That Ends .jmespath Is Opened As JMESPath
    [Tags]    p1
    Double Click Row    ${ROW_LOGINS}
    Query Box Should Hold    ${LOGINS_TEXT}
    Engine Chip Should Be Selected    jmespath
    Engine Chip Should Not Be Selected    jq
    Wait Until Region Matches    @{WS_QUERY_ROW}    Logs +/ +logins\\.jm    timeout=4

TC-WSP-042 A JSONPath Query And A JSON Pointer Query Are Opened In Their Own Language
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${ENGINES}
    # Rows: Logs, Errors, logins, Services, orders, update, paths, ptr, scratch.
    Double Click Row    6
    Query Box Should Hold    $.a
    Engine Chip Should Be Selected    jsonpath
    Double Click Row    7
    Query Box Should Hold    /a
    Engine Chip Should Be Selected    pointer
    Engine Chip Should Not Be Selected    jsonpath

TC-WSP-043 The Open Button Under The List Opens The Item That Is Picked
    [Tags]    p1
    Click Row    ${ROW_LOGINS}
    Press Leftmost In Details    Open
    Query Box Should Hold    ${LOGINS_TEXT}
    Engine Chip Should Be Selected    jmespath

TC-WSP-044 A Query That Was Changed Since It Was Opened Is Marked
    [Documentation]    The Query row says where the box came from and, once the text is not the item's any more,
    ...    marks it with a dot: the label is longer by the dot.
    [Tags]    p2
    Double Click Row    ${ROW_SCRATCH}
    Move Mouse To    600    300
    ${before}=    Origin Label Right Edge
    Type In Query Box    .changed
    Move Mouse To    600    300
    ${after}=    Origin Label Right Edge
    Should Be True    ${after} - ${before} >= 6    msg=The label ends at ${before} unchanged and ${after} changed
    Type In Query Box    ${SCRATCH_TEXT}
    Move Mouse To    600    300
    ${back}=    Origin Label Right Edge
    Should Be True    ${back} - ${before} <= 2    msg=The mark stayed when the text was the item's again: ${back}

TC-WSP-096 A Click Only Picks: What Is In The Query Box Stays Until Something Is Opened
    [Documentation]    A click on an item or on a folder picks it and shows it under the list; only an open (a double
    ...    click, the Open button, the menu) replaces what is in the box.
    [Tags]    p1
    Type In Query Box    .keep
    Click Row    ${ROW_SCRATCH}
    Click Row    ${ROW_LOGINS}
    # A folder is shut by a click and opened by another; the rows are where they were after both.
    Click Row    ${ROW_SERVICES}
    Click Row    ${ROW_SERVICES}
    Query Box Should Hold    .keep
    Double Click Row    ${ROW_SCRATCH}
    Query Box Should Hold    ${SCRATCH_TEXT}

TC-WSP-045 Open With Sample Opens The Sample As The Source And Runs The Query
    [Tags]    p1
    Click Row    ${ROW_ERRORS}
    Click Row    2
    Press In Details    sample
    Sleep    1.0s
    Query Box Should Hold    ${FAILURES_TEXT}
    Status Line Should Match    result\\(s\\)
    Engine Chip Should Be Selected    jq
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    2 items    timeout=5
    Wait Until Region Matches    @{WS_RESULTS_PANEL}    1 items    timeout=5

TC-WSP-046 A Query With No Sample Has No Button For One
    [Tags]    p2
    Click Row    ${ROW_SCRATCH}
    Details Should Show    Open
    Details Should Not Show    with sample

TC-WSP-047 A Document Is Opened As The Source
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${WITH_DOCUMENT}
    # Rows: Logs, Errors, logins, Services, orders, update, people, scratch.
    Double Click Row    6
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    2 items    timeout=6
    Region Should Contain Text    256    0    560    24    people

TC-WSP-048 The Button Under The List Opens A Document As The Source
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${WITH_DOCUMENT}
    Click Row    6
    Details Should Show    people    Open as Source
    Press In Details    Open as
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    2 items    timeout=6

TC-WSP-049 The Menu Of An Item Has What Can Be Done With It
    [Tags]    p1
    Row Menu Should Offer    ${ROW_SCRATCH}    Open    Rename    Duplicate    Move to    Copy text    file manager    Delete
    Row Menu Should Not Offer    ${ROW_SCRATCH}    with sample    Import    Export

TC-WSP-050 An Item That Has A Sample Has One More Item In Its Menu
    [Tags]    p2
    Row Menu Should Offer    ${ROW_ORDERS}    Use as schema    with its sample    Rename    Duplicate    Delete

TC-WSP-051 The Menu Of A Folder Has What Can Be Done With A Folder
    [Tags]    p1
    Row Menu Should Offer    ${ROW_SERVICES}    Save the query here    New folder    Rename    Move to    Import into this    Export this folder    file manager    Delete
    Row Menu Should Not Offer    ${ROW_SERVICES}    Duplicate    Copy text

TC-WSP-052 A Right Click Picks The Row It Is On
    [Tags]    p2
    Row Should Not Be Selected    ${ROW_SCRATCH}
    Right Click Row    ${ROW_SCRATCH}
    Press Key    escape
    Sleep    0.4s
    Move Mouse To    600    400
    Row Should Be Selected    ${ROW_SCRATCH}

TC-WSP-053 Open In The Menu Opens The Query
    [Tags]    p2
    Pick Row Menu Item    ${ROW_LOGINS}    Open
    Query Box Should Hold    ${LOGINS_TEXT}
    Engine Chip Should Be Selected    jmespath

TC-WSP-054 Rename In The Menu Gives An Item Another Name And Keeps Its Id
    [Documentation]    The name is typed over the old one in the row; the file is renamed, the id the workspace
    ...    keeps of it is the same and so is what it holds, and the row is picked under its new name.
    [Tags]    p1
    ${before}=    Workspace Item    scratch.jq
    Rename Row To    ${ROW_SCRATCH}    fresh
    Workspace File Should Be    fresh.jq    ${SCRATCH_TEXT}
    Workspace File Should Not Exist    scratch.jq
    ${after}=    Workspace Item    fresh.jq
    Should Be Equal    ${after}[id]    ${before}[id]
    Should Be Equal    ${after}[sha256]    ${before}[sha256]
    List Should Show    fresh
    List Should Not Show    scratch
    Row Should Be Selected    ${ROW_SCRATCH}

TC-WSP-055 Renaming An Item Takes Its Sample With It
    [Tags]    p2
    Click Row    ${ROW_ERRORS}
    Rename Row To    2    broken
    Workspace File Should Be    Logs/Errors/broken.jq    ${FAILURES_TEXT}
    Workspace File Should Be    Logs/Errors/broken.sample.json    ${FAILURES_SAMPLE}
    Workspace File Should Not Exist    Logs/Errors/failures.jq
    Workspace File Should Not Exist    Logs/Errors/failures.sample.json
    ${item}=    Workspace Item    Logs/Errors/broken.jq
    ${sha}=    Sha256 Of Text    ${FAILURES_SAMPLE}
    Should Be Equal    ${item}[sample][sha256]    ${sha}

TC-WSP-056 A Name That Is Typed And Then Escape Is Not A Rename
    [Tags]    p2
    Pick Row Menu Item    ${ROW_SCRATCH}    Rename
    # The box that the name is typed in starts with the name the item has (read in the row: the details under the list
    # say the name of the item that is picked as well).
    ${y}=    Row Y    ${ROW_SCRATCH}
    Wait Until Keyword Succeeds    4x    0.4s    Region Should Show Text    0    ${{ ${y} - 10 }}    256    20    scratch
    Press Keys    ctrl    a
    Type Text    nothing
    Press Key    escape
    Sleep    0.6s
    Workspace File Should Be    scratch.jq    ${SCRATCH_TEXT}
    Workspace File Should Not Exist    nothing.jq
    List Should Show    scratch
    List Should Not Show    nothing

TC-WSP-057 A Name That Is Taken Is Said And The Item Is Not Renamed
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${WITH_OTHER}
    # Rows: Logs, Errors, logins, Services, orders, update, other, scratch.
    Rename Row To    7    other
    Workspace File Should Be    scratch.jq    ${SCRATCH_TEXT}
    Workspace File Should Be    other.jq    .other
    Notice Should Say    already a query called
    List Should Show    scratch    other

TC-WSP-058 A Name That A File Cannot Have Is Said And The Item Is Not Renamed
    [Tags]    p2
    Rename Row To    ${ROW_SCRATCH}    a/b
    Workspace File Should Be    scratch.jq    ${SCRATCH_TEXT}
    Notice Should Say    can.t have
    List Should Show    scratch

TC-WSP-059 A Folder Is Renamed And Everything In It Keeps Its Id
    [Tags]    p1
    ${logins}=    Workspace Item    Logs/logins.jmespath
    Rename Row To    ${ROW_LOGS}    Journal
    Workspace File Should Be    Journal/logins.jmespath    ${LOGINS_TEXT}
    Workspace File Should Be    Journal/Errors/failures.jq    ${FAILURES_TEXT}
    Workspace File Should Not Exist    Logs/logins.jmespath
    ${after}=    Workspace Item    Journal/logins.jmespath
    Should Be Equal    ${after}[id]    ${logins}[id]
    List Should Show    Journal    logins
    List Should Not Show    Logs

TC-WSP-060 Duplicate Makes A Copy With Its Sample And An Id Of Its Own
    [Tags]    p1
    Click Row    ${ROW_ERRORS}
    ${first}=    Workspace Item    Logs/Errors/failures.jq
    Pick Row Menu Item    2    Duplicate
    # Rows: Logs, Errors, failures, failures (2), ... the copy is the one that is picked.
    Row Should Be Selected    3
    Workspace File Should Be    Logs/Errors/failures (2).jq    ${FAILURES_TEXT}
    Workspace File Should Be    Logs/Errors/failures (2).sample.json    ${FAILURES_SAMPLE}
    ${copy}=    Workspace Item    Logs/Errors/failures (2).jq
    Should Not Be Equal    ${copy}[id]    ${first}[id]
    Should Be Equal    ${copy}[sha256]    ${first}[sha256]
    Workspace File Should Be    Logs/Errors/failures.jq    ${FAILURES_TEXT}
    Notice Should Say    Copied as

TC-WSP-061 Duplicate Twice Makes Two Copies With Numbers
    [Tags]    p3
    Pick Row Menu Item    ${ROW_SCRATCH}    Duplicate
    Pick Row Menu Item    ${ROW_SCRATCH}    Duplicate
    Workspace File Should Exist    scratch (2).jq
    Workspace File Should Exist    scratch (3).jq

TC-WSP-062 Copy Text Puts The Text Of The Item On The Clipboard
    [Tags]    p1
    Set Clipboard    nothing was copied
    Pick Row Menu Item    ${ROW_LOGINS}    Copy text
    Clipboard Should Be    ${LOGINS_TEXT}

TC-WSP-063 Show In The File Manager Opens The Folder The Item Is In
    [Documentation]    The app asks the desktop to show the folder (xdg-open): the stand-in the cases start every app
    ...    with writes down what it was asked and opens nothing.
    [Tags]    p2
    Pick Row Menu Item    ${ROW_LOGINS}    file manager
    ${logs}=    Workspace Folder    Logs
    Opened Addresses Should Be    ${logs}

TC-WSP-064 Show In The File Manager On A Folder Opens That Folder
    [Tags]    p2
    Pick Row Menu Item    ${ROW_SERVICES}    file manager
    ${services}=    Workspace Folder    Services
    Opened Addresses Should Be    ${services}

TC-WSP-065 Delete Asks Before It Deletes And Cancel Keeps The Item
    [Tags]    p1
    Open Delete Form    ${ROW_SCRATCH}
    Form Should Show    scratch    cannot be undone
    Workspace File Should Exist    scratch.jq
    Press Cancel Button
    Form Should Not Be Open    cannot be undone
    Workspace File Should Be    scratch.jq    ${SCRATCH_TEXT}
    List Should Show    scratch

TC-WSP-066 Escape Closes The Question And Keeps The Item
    [Tags]    p2
    Open Delete Form    ${ROW_SCRATCH}
    Press Key    escape
    Sleep    0.6s
    Form Should Not Be Open    cannot be undone
    Workspace File Should Exist    scratch.jq

TC-WSP-067 Delete Deletes The File And The Id The Workspace Kept Of It
    [Tags]    p1
    ${index}=    Workspace Index
    Dictionary Should Contain Key    ${index}[items]    scratch.jq
    Open Delete Form    ${ROW_SCRATCH}
    Press Primary Button
    Workspace File Should Not Exist    scratch.jq
    List Should Not Show    scratch
    ${index}=    Workspace Index
    Dictionary Should Not Contain Key    ${index}[items]    scratch.jq
    Notice Should Say    Deleted
    Details Should Show    Pick an item

TC-WSP-068 Deleting An Item Deletes Its Sample Too
    [Tags]    p1
    Click Row    ${ROW_ERRORS}
    Open Delete Form    2
    Press Primary Button
    Workspace File Should Not Exist    Logs/Errors/failures.jq
    Workspace File Should Not Exist    Logs/Errors/failures.sample.json

TC-WSP-069 Deleting A Folder Deletes What The Workspace Put In It
    [Tags]    p1
    Open Delete Form    ${ROW_LOGS}
    Form Should Show    Logs
    Press Primary Button
    Workspace File Should Not Exist    Logs
    Workspace File Should Not Exist    Logs/Errors/failures.jq
    Workspace File Should Exist    Services/orders.schema.json
    List Should Not Show    Logs    logins
    List Should Show    Services    scratch
    Notice Should Say    Deleted

TC-WSP-070 A Folder That Has A File That Is Not The Workspace's Keeps It
    [Documentation]    Only what the workspace knows is deleted: a text file in the folder, and so the folder, are left,
    ...    and the app says so.
    [Tags]    p1
    Write Workspace File    Services/notes.txt    mine
    Pick Pane Menu Item    Read it again
    Open Delete Form    ${ROW_SERVICES}
    Press Primary Button
    Workspace File Should Be    Services/notes.txt    mine
    Workspace File Should Not Exist    Services/orders.schema.json
    Workspace File Should Not Exist    Services/update.patch.json
    Notice Should Say    other file
    Notice Should Say    left, and so\\s+is\\s+the
    # (The folder is still in the list, with the other file in it, and it is not the one that is picked any more.)
    Row Should Not Be Selected    ${ROW_SERVICES}

TC-WSP-168 A Message Under The List Goes After A Few Seconds
    [Tags]    p3
    Pick Row Menu Item    ${ROW_SCRATCH}    Duplicate
    Notice Should Say    Copied as
    Sleep    11s
    Region Should Not Contain Text    @{WS_DETAILS}    Copied as
