*** Settings ***
Documentation     The tutorial's tabs of help -- see docs/19_tutorial_pages.md, "The help tabs". After Tools come
...               AI assistants (in the builds with the MCP server) and General, last: lessons of words, commands
...               with a Copy button, links and pictures, with nothing to run in the tutorial itself. So the cases
...               do what the help says: a command copied with its Copy button is run as the app's command line, a
...               link is followed (to the stand-in for the browser), a key it names is pressed, and what it says
...               of the server -- how many tools, its address, how many tokens -- is checked against the server
...               and its panel.
...
...               The cases that run a tool's command wait for the Tools window and are tagged window-only; those
...               that open the MCP panel use its points of the window without the Tools' tabs (undocked-only).
Resource          ../../resources/mcp.resource
Resource          ../../resources/tutorial.resource
Library           Collections
Library           OperatingSystem
Library           String
Force Tags        tutorial_pages    tutorial_help
Suite Setup       Make The Files
Suite Teardown    Stop Test Display
Test Teardown     Close Jsonquery App

*** Variables ***
${DIR}                    ${TEMPDIR}/jq-help-commands
# The tabs after Tools, at x 420; without the MCP server General is where AI assistants is.
${TAB_AI_X}               515
${TAB_GENERAL_X}          618
${TAB_GENERAL_NOMCP_X}    500
@{TAB_ROW}                0      6      1040    32
# The line under the tabs, and the tutorial's status line at its foot.
@{TAGLINE}                0      40     1040    18
@{TUTORIAL_STATUS}        0      700    1040    20
# The icon at the start of the status line on the AI assistants tab.
@{STATUS_ICON}            4      703    22     16
# The Copy buttons, at the right of each command's box.
@{COPY_COLUMN}            960    130    80     570
# What a link is drawn in (egui's dark hyperlink colour).
@{LINK_COLOR}             90     170    255
# The Tools window (900x580; see tools.resource, which cannot be taken in beside tutorial.resource): its
# status bar and its tabs, the selected one filled with the selection blue.
${TOOLS_WINDOW}           JsonQuery — Tools
@{TOOLS_STATUS_BAR}       0      558    900    22
&{TOOL_TAB_X}             merge=48    format=140    diff=222    patch=302    validate=399    create=505
${THE_DOCS}               https://github.com/nujufas/jsonquery_gui/tree/master/docs
${COMMAND_LINE_DOC}       https://github.com/nujufas/jsonquery_gui/blob/master/docs/command-line.md
${MCP_DOC}                https://github.com/nujufas/jsonquery_gui/blob/master/docs/mcp.md

*** Test Cases ***
TC-TUT-075 The Help Tabs Come After Tools, General Last
    [Documentation]    After the four languages and Tools: AI assistants, then General. Each opens on its first
    ...    lesson, with its line under the tabs and its topics in the list.
    [Tags]    p1
    Launch Jsonquery App
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    ${tools}=    Find Text In Region    @{TAB_ROW}    Tools
    ${ai}=    Find Text In Region    @{TAB_ROW}    assistants
    ${general}=    Find Text In Region    @{TAB_ROW}    General
    Should Be True    ${tools}[0] < ${ai}[0] < ${general}[0]
    ...    msg=Tools, AI assistants, General: at ${tools}, ${ai}, ${general}
    Click At    ${TAB_AI_X}    ${TAB_Y}
    Sleep    0.6s
    Lesson Heading Should Be    What MCP is
    Wait Until Region Contains Text    @{TAGLINE}    work with what JsonQuery has open    timeout=3
    FOR    ${topic}    IN    Getting started    Add it to an assistant    Using it
        Lesson List Should Show    ${topic}
    END
    Click At    ${TAB_GENERAL_X}    ${TAB_Y}
    Sleep    0.6s
    Lesson Heading Should Be    Open a document as the app starts
    Wait Until Region Contains Text    @{TAGLINE}    The command line, the keys, big files    timeout=3
    Lesson List Should Show    Command line
    Lesson List Should Show    Working with the app

TC-TUT-076 Each Help Tab's Status Line Says What Is There To Do
    [Documentation]    On AI assistants: the server's icon (not words for it), then that it opens the server's
    ...    panel from the main window's status bar. On General: what Copy does.
    [Tags]    p2
    Launch Jsonquery App
    Show Help Tab    AI assistants
    Wait Until Region Contains Text    @{TUTORIAL_STATUS}    status bar opens the server    timeout=3
    Get Ink Bounds    @{STATUS_ICON}    threshold=60
    Region Should Not Contain Text    @{TUTORIAL_STATUS}    plug
    Click At    ${TAB_GENERAL_X}    ${TAB_Y}
    Sleep    0.6s
    Wait Until Region Contains Text    @{TUTORIAL_STATUS}    Copy puts a command on the clipboard    timeout=3

