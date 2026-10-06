*** Settings ***
Documentation     Tools window, the Format JSON page -- see
...               docs/13_tools_window.md. Input on the left, the formatted
...               document on the right; Indent (2 spaces, 4 spaces, Tab,
...               Minified), Sort keys and ASCII only in the command row.
...
...               The formatted text is small monospace text, which OCR reads only
...               in part, so wherever the exact text matters the test presses
...               the result's Copy button and compares the clipboard -- the
...               whole text, character for character, tabs and all. OCR is used
...               for the short things (the status bar, an error's words).
Resource          ../../resources/tools.resource
Library           Collections
Force Tags        tools    format
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${DOC}               {"b":1,"a":[1,2,{"c":null}],"d":{}}
# The Format button: dim (label ~112 grey) until there is something to format,
# bright (~240) after.
@{FORMAT_BUTTON}     8      24     50     20

*** Keywords ***
Format And Copy Should Give
    [Documentation]    Presses Format, waits for the status bar to compare sizes
    ...    ("… (was …)") and checks that Copy gives exactly `expected`.
    [Arguments]    ${expected}
    Press Main Button
    Status Should Read    was
    Copy Should Give    ${FORMAT_COPY_X}    ${HEADER_Y}    ${expected}

Pretty
    [Documentation]    The document as Python's json would print it with this
    ...    indent -- the layout the page's printer is meant to match.
    [Arguments]    ${text}    ${indent}=2    ${sort_keys}=${False}    ${ascii}=${False}
    ${out}=    Evaluate    json.dumps(json.loads($text), indent=(int($indent) if str($indent).isdigit() else $indent), sort_keys=$sort_keys, ensure_ascii=$ascii)    modules=json
    RETURN    ${out}

Format Button Should Be Disabled
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    @{FORMAT_BUTTON}    threshold=150

Format Button Should Be Enabled
    Get Ink Bounds    @{FORMAT_BUTTON}    threshold=150

*** Test Cases ***
TC-TWIN-006 Format JSON Pretty-Prints Pasted Text
    [Documentation]    Minified JSON pasted into the Input box comes back with
    ...    a line to each member and two spaces to a level.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${DOC}
    Press Main Button
    # The array's elements are one to a line, and the object member under them
    # is on its own line, indented. (Not asserting the commas: Tesseract reads
    # the second one as a semicolon, which the exact-text cases below don't care
    # about.)
    Result Should Read    1,\n2
    Result Should Read    null
    Result Should Read    "d": {}
    # The status bar says how big it came out against what went in.
    Status Should Read    was

TC-FMT-001 The Layout Is Two Spaces To A Level By Default
    [Documentation]    Exactly what Copy gives for the default indent: the same
    ...    as a standard JSON printer's two-space layout, one array element to a
    ...    line, an empty object as {}.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${DOC}
    ${expected}=    Pretty    ${DOC}
    Format And Copy Should Give    ${expected}

TC-FMT-002 Four Spaces To A Level
    [Documentation]    Picking "4 spaces" in the Indent dropdown formats with
    ...    four.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${DOC}
    Pick Indent    4 spaces
    ${expected}=    Pretty    ${DOC}    indent=4
    Format And Copy Should Give    ${expected}

TC-FMT-003 A Tab To A Level
    [Documentation]    Picking "Tab" indents with one tab character a level.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${DOC}
    Pick Indent    Tab
    ${tab}=    Evaluate    chr(9)
    ${expected}=    Pretty    ${DOC}    indent=${tab}
    Format And Copy Should Give    ${expected}

TC-FMT-004 Minified Has No White Space
    [Documentation]    "Minified" writes the whole document on one line with no
    ...    space after a colon or comma.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"b": 1, "a": [1, 2, {"c": null}], "d": {}}
    Pick Indent    Minified
    Format And Copy Should Give    ${DOC}

TC-FMT-005 Sort Keys Puts Every Object's Keys In Order
    [Documentation]    With "Sort keys" on, the keys of every object are in
    ...    order at every depth (the elements of an array keep theirs).
    [Tags]    p1
    ${doc}=    Set Variable    {"zebra":1,"apple":{"y":1,"x":2},"list":[{"b":1,"a":2},{"d":3,"c":4}]}
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${doc}
    Click At    ${SORT_KEYS_X}    ${COMMAND_Y}
    Sleep    0.3s
    ${expected}=    Pretty    ${doc}    sort_keys=${True}
    Format And Copy Should Give    ${expected}

