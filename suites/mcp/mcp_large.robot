*** Settings ***
Documentation     A document too big for a page, asked for whole as a model asks for it -- see docs/26_mcp_server.md.
...
...               A model that wants a document asks for all of it as often as not: read_value with no pointer,
...               run_query ".", format_json, the results the user sees, a workspace item. A big one would not fit in
...               its context. So an answer gives at most a page: a snippet of the value, and the member `snippet`
...               that says so, in the same words in every tool -- that the value is large and how large, the arrays
...               in it with how many items each has and how many are given, and `next`, the call that reads on. These
...               cases are the whole path, over HTTP and through jsonquery-mcp, against the running app; the finer
...               cases are the server's and the app's unit tests.
...
...               The crowd, in the workspace of each app: 5000 people (about 320 KB), as a list (list.json) and inside
...               an object (crowd.json), whose sample is 3000 of them; a file too big for a page that is not JSON
...               (broken.json); and a list whose last item is too big for a page alone (tail.json).
Resource          ../../resources/mcp.resource
Library           Collections
Library           OperatingSystem
Force Tags        mcp    undocked-only
Suite Setup       Make The Crowd
Suite Teardown    Stop Test Display
Test Setup        Launch Mcp App Serving    workspace=${CROWD}
Test Teardown     Close Jsonquery App

*** Test Cases ***
TC-MCP-116 A Large Array Asked For Whole Gives A Page, Says It Is A Snippet, And Says How To Read On
    [Documentation]    read_value with no pointer: the first page of the list, and the notice -- large (the file's
    ...    size, a quarter of it in tokens), an array of 5000 items of which 20 are given, a snippet -- whose `next`
    ...    gives the next page.
    [Tags]    p1
    Open The Crowd    list.json
    ${out}=    Mcp Tool Should Succeed    read_value    {}
    Length Should Be    ${out}[items]    20
    ${notice}=    Snippet Notice Should Be    ${out}    items
    Should Contain    ${notice}[note]    It holds arrays: the biggest, at "" (the top), has 5000 items, 20 of them given here.
    ${path}=    Workspace Folder    crowd/list.json
    ${size}=    Get File Size    ${path}
    Should Be Equal As Integers    ${notice}[bytes]    ${size}
    ${tokens}=    Evaluate    $size // 4
    Should Be Equal As Integers    ${notice}[tokens_about]    ${tokens}
    Should Be Equal    ${notice}[arrays][0]    ${{ {"pointer": "", "items": 5000, "given": 20, "next_offset": 20} }}
    Should Be Equal    ${notice}[next]
    ...    ${{ {"tool": "read_value", "arguments": {"input": "document", "pointer": "", "offset": 20}} }}
    ${on}=    Follow Next    ${notice}
    Should Be Equal As Integers    ${on}[items][0][id]    20

TC-MCP-117 run_query "." Of A Large Document Gives It Cut Down, Kept As last To Read On
    [Documentation]    The whole document as one result: its small part whole, its array's first people and a $more
    ...    that says where the rest are; the results are kept as "last", where `next` reads on.
    [Tags]    p1
    Open The Crowd    crowd.json
    ${out}=    Mcp Tool Should Succeed    run_query    {"query": "."}
    Should Be Equal    ${out}[items][0][meta]    ${{ {"source": "test"} }}
    Should Be Equal As Integers    ${out}[items][0][people][0][id]    0
    ${more}=    Set Variable    ${out}[items][0][people][-1]
    Should Be Equal    ${more}[pointer]    /0/people
    ${notice}=    Snippet Notice Should Be    ${out}    items
    Should Be Equal    ${notice}[next][arguments][input]    last
    Should Be Equal    ${notice}[next][arguments][pointer]    /0/people
    Should Be Equal As Integers    ${notice}[next][arguments][offset]    ${more}[offset]
    ${on}=    Follow Next    ${notice}
    Should Be Equal As Integers    ${on}[items][0][id]    ${more}[offset]

