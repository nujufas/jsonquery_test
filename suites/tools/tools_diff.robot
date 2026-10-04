*** Settings ***
Documentation     Tools window, the Diff JSON page -- see docs/13_tools_window.md.
...               Left and Right documents are compared by value (key order and
...               number notation are not differences) and shown four ways, as
...               tabs in the command row: Documents (the two boxes), Side by side
...               (the two documents line by line, what differs marked red, green
...               and amber, scrolling as one), Changes (a list with JSON
...               Pointers) and Patch (the RFC 6902 patch that turns Left into
...               Right). Compare opens Side by side by itself.
...
...               The side-by-side text is small monospace text, which OCR reads
...               only in part: the cases read plain words and the status bar, check
...               the marks by their colours (pixels), and check exact text through
...               the clipboard (Copy patch, and a click on a difference copying its
...               path).
Resource          ../../resources/tools.resource
Force Tags        tools    diff
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# Two documents that differ in five places: a changed value, an element removed from
# and one added to an array, a member only Left has and one only Right has.
${LEFT_DOC}          {"name":"Ann","tags":["a","b","c"],"n":1,"old":true}
${RIGHT_DOC}         {"name":"Anna","tags":["a","c","d"],"n":1.0,"new":[1,2]}
# Two that differ in two places, far apart: a number and a string, with a long array
# between that is the same.
${LONG_LEFT}         {"a":1,"b":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20],"c":"x"}
${LONG_RIGHT}        {"a":2,"b":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20],"c":"y"}
# The colours of the marks in the strip between the two columns (and in the overview
# strip at the right): changed amber, removed red, added green.
@{CHANGED_RGB}       210    150    40
@{REMOVED_RGB}       220    80     80
@{ADDED_RGB}         152    195    121
@{MARK_COLUMN}       434    76     6      470
# The tints of whole rows: removed (red) and added (green), as the background of the
# line; changed rows are amber (57, 47, 29).
@{REMOVED_TINT}      58     36     36
@{ADDED_TINT}        47     54     42
@{COMPARE_BUTTON}    8      24     60     20

*** Keywords ***
Compare Button Should Be Disabled
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    @{COMPARE_BUTTON}    threshold=150

Compare Button Should Be Enabled
    Get Ink Bounds    @{COMPARE_BUTTON}    threshold=150

*** Test Cases ***
TC-TWIN-007 Diff JSON Shows The Documents Side By Side
    [Documentation]    Two documents compared open side by side, Left on the
    ...    left and Right on the right, each under its heading, with the lines
    ...    of both documents; the Changes tab lists each addition, removal and
    ...    change with its path (an array is aligned by content: the removal of
    ...    "b" and the addition of "d" are two entries, not a change to every
    ...    element; a number written another way, 1 and 1.0, is not a
    ...    difference); the Patch tab has the same difference as a JSON Patch.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${LEFT_DOC}    ${RIGHT_DOC}
    # Comparing opens the side-by-side view by itself, and the tab says how many
    # changes there are.
    Tab Row Should Offer Changes    5
    Diff View Should Be Selected    side_by_side
    # ("Lef": the t of "Left" is read as a k at times.)
    Diff Should Read    Lef
    Diff Should Read    Right
    Diff Should Read    Ann
    Diff Should Read    Anna
    Status Should Read    added
    # Tesseract reads the digit in /tags/1 as a letter, so what is checked in
    # the list is the kind and the place of each entry that it does read; the
    # exact paths are pinned by the window tests in `cargo test`.
    Pick Diff View    changes
    Diff Should Read    Changed /name
    Diff Should Read    Added /tags
    Diff Should Read    Added /new
    Diff Should Read    Removed
    Pick Diff View    patch
    Diff Should Read    replace
    Diff Should Read    remove
    Diff Should Read    /name

TC-DIF-001 Compare Needs Both Documents
    [Documentation]    Compare is dim until both boxes have text: with only Left
    ...    filled, pressing it does nothing -- the page stays on Documents and
    ...    the status bar stays empty.
    [Tags]    p1
    Open Tool    diff
    Compare Button Should Be Disabled
    Paste Into Box    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}    ${LEFT_DOC}
    Compare Button Should Be Disabled
    Press Main Button
    Diff View Should Be Selected    documents
    Region Should Be Plain    0    560    900    18
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    ${RIGHT_DOC}
    Compare Button Should Be Enabled

