*** Settings ***
Documentation     Tools window, the Merge JSON page with a big result -- see
...               docs/13_tools_window.md (TC-MRG-040 to TC-MRG-045). A result as big as
...               a file is kept on disk from (the limit of the Settings window; the least
...               it can be is 1 KB, so a few lines are "big" here) is not kept as a value
...               in memory: it is printed to a temporary file that has no name, and the
...               document is that file, memory-mapped and indexed, as a file of that size
...               opened from disk is. The status bar says so, the right pane shows the
...               start of it as it does for any result, and Open in main window and Save...
...               work from the file. The cases start the app with that limit in its
...               settings and a TMPDIR of its own, to look into.
Resource          ../../resources/tools.resource
Resource          ../../resources/results.resource
Library           Collections
Library           OperatingSystem
Force Tags        tools    merge    merge_big
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch With A Low Limit
Test Teardown     Close Jsonquery App

*** Variables ***
${KEEP_FROM_1_KB}      {"limits": {"keep_on_disk_from": "1 KB"}}
${MERGE_FIXTURES}      ${CURDIR}/../../resources/fixtures/merge
${MERGE_SAVE_X}        727
# Two lists of this many words each: 120 items, about 1.4 KB printed.
${WORDS}               60
${JSON_FILTER}         ${{ [{"name": "JSON", "globs": ["*.json"]}] }}

*** Keywords ***
Launch With A Low Limit
    [Documentation]    The app with files kept on disk from 1 KB, and a TMPDIR of its
    ...    own (`${TMP}`).
    ${tmp}=    Make Temp Directory
    Set Test Variable    ${TMP}    ${tmp}
    Launch Jsonquery App    settings=${KEEP_FROM_1_KB}    temp_dir=${TMP}

Merge These
    [Documentation]    Drops the files on the main window, which opens the Tools window
    ...    with them on the Merge page, and merges them with the default filter.
    [Arguments]    @{paths}
    Drop Files On Window    400    400    @{paths}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Sleep    0.5s
    Press Main Button
    Status Should Read    Merged

Merge Two Lists Of Words
    [Documentation]    Merges two lists of 60 words: 120 items, and about 1.4 KB when printed.
    @{paths}=    Make Lists Of Words    2    ${WORDS}
    Merge These    @{paths}
    RETURN    @{paths}

File Should Hold The List
    [Documentation]    The file is JSON, and it is this list.
    [Arguments]    ${path}    ${expected}
    ${text}=    Get File    ${path}
    ${actual}=    Evaluate    json.loads($text)    modules=json
    Should Be Equal    ${actual}    ${expected}

*** Test Cases ***
TC-MRG-040 A Result As Big As Files Are Kept On Disk From Is Kept In A Temporary File
    [Documentation]    Kept on disk from 1 KB, a result of 1.4 KB is not a value in memory:
    ...    the status bar says what it is and that it is kept in a temporary file, the
    ...    right pane shows the start of it all the same, and the app has a deleted
    ...    file mapped -- the file, which has no name any more -- named after the merge.
    [Tags]    p1
    Merge Two Lists Of Words
    Status Should Read    120 items
    Status Should Read    kept in a temporary file
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{MERGE_RESULT}    platypus
    App Should Have Mapped A Deleted File    merged.json

TC-MRG-041 A Result Under That Size Stays In Memory
    [Documentation]    The same limit and a result of a few bytes (platypus and echidna):
    ...    a value in memory. The status bar says what it was made from and nothing of a
    ...    file, and the app has no file mapped. Its temporary folder is one that is not
    ...    there, in which no file could be made: a merge that made one (and read it back,
    ...    which looks the same from outside) would end in an error.
    [Tags]    p1
    Close Jsonquery App
    Launch Jsonquery App    settings=${KEEP_FROM_1_KB}    temp_dir=${TMP}/not-there
    Merge These    ${MERGE_FIXTURES}/platypus.json    ${MERGE_FIXTURES}/echidna.json
    Status Should Read    2 items
    Status Should Not Read    temporary file
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{MERGE_RESULT}    platypus
    App Should Not Have Mapped A Deleted File    merged.json

TC-MRG-042 A Big Result Opens In The Main Window As A File
    [Documentation]    Open in main window gives the main window the file: its toolbar says
    ...    "(merged from 2 files)", the Source pane has all of it (120 items), and its status
    ...    bar says Indexed, not Parsed, as for a file of that size opened from disk.
    [Tags]    p1
    Merge Two Lists Of Words
    Click At    ${OPEN_IN_MAIN_X}    ${MERGE_HEADER_Y}
    Switch To Main Window
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_AREA}    merged
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    120 items
    Region Should Contain Text    @{STATUS_BAR}    Indexed in
    App Should Have Mapped A Deleted File    merged.json

TC-MRG-043 A Big Result Is Saved Whole
    [Documentation]    Save... of a result that is a file writes all of it, in the order of the
    ...    files, as it would write a value in memory: the 60 words of the first file and then
    ...    the 60 of the second.
    [Tags]    p1
    @{paths}=    Merge Two Lists Of Words
    ${dir}=    Make Temp Directory
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${dir}
    Click At    ${MERGE_SAVE_X}    ${MERGE_HEADER_Y}
    ${asked}=    Wait For Dialog After    ${before}
    Should Be Equal    ${asked}[current_name]    merged.json
    Should Be Equal    ${asked}[filters]    ${JSON_FILTER}
    ${expected}=    Evaluate
    ...    [w for p in $paths for w in json.load(open(p))]    modules=json
    Length Should Be    ${expected}    120
    Wait Until Keyword Succeeds    15x    0.4s    File Should Hold The List    ${dir}/merged.json    ${expected}

TC-MRG-044 The Temporary File Has No Name
    [Documentation]    While the result is shown and while it is open in the main window there
    ...    is nothing in the temporary folder with the merge's name: the file was unlinked as
    ...    it was made, so that whatever happens to the app, nothing of it is left. The
    ...    app's memory map is the proof that the file is there all the same.
    [Tags]    p1
    Merge Two Lists Of Words
    App Should Have Mapped A Deleted File    merged.json
    ${names}=    List Directory    ${TMP}    pattern=*merged.json
    Should Be Empty    ${names}
    Click At    ${OPEN_IN_MAIN_X}    ${MERGE_HEADER_Y}
    Switch To Main Window
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    120 items
    ${names}=    List Directory    ${TMP}    pattern=*merged.json
    Should Be Empty    ${names}

TC-MRG-045 The Size Is The One In The Settings
    [Documentation]    Without the setting, files are kept on disk from 256 MB: the same two
    ...    lists, 1.4 KB, are a value in memory, and the status bar says nothing of a file.
    [Tags]    p1
    Close Jsonquery App
    Launch Jsonquery App    temp_dir=${TMP}
    Merge Two Lists Of Words
    Status Should Read    120 items
    Status Should Not Read    temporary file
    App Should Not Have Mapped A Deleted File    merged.json
