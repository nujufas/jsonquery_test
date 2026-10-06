*** Settings ***
Documentation     Whole journeys through the window -- see docs/20_workflows.md. Each case goes
...               from where a person starts (a file chosen in the dialog, a lesson of the
...               tutorial, a pasted document) to what they came for (a file on disk, rows on
...               the clipboard), crossing the features that the other suites check one at a
...               time: the file dialogs, the jq functions the app adds, the CSV and TSV
...               output, Save..., the tutorial, the Tools window.
Resource          ../../resources/results.resource
Resource          ../../resources/tutorial.resource
Force Tags        workflows
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${TOOLS_WINDOW_TITLE}    jsonquery — Tools
${TOOLS_BUTTON_X}        1094
${ABOUT_BUTTON_X}        1181
${ABOUT_BUTTON_Y}        789
${ABOUT_WINDOW_TITLE}    jsonquery — About

*** Test Cases ***
TC-WF-001 From A File To A CSV File
    [Documentation]    Choose team.json in the file dialog, ask for one row per member, and
    ...    save: results.csv holds the rows.
    [Tags]    p1
    Browse And Choose    ${FIXTURES}/team.json
    Wait Until Region Contains Text    @{STATUS_BAR}    Parsed    timeout=8
    Region Should Contain Text    @{SOURCE_FIELD}    team.json
    Run Query    .members[] | [.name, .age] | @csv
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    "Ada",36\n"Bo",41\n"Cy",29\n

TC-WF-002 From A Line-Delimited File To CSV
    [Documentation]    records.ndjson has one object to a line; loaded it is one array, and
    ...    the rows of a table come out of it.
    [Tags]    p2
    Browse And Choose    ${FIXTURES}/records.ndjson
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=8
    Run Query    .[] | [.id, .name] | @csv
    Results Should Be Text    1,"Ada"\n2,"Bob"\n3,"Cy"
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    1,"Ada"\n2,"Bob"\n3,"Cy"\n

TC-WF-003 From A Lesson To Your Own Query And A File
    [Documentation]    Try a lesson's CSV example, change the query to another column, run it,
    ...    and save: the file is the rows of the changed query over the lesson's data.
    [Tags]    p1
    Open Tutorial
    Show Lesson    csv & tsv    CSV & TSV
    Try Example    One CSV row
    Results Should Be Text    "Ada",36,"lead"\n"Linus",28,"dev"\n"Grace",45,"dev"\n"Alan",41,"qa"
    Run Query    .members[] | [.name, .role] | @csv
    Results Should Be Text    "Ada","lead"\n"Linus","dev"\n"Grace","dev"\n"Alan","qa"
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    "Ada","lead"\n"Linus","dev"\n"Grace","dev"\n"Alan","qa"\n

TC-WF-004 Joining Two Tables And Saving The Result As JSON
    [Documentation]    The shop document: each order is paired with its customer's city by INDEX
    ...    and JOIN; the results are JSON, and so is the file.
    [Tags]    p1
    Load Fixture    shop.json
    Run Query By Paste    INDEX(.customers[]; .code) as $c | JOIN($c; .orders[]; .customer; {order: .[0].no, city: .[1].city})
    Results Should Be Json    [{"order": 101, "city": "London"}, {"order": 102, "city": "New York"}, {"order": 103, "city": "London"}, {"order": 104, "city": "Helsinki"}]
    Move Mouse To    600    450
    Format Note Should Be Hidden
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be Pretty Json    ${dir}/results.json
    ...    [{"order": 101, "city": "London"}, {"order": 102, "city": "New York"}, {"order": 103, "city": "London"}, {"order": 104, "city": "Helsinki"}]

TC-WF-005 Taking A Document Apart And Putting It Back
    [Documentation]    tostream gives the seven events of the document; fromstream of them gives
    ...    the document again, as the one result.
    [Tags]    p2
    Load Fixture    nested.json
    Run Query    [tostream]
    Results Should Be Json    [[[[ "a", "b", 0], 1], [["a", "b", 1], 2], [["a", "b", 1]], [["a", "c"], "x"], [["a", "c"]], [["d"], 3], [["d"]]]]
    Run Query    fromstream(tostream)
    Results Should Be Json    [{"a": {"b": [1, 2], "c": "x"}, "d": 3}]

