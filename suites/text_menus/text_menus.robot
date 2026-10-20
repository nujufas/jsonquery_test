*** Settings ***
Documentation     The right-click menu of a text in the main window -- see docs/24_text_menus.md. A box that
...               can be typed in (the query box, the source field, the empty Source panel's paste box,
...               the Find field, the editable Text view of a pasted document) has Cut, Copy, Paste and
...               Select All; a text that is only shown (the Results' Text view, the Text view of a file,
...               an error in the status bar) has Copy and Select All; the lines of a list (the hits of
...               Find All) copy their path or their line.
...
...               The menu opens with its top-left corner at the pointer and its items at fixed distances
...               under it (the first 16 px down, then 21 px apart: Cut, Copy, Paste, Select All), so an
...               item is clicked by its distance, as the menus of the tree's rows are (results.resource):
...               OCR is only asked whether the menu is open. What an item did is read exactly, from the
...               clipboard and from the box (a box is read back by copying it all).
...
...               Paste goes to the window system, which reads the clipboard and answers with the event the
...               key Ctrl+V makes, a frame later: after a click on Paste the cases wait a moment before they
...               look.
Resource          ../../resources/results.resource
Library           OperatingSystem
Force Tags        text_menus
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The query box's first line, where a click is a click in the box, and a point on its text.
${QUERY_X}               100
${QUERY_Y}               58
${QUERY_TEXT_X}          60
# A query with a word to pick, and what a double click on the word takes.
${WORDS_QUERY}           .people | map(.name)
${WORD_X}                43
# The Results' Text view: the first of its lines is at the top left of the pane; a point on
# the second line, inside the text.
${RESULTS_TEXT_POINT_X}    630
${RESULTS_TEXT_POINT_Y}    175
# The Text tab of the Source pane, and a point in its Text view's box.
${SOURCE_TEXT_TAB_X}     129
${SOURCE_TABS_Y}         142
${SOURCE_TEXT_X}         200
${SOURCE_TEXT_Y}         250
# A point inside the text of a file's Text view (a box that is only as wide as its lines).
${FILE_TEXT_X}           40
${FILE_TEXT_Y}           200
# The first line of the list that Find All makes at the foot of the window (the docked
# profile says where it is: resources/docked_main.py), and a point on its text.
${HIT_ROW_1_Y}           628
${HIT_TEXT_X}            60
# The region the menu is looked for in (from just under and right of the point it was opened at).
${MENU_WIDTH}            130
${MENU_HEIGHT}           100
# What an item of a text menu is under the point the menu was opened at.
${MENU_FIRST_Y}          16
${MENU_PITCH}            21
${MENU_X_OFFSET}         40

