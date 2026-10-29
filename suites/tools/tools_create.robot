*** Settings ***
Documentation     Tools window, the Create Schema page -- see docs/13_tools_window.md. A
...               Document (pasted, a file, dropped, or the document open in the main window)
...               gives a JSON Schema: the types, the members and which every object has, and
...               what the strings are -- a date, a uuid, an address, a code of one shape, a
...               list of them with commas between -- as a format and a pattern. The options
...               (Draft, Patterns, Required, No other keys, Enums, Bounds) are in the command
...               row. The schema is in a box on the right, with Use in Validate, Save..., Copy
...               and Reset over it, and under it the list of the patterns (and enums) found.
...
...               A click on a row opens it under the list, to write another expression, make it
...               a plain string (for keys, any key) or put back what was found; an enum opens
...               with a tick for each value and a box to put in another. The click points the
...               pattern out: highlighted in the schema, and in the document the first place it
...               was found, with ⏶ and ⏷ to the others.
...
...               The schema is read through Copy, as JSON, and checked member by member; the
...               rows and the lines of what is open by OCR; what is highlighted by its orange,
...               read with the orange taken out (`Read Marked Text`); a button's state by the
...               brightness of its label.
Resource          ../../resources/tools.resource
Resource          ../../resources/results.resource
Force Tags        tools    create
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${CREATE_FIXTURES}    ${CURDIR}/../../resources/fixtures/create
# What the orders fixture gives (the patterns as the app writes them).
${ID_PATTERN}        ^ORD-[0-9]{4}-[0-9]{5}$
${UUID_PATTERN}      ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$
${WORDS_PATTERN}     ^(?:[a-z]+(?:,[a-z]+)*)?$
${OCTET}             (?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])
${JSON_FILTER}       ${{ [{"name": "JSON", "globs": ["*.json"]}] }}
${OPEN_FILE_X}       248
# The items of a row's right-click menu: Copy pattern (Copy enum), Copy path, Copy row.
${MENU_FIRST_Y}      16
${MENU_PITCH}        21
${MENU_X_OFFSET}     40
# The part of the list that is on show above an open enum (its rows are scrolled to keep the
# one picked in view), and where the tooltip of a row low in the list is.
@{LIST_ABOVE_ENUM}    458    375    434    88
@{ROW_TOOLTIP}       408    280    490    150
# Where the Schema header says "edited" (dim: read by its ink, which is about 95).
@{EDITED_LABEL}      515    56     60     14

*** Keywords ***
Open Create Page
    Open Tool    create

Create Orders
    [Documentation]    The orders fixture's schema made, with the options as they are.
    Open Create Page
    Create From Fixture    orders.json

Create Orders With Enums
    Open Create Page
    Fill Create Page    orders.json
    Click Option    enums
    Press Main Button
    Status Should Read    1 enum

Click Option
    [Documentation]    Ticks or unticks an option of the command row (patterns, required,
    ...    closed, enums, bounds).
    [Arguments]    ${option}
    Click At    ${OPTION_X}[${option}]    ${COMMAND_Y}
    Sleep    0.4s

Pick Draft
    [Arguments]    ${draft}
    Click At    ${DRAFT_X}    ${COMMAND_Y}
    Sleep    0.4s
    Click At    ${DRAFT_ITEM_X}    ${DRAFT_ITEM_Y}[${draft}]
    Sleep    0.4s

Copy From Row Menu
    [Documentation]    Right-clicks row `n` of the list and picks the item `item` (0: Copy pattern
    ...    or Copy enum, 1: Copy path, 2: Copy row); the clipboard is set to a marker first.
    [Arguments]    ${n}    ${item}
    Set Clipboard    nothing was copied
    ${y}=    Found Row Y    ${n}
    Right Click At    ${FOUND_ROW_X}    ${y}
    Sleep    0.5s
    ${at_x}=    Evaluate    ${FOUND_ROW_X} + ${MENU_X_OFFSET}
    ${at_y}=    Evaluate    ${y} + ${MENU_FIRST_Y} + ${MENU_PITCH} * int(${item})
    Click At    ${at_x}    ${at_y}
    Sleep    0.5s
    ${copied}=    Get Clipboard
    RETURN    ${copied}

Press Apply
    Click At    ${APPLY_X}    ${EDITOR_BUTTON_Y}
    Sleep    0.5s

Press Plain
    Click At    ${PLAIN_X}    ${EDITOR_BUTTON_Y}
    Sleep    0.5s

Press Restore
    Click At    ${PATTERN_RESTORE_X}    ${EDITOR_BUTTON_Y}
    Sleep    0.5s

