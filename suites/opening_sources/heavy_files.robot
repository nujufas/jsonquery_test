*** Settings ***
Documentation     Opening what is not an ordinary small file -- see docs/02_opening_sources.md
...               (TC-OPEN-029 to TC-OPEN-042). A file of 256 MiB or more is not parsed: it is
...               kept on disk, memory-mapped, checked once and indexed, and read as it is
...               looked at; a smaller one is parsed. A pipe has to be read whatever size it says
...               it is; a download is parsed from memory when it is small and goes through a
...               file that has no name, which is mapped, when it is large.
Resource          ../../resources/keywords.resource
Resource          ../../resources/results.resource
Force Tags        opening_sources
Suite Setup       Start The Display And Make The Big Files
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The byte size the toolbar shows after a load ("270.0 MB"): between the Clear
# button and the icon buttons at the far right.
@{BYTE_SIZE_AREA}    940    0    135    20

*** Keywords ***
Start The Display And Make The Big Files
    [Documentation]    Three files of more than 256 MiB, made once for the suite (they go
    ...    when the display stops): 270 MiB of a small document and blanks, 1500
    ...    strings of 190,000 characters, 272 MiB, which is a list of more than a thousand
    ...    children and takes a lot of memory to parse, and some 4.5 million records of
    ...    a few short fields, 270 MiB, which would take more than 4 GiB.
    Start Test Display
    ${heavy}=    Make Heavy File    270
    Set Suite Variable    ${HEAVY_FILE}    ${heavy}
    ${strings}=    Make File Of Long Strings
    Set Suite Variable    ${LONG_STRINGS_FILE}    ${strings}
    ${records}    ${count}=    Make File Of Records    270
    Set Suite Variable    ${RECORDS_FILE}    ${records}
    Set Suite Variable    ${RECORDS}    ${count}

Open The Long Strings
    Load Via Url    ${LONG_STRINGS_FILE}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    1500 items    timeout=30

Open The Records
    Load Via Url    ${RECORDS_FILE}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    ${RECORDS} items    timeout=60

Run Slow Query
    [Documentation]    Runs `query` and waits as long as `timeout` seconds for it to be
    ...    done: Run Query waits five, which is not for what reads 270 MiB.
    [Arguments]    ${query}    ${timeout}=90
    Click At    100    58
    Sleep    0.3s
    Press Keys    ctrl    a
    Type Text    ${query}
    Sleep    0.3s
    Press Keys    ctrl    enter
    Sleep    0.5s
    Wait Until Region Matches    @{STATUS_BAR}    Query ?ran ?in|result\\(s\\)|error    timeout=${timeout}

Slow Query Should Give
    [Arguments]    ${query}    ${expected}    ${timeout}=90
    Run Slow Query    ${query}    ${timeout}
    Results Should Be Json    ${expected}

*** Test Cases ***
TC-OPEN-029 A File Past The Indexing Size Opens Like Any Other
    [Documentation]    270 MiB, a small document and then blanks: past the 256 MiB from
    ...    which a file is kept on disk and indexed instead of parsed. It loads, the
    ...    toolbar says its size, the Source pane shows its content, and the status bar
    ...    says it was indexed.
    [Tags]    p2
    Load Via Url    ${HEAVY_FILE}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    2 keys    timeout=30
    Wait Until Region Matches    @{BYTE_SIZE_AREA}    270\\.0 ?MB    timeout=5
    Region Should Contain Text    @{STATUS_BAR}    Indexed in
    Region Should Not Contain Text    @{STATUS_BAR}    Load error

TC-OPEN-038 A File Below The Indexing Size Is Parsed
    [Documentation]    100 MiB of the same: below the 256 MiB, so read and parsed as any
    ...    file is, which the status bar says.
    [Tags]    p2
    ${file}=    Make Heavy File    100
    Load Via Url    ${file}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    2 keys    timeout=30
    Wait Until Region Matches    @{BYTE_SIZE_AREA}    100\\.0 ?MB    timeout=5
    Region Should Contain Text    @{STATUS_BAR}    Parsed in

TC-OPEN-030 A Named Pipe Opens With What Is Written To It
    [Documentation]    A path typed into the source field that is a pipe -- one made with
    ...    mkfifo here, or /dev/stdin for an app started at the end of one. A pipe says it
    ...    is 0 bytes long however much it will hand over, and it used to load as an empty
    ...    array, whatever was written to it.
    [Tags]    p2
    ${pipe}=    Make Named Pipe That Says    {"from": "a named pipe", "items": [1, 2, 3]}
    Load Via Url    ${pipe}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    a named pipe    timeout=10
    Region Should Contain Text    @{SOURCE_PANEL}    items
    Region Should Not Contain Text    @{STATUS_BAR}    Load error