*** Keywords ***
Put In Query Box
    [Documentation]    The query box holds `text`, put there with a paste (typing sends some
    ...    characters wrong, and is slow).
    [Arguments]    ${text}
    Set Clipboard    ${text}
    Click At    ${QUERY_X}    ${QUERY_Y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Press Keys    ctrl    v
    Sleep    0.4s

Open Text Menu
    [Documentation]    Right-clicks the point and waits until the menu is on show, which it
    ...    knows by a word that the menu has and is bright (an item that is not available is
    ...    dim, and dim text is not read): `Paste` for a box that can be typed in, `Select All`
    ...    for a text that is only shown. A right click now and then does not register, so
    ...    the right click is made again.
    [Arguments]    ${x}    ${y}    ${word}=Paste
    Wait Until Keyword Succeeds    3x    0.4s    Right Click And See Menu    ${x}    ${y}    ${word}

Right Click And See Menu
    [Arguments]    ${x}    ${y}    ${word}
    Right Click At    ${x}    ${y}
    Sleep    0.4s
    ${left}=    Evaluate    int(${x}) + 5
    ${top}=    Evaluate    int(${y}) + 8
    Region Should Contain Text    ${left}    ${top}    ${MENU_WIDTH}    ${MENU_HEIGHT}    ${word}

Menu Item Y
    [Documentation]    The height of the `row`-th item (0 is the first) of a menu opened at `y`.
    [Arguments]    ${y}    ${row}
    ${at}=    Evaluate    int(${y}) + ${MENU_FIRST_Y} + ${MENU_PITCH} * int(${row})
    RETURN    ${at}

Pick Menu Item
    [Documentation]    Clicks the `row`-th item of the menu that was opened at (x, y), and gives the
    ...    window a moment to do what it says (a Paste or a Cut is answered a frame later).
    [Arguments]    ${x}    ${y}    ${row}
    ${at_x}=    Evaluate    int(${x}) + ${MENU_X_OFFSET}
    ${at_y}=    Menu Item Y    ${y}    ${row}
    Click At    ${at_x}    ${at_y}
    Sleep    0.6s

Choose From Text Menu
    [Documentation]    Opens the menu at the point and clicks the `row`-th item of it.
    [Arguments]    ${x}    ${y}    ${row}    ${word}=Paste
    Open Text Menu    ${x}    ${y}    ${word}
    Pick Menu Item    ${x}    ${y}    ${row}

Menu Should Offer
    [Documentation]    The menu that is open at (x, y) has all of these items, in bright text.
    [Arguments]    ${x}    ${y}    @{items}
    ${left}=    Evaluate    int(${x}) + 5
    ${top}=    Evaluate    int(${y}) + 8
    FOR    ${item}    IN    @{items}
        Region Should Contain Text    ${left}    ${top}    ${MENU_WIDTH}    ${MENU_HEIGHT}    ${item}
    END

Menu Should Not Offer
    [Arguments]    ${x}    ${y}    @{items}
    ${left}=    Evaluate    int(${x}) + 5
    ${top}=    Evaluate    int(${y}) + 8
    FOR    ${item}    IN    @{items}
        Region Should Not Contain Text    ${left}    ${top}    ${MENU_WIDTH}    ${MENU_HEIGHT}    ${item}
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

Query Box Should Be Empty
    [Documentation]    Nothing is in the query box: all of it is taken and copied, and the
    ...    clipboard is still what it was set to (a box with nothing in it copies nothing).
    Set Clipboard    nothing was copied
    Click At    ${QUERY_X}    ${QUERY_Y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Press Keys    ctrl    c
    Sleep    0.4s
    ${text}=    Get Clipboard
    Should Be Equal    ${text}    nothing was copied
    Move Mouse To    600    400

Load People And Show Names As Text
    [Documentation]    The people fixture is loaded, `.[] | .name` is run and the Results pane
    ...    shows its Text view (`["Alice", "Bob", "Carol"]`, one to a line).
    Load Fixture    people.json
    Run Query    .[] | .name
    Show Results As Text

*** Test Cases ***
TC-TXM-001 The Query Box Has The Menu Of A Text Box
    [Documentation]    Right-click in the query box, in text that is all selected: the menu
    ...    has Cut, Copy, Paste and Select All, each with its key beside it, and all four are
    ...    bright (a box with nothing selected has Cut and Copy dim).
    [Tags]    p1
    Put In Query Box    ${WORDS_QUERY}
    Press Keys    ctrl    a
    Open Text Menu    ${QUERY_TEXT_X}    ${QUERY_Y}    Select All
    Menu Should Offer    ${QUERY_TEXT_X}    ${QUERY_Y}    Cut    Copy    Paste    Select All
    Menu Should Offer    ${QUERY_TEXT_X}    ${QUERY_Y}    Ctrl+X    Ctrl+V

TC-TXM-002 Paste In The Menu Of The Query Box Puts The Clipboard In It
    [Documentation]    The clipboard has a query; the box is empty. Right-click in the box
    ...    and Paste (the third item): the box holds the query, exactly.
    [Tags]    p1
    Set Clipboard    .[] | select(.age > 21)
    Choose From Text Menu    ${QUERY_X}    ${QUERY_Y}    2
    Query Text Should Be    .[] | select(.age > 21)

TC-TXM-003 Select All And Copy In The Menu Put The Whole Query On The Clipboard
    [Documentation]    Select All (the fourth item) takes all of the text, and Copy (the second)
    ...    puts it on the clipboard: the box is as it was.
    [Tags]    p1
    Put In Query Box    ${WORDS_QUERY}
    Choose From Text Menu    ${QUERY_TEXT_X}    ${QUERY_Y}    3    Select All
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${QUERY_TEXT_X}    ${QUERY_Y}    1    Select All
    Clipboard Should Be    ${WORDS_QUERY}
    Query Text Should Be    ${WORDS_QUERY}

TC-TXM-004 Cut In The Menu Moves The Query To The Clipboard
    [Documentation]    With all of the text selected, Cut (the first item) takes it out of the
    ...    box and puts it on the clipboard.
    [Tags]    p1
    Put In Query Box    ${WORDS_QUERY}
    Press Keys    ctrl    a
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${QUERY_TEXT_X}    ${QUERY_Y}    0    Select All
    Clipboard Should Be    ${WORDS_QUERY}
    Query Box Should Be Empty

TC-TXM-005 A Right Click Inside A Selection Keeps It, So That Copy Copies Just That
    [Documentation]    A double click takes a word; a right click on the word leaves it taken
    ...    (a right click used to put the caret where it landed, and Copy then had nothing),
    ...    and Copy puts the word, and only the word, on the clipboard.
    [Tags]    p1
    Put In Query Box    ${WORDS_QUERY}
    Double Click At    ${WORD_X}    ${QUERY_Y}
    Sleep    0.4s
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${WORD_X}    ${QUERY_Y}    1    Select All
    Clipboard Should Be    people

TC-TXM-006 A Right Click Outside A Selection Puts The Caret There, And Copy Is Dim
    [Documentation]    The word is taken, and the right click is far to the right of the text, not
    ...    on the word: the selection is gone (the caret is there), Copy is dim, and an
    ...    attempt to click it copies nothing.
    [Tags]    p2
    Put In Query Box    ${WORDS_QUERY}
    Double Click At    ${WORD_X}    ${QUERY_Y}
    Sleep    0.4s
    Open Text Menu    700    ${QUERY_Y}    Paste
    Set Clipboard    nothing was copied
    Pick Menu Item    700    ${QUERY_Y}    1
    ${text}=    Get Clipboard
    Should Be Equal    ${text}    nothing was copied

TC-TXM-007 The Menu Of The Source Field Pastes A Path
    [Documentation]    The source field takes a URL or a path; Paste puts the clipboard's text
    ...    in it (the field has the menu in the toolbar and in a popped-out Source pane).
    [Tags]    p1
    Set Clipboard    /some/where/people.json
    Choose From Text Menu    ${SOURCE_FIELD_X}    ${TOOLBAR_Y}    2
    Source Field Should Be    /some/where/people.json

TC-TXM-008 Paste In The Menu Of The Empty Source Panel Loads The Document
    [Documentation]    Nothing is loaded and the panel has its box ("Paste JSON here..."). The
    ...    clipboard has JSON; right-click in the box and Paste: the document is loaded (the
    ...    toolbar says "pasted JSON" and the Source tree has its rows).
    [Tags]    p1
    ${json}=    Get File    ${FIXTURES}/people.json
    Set Clipboard    ${json}
    Choose From Text Menu    200    300    2
    Wait Until Region Contains Text    @{STATUS_AREA}    pasted    timeout=5
    Region Should Contain Text    @{SOURCE_PANEL}    3 items

TC-TXM-009 The Results' Text View Has Copy And Select All, Not Cut Or Paste
    [Documentation]    The Text view of the results is text that is only shown: its menu has
    ...    Copy and Select All and nothing that would change it.
    [Tags]    p1
    Load People And Show Names As Text
    Open Text Menu    ${RESULTS_TEXT_POINT_X}    ${RESULTS_TEXT_POINT_Y}    Select All
    Menu Should Offer    ${RESULTS_TEXT_POINT_X}    ${RESULTS_TEXT_POINT_Y}    Select All    Ctrl+A
    Menu Should Not Offer    ${RESULTS_TEXT_POINT_X}    ${RESULTS_TEXT_POINT_Y}    Cut    Paste

TC-TXM-010 Select All And Copy In The Results' Text View Give All Of The Text
    [Documentation]    Select All (the second item) takes all of the text of the view, and Copy
    ...    (the first, bright now) puts it on the clipboard: the results as they are shown.
    [Tags]    p1
    Load People And Show Names As Text
    Choose From Text Menu    ${RESULTS_TEXT_POINT_X}    ${RESULTS_TEXT_POINT_Y}    1    Select All
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${RESULTS_TEXT_POINT_X}    ${RESULTS_TEXT_POINT_Y}    0    Select All
    ${nl}=    Evaluate    chr(10)
    Clipboard Should Be    [${nl}\ \ "Alice",${nl}\ \ "Bob",${nl}\ \ "Carol"${nl}]

TC-TXM-011 A Word Taken In The Results' Text View Stays Taken Under A Right Click
    [Documentation]    A double click on "Bob" takes the word, and a right click on it leaves it
    ...    taken: Copy puts the word on the clipboard and nothing else.
    [Tags]    p2
    Load People And Show Names As Text
    Double Click At    650    192
    Sleep    0.4s
    Set Clipboard    nothing was copied
    Choose From Text Menu    650    192    0    Select All
    Clipboard Should Be    Bob

TC-TXM-012 The Text View Of A Pasted Document Has The Menu Of A Box
    [Documentation]    The Source pane's Text view of a pasted document can be edited (Apply
    ...    reads it again), so its menu is a box's: Paste is there, and Cut and Copy (dim until
    ...    something is taken).
    [Tags]    p2
    Load Fixture    people.json
    Click At    ${SOURCE_TEXT_TAB_X}    ${SOURCE_TABS_Y}
    Sleep    0.5s
    Open Text Menu    ${SOURCE_TEXT_X}    ${SOURCE_TEXT_Y}    Paste
    Menu Should Offer    ${SOURCE_TEXT_X}    ${SOURCE_TEXT_Y}    Paste    Select All