TC-DIF-002 Documents That Are The Same Are Said To Be
    [Documentation]    Key order and number notation are not differences: {a: 1,
    ...    b: [1, 2]} and {b: [1, 2], a: 1.0} are the same. The status bar says
    ...    "same", the tab "Changes (0)" and the list "The documents are the same".
    [Tags]    p1
    Open Tool    diff
    Compare Documents    {"a":1,"b":[1,2]}    {"b":[1,2],"a":1.0}
    Tab Row Should Offer Changes    0
    Status Should Read    same
    Pick Diff View    changes
    Diff Should Read    documents are the same

TC-DIF-003 Swap Exchanges The Two Documents
    [Documentation]    Swap puts Left in the Right box and Right in the Left box
    ...    (the page is on its Documents view for it, as Swap drops any result).
    [Tags]    p1
    Open Tool    diff
    Paste Into Box    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}    {"one":"platypus"}
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    {"two":"echidna"}
    Click At    ${SWAP_X}    ${COMMAND_Y}
    Sleep    0.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{DIFF_LEFT_BOX}    echidna
    Region Should Contain Text    @{DIFF_RIGHT_BOX}    platypus
    Diff View Should Be Selected    documents

TC-DIF-004 Swap After A Comparison Goes Back To The Documents
    [Documentation]    The old comparison no longer matches the boxes once they
    ...    are swapped: the result goes, and the page is on Documents.
    [Tags]    p2
    Open Tool    diff
    Compare Documents    ${LEFT_DOC}    ${RIGHT_DOC}
    Tab Row Should Offer Changes    5
    Click At    ${SWAP_X}    ${COMMAND_Y}
    Sleep    0.5s
    Diff View Should Be Selected    documents
    Tab Row Should Not Offer Changes
    Region Should Be Plain    0    560    900    18

TC-DIF-005 The Changes List Names Each Difference
    [Documentation]    Each change is a row: its kind (Changed, Removed, Added), its
    ...    JSON Pointer and its value -- both values for a change ("Ann" ->
    ...    "Anna"). An element put into an array is one addition, not a change to
    ...    all that follow.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    [1,2,3]    [1,9,2,3]
    Tab Row Should Offer Changes    1
    Status Should Read    1 added
    Pick Diff View    changes
    Diff Should Read    Added /1
    Region Should Not Contain Text    @{DIFF_BODY}    Changed

TC-DIF-006 A Document Of Another Kind Replaces The Whole
    [Documentation]    An array against an object is one change at the root.
    [Tags]    p2
    Open Tool    diff
    Compare Documents    [1]    {"a":1}
    Tab Row Should Offer Changes    1
    Status Should Read    1 changed
    Pick Diff View    changes
    Diff Should Read    Changed

TC-DIF-007 Walking The Differences
    [Documentation]    The arrows in the command row (and Alt+Down/Alt+Up) step
    ...    to the next and the previous difference, and the status bar says
    ...    "Difference 1 of 2": next, next, previous.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${LONG_LEFT}    ${LONG_RIGHT}
    Tab Row Should Offer Changes    2
    Click At    ${NEXT_X}    ${COMMAND_Y}
    Difference Should Be    1
    Click At    ${NEXT_X}    ${COMMAND_Y}
    Difference Should Be    2
    Click At    ${PREVIOUS_X}    ${COMMAND_Y}
    Difference Should Be    1

TC-DIF-008 The Keyboard Walks The Differences Too
    [Documentation]    Alt+Down is "next difference" and Alt+Up "previous", with
    ...    the focus anywhere in the window.
    [Tags]    p2
    Open Tool    diff
    Compare Documents    ${LONG_LEFT}    ${LONG_RIGHT}
    Tab Row Should Offer Changes    2
    Press Keys    alt    down
    Difference Should Be    1
    Press Keys    alt    down
    Difference Should Be    2
    Press Keys    alt    up
    Difference Should Be    1

