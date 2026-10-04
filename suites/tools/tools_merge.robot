*** Settings ***
Documentation     Tools window, the Merge JSON page with files in it -- see
...               docs/13_tools_window.md. The files are put on the list by
...               DROPPING them (on the main window, when there are several, or on
...               the Tools window): the harness drags and drops files for real with
...               an XDND source (`Drop Files On Window`, resources/xdnd.py),
...               which is what the native "Add files…" dialog -- blocked here --
...               would have been. The list can be reordered, sorted, trimmed; a jq
...               filter (a preset, or one's own) is run over the files read in that
...               order and slurped into one array (`.`), `$files` being their
...               names; the result can be opened in the main window.
...
...               The fixtures are in resources/fixtures/merge/. Their contents are
...               words rather than numbers where the order matters, because OCR
...               reads words well and small digits badly.
Resource          ../../resources/tools.resource
Library           Collections
Library           String
Force Tags        tools    merge
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${MERGE_FIXTURES}    ${CURDIR}/../../resources/fixtures/merge
# The list of files (a box round its first three rows: a taller one reads as noise),
# its header's buttons (with files in the list, Add files…, Sort A–Z
# and Clear, left to right), and the buttons of a row: move up, move down, remove.
@{FILE_LIST}         8      132    433    64
@{FILES_HEADER}      8      110    433    24
${SORT_X}            366
${CLEAR_FILES_X}     421
${ROW_UP_X}          374
${ROW_DOWN_X}        401
${ROW_REMOVE_X}      428
${FIRST_FILE_Y}      142
${FILE_PITCH}        20
@{MERGE_BUTTON}      8      24     44     20

*** Keywords ***
Open Merge With
    [Documentation]    Drops the files on the main window, which opens the Tools
    ...    window with them on the Merge page (two or more files do; one is
    ...    opened as a document instead), and makes that window the current one.
    [Arguments]    @{names}
    @{paths}=    Create List
    FOR    ${name}    IN    @{names}
        Append To List    ${paths}    ${MERGE_FIXTURES}/${name}
    END
    Drop Files On Window    400    400    @{paths}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Sleep    0.5s

File Rows Should Be
    [Documentation]    The list has this many rows: there is a file name (light grey
    ...    text, which OCR reads as nothing on the grey of a row under the pointer)
    ...    in each of the first `count` rows' places and none in the next.
    [Arguments]    ${count}
    Move Mouse To    700    450
    Sleep    0.4s
    FOR    ${index}    IN RANGE    ${count}
        ${y}=    Evaluate    ${FIRST_FILE_Y} + ${FILE_PITCH} * ${index} - 8
        Get Ink Bounds    40    ${y}    200    16    threshold=100
    END
    ${y}=    Evaluate    ${FIRST_FILE_Y} + ${FILE_PITCH} * ${count} - 8
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    40    ${y}    200    16    threshold=100

Merge Files
    [Documentation]    Presses Merge and waits for the status bar to say it merged.
    Press Main Button
    Status Should Read    Merged

File Row Y
    [Arguments]    ${index}
    ${y}=    Evaluate    ${FIRST_FILE_Y} + ${FILE_PITCH} * ${index}
    RETURN    ${y}

Set Filter
    [Documentation]    Replaces the text of the filter box.
    [Arguments]    ${filter}
    Click At    ${FILTER_BOX_X}    ${FILTER_BOX_Y}
    Sleep    0.2s
    Press Keys    ctrl    a
    Type Text    ${filter}
    Sleep    0.4s

Text Should Come In Order
    [Documentation]    In the OCR of the region, `first` is read before `second`
    ...    (retried: the region may not have been drawn yet).
    [Arguments]    ${first}    ${second}    @{region}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Text Is In Order    ${first}    ${second}    @{region}

Text Is In Order
    [Arguments]    ${first}    ${second}    @{region}
    ${text}=    Read Region Text    @{region}
    ${lower}=    Convert To Lower Case    ${text}
    ${a}=    Convert To Lower Case    ${first}
    ${b}=    Convert To Lower Case    ${second}
    Should Contain    ${lower}    ${a}
    Should Contain    ${lower}    ${b}
    ${i}=    Evaluate    $lower.index($a)
    ${j}=    Evaluate    $lower.index($b)
    Should Be True    ${i} < ${j}    msg=${first} should come before ${second}, but OCR read: ${text}

*** Test Cases ***
TC-MRG-010 Files Dropped On The Main Window Open The Merge Page
    [Documentation]    Several files dropped on the main window (not one, which is
    ...    opened as a document) open the Tools window on its Merge page with the
    ...    files listed in the order they came: "Files (2)" and their names.
    [Tags]    p1
    Open Merge With    platypus.json    echidna.json
    Region Should Contain Text    @{FILES_HEADER}    Files (2
    File Rows Should Be    2

TC-MRG-011 One File Dropped On The Main Window Is Opened
    [Documentation]    A single dropped file is a document: it loads in the main
    ...    window and the Tools window does not open.
    [Tags]    p1
    Drop Files On Window    400    400    ${MERGE_FIXTURES}/platypus.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    1 item
    ${windows}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${windows}    0

TC-MRG-012 Files Dropped On The Tools Window Are Added
    [Documentation]    With the Tools window open on Merge, a file dropped on it
    ...    joins the list (one file is enough here), and a second drop adds to it,
    ...    after the first.
    [Tags]    p1
    Open Tool    merge
    Drop Files On Window    200    300    ${MERGE_FIXTURES}/platypus.json
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{FILES_HEADER}    Files (1
    Drop Files On Window    200    300    ${MERGE_FIXTURES}/echidna.json
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{FILES_HEADER}    Files (2
    Merge Files
    Text Should Come In Order    platypus    echidna    @{MERGE_RESULT}

TC-MRG-013 Append Arrays Joins The Files In Order
    [Documentation]    The default filter, `add`, appends the arrays: ["platypus"]
    ...    and ["echidna"] give both, platypus first; the status bar says how
    ...    many files were merged and how big the answer is.
    [Tags]    p1
    Open Merge With    platypus.json    echidna.json
    Merge Files
    Text Should Come In Order    platypus    echidna    @{MERGE_RESULT}
    Status Should Read    2 files

TC-MRG-014 The Order Of The List Is The Order Of The Merge
    [Documentation]    Moving a file down the list (the ⏷ button of its row) puts it
    ...    after the other in the list and in the result.
    [Tags]    p1
    Open Merge With    platypus.json    echidna.json
    ${y}=    File Row Y    0
    Click At    ${ROW_DOWN_X}    ${y}
    Sleep    0.5s
    Merge Files
    Text Should Come In Order    echidna    platypus    @{MERGE_RESULT}

TC-MRG-015 A File Can Be Taken Off The List
    [Documentation]    The × of a row removes it: "Files (1)", and the merge has
    ...    only the other.
    [Tags]    p1
    Open Merge With    platypus.json    echidna.json
    ${y}=    File Row Y    0
    Click At    ${ROW_REMOVE_X}    ${y}
    Sleep    0.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{FILES_HEADER}    Files (1
    File Rows Should Be    1
    Merge Files
    Region Should Contain Text    @{MERGE_RESULT}    echidna
    Region Should Not Contain Text    @{MERGE_RESULT}    platypus

TC-MRG-016 Clear Empties The List
    [Documentation]    Clear in the Files header takes every file off the list.
    [Tags]    p1
    Open Merge With    platypus.json    echidna.json
    Click At    ${CLEAR_FILES_X}    ${MERGE_HEADER_Y}
    Sleep    0.6s
    File Rows Should Be    0
    Region Should Not Contain Text    @{FILES_HEADER}    (2

TC-MRG-017 Sort A-Z Puts Numbers In Order
    [Documentation]    Sort A–Z orders the list by name with numbers read as
    ...    numbers: part1, part2, part10 -- not part1, part10, part2. The files
    ...    say "one", "two" and "ten", so the merged result shows the order the
    ...    list had: dropped as part10, part1, part2 it is ten, one, two; sorted,
    ...    one, two, ten.
    [Tags]    p1
    Open Merge With    part10.json    part1.json    part2.json
    Merge Files
    Text Should Come In Order    ten    one    @{MERGE_RESULT}
    Click At    ${SORT_X}    ${MERGE_HEADER_Y}
    Sleep    0.6s
    Merge Files
    Text Should Come In Order    one    two    @{MERGE_RESULT}
    Text Should Come In Order    two    ten    @{MERGE_RESULT}

TC-MRG-018 The Same File Is Listed Once
    [Documentation]    Dropping a file that is already on the list adds nothing:
    ...    still "Files (2)".
    [Tags]    p2
    Open Merge With    platypus.json    echidna.json
    Drop Files On Window    200    300    ${MERGE_FIXTURES}/platypus.json
    Sleep    0.8s
    Region Should Contain Text    @{FILES_HEADER}    Files (2
    File Rows Should Be    2

TC-MRG-019 Append Arrays Takes Objects Too
    [Documentation]    `add` on objects combines their keys, the later file winning:
    ...    two files that both have "alpha" give the second's alpha (wombat), not
    ...    both (no koala).
    [Tags]    p2
    Open Merge With    left.json    right.json
    Merge Files
    Region Should Contain Text    @{MERGE_RESULT}    wombat
    Region Should Not Contain Text    @{MERGE_RESULT}    koala

TC-MRG-020 Deep-Merge Keeps What Both Files Have Inside
    [Documentation]    The Deep-merge objects preset merges "alpha" itself: the result
    ...    has koala (from the first file) and wombat (from the second) both.
    [Tags]    p1
    Open Merge With    left.json    right.json
    Click At    ${MERGE_AS_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${MERGE_ITEM_X}    ${MERGE_ITEM_Y}[deep]
    Sleep    0.5s
    Merge Files
    Region Should Contain Text    @{MERGE_RESULT}    koala
    Region Should Contain Text    @{MERGE_RESULT}    wombat

TC-MRG-021 Sorted And De-Duplicated Gives Each Value Once
    [Documentation]    [3,1,3,2] and [2,1] under "Append, sorted and de-duplicated"
    ...    are three values, 1, 2 and 3 -- the status bar says "3 items".
    [Tags]    p1
    Open Merge With    dups_a.json    dups_b.json
    Click At    ${MERGE_AS_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${MERGE_ITEM_X}    ${MERGE_ITEM_Y}[unique]
    Sleep    0.5s
    Merge Files
    Wait Until Region Matches    @{TOOLS_STATUS}    3 ?items    timeout=6

TC-MRG-022 Bundle By File Name Labels Each File
    [Documentation]    The Bundle preset gives {file, data} for each file: the file
    ...    names (via $files) are in the result.
    [Tags]    p1
    Open Merge With    platypus.json    echidna.json
    Click At    ${MERGE_AS_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${MERGE_ITEM_X}    ${MERGE_ITEM_Y}[bundle]
    Sleep    0.5s
    Merge Files
    Region Should Contain Text    @{MERGE_RESULT}    platypus.json
    Region Should Contain Text    @{MERGE_RESULT}    echidna.json

TC-MRG-023 A Filter Of One's Own Runs
    [Documentation]    `.[0]` -- the first file's contents -- gives only platypus.
    [Tags]    p1
    Open Merge With    platypus.json    echidna.json
    Set Filter    .[0]
    Merge Files
    Region Should Contain Text    @{MERGE_RESULT}    platypus
    Region Should Not Contain Text    @{MERGE_RESULT}    echidna

TC-MRG-024 A Filter With Several Outputs Gives An Array Of Them
    [Documentation]    `.[]` gives each file's contents as an output; several
    ...    outputs become one array, here of the two arrays: both words, in the
    ...    order of the files.
    [Tags]    p2
    Open Merge With    platypus.json    echidna.json
    Set Filter    .[]
    Merge Files
    Text Should Come In Order    platypus    echidna    @{MERGE_RESULT}

TC-MRG-025 Adding An Array To An Object Is An Error
    [Documentation]    jq's own error is shown in the Result, in red: an array and an
    ...    object cannot be added.
    [Tags]    p1
    Open Merge With    platypus.json    left.json
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{MERGE_RESULT}    cannot

TC-MRG-026 A File That Is Not JSON Is Named
    [Documentation]    The error names the file that could not be read, and why.
    [Tags]    p1
    Open Merge With    platypus.json    broken.json
    Press Main Button
    # (The error gives the file's whole path; the "." of "broken.json" is read as a gap.)
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{MERGE_RESULT}    broken
    Region Should Contain Text    @{MERGE_RESULT}    pars

TC-MRG-027 A Filter That Gives Nothing Is An Error
    [Documentation]    `empty` produces no output: that is reported, not shown as a
    ...    blank result.
    [Tags]    p2
    Open Merge With    platypus.json    echidna.json
    Set Filter    empty
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{MERGE_RESULT}    output

TC-MRG-028 A Filter That Never Stops Is Cut Off
    [Documentation]    `repeat(1)` would give outputs forever: the merge stops at
    ...    a million of them and says so ("produced more than 1000000 outputs").
    [Tags]    p2
    Open Merge With    platypus.json    echidna.json
    Set Filter    repeat(1)
    Press Main Button
    Wait Until Keyword Succeeds    12x    1s
    ...    Region Should Contain Text    @{MERGE_RESULT}    1000000

TC-MRG-029 Open In Main Window Makes It The Document
    [Documentation]    "Open in main window" loads the merged document into the main
    ...    window: the toolbar says "(merged from 2 files)" and the Source tree
    ...    has it (an array of two items).
    [Tags]    p1
    Open Merge With    platypus.json    echidna.json
    Merge Files
    Click At    ${OPEN_IN_MAIN_X}    ${MERGE_HEADER_Y}
    Switch To Main Window
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_AREA}    merged
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    2 items

TC-MRG-030 Changing The Files Drops The Result
    [Documentation]    A result that no longer matches the files is not left on show:
    ...    taking a file off the list clears the result and the status bar.
    [Tags]    p1
    Open Merge With    platypus.json    echidna.json
    Merge Files
    Region Should Contain Text    @{MERGE_RESULT}    platypus
    ${y}=    File Row Y    0
    Click At    ${ROW_REMOVE_X}    ${y}
    Sleep    0.6s
    Region Should Not Contain Text    @{MERGE_RESULT}    echidna
    Status Should Not Read    Merged

TC-MRG-031 Changing The Filter Drops The Result
    [Documentation]    Likewise editing the filter box.
    [Tags]    p2
    Open Merge With    platypus.json    echidna.json
    Merge Files
    Region Should Contain Text    @{MERGE_RESULT}    platypus
    Set Filter    .[0]
    Region Should Not Contain Text    @{MERGE_RESULT}    echidna
    Status Should Not Read    Merged

TC-MRG-032 Ctrl+Enter Merges
    [Documentation]    The shortcut runs Merge from anywhere in the window.
    [Tags]    p2
    Open Merge With    platypus.json    echidna.json
    Press Keys    ctrl    enter
    Status Should Read    Merged

TC-MRG-033 The Merge Button Is Bright With Files
    [Documentation]    Merge is dim with an empty list and bright once there are
    ...    files.
    [Tags]    p2
    Open Tool    merge
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    @{MERGE_BUTTON}    threshold=150
    Drop Files On Window    200    300    ${MERGE_FIXTURES}/platypus.json
    Sleep    0.8s
    Get Ink Bounds    @{MERGE_BUTTON}    threshold=150

TC-MRG-034 Big Numbers Keep Their Digits
    [Documentation]    An integer too big for a double is merged with every digit.
    [Tags]    p2
    Open Merge With    bignum.json    part1.json
    Merge Files
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{MERGE_RESULT}    1234567890
