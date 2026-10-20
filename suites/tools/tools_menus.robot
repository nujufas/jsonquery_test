*** Settings ***
Documentation     Tools window: the right-click menu of a text -- see docs/24_text_menus.md. The boxes of
...               every page can be typed in and have Cut, Copy, Paste and Select All; a result shown as
...               text (Format's, Patch's) and an error are text that is only shown, with Copy and Select
...               All; the lines of the Diff page's side-by-side view and of its list of changes, and the
...               rows of Validate's list of problems, copy their text, their path or their message.
...
...               The menu opens with its top-left corner at the pointer and its items at fixed distances
...               under it (the first 16 px down, then 21 px apart), so an item is clicked by its distance;
...               OCR is only asked whether the menu is open. What an item did is read exactly, from the
...               clipboard. The menu of a side-by-side line has a separator after its two moves, which
...               puts Copy path 67 px under the pointer, then Copy left line and Copy right line.
Resource          ../../resources/tools.resource
Library           OperatingSystem
Force Tags        tools    text_menus
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${FORMAT_DOC}        {"b":1,"a":[1,2]}
# Two documents that differ in b (row 2 of the side-by-side view, a is row 1): a line the same
# on both sides, and one that differs.
${MENU_LEFT}         {"a":1,"b":2}
${MENU_RIGHT}        {"a":1,"b":3}
# A document with one problem: age is a string.
${MENU_VALUE}        {"age":"old"}
${MENU_SCHEMA}       {"properties":{"age":{"type":"integer"}}}
# A point inside the text of the result pane (its first lines start at its top left).
${RESULT_POINT_X}    480
${RESULT_POINT_Y}    92
# The first row of the list of changes, and a point on its text.
${CHANGE_ROW_X}      120
${CHANGE_ROW_Y}      64
# What an item of a menu is under the point it was opened at (see the Documentation).
${MENU_FIRST_Y}      16
${MENU_PITCH}        21
${MENU_X_OFFSET}     40
${SEPARATED_Y}       67
${MENU_WIDTH}        130
${MENU_HEIGHT}       130

*** Keywords ***
Open Text Menu
    [Documentation]    Right-clicks the point and waits until the menu is on show, which it
    ...    knows by a word that the menu has and is bright: `Paste` for a box that can be typed
    ...    in, `Select All` for a text that is only shown, `Copy` for a line of a list. A right
    ...    click now and then does not register, so it is made again.
    [Arguments]    ${x}    ${y}    ${word}=Paste
    Wait Until Keyword Succeeds    3x    0.4s    Right Click And See Menu    ${x}    ${y}    ${word}

Right Click And See Menu
    [Arguments]    ${x}    ${y}    ${word}
    Right Click At    ${x}    ${y}
    Sleep    0.4s
    ${left}=    Evaluate    int(${x}) + 5
    ${top}=    Evaluate    int(${y}) + 8
    Region Should Contain Text    ${left}    ${top}    ${MENU_WIDTH}    ${MENU_HEIGHT}    ${word}

Pick Menu Item
    [Documentation]    Clicks the item of the menu that was opened at (x, y) that is `offset` pixels
    ...    under the point, and gives the window a moment to do what it says.
    [Arguments]    ${x}    ${y}    ${offset}
    ${at_x}=    Evaluate    int(${x}) + ${MENU_X_OFFSET}
    ${at_y}=    Evaluate    int(${y}) + int(${offset})
    Click At    ${at_x}    ${at_y}
    Sleep    0.6s

Item
    [Documentation]    How far under the point the `row`-th item (0 is the first) of a menu is.
    [Arguments]    ${row}
    ${offset}=    Evaluate    ${MENU_FIRST_Y} + ${MENU_PITCH} * int(${row})
    RETURN    ${offset}

Choose From Text Menu
    [Arguments]    ${x}    ${y}    ${row}    ${word}=Paste
    Open Text Menu    ${x}    ${y}    ${word}
    ${offset}=    Item    ${row}
    Pick Menu Item    ${x}    ${y}    ${offset}

