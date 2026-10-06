*** Settings ***
Documentation     Reading a query's results exactly, and the files the app saves from
...               them -- shared by the suites of the jq functions the app adds
...               (jq_functions), the CSV/TSV output (output_formats), saving, the
...               tutorial pages and the workflows.
...
...               Exact text comes from the clipboard and from files, not from OCR: OCR
...               reads punctuation badly, and the whole point of these suites is that
...               a comma is a comma and a quote is doubled. The results root's
...               "Copy to Clipboard" gives every result at once; a row's gives that
...               result alone; the Text view's text can be selected and copied; and
...               Save... (through the stand-in portal, see AppLibrary's `Portal Will
...               ...` keywords) gives the file.
...
...               Every suite that uses this resource declares its own Suite/Test
...               Setup and Teardown, as keywords.resource explains.
Resource          keywords.resource
Library           OperatingSystem
Library           Collections
Library           String

*** Variables ***
${FIXTURES}               ${CURDIR}/fixtures
# The Results header, calibrated against screenshots of the default 1200x800 window
# in the Dark theme (2026-10-06): the title, the Tree and Text toggles, the note that
# says "CSV" or "TSV" (dim text, drawn only while the query ends in @csv or @tsv),
# Save... and the pop-out icon at the right edge.
${RESULTS_HEADER_Y}       142
${RESULTS_TREE_X}         689
${RESULTS_TEXT_X}         731
${RESULTS_SAVE_X}         1143
${RESULTS_POPOUT_X}       1184
# Where the note sits: x 757-778, y 138-146 at its brightest (~95 of 255 on a ~27
# background: too dim to OCR, so it is read by pixels and by its tooltip).
@{FORMAT_NOTE_AREA}       748    134    52    18
${FORMAT_NOTE_X}          767
# The tooltips of the note and of Save... open under the pointer; these are the
# areas they fill (a tooltip is plain bright text, so OCR reads it).
@{NOTE_TOOLTIP_AREA}      268    152    520    48
@{SAVE_TOOLTIP_AREA}      900    152    300    40
# The Results tree: the root row ("[...] (N items)") and then one row per result, 21px
# apart. The pointer goes on the text of a row, not on its arrow.
${RESULTS_ROOT_X}         680
${RESULTS_ROOT_Y}         165
${RESULTS_ROW_X}          700
${RESULTS_FIRST_ROW_Y}    186
${RESULTS_ROW_STEP}       21
# The browse button (...) beside the source field, which opens the file dialog.
${BROWSE_X}               830
# The Source tree's root and first rows, the same shape in the left pane.
${SOURCE_ROOT_X}          70
${SOURCE_ROOT_Y}          165
${SOURCE_ROW_X}           100
${SOURCE_FIRST_ROW_Y}     186
# A row's context menu opens with its top-left corner at the pointer and its items at
# fixed distances below it: Save... 16, Copy to Clipboard 37, Copy JSON Path 58 (and,
# on a Results row, Find in Source 79 and Search... 109). Clicked by offset, not found
# by OCR: the rows behind the menu confuse OCR (a TSV row's backslashes read as part
# of the menu), and a click that misses is caught by what it was meant to do.
${MENU_ITEM_X}            55
${MENU_SAVE_Y}            16
${MENU_COPY_Y}            37
${MENU_PATH_Y}            58
# The Results Text view is a selectable label whose first character is at the top
# left of the pane; pressing there and dragging down and to the right selects it all.
${TEXT_VIEW_START_X}      609
${TEXT_VIEW_START_Y}      157
${TEXT_VIEW_END_X}        1190
${TEXT_VIEW_END_Y}        700

*** Keywords ***
Load Fixture
    [Documentation]    Pastes the named file of resources/fixtures into the empty app.
    [Arguments]    ${name}
    ${json}=    Get File    ${FIXTURES}/${name}    encoding=UTF-8
    Load Fixture Via Paste    ${json}

Run Query By Paste
    [Documentation]    Puts the query in the box with a paste and runs it -- for a query
    ...    that has characters `Type Text` cannot send (anything outside ASCII) or that
    ...    is long enough for typing to be slow. Retried like `Run Query`.
    [Arguments]    ${query}
    Wait Until Keyword Succeeds    5x    0.5s
    ...    Paste And Run Query    ${query}

Paste And Run Query
    [Arguments]    ${query}
    Set Clipboard    ${query}
    Click At    100    58
    Sleep    0.3s
    Press Keys    ctrl    a
    Press Keys    ctrl    v
    Sleep    0.3s
    Press Keys    ctrl    enter
    Wait Until Region Matches    @{STATUS_BAR}    result\\(s\\)|error    timeout=5

Show Results As Text
    Click At    ${RESULTS_TEXT_X}    ${RESULTS_HEADER_Y}
    Sleep    0.5s

Show Results As Tree
    Click At    ${RESULTS_TREE_X}    ${RESULTS_HEADER_Y}
    Sleep    0.5s

Results Row Y
    [Documentation]    The y of the n-th result's row (0 is the first) in the Results tree.
    [Arguments]    ${n}
    ${y}=    Evaluate    ${RESULTS_FIRST_ROW_Y} + ${RESULTS_ROW_STEP} * int(${n})
    RETURN    ${y}

Copy From Menu At
    [Documentation]    Right-clicks the point, chooses "Copy to Clipboard" in the menu
    ...    that opens and returns what the clipboard holds. The clipboard is set to a
    ...    marker first, so a menu that did not open, or an item that does nothing,
    ...    fails here and does not return what an earlier step left. The copy goes
    ...    through the worker (Command::CopyNode), so the clipboard changes a frame or
    ...    two after the click: it is polled. The whole attempt is retried.
    [Arguments]    ${x}    ${y}
    Wait Until Keyword Succeeds    4x    0.5s    Try Copy From Menu At    ${x}    ${y}
    ${text}=    Get Clipboard
    RETURN    ${text}

Try Copy From Menu At
    [Arguments]    ${x}    ${y}
    Set Clipboard    nothing was copied
    Right Click At    ${x}    ${y}
    Sleep    0.5s
    ${item_x}=    Evaluate    ${x} + ${MENU_ITEM_X}
    ${item_y}=    Evaluate    ${y} + ${MENU_COPY_Y}
    Click At    ${item_x}    ${item_y}
    Wait Until Keyword Succeeds    8x    0.3s
    ...    Clipboard Should Not Be    nothing was copied

Clipboard Should Not Be
    [Arguments]    ${unexpected}
    ${text}=    Get Clipboard
    Should Not Be Equal    ${text}    ${unexpected}

Copy All Results
    [Documentation]    "Copy to Clipboard" on the Results root: every result, as JSON
    ...    (an array, pretty-printed) or, for a query ending in @csv or @tsv, as the rows
    ...    it made, one to a line.
    ${text}=    Copy From Menu At    ${RESULTS_ROOT_X}    ${RESULTS_ROOT_Y}
    RETURN    ${text}

Copy Result Row
    [Documentation]    "Copy to Clipboard" on the n-th result's row (0 is the first).
    [Arguments]    ${n}
    ${y}=    Results Row Y    ${n}
    ${text}=    Copy From Menu At    ${RESULTS_ROW_X}    ${y}
    RETURN    ${text}

Copy Source Row
    [Documentation]    "Copy to Clipboard" on the n-th row of the Source tree.
    [Arguments]    ${n}
    ${y}=    Evaluate    ${SOURCE_FIRST_ROW_Y} + ${RESULTS_ROW_STEP} * int(${n})
    ${text}=    Copy From Menu At    ${SOURCE_ROW_X}    ${y}
    RETURN    ${text}

Copy Results Text View
    [Documentation]    The text the Results pane's Text view shows, copied the way a
    ...    person would: the view is a selectable label, so press at its first character,
    ...    drag to the far corner and press Ctrl+C. Switches the pane to Text first.
    Show Results As Text
    Wait Until Keyword Succeeds    4x    0.5s    Try Copy Results Text View
    ${text}=    Get Clipboard
    RETURN    ${text}

Try Copy Results Text View
    Set Clipboard    nothing was copied
    Drag Mouse    ${TEXT_VIEW_START_X}    ${TEXT_VIEW_START_Y}    ${TEXT_VIEW_END_X}    ${TEXT_VIEW_END_Y}
    Press Keys    ctrl    c
    Sleep    0.4s
    Clipboard Should Not Be    nothing was copied

Results Should Be Json
    [Documentation]    Every result, compared as JSON values: `expected` is the JSON of
    ...    the array of results (`["Alice","Bob"]`, `[]`, `[1,[2]]`). Formatting does not
    ...    matter, only the values.
    [Arguments]    ${expected}
    ${text}=    Copy All Results
    ${actual}=    Evaluate    json.loads($text)    modules=json
    ${wanted}=    Evaluate    json.loads($expected)    modules=json
    Should Be Equal    ${actual}    ${wanted}
    ...    msg=The results were ${text}, expected ${expected}

Results Should Be Text
    [Documentation]    Every result as the text "Copy to Clipboard" gives for CSV or TSV
    ...    results: the rows joined by line breaks, with none after the last.
    [Arguments]    ${expected}
    ${text}=    Copy All Results
    Should Be Equal    ${text}    ${expected}

Query Should Give
    [Documentation]    Runs `query` and checks every result against the JSON array
    ...    `expected`. The engine is left on auto-detect, which is what a person gets:
    ...    these queries start with a dot, a bracket or a function name, none of which
    ...    is another engine's marker, so they run as jq (and a wrong guess would show
    ...    as an error, not as these results).
    [Arguments]    ${query}    ${expected}
    Run Query    ${query}
    Results Should Be Json    ${expected}

Rows Should Be
    [Documentation]    Runs `query` (it ends in @csv or @tsv) and checks the rows "Copy to
    ...    Clipboard" gives for all the results.
    [Arguments]    ${query}    ${expected}
    Run Query    ${query}
    Results Should Be Text    ${expected}

Format Note Should Be Shown
    [Documentation]    The dim "CSV"/"TSV" beside Tree and Text is drawn: something in its
    ...    place is brighter than the background.
    ${left}    ${top}    ${right}    ${bottom}=    Get Ink Bounds    @{FORMAT_NOTE_AREA}    threshold=70
    ${width}=    Evaluate    ${right} - ${left}
    Should Be True    ${width} > 10    msg=The note is only ${width} px wide

Format Note Should Be Hidden
    [Documentation]    Nothing is drawn where the note would be (a JSON result has none).
    Region Should Be Plain    @{FORMAT_NOTE_AREA}
    ...    msg=Expected no CSV/TSV note beside Tree and Text

Hover And Read
    [Documentation]    Rests the pointer on (x, y) and returns what the tooltip in the area
    ...    says, read by OCR. The pointer goes away first, so that a tooltip already
    ...    showing for something else is gone. Retried, as a tooltip takes a moment.
    [Arguments]    ${x}    ${y}    ${expect}    @{area}
    Wait Until Keyword Succeeds    4x    0.3s
    ...    Hover Once And Expect    ${x}    ${y}    ${expect}    @{area}
    ${text}=    Read Region Text    @{area}
    RETURN    ${text}

Hover Once And Expect
    [Arguments]    ${x}    ${y}    ${expect}    @{area}
    Move Mouse To    600    450
    Sleep    0.3s
    Move Mouse To    ${x}    ${y}
    Sleep    1.3s
    Region Should Contain Text    @{area}    ${expect}

Hover Format Note
    [Documentation]    The tooltip of the CSV/TSV note: "The query ends in @csv, so each
    ...    result is a row of CSV text. ..."
    ${text}=    Hover And Read    ${FORMAT_NOTE_X}    ${RESULTS_HEADER_Y}    query ends in    @{NOTE_TOOLTIP_AREA}
    RETURN    ${text}

Hover Results Save
    [Documentation]    The tooltip of the Results header's Save...; it says which format
    ...    the file will be only while the results are rows of CSV or TSV.
    ${text}=    Hover And Read    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}    Save the results    @{SAVE_TOOLTIP_AREA}
    RETURN    ${text}

Results Save Should Have No Tooltip
    [Documentation]    JSON results have none: Save... says nothing about a format when
    ...    there is only one. The pointer rests on it long enough for a tooltip to
    ...    have appeared.
    Move Mouse To    600    450
    Sleep    0.3s
    Move Mouse To    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}
    Sleep    1.5s
    Region Should Not Contain Text    @{SAVE_TOOLTIP_AREA}    Save the results

Portal Request Count
    [Documentation]    How many file dialogs the app has opened so far.
    ${requests}=    Get Portal Requests
    ${count}=    Get Length    ${requests}
    RETURN    ${count}

Wait For Dialog After
    [Documentation]    Waits until the app has opened one more file dialog than `before`
    ...    (a count from `Portal Request Count`) and returns that dialog's request: what the
    ...    app asked for. Counting, so that a second dialog in one test is not mistaken for
    ...    the first.
    [Arguments]    ${before}
    ${want}=    Evaluate    int(${before}) + 1
    ${requests}=    Wait Until Portal Is Asked    ${want}    timeout=8
    RETURN    ${requests}[-1]

Save Results Accepting
    [Documentation]    Presses the Results header's Save... with the file dialog answered
    ...    as `Portal Will Save To` says; returns the dialog's request (what the app
    ...    asked for).
    [Arguments]    ${path}
    ${before}=    Portal Request Count
    Portal Will Save To    ${path}
    Click At    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}
    ${request}=    Wait For Dialog After    ${before}
    RETURN    ${request}

Save Results Suggested In
    [Documentation]    Presses the Results header's Save... and accepts the name the dialog
    ...    suggests, in `folder`. Returns the dialog's request (what the app asked for).
    [Arguments]    ${folder}
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${folder}
    Click At    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}
    ${request}=    Wait For Dialog After    ${before}
    RETURN    ${request}

Browse And Choose
    [Documentation]    Presses … with the dialog answered as choosing `path`; returns the
    ...    dialog's request.
    [Arguments]    ${path}
    ${before}=    Portal Request Count
    Portal Will Pick    ${path}
    Click At    ${BROWSE_X}    ${TOOLBAR_Y}
    ${request}=    Wait For Dialog After    ${before}
    RETURN    ${request}

Wait For File
    [Documentation]    The file exists and the app has finished writing it (its status bar
    ...    says where it saved): the file is written by the worker thread, a moment after
    ...    the dialog returns.
    [Arguments]    ${path}
    Wait Until Created    ${path}    timeout=10s
    Wait Until Region Contains Text    @{STATUS_BAR}    Saved    timeout=8

File Should Be
    [Documentation]    The file holds exactly this text (UTF-8).
    [Arguments]    ${path}    ${expected}
    ${text}=    Get File    ${path}    encoding=UTF-8
    Should Be Equal    ${text}    ${expected}

File Should Be Pretty Json
    [Documentation]    The file is the JSON value pretty-printed the way the app writes it:
    ...    two-space indent, one array item or object member to a line.
    [Arguments]    ${path}    ${expected}
    ${text}=    Get File    ${path}    encoding=UTF-8
    Should Be Pretty Json    ${text}    ${expected}

Should Be Pretty Json
    [Arguments]    ${text}    ${expected}
    ${wanted}=    Evaluate    json.dumps(json.loads($expected), indent=2, ensure_ascii=False)    modules=json
    Should Be Equal    ${text}    ${wanted}

Status Bar Should Say
    [Arguments]    ${text}    ${timeout}=5
    Wait Until Region Contains Text    @{STATUS_BAR}    ${text}    timeout=${timeout}
