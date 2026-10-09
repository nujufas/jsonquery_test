*** Settings ***
Documentation     Tools window, the Diff JSON page -- see docs/13_tools_window.md.
...               Left and Right documents are compared by value (key order and
...               number notation are not differences) and shown four ways, as
...               tabs in the command row: Documents (the two boxes), Side by side
...               (the two documents line by line, what differs marked red, green
...               and amber, scrolling as one), Changes (a list with JSON
...               Pointers) and Patch (the RFC 6902 patch that turns Left into
...               Right). Compare opens Side by side by itself, and so does the tab
...               of any of the three views when the documents have not been compared.
...               Between the two columns of Side by side each difference has two
...               arrows that move it into the document they point at; a click picks
...               a line (Ctrl adds, Shift goes on, a drag runs over several) and then
...               the arrows, the buttons of the command row and the menu of a line
...               move only the lines that are picked, and a double click puts a caret in
...               the line, on either side, to type over it (Enter puts it in, Esc puts it
...               back); each column has a Save… for a document a move or an edit changed.
...               After a move the view stays where it was: it does not go on to the next
...               difference.
...
...               The side-by-side text is small monospace text, which OCR reads
...               only in part: the cases read plain words and the status bar, check
...               the marks by their colours (pixels), and check exact text through
...               the clipboard (Copy patch, which says what is left to differ after a
...               move, and the menu of a line copying its path).
Resource          ../../resources/tools.resource
Resource          ../../resources/results.resource
Library           OperatingSystem
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
@{MARK_COLUMN}       436    76     6      470
# The tints of whole rows: removed (red) and added (green), as the background of the
# line; changed rows are amber (57, 47, 29).
@{REMOVED_TINT}      58     36     36
@{ADDED_TINT}        47     54     42
@{COMPARE_BUTTON}    8      24     60     20
# Four changes in a row (one difference of the view: rows 1 to 4, the lines a, b, c and d)...
${FOUR_LEFT}         {"a":1,"b":2,"c":3,"d":4}
${FOUR_RIGHT}        {"a":9,"b":8,"c":7,"d":6}
# ...and two separate ones, with a line that is the same between (a is row 1, b is row 3).
${TWO_LEFT}          {"a":1,"s":0,"b":2}
${TWO_RIGHT}         {"a":9,"s":0,"b":8}
# What the colours say: a line that is picked has the selection colour over it.
@{PICKED_TINT}       26     72     83
${OPEN_FILE_X}       248
# Two that differ in b, which is row 2 of the view (row 0 is the bracket that opens them)...
${EDIT_LEFT}         {"a":1,"b":2}
${EDIT_RIGHT}        {"a":1,"b":3}

*** Keywords ***
File Should Hold Json
    [Documentation]    The file (written by the worker, a moment after the dialog returns)
    ...    holds this JSON value, however it is laid out.
    [Arguments]    ${path}    ${expected}
    Wait Until Keyword Succeeds    15x    0.4s    File Json Should Be    ${path}    ${expected}

File Json Should Be
    [Arguments]    ${path}    ${expected}
    ${text}=    Get File    ${path}    encoding=UTF-8
    ${actual}=    Evaluate    json.loads($text)    modules=json
    ${wanted}=    Evaluate    json.loads($expected)    modules=json
    Should Be Equal    ${actual}    ${wanted}

