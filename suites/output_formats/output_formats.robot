*** Settings ***
Documentation     CSV and TSV output -- see docs/18_output_formats.md. A jq query that
...               ends in `@csv` or `@tsv` makes one string per result, each a row of a
...               table. Written as JSON that is a quoted, escaped string, which no
...               spreadsheet reads, so the app writes such results as the rows they are:
...               "Copy to Clipboard", the Text view and Save... all follow the query,
...               and a note beside Tree and Text ("CSV" or "TSV") says so.
...
...               The text is checked exactly: through the clipboard (a row's menu, the
...               Results root's menu, and the Text view, whose text is selected with the
...               mouse and copied) and through the files Save... writes. The file dialog
...               is answered by the stand-in portal (resources/fake_portal.py), which
...               also records what the app asked for: the suggested name and the file
...               filter.
Resource          ../../resources/results.resource
Force Tags        output_formats
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${PEOPLE_CSV}          .[] | [.name, .age] | @csv
${PEOPLE_TSV}          .[] | [.name, .age] | @tsv
${PEOPLE_CSV_ROWS}     "Alice",34\n"Bob",19\n"Carol",45
${PEOPLE_TSV_ROWS}     Alice\t34\nBob\t19\nCarol\t45
${RESULTS_WINDOW}      jsonquery — Results
# In the Results pane's window (600 wide) everything of the pane is 600 left of and 125
# above where it is in the main window: the header at y=17, Save... at x=543, the root row
# at y=39, the first result at y=60, and the note at x 148-200.
${POP_HEADER_Y}        17
${POP_SAVE_X}          543
${POP_ROOT_X}          80
${POP_ROOT_Y}          39
${POP_ROW_X}           100
${POP_FIRST_ROW_Y}     60
@{POP_NOTE_AREA}       148    9    52    18
${AWKWARD_CSV}         .[] | [.name, .note] | @csv
${AWKWARD_TSV}         .[] | [.name, .note] | @tsv
# jq's own output for the two queries over awkward_text.json: commas, doubled
# quotes, a line break inside a field, a tab, a backslash.
${AWKWARD_CSV_ROWS}    "Smith, Jo","said ""hi"""\n"Ada","two\nlines"\n"Tab\tman","C:\\temp"
${AWKWARD_TSV_ROWS}    Smith, Jo\tsaid "hi"\nAda\ttwo\\nlines\nTab\\tman\tC:\\\\temp

*** Keywords ***
Load People
    Load Fixture    people.json

Hover Format Note Should Say
    [Documentation]    The note's tooltip holds all these phrases (read by OCR, so line
    ...    breaks and runs of spaces are folded into single spaces first).
    [Arguments]    @{words}
    ${tip}=    Hover Format Note
    ${flat}=    Evaluate    " ".join($tip.split())
    FOR    ${word}    IN    @{words}
        Should Contain    ${flat}    ${word}
    END

Pop Out Results
    [Documentation]    Opens the Results pane in a window of its own and makes it the one the
    ...    clicks and reads are relative to.
    Click At    ${RESULTS_POPOUT_X}    ${RESULTS_HEADER_Y}
    Wait Until Window Exists    ${RESULTS_WINDOW}    timeout=8
    Switch To Window    ${RESULTS_WINDOW}
    Sleep    0.8s

Popped Note Should Be Shown
    ${left}    ${top}    ${right}    ${bottom}=    Get Ink Bounds    @{POP_NOTE_AREA}    threshold=70
    ${width}=    Evaluate    ${right} - ${left}
    Should Be True    ${width} > 10    msg=The note is only ${width} px wide

Nothing Should Have Been Asked
    [Documentation]    The app opened no file dialog.
    ${requests}=    Get Portal Requests
    Should Be Empty    ${requests}

File Should Hold Json
    [Arguments]    ${path}    ${expected}
    ${text}=    Get File    ${path}
    ${actual}=    Evaluate    json.loads($text)    modules=json
    ${wanted}=    Evaluate    json.loads($expected)    modules=json
    Should Be Equal    ${actual}    ${wanted}

*** Test Cases ***
# --- the note beside Tree and Text -----------------------------------------------