Editor Line Should Read
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Show Text    @{EDITOR_LINE}    ${text}

Place Should Be
    [Documentation]    The line of what is open says which place of how many is highlighted:
    ...    "2 of 3" (read as a pattern: OCR reads "of" after a digit as "o0f" at times).
    [Arguments]    ${at}    ${count}    @{region}
    ${region}=    Set Variable If    $region    ${region}    ${EDITOR_PLACE}
    Wait Until Region Matches    @{region}    ${at} ?[o0]?.?f ?${count}    timeout=6

Enum Of Orders Should Be
    [Arguments]    @{values}
    ${expected}=    Evaluate    repr(list($values))
    Copied Schema Should Have    ITEM["status"]["enum"]    ${expected}

Schema Should Say Edited
    Get Ink Bounds    @{EDITED_LABEL}    threshold=80

Schema Should Not Say Edited
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    @{EDITED_LABEL}    threshold=80

List Above Enum Should Read
    [Documentation]    What the rows on show above an open enum say (the one picked among them).
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Show Text    @{LIST_ABOVE_ENUM}    ${text}

Status Of Orders Should Be
    [Documentation]    What the schema says of an order's status: exactly `expected` (Python).
    [Arguments]    ${expected}
    Copied Schema Should Have    ITEM["status"]    ${expected}

Click Enum Value
    [Documentation]    The tick of a value of the enum that is open, found by its word in the row
    ...    of ticks.
    [Arguments]    ${word}
    ${x}    ${y}=    Find Text In Region    @{ENUM_VALUES}    ${word}
    ${box}=    Evaluate    ${x} - 30
    Click At    ${box}    ${ENUM_VALUES_Y}
    Sleep    0.5s

Pointer Away
    Move Mouse To    600    ${TAB_Y}
    Sleep    0.4s

*** Test Cases ***
TC-CSC-001 Create Needs A Document
    [Documentation]    The page opens with an empty Document box and Create dim; with a document
    ...    in the box, Create is bright.
    [Tags]    p1
    Open Create Page
    Page Should Show    Document    @{LEFT_HEADER}
    Button Should Be Dim    @{CREATE_BUTTON}
    Fill Create Page    orders.json
    Button Should Be Bright    @{CREATE_BUTTON}

TC-CSC-002 Create Makes A Schema Of The Document
    [Documentation]    Three orders give one schema of an order: the array's items are an
    ...    object whose members are all required, the id a code of one shape, placed a
    ...    date-time, customer a uuid, ip an IPv4 address, tags a list of words. The schema is
    ...    of draft 2020-12, and the status bar says what it names and that the document fits it.
    [Tags]    p1
    Create Orders
    ${schema}=    Copied Schema
    ${draft}=    Evaluate    $schema["$schema"]
    Should Be Equal    ${draft}    https://json-schema.org/draft/2020-12/schema
    ${item}=    Set Variable    ${schema}[properties][orders][items]
    Should Be Equal    ${item}[type]    object
    Should Be Equal    ${item}[required]    ${{ ["id", "placed", "customer", "ip", "tags", "status"] }}
    Should Be Equal    ${item}[properties][id]    ${{ {"type": "string", "pattern": $ID_PATTERN} }}
    Should Be Equal    ${item}[properties][placed][format]    date-time
    Should Be Equal    ${item}[properties][customer]    ${{ {"type": "string", "format": "uuid", "pattern": $UUID_PATTERN} }}
    Should Be Equal    ${item}[properties][ip][format]    ipv4
    Should Be Equal    ${item}[properties][tags][pattern]    ${WORDS_PATTERN}
    Should Be Equal    ${item}[properties][status]    ${{ {"type": "string"} }}
    Status Should Read    7 properties
    Status Should Read    5 patterns
    Status Should Read    The document fits it

TC-CSC-003 Ctrl+Enter Creates
    [Documentation]    The shortcut makes the schema from the Document box.
    [Tags]    p2
    Open Create Page
    Fill Create Page    orders.json
    Press Keys    ctrl    enter
    Status Should Read    The document fits it