TC-DIF-009 Differences Only Folds What Is The Same
    [Documentation]    The "Differences only" checkbox folds the long run of the
    ...    same lines into one row that counts them ("... 16 lines are the
    ...    same"), keeping a few lines around each difference; unchecking
    ...    shows everything again.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${LONG_LEFT}    ${LONG_RIGHT}
    Tab Row Should Offer Changes    2
    Region Should Not Contain Text    @{SBS_LEFT}    lines are the same
    Click At    ${ONLY_DIFFERENCES_X}    ${HEADER_Y}
    Sleep    0.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{DIFF_BODY}    16 lines are the same
    Click At    ${ONLY_DIFFERENCES_X}    ${HEADER_Y}
    Sleep    0.5s
    Region Should Not Contain Text    @{DIFF_BODY}    lines are the same

TC-DIF-010 Clicking A Difference Copies Its Path
    [Documentation]    A click on a marked row copies the JSON Pointer of that
    ...    difference ("/a" for the first row of the long documents, "/c" for
    ...    the last) and the status bar says so.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${LONG_LEFT}    ${LONG_RIGHT}
    Tab Row Should Offer Changes    2
    Set Clipboard    nothing was copied
    Click At    120    100
    Sleep    0.5s
    ${path}=    Get Clipboard
    Should Be Equal    ${path}    /a
    Status Should Read    Copied the path
    Click At    120    490
    Sleep    0.5s
    ${path}=    Get Clipboard
    Should Be Equal    ${path}    /c

TC-DIF-011 Copy Patch Gives The Whole Patch
    [Documentation]    Copy patch puts the RFC 6902 patch that turns Left into
    ...    Right on the clipboard, one operation to a line, exactly as the
    ...    Patch tab shows it -- from the side-by-side view, where it was
    ...    pressed without looking at the patch.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${LONG_LEFT}    ${LONG_RIGHT}
    Tab Row Should Offer Changes    2
    ${nl}=    Evaluate    chr(10)
    ${expected}=    Catenate    SEPARATOR=${nl}
    ...    [
    ...    \ \ {"op": "replace", "path": "/a", "value": 2},
    ...    \ \ {"op": "replace", "path": "/c", "value": "y"}
    ...    ]
    Copy Should Give    ${COPY_PATCH_X}    ${COMMAND_Y}    ${expected}
    Status Should Read    Copied the patch

TC-DIF-012 Copy Patch Works From Every View
    [Documentation]    Copy patch is at the right end of the command row on every
    ...    view that has a result: the Changes and Patch tabs give the same text.
    [Tags]    p2
    Open Tool    diff
    Compare Documents    ${LONG_LEFT}    ${LONG_RIGHT}
    Tab Row Should Offer Changes    2
    ${nl}=    Evaluate    chr(10)
    ${expected}=    Catenate    SEPARATOR=${nl}
    ...    [
    ...    \ \ {"op": "replace", "path": "/a", "value": 2},
    ...    \ \ {"op": "replace", "path": "/c", "value": "y"}
    ...    ]
    Pick Diff View    changes
    Copy Should Give    ${COPY_PATCH_X}    ${COMMAND_Y}    ${expected}
    Pick Diff View    patch
    Copy Should Give    ${COPY_PATCH_X}    ${COMMAND_Y}    ${expected}

TC-DIF-013 Copy Patch Is Dim Until There Is A Patch
    [Documentation]    Before a comparison (and after an edit) there is no patch:
    ...    pressing Copy patch copies nothing.
    [Tags]    p2
    Open Tool    diff
    Paste Into Box    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}    ${LEFT_DOC}
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    ${RIGHT_DOC}
    Copy Should Do Nothing    ${COPY_PATCH_X}    ${COMMAND_Y}

TC-DIF-014 Editing A Document Drops The Comparison
    [Documentation]    A comparison that no longer matches the boxes is not left
    ...    on show: typing in Left after Compare takes the page back to Documents,
    ...    the Changes tab loses its count and the status bar its summary.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${LONG_LEFT}    ${LONG_RIGHT}
    Tab Row Should Offer Changes    2
    Pick Diff View    documents
    Click At    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}
    Press Keys    ctrl    end
    Type Text    ${SPACE}
    Sleep    0.5s
    Diff View Should Be Selected    documents
    Tab Row Should Not Offer Changes
    Region Should Be Plain    0    560    900    18

TC-DIF-015 A Second Comparison Replaces The First
    [Documentation]    Compare can be pressed again after an edit: the page
    ...    compares the new text (a regression guard -- the first version of
    ...    this page dropped the second request).
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${LONG_LEFT}    ${LONG_RIGHT}
    Tab Row Should Offer Changes    2
    Pick Diff View    documents
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    ${LONG_LEFT}
    Press Main Button
    Tab Row Should Offer Changes    0
    Status Should Read    same