TC-FMT-001 A JSON Result Has No Format Note
    [Documentation]    The note is for rows only: a query whose results are JSON values
    ...    draws nothing beside Tree and Text.
    [Tags]    p1
    Load People
    Run Query    .[] | .name
    Move Mouse To    600    450
    Format Note Should Be Hidden

TC-FMT-002 A Query Ending In @csv Shows The CSV Note
    [Documentation]    The note is drawn, and its tooltip says why: the query ends in
    ...    @csv, so each result is a row of CSV text.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    Format Note Should Be Shown
    Hover Format Note Should Say    @csv    CSV text    write the rows as CSV

TC-FMT-003 A Query Ending In @tsv Shows The TSV Note
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_TSV}
    Format Note Should Be Shown
    Hover Format Note Should Say    @tsv    TSV text    write the rows as TSV

TC-FMT-004 The Note Follows The Last Query That Ran
    [Documentation]    CSV, then a JSON query (the note goes), then TSV (it comes back,
    ...    saying TSV).
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    Format Note Should Be Shown
    Run Query    .[] | .name
    Move Mouse To    600    450
    Format Note Should Be Hidden
    Run Query    ${PEOPLE_TSV}
    Format Note Should Be Shown
    Hover Format Note Should Say    @tsv    TSV text

TC-FMT-005 Editing The Query Without Running It Leaves The Note Alone
    [Documentation]    The note describes the results on show, which the last run made:
    ...    typing another query changes it only when that query is run.
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    Click At    100    58
    Press Keys    ctrl    a
    Type Text    .[] | .name
    Sleep    0.5s
    Move Mouse To    600    450
    Format Note Should Be Shown
    Run Current Query
    Move Mouse To    600    450
    Format Note Should Be Hidden

TC-FMT-006 @csv Before The Last Stage Does Not Make Rows
    [Documentation]    `map(... | @csv) | length` uses @csv on the way to a number; what
    ...    the query ends in decides, and that is `length`.
    [Tags]    p1
    Load People
    Run Query    map([.name, .age] | @csv) | length
    Move Mouse To    600    450
    Format Note Should Be Hidden
    Results Should Be Json    [3]

TC-FMT-007 A Query Wrapped In Brackets Is JSON
    [Documentation]    `[ ... | @csv ]` collects the rows into one array of strings, which
    ...    is JSON and is written as JSON, escapes and all: the contrast case of the
    ...    tutorial's "Copy & save as CSV or TSV" page.
    [Tags]    p1
    Load People
    Run Query    [.[] | [.name, .age] | @csv]
    Move Mouse To    600    450
    Format Note Should Be Hidden
    Results Should Be Json    [["\\"Alice\\",34", "\\"Bob\\",19", "\\"Carol\\",45"]]

TC-FMT-008 A Parenthesised Last Stage Still Counts
    [Documentation]    `... | (... | @csv)` ends in a program of its own that ends in @csv.
    [Tags]    p2
    Load People
    Run Query    .[] | ([.name] | @csv)
    Format Note Should Be Shown

TC-FMT-009 A Trailing Comment Does Not Hide The Format
    [Tags]    p2
    Load People
    Run Query    .[] | [.name] | @csv # one name per row
    Format Note Should Be Shown
    Results Should Be Text    "Alice"\n"Bob"\n"Carol"

TC-FMT-010 The Try Operator After @csv Is Still CSV
    [Documentation]    `@csv?` drops the rows that cannot be formatted and is otherwise the
    ...    same stage.
    [Tags]    p3
    Load People
    Run Query    .[] | [.name] | @csv?
    Format Note Should Be Shown

TC-FMT-011 Another Engine Never Writes Rows
    [Documentation]    With JSONPath chosen the query is not jq, so nothing it says about
    ...    @csv matters: no note.
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    Format Note Should Be Shown
    Select Engine    JSONPath
    Run Query    $[*].name
    Move Mouse To    600    450
    Format Note Should Be Hidden