Status Should Say Picked
    [Documentation]    The status bar counts the lines that are picked ("1 line picked", "2 lines
    ...    picked"); read loosely, as Tesseract drops the spaces of text this small.
    [Arguments]    ${count}
    ${noun}=    Set Variable If    '${count}' == '1'    lines?    lines
    Wait Until Region Matches    @{TOOLS_STATUS}    ${count}\\W{0,3}${noun}\\W{0,3}picked    timeout=8

Left Label Right Edge
    [Documentation]    How far right the quiet label over the Left column reaches ("orders.json
    ...    · 4 lines", "orders.json (changed) · 4 lines"): OCR cannot read grey text that
    ...    small, but a label that says more is longer.
    ${bounds}=    Get Ink Bounds    58    56    300    14    threshold=70
    RETURN    ${bounds}[2]

Type Over Line
    [Documentation]    Double-click the text of row `row` of a column (`x` is somewhere on its text), take
    ...    all that is in the line and type `text` over it. Nothing is put in until Enter.
    [Arguments]    ${x}    ${row}    ${text}
    ${y}=    Sbs Row Y    ${row}
    Double Click At    ${x}    ${y}
    Press Keys    ctrl    a
    Type Text    ${text}

Press Enter
    Press Key    enter
    Sleep    0.4s

Status Should Say
    [Documentation]    The status bar says this, read loosely (Tesseract drops the spaces of text that
    ...    small): a regular expression, retried while the worker answers.
    [Arguments]    ${pattern}
    Wait Until Region Matches    @{TOOLS_STATUS}    ${pattern}    timeout=8

Left Column Should Read
    [Documentation]    OCR of the left column of the side-by-side view alone (retried).
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SBS_LEFT}    ${text}

Right Column Should Read
    [Documentation]    OCR of the right column of the side-by-side view alone (retried).
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SBS_RIGHT}    ${text}

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
    Left Column Should Read    Ann
    Right Column Should Read    Ann
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

TC-DIF-010 The Menu Of A Line Copies The Path Of Its Difference
    [Documentation]    A click on a marked row picks the line (and says so) and takes
    ...    nothing from the clipboard; its right-click menu has Copy path, which puts the
    ...    JSON Pointer of that difference on the clipboard ("/a" for the first row of
    ...    the long documents, "/c" for the last) and the status bar says so.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${LONG_LEFT}    ${LONG_RIGHT}
    Tab Row Should Offer Changes    2
    Set Clipboard    nothing was copied
    Click At    120    100
    Sleep    0.5s
    ${kept}=    Get Clipboard
    Should Be Equal    ${kept}    nothing was copied
    Status Should Say Picked    1
    Right Click At    120    100
    Sleep    0.5s
    Click At    158    167
    Sleep    0.5s
    ${path}=    Get Clipboard
    Should Be Equal    ${path}    /a
    Status Should Read    Copied the path
    Right Click At    120    490
    Sleep    0.5s
    Click At    158    557
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
    # the line with platypus on it (row 2) and the one under it: a band, as the whole column
    # is mostly empty, which Tesseract reads worse
    ${y}=    Sbs Row Y    2
    ${top}=    Evaluate    ${y} - 9
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    8    ${top}    416    40    platypus

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

TC-DIF-024 A View Compares The Documents When It Is Asked For, Without Compare
    [Documentation]    With both boxes filled and nothing compared, the tab of Side by
    ...    side, Changes or Patch compares them and shows that view: the count appears on
    ...    the Changes tab and the status bar says what differs, all without Compare being
    ...    pressed. A comparison that was made is not made again by going to another view.
    [Tags]    p0
    Open Tool    diff
    Paste Into Box    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}    ${LEFT_DOC}
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    ${RIGHT_DOC}
    Pick Diff View    side_by_side
    Tab Row Should Offer Changes    5
    Diff View Should Be Selected    side_by_side
    Left Column Should Read    Ann
    Status Should Read    added
    # The other two views, from the documents: a change to a box drops the comparison, and the
    # tab that is asked for makes it again.
    Pick Diff View    documents
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    {"name":"Ann","n":2}
    Tab Row Should Not Offer Changes
    Pick Diff View    changes
    Tab Row Should Offer Changes    3
    Diff View Should Be Selected    changes
    Diff Should Read    Changed /n
    Pick Diff View    documents
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    {"name":"Ann"}
    Pick Diff View    patch
    Tab Row Should Offer Changes    3
    Diff View Should Be Selected    patch
    Diff Should Read    remove

TC-DIF-025 A View Has Nothing To Compare Until Both Documents Are There
    [Documentation]    With only one box filled the tab of a view compares nothing and says
    ...    what is missing; once the other box is filled, it compares.
    [Tags]    p1
    Open Tool    diff
    Paste Into Box    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}    ${LEFT_DOC}
    Pick Diff View    side_by_side
    Diff Should Read    both boxes
    Tab Row Should Not Offer Changes
    Pick Diff View    documents
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    ${RIGHT_DOC}
    Pick Diff View    side_by_side
    Tab Row Should Offer Changes    5

