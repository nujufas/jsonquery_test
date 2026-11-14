*** Settings ***
Documentation     The app's command line -- see docs/27_command_line.md.
...
...               What the app opens as it starts: a document (a file, by a relative or a full path or a `file://`
...               address, a web address, what is piped in), a query to run on it once it has loaded (`--query` with
...               or without `--lang`, `--pointer`, a file of a query beside it), several documents for Merge's list,
...               and a tool's page filled with files and run (`--diff`, `--merge`, `--patch`, `--validate`, `--format`,
...               `--create-schema`). What the main window has is read through the MCP server's `get_state`, which is
...               exact; what a tool shows, by OCR of the Tools window. `--help`, `--version` and a command line that
...               cannot be done print, end, and open no window: the app is run on the suite's display, where a window
...               would keep it running and fail the case.
Resource          ../../resources/mcp.resource
Resource          ../../resources/tools.resource
Library           Collections
Library           OperatingSystem
Library           String
Force Tags        command_line    undocked-only
Suite Setup       Make The Files
Suite Teardown    Stop Test Display
Test Teardown     Close Jsonquery App

*** Variables ***
${DIR}                    ${TEMPDIR}/jq-command-line
# The toolbar's row: the source field, and what is loaded at its right ("(standard input)", the size).
@{TOOLBAR_ROW}            60     0      1040   20
# Merge's "Files (2)" over its list, in the Tools window (as suites/tools/tools_merge.robot has it).
@{FILES_HEADER}           8      110    433    24

*** Test Cases ***
TC-CLI-001 --version Prints The Version, And No Window Opens
    [Tags]    p1
    ${run}=    Run Jsonquery Command Line    --version
    Should Be Equal As Integers    ${run}[rc]    0
    Should Match Regexp    ${run}[stdout]    ^jsonquery_gui \\d+\\.\\d+\\.\\d+\\n$
    Should Be Empty    ${run}[stderr]
    ${short}=    Run Jsonquery Command Line    -V
    Should Be Equal    ${short}[stdout]    ${run}[stdout]

TC-CLI-002 The Build Without The MCP Server Says So In Its Version
    [Tags]    p2
    ${run}=    Run Jsonquery Command Line    --version    build=nomcp
    Should Be Equal As Integers    ${run}[rc]    0
    Should Match Regexp    ${run}[stdout]    ^jsonquery_gui \\d+\\.\\d+\\.\\d+ \\(built without the MCP server\\)\\n$

TC-CLI-003 --help Says How To Use It, Option By Option, And No Window Opens
    [Tags]    p1
    ${run}=    Run Jsonquery Command Line    --help
    Should Be Equal As Integers    ${run}[rc]    0
    Should Start With    ${run}[stdout]    jsonquery_gui
    FOR    ${part}    IN    Usage:    --query QUERY    --lang LANGUAGE    --pointer POINTER
    ...    --diff LEFT RIGHT    --merge FILE    --patch DOCUMENT PATCH    --validate DOCUMENT SCHEMA
    ...    --format FILE    --create-schema FILE    --help    --version    - for what is
    ...    git difftool
        Should Contain    ${run}[stdout]    ${part}
    END
    ${short}=    Run Jsonquery Command Line    -h
    Should Be Equal    ${short}[stdout]    ${run}[stdout]

TC-CLI-004 A Command Line That Cannot Be Done Is Said, Ends With 2, And No Window Opens
    [Tags]    p1
    Command Line Should Fail With    --bogus    says=--bogus is not an option
    Command Line Should Fail With    --diff    a.json    b.json    c.json
    ...    says=--diff takes 2 files, and 3 were given
    Command Line Should Fail With    --query    .a    --pointer    /a    says=there is one query box
    Command Line Should Fail With    --lang    sql    --query    .a
    ...    says=--lang takes jq, jsonpath, jmespath or pointer
    Command Line Should Fail With    --merge    a.json    https://example.com/b.json
    ...    says=https://example.com/b.json is a web address
    Command Line Should Fail With    --query
    ...    says=--query needs a query after it

TC-CLI-005 A Dash With Nothing Piped In Is Said, And No Window Opens
    [Documentation]    At a prompt the app's input is the terminal: reading it would wait for whoever is at it.
    [Tags]    p2
    ${run}=    Run Jsonquery Command Line    -    stdin_terminal=${True}
    Should Be Equal As Integers    ${run}[rc]    2
    Should Contain    ${run}[stderr]    - opens what is piped in, and nothing is

