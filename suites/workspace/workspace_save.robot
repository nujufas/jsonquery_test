*** Settings ***
Documentation     Saving what is in the query box in the workspace: the window that the 💾 of the pane (and the
...               Save… beside Run) opens, its tabs, name, folder, new folder and sample, the question of
...               replacing, and what is kept of what is saved (the file, and its id and SHA-256 in the hidden
...               index) -- see docs/25_workspace.md.
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Close Jsonquery App

*** Variables ***
# The window is told by a line of its own: its title is dim when the window is not the one with the focus.
${SAVE_TITLE}             new folder in it
${QUERY}                  .name | length
${DOCUMENT}               {"a": [1, 2, 3]}

*** Test Cases ***
TC-WSP-071 The Pane's Save Button Opens The Window That Saves What Is In The Query Box
    [Documentation]    The window has the sort of thing that is saved (the query is the one that is picked), the Name
    ...    box with the focus, the Folder box, a box for a folder to make, and the tick that keeps a sample.
    [Tags]    p1
    Type In Query Box    ${QUERY}
    Open Save Form
    Form Should Show    Save    the query    a schema    a patch    the Source    Name    Folder    new folder in it
    Form Should Show    Keep the Source as its sample
    # Save, which cannot be pressed with no name, and Cancel.
    Form Should Have This Many Buttons    2
    Workspace Files Should Be    ${STANDARD_FILES}

TC-WSP-072 Nothing Is Saved Until There Is A Name
    [Tags]    p1
    Type In Query Box    ${QUERY}
    Open Save Form
    Press Key    enter
    Sleep    0.6s
    Form Should Be Open    ${SAVE_TITLE}
    Press Primary Button
    Sleep    0.6s
    Form Should Be Open    ${SAVE_TITLE}
    Workspace Files Should Be    ${STANDARD_FILES}

TC-WSP-073 The Window Says What The File Will Be Called As The Name Is Typed
    [Tags]    p2
    Type In Query Box    ${QUERY}
    Open Save Form
    Type Text    mine
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    Saved as mine.jq
    # The button says Save (34 wide): it says Replace (53) when the name is taken.
    Primary Button Should Be This Wide    28    42

TC-WSP-074 Enter In The Name Box Saves The Query Under That Name
    [Documentation]    The file is the query's text; the item is picked in the list, the notice says it was saved, and
    ...    the Query row says that the box came from it.
    [Tags]    p1
    Type In Query Box    ${QUERY}
    Save Query As    mine
    Form Should Not Be Open    ${SAVE_TITLE}
    Workspace File Should Be    mine.jq    ${QUERY}
    List Should Show    mine
    Notice Should Say    Saved
    Wait Until Region Matches    @{WS_QUERY_ROW}    mine\\.j[aqg]    timeout=5
    Details Should Show    mine.jq

TC-WSP-075 What Is Kept Of The Query Is An Id And A SHA-256 Of What It Holds
    [Documentation]    Not shown to the person who saves it: the hidden index has, for every item, an id (a UUID
    ...    of version 4) and the SHA-256 of what it holds.
    [Tags]    p1
    Type In Query Box    ${QUERY}
    Save Query As    mine
    ${item}=    Workspace Item    mine.jq
    ${sha}=    Sha256 Of Text    ${QUERY}
    Should Be Equal    ${item}[sha256]    ${sha}
    Should Match Regexp    ${item}[id]    ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$
    Should Be Equal As Integers    ${item}[bytes]    ${{ len($QUERY.encode()) }}
    ${index}=    Workspace Index
    ${ids}=    Evaluate    [e["id"] for e in $index["items"].values()]
    ${count}=    Get Length    ${ids}
    ${unique}=    Evaluate    len(set($ids))
    Should Be Equal As Integers    ${count}    ${unique}    msg=Two items have the same id
    Should Be Equal As Integers    ${count}    6

TC-WSP-076 The Save Button Of The Window Saves Too
    [Tags]    p2
    Type In Query Box    ${QUERY}
    Open Save Form
    Type Text    clicked
    Press Primary Button
    Sleep    0.8s
    Workspace File Should Be    clicked.jq    ${QUERY}
    Form Should Not Be Open    ${SAVE_TITLE}

TC-WSP-077 Escape And Cancel And The Cross Close The Window And Save Nothing
    [Tags]    p1
    Type In Query Box    ${QUERY}
    Open Save Form
    Type Text    nothing
    Press Key    escape
    Sleep    0.6s
    Form Should Not Be Open    ${SAVE_TITLE}
    Open Save Form
    Press Cancel Button
    Sleep    0.6s
    Form Should Not Be Open    ${SAVE_TITLE}
    Open Save Form
    Click In Form    779    97
    Form Should Not Be Open    ${SAVE_TITLE}
    Workspace File Should Not Exist    nothing.jq

