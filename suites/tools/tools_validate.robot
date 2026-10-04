*** Settings ***
Documentation     Tools window, the Validate schema page -- see
...               docs/13_tools_window.md. A Document and a Schema (two boxes,
...               one above the other) give the Problems: each with its JSON
...               Pointer ("(document)" for the whole) and what is wrong. The
...               draft is taken from the schema's $schema (2020-12 by default),
...               formats are checked unless "Check formats" is off, and nothing
...               is ever fetched. A problem in the document that is open in the
...               main window can be shown there.
...
...               The messages are plain text OCR reads well; the exact report is
...               checked through the clipboard (Copy report).
Resource          ../../resources/tools.resource
Force Tags        tools    validate
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${DOC}               {"age":-1,"tags":["ok",5],"extra":true}
${SCHEMA}            {"type":"object","properties":{"age":{"type":"integer","minimum":0},"name":{"type":"string"},"tags":{"type":"array","items":{"type":"string"}}},"required":["name"],"additionalProperties":false}
@{VALIDATE_BUTTON}    8     24     56     20
@{SHOW_IN_MAIN_BUTTON}    760    54     134    18
# Where the first row is, and the colour of its background when it is the picked
# one (the selection colour, half translucent).
@{FIRST_ROW}         458    76     434    20
@{PICKED_ROW_RGB}    13     59     77

*** Keywords ***
Fill Validate Page
    [Arguments]    ${document}    ${schema}
    Paste Into Box    ${FIRST_BOX_X}    ${FIRST_BOX_Y}    ${document}
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${schema}

Run Validate
    [Documentation]    Presses Validate and waits for the status bar to say what
    ...    came out ("Checked against Draft ...").
    Press Main Button
    Status Should Read    Checked against

Validate Button Should Be Disabled
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    @{VALIDATE_BUTTON}    threshold=150

Validate Button Should Be Enabled
    Get Ink Bounds    @{VALIDATE_BUTTON}    threshold=150

Show In Main Window Should Be Disabled
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    @{SHOW_IN_MAIN_BUTTON}    threshold=150

Show In Main Window Should Be Enabled
    Get Ink Bounds    @{SHOW_IN_MAIN_BUTTON}    threshold=150

*** Test Cases ***
TC-TWIN-010 Validate Schema Lists The Problems
    [Documentation]    A document that breaks its schema in four ways: each
    ...    problem is listed with where it is (the document itself is
    ...    "(document)") and what is wrong.
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    ${DOC}    ${SCHEMA}
    Press Main Button
    Result Should Read    /age
    Result Should Read    /tags/1
    Result Should Read    (document)
    Result Should Read    required property
    Status Should Read    problems

TC-TWIN-011 A Problem Can Be Shown In The Main Window
    [Documentation]    With the document open in the main window used as the
    ...    one to check, picking a problem and pressing "Show in main window"
    ...    puts its JSON Pointer in the main window's query box and runs it, so
    ...    the value at fault is what the results show.
    [Tags]    p1
    Load Fixture Via Paste    {"age": -1, "name": "Ann"}
    Open Tool    validate
    Click At    ${OPEN_DOCUMENT_X}    ${HEADER_Y}
    Sleep    0.3s
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    {"properties":{"age":{"minimum":0}}}
    Press Main Button
    Result Should Read    /age
    Click At    640    ${FIRST_ROW_Y}
    Sleep    0.3s
    Click At    ${SHOW_IN_MAIN_X}    ${HEADER_Y}
    Switch To Main Window
    # The query ran under the Pointer engine and found the one value. (The query
    # box itself is tinted, which OCR reads badly; the status bar says it all.)
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_BAR}    1 result(s) [Pointer]

TC-VAL-001 A Document That Fits Is Valid
    [Documentation]    No problems: the result says "The document is valid" and
    ...    the draft, the status bar says "Valid".
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    {"name":"Ann","age":3}    ${SCHEMA}
    Run Validate
    Status Should Read    Valid
    Result Should Read    document is valid
    Result Should Read    Draft 2020-12