TC-FMT-012 Clear Removes The Note
    [Documentation]    Clear unloads the document and its results; there are no rows left
    ...    to describe.
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    Format Note Should Be Shown
    Click At    ${CLEAR_BUTTON_X}    ${TOOLBAR_Y}
    Sleep    0.8s
    Move Mouse To    600    450
    Format Note Should Be Hidden

TC-FMT-013 Loading Another Document Removes The Note
    [Documentation]    A new document replaces the results of the old one, so the note
    ...    goes until a query makes rows again.
    [Tags]    p2
    ${base_url}=    Start Fixture Server    ${HTTP_FIXTURES_DIR}
    Load People
    Run Query    ${PEOPLE_CSV}
    Format Note Should Be Shown
    Load Via Url    ${base_url}/valid.json
    Wait Until Pasted Source Is Replaced
    Sleep    0.8s
    Move Mouse To    600    450
    Format Note Should Be Hidden
    [Teardown]    Run Keywords    Stop Fixture Server    AND    Close Jsonquery App

TC-FMT-014 Save Says Which Format It Will Write
    [Documentation]    Save...'s tooltip names the format while the results are rows, and
    ...    says nothing for JSON.
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    ${tip}=    Hover Results Save
    Should Contain    ${tip}    Save the results as CSV
    Run Query    .[] | .name
    Results Save Should Have No Tooltip

# --- the views ---------------------------------------------------------------------

TC-FMT-020 The Tree Lists One Row Per Result
    [Documentation]    CSV results are still a list in the Tree: three results, three rows.
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    Status Bar Should Say    3 result
    Region Should Contain Text    @{RESULTS_PANEL}    Alice
    Region Should Contain Text    @{RESULTS_PANEL}    Bob
    Region Should Contain Text    @{RESULTS_PANEL}    Carol

TC-FMT-021 The Text View Shows The Rows
    [Documentation]    Not a JSON array of escaped strings: the rows, one to a line.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    ${text}=    Copy Results Text View
    Should Be Equal    ${text}    ${PEOPLE_CSV_ROWS}

TC-FMT-022 The Text View Of TSV Keeps Its Tabs And Escapes
    [Tags]    p1
    Load Fixture    awkward_text.json
    Run Query    ${AWKWARD_TSV}
    ${text}=    Copy Results Text View
    Should Be Equal    ${text}    ${AWKWARD_TSV_ROWS}

TC-FMT-023 The Text View Of CSV Keeps A Line Break Inside A Field
    [Documentation]    The second row's note holds a line break; in CSV it stays inside the
    ...    quotes, so that row takes two lines of the view.
    [Tags]    p2
    Load Fixture    awkward_text.json
    Run Query    ${AWKWARD_CSV}
    ${text}=    Copy Results Text View
    Should Be Equal    ${text}    ${AWKWARD_CSV_ROWS}

TC-FMT-024 The Text View Of JSON Results Is Pretty JSON
    [Documentation]    The contrast: names as JSON are a pretty-printed array of strings.
    [Tags]    p1
    Load People
    Run Query    .[] | .name
    ${text}=    Copy Results Text View
    Should Be Pretty Json    ${text}    ["Alice", "Bob", "Carol"]

TC-FMT-025 Switching Between Tree And Text Keeps The Rows
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    Show Results As Text
    Show Results As Tree
    Format Note Should Be Shown
    Results Should Be Text    ${PEOPLE_CSV_ROWS}

TC-FMT-026 A Long List Of Rows Is Cut Short In The Text View
    [Documentation]    The Text view shows the first 20,000 rows and says so, with an Expand All
    ...    button beside the notice (the notice is dim, the button is not); a short list has
    ...    neither. Expand All renders them all, and then the button goes. (OCR reads the
    ...    button as "Expand/All", so the case looks for its first word.)
    [Tags]    p2
    Load People
    Run Query    range(30) | [., "row"] | @csv
    Status Bar Should Say    30 result    timeout=20
    Show Results As Text
    Sleep    1s
    Region Should Not Contain Text    @{RESULTS_PANEL}    Expand
    Run Query    range(25000) | [., "row"] | @csv
    Status Bar Should Say    25000 result    timeout=30
    Wait Until Region Contains Text    @{RESULTS_PANEL}    Expand    timeout=10
    Click Text In Region    @{RESULTS_PANEL}    Expand
    Wait Until Keyword Succeeds    30x    1s
    ...    Region Should Not Contain Text    @{RESULTS_PANEL}    Expand

