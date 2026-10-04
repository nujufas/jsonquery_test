*** Settings ***
Documentation     Tools window, the Patch JSON page -- see docs/13_tools_window.md.
...               A Document and a Patch (two boxes, one above the other) give a
...               Result: Kind picks Operations (RFC 6902, a list of add / remove /
...               replace / move / copy / test) or Merge patch (RFC 7386); Apply
...               runs it. A failing operation is reported as "operation N (op
...               path): reason" and changes nothing. The result can be copied,
...               saved, or opened in the main window as the loaded document.
...
...               Exact results are checked through the clipboard (Copy), the
...               errors and the status bar by OCR.
Resource          ../../resources/tools.resource
Force Tags        tools    patch
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${DOC}               {"a":1,"b":[1,2]}
${OPS}               [{"op":"add","path":"/b/-","value":3},{"op":"replace","path":"/a","value":2}]
@{APPLY_BUTTON}      8      24     44     20
@{OPEN_IN_MAIN_BUTTON}    760    54     134    18

*** Keywords ***
Fill Patch Page
    [Documentation]    Pastes the document and the patch into the two boxes.
    [Arguments]    ${document}    ${patch}
    Paste Into Box    ${FIRST_BOX_X}    ${FIRST_BOX_Y}    ${document}
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${patch}

Apply Patch
    [Documentation]    Presses Apply and waits for the status bar to describe a
    ...    result ("object · 2 keys · 2 operations").
    Press Main Button
    Status Should Read    operation

Patched Should Be
    [Documentation]    Copy gives exactly this text, a standard two-space layout
    ...    of `expected_json`.
    [Arguments]    ${expected_json}
    ${text}=    Evaluate    json.dumps(json.loads($expected_json), indent=2)    modules=json
    Copy Should Give    ${PATCH_COPY_X}    ${HEADER_Y}    ${text}

Apply Button Should Be Disabled
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    @{APPLY_BUTTON}    threshold=150

Apply Button Should Be Enabled
    Get Ink Bounds    @{APPLY_BUTTON}    threshold=150

*** Test Cases ***
TC-TWIN-008 Patch JSON Applies A Patch And Opens The Result
    [Documentation]    A JSON Patch applied to a document shows the patched
    ...    document; "Open in main window" makes it the loaded one, named
    ...    "(patched)" in the toolbar.
    [Tags]    p1
    Open Tool    patch
    Fill Patch Page    ${DOC}    ${OPS}
    Apply Patch
    Patched Should Be    {"a":2,"b":[1,2,3]}
    Click At    ${OPEN_IN_MAIN_X}    ${HEADER_Y}
    Switch To Main Window
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_AREA}    patched

TC-TWIN-009 A Patch That Fails Names The Operation
    [Documentation]    An operation that cannot be done is reported with its
    ...    number and what it was, and nothing is changed.
    [Tags]    p2
    Open Tool    patch
    Fill Patch Page    {"a":1}    [{"op":"remove","path":"/zzz"}]
    Press Main Button
    Result Should Read    operation 1
    Result Should Read    remove /zzz

TC-PAT-001 Operations Apply In Order
    [Documentation]    add, replace, remove, move, copy and test in one patch, each
    ...    seeing the result of the one before it; the result is the exact
    ...    document (Copy), the status bar counts the operations.
    [Tags]    p1
    Open Tool    patch
    Fill Patch Page    {"a":{"b":1},"c":[1,2],"keep":true}    [{"op":"move","from":"/a/b","path":"/d"},{"op":"copy","from":"/c/0","path":"/e"},{"op":"test","path":"/d","value":1},{"op":"remove","path":"/keep"},{"op":"add","path":"/c/1","value":9}]
    Apply Patch
    Status Should Read    operations
    Patched Should Be    {"a":{},"c":[1,9,2],"d":1,"e":1}

