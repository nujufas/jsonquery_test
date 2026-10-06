*** Settings ***
Documentation     The tutorial pages for the jq functions the app adds -- see
...               docs/19_tutorial_pages.md. Two topics of the jq tab teach them: "Tables &
...               lookups" (CSV & TSV, Records to a table, Quoting & escaping, Copy & save as
...               CSV or TSV, IN, INDEX & JOIN) and "Event streams" (tostream, fromstream &
...               truncate_stream), with two rows on the cheat sheet. The window itself is
...               covered by satellites.robot; these cases read the lessons.
...
...               Every example of the eight pages is run the way a learner runs it: its
...               "▶ Try it" button hands the sample data and the query to the main window,
...               and what the main window then holds is read back exactly (the Results
...               root's Copy to Clipboard) and compared with what jq 1.8.1 prints for the
...               same query over the same data. Each page's text is checked by OCR only for
...               what OCR reads well: the title, the captions, the buttons.
Resource          ../../resources/results.resource
Resource          ../../resources/tutorial.resource
Force Tags        tutorial_pages
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
${TEAM_CSV_QUERY}      .members[] | [.name, .age, .role] | @csv
${AWKWARD_CSV_ROWS}    "Smith, Jo","said ""hi"""\n"Ada","two\nlines"\n"Tab\tman","C:\\temp"
${AWKWARD_TSV_ROWS}    Smith, Jo\tsaid "hi"\nAda\ttwo\\nlines\nTab\\tman\tC:\\\\temp

*** Keywords ***
Open Page
    [Documentation]    Opens the tutorial and shows the lesson that `filter` leaves alone in
    ...    the list; `check` is what its heading (or, with `where=body`, its body) says.
    [Arguments]    ${filter}    ${check}    ${where}=heading
    Open Tutorial
    Show Lesson    ${filter}    ${check}    ${where}

Example Should Give Json
    [Documentation]    "Try it" on the example whose caption contains `caption`; the main
    ...    window's results are the JSON array `expected` and carry no CSV/TSV note.
    [Arguments]    ${filter}    ${check}    ${caption}    ${expected}    ${where}=heading
    Open Page    ${filter}    ${check}    ${where}
    Try Example    ${caption}
    Results Should Be Json    ${expected}
    Move Mouse To    600    450
    Format Note Should Be Hidden

Example Should Give Rows
    [Documentation]    "Try it" on the example whose caption contains `caption`; the main
    ...    window's results are rows of CSV or TSV, exactly `expected`, and the note says so.
    [Arguments]    ${filter}    ${check}    ${caption}    ${expected}
    Open Page    ${filter}    ${check}
    Try Example    ${caption}
    Results Should Be Text    ${expected}
    Move Mouse To    600    450
    Format Note Should Be Shown

Page Should Show
    [Documentation]    The open page has a heading, a caption and the "Result" boxes, and
    ...    ends with its tips under "Good to know" (read after scrolling down).
    [Arguments]    ${caption}
    Lesson Should Read    ${caption}
    Lesson Should Read    Result
    Scroll Lesson    80
    Lesson Should Read    Good to know

*** Test Cases ***
# --- finding the pages ------------------------------------------------------------------

TC-TUT-001 The @csv Filter Lists The Four Table Pages
    [Documentation]    Every lesson with an example that uses @csv, under the topic that holds
    ...    them.
    [Tags]    p1
    Open Tutorial
    Filter Lessons    @csv
    Lesson List Should Show    Tables
    Lesson List Should Show    CSV & TSV
    Lesson List Should Show    Records
    Lesson List Should Show    Quoting
    Lesson List Should Show    Copy &

TC-TUT-002 The tostream Filter Lists The Event Stream Pages
    [Tags]    p1
    Open Tutorial
    Filter Lessons    tostream
    Lesson List Should Show    Event streams
    Lesson List Should Show    tostream
    Lesson List Should Show    fromstream

TC-TUT-003 The INDEX Filter Finds The Page And The Cheat Sheet
    [Tags]    p2
    Open Tutorial
    Filter Lessons    INDEX
    Lesson List Should Show    INDEX & JOIN
    Lesson List Should Show    Cheat sheet

TC-TUT-004 Another Language Has No Table Pages
    [Documentation]    JSON Pointer has no @csv: its tab, filtered by it, lists nothing.
    [Tags]    p2
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Click At    ${TAB_POINTER_X}    ${TAB_Y}
    Sleep    0.6s
    Filter Lessons    csv
    Lesson List Should Not Show    Tables
    Lesson List Should Not Show    CSV

TC-TUT-005 Both Topics Are In The List
    [Documentation]    With no filter the list shows every topic, the two new ones among them.
    [Tags]    p1
    Open Tutorial
    Switch To Window    ${TUTORIAL_WINDOW}
    Wait Until Keyword Succeeds    6x    0.5s
    ...    Region Should Contain Text    @{LESSON_LIST}    Tables
    Region Should Contain Text    @{LESSON_LIST}    Event streams

TC-TUT-006 Next Goes From CSV & TSV To Records To A Table
    [Tags]    p1
    Open Page    csv & tsv    CSV & TSV
    Go To Next Lesson
    Lesson Heading Should Be    Records

TC-TUT-007 Next Goes On From The Last Table Page Into The Next Topic
    [Documentation]    INDEX & JOIN is the last page of "Tables & lookups"; its Next button
    ...    opens "Variables", the first lesson of the topic after it.
    [Tags]    p2
    Open Page    index & join    INDEX
    Go To Next Lesson
    Lesson Heading Should Be    Variables

TC-TUT-008 Previous Goes Back From The First Event Stream Page
    [Documentation]    tostream follows "Recursion: .., paths, walk" (the last lesson of
    ...    "Variables & functions"): Previous crosses the topic boundary the other way.
    [Tags]    p2
    Open Page    The events of a small value    tostream
    Go To Previous Lesson
    Lesson Heading Should Be    Recursion

TC-TUT-009 The Last Event Stream Page Leads On To Errors
    [Tags]    p3
    Open Page    fromstream &    fromstream
    Go To Next Lesson
    Lesson Heading Should Be    try

# --- each page opens ----------------------------------------------------------------------

TC-TUT-010 CSV & TSV Opens With Its Examples And Tips
    [Tags]    p1
    Open Page    csv & tsv    CSV & TSV
    Page Should Show    One CSV row per member

TC-TUT-011 Records To A Table Opens With Its Examples And Tips
    [Tags]    p1
    Open Page    records to a table    Records
    Page Should Show    Header and rows

TC-TUT-012 Quoting & Escaping Opens With Its Examples And Tips
    [Tags]    p1
    Open Page    quoting &    Quoting
    Page Should Show    quotes around strings

TC-TUT-013 Copy & Save As CSV Or TSV Opens With Its Examples And Tips
    [Tags]    p1
    Open Page    not the last step    Copy
    Page Should Show    Ends in

TC-TUT-014 IN Opens With Its Examples And Tips
    [Tags]    p1
    Open Page    IN(.members    Members whose role    where=body
    Page Should Show    Members whose role

TC-TUT-015 INDEX & JOIN Opens With Its Examples And Tips
    [Tags]    p1
    Open Page    index & join    INDEX
    Page Should Show    lookup table

TC-TUT-016 tostream Opens With Its Examples And Tips
    [Tags]    p1
    Open Page    The events of a small value    tostream
    Page Should Show    events of a small

TC-TUT-017 fromstream & truncate_stream Opens With Its Examples And Tips
    [Tags]    p1
    Open Page    fromstream &    fromstream
    Page Should Show    written by hand

TC-TUT-018 The Compatibility Page Says The Functions Are Added
    [Documentation]    "jq here vs jq 1.7" no longer lists @csv and the others as missing:
    ...    it says jsonquery adds them, and still lists what is "Not available" ($ENV, input and the rest).
    [Tags]    p2
    Open Page    jq here vs    here vs
    Lesson Should Read    adds them
    Lesson Should Read    Not available

# --- every example, run in the main window ------------------------------------------------

TC-TUT-020 CSV & TSV: One CSV Row Per Member
    [Tags]    p1
    Example Should Give Rows    csv & tsv    CSV & TSV    One CSV row
    ...    "Ada",36,"lead"\n"Linus",28,"dev"\n"Grace",45,"dev"\n"Alan",41,"qa"

TC-TUT-021 CSV & TSV: A Header Row First Tab-Separated
    [Tags]    p1
    Example Should Give Rows    csv & tsv    CSV & TSV    header row first
    ...    name\tage\nAda\t36\nLinus\t28\nGrace\t45\nAlan\t41

TC-TUT-022 CSV & TSV: Missing Values Are Empty Fields
    [Tags]    p1
    Example Should Give Rows    csv & tsv    CSV & TSV    Missing values
    ...    "Ada","ada@example.com"\n"Linus",\n"Grace",\n"Alan","alan@example.com"

TC-TUT-023 Records: Header And Rows From One List Of Columns
    [Tags]    p1
    Example Should Give Rows    records to a table    Records    one list of columns
    ...    "name","role","age"\n"Ada","lead",36\n"Linus","dev",28\n"Grace","dev",45\n"Alan","qa",41

TC-TUT-024 Records: A List In One Cell
    [Tags]    p1
    Example Should Give Rows    records to a table    Records    in one cell
    ...    "Ada","rust;sql"\n"Linus","c;shell"\n"Grace","cobol"\n"Alan",""

TC-TUT-025 Records: An Object As Two Columns
    [Tags]    p2
    Example Should Give Rows    records to a table    Records    two columns
    ...    "city","Berlin"\n"floor",3

TC-TUT-026 Quoting: CSV Quotes Strings And Doubles The Quotes Inside
    [Tags]    p1
    Example Should Give Rows    quoting &    Quoting    quotes around
    ...    ${AWKWARD_CSV_ROWS}

TC-TUT-027 Quoting: TSV Quotes Nothing And Escapes Instead
    [Tags]    p1
    Example Should Give Rows    quoting &    Quoting    no quotes
    ...    ${AWKWARD_TSV_ROWS}

TC-TUT-028 Quoting: Only An Array Makes A Row
    [Documentation]    The third example catches the error of @csv on an object and shows its
    ...    text: one result, a JSON string naming the problem.
    [Tags]    p2
    Open Page    quoting &    Quoting
    Try Example    makes a row
    ${text}=    Copy All Results
    ${results}=    Evaluate    json.loads($text)    modules=json
    Length Should Be    ${results}    1
    Should Contain    ${results}[0]    cannot be csv-formatted

TC-TUT-029 Copy & Save: The Last Step @csv Makes Rows
    [Tags]    p1
    Example Should Give Rows    not the last step    Copy    Ends in
    ...    "Ada",36\n"Linus",28\n"Grace",45\n"Alan",41

TC-TUT-030 Copy & Save: Not The Last Step Is Still JSON
    [Documentation]    The contrast example: the same rows collected in brackets are one JSON
    ...    array of strings, and the Results panel has no CSV note.
    [Tags]    p1
    Example Should Give Json    not the last step    Copy    still JSON
    ...    [["\\"Ada\\",36", "\\"Linus\\",28", "\\"Grace\\",45", "\\"Alan\\",41"]]

TC-TUT-031 IN: Members Whose Role Is One Of Several
    [Tags]    p1
    Example Should Give Json    IN(.members    Members whose role    role is one of
    ...    ["Linus", "Grace", "Alan"]    where=body

TC-TUT-032 IN: Is Any Member In QA
    [Tags]    p1
    Example Should Give Json    IN(.members    Members whose role    any member
    ...    [true]    where=body

TC-TUT-033 IN: Skills That Are Not On A List
    [Tags]    p1
    Example Should Give Json    IN(.members    Members whose role    not on a list
    ...    [["c", "shell", "cobol"]]    where=body

TC-TUT-034 INDEX: A Lookup Table By Code
    [Tags]    p1
    Example Should Give Json    index & join    INDEX    lookup table
    ...    [{"ADA": "London", "LIN": "Helsinki", "GRA": "New York"}]

TC-TUT-035 INDEX: Look Up The Customer Of Every Order
    [Tags]    p1
    Example Should Give Json    index & join    INDEX    customer of every
    ...    [{"order": 101, "who": "Ada"}, {"order": 102, "who": "Grace"}, {"order": 103, "who": "Ada"}, {"order": 104, "who": "Linus"}]

TC-TUT-036 INDEX: JOIN Does The Matching
    [Tags]    p1
    Example Should Give Json    index & join    INDEX    does the matching
    ...    [{"order": 101, "city": "London"}, {"order": 102, "city": "New York"}, {"order": 103, "city": "London"}, {"order": 104, "city": "Helsinki"}]

TC-TUT-037 tostream: The Events Of A Small Value
    [Tags]    p1
    Example Should Give Json    The events of a small value    tostream    events of a small
    ...    [[[0], 1], [[1, 0], 2], [[1, 1], 3], [[1, 1]], [[1]]]

TC-TUT-038 tostream: Every Leaf As Path = Value
    [Tags]    p1
    Example Should Give Json    The events of a small value    tostream    Every leaf
    ...    ["a.0 = 1", "a.1.0 = 2", "a.1.1 = 3", "b.c = x"]

TC-TUT-039 tostream: Where Is A Value
    [Tags]    p1
    Example Should Give Json    The events of a small value    tostream    Where is a
    ...    [["a", 1, 1]]

TC-TUT-040 fromstream: Events Written By Hand
    [Tags]    p1
    Example Should Give Json    fromstream &    fromstream    written by hand
    ...    [{"a": 1, "b": 2}]

TC-TUT-041 fromstream: Drop A Field From Every Record
    [Tags]    p1
    Example Should Give Json    fromstream &    fromstream    Drop a field
    ...    [[{"code": "ADA", "name": "Ada"}, {"code": "LIN", "name": "Linus"}, {"code": "GRA", "name": "Grace"}]]

TC-TUT-042 fromstream: One Result Per Order
    [Tags]    p1
    Example Should Give Json    fromstream &    fromstream    per order
    ...    [{"no": 101, "customer": "ADA", "item": "keyboard", "qty": 2}, {"no": 102, "customer": "GRA", "item": "monitor", "qty": 1}, {"no": 103, "customer": "ADA", "item": "mouse", "qty": 3}, {"no": 104, "customer": "LIN", "item": "cable", "qty": 10}]

# --- the other buttons ----------------------------------------------------------------------

TC-TUT-050 Load Query Puts The CSV Query In The Main Window And Nothing Else
    [Documentation]    The query is in the box; no document is loaded.
    [Tags]    p1
    Open Page    csv & tsv    CSV & TSV
    Click Example Button    Load query    One CSV row
    Switch To Main Window
    Sleep    0.8s
    Query Text Should Be    ${TEAM_CSV_QUERY}
    Region Should Contain Text    @{SOURCE_PANEL}    Paste JSON here

TC-TUT-051 Load Data Opens The Sample Document
    [Documentation]    The Source pane shows the team document; the query box stays empty.
    [Tags]    p1
    Open Page    csv & tsv    CSV & TSV
    Click Example Button    Load data    One CSV row
    Switch To Main Window
    Wait Until Keyword Succeeds    8x    0.5s
    ...    Region Should Contain Text    @{SOURCE_PANEL}    Platform    flatten_tints=${True}
    Region Should Contain Text    @{QUERY_TEXTBOX}    e.g.

TC-TUT-052 Copy Query Copies The Query Exactly
    [Tags]    p1
    Open Page    csv & tsv    CSV & TSV
    Set Clipboard    nothing was copied
    Click Example Button    Copy query    One CSV row
    Sleep    0.6s
    ${copied}=    Get Clipboard
    Should Be Equal    ${copied}    ${TEAM_CSV_QUERY}

TC-TUT-053 Try It Replaces The Open Document And Query
    [Documentation]    With another document and a query already in the main window, Try It
    ...    replaces both: the Source pane shows the sample, and the results are its rows.
    [Tags]    p1
    Load Fixture    people.json
    Run Query    .[0].name
    Open Page    csv & tsv    CSV & TSV
    Try Example    One CSV row
    Region Should Contain Text    @{SOURCE_PANEL}    Platform    flatten_tints=${True}
    Results Should Be Text    "Ada",36,"lead"\n"Linus",28,"dev"\n"Grace",45,"dev"\n"Alan",41,"qa"

TC-TUT-054 A Page's Rows Can Be Saved As They Are
    [Documentation]    Try It on a CSV example, then Save... in the main window: the file is
    ...    the example's rows, named results.csv.
    [Tags]    p1
    Open Page    csv & tsv    CSV & TSV
    Try Example    One CSV row
    ${dir}=    Make Temp Directory
    ${asked}=    Save Results Suggested In    ${dir}
    Should Be Equal    ${asked}[current_name]    results.csv
    Wait Until Keyword Succeeds    15x    0.4s
    ...    File Should Be    ${dir}/results.csv    "Ada",36,"lead"\n"Linus",28,"dev"\n"Grace",45,"dev"\n"Alan",41,"qa"\n

# --- the cheat sheet --------------------------------------------------------------------------

TC-TUT-060 Cheat Sheet: One CSV Row Per Member
    [Tags]    p1
    Open Page    Cheat sheet    Cheat
    Try Cheat Sheet Row    one CSV row
    Results Should Be Text    "Ada",36\n"Linus",28\n"Grace",45\n"Alan",41
    Format Note Should Be Shown

TC-TUT-061 Cheat Sheet: A Lookup Table Keyed By Name
    [Tags]    p1
    Open Page    Cheat sheet    Cheat
    Try Cheat Sheet Row    lookup table keyed
    Results Should Be Json
    ...    [{"Ada": {"name": "Ada", "age": 36, "role": "lead", "active": true, "email": "ada@example.com", "skills": ["rust", "sql"]}, "Linus": {"name": "Linus", "age": 28, "role": "dev", "active": true, "email": null, "skills": ["c", "shell"]}, "Grace": {"name": "Grace", "age": 45, "role": "dev", "active": false, "skills": ["cobol"]}, "Alan": {"name": "Alan", "age": 41, "role": "qa", "active": true, "email": "alan@example.com", "skills": []}}]

TC-TUT-062 Cheat Sheet: Keep When The Value Is One Of Several
    [Tags]    p1
    Open Page    Cheat sheet    Cheat
    Try Cheat Sheet Row    one of several
    Results Should Be Json
    ...    [{"name": "Linus", "age": 28, "role": "dev", "active": true, "email": null, "skills": ["c", "shell"]}, {"name": "Grace", "age": 45, "role": "dev", "active": false, "skills": ["cobol"]}, {"name": "Alan", "age": 41, "role": "qa", "active": true, "email": "alan@example.com", "skills": []}]

TC-TUT-063 Cheat Sheet: The Value As Events
    [Tags]    p1
    Open Page    Cheat sheet    Cheat
    Try Cheat Sheet Row    events
    Results Should Be Json    [[["city"], "Berlin"], [["floor"], 3], [["floor"]]]