TC-FMT-006 Without Sort Keys The Keys Keep Their Order
    [Documentation]    The keys come out in the order they were read in, which
    ...    is not alphabetical here: "zebra" before "apple".
    [Tags]    p2
    ${doc}=    Set Variable    {"zebra":1,"apple":2}
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${doc}
    ${expected}=    Pretty    ${doc}
    Format And Copy Should Give    ${expected}
    Should Be True    $expected.index('zebra') < $expected.index('apple')

TC-FMT-007 ASCII Only Escapes What Is Not ASCII
    [Documentation]    With "ASCII only" on, characters outside ASCII are written
    ...    as \\uXXXX escapes (é as \\u00e9, the snowman as \\u2603), and the
    ...    escaped text reads back as the same document.
    [Tags]    p1
    ${doc}=    Set Variable    {"s":"é☃","t":"plain"}
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${doc}
    Click At    ${ASCII_ONLY_X}    ${COMMAND_Y}
    Sleep    0.3s
    ${expected}=    Pretty    ${doc}    ascii=${True}
    Format And Copy Should Give    ${expected}
    Should Contain    ${expected}    \\u00e9

TC-FMT-008 Characters Outside ASCII Are Kept By Default
    [Documentation]    Without "ASCII only" the same text comes back as it was
    ...    written.
    [Tags]    p2
    ${doc}=    Set Variable    {"s":"é☃"}
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${doc}
    ${expected}=    Pretty    ${doc}
    Format And Copy Should Give    ${expected}
    Should Contain    ${expected}    é☃

TC-FMT-009 Numbers Come Back As They Were Written
    [Documentation]    A number is printed with the digits it was read with:
    ...    1.50 keeps its trailing zero and an integer too big for a double
    ...    keeps every digit.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"a":1.50,"b":12345678901234567890123,"c":-0.0}
    ${nl}=    Evaluate    chr(10)
    ${expected}=    Catenate    SEPARATOR=${nl}
    ...    {
    ...    \ \ "a": 1.50,
    ...    \ \ "b": 12345678901234567890123,
    ...    \ \ "c": -0.0
    ...    }
    Format And Copy Should Give    ${expected}

TC-FMT-010 Empty Containers Stay On One Line
    [Documentation]    [] and {} are written as such, not split over lines.
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"a":[],"b":{},"c":[[]]}
    ${expected}=    Pretty    {"a":[],"b":{},"c":[[]]}
    Format And Copy Should Give    ${expected}

TC-FMT-011 A Document That Is Only A Scalar Formats Too
    [Documentation]    The root need not be an object or an array.
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    "just a string"
    Format And Copy Should Give    "just a string"

TC-FMT-012 Text That Is Not JSON Is Reported With Where
    [Documentation]    An unfinished document gives a red error in the result
    ...    area naming the box ("Input") and the line and column, and Copy has
    ...    nothing to copy.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"a":
    Press Main Button
    Result Should Read    Input
    Result Should Read    parsing JSON
    Result Should Read    line 1
    Copy Should Do Nothing    ${FORMAT_COPY_X}    ${HEADER_Y}

TC-FMT-013 Several Values In A Row Are Read As One Array
    [Documentation]    White-space-separated values (newline-delimited JSON, as the
    ...    main window reads it) come out as one array of them, one element
    ...    to a line.
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"a":1} {"b":2}
    ${expected}=    Pretty    [{"a":1},{"b":2}]
    Format And Copy Should Give    ${expected}

TC-FMT-023 Text After The Document Is An Error
    [Documentation]    Something that is not a value after the document is an
    ...    error naming the box and where it is, not silently dropped.
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"a":1} oops
    Press Main Button
    Result Should Read    Input
    Result Should Read    parsing JSON
    Copy Should Do Nothing    ${FORMAT_COPY_X}    ${HEADER_Y}

TC-FMT-014 Format Waits For Something To Format
    [Documentation]    The Format button is dim while the box is empty, or holds
    ...    only white space, and bright once there is text.
    [Tags]    p1
    Open Tool    format
    Format Button Should Be Disabled
    ${spaces}=    Evaluate    ' ' * 3
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${spaces}
    Format Button Should Be Disabled
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${DOC}
    Format Button Should Be Enabled