TC-VAL-002 The Draft Comes From The Schema
    [Documentation]    A schema that says $schema draft-07 is checked as draft 7
    ...    and the status bar names it; one that says nothing is 2020-12.
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    {"a":1}    {"$schema":"http://json-schema.org/draft-07/schema#","type":"object"}
    Run Validate
    Status Should Read    Draft 7

TC-VAL-003 Formats Are Checked By Default
    [Documentation]    A string that is not an email, held to "format": "email",
    ...    is a problem at its place; the status bar says "1 problem".
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    {"mail":"nope"}    {"properties":{"mail":{"type":"string","format":"email"}}}
    Run Validate
    Status Should Read    1 problem
    # (The path is read as "/marl" at times; the message has the word.)
    Result Should Read    email

TC-VAL-004 Check Formats Can Be Turned Off
    [Documentation]    With "Check formats" unchecked the same document is valid:
    ...    a format is then only an annotation. Changing the option drops the
    ...    old result, so Validate is pressed again.
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    {"mail":"nope"}    {"properties":{"mail":{"type":"string","format":"email"}}}
    Run Validate
    Status Should Read    1 problem
    Click At    ${CHECK_FORMATS_X}    ${COMMAND_Y}
    Sleep    0.5s
    Status Should Not Read    problem
    Run Validate
    Status Should Read    Valid

TC-VAL-005 A Schema That Is Not A Schema Is Explained
    [Documentation]    A "type" that is no type name is not a usable schema: the
    ...    result says "The schema can't be used" and why, instead of passing
    ...    the document.
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    {"a":1}    {"type":"nonsense"}
    Press Main Button
    Result Should Read    schema
    Result Should Read    can't be used

TC-VAL-006 A Reference To Somewhere Else Is Refused
    [Documentation]    A $ref to a URL is not followed -- nothing is ever
    ...    fetched -- and says so.
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    {"a":1}    {"$ref":"http://example.com/schema.json"}
    Press Main Button
    Result Should Read    can't be used

TC-VAL-007 A Reference Inside The Schema Works
    [Documentation]    $ref to the schema's own $defs is resolved: the integer
    ...    that is held to the definition is reported when it is wrong.
    [Tags]    p2
    Open Tool    validate
    Fill Validate Page    {"n":"text"}    {"$defs":{"count":{"type":"integer"}},"properties":{"n":{"$ref":"#/$defs/count"}}}
    Run Validate
    Status Should Read    1 problem
    Result Should Read    /n