TC-DIF-026 The Arrows In The Gutter Move A Difference Into The Document They Point At
    [Documentation]    Each difference has two arrows between the columns, at its first line:
    ...    the one at the left points to the Left document, which takes what Right has
    ...    there, the other to Right. One press moves the difference and compares again;
    ...    what is left is read from the patch.
    [Tags]    p0
    Open Tool    diff
    Compare Documents    ${TWO_LEFT}    ${TWO_RIGHT}
    Tab Row Should Offer Changes    2
    # The second difference (b, row 3) into Right: Right takes b=2, and a is what differs.
    Click Arrow To Right    3
    Tab Row Should Offer Changes    1
    Status Should Read    Moved the difference to the right
    Patch Should Replace    /a=9
    # The first one into Left: Left takes a=9, and the two are the same.
    Click Arrow To Left    1
    Tab Row Should Offer Changes    0
    Status Should Read    same
    Status Should Read    Moved the difference to the left
    Patch Should Be Empty

TC-DIF-027 A Line That Is Picked Is Moved By Itself, And The Rest Of Its Difference Stays
    [Documentation]    Four changes in a row are one difference. A click picks the line b
    ...    (it has the selection colour over it, and the status bar counts it); the arrow
    ...    of the difference then moves b alone, and a, c and d still differ.
    [Tags]    p0
    Open Tool    diff
    Compare Documents    ${FOUR_LEFT}    ${FOUR_RIGHT}
    Tab Row Should Offer Changes    4
    ${b}=    Sbs Row Y    2
    Click At    120    ${b}
    Status Should Say Picked    1
    Region Should Contain Color    @{SBS_RIGHT}    @{PICKED_TINT}    tolerance=3
    Click Arrow To Right    1
    Tab Row Should Offer Changes    3
    Status Should Read    Moved the picked lines to the right
    Patch Should Replace    /a=9    /c=7    /d=6

TC-DIF-028 With Nothing Picked The Arrow Moves The Whole Difference
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${FOUR_LEFT}    ${FOUR_RIGHT}
    Tab Row Should Offer Changes    4
    Click Arrow To Left    1
    Tab Row Should Offer Changes    0
    Status Should Read    same

