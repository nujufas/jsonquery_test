*** Settings ***
Documentation     A web address as an item of the workspace: a `.url` file (a Windows Internet Shortcut) that the pane lists with a yellow `url` tag
...               and a chip of its own (URLs), that is told under the list by its address, that loads the address as the Source at once ("Load
...               from the web": the button under the list, the menu and a double click), that the window that saves has a fifth choice for
...               (Web address), and that never has a sample -- see docs/25_workspace.md. The addresses that are loaded are served by a
...               server on 127.0.0.1 that the cases start and that writes down what it is asked for; the folder is read from Python before
...               and after, the bytes of a `.url` file as well (a CR LF is not one line end to the text reader).
Resource          ../../resources/workspace.resource
Library           OperatingSystem
Force Tags        workspace    urls
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Workspace App    files=${WITH_URLS}
Test Teardown     Stop Server And Close App

*** Variables ***
# The Save window is told by a line of its own (its title is dim when it is not the one with the focus).
${SAVE_TITLE}             new folder in it
${NO_ADDRESS_MESSAGE}     There is no web address in it
# The tag of a web address (the fill of the dark theme), of a document and of a jq query.
@{URL_TAG}                84     76     0
@{DOC_TAG}                56     56     56
@{JQ_TAG}                 31     53     85
# The name that the window that saves starts with, for an address, and the address: the last part of the path without .json,
# .ndjson or .jsonl, else the host without who it is for and the port; what a name may not have is a `-`.
@{DEFAULT_NAMES}          https://example.com/v1/orders.json    orders
...                       https://example.com/data/Feed.NDJSON    Feed
...                       https://example.com/a/b/    b
...                       https://example.com/events.jsonl?page=2#top    events
...                       http://user:secret@host.example:8080/    host.example
...                       https://example.com    example.com
...                       https://example.com/x:y.json    x-y
...                       https://example.com/readme    readme

*** Test Cases ***
TC-WSP-292 A Web Address Has A Yellow Tag That Says url
    [Documentation]    The tag at the right of a row says what the item is: a web address has an olive one of its own (84, 76, 0, in the dark
    ...    theme) that says `url` and is as wide as that makes it (19 points; the tag of a document, `json`, is 24 wide and that of a jq
    ...    query, `jq`, 15), and no other item has that colour.
    [Tags]    p1
    # Rows: 0 Logs ... 5 update, 6 Sources, 7 rates (url), 8 data (json), 9 scratch (jq), 10 weather (url).
    Row Should Have Tag Colour    ${ROW_RATES}    @{URL_TAG}
    Row Should Have Tag Colour    ${ROW_WEATHER}    @{URL_TAG}
    Row Should Not Have Tag Colour    ${ROW_RATES}    @{DOC_TAG}
    Row Should Not Have Tag Colour    ${ROW_RATES}    @{JQ_TAG}
    Row Should Not Have Tag Colour    ${ROW_DATA}    @{URL_TAG}
    Row Should Not Have Tag Colour    ${ROW_SCRATCH_WITH_URLS}    @{URL_TAG}
    Row Should Not Have Tag Colour    ${ROW_ORDERS}    @{URL_TAG}
    ${y}=    Row Y    ${ROW_RATES}
    Region Should Show Text    170    ${{ ${y} - 8 }}    80    16    url
    ${url}=    Tag Width    ${ROW_RATES}    @{URL_TAG}
    ${json}=    Tag Width    ${ROW_DATA}    @{DOC_TAG}
    ${jq}=    Tag Width    ${ROW_SCRATCH_WITH_URLS}    @{JQ_TAG}
    Should Be True    17 <= ${url} <= 21    msg=The tag of a web address is ${url} wide, not 19
    Should Be True    ${jq} < ${url} < ${json}    msg=The tags are ${jq} (jq), ${url} (url) and ${json} (json) wide

TC-WSP-293 The Sixth Chip Is URLs, After Docs, And Narrows The List To The Web Addresses
    [Documentation]    All, Queries, Schemas, Patches, Docs and URLs, in that order. With URLs picked the list has the web addresses and
    ...    the folder that has one, and nothing else; no other chip shows a web address, and All does.
    [Tags]    p1
    ${docs}    ${y}=    Find Text In Region    0    70    256    24    Docs
    ${urls}    ${y}=    Find Text In Region    0    70    256    24    URL
    Should Be True    ${docs} + 20 < ${urls}    msg=The URLs chip (${urls}) is not after the Docs chip (${docs})
    Should Be True    ${WS_CHIP_URLS_X} - 8 <= ${urls} <= ${WS_CHIP_URLS_X} + 8    msg=The URLs chip is at ${urls}
    Chip At Should Be Picked    ${WS_CHIP_ALL_X}
    Chip At Should Not Be Picked    ${WS_CHIP_URLS_X}
    Click Chip    urls
    Chip At Should Be Picked    ${WS_CHIP_URLS_X}
    Chip At Should Not Be Picked    ${WS_CHIP_ALL_X}
    List Should Show    Sources    rates    weather
    List Should Not Show    Logs    Services    orders    update    logins    scratch    data
    Click Chip    queries
    List Should Show    logins    scratch
    List Should Not Show    rates    weather    Sources
    Click Chip    docs
    List Should Show    data
    List Should Not Show    rates    weather    Sources
    Click Chip    schemas
    List Should Show    orders
    List Should Not Show    rates    weather
    Click Chip    patches
    List Should Show    update
    List Should Not Show    rates    weather
    Click Chip    all
    List Should Show    rates    weather    data    scratch    orders

TC-WSP-294 The URLs Chip And A Filter Narrow The List Together
    [Tags]    p2
    Click Chip    urls
    Type In Filter    wea
    List Should Show    weather
    List Should Not Show    rates    Sources
    Type In Filter    rat
    List Should Show    Sources    rates
    List Should Not Show    weather

TC-WSP-295 The URLs Chip Of A Workspace That Has No Web Address Says So
    [Tags]    p3
    Close Jsonquery App
    Launch Workspace App
    Click Chip    urls
    List Should Not Show    Logs    Services    scratch    orders
    Wait Until Region Matches    @{WS_LIST}    Nothing here    timeout=4

TC-WSP-296 The Details Of A Web Address Say Where It Is, Its Address And That It Is One, And Have One Button
    [Documentation]    Under the list: the name, the file, the address on a line of its own (where a query has its first lines), `Web address`
    ...    where an item would be told to have a sample or not, and the button that loads it -- the one button: there is no `with sample`.
    [Tags]    p1
    Click Row    ${ROW_RATES}
    Row Should Be Selected    ${ROW_RATES}
    Details Should Show    rates    Sources/rates.url    Load from the web
    Details Should Match    example.{0,3}com/data/rat
    Details Should Match    [Ww]eb ?add
    Details Should Not Show    InternetShortcut    No sample    Sample:    with sample    Open as
    Details Should Have One Button Saying    Load from the web
    # The next one the same, and what it said of the first is not said of it.
    Click Row    ${ROW_WEATHER}
    Details Should Show    weather    weather.url    Load from the web
    Details Should Match    example.{0,3}org/weather
    Details Should Not Show    rates    example.com

TC-WSP-297 A Web Address With A Sample File Beside It Has No Sample
    [Documentation]    A file that is called after a web address and that no query, schema or patch has the name of is nobody's sample: the row has
    ...    no paperclip (its tag ends where the tag of an item with no sample does), the details do not say `Sample:` and have one button,
    ...    the index keeps no sample for it, and the file is left where it is.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${URL_BESIDE_SAMPLE}
    # Rows: 0 Feeds, 1 orders (url), 2 scratch (jq).
    ${item}=    Workspace Item    Feeds/orders.url
    Dictionary Should Not Contain Key    ${item}    sample
    Row Should Have No Paperclip    1    @{URL_TAG}
    ${url_edge}=    Tag Right Edge    1    @{URL_TAG}
    ${jq_edge}=    Tag Right Edge    2    @{JQ_TAG}
    Should Be Equal As Integers    ${url_edge}    ${jq_edge}    msg=The tags end at ${url_edge} (url) and ${jq_edge} (jq, no sample)
    Click Row    1
    Details Should Show    orders    Feeds/orders.url
    Details Should Match    [Ww]eb ?add
    Details Should Not Show    Sample
    Details Should Have One Button Saying    Load from the web
    Workspace File Should Be    Feeds/orders.sample.json    [{"id": 1}, {"id": 2}]

TC-WSP-298 A Query And A Web Address Of One Name: The Sample Is The Query's
    [Documentation]    Two items called orders in one folder, as an item and a schema may be: the sample file is the query's (a paperclip, a
    ...    `Sample:` line, and the index has it) and the web address has none.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${URL_AND_QUERY}
    # Rows: 0 Archive, 1 notes, 2 Data, 3 orders (the query), 4 orders (the web address).
    Row Should Have A Paperclip    3    @{JQ_TAG}
    Row Should Have No Paperclip    4    @{URL_TAG}
    Click Row    3
    Details Should Match    Sam[pq]le: orders
    Click Row    4
    Details Should Match    [Ww]eb ?add
    Details Should Not Show    Sample
    ${query}=    Workspace Item    Data/orders.jq
    ${url}=    Workspace Item    Data/orders.url
    Dictionary Should Contain Key    ${query}    sample
    Dictionary Should Not Contain Key    ${url}    sample

