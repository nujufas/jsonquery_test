*** Settings ***
Documentation     Layout constants and keywords shared by the Tools-window suites
...               (suites/tools/): the window, its tabs, and the pages' boxes,
...               buttons and result areas. Every point is relative to the Tools
...               window's top-left once `Switch To Window` has made it the current
...               one, and was MEASURED on screenshots of the real window at its
...               default size, 900x580, in the Dark theme (undecorated, like the
...               main window -- the fluxbox `Deco NONE` rule matches the class).
...
...               The window is laid out as the main one is: a row of tabs at the
...               top (y 0-22, one per tool), the page's command row under it (y
...               23-45: the main button and the options), then two panes side by
...               side -- each with a header (a small title and its buttons) at
...               y=63 and its content from y=76 -- and a status bar in the last 23
...               pixels. The left pane is 450 wide; the right one starts at x=451.
...               Two exceptions: the Merge page has its filter box under the
...               command row, so its panes' headers are at y=120; and the Diff
...               page's Documents view has a margin around its two boxes (header
...               at y=71).
Resource          keywords.resource

*** Variables ***
${TOOLS_WINDOW}        jsonquery — Tools
# The 🛠 button in the main window's toolbar: icon only, so a fixed point (the first
# button left of the 📖 tutorial button).
${TOOLS_X}             1094
${TOOLS_Y}             11
# The tabs: one fixed point each (their names are read by OCR as one word, "FormatJSON",
# which no name lookup can match).
${TAB_Y}               11
&{TAB_X}               merge=48    format=140    diff=222    patch=302    validate=399
@{TAB_ROW}             0      0      560    22
@{COMMAND_ROW}         0      23     560    22
${COMMAND_Y}           34
# The page's main button (Merge, Format, Compare, Apply, Validate), first in the command row.
${RUN_X}               34
@{TOOLS_STATUS}        0      558    900    22
# The headers of the two panes (a title, then buttons pinned at the right), and what
# is under them.
${HEADER_Y}            63
@{LEFT_HEADER}         8      54     220    26
@{RESULT_HEADER}       459    54     240    26
@{MERGE_LEFT_HEADER}   8      110    220    24
@{MERGE_RESULT_HEADER}    459    110    240    24
# The result area of Format, Patch and Validate: the right pane's content.
@{TOOL_RESULT}         456    74     440    474
# The boxes of the left pane. Format has one, which fills it; Patch and Validate have
# two, one above the other: click either to type in it.
${FIRST_BOX_X}         200
${INPUT_BOX_Y}         300
${FIRST_BOX_Y}         190
${SECOND_BOX_Y}        440
@{FIRST_BOX}           8      76     433    220
@{SECOND_BOX}          8      328    433    220
@{INPUT_BOX}           8      76     433    472
# The header buttons, by what they are (x), at HEADER_Y: the first box's Open file…,
# Open document and Clear; the result's Copy, Save… and Open in main window / Show
# in main window.
${OPEN_DOCUMENT_X}     343
${CLEAR_X}             422
${SECOND_HEADER_Y}     315
# The result's header buttons. Format has Copy, Save…; Patch has Copy, Save…, Open in
# main window; Validate has Copy report, Show in main window.
${FORMAT_COPY_X}       817
${PATCH_COPY_X}        676
${OPEN_IN_MAIN_X}      825
${COPY_REPORT_X}       712
${SHOW_IN_MAIN_X}      825
# The first row of a list of problems (Validate), and the rows' pitch.
${FIRST_ROW_Y}         86
${ROW_PITCH}           20
# Format's options in the command row, and the dropdown's items (2 spaces, 4 spaces,
# Tab, Minified) once it is open.
${INDENT_X}            158
${SORT_KEYS_X}         217
${ASCII_ONLY_X}        295
${INDENT_ITEM_X}       150
&{INDENT_ITEM_Y}       2 spaces=59    4 spaces=80    Tab=101    Minified=122
# Patch's Kind dropdown and its two items.
${KIND_X}              175
${KIND_ITEM_X}         170
&{KIND_ITEM_Y}         operations=59    merge=80
# Validate's "Check formats" checkbox.
${CHECK_FORMATS_X}     79
# Diff: the boxes of the Documents view (one in each pane, margin 8: the headers are
# at y=71), the buttons of the command row, and the side-by-side view.
${DIFF_LEFT_X}         200
${DIFF_RIGHT_X}        650
${DIFF_BOX_Y}          300
${DIFF_HEADER_Y}       71
@{DIFF_LEFT_BOX}       16     84     424    456
@{DIFF_RIGHT_BOX}      458    84     426    456
${SWAP_X}              96
${DOCUMENTS_X}         175
${SIDE_BY_SIDE_X}      258
${CHANGES_X}           342
${PATCH_VIEW_X}        408
${PREVIOUS_X}          460
${NEXT_X}              487
${COPY_PATCH_X}        765
@{DIFF_BODY}           8      54     884    495
# The two columns of the side-by-side view, with the gutter between them (22 wide: the
# strip that marks a difference, and the arrows of each, one over the other) left out.
@{SBS_LEFT}            8      76     416    470
@{SBS_RIGHT}           454    76     414    470
# The arrows of a difference, in the gutter: the one at the top, at the difference's first
# line, points to the Left document (it takes what Right has there), the one under it, a
# line lower, to Right. And the Save… over each column.
${ARROW_X}             439
${DIFF_LEFT_SAVE_X}    403
${DIFF_RIGHT_SAVE_X}   845
# Where a click is a click on the text of a line of the Left column, and of the Right.
${LEFT_TEXT_X}         120
${RIGHT_TEXT_X}        600
# The buttons of the command row that move what is picked (or the difference Next went
# to) into Left and into Right, and the line over the two columns' headers.
${MOVE_LEFT_X}         529
${MOVE_RIGHT_X}        557
@{SBS_HEADER}          8      54     884    18
${ONLY_DIFFERENCES_X}  765
# The first row of the side-by-side view and the pitch of its rows.
${SBS_FIRST_ROW_Y}     83
${SBS_ROW_PITCH}       17
# Merge: its preset dropdown, its filter box (under the command row), the buttons of
# its panes, and what the dropdown lists.
${MERGE_AS_X}          227
${MERGE_ITEM_X}        200
&{MERGE_ITEM_Y}        append=59    unique=80    deep=101    bundle=122
${FILTER_BOX_X}        400
${FILTER_BOX_Y}        70
@{FILTER_BOX}          8      46     884    50
${ADD_FILES_X}         405
${MERGE_HEADER_Y}      120
@{MERGE_FILES}         8      130    433    410
@{MERGE_RESULT}        456    130    440    410

