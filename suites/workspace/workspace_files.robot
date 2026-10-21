*** Settings ***
Documentation     What the workspace keeps of its items, and how it keeps it in step with the folder: an id that
...               an item keeps for as long as it is stored (whatever becomes of its name, its place or its text)
...               and the SHA-256 of what it holds, in one hidden file, `.jsonquery/index.json` -- which is not
...               shown to the person who uses the app, and is what later work (keeping two workspaces in step,
...               knowing that an item is the one that was shared) goes by. Also the safety of the folder: what is
...               not an item is left alone, a link is not followed, the samples that items share, and a
...               damaged index. See docs/25_workspace.md.
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace    files
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Close Jsonquery App

*** Test Cases ***
TC-WSP-190 The First Read Of A Workspace That Has Files Gives Every Item An Id And A SHA-256
    [Documentation]    The index is made as the folder is read: a UUID of version 4 for every item (nothing of it in the
    ...    list), the SHA-256 of what the item holds, its size, and the sample's, if it has one.
    [Tags]    p1
    ${index}=    Workspace Index
    Should Be Equal    ${index}[format]    jsonquery-workspace
    Should Be Equal As Integers    ${index}[version]    1
    ${items}=    Set Variable    ${index}[items]
    ${paths}=    Get Dictionary Keys    ${items}    sort_keys=${TRUE}
    Lists Should Be Equal    ${paths}    ${{ ["Logs/Errors/failures.jq", "Logs/logins.jmespath", "Services/orders.schema.json", "Services/update.patch.json", "scratch.jq"] }}
    FOR    ${path}    ${entry}    IN    &{items}
        Should Match Regexp    ${entry}[id]    ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$
        Should Match Regexp    ${entry}[sha256]    ^[0-9a-f]{64}$
        ${full}=    Workspace Folder    ${path}
        ${size}=    Get File Size    ${full}
        Should Be Equal As Integers    ${entry}[bytes]    ${size}    msg=${path}
    END
    ${sha}=    Sha256 Of Text    ${SCRATCH_TEXT}
    Should Be Equal    ${items}[scratch.jq][sha256]    ${sha}
    Should Be Equal    ${items}[Services/orders.schema.json][sample][bytes]    ${2}
    ${ids}=    Evaluate    [e["id"] for e in $items.values()]
    ${unique}=    Evaluate    len(set($ids))
    Should Be Equal As Integers    ${unique}    5

TC-WSP-191 Nothing Is Made For A Workspace That Has Nothing In It
    [Documentation]    A new user who opens the pane has no folder made, and no index: the app does not leave a folder of
    ...    its own where nothing is kept.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${NO_FILES}
    Wait Until Region Matches    @{WS_LIST}    Nothing is saved    timeout=5
    ${folder}=    Workspace Folder
    Directory Should Not Exist    ${folder}

TC-WSP-192 What Is Not An Item Has No Id
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${MIXED}
    ${index}=    Workspace Index
    ${paths}=    Get Dictionary Keys    ${index}[items]    sort_keys=${TRUE}
    Should Contain    ${paths}    data.json
    Should Contain    ${paths}    events.ndjson
    Should Not Contain    ${paths}    notes.txt
    Should Not Contain    ${paths}    readme.md
    Should Not Contain    ${paths}    .hidden.jq
    Should Not Contain    ${paths}    Services/.secret/inside.jq
    ${all}=    Workspace Files    hidden=${TRUE}
    Should Contain    ${all}    .hidden.jq
    Should Contain    ${all}    .jsonquery/index.json

TC-WSP-193 Another Program Changes An Item And It Keeps Its Id With A New SHA-256
    [Tags]    p1
    ${before}=    Workspace Item    scratch.jq
    Write Workspace File    scratch.jq    . | length
    Pick Pane Menu Item    Read it again
    ${after}=    Workspace Item    scratch.jq
    Should Be Equal    ${after}[id]    ${before}[id]
    ${sha}=    Sha256 Of Text    . | length
    Should Be Equal    ${after}[sha256]    ${sha}
    Should Not Be Equal    ${after}[sha256]    ${before}[sha256]