TC-WSP-299 The Menu Of A Web Address Has Load From The Web Where Other Items Have Open
    [Documentation]    Load from the web, Rename, Duplicate, Move to, Copy text, Show in the file manager and Delete: no Open, and no
    ...    entry for a sample.
    [Tags]    p1
    Row Menu Should Offer    ${ROW_RATES}    Load from the web    Rename    Duplicate    Move to    Copy text    file manager    Delete
    Row Menu Should Not Offer    ${ROW_RATES}    Open    with sample    Use as    Import    Export

TC-WSP-300 The Menu Of A Folder Has Save A Web Address Here Beside Save The Query Here
    [Tags]    p1
    Row Menu Should Offer    ${ROW_SERVICES}    Save the query here    Save a web address here    New folder    Rename    Move to    Import into this    Export this folder    file manager    Delete

TC-WSP-301 Save A Web Address Here Opens The Window On The Web Address Choice, For That Folder
    [Documentation]    The choice that says Web address is the one that is picked, the box for the address is empty and has the focus (what is
    ...    typed goes in it), and what is saved is in the folder whose menu was used.
    [Tags]    p1
    Set Form Kind    save
    Pick Row Menu Item    ${ROW_SERVICES}    Save a web address here
    Form Should Be Open    ${SAVE_TITLE}
    Tab Of The Save Window Should Be Picked    ${SAVE_TAB_URL_X}
    Tab Of The Save Window Should Not Be Picked    ${SAVE_TAB_QUERY_X}
    Type Text    https://example.org/prices.json
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    Saved as Services/prices.url
    Press Key    enter
    Sleep    0.9s
    Form Should Not Be Open    ${SAVE_TITLE}
    Workspace File Should Hold Bytes    Services/prices.url    [InternetShortcut]\r\nURL=https://example.org/prices.json\r\n
    List Should Show    prices
    Details Should Show    prices    Services/prices.url