# --- Copy to Clipboard ---------------------------------------------------------------

TC-FMT-030 Copying All CSV Results Gives The Rows
    [Documentation]    The Results root's Copy to Clipboard: every row, a line each, with no
    ...    line break after the last.
    [Tags]    p1
    Load People
    Rows Should Be    ${PEOPLE_CSV}    ${PEOPLE_CSV_ROWS}

TC-FMT-031 Copying One CSV Row Gives That Row
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    ${row}=    Copy Result Row    1
    Should Be Equal    ${row}    "Bob",19

TC-FMT-032 Copying All TSV Results Gives Tabbed Rows
    [Tags]    p1
    Load People
    Rows Should Be    ${PEOPLE_TSV}    ${PEOPLE_TSV_ROWS}

TC-FMT-033 Copying One TSV Row Gives That Row
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_TSV}
    ${row}=    Copy Result Row    2
    Should Be Equal    ${row}    Carol\t45

TC-FMT-034 CSV Quoting Is Exact
    [Documentation]    A comma, a doubled quote, a line break, a tab and a backslash: what
    ...    jq's @csv writes, byte for byte.
    [Tags]    p1
    Load Fixture    awkward_text.json
    Rows Should Be    ${AWKWARD_CSV}    ${AWKWARD_CSV_ROWS}

TC-FMT-035 TSV Escaping Is Exact
    [Documentation]    @tsv writes a tab inside a field as \\t, a line break as \\n and a
    ...    backslash as \\\\, and quotes nothing.
    [Tags]    p1
    Load Fixture    awkward_text.json
    Rows Should Be    ${AWKWARD_TSV}    ${AWKWARD_TSV_ROWS}

TC-FMT-036 Non-ASCII Text Survives
    [Documentation]    Accents, Chinese characters and a ring: UTF-8 through the clipboard.
    [Tags]    p1
    Load Fixture    unicode.json
    Run Query By Paste    .[] | [.name, .city] | @csv
    Results Should Be Text    "Zoë","Zürich"\n"李雷","北京"\n"Åsa","Malmö"

TC-FMT-037 JSON Results Still Copy As JSON
    [Documentation]    The contrast: without @csv or @tsv nothing changed. All the names
    ...    are an array; one name is a JSON string, quotes included.
    [Tags]    p1
    Load People
    Run Query    .[] | .name
    Results Should Be Json    ["Alice", "Bob", "Carol"]
    ${row}=    Copy Result Row    0
    Should Be Equal    ${row}    "Alice"

TC-FMT-038 A Wrapped @csv Query Copies JSON Strings
    [Documentation]    `[... | @csv]` is one array of strings, so one row, not three.
    [Tags]    p1
    Load People
    Run Query    [.[] | [.name, .age] | @csv]
    ${row}=    Copy Result Row    0
    ${parsed}=    Evaluate    json.loads($row)    modules=json
    Should Be Equal    ${parsed}    ${{ ['"Alice",34', '"Bob",19', '"Carol",45'] }}

TC-FMT-039 The Source Pane Still Copies JSON
    [Documentation]    The format is the Results pane's: the Source pane's rows stay JSON,
    ...    whatever the query makes.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    ${row}=    Copy Source Row    0
    ${parsed}=    Evaluate    json.loads($row)    modules=json
    Should Be Equal    ${parsed}    ${{ {"name": "Alice", "age": 34, "role": "engineer"} }}

TC-FMT-040 A Single Row Has No Line Break After It
    [Tags]    p2
    Load People
    Rows Should Be    .[0] | [.name, .age] | @csv    "Alice",34

TC-FMT-041 A Header Row And Then The Data Rows
    [Documentation]    The first form the tutorial teaches: `["name","age"], (rows) | @csv`
    ...    makes the header row the first result.
    [Tags]    p1
    Load People
    Rows Should Be    ["name", "age"], (.[] | [.name, .age]) | @csv    "name","age"\n"Alice",34\n"Bob",19\n"Carol",45