TC-DIF-029 Ctrl Adds A Line To Those Picked And Takes It Away, And Shift Picks A Run
    [Documentation]    Ctrl+click on b and then d picks the two (the status bar says "2 lines
    ...    picked") and the arrow moves those two; Ctrl+click on a picked line lets it go;
    ...    a click on a, then Shift+click on c, picks the run a, b and c. A click on the first
    ...    line, which is the same on both sides, lets go of them all.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${FOUR_LEFT}    ${FOUR_RIGHT}
    ${a}=    Sbs Row Y    1
    ${b}=    Sbs Row Y    2
    ${c}=    Sbs Row Y    3
    ${d}=    Sbs Row Y    4
    ${bracket}=    Sbs Row Y    0
    Click At    120    ${b}
    Click At While Holding    120    ${d}    ctrl
    Status Should Say Picked    2
    Click At While Holding    120    ${d}    ctrl
    Status Should Say Picked    1
    Click At While Holding    120    ${d}    ctrl
    Status Should Say Picked    2
    Click At    120    ${bracket}
    Status Should Not Read    picked
    Click At    120    ${a}
    Click At While Holding    120    ${c}    shift
    Status Should Say Picked    3
    Click Arrow To Right    1
    Tab Row Should Offer Changes    1
    Patch Should Replace    /d=6

TC-DIF-030 A Drag Over Lines Picks Them, And Escape Lets Them Go
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${FOUR_LEFT}    ${FOUR_RIGHT}
    ${b}=    Sbs Row Y    2
    ${c}=    Sbs Row Y    3
    Drag Mouse    120    ${b}    120    ${c}
    Status Should Say Picked    2
    Press Keys    escape
    Sleep    0.4s
    Status Should Not Read    picked
    # picked again, the buttons of the command row move what is picked
    Drag Mouse    120    ${b}    120    ${c}
    Status Should Say Picked    2
    Click At    ${MOVE_RIGHT_X}    ${COMMAND_Y}
    Tab Row Should Offer Changes    2
    Patch Should Replace    /a=9    /d=6

TC-DIF-031 The Menu Of A Line Moves The Lines That Are Picked, In Every Difference
    [Documentation]    a and b are two differences (a line that is the same lies between). a
    ...    is picked, b is added with Ctrl, and Move to the right in the menu of b moves both.
    [Tags]    p2
    Open Tool    diff
    Compare Documents    ${TWO_LEFT}    ${TWO_RIGHT}
    Tab Row Should Offer Changes    2
    ${a}=    Sbs Row Y    1
    ${b}=    Sbs Row Y    3
    Click At    120    ${a}
    Click At While Holding    120    ${b}    ctrl
    Right Click At    120    ${b}
    Sleep    0.5s
    # Move to the right is the second item of the menu, under the line
    ${item}=    Evaluate    ${b} + 37
    Click At    150    ${item}
    Tab Row Should Offer Changes    0
    Patch Should Be Empty

TC-DIF-032 A Document That A Move Changed Says So, And Each Save Writes Its Own Document
    [Documentation]    Left is a file, Right is typed and has one more member. After a move
    ...    the Left document is called by its file with "(changed)" and is not Right (which
    ...    still has the member). Its Save… (over its column) asks for a file, proposing
    ...    the name of the file it came from in that file's folder; the file written holds
    ...    what the move made, the original is as it was, and once saved the document is
    ...    no longer said to be changed. Right's Save… proposes right.json (it came from
    ...    nowhere) and writes Right.
    [Tags]    p0
    ${dir}=    Make Temp Directory
    ${out}=    Make Temp Directory
    ${out2}=    Make Temp Directory
    Create File    ${dir}${/}orders.json    {"a":1,"b":2,"s":0}
    Open Tool    diff
    ${before}=    Portal Request Count
    Portal Will Pick    ${dir}${/}orders.json
    Click At    ${OPEN_FILE_X}    ${DIFF_HEADER_Y}
    Wait For Dialog After    ${before}
    Sleep    0.5s
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    {"a":1,"b":3,"s":0,"c":4}
    Press Main Button
    Tab Row Should Offer Changes    2
    ${plain}=    Left Label Right Edge
    # b (row 2) into Left, which is then the same as Right but for the member c
    Click Arrow To Left    2
    Tab Row Should Offer Changes    1
    ${changed}=    Left Label Right Edge
    Should Be True    ${changed} > ${plain} + 40    The label does not say the document is changed
    # Save… asks where, proposing the file's name and folder
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${out}
    Click At    ${DIFF_LEFT_SAVE_X}    63
    ${request}=    Wait For Dialog After    ${before}
    Should Be Equal    ${request}[current_name]    orders.json
    Should Contain    ${request}[current_folder]    ${dir}
    Status Should Read    Saved to
    File Should Hold Json    ${out}${/}orders.json    {"a":1,"b":3,"s":0}
    File Should Be    ${dir}${/}orders.json    {"a":1,"b":2,"s":0}
    ${saved}=    Left Label Right Edge
    Should Be True    abs(${saved} - ${plain}) < 8    The label still says the document is changed
    # Right came from nowhere: right.json, and its own text
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${out2}
    Click At    ${DIFF_RIGHT_SAVE_X}    63
    ${request}=    Wait For Dialog After    ${before}
    Should Be Equal    ${request}[current_name]    right.json
    File Should Hold Json    ${out2}${/}right.json    {"a":1,"b":3,"s":0,"c":4}

TC-DIF-033 A Double Click Puts A Caret In A Line, And Enter Puts What Was Typed In
    [Documentation]    A double click on a line puts a caret in it, on the side that was
    ...    clicked, and the status bar says so. What is typed takes the place of the line when
    ...    Enter is pressed: the document is changed (and says so), the comparison is made again,
    ...    and the other document is as it was. Save… writes what was typed.
    [Tags]    p0
    ${out}=    Make Temp Directory
    Open Tool    diff
    Compare Documents    ${EDIT_LEFT}    ${EDIT_RIGHT}
    Tab Row Should Offer Changes    1
    ${plain}=    Left Label Right Edge
    Type Over Line    ${LEFT_TEXT_X}    2    "b": 3
    Status Should Say    Editing\\W{0,3}line\\W{0,3}3
    Press Enter
    Tab Row Should Offer Changes    0
    Status Should Say    Changed\\W{0,3}line\\W{0,3}3
    Patch Should Be Empty
    ${changed}=    Left Label Right Edge
    Should Be True    ${changed} > ${plain} + 40    The label does not say the document is changed
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${out}
    Click At    ${DIFF_LEFT_SAVE_X}    63
    Wait For Dialog After    ${before}
    Status Should Read    Saved to
    File Should Hold Json    ${out}${/}left.json    {"a":1,"b":3}