TC-OPEN-031 A Small Download Leaves Nothing In The Temp Folder
    [Documentation]    A small response is parsed from memory. Before, every download was
    ...    written to a file in the temp folder, which was never deleted.
    [Tags]    p2
    ${before}=    App Temp Files
    ${base_url}=    Start Fixture Server    ${HTTP_FIXTURES_DIR}
    Load Via Url    ${base_url}/valid.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=5
    ${after}=    App Temp Files
    Should Be Equal    ${after}    ${before}
    [Teardown]    Run Keywords    Stop Fixture Server    AND    Close Jsonquery App

TC-OPEN-032 A Large Download Leaves Nothing In The Temp Folder
    [Documentation]    270 MiB, past the 256 MiB from which a response is written to a
    ...    file to be mapped and indexed. The file has no name from the moment it is made, so
    ...    there is nothing in the temp folder, while the document is open or after. Before,
    ...    it stayed there for good, the size of the download.
    [Tags]    p2
    ${folder}=    Evaluate    os.path.dirname($HEAVY_FILE)    modules=os
    ${before}=    App Temp Files
    ${base_url}=    Start Fixture Server    ${folder}
    Load Via Url    ${base_url}/heavy.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    2 keys    timeout=60
    Region Should Contain Text    @{STATUS_BAR}    Indexed in
    ${after}=    App Temp Files
    Should Be Equal    ${after}    ${before}
    [Teardown]    Run Keywords    Stop Fixture Server    AND    Close Jsonquery App

TC-OPEN-033 A File Past The Indexing Size Is Not Held In Memory
    [Documentation]    1500 strings of 190,000 characters, 272 MiB. Parsed, the app would
    ...    hold the bytes it read and the strings made of them, more than 500 MiB. Indexed,
    ...    the memory it holds that the system cannot take back (as it can the pages of a
    ...    file) stays about what it was; its peak is watched from before the load to after.
    [Tags]    p1
    Start Watching App Memory
    Open The Long Strings
    ${peak}=    Stop Watching App Memory
    Should Be True    ${peak} < 160
    ...    msg=The app held ${peak} MiB at its most while opening a file of 272 MiB

TC-OPEN-034 A Long List Of A File Kept On Disk Is Shown In Runs
    [Documentation]    More than a thousand children are not a thousand rows: the 1500 are
    ...    two runs, 0 to 999 and 1000 to 1499, which open into the children.
    [Tags]    p1
    Open The Long Strings
    Region Should Contain Text    @{SOURCE_PANEL}    1000 items
    Region Should Contain Text    @{SOURCE_PANEL}    500 items
    # Not "item-00000": OCR reads the i and the zeros of these rows as ".", "@" and so on,
    # while the row numbers and the long run of x are read well.
    Region Should Not Contain Text    @{SOURCE_PANEL}    xxxxxxxxxx
    Click At    28    185
    Sleep    0.5s
    Region Should Contain Text    @{SOURCE_PANEL}    xxxxxxxxxx
    Region Should Contain Text    @{SOURCE_PANEL}    20:
    Click At    28    185
    Sleep    0.5s
    Region Should Not Contain Text    @{SOURCE_PANEL}    xxxxxxxxxx

TC-OPEN-035 A Query Reads A File Kept On Disk As It Goes
    [Documentation]    What a query asks of the file is found in it: its length, one element
    ...    by number, a slice of it, the first that matches, and one that reads all 285
    ...    million characters of it (each of the 1500 in turn). The memory the app holds
    ...    stays small throughout.
    [Tags]    p1
    Open The Long Strings
    Start Watching App Memory
    Query Should Give    length    [1500]
    Query Should Give    .[1234] | length    [190011]
    Query Should Give    [.[1490:][] | .[0:10]]    [["item-01490","item-01491","item-01492","item-01493","item-01494","item-01495","item-01496","item-01497","item-01498","item-01499"]]
    Query Should Give    first(.[] | select(startswith("item-00007"))) | .[0:10]    ["item-00007"]
    Query Should Give    [.[] | length] | add    [285016500]
    ${peak}=    Stop Watching App Memory
    Should Be True    ${peak} < 200
    ...    msg=The app held ${peak} MiB at its most while it read a file of 272 MiB