TC-WSP-194 Another Program Renames An Item And It Is Found Again By What It Holds
    [Tags]    p1
    ${before}=    Workspace Item    Logs/logins.jmespath
    Move Workspace File    Logs/logins.jmespath    Logs/sign-ins.jmespath
    Pick Pane Menu Item    Read it again
    List Should Show    sign-ins
    List Should Not Show    logins
    ${after}=    Workspace Item    Logs/sign-ins.jmespath
    Should Be Equal    ${after}[id]    ${before}[id]
    ${index}=    Workspace Index
    Dictionary Should Not Contain Key    ${index}[items]    Logs/logins.jmespath

TC-WSP-195 Another Program Moves An Item To Another Folder And It Keeps Its Id
    [Tags]    p2
    ${before}=    Workspace Item    scratch.jq
    Move Workspace File    scratch.jq    Services/scratch.jq
    Pick Pane Menu Item    Read it again
    ${after}=    Workspace Item    Services/scratch.jq
    Should Be Equal    ${after}[id]    ${before}[id]

TC-WSP-196 An Item That Another Program Deleted Is Taken Out Of The Index
    [Tags]    p2
    Click Row    ${ROW_SCRATCH}
    Details Should Show    scratch.jq
    Delete Workspace File    scratch.jq
    Pick Pane Menu Item    Read it again
    List Should Not Show    scratch
    # What was picked is gone: nothing is picked.
    Details Should Show    Pick an item
    ${index}=    Workspace Index
    Dictionary Should Not Contain Key    ${index}[items]    scratch.jq

TC-WSP-197 An Item That Another Program Added Gets An Id
    [Tags]    p2
    Write Workspace File    Services/added.jq    .added
    Pick Pane Menu Item    Read it again
    List Should Show    added
    ${item}=    Workspace Item    Services/added.jq
    Should Match Regexp    ${item}[id]    ^[0-9a-f-]{36}$

TC-WSP-198 Two Items That Hold The Same Text Have Ids Of Their Own
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${TWINS}
    ${one}=    Workspace Item    twin one.jq
    ${two}=    Workspace Item    twin two.jq
    Should Be Equal    ${one}[sha256]    ${two}[sha256]
    Should Not Be Equal    ${one}[id]    ${two}[id]

TC-WSP-199 The Ids Are The Same When The App Is Started Again
    [Tags]    p1
    ${before}=    Workspace Index
    Quit And Start Again
    ${after}=    Workspace Index
    Compare Indexes    ${before}    ${after}
    List Should Show    scratch

TC-WSP-200 A Damaged Index Is Set Aside And Made Again From The Folder
    [Documentation]    The app does not stop at an index it cannot read: the file is kept as index.json.bad, the items
    ...    are listed all the same and get ids again.
    [Tags]    p2
    Quit Jsonquery App
    Close Jsonquery App    keep_home=${TRUE}
    Write Workspace File    .jsonquery/index.json    this is not json
    Launch Jsonquery App    keep_home=${TRUE}
    Sleep    1.0s
    List Should Show    Logs    scratch    Services
    ${index}=    Workspace Index
    Dictionary Should Contain Key    ${index}[items]    scratch.jq
    Workspace File Should Be    .jsonquery/index.json.bad    this is not json

TC-WSP-201 A Link Is Not Followed
    [Documentation]    A symbolic link in the workspace, to a file or a folder outside it, is not an item and is not entered:
    ...    the app does not read, write or delete through it.
    [Tags]    p1
    ${outside}=    Make Folder With Files    outside    ${{ {"secret.jq": ".secret", "deep/more.jq": ".more"} }}
    Link Workspace Path    linked.jq    ${outside}${/}secret.jq
    Link Workspace Path    linked folder    ${outside}
    Pick Pane Menu Item    Read it again
    List Should Show    scratch    Services
    List Should Not Show    linked    secret    more    deep
    # The links are said (a small warning sign at the end of the line under the title).
    Warning Should Be Shown Under The Title
    ${index}=    Workspace Index
    Dictionary Should Not Contain Key    ${index}[items]    linked.jq
    ${files}=    Files In Folder    ${outside}
    Lists Should Be Equal    ${files}    ${{ ["deep/more.jq", "secret.jq"] }}

TC-WSP-202 A Name That Differs From One That Is There Only By Its Case Is The Same Name
    [Tags]    p2
    Type In Query Box    .upper
    Open Save Form
    Press Keys    ctrl    a
    Type Text    SCRATCH
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    replaces it    Replace
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    scratch.jq    .upper
    Workspace File Should Not Exist    SCRATCH.jq