TC-WF-006 The Format Follows The Query Through A Change Of Engine
    [Documentation]    CSV rows from jq, then a JSONPath query: the note goes and the next save
    ...    is JSON, named results.json.
    [Tags]    p2
    Load Fixture    team.json
    Run Query    .members[] | [.name] | @csv
    Format Note Should Be Shown
    Select Engine    JSONPath
    Run Query    $.members[*].name
    Move Mouse To    600    450
    Format Note Should Be Hidden
    ${dir}=    Make Temp Directory
    ${asked}=    Save Results Suggested In    ${dir}
    Should Be Equal    ${asked}[current_name]    results.json
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be Pretty Json    ${dir}/results.json    ["Ada", "Bo", "Cy"]

TC-WF-007 A Large Document Becomes A Large CSV File
    [Documentation]    25,000 numbers, two columns each: 25,000 lines, the last one right.
    [Tags]    p2
    ${base_url}=    Start Fixture Server    ${HTTP_FIXTURES_DIR}
    Load Via Url    ${base_url}/big_array.json
    Wait Until Region Contains Text    @{STATUS_AREA}    KB    timeout=10
    Run Query    .[] | [., . * 2] | @csv
    Status Bar Should Say    25000 result    timeout=20
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until File Has Lines    ${dir}/results.csv    25000
    ${text}=    Get File    ${dir}/results.csv
    ${lines}=    Split To Lines    ${text}
    Should Be Equal    ${lines}[0]    0,0
    Should Be Equal    ${lines}[24999]    24999,49998
    [Teardown]    Run Keywords    Stop Fixture Server    AND    Close Jsonquery App

TC-WF-008 Saved JSON Can Be Opened Again
    [Documentation]    Save the names as JSON, choose that file in the dialog, and query it:
    ...    the same names come back.
    [Tags]    p1
    Load Fixture    people.json
    Run Query    [.[] | .name]
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be Pretty Json    ${dir}/results.json    [["Alice", "Bob", "Carol"]]
    Click At    ${CLEAR_BUTTON_X}    ${TOOLBAR_Y}
    Sleep    0.8s
    Browse And Choose    ${dir}/results.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    1 item    timeout=8
    Run Query    .[0][]
    Results Should Be Json    ["Alice", "Bob", "Carol"]

TC-WF-009 Every Window Open And A Save Still Works
    [Documentation]    The Tools window, the tutorial and About are open beside the main
    ...    window; a query run there and saved still gives its file.
    [Tags]    p2
    Click At    ${TOOLS_BUTTON_X}    ${TUTORIAL_BUTTON_Y}
    Wait Until Window Exists    ${TOOLS_WINDOW_TITLE}    timeout=8
    Open Tutorial
    Switch To Main Window
    Click At    ${ABOUT_BUTTON_X}    ${ABOUT_BUTTON_Y}
    Wait Until Window Exists    ${ABOUT_WINDOW_TITLE}    timeout=8
    Switch To Main Window
    Load Fixture    people.json
    Run Query    .[] | [.name, .age] | @tsv
    ${dir}=    Make Temp Directory
    Save Results Suggested In    ${dir}
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.tsv    Alice\t34\nBob\t19\nCarol\t45\n

TC-WF-010 Rows Copied As CSV Are Not A JSON Document
    [Documentation]    The rows copied from the results are text for a spreadsheet: pasted back
    ...    into an empty app they are not JSON, and the app says so instead of loading them.
    [Tags]    p3
    Load Fixture    people.json
    Run Query    .[] | [.name, .age] | @csv
    ${rows}=    Copy All Results
    Click At    ${CLEAR_BUTTON_X}    ${TOOLBAR_Y}
    Sleep    0.8s
    Set Clipboard    ${rows}
    Click At    200    300
    Sleep    0.3s
    Press Keys    ctrl    v
    Wait Until Region Contains Text    @{STATUS_BAR}    Load error    timeout=8
