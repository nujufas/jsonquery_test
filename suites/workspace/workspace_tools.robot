*** Settings ***
Documentation     The workspace and the Tools: Validate and Patch have a pair of buttons for what they take from a
...               file -- Save schema… and Saved schemas… on Validate, Save patch… and Saved patches… on Patch --
...               and a schema or a patch in the pane is put in its box of the page, with its sample as the
...               document, from the pane -- see docs/25_workspace.md. The Tools are in their window here (the
...               window of the Tools is where the buttons are drawn at the points below); the pane and the window
...               that saves are the main window's, which a wish from the Tools brings forward.
Resource          ../../resources/workspace.resource
Resource          ../../resources/tools.resource
Library           OperatingSystem
Force Tags        workspace    tools    window-only
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App
Test Teardown     Close Jsonquery App

*** Variables ***
# The buttons of the command row of the pages, in the Tools window (900x580).
${SAVE_SCHEMA_X}          243
${SAVED_SCHEMAS_X}        351
${SAVE_PATCH_X}           325
${SAVED_PATCHES_X}        425
${SCHEMA}                 {"type": "object", "required": ["name"]}
${DOCUMENT}               {"age": 3}
${PATCH}                  [{"op": "add", "path": "/b", "value": 2}]

*** Test Cases ***
TC-WSP-170 Save Schema Saves What Is In The Schema Box As A Schema Of The Workspace
    [Documentation]    The button is on Validate, in the command row; it brings the main window forward, with the window
    ...    that saves open on the tab for a schema. The file ends .schema.json, and what is in it is the schema.
    [Tags]    p1
    Open Tool    validate
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${SCHEMA}
    Click At    ${SAVE_SCHEMA_X}    ${COMMAND_Y}
    Switch To Main Window
    Set Form Kind    save
    Form Should Be Open    new folder in it
    Tab Of The Save Window Should Be Picked    ${SAVE_TAB_SCHEMA_X}
    Type Name In Form    mine
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    mine.schema.json    ${SCHEMA}
    ${item}=    Workspace Item    mine.schema.json
    ${sha}=    Sha256 Of Text    ${SCHEMA}
    Should Be Equal    ${item}[sha256]    ${sha}
    List Should Show    mine

TC-WSP-183 Save Schema Offers The Schema When The Patch Box Of The Other Page Has Something Too
    [Documentation]    Both pages have what can be saved: the button of Validate offers the schema, and the file is one.
    [Tags]    p2
    Open Tool    patch
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${PATCH}
    Pick Tool    validate
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${SCHEMA}
    Click At    ${SAVE_SCHEMA_X}    ${COMMAND_Y}
    Switch To Main Window
    Set Form Kind    save
    Form Should Be Open    new folder in it
    Tab Of The Save Window Should Be Picked    ${SAVE_TAB_SCHEMA_X}
    Type Name In Form    both
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    both.schema.json    ${SCHEMA}
    Workspace File Should Not Exist    both.patch.json

TC-WSP-184 Save Patch Offers The Patch When The Schema Box Of The Other Page Has Something Too
    [Documentation]    The same the other way: the button of Patch offers the patch.
    [Tags]    p2
    Open Tool    validate
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${SCHEMA}
    Pick Tool    patch
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${PATCH}
    Click At    ${SAVE_PATCH_X}    ${COMMAND_Y}
    Switch To Main Window
    Set Form Kind    save
    Form Should Be Open    new folder in it
    Tab Of The Save Window Should Be Picked    ${SAVE_TAB_PATCH_X}
    Type Name In Form    both
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    both.patch.json    ${PATCH}
    Workspace File Should Not Exist    both.schema.json

TC-WSP-171 The Document Box Of Validate Can Be Kept As The Sample Of The Schema
    [Tags]    p1
    Open Tool    validate
    Paste Into Box    ${FIRST_BOX_X}    ${FIRST_BOX_Y}    ${DOCUMENT}
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${SCHEMA}
    Click At    ${SAVE_SCHEMA_X}    ${COMMAND_Y}
    Switch To Main Window
    Set Form Kind    save
    Form Should Be Open    new folder in it
    Form Should Show    Keep the Document box
    Click In Form    ${SAVE_SAMPLE_X}    ${SAVE_SAMPLE_Y}
    Type Name In Form    withdoc
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    withdoc.schema.json    ${SCHEMA}
    Workspace File Should Be    withdoc.sample.json    ${DOCUMENT}