TC-DIF-016 The Marks Have Their Colours
    [Documentation]    Removed lines are red, added green and changed amber, in
    ...    the strip between the two columns: a document with one of each shows
    ...    all three colours there.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    {"keep":1,"gone":2,"edit":3}    {"keep":1,"edit":4,"fresh":5}
    Tab Row Should Offer Changes    3
    Region Should Contain Color    @{MARK_COLUMN}    @{CHANGED_RGB}
    Region Should Contain Color    @{MARK_COLUMN}    @{REMOVED_RGB}
    Region Should Contain Color    @{MARK_COLUMN}    @{ADDED_RGB}
    # And the right colours are on the right rows: what Left alone has (the removed
    # member) is tinted red in the Left column, what Right alone has (the added one)
    # green in the Right column, and neither has the other's tint.
    ${removed_on_left}=    Get Rows With Color    @{SBS_LEFT}    @{REMOVED_TINT}    tolerance=3
    ${added_on_right}=    Get Rows With Color    @{SBS_RIGHT}    @{ADDED_TINT}    tolerance=3
    Should Not Be Empty    ${removed_on_left}    msg=No red row in the Left column
    Should Not Be Empty    ${added_on_right}    msg=No green row in the Right column
    ${added_on_left}=    Get Rows With Color    @{SBS_LEFT}    @{ADDED_TINT}    tolerance=3
    ${removed_on_right}=    Get Rows With Color    @{SBS_RIGHT}    @{REMOVED_TINT}    tolerance=3
    Should Be Empty    ${added_on_left}    msg=A green row in the Left column
    Should Be Empty    ${removed_on_right}    msg=A red row in the Right column

TC-DIF-017 A Change Alone Is Only Amber
    [Documentation]    Companion to the above: with a changed value and nothing
    ...    else, neither red nor green is drawn.
    [Tags]    p2
    Open Tool    diff
    Compare Documents    {"keep":1,"edit":3}    {"keep":1,"edit":4}
    Tab Row Should Offer Changes    1
    Region Should Contain Color    @{MARK_COLUMN}    @{CHANGED_RGB}
    Region Should Not Contain Color    @{MARK_COLUMN}    @{REMOVED_RGB}
    Region Should Not Contain Color    @{MARK_COLUMN}    @{ADDED_RGB}

TC-DIF-018 A Left Document That Is Not JSON Is Named
    [Documentation]    The error says which box it is in ("Left: parsing JSON
    ...    ...") and where, in red, where the comparison would be.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    {"a":    ${RIGHT_DOC}
    Diff Should Read    Left
    Diff Should Read    parsing JSON

TC-DIF-019 A Right Document That Is Not JSON Is Named
    [Documentation]    Likewise for the Right box.
    [Tags]    p2
    Open Tool    diff
    Compare Documents    ${LEFT_DOC}    [1,2
    Diff Should Read    Right
    Diff Should Read    parsing JSON

TC-DIF-020 The Two Columns Scroll As One
    [Documentation]    A long comparison scrolls both columns together: after the
    ...    wheel has taken the view down to the changed line at the end, that
    ...    line (amber) is at the same height in the left and the right
    ...    column.
    [Tags]    p1
    ${left}=    Evaluate    '{"list":[' + ','.join(str(i) for i in range(1, 91)) + '],"end":"x"}'
    ${right}=    Evaluate    '{"list":[' + ','.join(str(i) for i in range(1, 91)) + '],"end":"y"}'
    Open Tool    diff
    Compare Documents    ${left}    ${right}
    Tab Row Should Offer Changes    1
    Scroll At    300    300    -40
    Sleep    0.8s
    Changed Rows Should Line Up

TC-DIF-021 The Open Document Can Be One Of The Two
    [Documentation]    "Open document" in the Left header takes the document open
    ...    in the main window as Left, and the comparison runs on it.
    [Tags]    p1
    Load Fixture Via Paste    {"x":1,"y":"platypus"}
    Open Tool    diff
    Click At    ${OPEN_DOCUMENT_X}    ${DIFF_HEADER_Y}
    Sleep    0.5s
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    {"x":2,"y":"platypus"}
    Press Main Button
    Tab Row Should Offer Changes    1
    Diff Should Read    platypus

TC-DIF-022 Clear Empties A Box
    [Documentation]    Clear in a box's header empties just that box and Compare
    ...    is dim again.
    [Tags]    p2
    Open Tool    diff
    Paste Into Box    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}    {"left":"platypus"}
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    {"right":"echidna"}
    Compare Button Should Be Enabled
    Click At    ${CLEAR_X}    ${DIFF_HEADER_Y}
    Sleep    0.5s
    Region Should Not Contain Text    @{DIFF_LEFT_BOX}    platypus
    Region Should Contain Text    @{DIFF_RIGHT_BOX}    echidna
    Compare Button Should Be Disabled

TC-DIF-023 Ctrl+Enter Compares
    [Documentation]    The shortcut runs Compare from a box.
    [Tags]    p2
    Open Tool    diff
    Paste Into Box    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}    {"a":1}
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    {"a":2}
    Press Keys    ctrl    enter
    Tab Row Should Offer Changes    1
