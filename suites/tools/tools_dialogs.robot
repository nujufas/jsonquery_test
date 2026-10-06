*** Settings ***
Documentation     The Tools window's file dialogs -- see docs/13_tools_window.md. Format, Patch,
...               Merge and Diff each have a Save... that asks for a file name, and Merge has
...               Add files... and every page that takes a document an Open file...: all of
...               them were out of reach while the dialog could not be driven. The dialog is
...               answered by the stand-in portal (resources/fake_portal.py), which says what
...               the person chose and records what the app asked for: the suggested name and
...               the file type.
Resource          ../../resources/tools.resource
Resource          ../../resources/results.resource
Library           Collections
Force Tags        tools    tools_dialogs
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${MERGE_FIXTURES}      ${FIXTURES}/merge
${FORMAT_SAVE_X}       867
${PATCH_SAVE_X}        726
${MERGE_SAVE_X}        727
${DIFF_SAVE_X}         849
${OPEN_FILE_X}         248
${DOC}                 {"b":1,"a":[1,2]}
${PATCHED_DOC}         {"a":1,"b":[1,2]}
${OPS}                 [{"op":"replace","path":"/a","value":2}]
${JSON_FILTER}         ${{ [{"name": "JSON", "globs": ["*.json"]}] }}
${OPEN_FILTER}         ${{ [{"name": "JSON", "globs": ["*.json", "*.ndjson", "*.jsonl", "*.log", "*.txt"]}] }}

*** Keywords ***
Save In Tools Window
    [Documentation]    Presses the Save button at (x, y) of the Tools window with the dialog
    ...    accepted as it opened, in `dir`; returns the dialog's request.
    [Arguments]    ${x}    ${y}    ${dir}
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${dir}
    Click At    ${x}    ${y}
    ${request}=    Wait For Dialog After    ${before}
    RETURN    ${request}

Format The Document
    [Arguments]    ${text}=${DOC}
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${text}
    Press Main Button
    Status Should Read    Formatted

File Should Hold Text
    [Arguments]    ${path}    ${expected}
    Wait Until Keyword Succeeds    15x    0.4s    File Should Be    ${path}    ${expected}

File Should Contain Json
    [Arguments]    ${path}    ${expected}
    ${text}=    Get File    ${path}
    ${actual}=    Evaluate    json.loads($text)    modules=json
    ${wanted}=    Evaluate    json.loads($expected)    modules=json
    Should Be Equal    ${actual}    ${wanted}

*** Test Cases ***
TC-TDLG-001 Format Saves Under formatted.json
    [Documentation]    A pasted document has no file name to start from: the suggestion is
    ...    formatted.json, with a JSON file type, and the file is the text shown.
    [Tags]    p1
    Format The Document
    ${dir}=    Make Temp Directory
    ${asked}=    Save In Tools Window    ${FORMAT_SAVE_X}    ${HEADER_Y}    ${dir}
    Should Be Equal    ${asked}[current_name]    formatted.json
    Should Be Equal    ${asked}[filters]    ${JSON_FILTER}
    Wait Until Keyword Succeeds    15x    0.4s    File Should Be Pretty Json    ${dir}/formatted.json    ${DOC}

TC-TDLG-002 Format Minified Saves Under min.json
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"b": 1, "a": [1, 2]}
    Pick Indent    Minified
    Press Main Button
    Status Should Read    Formatted
    ${dir}=    Make Temp Directory
    ${asked}=    Save In Tools Window    ${FORMAT_SAVE_X}    ${HEADER_Y}    ${dir}
    Should Be Equal    ${asked}[current_name]    min.json
    File Should Hold Text    ${dir}/min.json    {"b":1,"a":[1,2]}

TC-TDLG-003 A File Opened Through The Dialog Is Formatted And Saved Next To Its Name
    [Documentation]    Open file... on Format's input asks for a JSON-like file, loads the one
    ...    chosen into the box, and Format then Save... suggests people.formatted.json.
    [Tags]    p1
    Open Tool    format
    ${before}=    Portal Request Count
    Portal Will Pick    ${FIXTURES}/people.json
    Click At    ${OPEN_FILE_X}    ${HEADER_Y}
    ${opened}=    Wait For Dialog After    ${before}
    Should Be Equal    ${opened}[method]    OpenFile
    Should Be Equal    ${opened}[filters]    ${OPEN_FILTER}
    Press Main Button
    Status Should Read    Formatted
    ${dir}=    Make Temp Directory
    ${asked}=    Save In Tools Window    ${FORMAT_SAVE_X}    ${HEADER_Y}    ${dir}
    Should Be Equal    ${asked}[current_name]    people.formatted.json

