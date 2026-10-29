*** Settings ***
Documentation     The tutorial's Tools tab -- see docs/19_tutorial_pages.md. A fifth tab, after
...               the four query languages: a topic for getting started and one for each tool,
...               each lesson with examples whose samples are the documents the tool's page
...               takes. "▶ Try it" puts the samples in the tool's page and runs it there (the
...               Tools window opens on that page); "Load samples" puts them in without running.
...               What the lesson shows as the result is what the tool makes.
...
...               The cases that press Try it wait for the Tools window and are tagged
...               window-only: with the Tools docked the tool's tab comes to the front instead
...               (TC-DOCK-045, tools_docked_tutorial.robot).
...
...               This is a suite of its own because the Tools window's points are in
...               tools.resource, whose names clash with tutorial.resource's: the few points of
...               the Tools window needed here are below.
Resource          ../../resources/results.resource
Resource          ../../resources/tutorial.resource
Force Tags        tutorial_pages    tutorial_tools
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The Tools tab of the tutorial, after JMESPath.
${TAB_TOOLS_X}         420
# Load samples is right of ▶ Try it, which is found by its fill.
${LOAD_SAMPLES_DX}     79
# The Tools window (900x580; see tools.resource): its status bar, its tabs (the selected one is
# filled with the selection blue), and Create Schema's points that are read here.
${TOOLS_WINDOW}        JsonQuery — Tools
@{TOOLS_STATUS_BAR}    0      558    900    22
&{TOOL_TAB_X}          merge=48    format=140    diff=222    patch=302    validate=399    create=505
@{CREATE_BUTTON_AREA}    8      24     50     20
${SCHEMA_COPY_X}       717
${TOOLS_HEADER_Y}      63

*** Keywords ***
Show Tools Tab
    [Documentation]    The tutorial window open on its Tools tab.
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Click At    ${TAB_TOOLS_X}    ${TAB_Y}
    Sleep    0.6s

Show Tools Lesson
    [Arguments]    ${filter}    ${heading}
    Show Tools Tab
    Show Lesson    ${filter}    ${heading}

Press On Example
    [Documentation]    Presses ▶ Try it (or, with `button=Load samples`, the button beside it) of
    ...    the example whose caption has `caption`, and waits for the Tools window.
    [Arguments]    ${caption}    ${button}=Try it
    ${x}    ${y}=    Example Button Centre    ${caption}
    ${dx}=    Set Variable If    '${button}' == 'Try it'    0    ${LOAD_SAMPLES_DX}
    ${click_x}=    Evaluate    ${x} + ${dx}
    Click At    ${click_x}    ${y}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Move Mouse To    600    11
    Sleep    0.4s

Tools Status Should Read
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    10x    0.5s    Region Should Contain Text    @{TOOLS_STATUS_BAR}    ${text}

Tool Tab Should Be Selected
    [Arguments]    ${tool}
    ${x}=    Evaluate    int(${TOOL_TAB_X}[${tool}]) - 30
    Region Should Contain Color    ${x}    5    60    12    0    92    128    tolerance=10

*** Test Cases ***
TC-TUT-064 The Tools Tab Has A Topic For Each Tool
    [Documentation]    After the four languages, a Tools tab: Getting started, then Merge JSON,
    ...    Format JSON, Diff JSON, Patch JSON, Validate Schema and Create Schema; it opens on
    ...    the first lesson, "The Tools window".
    [Tags]    p1
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    0    6    480    32    Tools
    Click At    ${TAB_TOOLS_X}    ${TAB_Y}
    Sleep    0.6s
    Lesson Heading Should Be    The Tools window
    FOR    ${topic}    IN    Getting started    Merge JSON    Format JSON    Diff JSON    Patch JSON    Validate Schema    Create Schema
        Lesson List Should Show    ${topic}
    END

TC-TUT-065 Try It Makes The Schema Of A Lesson's Sample
    [Documentation]    On a Create Schema lesson, ▶ Try it opens the Tools window on Create Schema
    ...    with the sample in its box and the schema made: what the lesson's result says.
    [Tags]    p1    window-only
    Show Tools Lesson    Patterns in strings    Patterns in strings
    Lesson Should Read    8 properties
    Press On Example    Orders with ids
    Tool Tab Should Be Selected    create
    Tools Status Should Read    8 properties
    Tools Status Should Read    8 patterns
    Tools Status Should Read    The document fits it
    Get Ink Bounds    @{CREATE_BUTTON_AREA}    threshold=150