TC-WSP-078 The Save Button Beside Run Opens The Same Window
    [Tags]    p1
    Type In Query Box    ${QUERY}
    Click At    ${WS_QUERY_SAVE_X}    ${WS_QUERY_SAVE_Y}
    Form Should Be Open    ${SAVE_TITLE}
    Type Text    beside
    Press Key    enter
    Sleep    0.8s
    Workspace File Should Be    beside.jq    ${QUERY}

TC-WSP-079 The Query Can Be Saved In A Folder That Is Chosen In The Window
    [Tags]    p1
    Type In Query Box    ${QUERY}
    Open Save Form
    Choose Save Folder    Services
    Type Name In Form    inside
    Form Should Show    Saved as Services/inside.jq
    Press Key    enter
    Sleep    0.8s
    Workspace File Should Be    Services/inside.jq    ${QUERY}
    List Should Show    inside    orders

TC-WSP-080 A New Folder Is Made For The Query By Typing Its Name
    [Tags]    p1
    Type In Query Box    ${QUERY}
    Open Save Form
    Click In Form    ${SAVE_SUB_X}    ${SAVE_SUB_Y}
    Type Text    Fresh
    Click In Form    ${SAVE_NAME_X}    ${SAVE_NAME_Y}
    Type Text    first
    Form Should Show    Saved as Fresh/first.jq
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    Fresh/first.jq    ${QUERY}
    List Should Show    Fresh    first

TC-WSP-081 A Folder Is Chosen And A New One Is Made In It
    [Tags]    p2
    Type In Query Box    ${QUERY}
    Open Save Form
    Choose Save Folder    Logs
    Click In Form    ${SAVE_SUB_X}    ${SAVE_SUB_Y}
    Type Text    Old
    Click In Form    ${SAVE_NAME_X}    ${SAVE_NAME_Y}
    Type Text    deep
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    Logs/Old/deep.jq    ${QUERY}

TC-WSP-082 A Name That A File Cannot Have Is Said In Red And Nothing Is Saved
    [Tags]    p1
    Type In Query Box    ${QUERY}
    Open Save Form
    Type Text    a/b
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    have any of
    Press Key    enter
    Sleep    0.6s
    Form Should Be Open    ${SAVE_TITLE}
    Workspace File Should Not Exist    a
    Workspace File Should Not Exist    a/b.jq

TC-WSP-083 A Name That Is Taken Asks To Replace And Replacing Keeps The Id
    [Documentation]    The button says Replace and the window says that saving replaces what is there; the file
    ...    is the new text, and the item is the same item: its id is kept, its SHA-256 is the new text's.
    [Tags]    p1
    ${before}=    Workspace Item    scratch.jq
    Type In Query Box    ${QUERY}
    Open Save Form
    Type Text    scratch
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    replaces it    Replace
    Primary Button Should Be This Wide    45    65
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    scratch.jq    ${QUERY}
    ${after}=    Workspace Item    scratch.jq
    Should Be Equal    ${after}[id]    ${before}[id]
    ${sha}=    Sha256 Of Text    ${QUERY}
    Should Be Equal    ${after}[sha256]    ${sha}
    Should Not Be Equal    ${after}[sha256]    ${before}[sha256]

TC-WSP-084 A Query That Came From The Workspace Is Offered Back Under Its Own Name
    [Tags]    p1
    ${before}=    Workspace Item    scratch.jq
    Double Click Row    ${ROW_SCRATCH}
    Type In Query Box    . | length
    Open Save Form
    Form Should Show    scratch    Replace
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    scratch.jq    . | length
    ${after}=    Workspace Item    scratch.jq
    Should Be Equal    ${after}[id]    ${before}[id]

TC-WSP-085 The Language The Query Is In Gives The File Its End
    [Documentation]    jq is the default: .jq; the engine that is picked decides otherwise: .jsonpath, .jmespath, .jsonptr.
    [Tags]    p1
    Pick Engine    jsonpath
    Type In Query Box    $.a
    Save Query As    one
    Workspace File Should Be    one.jsonpath    $.a
    Pick Engine    jmespath
    Type In Query Box    a.b
    Save Query As    two
    Workspace File Should Be    two.jmespath    a.b
    Pick Engine    pointer
    Type In Query Box    /a
    Save Query As    three
    Workspace File Should Be    three.jsonptr    /a
    Pick Engine    jq
    Type In Query Box    .a
    Save Query As    four
    Workspace File Should Be    four.jq    .a

TC-WSP-086 Nothing Can Be Saved From An Empty Query Box
    [Documentation]    The tab for the query is dim, and the window can be closed: with nothing in the box there is
    ...    nothing to save.
    [Tags]    p2
    Open Save Form
    Press Key    enter
    Type Text    nothing
    Press Key    enter
    Sleep    0.6s
    Form Should Be Open    ${SAVE_TITLE}
    Workspace File Should Not Exist    nothing.jq
    Press Key    escape
    Sleep    0.5s
    Form Should Not Be Open    ${SAVE_TITLE}

