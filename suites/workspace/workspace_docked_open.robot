*** Settings ***
Documentation     A document of the workspace opened with the Tools docked: it goes to the page that is in front -- the box
...               the page works on (Validate's, Patch's and Create Schema's Document box, Format's Input, the first empty
...               side of Diff, else its right; one more file of Merge's list) -- and the page stays in front; with the Json
...               Query tab in front it is the Source, as it always was. The button under the list, and the menu of a
...               right click, say where it goes -- see docs/25_workspace.md.
Resource          ../../resources/workspace.resource
Resource          ../../resources/docked.resource
Library           OperatingSystem
Force Tags        workspace    docked
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Docked Workspace With A Document
Test Teardown     Close Jsonquery App

*** Variables ***
${DOCKED_AND_OPEN}        {"tools": "docked", "workspace": {"pane": "open"}}
# The row of people.json in WITH_DOCUMENT (the folders, then people and scratch).
${ROW_PEOPLE}             6
# The pages of the main window with the pane open (the window's points: the row of tabs is above them). The inputs are in
# the left half of a page, two boxes one above the other where the page has two; the result is in the right half. Diff has
# its two sides in the halves. What is in a box is read from its title (the file's name is there) down.
@{PAGE_FIRST_BOX}         262    56     458    344
@{PAGE_SECOND_BOX}        262    410    458    360
@{PAGE_RESULT}            728    56     460    340
@{DIFF_LEFT}              268    62     454    330
@{DIFF_RIGHT}             734    62     454    330
@{MERGE_FILES}            262    110    458    80
# Format's button, at the left of its row of commands.
${FORMAT_BUTTON_X}        286
${COMMAND_ROW_Y}          34
# The page's status line, at the foot of the window.
@{PAGE_STATUS}            36     779    964    20

*** Test Cases ***
TC-WSP-339 A Document Opened From The List With Validate In Front Goes In Its Document Box
    [Documentation]    The page in front is where the document goes: Validate's Document box, the Schema box left as it was,
    ...    and the page stays in front. Picked, the document's button says so first.
    [Tags]    p1
    Show Docked Tab    validate
    Set Layout Shift    ${DY}
    Click Row    ${ROW_PEOPLE}
    Without Layout Shift    Details Should Show    Open in Validate
    Double Click Row    ${ROW_PEOPLE}
    Docked Tab Should Be Selected    validate
    Without Layout Shift    Wait Until Region Contains Text    @{PAGE_FIRST_BOX}    Ana    timeout=5
    # (OCR reads the file's name without its dot: "people json".)
    Without Layout Shift    Region Should Contain Text    @{PAGE_FIRST_BOX}    people
    Without Layout Shift    Region Should Not Contain Text    @{PAGE_SECOND_BOX}    Ana

TC-WSP-340 A Document Opened From The List With Format In Front Goes In Its Input Box, Ready To Format
    [Documentation]    Format's Input box takes it, and Format formats it.
    [Tags]    p1
    Show Docked Tab    format
    Set Layout Shift    ${DY}
    Click Row    ${ROW_PEOPLE}
    Without Layout Shift    Details Should Show    Open in Format
    Double Click Row    ${ROW_PEOPLE}
    Docked Tab Should Be Selected    format
    Without Layout Shift    Wait Until Region Contains Text    @{PAGE_FIRST_BOX}    Ana    timeout=5
    Without Layout Shift    Click At    ${FORMAT_BUTTON_X}    ${COMMAND_ROW_Y}
    Without Layout Shift    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{PAGE_STATUS}    Formatted in
    Without Layout Shift    Region Should Contain Text    @{PAGE_RESULT}    Ana

TC-WSP-341 A Document Opened From The List With Diff In Front Goes In Its Left Side, And The Next In Its Right
    [Documentation]    As a file dropped on the page: the first side that is empty, else the right one.
    [Tags]    p1
    Show Docked Tab    diff
    Set Layout Shift    ${DY}
    Click Row    ${ROW_PEOPLE}
    Without Layout Shift    Details Should Show    Open in Diff
    Double Click Row    ${ROW_PEOPLE}
    Docked Tab Should Be Selected    diff
    Without Layout Shift    Wait Until Region Contains Text    @{DIFF_LEFT}    Ana    timeout=5
    Without Layout Shift    Region Should Not Contain Text    @{DIFF_RIGHT}    Ana
    Double Click Row    ${ROW_PEOPLE}
    Without Layout Shift    Wait Until Region Contains Text    @{DIFF_RIGHT}    Ana    timeout=5
    Without Layout Shift    Region Should Contain Text    @{DIFF_LEFT}    Ana

TC-WSP-342 A Document Opened From The List With Patch In Front Goes In Its Document Box, Not The Patch Box
    [Tags]    p1
    Show Docked Tab    patch
    Set Layout Shift    ${DY}
    Click Row    ${ROW_PEOPLE}
    Without Layout Shift    Details Should Show    Open in Patch
    Double Click Row    ${ROW_PEOPLE}
    Docked Tab Should Be Selected    patch
    Without Layout Shift    Wait Until Region Contains Text    @{PAGE_FIRST_BOX}    Ana    timeout=5
    Without Layout Shift    Region Should Not Contain Text    @{PAGE_SECOND_BOX}    Ana

TC-WSP-343 A Document Opened From The List With Create Schema In Front Goes In Its Document Box
    [Tags]    p1
    Show Docked Tab    create
    Set Layout Shift    ${DY}
    Click Row    ${ROW_PEOPLE}
    Without Layout Shift    Details Should Show    Open in Create Schema
    Double Click Row    ${ROW_PEOPLE}
    Docked Tab Should Be Selected    create
    Without Layout Shift    Wait Until Region Contains Text    @{PAGE_FIRST_BOX}    Ana    timeout=5

TC-WSP-344 A Document Opened From The List With Merge In Front Is One More File Of Its List, Once
    [Documentation]    Merge works on files: the document is added to its list; opened again, it is not added twice.
    [Tags]    p1
    Show Docked Tab    merge
    Set Layout Shift    ${DY}
    Click Row    ${ROW_PEOPLE}
    Without Layout Shift    Details Should Show    Add to Merge
    Double Click Row    ${ROW_PEOPLE}
    Docked Tab Should Be Selected    merge
    Without Layout Shift    Wait Until Region Contains Text    @{MERGE_FILES}    Files (1)    timeout=5
    Without Layout Shift    Region Should Contain Text    @{MERGE_FILES}    people
    Double Click Row    ${ROW_PEOPLE}
    Sleep    0.5s
    Without Layout Shift    Region Should Contain Text    @{MERGE_FILES}    Files (1)

TC-WSP-345 The Menu Of A Right Click On A Document Says Where It Goes, And Puts It There
    [Documentation]    The menu's Open is the button's: with Diff in front, "Open in Diff", which fills the left side.
    [Tags]    p2
    Show Docked Tab    diff
    Set Layout Shift    ${DY}
    Pick Row Menu Item    ${ROW_PEOPLE}    Open in Diff
    Docked Tab Should Be Selected    diff
    Without Layout Shift    Wait Until Region Contains Text    @{DIFF_LEFT}    Ana    timeout=5

TC-WSP-346 With The Json Query Tab In Front A Document Opened From The List Is The Source, As Ever
    [Tags]    p1
    Show Docked Tab    json
    Click Row    ${ROW_PEOPLE}
    Details Should Show    Open as Source
    Double Click Row    ${ROW_PEOPLE}
    Docked Tab Should Be Selected    json
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    2 items    timeout=6

*** Keywords ***
Launch Docked Workspace With A Document
    Launch Jsonquery App    settings=${DOCKED_AND_OPEN}    workspace=${WITH_DOCUMENT}
    Sleep    0.8s
