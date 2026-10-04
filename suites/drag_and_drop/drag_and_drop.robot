*** Settings ***
Documentation     Files dropped on the app's windows -- see
...               docs/16_drag_and_drop.md. One file dropped on the main window
...               (or the Source window) is opened as the document; several open the
...               Tools window on its Merge page; on the Tools window a dropped file
...               goes into the first empty box of the page (or replaces the last).
...
...               `Drop Files On Window` drags and drops files for real: an XDND
...               source (resources/xdnd.py, python-xlib) that owns the
...               selection and answers the target's request for the file list,
...               as a file manager does. It was thought impossible here before --
...               `xdotool` cannot do it -- and the dropped files are in
...               resources/fixtures/merge/. (Not native Wayland, where the app
...               gets no drops: see "Known limitations" in the README.)
Resource          ../../resources/tools.resource
Library           Collections
Force Tags        drag_and_drop
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${DROPPED}           ${CURDIR}/../../resources/fixtures/merge
${FIXTURES}          ${CURDIR}/../../resources/fixtures
${SOURCE_WINDOW}     jsonquery — Source
# The top of the page's boxes: a crop of a whole box (220px) round a line of text reads
# as noise.
@{FIRST_BOX_TOP}     8      76     433    40
@{SECOND_BOX_TOP}    8      328    433    40
# The overlay shown while files are over an empty window: "Drop to open", in the
# middle of the Source pane.
@{DROP_OVERLAY}      100    190    400    36
# Where in the window the drop is made: anywhere will do.
${DROP_X}            400
${DROP_Y}            400

*** Keywords ***
Source Should Show
    [Documentation]    The Source tree reads `text` (retried). Not with tints flattened:
    ...    "3 items" is dim, which flattening erases.
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    ${text}

Open Tools On Page
    [Documentation]    Opens the Tools window on a tool's page (it is the current
    ...    window afterwards).
    [Arguments]    ${tool}
    Open Tool    ${tool}

*** Test Cases ***
TC-DND-001 A File Dropped On The Main Window Is Opened
    [Documentation]    One dropped file is a document: the Source pane shows it (an
    ...    array of 3 items) and the status bar says it was parsed.
    [Tags]    p1
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${FIXTURES}/people.json
    Source Should Show    3 items
    Wait Until Region Contains Text    @{STATUS_BAR}    Parsed    timeout=5

TC-DND-002 It Does Not Matter Where On The Window It Is Dropped
    [Documentation]    The whole window is the drop target: a file dropped on the
    ...    query box loads just the same.
    [Tags]    p2
    Drop Files On Window    600    70    ${FIXTURES}/people.json
    Source Should Show    3 items

TC-DND-003 A Dropped File Replaces The Open Document
    [Documentation]    With people.json open, dropping team.json (an object with
    ...    "members") shows that instead.
    [Tags]    p1
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${FIXTURES}/people.json
    Source Should Show    3 items
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${FIXTURES}/team.json
    Source Should Show    members
    # (people.json's root says "3 items"; team.json's says "1 keys".)
    Region Should Contain Text    @{SOURCE_PANEL}    1 keys

TC-DND-004 A File That Is Not JSON Gives A Load Error
    [Documentation]    A text file dropped on the window is reported in the status
    ...    bar ("Load error ...") and nothing is loaded.
    [Tags]    p1
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${DROPPED}/notes.txt
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_BAR}    Load error

TC-DND-005 A File With Broken JSON Gives A Load Error
    [Documentation]    A file that stops half way is an error too, not a document.
    [Tags]    p2
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${DROPPED}/broken.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{STATUS_BAR}    Load error