TC-WSP-203 Items That Share A Name Share The Sample
    [Documentation]    orders.schema.json and orders.patch.json are two items with one sample, orders.sample.json: it goes
    ...    when the last of them goes, and not before.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${SHARED_SAMPLE}
    # Rows: Logs, Errors, logins, Services, orders (the patch: .patch.json is before .schema.json), orders (the
    # schema), update, scratch.
    Open Delete Form    4
    Press Primary Button
    Workspace File Should Not Exist    Services/orders.patch.json
    Workspace File Should Exist    Services/orders.schema.json
    Workspace File Should Be    Services/orders.sample.json    {}
    List Should Show    orders
    Open Delete Form    4
    Press Primary Button
    Workspace File Should Not Exist    Services/orders.schema.json
    Workspace File Should Not Exist    Services/orders.sample.json

TC-WSP-204 A Save Leaves Nothing Of Its Own Behind
    [Documentation]    The workspace's own folder holds the index and nothing else once a save is done: no staged file
    ...    of a document, no half-written file.
    [Tags]    p2
    Paste In Source    {"a": [1, 2, 3]}
    Type In Query Box    .a
    Open Save Form
    Click In Form    ${SAVE_SAMPLE_X}    ${SAVE_SAMPLE_Y}
    Type Name In Form    clean
    Press Key    enter
    Wait Until Workspace File Exists    clean.sample.json    timeout=8
    Sleep    1.0s
    ${all}=    Workspace Files    hidden=${TRUE}
    ${own}=    Evaluate    [f for f in $all if f.startswith(".jsonquery/")]
    Lists Should Be Equal    ${own}    ${{ [".jsonquery/index.json"] }}
    ${stray}=    Evaluate    [f for f in $all if f.endswith(".tmp") or ".tmp" in f]
    Should Be Empty    ${stray}

TC-WSP-205 What Another Program Did Is Seen When The Window Gets The Focus Back
    [Documentation]    The folder is read again when the window that had lost the focus gets it back.
    [Tags]    p2
    Write Workspace File    focus.jq    .focus
    Click At    1123    789
    Wait Until Window Exists    JsonQuery — Settings    timeout=8
    Switch To Window    JsonQuery — Settings
    Sleep    0.6s
    Switch To Main Window
    Sleep    1.0s
    List Should Show    focus

TC-WSP-206 The Index Is Written Again Only When It Changes
    [Documentation]    Reading the folder when nothing was changed leaves the index file as it was: the same bytes,
    ...    and not written again.
    [Tags]    p3
    ${file}=    Workspace Folder    .jsonquery/index.json
    ${before}=    Get File    ${file}
    ${mtime}=    Get Modified Time    ${file}    epoch
    Sleep    1.2s
    Pick Pane Menu Item    Read it again
    ${after}=    Get File    ${file}
    Should Be Equal    ${after}    ${before}
    ${mtime_after}=    Get Modified Time    ${file}    epoch
    Should Be Equal As Integers    ${mtime_after}    ${mtime}

TC-WSP-207 A Folder That Cannot Be Written To Says So And Saves Nothing
    [Documentation]    The workspace is made read-only under the app: the window that saves says in red that it could not, and stays
    ...    open; when the folder can be written to again the same window saves.
    [Tags]    p2
    Type In Query Box    .x
    ${folder}=    Workspace Folder
    Evaluate    os.chmod($folder, 0o555)    modules=os
    TRY
        Save Query As    nope
        Form Should Show    could not be saved
        Form Should Be Open    new folder in it
        Workspace File Should Not Exist    nope.jq
    FINALLY
        Evaluate    os.chmod($folder, 0o755)    modules=os
    END
    Press Primary Button
    Sleep    0.9s
    Workspace File Should Be    nope.jq    .x

TC-WSP-208 An Item That Is Too Big For The Box Is Said And The Box Is Not Touched
    [Documentation]    A query of more than a megabyte is listed, and opening it is refused in red: the query box is as it was.
    [Tags]    p2
    Close Jsonquery App
    ${big}=    Evaluate    "x" * 1300000
    ${files}=    Evaluate    {**$STANDARD, "big.jq": $big}
    Launch Workspace App    files=${files}
    # Rows: Logs, Errors, logins, Services, orders, update, big, scratch.
    Type In Query Box    .keep
    Double Click Row    6
    Notice Should Say    too big
    Query Box Should Hold    .keep