TC-FMT-042 Numbers Booleans And Null In A Row
    [Documentation]    CSV: numbers and booleans bare, null empty, strings quoted. TSV: all
    ...    bare.
    [Tags]    p1
    Load People
    Rows Should Be    [1, 1.5, true, null, "x"] | @csv    1,1.5,true,,"x"
    Rows Should Be    [1, 1.5, true, null, "x"] | @tsv    1\t1.5\ttrue\t\tx

TC-FMT-043 An Empty Result Has No Rows And Nothing To Save
    [Documentation]    A query that matches nothing makes no rows; Save... does nothing then
    ...    (it is disabled), and no dialog opens.
    [Tags]    p2
    Load People
    Run Query    .[] | select(.age > 100) | [.name] | @csv
    Status Bar Should Say    result
    Click At    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}
    Sleep    1s
    Nothing Should Have Been Asked

TC-FMT-044 A Row That Cannot Be Made Is An Item Error The Others Survive
    [Documentation]    Bob's branch produces a number, which @csv refuses; the run goes on and
    ...    counts one item error, and the two rows that could be made are the results.
    [Tags]    p1
    Load People
    Run Query    .[] | if .age > 30 then [.name, .age] else .age end | @csv
    Status Bar Should Say    1 item error
    Status Bar Should Say    2 result
    Results Should Be Text    "Alice",34\n"Carol",45

TC-FMT-045 Copying A Long List Of Rows Gives Every Row
    [Documentation]    The Text view stops at 20,000 rows, but Copy to Clipboard does not depend on
    ...    the view: the root's copy is all 25,000, the first and the last right.
    [Tags]    p2
    Load People
    Run Query    range(25000) | [., "row"] | @csv
    Status Bar Should Say    25000 result    timeout=30
    ${text}=    Copy All Results
    ${lines}=    Split To Lines    ${text}
    Length Should Be    ${lines}    25000
    Should Be Equal    ${lines}[0]    0,"row"
    Should Be Equal    ${lines}[24999]    24999,"row"

# --- Save... ----------------------------------------------------------------------------

TC-FMT-050 Saving CSV Results Writes The Rows
    [Documentation]    The dialog suggests results.csv and offers a CSV file type; accepted
    ...    as it opened, the file holds the rows, each ending in a line break.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    ${dir}=    Make Temp Directory
    ${asked}=    Save Results Suggested In    ${dir}
    Should Be Equal    ${asked}[method]    SaveFile
    Should Be Equal    ${asked}[current_name]    results.csv
    Should Be Equal    ${asked}[filters]    ${{ [{"name": "CSV", "globs": ["*.csv"]}] }}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    "Alice",34\n"Bob",19\n"Carol",45\n

TC-FMT-051 Saving TSV Results Writes Tabbed Rows
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_TSV}
    ${dir}=    Make Temp Directory
    ${asked}=    Save Results Suggested In    ${dir}
    Should Be Equal    ${asked}[current_name]    results.tsv
    Should Be Equal    ${asked}[filters]    ${{ [{"name": "TSV", "globs": ["*.tsv"]}] }}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.tsv    Alice\t34\nBob\t19\nCarol\t45\n

TC-FMT-052 Saving JSON Results Still Writes Pretty JSON
    [Documentation]    The contrast: results.json, a JSON file type, the array pretty-printed.
    [Tags]    p1
    Load People
    Run Query    .[] | .name
    ${dir}=    Make Temp Directory
    ${asked}=    Save Results Suggested In    ${dir}
    Should Be Equal    ${asked}[current_name]    results.json
    Should Be Equal    ${asked}[filters]    ${{ [{"name": "JSON", "globs": ["*.json"]}] }}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be Pretty Json    ${dir}/results.json    ["Alice", "Bob", "Carol"]