TC-TDLG-004 Patch Saves Under patched.json
    [Tags]    p1
    Open Tool    patch
    Paste Into Box    ${FIRST_BOX_X}    ${FIRST_BOX_Y}    ${PATCHED_DOC}
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${OPS}
    Press Main Button
    Status Should Read    operation
    ${dir}=    Make Temp Directory
    ${asked}=    Save In Tools Window    ${PATCH_SAVE_X}    ${HEADER_Y}    ${dir}
    Should Be Equal    ${asked}[current_name]    patched.json
    Should Be Equal    ${asked}[filters]    ${JSON_FILTER}
    ${text}=    Evaluate    json.dumps({"a": 2, "b": [1, 2]}, indent=2)    modules=json
    File Should Hold Text    ${dir}/patched.json    ${text}

TC-TDLG-005 Merge Saves Under merged.json
    [Documentation]    Two files dropped on the main window open the Merge page; Merge then
    ...    Save... suggests merged.json, and the file is the merged array.
    [Tags]    p1
    ${paths}=    Create List    ${MERGE_FIXTURES}/part1.json    ${MERGE_FIXTURES}/part2.json
    Drop Files On Window    400    400    @{paths}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Sleep    0.8s
    Press Main Button
    Status Should Read    Merged
    ${dir}=    Make Temp Directory
    ${asked}=    Save In Tools Window    ${MERGE_SAVE_X}    ${MERGE_HEADER_Y}    ${dir}
    Should Be Equal    ${asked}[current_name]    merged.json
    Should Be Equal    ${asked}[filters]    ${JSON_FILTER}
    ${text}=    Evaluate    json.dumps(["one", "two"], indent=2)    modules=json
    File Should Hold Text    ${dir}/merged.json    ${text}

TC-TDLG-006 Diff Saves The Patch Under patch.json
    [Tags]    p1
    Open Tool    diff
    Compare Documents    {"a":1}    {"a":2}
    Pick Diff View    patch
    ${dir}=    Make Temp Directory
    ${asked}=    Save In Tools Window    ${DIFF_SAVE_X}    ${COMMAND_Y}    ${dir}
    Should Be Equal    ${asked}[current_name]    patch.json
    Should Be Equal    ${asked}[filters]    ${JSON_FILTER}
    Wait Until Keyword Succeeds    15x    0.4s    File Should Contain Json    ${dir}/patch.json    [{"op": "replace", "path": "/a", "value": 2}]

TC-TDLG-007 Merge Add Files Takes Several Files From The Dialog
    [Documentation]    Add files... asks for several files at once, of the JSON-like types; the
    ...    ones chosen are listed in the order given.
    [Tags]    p1
    Open Tool    merge
    ${before}=    Portal Request Count
    Portal Will Pick    ${MERGE_FIXTURES}/part1.json    ${MERGE_FIXTURES}/part2.json
    Click At    ${ADD_FILES_X}    ${MERGE_HEADER_Y}
    ${asked}=    Wait For Dialog After    ${before}
    Should Be Equal    ${asked}[method]    OpenFile
    Should Be True    ${asked}[multiple]
    Should Be Equal    ${asked}[filters]    ${OPEN_FILTER}
    # (OCR reads the "1" of part1 as an "i" at times.)
    Wait Until Region Matches    @{MERGE_FILES}    part[1il]    timeout=6
    Wait Until Region Matches    @{MERGE_FILES}    part2    timeout=6

TC-TDLG-008 Closing A Save Dialog Writes Nothing
    [Tags]    p2
    Format The Document
    ${dir}=    Make Temp Directory
    ${before}=    Portal Request Count
    Portal Will Cancel
    Click At    ${FORMAT_SAVE_X}    ${HEADER_Y}
    Wait For Dialog After    ${before}
    Sleep    1s
    ${files}=    List Directory    ${dir}
    Should Be Empty    ${files}
    ${formatted}=    Evaluate    json.dumps(json.loads($DOC), indent=2)    modules=json
    Copy Should Give    ${FORMAT_COPY_X}    ${HEADER_Y}    ${formatted}

TC-TDLG-009 Closing An Open Dialog Leaves The Box As It Was
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${DOC}
    ${before}=    Portal Request Count
    Portal Will Cancel
    Click At    ${OPEN_FILE_X}    ${HEADER_Y}
    Wait For Dialog After    ${before}
    Sleep    1s
    Press Main Button
    Status Should Read    Formatted
    ${formatted}=    Evaluate    json.dumps(json.loads($DOC), indent=2)    modules=json
    Copy Should Give    ${FORMAT_COPY_X}    ${HEADER_Y}    ${formatted}
