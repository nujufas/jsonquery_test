*** Settings ***
Documentation     The browse button (…) beside the source field -- see docs/02_opening_sources.md
...               (TC-OPEN-001 and TC-OPEN-002, which were blocked while the file dialog could
...               not be driven, and what else the button does). The dialog is answered by the
...               stand-in portal (resources/fake_portal.py): a test says which file the person
...               chose, or that they closed the dialog, and reads back what the app asked for.
Resource          ../../resources/results.resource
Force Tags        opening_sources
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The file's size, in the toolbar after the buttons (a file source has no "(pasted JSON)"
# note before it); the status area of the other suites starts under the end of the field.
@{FILE_SIZE_AREA}     945    0    95    22
${JSON_EXTENSIONS}    ${{ ["*.json", "*.ndjson", "*.jsonl", "*.log", "*.txt"] }}

*** Test Cases ***
TC-OPEN-001 Open A Valid JSON File Through The Dialog
    [Documentation]    The file chosen is loaded: the field shows its path, the toolbar its
    ...    size, the status bar the parse time and the Source pane the content; and the
    ...    window is still titled "jsonquery".
    [Tags]    p1
    Browse And Choose    ${FIXTURES}/simple_object.json
    Wait Until Region Contains Text    @{STATUS_BAR}    Parsed    timeout=8
    Region Should Contain Text    @{SOURCE_FIELD}    simple_object.json
    Wait Until Region Matches    @{FILE_SIZE_AREA}    \\d+ ?[B8]    timeout=5    psm=7
    Region Should Contain Text    @{SOURCE_PANEL}    keys
    Region Should Not Contain Text    @{STATUS_AREA}    NDJSON
    ${exists}=    Window Exists    jsonquery
    Should Be True    ${exists}

TC-OPEN-002 The Dialog Offers Only The JSON-Like File Types
    [Documentation]    One file type, JSON, matching .json, .ndjson, .jsonl, .log and .txt; a
    ...    single file is chosen, not several, and no folder.
    [Tags]    p2
    ${asked}=    Browse And Choose    ${FIXTURES}/simple_object.json
    Should Be Equal    ${asked}[method]    OpenFile
    Length Should Be    ${asked}[filters]    1
    Should Be Equal    ${asked}[filters][0][name]    JSON
    Should Be Equal    ${asked}[filters][0][globs]    ${JSON_EXTENSIONS}
    Should Not Be True    ${asked}[multiple]
    Should Not Be True    ${asked}[directory]

TC-OPEN-022 Closing The Dialog Loads Nothing
    [Documentation]    Cancelled, the dialog leaves the app as it was: no file, an empty
    ...    source field, the paste box still waiting.
    [Tags]    p1
    Portal Will Cancel
    Click At    ${BROWSE_X}    ${TOOLBAR_Y}
    Wait Until Portal Is Asked    1    timeout=8
    Sleep    1s
    Region Should Contain Text    @{SOURCE_PANEL}    Paste JSON here
    Region Should Not Contain Text    @{STATUS_BAR}    Parsed
    Region Should Not Contain Text    @{STATUS_BAR}    Load error

TC-OPEN-023 A File Chosen Replaces The Document On Show
    [Documentation]    With a pasted document loaded, choosing a file replaces it: the
    ...    "(pasted JSON)" note goes and the file's content is on show.
    [Tags]    p1
    Load Fixture    simple_object.json
    Region Should Contain Text    @{STATUS_AREA}    pasted JSON
    Browse And Choose    ${FIXTURES}/people.json
    Wait Until Pasted Source Is Replaced
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=8

TC-OPEN-024 A Line-Delimited File Becomes One Array
    [Documentation]    records.ndjson holds three JSON values, one to a line: they load as an
    ...    array of three, with the note saying how many records there were.
    [Tags]    p2
    Browse And Choose    ${FIXTURES}/records.ndjson
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=8
    Region Should Contain Text    @{STATUS_AREA}    3 NDJSON records

TC-OPEN-025 A File That Is Not JSON Shows A Load Error
    [Tags]    p1
    Browse And Choose    ${FIXTURES}/merge/broken.json
    Wait Until Region Contains Text    @{STATUS_BAR}    Load error    timeout=8
    Region Should Contain Text    @{SOURCE_FIELD}    broken.json

TC-OPEN-026 A File Chosen Can Be Queried At Once
    [Documentation]    From the dialog to a result, with nothing between: choose a file, run a
    ...    query over it, copy the rows.
    [Tags]    p1
    Browse And Choose    ${FIXTURES}/people.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=8
    Run Query    .[] | [.name, .role] | @csv
    Results Should Be Text    "Alice","engineer"\n"Bob","intern"\n"Carol","manager"

TC-OPEN-027 Choosing A File Twice Loads The Second
    [Tags]    p2
    Browse And Choose    ${FIXTURES}/simple_object.json
    Wait Until Region Contains Text    @{STATUS_BAR}    Parsed    timeout=8
    Browse And Choose    ${FIXTURES}/people.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=8
    Region Should Contain Text    @{SOURCE_FIELD}    people.json

TC-OPEN-028 Each Press Asks The Dialog Once
    [Tags]    p3
    Portal Will Cancel
    Portal Will Cancel
    Click At    ${BROWSE_X}    ${TOOLBAR_Y}
    Wait Until Portal Is Asked    1    timeout=8
    Sleep    1s
    ${count}=    Portal Request Count
    Should Be Equal As Integers    ${count}    1
    Click At    ${BROWSE_X}    ${TOOLBAR_Y}
    Wait Until Portal Is Asked    2    timeout=8