TC-FMT-053 Cancelling The Dialog Writes Nothing
    [Documentation]    A person who closes the dialog gets no file, and the app carries on:
    ...    the next query runs.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    ${dir}=    Make Temp Directory
    Portal Will Cancel
    Click At    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}
    Wait Until Portal Is Asked    1    timeout=8
    Sleep    1s
    ${files}=    List Directory    ${dir}
    Should Be Empty    ${files}
    Run Query    .[0].name
    Status Bar Should Say    1 result

TC-FMT-054 A Row Saved From Its Menu Is Written As That Row
    [Documentation]    Right-click the second result, choose Save...: the suggested name is
    ...    that row's (item_1.csv) and the file is that one row.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    ${dir}=    Make Temp Directory
    Portal Will Accept Suggested Name In    ${dir}
    ${y}=    Results Row Y    1
    Right Click At    ${RESULTS_ROW_X}    ${y}
    Sleep    0.5s
    ${item_x}=    Evaluate    ${RESULTS_ROW_X} + ${MENU_ITEM_X}
    ${item_y}=    Evaluate    ${y} + ${MENU_SAVE_Y}
    Click At    ${item_x}    ${item_y}
    ${asked}=    Wait Until Portal Is Asked    1    timeout=8
    Should Be Equal    ${asked}[0][current_name]    item_1.csv
    Should Be Equal    ${asked}[0][filters]    ${{ [{"name": "CSV", "globs": ["*.csv"]}] }}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/item_1.csv    "Bob",19\n

TC-FMT-055 The Root Saved From Its Menu Is Every Row
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_TSV}
    ${dir}=    Make Temp Directory
    Portal Will Accept Suggested Name In    ${dir}
    Right Click At    ${RESULTS_ROOT_X}    ${RESULTS_ROOT_Y}
    Sleep    0.5s
    ${item_x}=    Evaluate    ${RESULTS_ROOT_X} + ${MENU_ITEM_X}
    ${item_y}=    Evaluate    ${RESULTS_ROOT_Y} + ${MENU_SAVE_Y}
    Click At    ${item_x}    ${item_y}
    ${asked}=    Wait Until Portal Is Asked    1    timeout=8
    Should Be Equal    ${asked}[0][current_name]    results.tsv
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.tsv    Alice\t34\nBob\t19\nCarol\t45\n

TC-FMT-056 Awkward Rows Are Saved Exactly
    [Documentation]    The file for the quoting data is what jq -r writes for it.
    [Tags]    p1
    Load Fixture    awkward_text.json
    Run Query    ${AWKWARD_CSV}
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    ${AWKWARD_CSV_ROWS}\n
    Run Query    ${AWKWARD_TSV}
    Portal Will Accept Suggested Name In    ${dir}
    Click At    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.tsv    ${AWKWARD_TSV_ROWS}\n

TC-FMT-057 Non-ASCII Text Is Saved As UTF-8 Without A Byte Order Mark
    [Tags]    p1
    Load Fixture    unicode.json
    Run Query By Paste    .[] | [.name, .city] | @csv
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    "Zoë","Zürich"\n"李雷","北京"\n"Åsa","Malmö"\n
    ${bytes}=    Get Binary File    ${dir}/results.csv
    Should Be Equal As Integers    ${bytes}[0]    34    msg=The file starts with a quote, not a byte order mark

TC-FMT-058 A Result Past The Live Preview Is Saved Whole
    [Documentation]    The Results pane keeps the first 50,000 results; saving fetches all
    ...    of them again first. 60,000 rows come out as 60,000 lines, the last of them
    ...    the last row.
    [Tags]    p2
    Load People
    Run Query    range(60000) | [., "row"] | @csv
    Status Bar Should Say    capped    timeout=20
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until File Has Lines    ${dir}/results.csv    60000
    ${text}=    Get File    ${dir}/results.csv
    ${lines}=    Split To Lines    ${text}
    Should Be Equal    ${lines}[0]    0,"row"
    Should Be Equal    ${lines}[59999]    59999,"row"

TC-FMT-059 The File Follows The Latest Query
    [Documentation]    CSV saved, then a JSON query, then Save... again: the second file is
    ...    JSON, under the JSON name.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    ${PEOPLE_CSV_ROWS}\n
    Run Query    .[] | .name
    Portal Will Accept Suggested Name In    ${dir}
    Click At    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be Pretty Json    ${dir}/results.json    ["Alice", "Bob", "Carol"]