TC-WSP-302 Copy Text Of A Web Address Copies The Address And Not The File
    [Documentation]    The clipboard has the address as it is written, with no `[InternetShortcut]`, no `URL=` and no line end.
    [Tags]    p1
    Set Clipboard    nothing was copied
    Pick Row Menu Item    ${ROW_RATES}    Copy text
    Clipboard Should Be    ${RATES_ADDRESS}
    Set Clipboard    nothing was copied
    Pick Row Menu Item    ${ROW_WEATHER}    Copy text
    Clipboard Should Be    ${WEATHER_ADDRESS}

TC-WSP-303 A Shortcut That Another Program Wrote Is Read Whatever Way It Was Written
    [Documentation]    Eleven files, each written another way (a line that is only the address, a byte-order mark, CR LF, other keys and sections
    ...    round it, two `URL` lines, LF alone, `url=` in small letters, a section that is not `[InternetShortcut]`, spaces round the key and
    ...    the address, `.URL` in capitals, the scheme in capitals, and a byte-order mark in front of a bare address): every one is listed with the tag of a web address, and its text is the address
    ...    that the first `URL` line has (a file that is one line is that line), as it was written.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${SHAPE_FILES}
    ${row}=    Set Variable    ${0}
    FOR    ${name}    ${pair}    IN    &{SHAPES}
        Row Should Have Tag Colour    ${row}    @{URL_TAG}
        Set Clipboard    nothing was copied
        Pick Row Menu Item    ${row}    Copy text
        Clipboard Should Be    ${pair}[1]
        ${row}=    Evaluate    ${row} + 1
    END

TC-WSP-304 A File That Holds No Address Is Listed, And Its Copy Text Says So And Copies Nothing
    [Documentation]    Eight files that look like a shortcut and are not one (nothing in it, words, `ftp://`, no scheme, a space in the address,
    ...    no host, no `URL` line, 4097 characters): each is listed as a web address all the same (the end of its name says what it is), and
    ...    what is said under the list is `There is no web address in it` -- the clipboard is left as it was.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${NO_ADDRESS}
    FOR    ${row}    IN RANGE    8
        Row Should Have Tag Colour    ${row}    @{URL_TAG}
        Set Clipboard    nothing was copied
        Pick Row Menu Item    ${row}    Copy text
        Sleep    0.6s
        Clipboard Should Be    nothing was copied
        IF    ${row} == 0
            Notice Should Say    ${NO_ADDRESS_MESSAGE}
        END
    END

TC-WSP-305 An Address Of 4096 Characters Is One And An Address Of 4097 Is Not
    [Tags]    p3
    Close Jsonquery App
    Launch Workspace App    files=${EDGE_FILES}
    Set Clipboard    nothing was copied
    Pick Row Menu Item    0    Copy text
    Clipboard Should Be    ${EDGE_ADDRESS}
    Set Clipboard    nothing was copied
    Pick Row Menu Item    1    Copy text
    Sleep    0.6s
    Clipboard Should Be    nothing was copied
    Notice Should Say    ${NO_ADDRESS_MESSAGE}

TC-WSP-306 Load From The Web Loads The Address Into The Source At Once
    [Documentation]    A click on the item only picks it and asks for nothing; the button under the list loads the address as if it had been
    ...    typed in the Source field and Load pressed: the server is asked once, for the path of the address, the field holds the address, the
    ...    document is the Source (its first row says how many items it has) and the status bar says it was parsed.
    [Tags]    p1
    Close Jsonquery App
    ${base}=    Launch With Web Addresses    ${SERVED}    ${{ {"Sources/feed.url": "/valid.json"} }}
    # Rows: 0 Logs ... 5 update, 6 Sources, 7 feed, 8 scratch.
    Click Row    ${ROW_RATES}
    Details Should Show    feed    Sources/feed.url    Load from the web
    Source Field Should Be Empty
    Fixture Server Should Have Been Asked For
    Press Load From The Web
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    3 items    timeout=8
    Source Field Should Hold    ${base}/valid.json
    Fixture Server Should Have Been Asked For    /valid.json
    Status Line Should Match    Parsed
    Region Should Not Contain Text    @{WS_STATUS_LINE}    Load error

TC-WSP-307 A Double Click And The Menu's Load From The Web Load It Too
    [Documentation]    The same load by the other two ways: each item loads its own address (the second replaces the first document), and
    ...    the server is asked for the two, in that order, once each.
    [Tags]    p1
    Close Jsonquery App
    ${base}=    Launch With Web Addresses    ${SERVED}    ${{ {"Sources/a feed.url": "/valid.json", "Sources/b orders.url": "/v1/orders.json"} }}
    # Rows: ... 6 Sources, 7 a feed, 8 b orders, 9 scratch.
    Double Click Row    7
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    3 items    timeout=8
    Source Field Should Hold    ${base}/valid.json
    Pick Row Menu Item    8    Load from the web
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    orders    timeout=8
    Source Field Should Hold    ${base}/v1/orders.json
    Fixture Server Should Have Been Asked For    /valid.json    /v1/orders.json