TC-CSC-004 The Patterns Found Are Listed
    [Documentation]    Under the schema, "Patterns (5)" and a row for each: where (as jq writes
    ...    the path) and what was found, with its format.
    [Tags]    p1
    Create Orders
    Pointer Away
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{FOUND_HEADER}    Patterns (5
    Found Row Should Read    0    like ORD-1357-24681
    Found Row Should Read    1    date-time
    Found Row Should Read    2    uuid
    Found Row Should Read    3    IPv4 address
    Found Row Should Read    4    comma-separated: words

TC-CSC-005 Copy List Gives A Row To A Line
    [Documentation]    Copy list copies every row: the path, what was found and the pattern,
    ...    with tabs between.
    [Tags]    p1
    Create Orders
    ${tab}=    Evaluate    chr(9)
    ${nl}=    Evaluate    chr(10)
    ${expected}=    Catenate    SEPARATOR=
    ...    .orders[].id${tab}like ORD-1357-24681${tab}${ID_PATTERN}${nl}
    ...    .orders[].placed${tab}date-time · format date-time${tab}
    ...    ^[0-9]{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])T(?:[01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](?:\\.[0-9]+)?(?:Z|[+-](?:[01][0-9]|2[0-3]):[0-5][0-9])$${nl}
    ...    .orders[].customer${tab}uuid · format uuid${tab}${UUID_PATTERN}${nl}
    ...    .orders[].ip${tab}IPv4 address · format ipv4${tab}^(?:${OCTET}\\.){3}${OCTET}$${nl}
    ...    .orders[].tags${tab}comma-separated: words${tab}${WORDS_PATTERN}${nl}
    Copy Should Give    ${COPY_LIST_X}    ${FOUND_HEADER_Y}    ${expected}
    Status Should Read    Copied the patterns

TC-CSC-006 A Row's Menu Copies Its Pattern, Its Path And The Row
    [Documentation]    The right-click menu of a row has Copy pattern, Copy path and Copy row.
    [Tags]    p1
    Create Orders
    ${copied}=    Copy From Row Menu    0    0
    Should Be Equal    ${copied}    ${ID_PATTERN}
    ${copied}=    Copy From Row Menu    2    1
    Should Be Equal    ${copied}    .orders[].customer
    ${copied}=    Copy From Row Menu    2    2
    Should Be Equal    ${copied}    .orders[].customer${{ chr(9) }}uuid · format uuid${{ chr(9) }}${UUID_PATTERN}

TC-CSC-007 A Row's Tooltip Has Its Pattern And Format
    [Documentation]    Hovering a row shows what was found, where, the pattern and the format, and
    ...    that a click finds it and changes it.
    [Tags]    p2
    Create Orders
    ${y}=    Found Row Y    3
    Move Mouse To    ${FOUND_ROW_X}    ${y}
    Sleep    1.2s
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{ROW_TOOLTIP}    Format: ipv4
    Region Should Contain Text    @{ROW_TOOLTIP}    Click to find it

TC-CSC-008 Without Patterns The Strings Are Plain
    [Documentation]    With Patterns off, a string is only a string: no format and no pattern;
    ...    the list says so and Copy list is dim.
    [Tags]    p1
    Open Create Page
    Click Option    patterns
    Create From Fixture    orders.json
    Copied Schema Should Have    ITEM["id"]    {"type": "string"}
    Copied Schema Should Have    ITEM["customer"]    {"type": "string"}
    Status Should Read    0 patterns
    Copy Should Do Nothing    ${COPY_LIST_X}    ${FOUND_HEADER_Y}

TC-CSC-009 Without Required Nothing Is Required
    [Tags]    p2
    Open Create Page
    Click Option    required
    Create From Fixture    orders.json
    ${schema}=    Copied Schema
    ${text}=    Evaluate    json.dumps($schema)    modules=json
    Should Not Contain    ${text}    "required"

TC-CSC-010 No Other Keys Allows Only The Members Seen
    [Documentation]    Every object of the schema gets additionalProperties: false.
    [Tags]    p2
    Open Create Page
    Click Option    closed
    Create From Fixture    orders.json
    Copied Schema Should Have    ["additionalProperties"]    False
    Copied Schema Should Have    ["properties"]["orders"]["items"]["additionalProperties"]    False
    Status Should Read    The document fits it

TC-CSC-011 Enums Make An Enum Of A Few Strings
    [Documentation]    With Enums, the status (open, closed, open) is an enum in place of a plain
    ...    string; the list is "Patterns and enums (6)", its last row says the values, and the
    ...    status bar counts the enum.
    [Tags]    p1
    Create Orders With Enums
    Status Of Orders Should Be    {"type": "string", "enum": ["open", "closed"]}
    Pointer Away
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{FOUND_HEADER}    Patterns and enums (6
    Found Row Should Read    5    enum: open, closed

TC-CSC-012 Bounds Give The Least And The Most Seen
    [Documentation]    With Bounds, the list of three orders has minItems and maxItems 3, and the
    ...    widths of the patterns become ranges where they differ.
    [Tags]    p2
    Open Create Page
    Click Option    bounds
    Create From Fixture    orders.json
    Copied Schema Should Have    ["properties"]["orders"]["minItems"]    3
    Copied Schema Should Have    ["properties"]["orders"]["maxItems"]    3
    Status Should Read    The document fits it

TC-CSC-013 The Draft Is Written And Decides The Formats
    [Documentation]    Draft 7 is written in $schema, and a uuid has its pattern but no format
    ...    (uuid is a format of 2019-09 on).
    [Tags]    p1
    Open Create Page
    Pick Draft    7
    Create From Fixture    orders.json
    Copied Schema Should Have    ["$schema"]    "http://json-schema.org/draft-07/schema#"
    Copied Schema Should Have    ITEM["customer"]    {"type": "string", "pattern": $UUID_PATTERN}
    Copied Schema Should Have    ITEM["placed"]["format"]    "date-time"

TC-CSC-014 Changing An Option Drops The Schema
    [Documentation]    The schema made no longer matches the options: it goes, and Copy is dim.
    [Tags]    p2
    Create Orders
    Click Option    required
    Status Should Not Read    Created in
    Copy Should Do Nothing    ${SCHEMA_COPY_X}    ${HEADER_Y}

TC-CSC-015 Typing In The Document Drops The Schema
    [Tags]    p2
    Create Orders
    Click At    ${CREATE_BOX_X}    ${CREATE_BOX_Y}
    Press Keys    ctrl    end
    Type Text    ${SPACE}
    Sleep    0.5s
    Status Should Not Read    Created in
    Copy Should Do Nothing    ${SCHEMA_COPY_X}    ${HEADER_Y}

TC-CSC-016 A Document That Is Not JSON Is Named
    [Documentation]    The error names the box and says what is wrong; there is no schema.
    [Tags]    p1
    Open Create Page
    Paste Into Box    ${CREATE_BOX_X}    ${CREATE_BOX_Y}    {"a":
    Press Main Button
    Wait Until Keyword Succeeds    8x    0.5s    Region Should Contain Text    @{SCHEMA_BOX}    Document
    Region Should Contain Text    @{SCHEMA_BOX}    JSON
    Copy Should Do Nothing    ${SCHEMA_COPY_X}    ${HEADER_Y}

TC-CSC-017 A List May Be Empty
    [Documentation]    Addresses with commas between, one of them none at all (""), are a list
    ...    of IPv4 addresses: empty, or one or more. The ports, with semicolons, are a list of
    ...    numbers written as text. The document fits the schema made, the empty one too.
    [Tags]    p1
    Open Create Page
    Create From Fixture    servers.json
    Copied Schema Should Have    ["properties"]["servers"]["items"]["properties"]["ips"]["pattern"]
    ...    "^(?:(?:" + $OCTET + "\\\\.){3}" + $OCTET + "(?:,(?:" + $OCTET + "\\\\.){3}" + $OCTET + ")*)?$"
    Copied Schema Should Have    ["properties"]["servers"]["items"]["properties"]["ports"]["pattern"]
    ...    "^(?:[0-9]+(?:;[0-9]+)*)?$"
    Found Row Should Read    0    comma-separated: IPv4 address
    Found Row Should Read    1    semicolon-separated
    Status Should Read    The document fits it

TC-CSC-018 Numbered Keys And Keys That Are Data Are Patterns Of Keys
    [Documentation]    phone1 and phone2 are numbered keys, ^phone[0-9]+$, and the owners' keys,
    ...    all uuids, make a map: both are under patternProperties, and the list says so.
    [Tags]    p2
    Open Create Page
    Create From Fixture    servers.json
    ${schema}=    Copied Schema
    Dictionary Should Contain Key    ${schema}[properties][servers][items][patternProperties]    ^phone[0-9]+$
    Dictionary Should Contain Key    ${schema}[properties][owners][patternProperties]    ${UUID_PATTERN}
    Found Row Should Read    2    numbered keys: phone1, phone2
    Found Row Should Read    4    keys: uuid

TC-CSC-019 Use In Validate Checks The Document Against The Schema
    [Documentation]    Use in Validate puts the document and the schema in Validate Schema's boxes,
    ...    shows that page and checks: the document is valid.
    [Tags]    p1
    Create Orders
    Click At    ${USE_IN_VALIDATE_X}    ${HEADER_Y}
    Sleep    0.8s
    Tab Should Be Selected    validate
    Status Should Read    Valid
    Result Should Read    document is valid

TC-CSC-020 Save Writes The Schema
    [Documentation]    Save... of a pasted document suggests schema.json, a JSON file, and writes
    ...    the schema that Copy gives.
    [Tags]    p1
    Create Orders
    ${made}=    Copied Schema
    ${dir}=    Make Temp Directory
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${dir}
    Click At    ${SCHEMA_SAVE_X}    ${HEADER_Y}
    ${asked}=    Wait For Dialog After    ${before}
    Should Be Equal    ${asked}[current_name]    schema.json
    Should Be Equal    ${asked}[filters]    ${JSON_FILTER}
    Wait Until Keyword Succeeds    15x    0.4s    File Should Exist    ${dir}/schema.json
    ${text}=    Wait Until Keyword Succeeds    15x    0.4s    Get File    ${dir}/schema.json
    ${saved}=    Evaluate    json.loads($text)    modules=json
    Should Be Equal    ${saved}    ${made}

TC-CSC-021 A File Opened Is The Document, And Names The Save
    [Documentation]    Open file... loads the file chosen into the Document box; Create, then
    ...    Save... suggests orders.schema.json.
    [Tags]    p2
    Open Create Page
    ${before}=    Portal Request Count
    Portal Will Pick    ${CREATE_FIXTURES}/orders.json
    Click At    ${OPEN_FILE_X}    ${HEADER_Y}
    ${opened}=    Wait For Dialog After    ${before}
    Should Be Equal    ${opened}[method]    OpenFile
    Press Main Button
    Status Should Read    The document fits it
    ${dir}=    Make Temp Directory
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${dir}
    Click At    ${SCHEMA_SAVE_X}    ${HEADER_Y}
    ${asked}=    Wait For Dialog After    ${before}
    Should Be Equal    ${asked}[current_name]    orders.schema.json

TC-CSC-022 A Dropped File Is The Document
    [Tags]    p2
    Open Create Page
    Drop Files On Window    ${CREATE_BOX_X}    ${CREATE_BOX_Y}    ${CREATE_FIXTURES}/servers.json
    Sleep    0.8s
    Press Main Button
    Status Should Read    6 properties

TC-CSC-023 The Document Open In The Main Window Can Be Used
    [Documentation]    Open document takes the main window's document: the schema is made of it.
    ...    Its text is not shown in the box, so a click on a pattern points it out in the schema
    ...    only, and the line of what is open says no "1 of n".
    [Tags]    p1    main-layout
    ${text}=    Get File    ${CREATE_FIXTURES}/orders.json
    Load Fixture Via Paste    ${text}
    Open Create Page
    Click At    ${OPEN_DOCUMENT_X}    ${HEADER_Y}
    Sleep    0.3s
    Press Main Button
    Status Should Read    7 properties
    Open Found Row    2
    Schema Should Point Out    a-f
    Nothing Should Be Pointed Out    @{CREATE_DOCUMENT}
    Run Keyword And Expect Error    *    Place Should Be    1    3

TC-CSC-030 A Click Opens The Pattern Under The List
    [Documentation]    A click on a row picks it and opens it: its line says which, its box holds
    ...    the pattern, Apply and Restore are dim (it is as found), Plain string is bright.
    [Tags]    p1
    Create Orders
    Open Found Row    0
    Editor Line Should Read    Pattern of
    Editor Line Should Read    orders[].id
    ${y}=    Found Row Y    0
    ${top}=    Evaluate    ${y} - 9
    ${rows}=    Get Rows With Color    460    ${top}    430    18    13    59    77    tolerance=8
    Should Not Be Empty    ${rows}    msg=The row is not drawn as the picked one
    Editor Box Should Hold    ${ID_PATTERN}
    Button Should Be Dim    @{APPLY_BUTTON}
    Button Should Be Dim    @{PATTERN_RESTORE_BUTTON}
    Button Should Be Bright    @{PLAIN_BUTTON}

TC-CSC-031 Apply Puts Another Expression In The Schema
    [Documentation]    Another expression in the box and Apply: the schema has it, the row says
    ...    edited, the Schema header says edited and Reset is bright, and the status bar says the
    ...    schema was changed. Apply is dim again: it is the expression the schema has.
    [Tags]    p1
    Create Orders
    Open Found Row    0
    Schema Should Not Say Edited
    Put In Editor Box    ^ORD-[0-9]+-[0-9]+$
    Button Should Be Bright    @{APPLY_BUTTON}
    Press Apply
    Pointer Away
    Copied Schema Should Have    ITEM["id"]    {"type": "string", "pattern": "^ORD-[0-9]+-[0-9]+$"}
    Found Row Should Read    0    edited
    Wait Until Keyword Succeeds    6x    0.5s    Schema Should Say Edited
    Button Should Be Bright    @{RESET_BUTTON}
    Status Should Read    Edited
    Button Should Be Dim    @{APPLY_BUTTON}
    Button Should Be Bright    @{PATTERN_RESTORE_BUTTON}

TC-CSC-032 Enter Applies The Expression
    [Tags]    p2
    Create Orders
    Open Found Row    0
    Put In Editor Box    ^ORD-.*$
    Press Keys    enter
    Sleep    0.5s
    Copied Schema Should Have    ITEM["id"]["pattern"]    "^ORD-.*$"

TC-CSC-033 An Expression That Cannot Be Read Is Refused
    [Documentation]    An expression the validator can't read is refused, with the reason beside
    ...    the buttons; the schema keeps the pattern found.
    [Tags]    p1
    Create Orders
    Open Found Row    0
    Put In Editor Box    ^[0-9
    Press Apply
    Pointer Away
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{EDITOR_PROBLEM}    can't be used
    Copied Schema Should Have    ITEM["id"]["pattern"]    $ID_PATTERN
    Status Should Read    The document fits it

TC-CSC-034 Plain String Takes Out The Pattern And The Format
    [Documentation]    The customer, a uuid, made a plain string: no pattern, no format; the row
    ...    says "string · was uuid", the box is empty, Plain string is dim and Apply too.
    [Tags]    p1
    Create Orders
    Open Found Row    2
    Press Plain
    Pointer Away
    Copied Schema Should Have    ITEM["customer"]    {"type": "string"}
    Found Row Should Read    2    was uuid
    Editor Box Should Hold    ${EMPTY}
    Button Should Be Dim    @{PLAIN_BUTTON}
    Button Should Be Dim    @{APPLY_BUTTON}

TC-CSC-035 After Plain String Apply Waits For An Expression
    [Documentation]    With the box empty, Enter changes nothing (the string stays plain); an
    ...    expression written in it and applied is the pattern -- the one found, written again,
    ...    is what was found, and the format comes back with it.
    [Tags]    p1
    Create Orders
    Open Found Row    2
    Press Plain
    Click At    ${EDITOR_BOX_X}    ${EDITOR_BOX_Y}
    Press Keys    enter
    Sleep    0.5s
    Copied Schema Should Have    ITEM["customer"]    {"type": "string"}
    Put In Editor Box    ${UUID_PATTERN}
    Press Apply
    Copied Schema Should Have    ITEM["customer"]    {"type": "string", "format": "uuid", "pattern": $UUID_PATTERN}
    Pointer Away
    Found Row Should Read    2    format uuid

TC-CSC-036 Restore Puts Back What Was Found
    [Tags]    p1
    Create Orders
    Open Found Row    3
    Press Plain
    Copied Schema Should Have    ITEM["ip"]    {"type": "string"}
    Press Restore
    Copied Schema Should Have    ITEM["ip"]["format"]    "ipv4"
    Editor Box Should Hold    ^(?:${OCTET}\\.){3}${OCTET}$
    Button Should Be Dim    @{PATTERN_RESTORE_BUTTON}

TC-CSC-037 The Keys Of A Map Can Be Any Key
    [Documentation]    The owners' uuid keys opened: the button is Any key, which moves their
    ...    values' schema to additionalProperties; the row says "any key · was uuid".
    [Tags]    p2
    Open Create Page
    Create From Fixture    servers.json
    Open Found Row    4
    Editor Line Should Read    Keys of
    Press Plain
    Pointer Away
    ${schema}=    Copied Schema
    Dictionary Should Not Contain Key    ${schema}[properties][owners]    patternProperties
    Should Be Equal    ${schema}[properties][owners][additionalProperties][properties][name]    ${{ {"type": "string"} }}
    Found Row Should Read    4    any key

TC-CSC-038 Reset Undoes Every Change
    [Documentation]    Two patterns changed, then Reset: the schema is the one made, Reset is dim
    ...    and the status bar says the document fits it again.
    [Tags]    p1
    Create Orders
    ${made}=    Copied Schema
    Open Found Row    0
    Put In Editor Box    ^ORD-.*$
    Press Apply
    Open Found Row    2
    Press Plain
    Status Should Read    Edited
    Click At    ${RESET_X}    ${HEADER_Y}
    Sleep    0.5s
    ${now}=    Copied Schema
    Should Be Equal    ${now}    ${made}
    Pointer Away
    Button Should Be Dim    @{RESET_BUTTON}
    Status Should Read    The document fits it

TC-CSC-039 The Schema Can Be Typed In
    [Documentation]    The schema is in a box: typed in, it is edited; made no JSON, the box says
    ...    so ("Not JSON") and Use in Validate is dim; Reset puts back the one made.
    [Tags]    p1
    Create Orders
    Click At    650    200
    Press Keys    ctrl    end
    Type Text    x
    Sleep    0.5s
    Pointer Away
    Status Should Read    Edited
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{SCHEMA_BOX}    Not JSON
    Button Should Be Dim    @{USE_IN_VALIDATE_BUTTON}
    Click At    ${RESET_X}    ${HEADER_Y}
    Sleep    0.5s
    Pointer Away
    Button Should Be Bright    @{USE_IN_VALIDATE_BUTTON}
    Region Should Not Contain Text    @{SCHEMA_BOX}    Not JSON

TC-CSC-040 Use In Validate Takes The Schema As It Was Changed
    [Documentation]    The id held to two of the three ids found: Use in Validate checks the
    ...    document against that, and the third order's id is the one problem.
    [Tags]    p1
    Create Orders
    Open Found Row    0
    Put In Editor Box    ^ORD-1357-2468[12]$
    Press Apply
    Click At    ${USE_IN_VALIDATE_X}    ${HEADER_Y}
    Sleep    0.8s
    Tab Should Be Selected    validate
    Status Should Read    1 problem
    Result Should Read    /orders/2/id

TC-CSC-041 Copy And Save Take The Schema As It Was Changed
    [Tags]    p2
    Create Orders
    Open Found Row    2
    Press Plain
    ${changed}=    Copied Schema
    Should Be Equal    ${changed}[properties][orders][items][properties][customer]    ${{ {"type": "string"} }}
    ${dir}=    Make Temp Directory
    ${before}=    Portal Request Count
    Portal Will Accept Suggested Name In    ${dir}
    Click At    ${SCHEMA_SAVE_X}    ${HEADER_Y}
    Wait For Dialog After    ${before}
    ${text}=    Wait Until Keyword Succeeds    15x    0.4s    Get File    ${dir}/schema.json
    ${saved}=    Evaluate    json.loads($text)    modules=json
    Should Be Equal    ${saved}    ${changed}

TC-CSC-045 A Click Points The Pattern Out In The Document And The Schema
    [Documentation]    The id's row clicked: the document highlights the first id, the schema the
    ...    id's pattern, and the line of what is open says it is the first place of three.
    [Tags]    p1
    Create Orders
    Open Found Row    0
    Document Should Point Out    ORD-1357-24681
    Schema Should Point Out    pattern
    Place Should Be    1    3

TC-CSC-046 The Arrows Go From Place To Place, Round
    [Documentation]    ⏷ goes to the next id (2 of 3), and from the last round to the first; ⏶
    ...    from the first round to the last.
    [Tags]    p1
    Create Orders
    Open Found Row    0
    Click At    ${NEXT_PLACE_X}    ${PLACE_Y}
    Sleep    0.5s
    Document Should Point Out    ORD-1357-24682
    Place Should Be    2    3
    Click At    ${NEXT_PLACE_X}    ${PLACE_Y}
    Sleep    0.3s
    Click At    ${NEXT_PLACE_X}    ${PLACE_Y}
    Sleep    0.5s
    Document Should Point Out    ORD-1357-24681
    Place Should Be    1    3
    Click At    ${PREVIOUS_PLACE_X}    ${PLACE_Y}
    Sleep    0.5s
    Document Should Point Out    ORD-1357-24683
    Place Should Be    3    3

TC-CSC-047 The Document Box Scrolls To The Place
    [Documentation]    Forty orders: ⏶ from the first id goes round to the fortieth, far down the
    ...    box, which is scrolled to it; the id's place is the fortieth of forty.
    [Tags]    p1
    Open Create Page
    Create From Fixture    forty.json
    Open Found Row    0
    Document Should Point Out    ORD-1357-24681
    Click At    ${PREVIOUS_PLACE_X}    ${PLACE_Y}
    Sleep    0.8s
    Document Should Point Out    ORD-1357-24734
    Place Should Be    40    40

TC-CSC-048 Changing The Document Takes The Highlight Away
    [Documentation]    Typed in, the document is not the one the schema was made of: nothing is
    ...    pointed out in it, and the schema is gone.
    [Tags]    p2
    Create Orders
    Open Found Row    0
    Document Should Point Out    ORD-1357-24681
    Click At    ${CREATE_BOX_X}    ${CREATE_BOX_Y}
    Press Keys    ctrl    end
    Type Text    ${SPACE}
    Sleep    0.5s
    Nothing Should Be Pointed Out    @{CREATE_DOCUMENT}

TC-CSC-049 A Changed Pattern Is Pointed Out Where It Is Now
    [Documentation]    After Apply, the schema highlights the pattern as it now is.
    [Tags]    p2
    Create Orders
    Open Found Row    0
    Put In Editor Box    ^ORD-[A-Z0-9-]+$
    Press Apply
    Pointer Away
    Schema Should Point Out    A-Z

TC-CSC-050 A Click Opens The Enum With A Tick For Each Value
    [Documentation]    The status's enum opened: its line says "Enum of", the values have a tick
    ...    each (open, closed), the document highlights the first status and the schema the
    ...    enum.
    [Tags]    p1
    Create Orders With Enums
    Open Found Row    5
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Show Text    @{ENUM_LINE}    Enum of
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Show Text    @{ENUM_VALUES}    open
    Region Should Show Text    @{ENUM_VALUES}    closed
    Document Should Point Out    open
    Schema Should Point Out    closed
    Place Should Be    1    3    @{ENUM_PLACE}

TC-CSC-051 Unticking A Value Leaves It Out Of The Enum
    [Documentation]    closed unticked: the enum is open alone, and the row says it was edited.
    [Tags]    p1
    Create Orders With Enums
    Open Found Row    5
    Click Enum Value    closed
    Enum Of Orders Should Be    open
    Pointer Away
    List Above Enum Should Read    enum: open
    List Above Enum Should Read    edited
    Status Should Read    Edited

TC-CSC-052 Ticking It Again Puts It Back
    [Documentation]    closed ticked again: the enum is the one found, in its order, and the row
    ...    is as found.
    [Tags]    p2
    Create Orders With Enums
    Open Found Row    5
    Click Enum Value    closed
    Enum Of Orders Should Be    open
    Click Enum Value    closed
    Enum Of Orders Should Be    open    closed
    Pointer Away
    List Above Enum Should Read    enum: open, closed
    Region Should Not Contain Text    @{LIST_ABOVE_ENUM}    edited

TC-CSC-053 Another Value Can Be Put In
    [Documentation]    waiting written in the box and Add: the enum has it after the values
    ...    found, and it has a tick of its own.
    [Tags]    p1
    Create Orders With Enums
    Open Found Row    5
    Put In Editor Box    waiting
    Click At    ${ADD_X}    ${EDITOR_BUTTON_Y}
    Sleep    0.5s
    Enum Of Orders Should Be    open    closed    waiting
    Pointer Away
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Show Text    @{ENUM_VALUES}    waiting

TC-CSC-054 Enter Puts In A Value And Keeps The Box
    [Documentation]    Enter in the box puts the value in and leaves the box in focus, empty, so
    ...    that several are put in one after the other.
    [Tags]    p2
    Create Orders With Enums
    Open Found Row    5
    Put In Editor Box    hold
    Press Keys    enter
    Sleep    0.5s
    Type Text    late
    Press Keys    enter
    Sleep    0.5s
    Enum Of Orders Should Be    open    closed    hold    late

TC-CSC-055 A Value That Is There Already Is Refused
    [Tags]    p2
    Create Orders With Enums
    Open Found Row    5
    Put In Editor Box    open
    Click At    ${ADD_X}    ${EDITOR_BUTTON_Y}
    Sleep    0.5s
    Enum Of Orders Should Be    open    closed
    Pointer Away
    ${problem}=    Read Region Text    630    531    262    18
    Should Not Be Empty    ${problem}    msg=No reason is given beside the buttons

TC-CSC-056 Plain String Takes The Enum Out
    [Tags]    p1
    Create Orders With Enums
    Open Found Row    5
    Click At    ${ENUM_PLAIN_X}    ${EDITOR_BUTTON_Y}
    Sleep    0.5s
    Status Of Orders Should Be    {"type": "string"}
    Pointer Away
    List Above Enum Should Read    was enum

TC-CSC-057 Restore Puts Back The Values Found
    [Tags]    p2
    Create Orders With Enums
    Open Found Row    5
    Click Enum Value    open
    Put In Editor Box    waiting
    Click At    ${ADD_X}    ${EDITOR_BUTTON_Y}
    Sleep    0.5s
    Enum Of Orders Should Be    closed    waiting
    Click At    ${ENUM_RESTORE_X}    ${EDITOR_BUTTON_Y}
    Sleep    0.5s
    Enum Of Orders Should Be    open    closed
    Button Should Be Dim    @{ENUM_RESTORE_BUTTON}

TC-CSC-058 A Value's Tooltip Says How Often It Is In The Document
    [Tags]    p3
    Create Orders With Enums
    Open Found Row    5
    ${x}    ${y}=    Find Text In Region    @{ENUM_VALUES}    open
    Move Mouse To    ${x}    ${ENUM_VALUES_Y}
    Sleep    1.2s
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    450    300    450    260    2 times