TC-DIF-034 The Right Column Is Typed Over Too, And Escape Puts The Line Back
    [Documentation]    A line of the right column is typed over the same way. Esc puts the line back
    ...    as it was: nothing is changed, and the two still differ in b.
    [Tags]    p0
    Open Tool    diff
    Compare Documents    ${EDIT_LEFT}    ${EDIT_RIGHT}
    Type Over Line    ${RIGHT_TEXT_X}    2    "b": 2
    Status Should Say    Editing\\W{0,3}line\\W{0,3}3\\W{0,3}of\\W{0,3}Right
    Press Keys    escape
    Sleep    0.5s
    Status Should Not Read    Editing
    Patch Should Replace    /b=3
    # again, and this time Enter
    Type Over Line    ${RIGHT_TEXT_X}    2    "b": 2
    Press Enter
    Tab Row Should Offer Changes    0
    Status Should Say    Changed\\W{0,3}line\\W{0,3}3\\W{0,3}of\\W{0,3}the\\W{0,3}right
    Patch Should Be Empty

TC-DIF-035 What Is Not JSON Is Said And Stays To Be Put Right
    [Documentation]    "b": and nothing after the colon is no JSON: the status bar says so, in red,
    ...    the line keeps its caret and the documents are as they were. Typing the rest (3, which
    ...    is what Right has) and Enter puts it in: the two are the same.
    [Tags]    p0
    Open Tool    diff
    Compare Documents    ${EDIT_LEFT}    ${EDIT_RIGHT}
    Type Over Line    ${LEFT_TEXT_X}    2    "b":${SPACE}
    Press Enter
    Status Should Say    Not\\W{0,3}valid\\W{0,3}JSON
    Patch Should Replace    /b=3
    Type Text    3
    Press Enter
    Tab Row Should Offer Changes    0
    Status Should Read    same

TC-DIF-036 A Line Is Taken Out By Typing Nothing, And Several Are Put In By Typing Them
    [Documentation]    Nothing typed takes the line out of the document; two members typed with a
    ...    comma between them take the place of the one that was there.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${EDIT_LEFT}    ${EDIT_RIGHT}
    ${y}=    Sbs Row Y    1
    Double Click At    ${LEFT_TEXT_X}    ${y}
    Press Keys    ctrl    a
    Press Key    backspace
    Press Enter
    Status Should Say    Took\\W{0,3}line\\W{0,3}2\\W{0,3}out
    Tab Row Should Offer Changes    2
    # b is in row 2 still (the line Right has and Left has not is blank on the left)
    Type Over Line    ${LEFT_TEXT_X}    2    "b": 3, "a": 1
    Press Enter
    Tab Row Should Offer Changes    0
    Status Should Read    same