TC-TUT-077 Copy Puts The Command On The Clipboard As It Is Shown, And Says So
    [Tags]    p1
    Launch Jsonquery App
    Show Help Tab    General
    ${file}=    Copy Command    1
    Should Be Equal    ${file}    jsonquery_gui data.json
    Wait Until Region Contains Text    @{TUTORIAL_STATUS}    Copied    timeout=3
    ${pipe}=    Copy Command    3
    Should Be Equal    ${pipe}    curl -s https://api.github.com/repos/jqlang/jq | jsonquery_gui -

TC-TUT-078 The Commands That Open A Document Open It
    [Documentation]    "A file" opens data.json from the folder the app is started in; the app's part of "What
    ...    another program prints" opens what is piped into it (here the file's text, for what curl prints).
    [Tags]    p1
    Launch Jsonquery App
    Show Help Tab    General
    @{commands}=    Copied Commands    3
    Close Jsonquery App
    Run Copied Command    ${commands}[0]
    ${state}=    State When Loaded
    Should Be Equal    ${state}[document][source]    file
    Should Be Equal    ${state}[document][from]    ${DIR}/data.json
    Close Jsonquery App
    ${text}=    Get File    ${DIR}/data.json
    Run Copied Command    ${commands}[2]    stdin_text=${text}
    ${state}=    State When Loaded
    Should Be Equal    ${state}[document][source]    standard input
    ${results}=    Mcp Tool Should Succeed    run_query    {"query": ".items | length"}
    Should Be Equal    ${results}[items]    ${{ [3] }}

TC-TUT-079 The Commands That Run A Query Run It As The Lesson Says
    [Documentation]    The four commands of "Run a query as it opens", each run in the folder with data.json and
    ...    names.jq: the query is in the box in its language, and it has run.
    [Tags]    p1
    Launch Jsonquery App
    Show Help Lesson    General    --pointer    Run a query as it opens
    @{commands}=    Copied Commands    4
    Close Jsonquery App
    # A jq query: its language is told from it.
    Run Copied Command    ${commands}[0]
    ${state}=    State With Results
    Should Be Equal    ${state}[query][text]    .items[] | .name
    Should Be Equal    ${state}[query][language]    jq
    Should Not Be True    ${state}[query][language_chosen]
    Results Should Be    ${{ ["Ada", "Grace", "Linus"] }}
    Close Jsonquery App
    # A JSONPath query, its language named.
    Run Copied Command    ${commands}[1]
    ${state}=    State With Results
    Should Be Equal    ${state}[query][text]    $.items[*].name
    Should Be Equal    ${state}[query][language]    jsonpath
    Should Be True    ${state}[query][language_chosen]
    Results Should Be    ${{ ["Ada", "Grace", "Linus"] }}
    Close Jsonquery App
    # The value at a JSON Pointer.
    Run Copied Command    ${commands}[2]
    ${state}=    State With Results
    Should Be Equal    ${state}[query][text]    /items/0
    Should Be Equal    ${state}[query][language]    pointer
    Results Should Be    ${{ [{"name": "Ada"}] }}
    Close Jsonquery App
    # A query kept in a file.
    Run Copied Command    ${commands}[3]
    ${state}=    State With Results
    Should Be Equal    ${state}[query][text]    .items[].name
    Results Should Be    ${{ ["Ada", "Grace", "Linus"] }}

TC-TUT-080 The Commands That Open A Tool Fill Its Page And Run It
    [Documentation]    The six commands of "Open a tool", each run in the folder with its files: the Tools window
    ...    opens on that tool, which has run. Then the command git's difftool is given (-x), run as git runs it,
    ...    with the two versions of the file after it: Diff compares them. (git itself is not run: the app is
    ...    started with nothing on its PATH but the stand-in for the browser.)
    [Tags]    p2    window-only
    Launch Jsonquery App
    Show Help Lesson    General    difftool    Open a tool
    @{commands}=    Copied Commands    7
    Close Jsonquery App
    Run Tool Command    ${commands}[0]    diff    changed
    Run Tool Command    ${commands}[1]    validate    2 problems
    Run Tool Command    ${commands}[2]    patch    Patched
    Run Tool Command    ${commands}[3]    merge    Merged 3 files
    Run Tool Command    ${commands}[4]    format    Formatted
    Run Tool Command    ${commands}[5]    create    Created
    ${git}=    Shell Words    ${commands}[6]
    Should Be Equal    ${git}[:3]    ${{ ["git", "difftool", "-y"] }}
    ${tool}=    Evaluate    $git[$git.index('-x') + 1]
    Run Tool Command    ${tool} old.json new.json    diff    changed