TC-CLI-006 A File Given Is Opened, As Load Opens It
    [Tags]    p1
    Launch Mcp App Serving    args=${{ [$PEOPLE] }}
    ${state}=    State When Loaded
    Should Be Equal    ${state}[document][source]    file
    Should Be Equal    ${state}[document][from]    ${PEOPLE}
    Should Be Equal    ${state}[query][text]    ${EMPTY}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=5
    Source Field Should Be    ${PEOPLE}

TC-CLI-007 A Relative Path Is Opened From The Folder The App Was Started In
    [Tags]    p1
    Launch Mcp App Serving    args=${{ ['people.json'] }}    cwd=${DIR}
    ${state}=    State When Loaded
    Should Be Equal    ${state}[document][from]    ${PEOPLE}

TC-CLI-008 A Query Given Is Put In The Box And Runs On The Document Once It Has Loaded
    [Tags]    p1
    Launch Mcp App Serving    args=${{ [$PEOPLE, '--query', '.[] | select(.age > 30) | .name'] }}
    ${state}=    State With Results
    Should Be Equal    ${state}[query][text]    .[] | select(.age > 30) | .name
    Should Be Equal    ${state}[query][language]    jq
    Should Not Be True    ${state}[query][language_chosen]
    Should Be Equal As Integers    ${state}[query][results][count]    2
    Wait Until Region Contains Text    @{RESULTS_PANEL}    Carol    timeout=5
    Region Should Not Contain Text    @{RESULTS_PANEL}    Bob

TC-CLI-009 --lang Names The Query's Language, Which Is Picked
    [Tags]    p1
    Launch Mcp App Serving    args=${{ [$PEOPLE, '-q', '[?age > `30`].name', '--lang', 'JMESPath'] }}
    ${state}=    State With Results
    Should Be Equal    ${state}[query][language]    jmespath
    Should Be True    ${state}[query][language_chosen]
    ${results}=    Mcp Tool Should Succeed    get_results
    Should Be Equal    ${results}[items][0]    ${{ ["Alice", "Carol"] }}

TC-CLI-010 --pointer Shows The Value It Points At
    [Tags]    p1
    Launch Mcp App Serving    args=${{ [$PEOPLE, '--pointer', '/1/name'] }}
    ${state}=    State With Results
    Should Be Equal    ${state}[query][text]    /1/name
    Should Be Equal    ${state}[query][language]    pointer
    Should Be True    ${state}[query][language_chosen]    msg=picked, not told from the text
    Should Be Equal As Integers    ${state}[query][results][count]    1
    Wait Until Region Contains Text    @{RESULTS_PANEL}    Bob    timeout=5

TC-CLI-011 A File Of A Query Beside The Document Is Put In The Box And Run, As When It Is Dropped
    [Tags]    p1
    Launch Mcp App Serving    args=${{ [$PEOPLE, $NAMES_JQ] }}
    ${state}=    State With Results
    Should Be Equal    ${state}[query][text]    .[].name
    Should Be Equal    ${state}[query][language]    jq
    Should Be Equal As Integers    ${state}[query][results][count]    3

TC-CLI-012 What Is Piped In Is Opened, With No Address In Source
    [Tags]    p1
    ${text}=    Get File    ${PEOPLE}
    Launch Mcp App Serving    args=${{ ['-', '--query', '.[0].name'] }}    stdin_text=${text}
    ${state}=    State With Results
    Should Be Equal    ${state}[document][source]    standard input
    Dictionary Should Not Contain Key    ${state}[document]    kept_on_disk
    ${results}=    Mcp Tool Should Succeed    get_results
    Should Be Equal    ${results}[items]    ${{ ["Alice"] }}
    Wait Until Region Contains Text    @{TOOLBAR_ROW}    standard input    timeout=5
    # Nothing in Source: its hint shows.
    Region Should Contain Text    @{SOURCE_FIELD}    URL or local path