TC-WSP-308 The Whole Address Is Asked For, Its Path And Its Query
    [Tags]    p1
    Close Jsonquery App
    ${base}=    Launch With Web Addresses    ${SERVED}    ${{ {"Sources/orders.url": "/v1/orders.json?page=2&sort=id"} }}
    Double Click Row    ${ROW_RATES}
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    orders    timeout=8
    Source Field Should Hold    ${base}/v1/orders.json?page=2&sort=id
    Fixture Server Should Have Been Asked For    /v1/orders.json?page=2&sort=id

TC-WSP-309 An Address That The Server Answers With 404 Is Said In The Status Bar And Stays In The Source Field
    [Documentation]    As for an address that is typed in the Source field: the message says what was asked and the status, the field keeps the
    ...    address (to be corrected), and there is no document.
    [Tags]    p1
    Close Jsonquery App
    ${base}=    Launch With Web Addresses    ${SERVED}    ${{ {"Sources/missing.url": "/missing.json"} }}
    Double Click Row    ${ROW_RATES}
    Status Line Should Match    Load error.{0,3} ?requesting.*404
    Source Field Should Hold    ${base}/missing.json
    Fixture Server Should Have Been Asked For    /missing.json
    Region Should Contain Text    @{WS_SOURCE_PANEL}    Drag

TC-WSP-310 A Response That Is Not JSON And A Server That Is Not There Are Said Too
    [Tags]    p2
    Close Jsonquery App
    ${down}=    Shortcut Text    http://127.0.0.1:1/x.json
    ${files}=    Evaluate    {**$STANDARD, "Sources/b down.url": $down}
    ${base}=    Launch With Web Addresses    ${SERVED}    ${{ {"Sources/a text.url": "/invalid.txt"} }}    files=${files}
    # Rows: ... 6 Sources, 7 a text, 8 b down, 9 scratch.
    Double Click Row    7
    Status Line Should Match    Load error.*parsing JSON
    Source Field Should Hold    ${base}/invalid.txt
    Double Click Row    8
    Status Line Should Match    Load error.*Connection refused
    Source Field Should Hold    http://127.0.0.1:1/x.json
    Region Should Contain Text    @{WS_SOURCE_PANEL}    Drag

TC-WSP-311 A File That Holds No Address Loads Nothing And Is Said Under The List
    [Documentation]    Each of the eight files of TC-WSP-304, opened by a double click: nothing is loaded and nothing is asked of any server,
    ...    the Source field stays empty and the status bar says no more than it did, and under the list is said that there is no address.
    [Tags]    p1
    Close Jsonquery App
    ${base}=    Serve These Files    ${SERVED}
    Launch Workspace App    files=${NO_ADDRESS}
    FOR    ${row}    IN RANGE    8
        Double Click Row    ${row}
        Sleep    0.5s
        IF    ${row} == 0
            Notice Should Say    ${NO_ADDRESS_MESSAGE}
        END
        Source Field Should Be Empty
    END
    Region Should Not Contain Text    @{WS_STATUS_LINE}    Load error
    Region Should Contain Text    @{WS_SOURCE_PANEL}    Drag
    Fixture Server Should Have Been Asked For

TC-WSP-312 A Shortcut With A Byte-Order Mark, A Lower-Case Key And Line Feeds Loads, And So Does A File That Is Only The Address
    [Tags]    p2
    Close Jsonquery App
    ${base}=    Serve These Files    ${SERVED}
    ${shortcut}=    Evaluate    "\\ufeff[InternetShortcut]\\nurl=" + $base + "/valid.json\\n"
    ${bare}=    Evaluate    $base + "/v1/orders.json\\n"
    ${files}=    Evaluate    {**$STANDARD, "Sources/a other tool.url": $shortcut, "Sources/b bare.url": $bare}
    Launch Workspace App    files=${files}
    Double Click Row    7
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    3 items    timeout=8
    Source Field Should Hold    ${base}/valid.json
    Double Click Row    8
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    orders    timeout=8
    Source Field Should Hold    ${base}/v1/orders.json
    Fixture Server Should Have Been Asked For    /valid.json    /v1/orders.json

TC-WSP-313 A Web Address That Is Loaded Replaces The Document That Was Open And Leaves What Is In The Query Box
    [Tags]    p2
    Close Jsonquery App
    ${base}=    Launch With Web Addresses    ${SERVED}    ${{ {"Sources/feed.url": "/other.json"} }}
    Paste In Source    {"old": true}
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    old    timeout=5
    Type In Query Box    .alpha
    Double Click Row    ${ROW_RATES}
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    alpha    timeout=8
    Region Should Not Show Text    @{WS_SOURCE_PANEL}    old
    Query Box Should Hold    .alpha

TC-WSP-314 The Save Window Has A Fifth Choice, Web Address, That Can Always Be Picked
    [Documentation]    With nothing in the boxes of the window the choices for a schema, a patch and the Source are dim; a web address is typed in
    ...    the window, so its choice is not. Picked, the window has a box for the address above the name, and the tick that keeps a sample is gone.
    [Tags]    p1
    Open Save Form
    Save Choice Should Be Dim    ${SAVE_TAB_SCHEMA_X}
    Save Choice Should Be Dim    ${SAVE_TAB_PATCH_X}
    Save Choice Should Be Dim    ${SAVE_TAB_SOURCE_X}
    Save Choice Should Be Bright    ${SAVE_TAB_URL_X}
    Choose Web Address In Save Form
    # (The labels are read in a crop of their own: with the Tools docked the Name label is on the line of the text behind the window, and a
    # crop that has both reads them as one line.)
    ${y}=    Form Y    143
    Wait Until Keyword Succeeds    4x    0.4s    Region Should Contain Text    400    ${y}    120    20    Web address
    ${y}=    Form Y    183
    Region Should Contain Text    400    ${y}    120    20    Name
    Form Should Show    Folder    new folder in it
    Form Should Not Show    sample
    Form Should Have This Many Buttons    2