TC-VAL-008 A Document That Is Not JSON Is Named
    [Documentation]    The error names the box ("Document") and what is wrong.
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    {"a":    ${SCHEMA}
    Press Main Button
    Result Should Read    Document
    Result Should Read    parsing JSON

TC-VAL-009 A Schema That Is Not JSON Is Named
    [Documentation]    Likewise for the Schema box.
    [Tags]    p2
    Open Tool    validate
    Fill Validate Page    ${DOC}    {"type":
    Press Main Button
    Result Should Read    Schema
    Result Should Read    parsing JSON

TC-VAL-010 Validate Needs Both Boxes
    [Documentation]    Validate is dim until the Document and the Schema both have
    ...    text.
    [Tags]    p1
    Open Tool    validate
    Validate Button Should Be Disabled
    Paste Into Box    ${FIRST_BOX_X}    ${FIRST_BOX_Y}    ${DOC}
    Validate Button Should Be Disabled
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${SCHEMA}
    Validate Button Should Be Enabled

TC-VAL-011 The Report Can Be Copied
    [Documentation]    Copy report puts the verdict, the draft and one line to a
    ...    problem -- its path, the message and the keyword that found it --
    ...    on the clipboard.
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    {"age":-1}    {"properties":{"age":{"minimum":0}}}
    Run Validate
    ${nl}=    Evaluate    chr(10)
    ${expected}=    Catenate    SEPARATOR=${EMPTY}
    ...    1 problem (Draft 2020-12)${nl}
    ...    /age: -1 is less than the minimum of 0 [minimum]${nl}
    Copy Should Give    ${COPY_REPORT_X}    ${HEADER_Y}    ${expected}
    Status Should Read    Copied

TC-VAL-012 Copy Report Is Dim Without Problems
    [Documentation]    A valid document has no report: pressing Copy report copies
    ...    nothing.
    [Tags]    p2
    Open Tool    validate
    Fill Validate Page    {"name":"Ann"}    ${SCHEMA}
    Run Validate
    Copy Should Do Nothing    ${COPY_REPORT_X}    ${HEADER_Y}

TC-VAL-013 Picking A Row Marks It
    [Documentation]    A click on a problem picks it: its row is drawn in the
    ...    selection colour. With the document not being the open one,
    ...    "Show in main window" stays dim -- the pointer means nothing there.
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    ${DOC}    ${SCHEMA}
    Press Main Button
    Result Should Read    /age
    Region Should Not Contain Color    @{FIRST_ROW}    @{PICKED_ROW_RGB}    tolerance=8
    Click At    640    ${FIRST_ROW_Y}
    Sleep    0.4s
    ${rows}=    Get Rows With Color    @{FIRST_ROW}    @{PICKED_ROW_RGB}    tolerance=8
    Should Not Be Empty    ${rows}    msg=The picked row is not drawn in the selection colour
    Show In Main Window Should Be Disabled

TC-VAL-014 Show In Main Window Needs The Open Document
    [Documentation]    With the main window's document as the one checked and a
    ...    row picked, "Show in main window" is bright; without a row it is dim.
    [Tags]    p1
    Load Fixture Via Paste    {"age": -1, "name": "Ann"}
    Open Tool    validate
    Click At    ${OPEN_DOCUMENT_X}    ${HEADER_Y}
    Sleep    0.3s
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    {"properties":{"age":{"minimum":0}}}
    Press Main Button
    Result Should Read    /age
    Show In Main Window Should Be Disabled
    Click At    640    ${FIRST_ROW_Y}
    Sleep    0.4s
    Show In Main Window Should Be Enabled

TC-VAL-015 A Double-Click Shows The Problem
    [Documentation]    A double-click on a row of the open document's report does
    ...    what "Show in main window" does: the pointer runs in the main window.
    [Tags]    p1
    Load Fixture Via Paste    {"age": -1, "name": "Ann"}
    Open Tool    validate
    Click At    ${OPEN_DOCUMENT_X}    ${HEADER_Y}
    Sleep    0.3s
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    {"properties":{"age":{"minimum":0}}}
    Press Main Button
    Result Should Read    /age
    Double Click At    640    ${FIRST_ROW_Y}
    Switch To Main Window
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_BAR}    1 result(s) [Pointer]

TC-VAL-016 Editing A Box Drops The Report
    [Documentation]    Typing in the Document box clears the problems and the
    ...    status bar's verdict.
    [Tags]    p1
    Open Tool    validate
    Fill Validate Page    ${DOC}    ${SCHEMA}
    Press Main Button
    Result Should Read    /age
    Click At    ${FIRST_BOX_X}    ${FIRST_BOX_Y}
    Press Keys    ctrl    end
    Type Text    ${SPACE}
    Sleep    0.5s
    Result Should Not Read    /age
    Status Should Not Read    problems

TC-VAL-017 Ctrl+Enter Validates
    [Documentation]    The shortcut runs Validate from a box.
    [Tags]    p2
    Open Tool    validate
    Fill Validate Page    ${DOC}    ${SCHEMA}
    Press Keys    ctrl    enter
    Status Should Read    problems

TC-VAL-018 Every Problem Is Listed
    [Documentation]    A document with problems of several kinds lists one row for
    ...    each, in a list that holds them all: five properties that must be
    ...    integers, all strings, are five problems.
    [Tags]    p2
    Open Tool    validate
    Fill Validate Page    {"a":"x","b":"x","c":"x","d":"x","e":"x"}    {"additionalProperties":{"type":"integer"}}
    Run Validate
    Status Should Read    5 problems
    Result Should Read    /a
    Result Should Read    /d