Menu Should Not Offer
    [Arguments]    ${x}    ${y}    @{items}
    ${left}=    Evaluate    int(${x}) + 5
    ${top}=    Evaluate    int(${y}) + 8
    FOR    ${item}    IN    @{items}
        Region Should Not Contain Text    ${left}    ${top}    ${MENU_WIDTH}    ${MENU_HEIGHT}    ${item}
    END

Menu Should Offer
    [Arguments]    ${x}    ${y}    @{items}
    ${left}=    Evaluate    int(${x}) + 5
    ${top}=    Evaluate    int(${y}) + 8
    FOR    ${item}    IN    @{items}
        Region Should Contain Text    ${left}    ${top}    ${MENU_WIDTH}    ${MENU_HEIGHT}    ${item}
    END

Clipboard Should Be
    [Documentation]    The clipboard holds exactly `expected`, once the app has put it there (a
    ...    cut or a copy reaches it a frame or two after the click: polled).
    [Arguments]    ${expected}
    Wait Until Keyword Succeeds    8x    0.3s    Clipboard Equals    ${expected}

Clipboard Equals
    [Arguments]    ${expected}
    ${text}=    Get Clipboard
    Should Be Equal    ${text}    ${expected}

Clipboard Should Start With
    [Arguments]    ${expected}
    Wait Until Keyword Succeeds    8x    0.3s    Clipboard Starts With    ${expected}

Clipboard Starts With
    [Arguments]    ${expected}
    ${text}=    Get Clipboard
    Should Start With    ${text}    ${expected}

Pretty
    [Documentation]    The document as a standard JSON printer lays it out, two spaces to a level.
    [Arguments]    ${text}
    ${out}=    Evaluate    json.dumps(json.loads($text), indent=2)    modules=json
    RETURN    ${out}

Box Should Be Empty
    [Documentation]    Nothing is in the box at (x, y): all of it is taken and copied, and the
    ...    clipboard is still what it was set to (a box with nothing in it copies nothing).
    [Arguments]    ${x}    ${y}
    Set Clipboard    nothing was copied
    Click At    ${x}    ${y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Press Keys    ctrl    c
    Sleep    0.4s
    ${text}=    Get Clipboard
    Should Be Equal    ${text}    nothing was copied

Status Should Say
    [Documentation]    The status bar says this, read loosely (Tesseract drops the spaces of text that
    ...    small): a regular expression, retried while the worker answers.
    [Arguments]    ${pattern}
    Wait Until Region Matches    @{TOOLS_STATUS}    ${pattern}    timeout=8

Press Enter
    Press Key    enter
    Sleep    0.4s

Format The Document
    [Documentation]    The Format page, with the document in its Input box, formatted.
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${FORMAT_DOC}
    Press Main Button
    Status Should Read    was

*** Test Cases ***
TC-TXM-017 Every Box Of The Tools Has The Menu Of A Text Box
    [Documentation]    Right-click in an empty box of each page: Format's Input, Diff's Left and
    ...    Right, Patch's Document and Patch, Validate's Document and Schema, and Merge's filter. The
    ...    menu has Paste in bright text (Cut, Copy and Select All are dim in a box with nothing in it).
    [Tags]    p1
    Open Tool    format
    Open Text Menu    ${FIRST_BOX_X}    ${INPUT_BOX_Y}
    Press Key    escape
    Pick Tool    diff
    Open Text Menu    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}
    Press Key    escape
    Open Text Menu    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}
    Press Key    escape
    Pick Tool    patch
    Open Text Menu    ${FIRST_BOX_X}    ${FIRST_BOX_Y}
    Press Key    escape
    Open Text Menu    ${FIRST_BOX_X}    ${SECOND_BOX_Y}
    Press Key    escape
    Pick Tool    validate
    Open Text Menu    ${FIRST_BOX_X}    ${FIRST_BOX_Y}
    Press Key    escape
    Open Text Menu    ${FIRST_BOX_X}    ${SECOND_BOX_Y}
    Press Key    escape
    Pick Tool    merge
    Open Text Menu    ${FILTER_BOX_X}    ${FILTER_BOX_Y}