TC-WSP-315 A Document That Was Loaded From The Web Offers Its Address, Whatever Is Typed In The Source Field After
    [Documentation]    The box starts with the address of the open document, and the name with what that address gives; an address that was typed in the
    ...    Source field since and not loaded is not the document's.
    [Tags]    p1
    Close Jsonquery App
    ${base}=    Launch With Web Addresses    ${SERVED}    ${{ {"Sources/feed.url": "/v1/orders.json"} }}
    Double Click Row    ${ROW_RATES}
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    orders    timeout=8
    Open Save Form On Web Address
    Address In Save Form Should Be    ${base}/v1/orders.json
    Name In Save Form Should Be    orders
    # (The folder is the one that the picked item is in.)
    Form Should Show    Saved as Sources/orders.url
    Press Key    escape
    Sleep    0.6s
    Click At    ${WS_SOURCE_FIELD_X}    ${TOOLBAR_Y}
    Press Keys    ctrl    a
    Type Text    https://example.com/typed.json
    Open Save Form On Web Address
    Address In Save Form Should Be    ${base}/v1/orders.json
    Name In Save Form Should Be    orders

TC-WSP-316 An Address Typed In The Source Field And Not Loaded Is Offered, And A Path Is Not
    [Tags]    p1
    Click At    ${WS_SOURCE_FIELD_X}    ${TOOLBAR_Y}
    Type Text    https://example.com/data/people.json
    Open Save Form On Web Address
    Address In Save Form Should Be    https://example.com/data/people.json
    Name In Save Form Should Be    people
    Press Key    enter
    Sleep    0.9s
    Workspace File Should Hold Bytes    people.url    [InternetShortcut]\r\nURL=https://example.com/data/people.json\r\n
    Source Field Should Hold    https://example.com/data/people.json
    # A path is not a web address: the box is empty.
    Click At    ${WS_SOURCE_FIELD_X}    ${TOOLBAR_Y}
    Press Keys    ctrl    a
    Type Text    /home/me/data/people.json
    Open Save Form On Web Address
    Address In Save Form Should Be Empty

TC-WSP-317 With Nothing To Offer The Box Is Empty And Has The Focus, And What Is Typed Is Saved As The Lines Of A Shortcut
    [Documentation]    Nothing is clicked between the choice and the typing: the box for the address has the focus. The name follows the address, the
    ...    file is exactly `[InternetShortcut]`, CR LF, `URL=` and the address, CR LF (no byte-order mark), the item is picked and said to be
    ...    saved, its id and SHA-256 are in the index, and no sample is.
    [Tags]    p1
    Open Save Form On Web Address
    Type Text    https://example.org/v2/prices.json
    Address In Save Form Should Be    https://example.org/v2/prices.json
    Name In Save Form Should Be    prices
    Form Should Show    Saved as prices.url
    Press Key    enter
    Sleep    0.9s
    Form Should Not Be Open    ${SAVE_TITLE}
    ${text}=    Shortcut Text    https://example.org/v2/prices.json
    Workspace File Should Hold Bytes    prices.url    ${text}
    ${item}=    Workspace Item    prices.url
    ${sha}=    Sha256 Of Text    ${text}
    Should Be Equal    ${item}[sha256]    ${sha}
    Should Be Equal As Integers    ${item}[bytes]    ${{ len($text) }}
    Should Match Regexp    ${item}[id]    ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$
    Dictionary Should Not Contain Key    ${item}    sample
    ${expected}=    Evaluate    sorted(list($STANDARD) + ["data.json", "Sources/rates.url", "weather.url", "prices.url"])
    Workspace Files Should Be    ${expected}
    List Should Show    prices
    Details Should Show    prices    prices.url
    Notice Should Say    Saved