TC-DIF-037 The Name Of A Line That Opens An Object Is Changed And What Is In It Stays
    [Tags]    p1
    Open Tool    diff
    Compare Documents    {"home":{"city":"London"}}    {"home":{"city":"London"}}
    Status Should Read    same
    Type Over Line    ${LEFT_TEXT_X}    1    "address": {
    Press Enter
    Tab Row Should Offer Changes    2
    Status Should Say    Changed\\W{0,3}line\\W{0,3}2

TC-DIF-038 A Line That Closes Something Has No Caret, And A Line Cut Short Says So
    [Tags]    p1
    ${long}=    Evaluate    'x' * 600
    Open Tool    diff
    Compare Documents    {"s":"${long}","n":1}    {"s":"${long}","n":2}
    # the bracket that closes the document
    ${y}=    Sbs Row Y    3
    Double Click At    ${LEFT_TEXT_X}    ${y}
    Sleep    0.5s
    Status Should Not Read    Editing
    # the line that was cut short
    ${y}=    Sbs Row Y    1
    Double Click At    ${LEFT_TEXT_X}    ${y}
    Status Should Say    too\\W{0,3}long\\W{0,3}to\\W{0,3}edit
    Status Should Not Read    Editing

TC-DIF-039 A Click Elsewhere Puts In What Was Typed, And An Arrow Is Not Held Up By A Caret
    [Documentation]    A click on another line takes what was typed (and is not a click on that
    ...    line); a caret in a line where nothing was typed does not stop the arrow of its
    ...    difference from moving it.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${EDIT_LEFT}    ${EDIT_RIGHT}
    Type Over Line    ${LEFT_TEXT_X}    2    "b": 5
    ${y}=    Sbs Row Y    2
    Click At    ${RIGHT_TEXT_X}    ${y}
    Status Should Say    Changed\\W{0,3}line\\W{0,3}3
    Tab Row Should Offer Changes    1
    Patch Should Replace    /b=3
    # a caret and nothing typed, then the arrow of the difference
    Double Click At    ${LEFT_TEXT_X}    ${y}
    Click Arrow To Left    2
    Tab Row Should Offer Changes    0
    Status Should Read    same

TC-DIF-040 A Single Click Only Picks, So That More Lines Can Be Picked After It
    [Documentation]    A click on a line picks it and puts no caret in it, so a Ctrl+click and a
    ...    drag go on picking: Ctrl+click on d makes two lines picked, and a click on a followed
    ...    by a drag over b and c picks those two instead. The status bar never says a line has a
    ...    caret, and the arrow moves what is picked.
    [Tags]    p0
    Open Tool    diff
    Compare Documents    ${FOUR_LEFT}    ${FOUR_RIGHT}
    Tab Row Should Offer Changes    4
    ${a}=    Sbs Row Y    1
    ${b}=    Sbs Row Y    2
    ${c}=    Sbs Row Y    3
    ${d}=    Sbs Row Y    4
    Click At    ${LEFT_TEXT_X}    ${b}
    Status Should Say Picked    1
    Status Should Not Read    Editing
    Click At While Holding    ${LEFT_TEXT_X}    ${d}    ctrl
    Status Should Say Picked    2
    Status Should Not Read    Editing
    Click At    ${LEFT_TEXT_X}    ${a}
    Drag Mouse    ${LEFT_TEXT_X}    ${b}    ${LEFT_TEXT_X}    ${c}
    Status Should Say Picked    2
    Status Should Not Read    Editing
    Click Arrow To Right    1
    Tab Row Should Offer Changes    2
    Status Should Read    Moved the picked lines to the right
    Patch Should Replace    /a=9    /d=6

TC-DIF-041 After A Move The View Stays Where It Was And Picks Nothing
    [Documentation]    Two differences far apart in a long array: the first is near the top, the
    ...    second is a hundred lines down. The arrow of the first moves it, and the view is
    ...    still at the top (the second difference, amber, has not been scrolled to), the status
    ...    bar names no difference as picked, and the second is what Next goes to afterwards.
    [Tags]    p0
    ${left}=    Evaluate    '[' + ','.join(str(7 if n == 5 else 9 if n == 100 else 1000 + n) for n in range(120)) + ']'
    ${right}=    Evaluate    '[' + ','.join(str(8 if n == 5 else 10 if n == 100 else 1000 + n) for n in range(120)) + ']'
    Open Tool    diff
    Compare Documents    ${left}    ${right}
    Tab Row Should Offer Changes    2
    # the first difference is in view, amber
    Region Should Contain Color    @{SBS_LEFT}    57    47    29    tolerance=3
    # element 5 is row 6: its arrow into Right
    Click Arrow To Right    6
    Tab Row Should Offer Changes    1
    Status Should Read    Moved the difference to the right
    Patch Should Replace    /100=10
    # nothing is picked and the view is where it was: the one difference left is far below
    Status Should Not Read    Difference 1 of
    Region Should Not Contain Color    @{SBS_LEFT}    57    47    29    tolerance=3
    # Next goes to it
    Press Keys    alt    down
    Status Should Read    Difference 1 of 1
    Region Should Contain Color    @{SBS_LEFT}    57    47    29    tolerance=3