TC-WSP-209 An Item That Is Not Text Is Said When It Is Opened
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App
    ${bad}=    Workspace Folder    bad.jq
    Evaluate    open($bad, "wb").write(b"\\xff\\xfe\\x00 not text")
    Pick Pane Menu Item    Read it again
    List Should Show    bad
    Type In Query Box    .keep
    # Rows: Logs, Errors, logins, Services, orders, update, bad, scratch.
    Double Click Row    6
    Notice Should Say    could not be read
    Query Box Should Hold    .keep

TC-WSP-213 An Item With A Byte-Order Mark Is Opened Without It
    [Tags]    p3
    Close Jsonquery App
    ${files}=    Evaluate    {**$STANDARD, "bom.jq": "\ufeff.after"}
    Launch Workspace App    files=${files}
    # Rows: Logs, Errors, logins, Services, orders, update, bom, scratch.
    Double Click Row    6
    Query Box Should Hold    .after

TC-WSP-214 A Workspace That Is A Link To Another Folder Is Used
    [Documentation]    The folder the workspace is in may itself be a link (a folder kept on another disk): what is in it is listed
    ...    and what is saved goes to the folder it points at.
    [Tags]    p2
    Close Jsonquery App
    ${real}=    Make Folder With Files    realws    ${STANDARD}
    ${parent}=    Make Temp Directory
    ${link}=    Set Variable    ${parent}${/}linkws
    Evaluate    os.symlink($real, $link)    modules=os
    ${settings}=    Evaluate    json.dumps({"workspace": {"pane": "open", "folder": $link}})    modules=json
    Launch Jsonquery App    settings=${settings}
    Pane Should Be Open
    List Should Show    Logs    scratch    Services
    Type In Query Box    .through
    Save Query As    linked
    ${found}=    Files In Folder    ${real}
    Should Contain    ${found}    linked.jq

TC-WSP-215 A Name Longer Than The Row Is Cut Short And The Tag Stays
    [Tags]    p3
    Close Jsonquery App
    ${long}=    Evaluate    "a name that is a good deal longer than a row of the list can hold " * 3
    ${files}=    Evaluate    {**$STANDARD, $long + ".jq": "."}
    Launch Workspace App    files=${files}
    # Rows: Logs, Errors, logins, Services, orders, update, the long one, scratch.
    Row Should Have Tag Colour    6    31    53    85
    Row Should Have Tag Colour    7    31    53    85
    ${y}=    Row Name Y    scratch
    ${wanted}=    Row Y    7
    Should Be True    abs(${y} - ${wanted}) <= 6    msg=The row under the long one is at ${y}, not ${wanted}
    Region Should Be Plain    249    ${{ ${wanted} - 120 }}    5    300

TC-WSP-216 A Name With Letters Of Other Languages Is Kept As It Is
    [Tags]    p3
    ${name}=    Set Variable    résumé naïve
    Type In Query Box    .letters
    Open Save Form
    Set Clipboard    ${name}
    Press Keys    ctrl    a
    Press Keys    ctrl    v
    Sleep    0.5s
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    ${name}.jq    .letters

TC-WSP-217 Three Thousand Items Are Read And Listed
    [Documentation]    The list draws the rows that are in view and no more: a workspace of three thousand queries opens at
    ...    once, says how many there are, and scrolls.
    [Tags]    p3
    Close Jsonquery App
    ${files}=    Evaluate    {f"q{n:04d}.jq": "." for n in range(3000)}
    Launch Workspace App    files=${files}
    # The pointer is put away: over the Save button it has a tooltip, which covers the line that says how many there are.
    Move Mouse To    600    400
    Wait Until Region Matches    @{WS_PATH_LINE}    3[0O]{2,3}[^0-9]{0,3}[a-z]{3,6}    timeout=15
    Wait Until Region Matches    @{WS_LIST}    q[0O]{2}[0O1l]    timeout=10
    Scroll At    ${WS_ROW_X}    300    -1500
    Sleep    1.0s
    Wait Until Region Matches    @{WS_LIST}    q[0-9OSl]{4}    timeout=6
    Region Should Not Show Text    @{WS_LIST}    q0000

*** Keywords ***
Warning Should Be Shown Under The Title
    [Documentation]    The line that says where the workspace is has a small warning sign (orange) at its end when the
    ...    last read left something out or could not be done as it should; what it says is in its tooltip.
    Region Should Contain Color    0    30    256    18    255    143    0    tolerance=40
    ...    msg=No warning sign at the end of the line under the title