*** Keywords ***
Open Tools Window
    Switch To Main Window
    Click At    ${TOOLS_X}    ${TOOLS_Y}
    Wait Until Window Exists    ${TOOLS_WINDOW}

Pick Tool
    [Documentation]    Clicks a tool's tab (merge, format, diff, patch or
    ...    validate). The Tools window must be the current one.
    [Arguments]    ${tool}
    Click At    ${TAB_X}[${tool}]    ${TAB_Y}
    Sleep    0.5s

Open Tool
    [Documentation]    Opens the Tools window and goes to the page of a tool;
    ...    every coordinate is the window's from here on.
    [Arguments]    ${tool}
    Open Tools Window
    Switch To Window    ${TOOLS_WINDOW}
    Pick Tool    ${tool}

Tools Window Should Read
    [Documentation]    OCR of a region of the Tools window (retried), from
    ...    wherever the test is; goes back to the main window afterwards.
    [Arguments]    ${text}    @{region}
    Switch To Window    ${TOOLS_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{region}    ${text}
    Switch To Main Window

Page Should Show
    [Documentation]    OCR of the heading over the left pane of the page that is
    ...    showing, in the Tools window (which must be the current one).
    [Arguments]    ${heading}    @{region}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{region}    ${heading}

Paste Into Box
    [Documentation]    Replaces what is in the box at (x, y) with `text`, by
    ...    pasting it, as the main window's tests do (typing JSON through
    ...    xdotool is slower and mistypes some characters).
    [Arguments]    ${x}    ${y}    ${text}
    Set Clipboard    ${text}
    Click At    ${x}    ${y}
    Sleep    0.2s
    Press Keys    ctrl    a
    Press Keys    ctrl    v
    Sleep    0.3s