TC-CLI-013 A Large Pipe Is Kept On Disk And Queried From There
    [Documentation]    From the size files are kept on disk from (set to 1 KB here), what is piped in goes to a temporary
    ...    file nobody else can open, and is read from there, as a big download is.
    [Tags]    p2
    ${text}=    Evaluate    json.dumps(list(range(5000)))    modules=json
    Launch Mcp App Serving    args=${{ ['-', '-q', 'length'] }}    stdin_text=${text}
    ...    settings={"limits": {"keep_on_disk_from": "1 KB"}}
    ${state}=    State With Results
    Should Be Equal    ${state}[document][source]    standard input
    Dictionary Should Contain Key    ${state}[document]    kept_on_disk
    ${results}=    Mcp Tool Should Succeed    get_results
    Should Be Equal    ${results}[items]    ${{ [5000] }}

TC-CLI-014 A Web Address Given Is Downloaded
    [Tags]    p1
    ${base}=    Start Fixture Server    ${HTTP_FIXTURES_DIR}
    Launch Mcp App Serving    args=${{ [$base + '/valid.json'] }}
    ${state}=    State When Loaded
    Should Be Equal    ${state}[document][source]    web address
    Should Be Equal    ${state}[document][from]    ${base}/valid.json
    ${asked}=    Fixture Server Requests
    Should Be Equal    ${asked}    ${{ ['/valid.json'] }}
    [Teardown]    Run Keywords    Stop Fixture Server    AND    Close Jsonquery App

TC-CLI-015 A file:// Address Is The File It Names
    [Documentation]    As a desktop's launcher may hand a file over: the name's space is %20.
    [Tags]    p2
    Launch Mcp App Serving    args=${{ ['file://' + $SPACED.replace(' ', '%20')] }}
    ${state}=    State When Loaded
    Should Be Equal    ${state}[document][source]    file
    Should Be Equal    ${state}[document][from]    ${SPACED}

TC-CLI-016 A Document That Cannot Be Opened: The Window Opens And Says Why, And The Query Waits
    [Tags]    p1
    Launch Mcp App Serving    args=${{ [$DIR + '/gone.json', '-q', '.a'] }}
    ${state}=    Wait Until Keyword Succeeds    10x    0.5s    State With A Load Error
    Should Contain    ${state}[load_error]    gone.json
    Should Be Equal    ${state}[document]    ${None}
    Should Be Equal    ${state}[query][text]    .a
    Should Be Equal    ${state}[query][results]    ${None}
    Wait Until Region Contains Text    @{STATUS_BAR}    Load error    timeout=5
    Source Field Should Be    ${DIR}/gone.json