TC-PAT-002 A Merge Patch Replaces, Removes And Adds
    [Documentation]    With Kind set to "Merge patch (RFC 7386)" the patch is a
    ...    document merged in: null removes a member, an object merges into one,
    ...    anything else replaces.
    [Tags]    p1
    Open Tool    patch
    Click At    ${KIND_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${KIND_ITEM_X}    ${KIND_ITEM_Y}[merge]
    Sleep    0.4s
    Fill Patch Page    {"a":1,"b":2,"c":{"d":1}}    {"b":null,"c":{"e":2},"f":3}
    Press Main Button
    Status Should Read    Patched
    Patched Should Be    {"a":1,"c":{"d":1,"e":2},"f":3}

TC-PAT-003 Changing The Kind Drops The Result
    [Documentation]    A result made one way is not left on show once the other is
    ...    picked: the answer and the status bar's summary go.
    [Tags]    p2
    Open Tool    patch
    Fill Patch Page    {"a":"platypus"}    [{"op":"add","path":"/b","value":1}]
    Apply Patch
    Result Should Read    platypus
    Click At    ${KIND_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${KIND_ITEM_X}    ${KIND_ITEM_Y}[merge]
    Sleep    0.5s
    Result Should Not Read    platypus
    Status Should Not Read    operation

TC-PAT-004 A Patch That Is Not A List Is Explained
    [Documentation]    Operations are an array: an object in the Patch box under
    ...    "Operations" is reported as needing an array of operations.
    [Tags]    p1
    Open Tool    patch
    Fill Patch Page    {"a":1}    {"op":"add","path":"/b","value":1}
    Press Main Button
    Result Should Read    array of operations

TC-PAT-005 A Document That Is Not JSON Is Named
    [Documentation]    The error says which box it came from ("Document") and what
    ...    is wrong with the text.
    [Tags]    p1
    Open Tool    patch
    Fill Patch Page    {"a":    ${OPS}
    Press Main Button
    Result Should Read    Document
    Result Should Read    parsing JSON

TC-PAT-006 A Patch That Is Not JSON Is Named
    [Documentation]    Likewise for the Patch box.
    [Tags]    p2
    Open Tool    patch
    Fill Patch Page    ${DOC}    [{"op":
    Press Main Button
    Result Should Read    Patch
    Result Should Read    parsing JSON

TC-PAT-007 A Failed Test Changes Nothing
    [Documentation]    The patch is all or nothing: an add that would have worked,
    ...    then a test that fails, gives only the error naming the second
    ...    operation and its place -- no half-patched document, and Copy has
    ...    nothing.
    [Tags]    p1
    Open Tool    patch
    Fill Patch Page    {"a":1}    [{"op":"add","path":"/x","value":1},{"op":"test","path":"/a","value":2}]
    Press Main Button
    Result Should Read    operation 2
    Result Should Read    test /a
    Copy Should Do Nothing    ${PATCH_COPY_X}    ${HEADER_Y}

TC-PAT-008 An Array Index Out Of Range Is An Error
    [Documentation]    Adding past the end of an array (index 5 of one with a
    ...    single element) is refused, naming the operation and the path.
    [Tags]    p2
    Open Tool    patch
    Fill Patch Page    {"list":[1]}    [{"op":"add","path":"/list/5","value":2}]
    Press Main Button
    Result Should Read    operation 1
    Result Should Read    /list/5

TC-PAT-009 A Pointer Reaches A Key That Has A Slash
    [Documentation]    ~1 in a path stands for a slash in a key and ~0 for a tilde:
    ...    "/a~1b" is the key "a/b".
    [Tags]    p2
    Open Tool    patch
    Fill Patch Page    {"a/b":1,"c~d":1}    [{"op":"replace","path":"/a~1b","value":2},{"op":"replace","path":"/c~0d","value":3}]
    Apply Patch
    Patched Should Be    {"a/b":2,"c~d":3}

TC-PAT-010 Apply Needs Both Boxes
    [Documentation]    Apply is dim until the Document and the Patch both have
    ...    text.
    [Tags]    p1
    Open Tool    patch
    Apply Button Should Be Disabled
    Paste Into Box    ${FIRST_BOX_X}    ${FIRST_BOX_Y}    ${DOC}
    Apply Button Should Be Disabled
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${OPS}
    Apply Button Should Be Enabled

TC-PAT-011 Open In Main Window Waits For A Result
    [Documentation]    Open in main window is dim until there is a patched
    ...    document, and bright after.
    [Tags]    p2
    Open Tool    patch
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    @{OPEN_IN_MAIN_BUTTON}    threshold=150
    Fill Patch Page    ${DOC}    ${OPS}
    Apply Patch
    Get Ink Bounds    @{OPEN_IN_MAIN_BUTTON}    threshold=150

TC-PAT-012 The Patched Document Becomes The Main Window's Document
    [Documentation]    After "Open in main window" the main window's toolbar names
    ...    the document "(patched)" and its tree shows the patched document: the
    ...    array "b" now has three items.
    [Tags]    p1
    Open Tool    patch
    Fill Patch Page    ${DOC}    ${OPS}
    Apply Patch
    Click At    ${OPEN_IN_MAIN_X}    ${HEADER_Y}
    Switch To Main Window
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_AREA}    patched
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    3 items

TC-PAT-013 Editing A Box Drops The Result
    [Documentation]    Typing in the Document box (or the Patch box) clears the
    ...    result and the status bar's summary.
    [Tags]    p1
    Open Tool    patch
    Fill Patch Page    {"a":"platypus"}    [{"op":"add","path":"/b","value":1}]
    Apply Patch
    Result Should Read    platypus
    Click At    ${FIRST_BOX_X}    ${FIRST_BOX_Y}
    Press Keys    ctrl    end
    Type Text    ${SPACE}
    Sleep    0.5s
    Result Should Not Read    platypus
    Status Should Not Read    operation

TC-PAT-014 Clear Empties A Box
    [Documentation]    Clear in the Patch box's header empties it, drops the
    ...    result, and Apply is dim again.
    [Tags]    p2
    Open Tool    patch
    Fill Patch Page    {"a":"platypus"}    [{"op":"add","path":"/b","value":1}]
    Apply Patch
    Click At    ${CLEAR_X}    ${SECOND_HEADER_Y}
    Sleep    0.5s
    Result Should Not Read    platypus
    Region Should Not Contain Text    @{SECOND_BOX}    add
    Apply Button Should Be Disabled

TC-PAT-015 The Open Document Is Patched
    [Documentation]    "Open document" in the Document header uses the document
    ...    open in the main window, and the patch is applied to it.
    [Tags]    p1
    Load Fixture Via Paste    {"x":"platypus"}
    Open Tool    patch
    Click At    ${OPEN_DOCUMENT_X}    ${HEADER_Y}
    Sleep    0.5s
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    [{"op":"add","path":"/y","value":2}]
    Apply Patch
    Patched Should Be    {"x":"platypus","y":2}

TC-PAT-016 Ctrl+Enter Applies
    [Documentation]    The shortcut runs Apply from a box.
    [Tags]    p2
    Open Tool    patch
    Fill Patch Page    ${DOC}    ${OPS}
    Press Keys    ctrl    enter
    Status Should Read    operation

TC-PAT-017 Copy Says So In The Status Bar
    [Documentation]    After Copy the status bar says "Copied".
    [Tags]    p2
    Open Tool    patch
    Fill Patch Page    ${DOC}    ${OPS}
    Apply Patch
    Click At    ${PATCH_COPY_X}    ${HEADER_Y}
    Status Should Read    Copied

TC-PAT-018 Numbers Keep Their Digits Through A Patch
    [Documentation]    The digits of a number that is not touched come back as
    ...    they were written (1.50, a long integer), and a number put in by the
    ...    patch is written as given.
    [Tags]    p2
    Open Tool    patch
    Fill Patch Page    {"keep":1.50,"big":12345678901234567890123}    [{"op":"add","path":"/new","value":2.0}]
    Apply Patch
    ${nl}=    Evaluate    chr(10)
    ${expected}=    Catenate    SEPARATOR=${nl}
    ...    {
    ...    \ \ "keep": 1.50,
    ...    \ \ "big": 12345678901234567890123,
    ...    \ \ "new": 2.0
    ...    }
    Copy Should Give    ${PATCH_COPY_X}    ${HEADER_Y}    ${expected}