TC-TUT-081 The Help And Version Commands Print And Open No Window
    [Tags]    p2
    Launch Jsonquery App
    Show Help Lesson    General    the version    Help, the version, and mistakes
    @{commands}=    Copied Commands    2
    Close Jsonquery App
    ${words}=    App Words Of    ${commands}[0]
    ${help}=    Run Jsonquery Command Line    @{words}
    Should Be Equal As Integers    ${help}[rc]    0
    Should Contain    ${help}[stdout]    Usage:
    ${words}=    App Words Of    ${commands}[1]
    ${version}=    Run Jsonquery Command Line    @{words}
    Should Be Equal As Integers    ${version}[rc]    0
    Should Match Regexp    ${version}[stdout]    ^jsonquery_gui \\d+\\.\\d+\\.\\d+\\n$

TC-TUT-082 The Keys Lesson's F1 Opens The Tutorial
    [Tags]    p3
    Launch Jsonquery App
    Switch To Main Window
    Press Key    f1
    Wait Until Window Exists    ${TUTORIAL_WINDOW}    timeout=8
    Switch To Window    ${TUTORIAL_WINDOW}
    Click At    ${TAB_GENERAL_X}    ${TAB_Y}
    Sleep    0.6s
    Show Lesson    the most clicks    Keys
    Lesson Should Read    opens this window

TC-TUT-083 What MCP Is Says As Many Tools As The Server Has, And Names Each
    [Documentation]    The number in the lesson is the number of tools the server lists, and the name of each is
    ...    read in the lesson. The names are on chips, which OCR reads once their grey is made black; a name is
    ...    read when a word (or two, for an underscore read as a space) is nearly it.
    [Tags]    p1    undocked-only
    Launch Mcp App Serving    access=read
    ${names}=    Mcp Tool Names
    ${count}=    Get Length    ${names}
    Show Help Tab    AI assistants
    Lesson Heading Should Be    What MCP is
    Lesson Should Read    with ${count} tools
    ${text}=    Read Region Text    @{LESSON_BODY}    flatten_tints=${True}
    ${missed}=    Words Not Read    ${names}    ${text}
    Should Be Empty    ${missed}    msg=not in the lesson: ${missed}; it reads: ${text}

TC-TUT-084 Start The Server Shows The Icon And The Panel's Own Address
    [Documentation]    The lesson begins with the status bar's icon, not words for it, and gives the address of
    ...    the server as the panel of a first start has it (no mcp.json: 7457, and nothing started).
    [Tags]    p2    undocked-only
    Launch Jsonquery App
    Open Mcp Panel
    Panel Line Should Say    127.0.0.1:7457/mcp    region=${MCP_ADDRESS_ROW}
    Close Mcp Panel
    Show Help Lesson    AI assistants    7457    Start the server
    Lesson Should Read    http://127.0.0.1:7457/mcp
    ${cx}    ${cy}=    Find Text In Region    @{LESSON_BODY}    status bar opens
    ${top}=    Evaluate    int(${cy}) - 8
    Get Ink Bounds    278    ${top}    20    16    threshold=60
    Region Should Not Contain Text    @{LESSON_BODY}    plug

TC-TUT-085 The QuickAI Lesson Names The Model And The Context, And Links To QuickAI
    [Tags]    p1
    Launch Jsonquery App
    Show Help Lesson    AI assistants    Qwen    Quick
    ${text}=    Lesson Text Above Its Pictures
    # (OCR reads the italic 9B as 98 at times.)
    Should Match Regexp    ${text}    Qwen3\\.5-9[B8]-Q4.?K.?M
    Should Contain    ${text}    32K tokens or more
    ${links}=    Find Color Blocks    @{LESSON_BODY}    @{LINK_COLOR}    tolerance=12
    Click At    ${links}[0][0]    ${links}[0][1]
    # (The opener writes a bare host's address with its slash.)
    Opened Addresses Should Be    https://quickai.everybodyai.dev/

