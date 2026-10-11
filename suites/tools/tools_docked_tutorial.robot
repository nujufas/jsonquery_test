*** Settings ***
Documentation     The tutorial's examples with the Tools docked -- see docs/22_tools_docked.md.
...               The 📖 button is in the row of tabs, at its right end; the tutorial is a window
...               of its own, as it is without tabs, and what it hands to the main window (an
...               example's data and query, run by "Try it") goes to the Json Query tab, which
...               comes to the front if a tool's page was in front of it. This is its own suite
...               because it needs tutorial.resource, whose names for the tutorial's own tabs
...               are not those of the Tools.
Resource          ../../resources/docked.resource
Resource          ../../resources/tutorial.resource
Force Tags        tools    docked
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Docked
Test Teardown     Close Jsonquery App

*** Test Cases ***
TC-DOCK-035 The Tutorial Button In The Row Of Tabs Opens The Tutorial
    [Documentation]    Pressed with a tool's page in front, the 📖 at the right end of the row
    ...    opens the tutorial window, which is a window of its own.
    [Tags]    p1
    Show Docked Tab    format
    Click At    ${TUTORIAL_BUTTON_X}    ${DT_TAB_Y}
    Wait Until Window Exists    ${TUTORIAL_WINDOW}    timeout=8
    Filter Lessons    csv & tsv
    Lesson List Should Show    CSV & TSV

TC-DOCK-036 An Example Tried From A Tool's Tab Runs In The Json Query Tab
    [Documentation]    With Format's page in front, "Try it" on a lesson's example hands its data
    ...    and query to the main window: the Json Query tab comes to the front and the query runs
    ...    in it, so the learner sees the answer.
    [Tags]    p1
    Show Docked Tab    format
    Click At    ${TUTORIAL_BUTTON_X}    ${DT_TAB_Y}
    Wait Until Window Exists    ${TUTORIAL_WINDOW}    timeout=8
    Show Lesson    csv & tsv    CSV & TSV
    Try Example    One CSV row
    Set Layout Shift    ${DY}
    Docked Tab Should Be Selected    json
    Docked Tab Should Not Be Selected    format
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{STATUS_BAR}    result(s)