TC-MCP-118 format_json Of A Large Document Gives A Snippet Of It Formatted, Which Is JSON
    [Documentation]    Not the first bytes of the text, cut anywhere: the snippet, formatted, with what it leaves out
    ...    written in its place -- and the notice says that save_file writes all of it.
    [Tags]    p1
    Open The Crowd    crowd.json
    ${out}=    Mcp Tool Should Succeed    format_json    {"input": "document", "indent": 2}
    Should Not Be True    ${out}[complete]
    Should Start With    ${out}[text]    {\n  "people": [\n    {\n
    ${snippet}=    Evaluate    json.loads($out["text"])    modules=json
    Should Be Equal As Integers    ${snippet}[people][0][id]    0
    Should Be Equal    ${snippet}[people][-1][pointer]    /people
    Should Be Equal    ${snippet}[meta]    ${{ {"source": "test"} }}
    ${notice}=    Snippet Notice Should Be    ${out}    text
    Should Contain    ${notice}[note]    save_file writes all of it formatted

TC-MCP-119 open_document And get_state Say A Document Is Large, And A Small One Is Not
    [Tags]    p1
    ${opened}=    Open The Crowd    crowd.json
    Should Start With    ${opened}[document][large]    Large: crowd.json takes
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Contain    ${state}[document][large]    Do not ask for all of it
    ${info}=    Mcp Tool Should Succeed    document_info    {}
    Should Start With    ${info}[large]    Large: crowd.json takes
    ${opened}=    Mcp Tool Should Succeed    open_document    {"text": "[1, 2]"}
    Dictionary Should Not Contain Key    ${opened}[document]    large

TC-MCP-120 With Answers Of 4 KB The Snippet And Its Notice Keep To The Page, And Are JSON
    [Documentation]    The smallest page the panel has: what is given of the value is less, so that the notice fits
    ...    too, and nothing is cut by the server's last resort.
    [Tags]    p1
    [Setup]    Launch Mcp App Serving    workspace=${CROWD}    answer_kb=4
    Open The Crowd    crowd.json
    FOR    ${tool}    ${arguments}    IN
    ...    read_value    {}
    ...    run_query    {"query": "."}
    ...    run_query    {"query": ".people[]", "limit": 1000}
    ...    format_json    {"input": "document"}
    ...    workspace_read    {"path": "crowd/list.json"}
        ${outcome}=    Call Mcp Tool    ${tool}    ${arguments}
        Should Not Be True    ${outcome}[error]    msg=${outcome}[text]
        ${length}=    Get Length    ${outcome}[text]
        Should Be True    ${length} <= 4000    msg=${tool}: ${length} bytes
        Should Not Be Equal    ${outcome}[value]    ${None}    msg=${tool}: not JSON (cut)
        Dictionary Should Contain Key    ${outcome}[value]    snippet
    END

TC-MCP-121 A Workspace Document Too Big For A Page Is A Snippet, Read On By Its Path
    [Tags]    p2
    ${out}=    Mcp Tool Should Succeed    workspace_read    {"path": "crowd/crowd.json"}
    Should Be Equal    ${out}[content][meta]    ${{ {"source": "test"} }}
    ${notice}=    Snippet Notice Should Be    ${out}    content
    Should Be Equal    ${notice}[of]    crowd/crowd.json
    Should Be Equal    ${notice}[next][arguments][input]    ${{ {"workspace": "crowd/crowd.json"} }}
    ${on}=    Follow Next    ${notice}
    Should Be Equal As Integers    ${on}[items][0][id]    ${notice}[arrays][0][given]

TC-MCP-122 What Fits In A Page Is Given Whole, And Nothing Is Said
    [Tags]    p2
    Open The Crowd    crowd.json
    ${out}=    Mcp Tool Should Succeed    read_value    {"pointer": "/people/7"}
    Should Be Equal As Integers    ${out}[members][id]    7
    Dictionary Should Not Contain Key    ${out}    snippet
    ${out}=    Mcp Tool Should Succeed    run_query    {"query": ".people | length"}
    Should Be Equal    ${out}[items]    ${{ [5000] }}
    Dictionary Should Not Contain Key    ${out}    snippet

TC-MCP-123 Through jsonquery-mcp, As QuickAI Calls, A Large Document Read Whole Says It Is A Snippet
    [Tags]    p2
    Open The Crowd    list.json
    ${result}=    Bridge Tool Call    read_value    {}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    ${answer}=    Evaluate    json.loads($result["text"])    modules=json
    ${notice}=    Snippet Notice Should Be    ${answer}    items
    Should Be Equal As Integers    ${notice}[arrays][0][items]    5000

TC-MCP-124 The Results The User Sees, Too Big For A Page, Say So, And Are Read On In results
    [Documentation]    set_query runs a query of every person in the query box: its answer, the first 20 results,
    ...    is a snippet of them, read on in "results" (what the user sees); get_results says the same of any page.
    [Tags]    p1
    Open The Crowd    crowd.json
    ${out}=    Mcp Tool Should Succeed    set_query    {"query": ".people[]"}
    Length Should Be    ${out}[items]    20
    ${notice}=    Snippet Notice Should Be    ${out}    items
    Should Be Equal    ${notice}[of]    the results the user sees
    Should Be Equal    ${notice}[next]
    ...    ${{ {"tool": "read_value", "arguments": {"input": "results", "pointer": "", "offset": 20}} }}
    ${on}=    Follow Next    ${notice}
    Should Be Equal As Integers    ${on}[items][0][id]    20
    ${page}=    Mcp Tool Should Succeed    get_results    {"offset": 40, "limit": 10}
    Should Be Equal As Integers    ${page}[items][0][id]    40
    ${notice}=    Snippet Notice Should Be    ${page}    items
    Should Be Equal As Integers    ${notice}[arrays][0][next_offset]    50

TC-MCP-125 What A Tool Makes Too Big For A Page Is A Snippet Read On In last, And A Schema That Fits Is Whole
    [Documentation]    apply_patch and merge_documents of the crowd make a document as big as it: each answer's
    ...    `result` is a snippet of it, whose `next` reads on in "last", where it is kept. The schema of the crowd is
    ...    small: given whole, and nothing said.
    [Tags]    p1
    Open The Crowd    crowd.json
    ${out}=    Mcp Tool Should Succeed    apply_patch
    ...    {"input": "document", "patch": [{"op": "replace", "path": "/meta/source", "value": "patched"}]}
    Should Be Equal    ${out}[result][meta][source]    patched
    ${notice}=    Snippet Notice Should Be    ${out}    result
    Should Be Equal    ${notice}[of]    the patched document
    Should Be Equal    ${notice}[next][arguments][input]    last
    ${on}=    Follow Next    ${notice}
    Should Be Equal As Integers    ${on}[items][0][id]    ${notice}[arrays][0][given]
    ${merged}=    Mcp Tool Should Succeed    merge_documents
    ...    {"inputs": ["document", {"json": {"more": true}}], "how": "deep"}
    Should Be True    ${merged}[result][more]
    ${notice}=    Snippet Notice Should Be    ${merged}    result
    Should Be Equal    ${notice}[of]    the merge
    ${made}=    Mcp Tool Should Succeed    create_schema    {"input": "document"}
    Should Be Equal    ${made}[schema][type]    object
    Dictionary Should Not Contain Key    ${made}    snippet

TC-MCP-126 A Workspace Item And Its Sample, Both Too Big, Each Say So, And The Sample Is Read On By Its Own Path
    [Documentation]    workspace_read with `sample`: the item's snippet and notice (`snippet`), the sample's
    ...    (`sample_snippet`), in a page together; the sample's path is given, and is an input of its own.
    [Tags]    p2
    ${outcome}=    Call Mcp Tool    workspace_read    {"path": "crowd/crowd.json", "sample": true}
    Should Not Be True    ${outcome}[error]    msg=${outcome}[text]
    ${length}=    Get Length    ${outcome}[text]
    Should Be True    ${length} <= 24000 + 24000 / 4    msg=${length} bytes
    ${out}=    Set Variable    ${outcome}[value]
    Snippet Notice Should Be    ${out}    content
    Should Be Equal    ${out}[sample_path]    crowd/crowd.sample.json
    Should Be Equal As Integers    ${out}[sample][0][id]    0
    ${sample}=    Snippet Notice Should Be    ${out}    sample    key=sample_snippet
    Should Be Equal    ${sample}[of]    crowd/crowd.sample.json
    Should Be Equal    ${sample}[next][arguments][input]    ${{ {"workspace": "crowd/crowd.sample.json"} }}
    ${on}=    Follow Next    ${sample}
    Should Be Equal As Integers    ${on}[items][0][id]    ${sample}[arrays][0][given]

TC-MCP-127 A Workspace File Too Big For A Page That Is Not JSON Is Said To Be So, And The Call Goes Well
    [Tags]    p2
    ${out}=    Mcp Tool Should Succeed    workspace_read    {"path": "crowd/broken.json"}
    ${what}=    Evaluate    $out["content"]["$omitted"]
    Should Contain    ${what}    not read as JSON
    Should End With    ${out}[content][file]    /crowd/broken.json
    Dictionary Should Not Contain Key    ${out}    snippet

TC-MCP-128 A Last Item Too Big For A Page Is Cut Down, And No Page Is Said To Follow It
    [Documentation]    The list's last item alone is more than a page: it is given cut down (its long string by its
    ...    start), there is no next_offset, and the notice says the long string is what is cut.
    [Tags]    p2
    ${out}=    Mcp Tool Should Succeed    read_value    {"input": {"workspace": "crowd/tail.json"}, "offset": 1}
    Dictionary Should Not Contain Key    ${out}    next_offset
    ${item}=    Set Variable    ${out}[items][0]
    ${what}=    Evaluate    $item["text"]["$omitted"]
    Should Be Equal    ${what}    long string
    Should Be Equal    ${item}[text][pointer]    /1/text
    ${notice}=    Snippet Notice Should Be    ${out}    items
    Should Contain    ${notice}[note]    It holds strings too long to give whole: 1 given by their start.
    Should Be Equal As Integers    ${notice}[strings_cut]    1

TC-MCP-129 The Handshake Tells The Assistant Not To Ask For All Of A Large Document, And How A Snippet Is Said
    [Documentation]    What a model reads before its first call: the server's instructions and read_value's
    ...    description name the snippet and its `snippet`.
    [Tags]    p2
    ${result}=    Mcp Initialize    client=Robot assistant
    Should Contain    ${result}[instructions]    Never ask for all of a large document: it would not fit.
    Should Contain    ${result}[instructions]    the answer says so in `snippet`
    ${listed}=    Mcp Post    {"jsonrpc": "2.0", "id": 9, "method": "tools/list"}
    ${read}=    Evaluate    [t for t in $listed["json"]["result"]["tools"] if t["name"] == "read_value"][0]["description"]
    Should Contain    ${read}    a snippet, said in `snippet`

*** Keywords ***
Make The Crowd
    [Documentation]    The display, and the crowd for the workspace of each app.
    Start Test Display
    ${people}=    Evaluate
    ...    [{"id": i, "name": f"person {i}", "tags": ["a", "b"], "city": "Lisbon"} for i in range(5000)]
    ${list}=    Evaluate    json.dumps($people)    modules=json
    ${crowd}=    Evaluate    json.dumps({"people": $people, "meta": {"source": "test"}})    modules=json
    ${sample}=    Evaluate    json.dumps($people[:3000])    modules=json
    ${broken}=    Evaluate    "this is not JSON at all " * 1500
    ${tail}=    Evaluate    json.dumps([1, {"text": "x" * 30000}])    modules=json
    &{workspace}=    Create Dictionary    crowd/list.json=${list}    crowd/crowd.json=${crowd}
    ...    crowd/crowd.sample.json=${sample}    crowd/broken.json=${broken}    crowd/tail.json=${tail}
    Set Suite Variable    ${CROWD}    ${workspace}

Open The Crowd
    [Documentation]    Opens the crowd's file `name` as the Source, by open_document; returns its answer.
    [Arguments]    ${name}
    ${path}=    Workspace Folder    crowd/${name}
    ${opened}=    Mcp Tool Should Succeed    open_document    ${{ {"path": $path} }}
    RETURN    ${opened}

Snippet Notice Should Be
    [Documentation]    The answer's notice (its `snippet`, or the member `key`), which it must have, for its member
    ...    `member`: what every notice says.
    [Arguments]    ${answer}    ${member}    ${key}=snippet
    Dictionary Should Contain Key    ${answer}    ${key}
    ${notice}=    Set Variable    ${answer}[${key}]
    Should Be Equal    ${notice}[in]    ${member}
    Should Start With    ${notice}[note]    Large:
    Should Contain    ${notice}[note]    `${member}` holds a snippet of it, not all of it
    Should Contain    ${notice}[note]    Do not ask for all of it
    RETURN    ${notice}

Follow Next
    [Documentation]    Makes the call the notice's `next` names, as a model would; returns what it gives.
    [Arguments]    ${notice}
    ${answer}=    Mcp Tool Should Succeed    ${notice}[next][tool]    ${notice}[next][arguments]
    RETURN    ${answer}