TC-WSP-318 The Name Follows The Address Until A Name Is Typed
    [Documentation]    The name is made from the address each time the address changes, until a name is typed; a name that was emptied is made
    ...    from the address again; Enter in the box for the address saves (the typed name is the file's).
    [Tags]    p1
    Open Save Form On Web Address
    Type Text    https://example.org/a/first.json
    Name In Save Form Should Be    first
    Paste In Address Box    https://example.org/a/second.json
    Name In Save Form Should Be    second
    Type Name In Url Form    mine
    Paste In Address Box    https://example.org/a/third.json
    Name In Save Form Should Be    mine
    Click In Form    ${SAVE_NAME_X}    ${SAVE_URL_NAME_Y}
    Press Keys    ctrl    a
    Press Key    delete
    Paste In Address Box    https://example.org/a/fourth.json
    Name In Save Form Should Be    fourth
    Type Name In Url Form    mine
    Paste In Address Box    https://example.org/a/fifth.json
    Press Key    enter
    Sleep    0.9s
    Form Should Not Be Open    ${SAVE_TITLE}
    ${text}=    Shortcut Text    https://example.org/a/fifth.json
    Workspace File Should Hold Bytes    mine.url    ${text}
    Workspace File Should Not Exist    first.url
    Workspace File Should Not Exist    fourth.url

TC-WSP-319 The Name Starts As The Last Part Of The Address Without .json, Or As The Host
    [Documentation]    The last part of the path that is not empty, without `.json`, `.ndjson` or `.jsonl` (in any case) and without the query
    ...    and the fragment; where there is none, the host without who it is for and without the port; what a name may not have becomes `-`.
    [Tags]    p2
    Open Save Form On Web Address
    FOR    ${address}    ${name}    IN    @{DEFAULT_NAMES}
        Paste In Address Box    ${address}
        Name In Save Form Should Be    ${name}
    END
    Press Key    escape

TC-WSP-320 An Address That Is Not One Is Said In Red And Cannot Be Saved
    [Documentation]    Five things that are not a web address (no scheme, `ftp://`, no host, a space in it, `javascript:`): each is said under the box, and
    ...    neither Enter nor the Save button saves it, though the name is good; a good address saves.
    [Tags]    p1
    Open Save Form On Web Address
    Paste In Address Box    https://example.org/ok.json
    Type Name In Url Form    nope
    FOR    ${bad}    IN    example.com/a.json    ftp://example.com/a.json    https://    https://exa mple.com    javascript:alert(1)
        Paste In Address Box    ${bad}
        Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    not a web address
        Press Key    enter
        Sleep    0.5s
        Press Primary Button
        Sleep    0.4s
        Form Should Be Open    ${SAVE_TITLE}
        Form Should Show    not a web address
        Form Should Not Show    nothing to save
        Workspace File Should Not Exist    nope.url
    END
    Paste In Address Box    https://example.org/ok.json
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Not Show    not a web address
    Press Key    enter
    Sleep    0.9s
    ${text}=    Shortcut Text    https://example.org/ok.json
    Workspace File Should Hold Bytes    nope.url    ${text}

TC-WSP-321 An Address Of 4096 Characters Can Be Saved And One Of 4097 Cannot
    [Tags]    p3
    Open Save Form On Web Address
    Paste In Address Box    ${OVER_ADDRESS}
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    not a web address
    Paste In Address Box    ${EDGE_ADDRESS}
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Not Show    not a web address
    Type Name In Url Form    edge
    Press Key    enter
    Sleep    1.0s
    ${text}=    Shortcut Text    ${EDGE_ADDRESS}
    Workspace File Should Hold Bytes    edge.url    ${text}

TC-WSP-322 A Name That Is Taken Asks To Replace And Replacing Keeps The Id
    [Documentation]    The button says Replace and the window says that saving replaces the web address that is there; the file is the new text, and
    ...    the item is the same item: its id is kept, its SHA-256 is the new text's.
    [Tags]    p1
    ${before}=    Workspace Item    weather.url
    Open Save Form On Web Address
    Paste In Address Box    http://example.org/forecast.json
    Type Name In Url Form    weather
    Wait Until Keyword Succeeds    4x    0.5s    Form Should Show    web address of that    replaces it    Replace
    Primary Button Should Be This Wide    45    65
    Press Key    enter
    Sleep    0.9s
    ${text}=    Shortcut Text    http://example.org/forecast.json
    Workspace File Should Hold Bytes    weather.url    ${text}
    ${after}=    Workspace Item    weather.url
    Should Be Equal    ${after}[id]    ${before}[id]
    ${sha}=    Sha256 Of Text    ${text}
    Should Be Equal    ${after}[sha256]    ${sha}
    Should Not Be Equal    ${after}[sha256]    ${before}[sha256]
    Workspace File Should Not Exist    weather (2).url

TC-WSP-323 The Window Offers No Sample For A Web Address, Though A Document Is Open, And None Is Written
    [Documentation]    With a query in the box and the document open the window offers to keep the Source as the sample; with the Web address picked
    ...    that offer is gone, the address offered is the document's, and what is written is the one file.
    [Tags]    p1
    Close Jsonquery App
    ${base}=    Launch With Web Addresses    ${SERVED}    ${{ {"Sources/feed.url": "/valid.json"} }}
    Double Click Row    ${ROW_RATES}
    Wait Until Region Matches    @{WS_SOURCE_PANEL}    3 items    timeout=8
    Type In Query Box    .[0]
    Open Save Form
    Form Should Show    Keep the Source as its sample
    Choose Web Address In Save Form
    Form Should Not Show    Keep the Source    its sample
    Address In Save Form Should Be    ${base}/valid.json
    Type Name In Url Form    nosample
    Press Key    enter
    # (in the folder of the item that is picked)
    Wait Until Workspace File Exists    Sources/nosample.url    timeout=8
    Sleep    1.5s
    ${expected}=    Evaluate    sorted(list($STANDARD) + ["Sources/feed.url", "Sources/nosample.url"])
    Workspace Files Should Be    ${expected}

TC-WSP-324 Renaming A Web Address Leaves The Sample Of The Items Of Its Name Where It Is
    [Documentation]    orders is a query and a web address in one folder, and the sample is the query's: the address is renamed with its id and takes no
    ...    sample along (nor is one made for the new name), and the query keeps its sample. A name that ends like another sort of item
    ...    (`data.json`) is a name for an address.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${URL_AND_QUERY}
    # Rows: 0 Archive, 1 notes, 2 Data, 3 orders (the query), 4 orders (the web address).
    ${text}=    Shortcut Text    ${ORDERS_ADDRESS}
    ${before}=    Workspace Item    Data/orders.url
    Rename Row To    4    rates
    Workspace File Should Hold Bytes    Data/rates.url    ${text}
    Workspace File Should Not Exist    Data/orders.url
    Workspace File Should Be    Data/orders.sample.json    [{"id": 1}, {"id": 2}]
    Workspace File Should Not Exist    Data/rates.sample.json
    ${after}=    Workspace Item    Data/rates.url
    Should Be Equal    ${after}[id]    ${before}[id]
    ${query}=    Workspace Item    Data/orders.jq
    Dictionary Should Contain Key    ${query}    sample
    Rename Row To    4    data.json
    Workspace File Should Hold Bytes    Data/data.json.url    ${text}
    Workspace File Should Not Exist    Data/rates.url

TC-WSP-325 Renaming A Query Takes Its Sample With It Though A Web Address Has The Same Name
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${URL_AND_QUERY}
    ${text}=    Shortcut Text    ${ORDERS_ADDRESS}
    Rename Row To    3    fresh
    Workspace File Should Be    Data/fresh.jq    .[0]
    Workspace File Should Be    Data/fresh.sample.json    [{"id": 1}, {"id": 2}]
    Workspace File Should Not Exist    Data/orders.sample.json
    Workspace File Should Hold Bytes    Data/orders.url    ${text}

TC-WSP-326 Deleting A Query Deletes Its Sample Though A Web Address Has The Same Name
    [Documentation]    The web address does not keep the sample alive: it goes with the query, and the address stays.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${URL_AND_QUERY}
    ${text}=    Shortcut Text    ${ORDERS_ADDRESS}
    Open Delete Form    3
    Form Should Match    sample goes
    Press Primary Button
    Workspace File Should Not Exist    Data/orders.jq
    Workspace File Should Not Exist    Data/orders.sample.json
    Workspace File Should Hold Bytes    Data/orders.url    ${text}
    Notice Should Say    Deleted

TC-WSP-327 Deleting A Web Address Deletes No Sample, And The Window Says None Goes With It
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${URL_AND_QUERY}
    Open Delete Form    4
    Form Should Show    orders    cannot be undone
    Form Should Not Show    sample
    Press Primary Button
    Workspace File Should Not Exist    Data/orders.url
    Workspace File Should Be    Data/orders.jq    .[0]
    Workspace File Should Be    Data/orders.sample.json    [{"id": 1}, {"id": 2}]
    Row Should Have A Paperclip    3    @{JQ_TAG}
    ${index}=    Workspace Index
    Dictionary Should Not Contain Key    ${index}[items]    Data/orders.url

TC-WSP-328 Moving A Web Address By Dragging Does Not Take The Sample Of Its Name Along, And Is Not Stopped By One
    [Documentation]    The address is dropped on Archive: it goes there with its id, the sample of the query stays in Data, and the sample file that is
    ...    already in Archive (nobody's: a query or a schema of that name would have been refused) is not touched.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${URL_AND_QUERY_WITH_OTHER_SAMPLE}
    ${text}=    Shortcut Text    ${ORDERS_ADDRESS}
    ${before}=    Workspace Item    Data/orders.url
    Drag Row    4    0
    Workspace File Should Hold Bytes    Archive/orders.url    ${text}
    Workspace File Should Not Exist    Data/orders.url
    Workspace File Should Be    Data/orders.sample.json    [{"id": 1}, {"id": 2}]
    Workspace File Should Be    Archive/orders.sample.json    []
    ${after}=    Workspace Item    Archive/orders.url
    Should Be Equal    ${after}[id]    ${before}[id]
    Dictionary Should Not Contain Key    ${after}    sample
    Notice Should Say    Moved

TC-WSP-329 Duplicating A Web Address Copies The File Alone, Whatever Sample Files Have The Name Of The Copy
    [Documentation]    The copy is called orders (2) though a file `orders (2).sample.json` is in the folder (a query's copy would skip that name), holds
    ...    the same text, has an id of its own, and no sample is made for it or taken from there.
    [Tags]    p1
    Close Jsonquery App
    ${files}=    Evaluate    {**$URL_AND_QUERY, "Data/orders (2).sample.json": "[]"}
    Launch Workspace App    files=${files}
    ${text}=    Shortcut Text    ${ORDERS_ADDRESS}
    ${first}=    Workspace Item    Data/orders.url
    Pick Row Menu Item    4    Duplicate
    Workspace File Should Hold Bytes    Data/orders (2).url    ${text}
    Workspace File Should Not Exist    Data/orders (3).url
    Workspace File Should Be    Data/orders (2).sample.json    []
    Workspace File Should Hold Bytes    Data/orders.url    ${text}
    ${copy}=    Workspace Item    Data/orders (2).url
    Should Not Be Equal    ${copy}[id]    ${first}[id]
    Should Be Equal    ${copy}[sha256]    ${first}[sha256]
    Dictionary Should Not Contain Key    ${copy}    sample
    Notice Should Say    Copied as

TC-WSP-330 An Export Copies The Web Addresses As They Are And No Sample For Them
    [Documentation]    The window counts the web address among the items and no sample among the files; the copy has the bytes of the file, the id and
    ...    SHA-256 it had, and the sample file beside it (nobody's) is not copied.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App    files=${URL_BESIDE_SAMPLE}
    ${out}=    Make Export Folder
    Open Export Form
    Form Should Match    2 items in 1 folder
    Form Should Match    [0O©] ?files
    Export To    ${out}
    Form Should Not Be Open    To the folder
    ${files}=    Files In Folder    ${out}
    Lists Should Be Equal    ${files}    ${{ ["Feeds/orders.url", "scratch.jq"] }}
    ${text}=    Shortcut Text    ${ORDERS_ADDRESS}
    ${bytes}=    Get Binary File    ${out}${/}Feeds${/}orders.url
    Should Be Equal    ${bytes}    ${{ $text.encode("utf-8") }}
    ${mine}=    Workspace Index
    ${theirs}=    Index Of Folder    ${out}
    Compare Indexes    ${mine}    ${theirs}
    Dictionary Should Not Contain Key    ${theirs}[items][Feeds/orders.url]    sample
    Notice Should Say    Exported +[^ ]{1,3} +ite

TC-WSP-331 Import Says How Many Web Addresses A Folder Has And Brings Them In Without A Sample
    [Documentation]    The window says `3 items in 1 folder: 1 query, 2 web addresses`; the items come in, in a new folder, with ids of their own and no
    ...    sample, and the sample file beside them (nobody's) stays where it was.
    [Tags]    p1
    Close Jsonquery App
    Launch Workspace App
    ${incoming}=    Make Folder With Files    incoming    ${INCOMING_URLS}
    Open Import Form
    Type In Import Folder    ${incoming}
    Form Should Match    3 items in 1 folder
    Form Should Match    1 quer[yv], 2 web ?addresses
    Press Primary Button
    Sleep    1.2s
    Form Should Not Be Open    From the folder
    ${rates}=    Shortcut Text    ${RATES_ADDRESS}
    ${weather}=    Shortcut Text    ${WEATHER_ADDRESS}
    Workspace File Should Hold Bytes    incoming/Feeds/rates.url    ${rates}
    Workspace File Should Hold Bytes    incoming/Feeds/weather.url    ${weather}
    Workspace File Should Be    incoming/checks.jq    .checks
    Workspace File Should Not Exist    incoming/Feeds/rates.sample.json
    ${item}=    Workspace Item    incoming/Feeds/rates.url
    Should Match Regexp    ${item}[id]    ^[0-9a-f-]{36}$
    Dictionary Should Not Contain Key    ${item}    sample
    Notice Should Say    Imported +[^ ]{1,3} +ite

TC-WSP-332 An Imported Web Address Whose Name Is Taken Gets The Next Number Though A Sample File Has It
    [Documentation]    Into Data, which has orders (a web address and a query) and a file `orders (2).sample.json` that is nobody's: the web address that
    ...    comes in with that name and other text is kept beside the old one as orders (2), and the old one is as it was.
    [Tags]    p2
    Close Jsonquery App
    ${files}=    Evaluate    {**$URL_AND_QUERY, "Data/orders (2).sample.json": "[]"}
    Launch Workspace App    files=${files}
    ${old}=    Shortcut Text    ${ORDERS_ADDRESS}
    ${new}=    Shortcut Text    ${RATES_ADDRESS}
    ${incoming}=    Make Folder With Files    incoming    ${{ {"orders.url": $new} }}
    Set Form Kind    import
    Pick Row Menu Item    2    Import into
    Form Should Be Open    From the folder
    Type In Import Folder    ${incoming}
    Press In Form    among
    Press Primary Button
    Sleep    1.2s
    Workspace File Should Hold Bytes    Data/orders (2).url    ${new}
    Workspace File Should Not Exist    Data/orders (3).url
    Workspace File Should Hold Bytes    Data/orders.url    ${old}
    Workspace File Should Be    Data/orders (2).sample.json    []
    Notice Should Say    Imported

TC-WSP-338 Web Addresses That Are Exported And Imported Into Another Workspace Come In As The Same Items
    [Documentation]    The index travels with an export: in the other workspace (made empty) the window says what the folder holds, and the items come in with
    ...    the ids and SHA-256s they had, the bytes they had, and no sample.
    [Tags]    p2
    Close Jsonquery App
    Launch Workspace App    files=${WITH_URLS}
    ${out}=    Make Export Folder
    Open Export Form
    Export To    ${out}
    Form Should Not Be Open    To the folder
    ${theirs}=    Index Of Folder    ${out}
    Close Jsonquery App
    Launch Workspace App    files=${NO_FILES}
    Open Import Form
    Type In Import Folder    ${out}
    Form Should Match    8 items in 4 folders
    Form Should Match    2 web ?addresses
    Press Primary Button
    Sleep    1.2s
    Form Should Not Be Open    From the folder
    ${rates}=    Shortcut Text    ${RATES_ADDRESS}
    ${weather}=    Shortcut Text    ${WEATHER_ADDRESS}
    Workspace File Should Hold Bytes    exported/Sources/rates.url    ${rates}
    Workspace File Should Hold Bytes    exported/weather.url    ${weather}
    FOR    ${here}    ${there}    IN    exported/Sources/rates.url    Sources/rates.url    exported/weather.url    weather.url
        ${item}=    Workspace Item    ${here}
        Should Be Equal    ${item}[id]    ${theirs}[items][${there}][id]    msg=${here}: the id changed
        Should Be Equal    ${item}[sha256]    ${theirs}[items][${there}][sha256]    msg=${here}: the SHA-256 changed
        Dictionary Should Not Contain Key    ${item}    sample
    END
