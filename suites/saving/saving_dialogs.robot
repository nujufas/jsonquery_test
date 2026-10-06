*** Settings ***
Documentation     Saving, through the file dialog -- see docs/09_saving.md. These are the
...               cases that were blocked while the dialog could not be driven: the app's
...               file dialog is answered by the stand-in portal (resources/fake_portal.py)
...               which says what the person chose, and records what the app asked for (the
...               suggested name, the folder and the file type). Everything on the app's side
...               is the real thing, down to the file the worker writes.
...
...               Cases that save CSV or TSV rows are in output_formats.robot; here it is the
...               document, its rows and the JSON results.
Resource          ../../resources/results.resource
Force Tags        saving
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${PEOPLE_JSON}        [{"name":"Alice","age":34,"role":"engineer"},{"name":"Bob","age":19,"role":"intern"},{"name":"Carol","age":45,"role":"manager"}]
${TEAM_MEMBERS}       [{"name":"Ada","active":true,"age":36},{"name":"Bo","active":false,"age":41},{"name":"Cy","active":true,"age":29}]
${SOURCE_SAVE_X}      566
${JSON_FILTER}        ${{ [{"name": "JSON", "globs": ["*.json"]}] }}
# The status bar's one line of text, read tightly: dim text ("Saved to ...") is only read
# when the crop is one line high, and then with the single-line page mode.
@{STATUS_LINE}        0    775    1100    25

*** Keywords ***
Load People
    Load Fixture    people.json

Load Team
    Load Fixture    team.json

Source Save Suggested In
    [Documentation]    Source's header Save... with the dialog accepted as it opened, in `dir`.
    [Arguments]    ${dir}
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${dir}
    Click At    ${SOURCE_SAVE_X}    ${RESULTS_HEADER_Y}
    ${request}=    Wait For Dialog After    ${before}
    RETURN    ${request}

Save From Menu At
    [Documentation]    Right-clicks the point, chooses Save... and accepts the dialog as it
    ...    opened, in `dir`. Returns the dialog's request.
    [Arguments]    ${x}    ${y}    ${dir}
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${dir}
    Right Click At    ${x}    ${y}
    Sleep    0.5s
    ${item_x}=    Evaluate    ${x} + ${MENU_ITEM_X}
    ${item_y}=    Evaluate    ${y} + ${MENU_SAVE_Y}
    Click At    ${item_x}    ${item_y}
    ${request}=    Wait For Dialog After    ${before}
    RETURN    ${request}

Source Row Y
    [Arguments]    ${n}
    ${y}=    Evaluate    ${SOURCE_FIRST_ROW_Y} + ${RESULTS_ROW_STEP} * int(${n})
    RETURN    ${y}

File Should Hold
    [Documentation]    The file holds the JSON value, pretty-printed as the app writes it.
    [Arguments]    ${path}    ${expected}
    Wait Until Keyword Succeeds    15x    0.4s    File Should Be Pretty Json    ${path}    ${expected}

Status Line Should Say
    [Arguments]    ${text}    ${timeout}=8
    Wait Until Region Contains Text    @{STATUS_LINE}    ${text}    timeout=${timeout}    psm=7

Status Line Should Not Say
    [Arguments]    ${text}
    Region Should Not Contain Text    @{STATUS_LINE}    ${text}    psm=7

File Should Hold Numbers
    [Documentation]    The file is a JSON array of 0, 1, 2 ... count - 1, once it is complete.
    [Arguments]    ${path}    ${count}
    ${values}=    Wait Until File Holds Json    ${path}
    Length Should Be    ${values}    ${count}
    Should Be Equal As Integers    ${values}[0]    0
    ${last}=    Evaluate    int(${count}) - 1
    Should Be Equal As Integers    ${values}[${last}]    ${last}

*** Test Cases ***
# --- the Source header's Save... -------------------------------------------------------------

TC-SAVE-001a A File Source Is Saved Under Its Own Name
    [Documentation]    A document opened from a file suggests that file's name; accepted, the
    ...    file written is the whole document, pretty-printed.
    [Tags]    p1
    Load Via Url    ${FIXTURES}/people.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=8
    ${dir}=    Make Temp Directory
    ${asked}=    Source Save Suggested In    ${dir}
    Should Be Equal    ${asked}[current_name]    people.json
    Should Be Equal    ${asked}[filters]    ${JSON_FILTER}
    File Should Hold    ${dir}/people.json    ${PEOPLE_JSON}

TC-SAVE-001b A Pasted Source Is Saved As data.json
    [Tags]    p1
    Load People
    ${dir}=    Make Temp Directory
    ${asked}=    Source Save Suggested In    ${dir}
    Should Be Equal    ${asked}[current_name]    data.json
    File Should Hold    ${dir}/data.json    ${PEOPLE_JSON}