TC-TUT-086 The QuickAI Lesson's Numbers Are The Server's And The Panel's
    [Documentation]    The lesson says the tools take about 7K tokens before the first question, an answer up to
    ...    6K more with Answers at 24 KB, and to choose 8 KB with a smaller context. At the panel's four bytes
    ...    a token: what the server gives before a question (its instructions and the list of its tools)
    ...    rounds to 7K, and the panel says 6,000 tokens at 24 KB and offers 8 KB (2,000).
    [Tags]    p3    undocked-only
    Launch Mcp App Serving    access=read
    ${chars}=    Mcp Characters Before A Question
    ${thousands}=    Evaluate    round(${chars} / 4 / 1000)
    Should Be Equal As Integers    ${thousands}    7
    ...    msg=the lesson says about 7K tokens; the server gives ${chars} characters before a question
    Open Mcp Panel
    Answer Size Should Be Chosen    24
    Tokens Should Say    6
    Choose Answer Size    8
    Tokens Should Say    2
    Close Mcp Panel
    Show Help Lesson    AI assistants    Qwen    Quick
    ${text}=    Lesson Text Above Its Pictures
    Should Contain    ${text}    about 7K tokens
    Should Contain    ${text}    6K more
    Should Contain    ${text}    of 8 KB

TC-TUT-087 The Assistants' Lessons Show Their Pictures
    [Documentation]    Claude Code's lesson has a picture, VS Code's and QuickAI's two each, each over its caption.
    [Tags]    p2
    Launch Jsonquery App
    Show Help Lesson    AI assistants    in a terminal    Claude Code
    Picture Should Be Above Caption    Claude Code in a terminal
    Show Lesson    Copilot    VS Code
    Picture Should Be Above Caption    with the entry that JsonQuery
    Picture Should Be Above Caption    Claude Code in VS Code
    Show Lesson    Qwen    Quick
    Picture Should Be Above Caption    MCP servers: the entry
    Picture Should Be Above Caption    then, with Edit allowed

TC-TUT-088 The Read More Links Open The Docs
    [Documentation]    Each link of "Read more" hands its page of the app's repository to the browser.
    [Tags]    p2
    Launch Jsonquery App
    Show Help Lesson    General    command-line.md    Read more
    ${links}=    Find Color Blocks    @{LESSON_BODY}    @{LINK_COLOR}    tolerance=12
    Length Should Be    ${links}    3
    FOR    ${link}    IN    @{links}
        Click At    ${link}[0]    ${link}[1]
        Sleep    0.3s
    END
    Opened Addresses Should Be    ${THE_DOCS}    ${COMMAND_LINE_DOC}    ${MCP_DOC}

TC-TUT-089 What To Ask: Copy Copies The Question As It Is
    [Tags]    p3
    Launch Jsonquery App
    Show Help Lesson    AI assistants    your own words    What to ask
    ${question}=    Copy Command    1
    Should Be Equal    ${question}    What is open in JsonQuery, and what does it hold?

TC-TUT-090 The Filter Finds A Help Lesson On Either Tab
    [Tags]    p2
    Launch Jsonquery App
    Show Help Tab    General
    Filter Lessons    difftool
    Lesson List Should Show    Open a tool
    Lesson List Should Not Show    Keys
    Filter Lessons    ${EMPTY}
    Click At    ${TAB_AI_X}    ${TAB_Y}
    Sleep    0.6s
    Filter Lessons    Qwen
    Lesson List Should Show    Quick
    Lesson List Should Not Show    Claude Code

TC-TUT-091 Next And Previous Walk The Help Lessons Across Their Topics
    [Documentation]    From the last lesson of General's first topic, Next is the first of the next topic; Previous
    ...    goes back. (A help lesson is short: the pager is under it, where its titles are read.)
    [Tags]    p2
    Launch Jsonquery App
    Show Help Lesson    General    the version    Help, the version, and mistakes
    Click Text In Region    @{LESSON_BODY}    Keys
    Sleep    0.8s
    Lesson Heading Should Be    Keys
    Wait Until Region Contains Text    @{LESSON_TOPIC}    Working with the app    timeout=3
    Click Text In Region    @{LESSON_BODY}    mistakes
    Sleep    0.8s
    Lesson Heading Should Be    Help, the version, and mistakes