TC-TUT-066 Load Samples Puts The Sample In Without Running It
    [Documentation]    Load samples fills Create Schema's box (Create is bright) and makes nothing:
    ...    the status bar says nothing of a schema and Copy copies nothing.
    [Tags]    p1    window-only
    Show Tools Lesson    Patterns in strings    Patterns in strings
    Press On Example    Orders with ids    button=Load samples
    Tool Tab Should Be Selected    create
    Get Ink Bounds    @{CREATE_BUTTON_AREA}    threshold=150
    Sleep    0.5s
    Region Should Not Contain Text    @{TOOLS_STATUS_BAR}    Created in
    Set Clipboard    nothing was copied
    Click At    ${SCHEMA_COPY_X}    ${TOOLS_HEADER_Y}
    Sleep    0.5s
    ${copied}=    Get Clipboard
    Should Be Equal    ${copied}    nothing was copied

TC-TUT-067 Try It On A Validate Lesson Lists The Problems
    [Documentation]    "A person with six things wrong": Validate Schema checks the sample against
    ...    its schema and finds six problems.
    [Tags]    p1    window-only
    Show Tools Lesson    What does not fit    What does not fit
    Press On Example    six things wrong
    Tool Tab Should Be Selected    validate
    Tools Status Should Read    6 problems

TC-TUT-068 Try It On A Merge Lesson Merges Its Files
    [Documentation]    Merge's samples are files: Try it writes them, lists them on the page and
    ...    merges them -- two months of orders, one list of three.
    [Tags]    p2    window-only
    Show Tools Lesson    Append files    Append files
    Press On Example    Two months
    Tool Tab Should Be Selected    merge
    Tools Status Should Read    Merged 2 files
    Tools Status Should Read    3 items

TC-TUT-069 Try It On A Format Lesson Formats The Sample
    [Tags]    p2    window-only
    Show Tools Lesson    Pretty-print    Pretty-print
    Press On Example    minified document
    Tool Tab Should Be Selected    format
    Tools Status Should Read    Formatted

TC-TUT-070 Try It On A Diff Lesson Compares The Two Samples
    [Tags]    p2    window-only
    Show Tools Lesson    Two versions    Two versions
    Press On Example    Version 1.4
    Tool Tab Should Be Selected    diff
    Tools Status Should Read    3 changed

TC-TUT-071 Try It On A Patch Lesson Patches The Sample
    [Tags]    p2    window-only
    Show Tools Lesson    Operations (RFC    Operations
    Press On Example    Release a new
    Tool Tab Should Be Selected    patch
    Tools Status Should Read    7 operations
    Tools Status Should Read    Patched

TC-TUT-072 A Second Try It Goes To The Window That Is Open
    [Documentation]    With the Tools window open on one tool, Try it on another tool's lesson
    ...    shows that tool's page in the same window.
    [Tags]    p2    window-only
    Show Tools Lesson    What does not fit    What does not fit
    Press On Example    six things wrong
    Tool Tab Should Be Selected    validate
    Show Tools Lesson    Patterns in strings    Patterns in strings
    Press On Example    Orders with ids
    Tool Tab Should Be Selected    create
    ${count}=    Count Windows    ${TOOLS_WINDOW}
    Should Be Equal As Integers    ${count}    1

TC-TUT-073 A Filter Finds The Lessons Of The Tools
    [Documentation]    On the Tools tab the filter looks in its lessons: "bounds" leaves Create
    ...    Schema's "Enums and bounds".
    [Tags]    p2
    Show Tools Tab
    Filter Lessons    bounds
    Lesson List Should Show    Enums and bounds
    Lesson List Should Not Show    Merge JSON

TC-TUT-074 The Tools Tab Keeps Its Lesson
    [Documentation]    A lesson picked on the Tools tab is still the one shown after a visit to the
    ...    jq tab.
    [Tags]    p3
    Show Tools Lesson    Lists, maps    Lists, maps
    Filter Lessons    ${EMPTY}
    Click At    ${TAB_JQ_X}    ${TAB_Y}
    Sleep    0.6s
    Click At    ${TAB_TOOLS_X}    ${TAB_Y}
    Sleep    0.6s
    Lesson Heading Should Be    Lists, maps