TC-DND-006 Several Files Open The Tools Window On Merge
    [Documentation]    Dropping two files on the main window opens the Tools window
    ...    with them listed on the Merge page ("Files (2)"), and loads nothing
    ...    in the main window.
    [Tags]    p1
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${DROPPED}/platypus.json    ${DROPPED}/echidna.json
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{MERGE_LEFT_HEADER}    Files (2
    Switch To Main Window
    Region Should Contain Text    @{SOURCE_PANEL}    Paste JSON here

TC-DND-007 Several Files Bring The Merge Page Up From Another Page
    [Documentation]    With the Tools window open on Format, dropping several files
    ...    on the main window still adds them to Merge and shows that page.
    [Tags]    p2
    Open Tools On Page    format
    Switch To Main Window
    Drop Files On Window    ${DROP_X}    ${DROP_Y}    ${DROPPED}/platypus.json    ${DROPPED}/echidna.json
    Switch To Window    ${TOOLS_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{MERGE_LEFT_HEADER}    Files (2

TC-DND-008 A File Dropped On Format Goes Into The Input Box
    [Documentation]    A small file is read into the box, where it can be edited;
    ...    Format then prints it.
    [Tags]    p1
    Open Tools On Page    format
    Drop Files On Window    200    300    ${DROPPED}/platypus.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{INPUT_BOX}    platypus
    Press Main Button
    Status Should Read    was
    Result Should Read    platypus

TC-DND-009 A Second File Dropped On Format Replaces The First
    [Documentation]    Format has one box: a file dropped on it replaces what is
    ...    there.
    [Tags]    p2
    Open Tools On Page    format
    Drop Files On Window    200    300    ${DROPPED}/platypus.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{INPUT_BOX}    platypus
    Drop Files On Window    200    300    ${DROPPED}/echidna.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{INPUT_BOX}    echidna
    Region Should Not Contain Text    @{INPUT_BOX}    platypus

TC-DND-010 Two Files Fill The Two Boxes Of Diff
    [Documentation]    The first goes to Left and the second to Right (each into the
    ...    first box still empty); Compare then finds the one difference.
    [Tags]    p1
    Open Tools On Page    diff
    Drop Files On Window    200    300    ${DROPPED}/platypus.json    ${DROPPED}/echidna.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{DIFF_LEFT_BOX}    platypus
    Region Should Contain Text    @{DIFF_RIGHT_BOX}    echidna
    Press Main Button
    Tab Row Should Offer Changes    1

TC-DND-011 Two Files Fill The Document And The Patch
    [Documentation]    On Patch the first file is the Document and the second the
    ...    Patch: applying gives the patched document (a: 2, keep: platypus).
    [Tags]    p1
    Open Tools On Page    patch
    Drop Files On Window    200    300    ${DROPPED}/patch_doc.json    ${DROPPED}/patch_ops.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{FIRST_BOX_TOP}    platypus
    Region Should Contain Text    @{SECOND_BOX_TOP}    replace
    Press Main Button
    Status Should Read    operation
    Result Should Read    platypus

TC-DND-012 Two Files Fill The Document And The Schema
    [Documentation]    On Validate the first file is the Document and the second the
    ...    Schema: validating finds that age is below its minimum.
    [Tags]    p1
    Open Tools On Page    validate
    Drop Files On Window    200    300    ${DROPPED}/validate_doc.json    ${DROPPED}/validate_schema.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{FIRST_BOX_TOP}    platypus
    Region Should Contain Text    @{SECOND_BOX_TOP}    minimum
    Press Main Button
    Status Should Read    1 problem

TC-DND-013 A File Dropped On The Source Window Opens In It
    [Documentation]    The Source pane's own window takes drops, as the main window
    ...    does: the file opens in the pane there.
    [Tags]    p1
    Click At    583    144
    Wait Until Window Exists    ${SOURCE_WINDOW}
    Switch To Window    ${SOURCE_WINDOW}
    Drop Files On Window    300    300    ${FIXTURES}/people.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    0    52    600    160    3 items

TC-DND-014 A Folder Is Not Added To The Merge List
    [Documentation]    A folder dropped with a file is left out: the list has the
    ...    file only ("Files (1)").
    [Tags]    p2
    Open Tools On Page    merge
    Drop Files On Window    200    300    ${DROPPED}    ${DROPPED}/platypus.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{MERGE_LEFT_HEADER}    Files (1

TC-DND-015 Files Dropped On The Tools Window Do Not Open In The Main Window
    [Documentation]    A drop on the Tools window is the Tools window's: the main
    ...    window under it stays empty.
    [Tags]    p2
    Open Tools On Page    format
    Drop Files On Window    200    300    ${DROPPED}/platypus.json
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{INPUT_BOX}    platypus
    Switch To Main Window
    Region Should Contain Text    @{SOURCE_PANEL}    Paste JSON here

TC-DND-016 Files Held Over An Empty Window Show The Drop Overlay
    [Documentation]    While a file is dragged over the window, not yet dropped, the
    ...    empty Source pane says "Drop to open" (the harness holds the drag: an
    ...    XDND source that sends the enter and the position and goes on answering).
    [Tags]    p1
    Region Should Not Contain Text    @{DROP_OVERLAY}    Drop to open
    Start Hovering Files    ${DROP_X}    ${DROP_Y}    ${FIXTURES}/people.json
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{DROP_OVERLAY}    Drop to open
    Stop Hovering Files

TC-DND-017 The Overlay Goes When The Files Leave
    [Documentation]    Dragging the file away again (the drag is cancelled) takes the
    ...    overlay down, and nothing was loaded.
    [Tags]    p1
    Start Hovering Files    ${DROP_X}    ${DROP_Y}    ${FIXTURES}/people.json
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{DROP_OVERLAY}    Drop to open
    Stop Hovering Files
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Not Contain Text    @{DROP_OVERLAY}    Drop to open
    Region Should Contain Text    @{SOURCE_PANEL}    Paste JSON here

TC-DND-018 With A Document Loaded There Is No Overlay
    [Documentation]    The overlay is for the empty window only: with a document
    ...    open, files held over it show nothing (releasing them would still replace
    ...    the document).
    [Tags]    p2
    Load Fixture Via Paste    {"keep":"platypus"}
    Source Should Show    platypus
    Start Hovering Files    ${DROP_X}    ${DROP_Y}    ${FIXTURES}/people.json
    Sleep    1s
    Region Should Not Contain Text    @{DROP_OVERLAY}    Drop to open
    Stop Hovering Files