Press Main Button
    [Documentation]    The page's Merge / Format / Compare / Apply / Validate button.
    Click At    ${RUN_X}    ${COMMAND_Y}
    Sleep    0.5s

Result Should Read
    [Documentation]    OCR of the right pane's content (retried while the worker
    ...    answers). The result is small monospace text, which Tesseract reads
    ...    well in part: ask for what it does read reliably (punctuation-rich
    ...    lines like `"b": 1,` come back garbled, a plain `1,` per line does not).
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{TOOL_RESULT}    ${text}

Result Should Not Read
    [Arguments]    ${text}
    Region Should Not Contain Text    @{TOOL_RESULT}    ${text}

Status Should Read
    [Documentation]    OCR of the Tools window's status bar (retried while the
    ...    worker answers): what the page says about its result, in the main
    ...    window's body text, which reads well.
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{TOOLS_STATUS}    ${text}

Status Should Not Read
    [Arguments]    ${text}
    Region Should Not Contain Text    @{TOOLS_STATUS}    ${text}

Copy Should Give
    [Documentation]    Clicks a header button that copies to the clipboard and
    ...    checks the clipboard against `expected`, exactly -- the one way to
    ...    check a long result without reading it off the screen. The clipboard
    ...    is set to a marker first, so a button that does nothing fails the check.
    [Arguments]    ${x}    ${y}    ${expected}
    Set Clipboard    nothing was copied
    Click At    ${x}    ${y}
    Sleep    0.5s
    ${copied}=    Get Clipboard
    Should Be Equal    ${copied}    ${expected}

Copy Should Do Nothing
    [Documentation]    Clicks a button that is disabled: the clipboard stays as it was.
    [Arguments]    ${x}    ${y}
    Set Clipboard    nothing was copied
    Click At    ${x}    ${y}
    Sleep    0.5s
    ${copied}=    Get Clipboard
    Should Be Equal    ${copied}    nothing was copied

Tab Should Be Selected
    [Documentation]    The tab of this tool is the one marked (white on blue): its
    ...    fill, the selection blue, is somewhere in a strip across the tab.
    [Arguments]    ${tool}
    ${x}=    Evaluate    int(${TAB_X}[${tool}]) - 30
    Region Should Contain Color    ${x}    5    60    12    0    92    128    tolerance=10

Tab Should Not Be Selected
    [Arguments]    ${tool}
    ${x}=    Evaluate    int(${TAB_X}[${tool}]) - 30
    Region Should Not Contain Color    ${x}    5    60    12    0    92    128    tolerance=10

Pick Indent
    [Documentation]    Opens Format's Indent dropdown and picks one of its items
    ...    ("2 spaces", "4 spaces", "Tab", "Minified").
    [Arguments]    ${item}
    Click At    ${INDENT_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${INDENT_ITEM_X}    ${INDENT_ITEM_Y}[${item}]
    Sleep    0.4s

Pick Diff View
    [Documentation]    Clicks one of Diff's tabs (documents, side_by_side, changes,
    ...    patch) in the command row.
    [Arguments]    ${view}
    ${x}=    Diff View X    ${view}
    Click At    ${x}    ${COMMAND_Y}
    Sleep    0.5s

Diff Should Read
    [Documentation]    OCR of what Diff shows under its command row (retried
    ...    while the worker answers). Only plain words and short lines are
    ...    reliable: the small monospace text comes back garbled where it has
    ...    punctuation.
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DIFF_BODY}    ${text}

Sbs Row Y
    [Documentation]    The height of row `n` (0 is the first line) of the side-by-side view.
    [Arguments]    ${n}
    ${y}=    Evaluate    int(${SBS_FIRST_ROW_Y}) + int(${n}) * int(${SBS_ROW_PITCH})
    RETURN    ${y}

Click Arrow To Left
    [Documentation]    Press the arrow that points to the Left document, of the difference whose
    ...    first line is row `row` of the side-by-side view.
    [Arguments]    ${row}
    ${y}=    Sbs Row Y    ${row}
    Click At    ${ARROW_X}    ${y}