TC-FMT-060 Ctrl+S In The Results Pane Saves The Rows
    [Documentation]    The shortcut saves the pane that has the focus: after a click in the
    ...    Results pane, rows.
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    ${dir}=    Make Temp Directory
    Portal Will Accept Suggested Name In    ${dir}
    Click At    900    500
    Sleep    0.3s
    Press Keys    ctrl    s
    ${asked}=    Wait Until Portal Is Asked    1    timeout=8
    Should Be Equal    ${asked}[0][current_name]    results.csv
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    ${PEOPLE_CSV_ROWS}\n

TC-FMT-061 A Name The Person Chose Is Used As Given
    [Documentation]    The format follows the query, not the file name: rows saved as
    ...    notes.txt are still CSV.
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    ${dir}=    Make Temp Directory
    Save Results Accepting    ${dir}/notes.txt
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/notes.txt    ${PEOPLE_CSV_ROWS}\n

TC-FMT-062 Saving Into A Missing Folder Says So
    [Documentation]    The write fails and the status bar says "Save error", in red: the
    ...    rows were not lost, the results are still on screen.
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    Save Results Accepting    /no/such/folder/rows.csv
    Wait Until Region Contains Text    @{STATUS_BAR}    Save error    timeout=8
    Region Should Contain Text    @{RESULTS_PANEL}    Alice

TC-FMT-063 The Source Pane Saves JSON Whatever The Results Are
    [Documentation]    Source's Save... writes the document, as JSON, named data.json for a
    ...    pasted one, with a JSON file type -- while the Results are CSV.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    ${dir}=    Make Temp Directory
    Portal Will Accept Suggested Name In    ${dir}
    Click At    566    144
    ${asked}=    Wait Until Portal Is Asked    1    timeout=8
    Should Be Equal    ${asked}[0][current_name]    data.json
    Should Be Equal    ${asked}[0][filters]    ${{ [{"name": "JSON", "globs": ["*.json"]}] }}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Hold Json    ${dir}/data.json    [{"name":"Alice","age":34,"role":"engineer"},{"name":"Bob","age":19,"role":"intern"},{"name":"Carol","age":45,"role":"manager"}]

# --- the Results pane in a window of its own --------------------------------------------------

TC-FMT-070 The Popped-Out Results Pane Has The Note
    [Documentation]    The pane is the same pane in its window: the CSV note beside Tree and
    ...    Text, and the tooltip that says why.
    [Tags]    p2
    Load People
    Run Query    ${PEOPLE_CSV}
    Pop Out Results
    Popped Note Should Be Shown

TC-FMT-071 The Popped-Out Results Pane Has No Note For JSON
    [Tags]    p2
    Load People
    Run Query    .[] | .name
    Pop Out Results
    Region Should Be Plain    @{POP_NOTE_AREA}

TC-FMT-072 Copying From The Popped-Out Pane Gives Rows
    [Documentation]    The Results root of the window copies every row; one row copies that row.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    Pop Out Results
    ${all}=    Copy From Menu At    ${POP_ROOT_X}    ${POP_ROOT_Y}
    Should Be Equal    ${all}    ${PEOPLE_CSV_ROWS}
    ${row_y}=    Evaluate    ${POP_FIRST_ROW_Y} + ${RESULTS_ROW_STEP}
    ${row}=    Copy From Menu At    ${POP_ROW_X}    ${row_y}
    Should Be Equal    ${row}    "Bob",19

TC-FMT-073 Saving From The Popped-Out Pane Writes The Rows
    [Documentation]    Save... in the window asks for results.csv and writes the rows.
    [Tags]    p1
    Load People
    Run Query    ${PEOPLE_CSV}
    Pop Out Results
    ${dir}=    Make Temp Directory
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${dir}
    Click At    ${POP_SAVE_X}    ${POP_HEADER_Y}
    ${asked}=    Wait For Dialog After    ${before}
    Should Be Equal    ${asked}[current_name]    results.csv
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    ${PEOPLE_CSV_ROWS}\n
