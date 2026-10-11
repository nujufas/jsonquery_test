*** Settings ***
Documentation     The 🌐 in the status bar, between the ⓘ and the ⚙ -- see docs/23_website.md.
...               One click on it hands the address of the website, https://jsonquery.dev, to
...               the person's browser; held still under the pointer it says what the site is
...               and where a click goes, in two short lines. What the About window says of the
...               site is in suites/satellites/ (TC-SAT-024 to 026).
...
...               The browser is never the real one: every app the suite starts has a stand-in
...               for it (resources/AppLibrary.py, BROWSER_OPENERS) that writes down the address
...               it was asked to open and opens nothing, and `Opened Addresses Should Be` reads
...               that list. The browser crate normalises the address it hands over, so the one
...               the stand-in sees ends in a slash.
Resource          ../../resources/keywords.resource
Force Tags        website
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The status bar's buttons (icon only: fixed points), from the right: the ⓘ, the 🌐, the ⚙.
# With the Tools docked there is a 🗗 left of the ⚙ (tools_docked.robot).
${BAR_Y}               789
${INFO_X}              1181
${GLOBE_X}             1152
${GEAR_X}              1123
${NO_BUTTON_X}         1095
# Where the tooltip of the 🌐 is: above the status bar, its right end near the window's.
@{GLOBE_TIP}           800    730    380    44
@{ABOVE_THE_TIP}       600    560    600    170
${WEBSITE_ADDRESS}     https://jsonquery.dev/
${ABOUT_WINDOW}        JsonQuery — About
${SETTINGS_WINDOW}     JsonQuery — Settings

*** Test Cases ***
TC-WEB-001 The Status Bar Has A Globe Between The Info And The Settings Buttons
    [Documentation]    From the right: ⓘ, 🌐, ⚙, and nothing left of the ⚙ (the 🗗 is only there
    ...    with the Tools docked).
    [Tags]    p1    undocked-only
    Status Bar Icon Should Be At    ${INFO_X}
    Status Bar Icon Should Be At    ${GLOBE_X}
    Status Bar Icon Should Be At    ${GEAR_X}
    Nothing Should Be In The Status Bar At    ${NO_BUTTON_X}

TC-WEB-002 Hovering The Globe Says What The Site Is And Where A Click Goes
    [Documentation]    Held still under the pointer, the 🌐 shows two lines: the name of the site
    ...    and what is there, then the address a click opens. Not a paragraph, and nothing is
    ...    opened by looking.
    [Tags]    p1
    Move Mouse To    ${GLOBE_X}    ${BAR_Y}
    Sleep    1.5s
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{GLOBE_TIP}    queries, tools and lessons in your browser
    Region Should Contain Text    @{GLOBE_TIP}    jsonquery.dev
    Region Should Contain Text    @{GLOBE_TIP}    Click to open https://jsonquery.dev
    Region Should Not Contain Text    @{ABOVE_THE_TIP}    nothing to install
    Nothing Should Have Been Opened    settle=0.5
    # Away, over nothing, it is gone.
    Move Mouse To    600    400
    Sleep    1.0s
    Region Should Not Contain Text    @{GLOBE_TIP}    Click to open

TC-WEB-003 Clicking The Globe Opens The Website In The Browser
    [Documentation]    One click: the address of the site goes to the browser, once, and no
    ...    window of the app opens.
    [Tags]    p1
    Nothing Should Have Been Opened    settle=0.3
    Click At    ${GLOBE_X}    ${BAR_Y}
    Opened Addresses Should Be    ${WEBSITE_ADDRESS}
    ${about}=    Count Windows    ${ABOUT_WINDOW}
    ${settings}=    Count Windows    ${SETTINGS_WINDOW}
    Should Be Equal As Integers    ${about}    0
    Should Be Equal As Integers    ${settings}    0

TC-WEB-004 Every Click On The Globe Opens The Site Once
    [Documentation]    Two clicks, two openings: the button does not remember that it was
    ...    pressed, and a click does not open it twice.
    [Tags]    p2
    Click At    ${GLOBE_X}    ${BAR_Y}
    Opened Addresses Should Be    ${WEBSITE_ADDRESS}
    Click At    ${GLOBE_X}    ${BAR_Y}
    Opened Addresses Should Be    ${WEBSITE_ADDRESS}    ${WEBSITE_ADDRESS}

TC-WEB-005 The Info And The Settings Buttons Work Beside The Globe And Open Nothing In The Browser
    [Documentation]    The ⓘ opens About and the ⚙ the Settings window, each from its own place
    ...    (the 🌐 took the ⚙'s old one), and neither hands an address to the browser.
    [Tags]    p1
    Click At    ${INFO_X}    ${BAR_Y}
    Wait Until Window Exists    ${ABOUT_WINDOW}    timeout=8
    Switch To Main Window
    Click At    ${GEAR_X}    ${BAR_Y}
    Wait Until Window Exists    ${SETTINGS_WINDOW}    timeout=8
    Switch To Main Window
    Nothing Should Have Been Opened    settle=0.5

*** Keywords ***
Status Bar Icon Should Be At
    [Documentation]    Something is drawn on the point: a button's icon, which OCR cannot read.
    [Arguments]    ${x}
    ${left}=    Evaluate    int(${x}) - 10
    ${top}=    Evaluate    ${BAR_Y} - 8
    Get Ink Bounds    ${left}    ${top}    20    16    threshold=60

Nothing Should Be In The Status Bar At
    [Arguments]    ${x}
    ${left}=    Evaluate    int(${x}) - 10
    ${top}=    Evaluate    ${BAR_Y} - 8
    Run Keyword And Expect Error    Nothing as bright as*
    ...    Get Ink Bounds    ${left}    ${top}    20    16    threshold=60