TC-OPEN-036 A Query That Needs All Of A Long List As A Value Says So
    [Documentation]    `to_entries` makes a list of the same length of objects, which is
    ...    more than can be held for a list this long: the error says what it needed,
    ...    and no result is made. (`sort_by`, `group_by` and `..` are not of these: see
    ...    TC-OPEN-040.)
    [Tags]    p1
    Open The Long Strings
    Run Query    to_entries
    Status Bar Should Say    needs all of an array of 1500 items
    Status Bar Should Say    0 result(s)

TC-OPEN-037 JSONPath And JMESPath Read A File Kept On Disk
    [Documentation]    Both engines read the query as they do for any document and walk
    ...    the file for as long as a node is too big to be a value: a filter is tested on
    ...    each of 4.5 million records, and the one that passes is the answer.
    [Tags]    p1
    Open The Records
    Slow Query Should Give    $[?(@.id == 1234567)].k    ["cat-167"]
    Slow Query Should Give    [?id == `1234567`].k | [0]    ["cat-167"]

TC-OPEN-039 A File Cut Short While It Is Open Does Not Close The App
    [Documentation]    Another program cuts the file the app has open in half. Reading
    ...    what is past the cut used to end the whole process (SIGBUS): now the app
    ...    says that the file was changed, and goes on.
    [Tags]    p1
    ${copy}=    Copy Of File    ${RECORDS_FILE}
    Load Via Url    ${copy}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    ${RECORDS} items    timeout=60
    Cut File In Half    ${copy}
    Run Query    .[-1].id
    Status Bar Should Say    changed on disk
    # Whatever is asked of it from now on is refused, and the window is there.
    Run Query    length
    Status Bar Should Say    changed on disk
    Region Should Contain Text    @{SOURCE_PANEL}    ${RECORDS} items

TC-OPEN-040 A Long List Is Sorted And Grouped Where It Lies
    [Documentation]    `sort_by`, `group_by`, `min_by` and `max_by` over 4.5 million
    ...    records: the key of each is made, and where it is in the file, and what comes
    ...    out is the same list in another order or in groups, still in the file, read
    ...    as the next stage asks. The app holds some hundreds of MiB, not the more than
    ...    4 GiB that parsing the file would take.
    [Tags]    p1
    Open The Records
    ${last}=    Evaluate    ${RECORDS} - 1
    ${per}=    Evaluate    ${RECORDS} // 200
    Start Watching App Memory
    Slow Query Should Give    sort_by(.n) | .[0:3] | map(.id)    [[0,1000,2000]]
    Slow Query Should Give    sort_by(.id) | reverse | .[0].id    [${last}]
    Slow Query Should Give    group_by(.k) | length    [200]
    Slow Query Should Give    group_by(.k) | map({k: .[0].k, n: length}) | .[0]    [{"k":"cat-000","n":${per}}]
    Slow Query Should Give    min_by(.n) | .id    [0]
    Slow Query Should Give    max_by(.n) | .id    [${last}]
    ${peak}=    Stop Watching App Memory
    Should Be True    ${peak} < 1100
    ...    msg=The app held ${peak} MiB at its most while it sorted and grouped 270 MiB

TC-OPEN-041 An Expression Of Parts And A Search Down Through Everything Are Run On A File Kept On Disk
    [Documentation]    `{count: length, first: .[0].id}` and `.[-1].id - .[0].id` are taken
    ...    apart at their braces and operators and each part is walked; `..` goes down
    ...    through the whole list to the first string that ends as it is asked, and
    ...    stops there.
    [Tags]    p1
    Open The Records
    ${last}=    Evaluate    ${RECORDS} - 1
    Slow Query Should Give    {count: length, first: .[0].id, last: .[-1].id}    [{"count":${RECORDS},"first":0,"last":${last}}]
    Slow Query Should Give    .[-1].id - .[0].id    [${last}]
    Slow Query Should Give    first(.. | select(type == "string" and test("cat-199$")))    ["cat-199"]

TC-OPEN-042 A Key Repeated In An Object Of A File Kept On Disk Is Shown Once
    [Documentation]    `{"a": 1, "b": 2, "a": 3}` has two keys, `a` and `b`, with `a`
    ...    holding 3, as it does parsed; the file here is 270 MiB, so it is kept on disk.
    [Tags]    p2
    ${file}=    Make Heavy File    270    {"a": 1, "b": 2, "a": 3}
    Load Via Url    ${file}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    2 keys    timeout=30
    Region Should Not Contain Text    @{SOURCE_PANEL}    3 keys
    Query Should Give    .a    [3]