TC-SAVE-001c A URL Source Is Saved Under The Last Part Of Its Address
    [Tags]    p2
    ${base_url}=    Start Fixture Server    ${HTTP_FIXTURES_DIR}
    Load Via Url    ${base_url}/valid.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=8
    ${dir}=    Make Temp Directory
    ${asked}=    Source Save Suggested In    ${dir}
    Should Be Equal    ${asked}[current_name]    valid.json
    File Should Hold    ${dir}/valid.json    [{"name":"Alice","age":34,"role":"engineer"},{"name":"Bob","age":19,"role":"intern"},{"name":"Carol","age":45,"role":"manager"}]
    [Teardown]    Run Keywords    Stop Fixture Server    AND    Close Jsonquery App

TC-SAVE-002a The Source Save Stays Available Without A Query
    [Documentation]    No query has run, and the button still opens the dialog.
    [Tags]    p3
    Load People
    ${dir}=    Make Temp Directory
    ${asked}=    Source Save Suggested In    ${dir}
    Should Be Equal    ${asked}[method]    SaveFile

# --- the rows' Save... -------------------------------------------------------------------------

TC-SAVE-003a A Source Row With A Key Is Saved Under That Key
    [Documentation]    team.json's "members" row: members.json, holding just that array.
    [Tags]    p1
    Load Team
    ${dir}=    Make Temp Directory
    ${y}=    Source Row Y    0
    ${asked}=    Save From Menu At    ${SOURCE_ROW_X}    ${y}    ${dir}
    Should Be Equal    ${asked}[current_name]    members.json
    File Should Hold    ${dir}/members.json    ${TEAM_MEMBERS}

TC-SAVE-003b An Element Of The Root Array Is Saved As item_N
    [Tags]    p1
    Load People
    ${dir}=    Make Temp Directory
    ${y}=    Source Row Y    1
    ${asked}=    Save From Menu At    ${SOURCE_ROW_X}    ${y}    ${dir}
    Should Be Equal    ${asked}[current_name]    item_1.json
    File Should Hold    ${dir}/item_1.json    {"name":"Bob","age":19,"role":"intern"}

TC-SAVE-003c The Source Root Is Saved As data.json
    [Documentation]    The root has neither key nor index: the fallback name, and the whole
    ...    document.
    [Tags]    p1
    Load People
    ${dir}=    Make Temp Directory
    ${asked}=    Save From Menu At    ${SOURCE_ROOT_X}    ${SOURCE_ROOT_Y}    ${dir}
    Should Be Equal    ${asked}[current_name]    data.json
    File Should Hold    ${dir}/data.json    ${PEOPLE_JSON}

TC-SAVE-004a A Results Row Is Saved As item_N
    [Tags]    p2
    Load People
    Run Query    .[]
    ${dir}=    Make Temp Directory
    ${y}=    Results Row Y    2
    ${asked}=    Save From Menu At    ${RESULTS_ROW_X}    ${y}    ${dir}
    Should Be Equal    ${asked}[current_name]    item_2.json
    Should Be Equal    ${asked}[filters]    ${JSON_FILTER}
    File Should Hold    ${dir}/item_2.json    {"name":"Carol","age":45,"role":"manager"}

TC-SAVE-004b The Results Root Is Saved As results.json
    [Documentation]    The fallback differs from the Source's: results.json, not data.json.
    [Tags]    p2
    Load People
    Run Query    [.[] | .name]
    ${dir}=    Make Temp Directory
    ${asked}=    Save From Menu At    ${RESULTS_ROOT_X}    ${RESULTS_ROOT_Y}    ${dir}
    Should Be Equal    ${asked}[current_name]    results.json
    File Should Hold    ${dir}/results.json    [["Alice","Bob","Carol"]]

TC-SAVE-004c A Key Inside A Result Is Saved Under That Key
    [Documentation]    Open the one result (an object) and save its "age" row: age.json.
    [Tags]    p2
    Load People
    Run Query    .[0] | {name, age}
    Click At    628    186
    Sleep    0.6s
    ${dir}=    Make Temp Directory
    ${y}=    Results Row Y    2
    ${asked}=    Save From Menu At    ${RESULTS_ROW_X}    ${y}    ${dir}
    Should Be Equal    ${asked}[current_name]    age.json
    File Should Hold    ${dir}/age.json    34

# --- the Results header's Save..., JSON ------------------------------------------------------

TC-SAVE-005a The Results Save Writes The Results Array
    [Tags]    p1
    Load People
    Run Query    .[] | .name
    ${dir}=    Make Temp Directory
    ${asked}=    Save Results Suggested In    ${dir}
    Should Be Equal    ${asked}[current_name]    results.json
    File Should Hold    ${dir}/results.json    ["Alice","Bob","Carol"]

TC-SAVE-005b The Results Save Does Nothing Without Results
    [Documentation]    The button is disabled until a query has produced something: pressing it
    ...    opens no dialog.
    [Tags]    p1
    Load People
    Click At    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}
    Sleep    1s
    ${requests}=    Get Portal Requests
    Should Be Empty    ${requests}