TC-FMT-015 Ctrl+Enter Formats
    [Documentation]    The shortcut runs Format from the box, as it runs a query
    ...    in the main window.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"name":"platypus"}
    Press Keys    ctrl    enter
    Status Should Read    was
    Result Should Read    platypus

TC-FMT-016 Clear Empties The Box And Drops The Result
    [Documentation]    Clear in the Input header empties the box, and the old
    ...    result goes with it: nothing of it is left on either side, and
    ...    Format is dim again.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"name":"platypus"}
    Press Main Button
    Result Should Read    platypus
    Click At    ${CLEAR_X}    ${HEADER_Y}
    Sleep    0.5s
    Result Should Not Read    platypus
    Region Should Not Contain Text    @{INPUT_BOX}    platypus
    Format Button Should Be Disabled

TC-FMT-017 Editing The Input Drops The Result
    [Documentation]    A result that no longer matches its input is not left on
    ...    show: typing in the box clears it and the status bar's summary.
    [Tags]    p1
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"name":"platypus"}
    Press Main Button
    Result Should Read    platypus
    Click At    ${FIRST_BOX_X}    ${INPUT_BOX_Y}
    Press Keys    ctrl    end
    Type Text    ${SPACE}
    Sleep    0.5s
    Result Should Not Read    platypus
    Status Should Not Read    was

TC-FMT-018 Changing An Option Drops The Result
    [Documentation]    Picking another indent clears the old answer: it was
    ...    printed another way, so it is run again when asked.
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    {"name":"platypus"}
    Press Main Button
    Result Should Read    platypus
    Pick Indent    4 spaces
    Result Should Not Read    platypus
    Status Should Not Read    was

TC-FMT-019 Copy Says So In The Status Bar
    [Documentation]    After Copy the status bar says "Copied to the clipboard".
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${DOC}
    Press Main Button
    Status Should Read    was
    Click At    ${FORMAT_COPY_X}    ${HEADER_Y}
    Status Should Read    Copied

TC-FMT-020 The Status Bar Compares The Sizes
    [Documentation]    "79 B (was 35 B)": the formatted size against the
    ...    input's, and how long it took.
    [Tags]    p2
    Open Tool    format
    Paste Into Box    ${FIRST_BOX_X}    ${INPUT_BOX_Y}    ${DOC}
    Press Main Button
    Status Should Read    (was
    Status Should Read    35
    Status Should Read    Formatted in

TC-FMT-021 The Open Document Can Be Formatted
    [Documentation]    With a document open in the main window, "Open document"
    ...    puts it in the Input box (as a note, not as text) and Format prints
    ...    it; the boxes of the two windows are one document, not copies.
    [Tags]    p1
    Load Fixture Via Paste    {"members":[{"name":"Ann"}],"team":"platypus"}
    Open Tool    format
    Click At    ${OPEN_DOCUMENT_X}    ${HEADER_Y}
    Sleep    0.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{INPUT_BOX}    open document
    Press Main Button
    Result Should Read    platypus
    Result Should Read    Ann

TC-FMT-022 Open Document Is Dim Without A Document
    [Documentation]    Nothing is open in the main window, so pressing "Open
    ...    document" does nothing: the box stays empty and Format stays dim.
    [Tags]    p2
    Open Tool    format
    Click At    ${OPEN_DOCUMENT_X}    ${HEADER_Y}
    Sleep    0.5s
    Format Button Should Be Disabled
    Region Should Not Contain Text    @{INPUT_BOX}    open document

TC-FMT-080 A Document Kept On Disk Is Formatted As It Is Saved
    [Documentation]    A file of 256 MiB or more is not text in memory: Format shows the
    ...    start of it, says that it is written from its file when saved, and Copy is
    ...    off. (Save… writes all of it from the file, a piece at a time.)
    [Tags]    p2
    ${file}=    Make Heavy File    270    {"members": [{"name": "Ann"}], "team": "platypus"}
    Load Via Url    ${file}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    platypus    timeout=30
    Open Tool    format
    Click At    ${OPEN_DOCUMENT_X}    ${HEADER_Y}
    Sleep    0.5s
    Press Main Button
    Result Should Read    platypus
    Result Should Read    Ann
    Status Should Read    written from its file
    Click At    ${FORMAT_COPY_X}    ${HEADER_Y}
    Status Should Not Read    Copied