Click Arrow To Right
    [Documentation]    The arrow that points to the Right document: under the other, a line lower.
    [Arguments]    ${row}
    ${y}=    Sbs Row Y    ${row}
    ${y}=    Evaluate    ${y} + int(${SBS_ROW_PITCH})
    Click At    ${ARROW_X}    ${y}

Patch Should Replace
    [Documentation]    Copy patch gives exactly these replacements, in this order: each is
    ...    `path=value` (a JSON Pointer, and the new value as JSON). It is the exact
    ...    way to read what is left to differ after a move.
    [Arguments]    @{replacements}
    ${expected}=    Evaluate    (lambda items: '[' + chr(10) + (',' + chr(10)).join(chr(32) * 2 + '{"op": "replace", "path": "%s", "value": %s}' % tuple(r.split('=', 1)) for r in items) + chr(10) + ']')($replacements)
    Copy Should Give    ${COPY_PATCH_X}    ${COMMAND_Y}    ${expected}

Patch Should Be Empty
    [Documentation]    Nothing is left to differ: the patch is `[]`.
    Copy Should Give    ${COPY_PATCH_X}    ${COMMAND_Y}    []

Compare Documents
    [Documentation]    Pastes two documents into Diff's boxes (on its Documents
    ...    view) and presses Compare, which opens the side-by-side view.
    [Arguments]    ${left}    ${right}
    Paste Into Box    ${DIFF_LEFT_X}    ${DIFF_BOX_Y}    ${left}
    Paste Into Box    ${DIFF_RIGHT_X}    ${DIFF_BOX_Y}    ${right}
    Press Main Button

Diff View Should Be Selected
    [Documentation]    The tab of this view (documents, side_by_side, changes or
    ...    patch) is the one marked, white on the selection blue.
    [Arguments]    ${view}
    ${x}=    Diff View X    ${view}
    ${left}=    Evaluate    ${x} - 20
    Region Should Contain Color    ${left}    27    40    14    0    92    128    tolerance=10

Diff View Should Not Be Selected
    [Arguments]    ${view}
    ${x}=    Diff View X    ${view}
    ${left}=    Evaluate    ${x} - 20
    Region Should Not Contain Color    ${left}    27    40    14    0    92    128    tolerance=10

Diff View X
    [Arguments]    ${view}
    ${x}=    Set Variable If    '${view}' == 'documents'    ${DOCUMENTS_X}
    ...    '${view}' == 'side_by_side'    ${SIDE_BY_SIDE_X}
    ...    '${view}' == 'changes'    ${CHANGES_X}
    ...    ${PATCH_VIEW_X}
    RETURN    ${x}

Changed Rows Should Line Up
    [Documentation]    The side-by-side view scrolls as one: the rows tinted as
    ...    changed (amber) are at the same heights in the left and the right
    ...    column, and there are some on show.
    ${left}=    Get Rows With Color    @{SBS_LEFT}    57    47    29    tolerance=4
    ${right}=    Get Rows With Color    @{SBS_RIGHT}    57    47    29    tolerance=4
    Should Not Be Empty    ${left}    msg=No changed row on show on the left
    Should Be Equal    ${left}    ${right}

Tab Row Should Offer Changes
    [Documentation]    Diff's "Changes (n)" tab says how many differences there
    ...    are. Matched on the opening of it, "Changes (5": Tesseract reads the
    ...    closing parenthesis after a digit as an S or drops it, and a zero as
    ...    an O.
    [Arguments]    ${count}
    ${digit}=    Set Variable If    '${count}' == '0'    [0Oo]    ${count}
    Wait Until Region Matches    @{COMMAND_ROW}    Changes ?\\(${digit}    timeout=8

Tab Row Should Not Offer Changes
    ${text}=    Read Region Text    @{COMMAND_ROW}
    Should Not Match Regexp    ${text}    Changes ?\\(

Difference Should Be
    [Documentation]    The status bar's "Difference 2 of 5" names the difference
    ...    the view is on; the number after the word is what is checked (the
    ...    rest, "of 5", is read as "o0f5" at times).
    [Arguments]    ${number}
    Wait Until Region Matches    @{TOOLS_STATUS}    Difference ?${number}    timeout=8