TC-SAVE-006 A Result Past The Live Preview Is Saved Whole
    [Documentation]    The Results pane keeps the first 50,000 results, but Save... fetches
    ...    them all again first: 60,000 numbers come out as an array of 60,000.
    [Tags]    p2
    Load People
    Run Query    range(60000)
    Status Bar Should Say    capped    timeout=20
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    File Should Hold Numbers    ${dir}/results.json    60000

TC-SAVE-007a Saving Into A Missing Folder Reports A Save Error
    [Documentation]    The status bar says so in red; the results are still there.
    [Tags]    p2
    Load People
    Run Query    .[] | .name
    Save Results Accepting    /no/such/folder/out.json
    Wait Until Region Contains Text    @{STATUS_BAR}    Save error    timeout=8
    Region Should Contain Text    @{RESULTS_PANEL}    Alice

TC-SAVE-007b Saving Into A Read-Only Folder Reports A Save Error
    [Tags]    p3
    ${is_root}=    Evaluate    __import__("os").geteuid() == 0
    Skip If    ${is_root}    The test is run as root, who can write anywhere
    Load People
    Run Query    .[] | .name
    ${dir}=    Make Temp Directory
    Evaluate    __import__("os").chmod($dir, 0o555)
    Save Results Accepting    ${dir}/out.json
    Wait Until Region Contains Text    @{STATUS_BAR}    Save error    timeout=8
    [Teardown]    Run Keywords    Run Keyword And Ignore Error    Evaluate    __import__("os").chmod($dir, 0o755)    AND    Close Jsonquery App

TC-SAVE-009 A Load Clears The Save Confirmation
    [Documentation]    "Saved to <path>" stays until something else replaces it: another load,
    ...    even one that fails, clears it.
    [Tags]    p3
    Load People
    Run Query    .[] | .name
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Status Line Should Say    Saved to
    Load Via Url    ${FIXTURES}/no_such_file.json
    Wait Until Region Contains Text    @{STATUS_BAR}    Load error    timeout=8
    Status Line Should Not Say    Saved to

TC-SAVE-010a Every Save Offers A JSON File Type For JSON
    [Documentation]    The header buttons and the row menus of both panes, for JSON results: one
    ...    file type, JSON, *.json.
    [Tags]    p2
    Load People
    Run Query    .[] | .name
    ${dir}=    Make Temp Directory
    ${source_header}=    Source Save Suggested In    ${dir}
    Should Be Equal    ${source_header}[filters]    ${JSON_FILTER}
    ${results_header}=    Save Results Suggested In    ${dir}
    Should Be Equal    ${results_header}[filters]    ${JSON_FILTER}
    ${menu}=    Save From Menu At    ${SOURCE_ROW_X}    ${SOURCE_FIRST_ROW_Y}    ${dir}
    Should Be Equal    ${menu}[filters]    ${JSON_FILTER}
    ${count}=    Portal Request Count
    Should Be Equal As Integers    ${count}    3

# --- Ctrl+S -------------------------------------------------------------------------------------------

TC-KEY-003a Ctrl+S In The Source Pane Saves The Document
    [Tags]    p2
    Load People
    ${dir}=    Make Temp Directory
    Portal Will Accept Suggested Name In    ${dir}
    Click At    300    500
    Sleep    0.3s
    Press Keys    ctrl    s
    ${asked}=    Wait Until Portal Is Asked    1    timeout=8
    Should Be Equal    ${asked}[0][current_name]    data.json
    File Should Hold    ${dir}/data.json    ${PEOPLE_JSON}

TC-KEY-003b Ctrl+S In The Results Pane Saves The Results
    [Tags]    p2
    Load People
    Run Query    .[] | .name
    ${dir}=    Make Temp Directory
    Portal Will Accept Suggested Name In    ${dir}
    Click At    900    500
    Sleep    0.3s
    Press Keys    ctrl    s
    ${asked}=    Wait Until Portal Is Asked    1    timeout=8
    Should Be Equal    ${asked}[0][current_name]    results.json
    File Should Hold    ${dir}/results.json    ["Alice","Bob","Carol"]

TC-KEY-003c Ctrl+S In The Results Pane With No Results Opens Nothing
    [Tags]    p2
    Load People
    Click At    900    500
    Sleep    0.3s
    Press Keys    ctrl    s
    Sleep    1s
    ${requests}=    Get Portal Requests
    Should Be Empty    ${requests}

# --- the status bar -------------------------------------------------------------------------------------

TC-TOOL-006 A Save Error Replaces The Save Confirmation
    [Documentation]    "Saved to <path>" after a save that worked; after one that fails, "Save
    ...    error: ..." in red, and never both.
    [Tags]    p2
    Load People
    Run Query    .[] | .name
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Status Line Should Say    Saved to
    Portal Will Save To    /no/such/folder/out.json
    Click At    ${RESULTS_SAVE_X}    ${RESULTS_HEADER_Y}
    Wait Until Region Contains Text    @{STATUS_BAR}    Save error    timeout=8
    Status Line Should Not Say    Saved to