TC-TXM-018 Paste In The Menu Of A Box Of A Tool Puts The Clipboard In It
    [Documentation]    The clipboard has a document and Format's Input box is empty: Paste (the
    ...    third item) puts it in the box, and Format gives it laid out.
    [Tags]    p1
    Open Tool    format
    Set Clipboard    ${FORMAT_DOC}
    Choose From Text Menu    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    2
    Press Main Button
    Status Should Read    was
    ${expected}=    Pretty    ${FORMAT_DOC}
    Copy Should Give    ${FORMAT_COPY_X}    ${HEADER_Y}    ${expected}

TC-TXM-019 Select All And Cut In The Menu Of A Box Of A Tool Empty It Into The Clipboard
    [Documentation]    The box has a document. Select All (the fourth item) takes all of it and Cut
    ...    (the first) puts it on the clipboard and takes it out of the box.
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${FORMAT_DOC}
    Choose From Text Menu    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    3    Select All
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    0    Select All
    Clipboard Should Be    ${FORMAT_DOC}
    Box Should Be Empty    ${FIRST_BOX_X}    ${INPUT_BOX_Y}

TC-TXM-020 The Result Of A Tool Is Text With Copy And Select All, Not Cut Or Paste
    [Documentation]    Format's result is shown as text that cannot be changed: its menu has Copy and
    ...    Select All, and Select All and Copy put the whole of it on the clipboard.
    [Tags]    p1
    Format The Document
    Open Text Menu    ${RESULT_POINT_X}    ${RESULT_POINT_Y}    Select All
    Menu Should Not Offer    ${RESULT_POINT_X}    ${RESULT_POINT_Y}    Cut    Paste
    ${offset}=    Item    1
    Pick Menu Item    ${RESULT_POINT_X}    ${RESULT_POINT_Y}    ${offset}
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${RESULT_POINT_X}    ${RESULT_POINT_Y}    0    Select All
    ${expected}=    Pretty    ${FORMAT_DOC}
    Clipboard Should Be    ${expected}