TC-WSP-087 The Source Can Be Kept As The Sample Of The Query
    [Documentation]    With a document open as the Source the window offers to keep it with the query: it is written
    ...    next to it as <name>.sample.json, and the index has its SHA-256 as well.
    [Tags]    p1
    Paste In Source    ${DOCUMENT}
    Type In Query Box    .a
    Open Save Form
    Form Should Show    Keep the Source as its sample
    Click In Form    ${SAVE_SAMPLE_X}    ${SAVE_SAMPLE_Y}
    Type Name In Form    withsample
    Press Key    enter
    Wait Until Workspace File Exists    withsample.sample.json    timeout=8
    Workspace File Should Be    withsample.jq    .a
    Workspace File Should Hold Json    withsample.sample.json    ${DOCUMENT}
    ${item}=    Workspace Item    withsample.jq
    Should Not Be Empty    ${item}[sample][sha256]
    List Should Show    withsample

TC-WSP-088 The Tick For A Sample Is Dim When There Is No Source
    [Tags]    p2
    Type In Query Box    .a
    Open Save Form
    Click In Form    ${SAVE_SAMPLE_X}    ${SAVE_SAMPLE_Y}
    Type Name In Form    nosample
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    nosample.jq    .a
    Workspace File Should Not Exist    nosample.sample.json

TC-WSP-089 Without The Tick No Sample Is Kept
    [Tags]    p2
    Paste In Source    ${DOCUMENT}
    Type In Query Box    .a
    Save Query As    plain
    Workspace File Should Be    plain.jq    .a
    Workspace File Should Not Exist    plain.sample.json

TC-WSP-090 The Source Is Saved As A Document Of The Workspace
    [Tags]    p1
    Paste In Source    ${DOCUMENT}
    Open Save Form
    # With nothing in the query box the window offers what there is: the Source.
    Tab Of The Save Window Should Be Picked    ${SAVE_TAB_SOURCE_X}
    Click In Form    ${SAVE_TAB_SOURCE_X}    ${SAVE_TAB_Y}
    Type Name In Form    saved
    Press Key    enter
    Wait Until Workspace File Exists    saved.json    timeout=8
    Workspace File Should Hold Json    saved.json    ${DOCUMENT}
    ${item}=    Workspace Item    saved.json
    Should Match Regexp    ${item}[id]    ^[0-9a-f-]{36}$

TC-WSP-091 The Folder That Is Picked In The List Is The One The Window Offers
    [Tags]    p2
    Click Row    ${ROW_SERVICES}
    Type In Query Box    ${QUERY}
    Open Save Form
    Type Text    here
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    Saved as Services/here.jq
    Press Key    enter
    Sleep    0.8s
    Workspace File Should Be    Services/here.jq    ${QUERY}

TC-WSP-092 An Item That Is Picked Offers The Folder It Is In
    [Tags]    p2
    Click Row    ${ROW_LOGINS}
    Type In Query Box    ${QUERY}
    Open Save Form
    Type Text    beside
    Press Key    enter
    Sleep    0.8s
    Workspace File Should Be    Logs/beside.jq    ${QUERY}

TC-WSP-093 After A Query Is Saved The Box Came From It And The Window Offers Its Name Again
    [Documentation]    The query that was saved is the one the box came from: the next time the window opens it has
    ...    that name and says that saving replaces it (a name typed over it is another item).
    [Tags]    p3
    Type In Query Box    ${QUERY}
    Save Query As    first
    Type In Query Box    .other
    Open Save Form
    Form Should Show    Saved as first.jq    replaces it    Replace
    Press Key    escape

TC-WSP-094 A Query Saved With The Pane Folded Is In The Workspace All The Same
    [Tags]    p2
    Click Header Button    fold
    Pane Should Not Be Shown
    Type Into Folded Query Box    ${QUERY}
    Click Text In Region    @{WS_QUERY_ROW_FOLDED}    Save
    Form Should Be Open    ${SAVE_TITLE}
    Type Text    folded
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    folded.jq    ${QUERY}

TC-WSP-095 The Menu Of A Folder Saves The Query In That Folder
    [Tags]    p2
    Type In Query Box    ${QUERY}
    Set Form Kind    save
    Pick Row Menu Item    ${ROW_SERVICES}    Save the query
    Form Should Be Open    ${SAVE_TITLE}
    Type Name In Form    here
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    Saved as Services/here.jq
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    Services/here.jq    ${QUERY}

*** Keywords ***
Type Into Folded Query Box
    [Documentation]    The query box, with the pane folded to its strip, holds `text` (put there with a paste).
    [Arguments]    ${text}
    Set Clipboard    ${text}
    Click At    600    80
    Sleep    0.3s
    Press Keys    ctrl    a
    Press Keys    ctrl    v
    Sleep    0.4s