TC-CLI-017 Several Documents Go To Merge's List, As When They Are Dropped
    [Tags]    p1
    Launch Mcp App Serving    args=${{ [$PART1, $PART2] }}
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Be Equal    ${state}[document]    ${None}
    Should Be Equal    ${state}[tools]    open in a window of their own
    Tools Window Should Read    Files (2    @{FILES_HEADER}
    Switch To Window    ${TOOLS_WINDOW}
    Tab Should Be Selected    merge
    Sleep    1s
    Status Should Not Read    Merged

TC-CLI-018 --diff Compares The Left File With The Right
    [Tags]    p1
    Launch Tool From Command Line    --diff    ${OLD}    ${NEW}
    Tab Row Should Offer Changes    2

TC-CLI-019 --validate Checks The Document Against The Schema
    [Tags]    p1
    Launch Tool From Command Line    --validate    ${DOC}    ${SCHEMA}
    Status Should Read    2 problems
    Result Should Read    /age

TC-CLI-020 --patch Applies The Patch To The Document
    [Tags]    p1
    Launch Tool From Command Line    --patch    ${PATCH_DOC}    ${PATCH}
    Status Should Read    Patched

TC-CLI-021 --format Formats The File
    [Tags]    p1
    Launch Tool From Command Line    --format    ${MESSY}
    Status Should Read    Formatted

TC-CLI-022 --create-schema Makes The Schema Of The File
    [Tags]    p1
    Launch Tool From Command Line    --create-schema    ${PEOPLE}
    Status Should Read    Created

TC-CLI-023 --merge Merges The Files
    [Tags]    p1
    Launch Tool From Command Line    --merge    ${PART1}    ${PART2}
    Status Should Read    Merged 2 files

TC-CLI-024 A Tool Given Fewer Files Than Boxes Fills What It Can, And Waits
    [Tags]    p2
    Launch Tool From Command Line    --validate    ${DOC}
    Tab Should Be Selected    validate
    Sleep    1s
    Status Should Not Read    problem
    Status Should Not Read    Valid

TC-CLI-025 With The Tools Docked, A Tool's Tab Comes To The Front
    [Tags]    p2
    Launch Mcp App Serving    args=${{ ['--diff', $OLD, $NEW] }}    settings={"tools": "docked"}
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Be Equal    ${state}[tools]    docked as tabs of the main window
    Should Be Equal    ${state}[in_front]    Diff JSON
    ${window}=    Window Exists    ${TOOLS_WINDOW}
    Should Not Be True    ${window}    msg=the Tools are docked: they have no window

*** Keywords ***
Make The Files
    Start Test Display
    Remove Directory    ${DIR}    recursive=${True}
    Create Directory    ${DIR}
    Copy File    ${PEOPLE_FIXTURE}    ${DIR}/people.json
    Set Suite Variable    ${PEOPLE}    ${DIR}/people.json
    Create File    ${DIR}/names.jq    .[].name
    Set Suite Variable    ${NAMES_JQ}    ${DIR}/names.jq
    Copy File    ${PEOPLE_FIXTURE}    ${DIR}/my people.json
    Set Suite Variable    ${SPACED}    ${DIR}/my people.json
    Create File    ${DIR}/old.json    {"a": 1, "b": [1, 2]}
    Create File    ${DIR}/new.json    {"a": 2, "b": [1, 2, 3]}
    Set Suite Variable    ${OLD}    ${DIR}/old.json
    Set Suite Variable    ${NEW}    ${DIR}/new.json
    Create File    ${DIR}/doc.json    {"age": -1}
    Create File    ${DIR}/schema.json    {"properties": {"age": {"minimum": 0}}, "required": ["name"]}
    Set Suite Variable    ${DOC}    ${DIR}/doc.json
    Set Suite Variable    ${SCHEMA}    ${DIR}/schema.json
    Create File    ${DIR}/patch_doc.json    {"a": 1}
    Create File    ${DIR}/fix.json    [{"op": "add", "path": "/b", "value": 2}]
    Set Suite Variable    ${PATCH_DOC}    ${DIR}/patch_doc.json
    Set Suite Variable    ${PATCH}    ${DIR}/fix.json
    Create File    ${DIR}/messy.json    {"b":1,"a":[1,2]}
    Set Suite Variable    ${MESSY}    ${DIR}/messy.json
    Create File    ${DIR}/part1.json    [1, 2]
    Create File    ${DIR}/part2.json    [3]
    Set Suite Variable    ${PART1}    ${DIR}/part1.json
    Set Suite Variable    ${PART2}    ${DIR}/part2.json

Command Line Should Fail With
    [Documentation]    The app run with `args` says `says` on its error output, with where to look, prints nothing
    ...    else, ends with 2 and opens no window.
    [Arguments]    @{args}    ${says}
    ${run}=    Run Jsonquery Command Line    @{args}
    Should Be Equal As Integers    ${run}[rc]    2    msg=${args}: ${run}
    Should Contain    ${run}[stderr]    ${says}
    Should Contain    ${run}[stderr]    See jsonquery_gui --help.
    Should Be Empty    ${run}[stdout]

State When Loaded
    [Documentation]    get_state, once the document has loaded.
    ${state}=    Wait Until Keyword Succeeds    20x    0.5s    State With A Document
    RETURN    ${state}

State With A Document
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Not Be Equal    ${state}[document]    ${None}    msg=no document yet: ${state}
    Should Not Be True    ${state}[loading]
    RETURN    ${state}

State With Results
    [Documentation]    get_state, once the document has loaded and the query has run on it.
    ${state}=    Wait Until Keyword Succeeds    20x    0.5s    State With Its Results
    RETURN    ${state}

State With Its Results
    ${state}=    State With A Document
    Should Not Be Equal    ${state}[query][results]    ${None}    msg=no results yet: ${state}
    Should Not Be True    ${state}[query][running]
    RETURN    ${state}

State With A Load Error
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Not Be Equal    ${state}[load_error]    ${None}    msg=no error yet: ${state}
    RETURN    ${state}

Launch Tool From Command Line
    [Documentation]    The app started with `args`, which fill a tool's page; the Tools window, open on it, is the
    ...    current one.
    [Arguments]    @{args}
    Launch Mcp App Serving    args=${args}
    Wait Until Window Exists    ${TOOLS_WINDOW}
    Switch To Window    ${TOOLS_WINDOW}