TC-TXM-013 The Text View Of A File Has Copy And Select All, Not Cut Or Paste
    [Documentation]    A file that was opened is shown as text that cannot be changed: its
    ...    menu has Copy and Select All, and Select All and Copy give the text.
    [Tags]    p2
    Load Via Url    ${FIXTURES}/people.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=8
    Click At    ${SOURCE_TEXT_TAB_X}    ${SOURCE_TABS_Y}
    Sleep    0.5s
    Open Text Menu    ${FILE_TEXT_X}    ${FILE_TEXT_Y}    Select All
    Menu Should Not Offer    ${FILE_TEXT_X}    ${FILE_TEXT_Y}    Cut    Paste
    Pick Menu Item    ${FILE_TEXT_X}    ${FILE_TEXT_Y}    1
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${FILE_TEXT_X}    ${FILE_TEXT_Y}    0    Select All
    Clipboard Should Start With    [
    ${text}=    Get Clipboard
    Should Contain    ${text}    "name": "Alice"
    Should Contain    ${text}    "role": "manager"

TC-TXM-014 An Error In The Status Bar Is Copied With A Right Click
    [Documentation]    A query that does not parse says so in red in the status bar; a right
    ...    click on the message offers Copy, and the clipboard then has the message.
    [Tags]    p2
    Load Fixture    people.json
    Run Query    .[
    ${x}    ${y}=    Find Text In Region    @{STATUS_BAR}    Query error
    Right Click At    ${x}    ${y}
    Sleep    0.5s
    # The status bar is at the foot of the window, so the menu does not open under the
    # pointer: Copy is found where it is.
    ${left}=    Evaluate    int(${x}) - 20
    ${top}=    Evaluate    int(${y}) - 75
    Set Clipboard    nothing was copied
    Click Text In Region    ${left}    ${top}    160    140    Copy
    Clipboard Should Start With    Query error: query syntax error

TC-TXM-015 The Find Field Has The Menu Of A Text Box
    [Documentation]    Ctrl+F opens the Find dialog with the cursor in its field: right-click
    ...    there and Paste puts the clipboard's text in it, and Find finds it ("1 of 1").
    [Tags]    p3
    Load Fixture    people.json
    Click At    200    300
    Sleep    0.2s
    Press Keys    ctrl    f
    Sleep    0.4s
    Set Clipboard    Bob
    Choose From Text Menu    ${SEARCH_FIND_FIELD_X}    ${SEARCH_FIND_FIELD_Y}    2
    Press Key    enter
    Wait Until Region Matches    @{SEARCH_STATUS_AREA}    1 ?o?f ?1    timeout=5

TC-TXM-016 A Hit Of Find All Copies Its Path Or Its Line
    [Documentation]    Find All lists where "Alice" is; a right click on the hit offers Copy path
    ...    (the jq path of the value) and Copy line (the line as it is listed).
    [Tags]    p3
    Load Fixture    people.json
    Click At    200    300
    Sleep    0.2s
    Press Keys    ctrl    f
    Sleep    0.4s
    Click At    ${SEARCH_FIND_FIELD_X}    ${SEARCH_FIND_FIELD_Y}
    Sleep    0.2s
    Press Keys    ctrl    a
    Type Text    Alice
    Sleep    0.3s
    Click At    ${SEARCH_FIND_ALL_X}    ${SEARCH_FIND_ALL_Y}
    Wait Until Region Contains Text    @{SEARCH_RESULTS_AREA}    Search results    timeout=5
    Set Clipboard    nothing was copied
    Choose From Text Menu    ${HIT_TEXT_X}    ${HIT_ROW_1_Y}    0    Copy path
    Clipboard Should Be    .[0].name
    Choose From Text Menu    ${HIT_TEXT_X}    ${HIT_ROW_1_Y}    1    Copy path
    Clipboard Should Start With    [Source]

TC-TXM-026 Ctrl+A In A Text View Takes All Of Its Text, As Select All In The Menu Does
    [Documentation]    The Text view of the results is a text box that cannot be changed, so the keys of a box
    ...    work in it: a click in it, Ctrl+A and Ctrl+C put the whole text on the clipboard (a selectable
    ...    label had no Ctrl+A).
    [Tags]    p3
    Load People And Show Names As Text
    Click At    ${RESULTS_TEXT_POINT_X}    ${RESULTS_TEXT_POINT_Y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Set Clipboard    nothing was copied
    Press Keys    ctrl    c
    ${nl}=    Evaluate    chr(10)
    Clipboard Should Be    [${nl}\ \ "Alice",${nl}\ \ "Bob",${nl}\ \ "Carol"${nl}]