TC-TUT-092 Each Help Tab Keeps Its Lesson
    [Tags]    p3
    Launch Jsonquery App
    Show Help Lesson    General    the most clicks    Keys
    Filter Lessons    ${EMPTY}
    Click At    ${TAB_AI_X}    ${TAB_Y}
    Sleep    0.6s
    Lesson Heading Should Be    What MCP is
    Click At    ${TAB_GENERAL_X}    ${TAB_Y}
    Sleep    0.6s
    Lesson Heading Should Be    Keys

TC-TUT-093 The Build Without The Server Has No AI Assistants Tab
    [Documentation]    General follows Tools, and its Read more has no link to the MCP server's page.
    [Tags]    p1
    Launch Jsonquery App    build=nomcp
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    ${tools}=    Find Text In Region    @{TAB_ROW}    Tools
    ${general}=    Find Text In Region    @{TAB_ROW}    General
    Should Be True    ${tools}[0] < ${general}[0]
    Region Should Not Contain Text    @{TAB_ROW}    assistants
    Click At    ${TAB_GENERAL_NOMCP_X}    ${TAB_Y}
    Sleep    0.6s
    Lesson Heading Should Be    Open a document as the app starts
    Show Lesson    command-line.md    Read more
    ${links}=    Find Color Blocks    @{LESSON_BODY}    @{LINK_COLOR}    tolerance=12
    Length Should Be    ${links}    2
    Region Should Not Contain Text    @{LESSON_BODY}    MCP

TC-TUT-094 Every Tab Is In The Tutorial At Its Narrowest
    [Documentation]    At the least size the window may have (720x460) the tabs are all there, General too.
    [Tags]    p3
    Launch Jsonquery App
    Open Tutorial
    Resize Window    ${TUTORIAL_WINDOW}    720    460
    Switch To Window    ${TUTORIAL_WINDOW}
    Sleep    0.6s
    # (OCR reads it "Generel" at times.)
    ${general}=    Find Text In Region    0    0    720    80    Gener
    Click At    ${general}[0]    ${general}[1]
    Sleep    0.6s
    Lesson Heading Should Be    Open a document as the app starts

*** Keywords ***
Make The Files
    [Documentation]    The files the help's commands name, in a folder of their own that the app is started in.
    Start Test Display
    Remove Directory    ${DIR}    recursive=${True}
    Create Directory    ${DIR}
    Create File    ${DIR}/data.json    {"items": [{"name": "Ada"}, {"name": "Grace"}, {"name": "Linus"}]}
    Create File    ${DIR}/names.jq    .items[].name
    Create File    ${DIR}/old.json    {"a": 1, "b": [1, 2]}
    Create File    ${DIR}/new.json    {"a": 2, "b": [1, 2, 3]}
    Create File    ${DIR}/order.json    {"id": "A1", "total": -5}
    Create File    ${DIR}/order.schema.json
    ...    {"type": "object", "required": ["id", "total", "customer"], "properties": {"total": {"minimum": 0}}}
    Create File    ${DIR}/doc.json    {"a": 1}
    Create File    ${DIR}/fix.json    [{"op": "add", "path": "/b", "value": 2}]
    Create File    ${DIR}/a.json    [1]
    Create File    ${DIR}/b.json    [2]
    Create File    ${DIR}/c.json    [3]

Show Help Tab
    [Documentation]    The tutorial open on the help tab `tab` (General, or AI assistants).
    [Arguments]    ${tab}
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    ${x}=    Set Variable If    '${tab}' == 'General'    ${TAB_GENERAL_X}    ${TAB_AI_X}
    Click At    ${x}    ${TAB_Y}
    Sleep    0.6s

Show Help Lesson
    [Arguments]    ${tab}    ${filter}    ${heading}
    Show Help Tab    ${tab}
    Show Lesson    ${filter}    ${heading}