TC-TXM-021 An Error Of A Tool Is Text That Can Be Selected And Copied
    [Documentation]    A document that is not JSON is told in red in the result pane; its menu has Copy and
    ...    Select All, and the clipboard then has the message.
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {not json
    Press Main Button
    Result Should Read    parsing JSON
    Open Text Menu    ${RESULT_POINT_X}    ${RESULT_POINT_Y}    Select All
    ${offset}=    Item    1
    Pick Menu Item    ${RESULT_POINT_X}    ${RESULT_POINT_Y}    ${offset}
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${RESULT_POINT_X}    ${RESULT_POINT_Y}    0    Select All
    Clipboard Should Start With    Input: parsing JSON

TC-TXM-022 A Line Of The Side By Side View Copies Its Text
    [Documentation]    a is the same on both sides, b differs. The menu of a (nothing is moved or pointed to
    ...    by a line that is the same) has Copy line and gives the line as it is shown; the menu of b has
    ...    the moves, Copy path and a Copy for each side, and each gives that side's line.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${MENU_LEFT}    ${MENU_RIGHT}
    Tab Row Should Offer Changes    1
    ${a}=    Sbs Row Y    1
    Set Clipboard    nothing was copied
    Open Text Menu    120    ${a}    Copy line
    Menu Should Not Offer    120    ${a}    Move to the left    Move to the right    Copy path
    Pick Menu Item    120    ${a}    ${MENU_FIRST_Y}
    Clipboard Should Be    ${SPACE}${SPACE}"a": 1,
    ${b}=    Sbs Row Y    2
    Open Text Menu    120    ${b}    Copy path
    Menu Should Offer    120    ${b}    Move to the left    Move to the right    Copy path    Copy left line    Copy right line
    ${left}=    Evaluate    ${SEPARATED_Y} + ${MENU_PITCH}
    Pick Menu Item    120    ${b}    ${left}
    Clipboard Should Be    ${SPACE}${SPACE}"b": 2
    Open Text Menu    120    ${b}    Copy path
    ${right}=    Evaluate    ${SEPARATED_Y} + 2 * ${MENU_PITCH}
    Pick Menu Item    120    ${b}    ${right}
    Clipboard Should Be    ${SPACE}${SPACE}"b": 3

TC-TXM-023 The Menu Of A Line Being Typed Over Is That Of A Box, And The Typing Goes On
    [Documentation]    A double click on b of Left puts a caret in the line. Its right-click menu is a box's
    ...    (Cut, Copy, Paste, Select All) and has the path under them but no moves; pressing Select All in it
    ...    does not end the typing (the press takes the focus from the field, and the menu gives it back),
    ...    and what is typed next takes the place of all of the line.
    [Tags]    p1
    Open Tool    diff
    Compare Documents    ${MENU_LEFT}    ${MENU_RIGHT}
    Tab Row Should Offer Changes    1
    ${b}=    Sbs Row Y    2
    Double Click At    120    ${b}
    Status Should Say    Editing ?line
    Open Text Menu    120    ${b}    Paste
    Menu Should Offer    120    ${b}    Paste    Select All    Copy path
    Menu Should Not Offer    120    ${b}    Move to the left    Copy left line
    ${offset}=    Item    3
    Pick Menu Item    120    ${b}    ${offset}
    Status Should Say    Editing ?line
    Type Text    "b": 7
    Press Enter
    Tab Row Should Offer Changes    1
    Patch Should Replace    /b=3

TC-TXM-024 A Change In The List Copies Its Path Or Its Line
    [Documentation]    The list of changes has b changed from 2 to 3: the menu of its row has Copy path (the
    ...    JSON Pointer, which the status bar says it copied) and Copy line (what the row says).
    [Tags]    p2
    Open Tool    diff
    Compare Documents    ${MENU_LEFT}    ${MENU_RIGHT}
    Tab Row Should Offer Changes    1
    Pick Diff View    changes
    Diff Should Read    Changed
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${CHANGE_ROW_X}    ${CHANGE_ROW_Y}    0    Copy path
    Clipboard Should Be    /b
    Status Should Read    Copied the path
    Choose From Text Menu    ${CHANGE_ROW_X}    ${CHANGE_ROW_Y}    1    Copy path
    ${arrow}=    Evaluate    chr(8594)
    Clipboard Should Be    Changed /b${SPACE}${SPACE}2 ${arrow} 3

TC-TXM-025 A Problem In The List Copies Its Path, Its Message Or Its Line
    [Documentation]    age is a string where the schema says integer. The menu of the problem's row has Copy
    ...    path (/age), Copy message (what is wrong) and Copy problem (the line of the report: path, message
    ...    and the keyword in brackets).
    [Tags]    p2
    Open Tool    validate
    Paste Into Box    ${FIRST_BOX_X}    ${FIRST_BOX_Y}    ${MENU_VALUE}
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${MENU_SCHEMA}
    Press Main Button
    Status Should Read    Checked against
    Result Should Read    /age
    Set Clipboard    nothing was copied
    Choose From Text Menu    640    ${FIRST_ROW_Y}    0    Copy path
    Clipboard Should Be    /age
    Choose From Text Menu    640    ${FIRST_ROW_Y}    1    Copy path
    ${message}=    Get Clipboard
    Should Contain    ${message}    integer
    Should Not Contain    ${message}    /age
    Choose From Text Menu    640    ${FIRST_ROW_Y}    2    Copy path
    Clipboard Should Be    /age: ${message} [type]