TC-WSP-172 Save Schema Does Nothing While The Schema Box Is Empty
    [Tags]    p2
    Open Tool    validate
    Click At    ${SAVE_SCHEMA_X}    ${COMMAND_Y}
    Sleep    0.8s
    Switch To Main Window
    Set Form Kind    save
    Form Should Not Be Open    new folder in it

TC-WSP-173 Saved Schemas Narrows The List To The Schemas
    [Documentation]    The button brings the main window forward with the pane showing the schemas of the workspace, and
    ...    only those.
    [Tags]    p1
    Open Tool    validate
    Click At    ${SAVED_SCHEMAS_X}    ${COMMAND_Y}
    Switch To Main Window
    Sleep    0.8s
    List Should Show    orders
    List Should Not Show    scratch    update    logins

TC-WSP-174 Saved Schemas Shows The Pane When It Was Hidden
    [Tags]    p1
    Close Jsonquery App
    Launch Jsonquery App    workspace=${STANDARD}
    Pane Should Not Be Shown
    Open Tool    validate
    Click At    ${SAVED_SCHEMAS_X}    ${COMMAND_Y}
    Switch To Main Window
    Sleep    0.8s
    Pane Should Be Open
    List Should Show    orders
    List Should Not Show    scratch

TC-WSP-175 Use As Schema Puts The Schema In The Schema Box Of Validate
    [Tags]    p1
    Pick Row Menu Item    ${ROW_ORDERS}    Use as schema
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{SECOND_BOX}    required
    Region Should Show Text    @{SECOND_BOX}    object
    Tab Should Be Selected    validate

TC-WSP-176 Use As Schema With Its Sample Puts The Sample In The Document Box And Checks It
    [Documentation]    orders has a sample ({}), which does not have the property id that its schema asks for: the page
    ...    says so.
    [Tags]    p1
    Click Row    ${ROW_ORDERS}
    Press In Details    sample
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Status Should Read    problem
    Result Should Read    id

TC-WSP-177 The Button Under The List Does The Same As The Menu
    [Documentation]    A schema that has a sample has two buttons under the list: Use as schema, and then With its sample.
    [Tags]    p2
    Click Row    ${ROW_ORDERS}
    Details Buttons Should Be In Order    schema    sample
    Press In Details    schema
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{SECOND_BOX}    required

TC-WSP-178 Save Patch Saves What Is In The Patch Box As A Patch Of The Workspace
    [Tags]    p1
    Open Tool    patch
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${PATCH}
    Click At    ${SAVE_PATCH_X}    ${COMMAND_Y}
    Switch To Main Window
    Set Form Kind    save
    Form Should Be Open    new folder in it
    Tab Of The Save Window Should Be Picked    ${SAVE_TAB_PATCH_X}
    Type Name In Form    adder
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    adder.patch.json    ${PATCH}
    List Should Show    adder

TC-WSP-179 The Document Box Of Patch Can Be Kept As The Sample Of The Patch
    [Tags]    p2
    Open Tool    patch
    Paste Into Box    ${FIRST_BOX_X}    ${FIRST_BOX_Y}    ${DOCUMENT}
    Paste Into Box    ${FIRST_BOX_X}    ${SECOND_BOX_Y}    ${PATCH}
    Click At    ${SAVE_PATCH_X}    ${COMMAND_Y}
    Switch To Main Window
    Set Form Kind    save
    Form Should Be Open    new folder in it
    Click In Form    ${SAVE_SAMPLE_X}    ${SAVE_SAMPLE_Y}
    Type Name In Form    adder
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Be    adder.patch.json    ${PATCH}
    Workspace File Should Be    adder.sample.json    ${DOCUMENT}

TC-WSP-180 Saved Patches Narrows The List To The Patches
    [Tags]    p1
    Open Tool    patch
    Click At    ${SAVED_PATCHES_X}    ${COMMAND_Y}
    Switch To Main Window
    Sleep    0.8s
    List Should Show    update
    List Should Not Show    scratch    orders    logins

TC-WSP-181 Use As Patch Puts The Patch In The Patch Box Of Patch
    [Tags]    p1
    Pick Row Menu Item    ${ROW_UPDATE}    Use as patch
    Wait Until Window Exists    ${TOOLS_WINDOW}    timeout=8
    Switch To Window    ${TOOLS_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s    Region Should Contain Text    @{SECOND_BOX}    add
    Tab Should Be Selected    patch

TC-WSP-182 A Document Item Is Opened As The Source Of The Main Window
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${WITH_DOCUMENT}
    Pick Row Menu Item    6    Open as Source
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    2 items    timeout=6