Copy Buttons
    [Documentation]    Where the Copy buttons of the lesson on show are, top to bottom (the pointer taken off them
    ...    first: a lit button's label is read badly).
    Switch To Window    ${TUTORIAL_WINDOW}
    Move Mouse To    150    600
    Sleep    0.3s
    ${buttons}=    Find All Text In Region    @{COPY_COLUMN}    Copy
    RETURN    ${buttons}

Press Copy At
    [Documentation]    Presses the Copy button at (x, y) and returns what it put on the clipboard.
    [Arguments]    ${x}    ${y}
    Set Clipboard    nothing was copied
    Click At    ${x}    ${y}
    Wait Until Keyword Succeeds    10x    0.2s    Clipboard Should Have Changed
    ${text}=    Get Clipboard
    RETURN    ${text}

Copy Command
    [Documentation]    Presses the `n`th Copy of the lesson on show (1: the top one); returns what it copied.
    [Arguments]    ${n}
    ${buttons}=    Copy Buttons
    ${button}=    Get From List    ${buttons}    ${{ int($n) - 1 }}
    ${text}=    Press Copy At    ${button}[0]    ${button}[1]
    RETURN    ${text}

Copied Commands
    [Documentation]    Presses every Copy of the lesson on show, top to bottom, and returns what each copied; the
    ...    lesson has `count` of them.
    [Arguments]    ${count}
    ${buttons}=    Copy Buttons
    Length Should Be    ${buttons}    ${count}
    @{commands}=    Create List
    FOR    ${button}    IN    @{buttons}
        ${text}=    Press Copy At    ${button}[0]    ${button}[1]
        Append To List    ${commands}    ${text}
    END
    RETURN    ${commands}

App Words Of
    [Documentation]    What follows the app's name in a command of the help: the words of its command line. In a
    ...    command that pipes into the app, the app's part is after the last pipe.
    [Arguments]    ${command}
    ${words}=    Shell Words    ${command}
    ${after}=    Evaluate    max([i + 1 for i, w in enumerate($words) if w == '|'], default=0)
    ${words}=    Get Slice From List    ${words}    ${after}
    Should Be Equal    ${words}[0]    jsonquery_gui    msg=the command starts the app: ${command}
    ${args}=    Get Slice From List    ${words}    1
    RETURN    ${args}

Run Copied Command
    [Documentation]    Starts the app as a command copied from the help starts it, in the folder of the suite's
    ...    files: the app under test for `jsonquery_gui`, with the words after it. `stdin_text` is what is piped
    ...    in, for the command whose app part reads it (-).
    [Arguments]    ${command}    ${stdin_text}=${None}
    ${args}=    App Words Of    ${command}
    Launch Mcp App Serving    args=${args}    cwd=${DIR}    stdin_text=${stdin_text}

Run Tool Command
    [Documentation]    Runs a command of the help that fills a tool's page; the Tools window opens on `tool`, whose
    ...    status bar reads `says`. Then the app is closed.
    [Arguments]    ${command}    ${tool}    ${says}
    Run Copied Command    ${command}
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=10
    Switch To Window    ${TOOLS_WINDOW}
    Move Mouse To    600    11
    Tool Tab Should Be Selected    ${tool}
    Wait Until Keyword Succeeds    10x    0.5s    Region Should Contain Text    @{TOOLS_STATUS_BAR}    ${says}
    Close Jsonquery App

Tool Tab Should Be Selected
    [Arguments]    ${tool}
    ${x}=    Evaluate    int(${TOOL_TAB_X}[${tool}]) - 30
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Color    ${x}    5    60    12    0    92    128    tolerance=10

Results Should Be
    [Documentation]    The results of the query in the window are `items` (get_results).
    [Arguments]    ${items}
    ${results}=    Mcp Tool Should Succeed    get_results
    Should Be Equal    ${results}[items]    ${items}

Picture Should Be Above Caption
    [Documentation]    Scrolls the lesson down until a picture is in view with a phrase of its caption read in the
    ...    first line under it (`Picture Caption Should Be Read`: a picture is a bright block at least 120 rows
    ...    high on the dark window).
    [Arguments]    ${caption}
    Switch To Window    ${TUTORIAL_WINDOW}
    FOR    ${i}    IN RANGE    20
        ${found}=    Run Keyword And Return Status
        ...    Picture Caption Should Be Read    @{LESSON_BODY}    ${caption}    min_height=120
        IF    ${found}    RETURN
        Scroll Lesson    3
    END
    Picture Caption Should Be Read    @{LESSON_BODY}    ${caption}    min_height=120

Lesson Text Above Its Pictures
    [Documentation]    What OCR reads of the lesson on show down to its first picture: a region with a picture in
    ...    it is read badly, the text beside the picture too.
    Switch To Window    ${TUTORIAL_WINDOW}
    ${blocks}=    Find Bright Blocks    @{LESSON_BODY}    min_height=120
    ${foot}=    Evaluate    $blocks[0][0] if $blocks else 700
    ${height}=    Evaluate    ${foot} - 130
    ${text}=    Read Region Text    278    130    750    ${height}
    RETURN    ${text}
