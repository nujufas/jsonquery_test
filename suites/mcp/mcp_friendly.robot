*** Settings ***
Documentation     What a model gives, taken as it means it -- see docs/26_mcp_server.md.
...
...               A model reads a few words of a tool's schema and gives what it means the way it finds easiest: the
...               JSON itself rather than {"json": ...}, the JSON as text, a file's full path, an argument by another
...               name ("filter" for "query", "data" for "input"), a workspace item by its folder and name, with the
...               ending of its file and no kind. The server takes all of these as they are meant, and a call it still
...               cannot do says why and ends with a call of that tool that works. These cases are the whole path, over
...               HTTP and through jsonquery-mcp, against the running app; the finer cases are the server's unit tests.
Resource          ../../resources/mcp.resource
Library           Collections
Library           OperatingSystem
Force Tags        mcp    undocked-only
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Mcp App Serving    access=read
Test Teardown     Close Jsonquery App

*** Variables ***
&{WORKSPACE}      old.jq=.a

*** Test Cases ***
TC-MCP-110 The Tools Take The JSON Itself, Or Its Text, As What They Work On
    [Documentation]    format_json, validate_json, apply_patch, diff_documents, merge_documents and create_schema, each given
    ...    plain JSON (and format_json the JSON as text): what the schema says, {"json": ...}, is not needed.
    [Tags]    p1
    ${out}=    Mcp Tool Should Succeed    format_json    {"input": {"b": 1, "a": [1, 2]}, "sort_keys": true}
    Should Start With    ${out}[text]    {\n  "a": [
    ${out}=    Mcp Tool Should Succeed    format_json    {"input": "{\\"b\\": 1}"}
    Should Start With    ${out}[text]    {\n  "b": 1\n}
    ${valid}=    Mcp Tool Should Succeed    validate_json    {"input": {"id": 1}, "schema": {"type": "object", "required": ["id"]}}
    Should Be True    ${valid}[valid]
    ${patched}=    Mcp Tool Should Succeed    apply_patch    {"input": {"a": 1}, "patch": [{"op": "replace", "path": "/a", "value": 2}]}
    Should Be Equal    ${patched}[result]    ${{ {"a": 2} }}
    ${diff}=    Mcp Tool Should Succeed    diff_documents    {"left": {"a": 1, "b": 1}, "right": {"a": 2, "b": 1}}
    Should Be Equal As Integers    ${diff}[changed]    1
    Should Be Equal    ${diff}[changes][0][pointer]    /a
    ${merged}=    Mcp Tool Should Succeed    merge_documents    {"inputs": [{"a": {"x": 1}}, {"a": {"y": 2}}], "how": "deep"}
    Should Be Equal    ${merged}[result]    ${{ {"a": {"x": 1, "y": 2}} }}
    ${made}=    Mcp Tool Should Succeed    create_schema    {"input": [{"id": 1, "name": "Ana"}]}
    Should Be Equal    ${made}[schema][type]    array
    Query Box Should Be Empty

TC-MCP-111 workspace_save Saves The JSON Itself, And Knows What An Item Is From Its Name Or What It Holds
    [Documentation]    The call of the user's QuickAI that failed: a path and the JSON, no kind. Then a query by its folder,
    ...    its name and the ending of its file; a schema, a patch and a web address by what they hold. Each is saved
    ...    as what it is, without a question (they are new).
    [Tags]    p1
    [Setup]    Launch Mcp App Serving    workspace=${WORKSPACE}    access=edit
    ${saved}=    Mcp Tool Should Succeed    workspace_save    {"path": "examples/complex", "content": {"users": [{"name": "Ana"}]}}
    Should Be Equal    ${saved}[saved]    examples/complex.json
    ${read}=    Mcp Tool Should Succeed    read_value    {"input": {"workspace": "examples/complex.json"}, "pointer": "/users/0/name"}
    Should Be Equal    ${read}[value]    Ana
    ${saved}=    Mcp Tool Should Succeed    workspace_save    {"folder": "queries", "name": "late.jq", "content": ".orders[] | select(.late)"}
    Should Be Equal    ${saved}[saved]    queries/late.jq
    Workspace File Should Be    queries/late.jq    .orders[] | select(.late)
    ${saved}=    Mcp Tool Should Succeed    workspace_save
    ...    {"path": "schemas/user", "content": {"$schema": "https://json-schema.org/draft/2020-12/schema", "type": "object"}}
    Should Be Equal    ${saved}[saved]    schemas/user.schema.json
    ${saved}=    Mcp Tool Should Succeed    workspace_save    {"path": "patches/bump", "content": [{"op": "add", "path": "/x", "value": 1}]}
    Should Be Equal    ${saved}[saved]    patches/bump.patch.json
    ${saved}=    Mcp Tool Should Succeed    workspace_save    {"path": "links/feed", "content": "https://example.com/a.json"}
    Should Be Equal    ${saved}[saved]    links/feed.url
    ${saved}=    Mcp Tool Should Succeed    workspace_save    {"path": "queries/adults", "type": "jmespath", "content": "[?age > `21`]"}
    Should Be Equal    ${saved}[saved]    queries/adults.jmespath
    No Question Should Be Shown

TC-MCP-112 Arguments By The Names A Model Gives Them Are Taken, And Arguments Sent As JSON Text
    [Documentation]    "filter" and "lang" for run_query's query and language, "data" for format_json's input, "document" for
    ...    validate_json's, "old" and "new" for diff_documents' left and right; and the arguments of a call as JSON text.
    [Tags]    p1
    Load Fixture Via Paste    [{"age": 30}, {"age": 10}]
    ${ran}=    Mcp Tool Should Succeed    run_query    {"filter": ".[] | select(.age > 20) | .age", "lang": "jq"}
    Should Be Equal    ${ran}[items]    ${{ [30] }}
    ${out}=    Mcp Tool Should Succeed    format_json    {"data": {"b": 1}}
    Should Start With    ${out}[text]    {\n  "b": 1\n}
    ${valid}=    Mcp Tool Should Succeed    validate_json    {"document": {"id": 1}, "schema": {"required": ["id"]}}
    Should Be True    ${valid}[valid]
    ${diff}=    Mcp Tool Should Succeed    diff_documents    {"old": [1], "new": [2]}
    Should Be Equal As Integers    ${diff}[changed]    1
    Mcp Initialize
    ${posted}=    Mcp Post    {"jsonrpc": "2.0", "id": 9, "method": "tools/call", "params": {"name": "format_json", "arguments": "{\\"input\\": {\\"c\\": 3}}"}}
    Should Be Equal As Integers    ${posted}[status]    200
    Should Not Be True    ${posted}[json][result][isError]    msg=${posted}[body]
    Should Contain    ${posted}[json][result][content][0][text]    \\"c\\": 3

TC-MCP-113 A Call That Cannot Be Done Says Why, And Ends With A Call Of That Tool That Works
    [Documentation]    What is missing or not known is said, and a call that works is given after it, for the model to
    ...    make its next call right.
    [Tags]    p1
    ${text}=    Mcp Tool Should Fail    format_json    {}    expected=`input` is needed
    Should Contain    ${text}    For example: {"input"
    ${text}=    Mcp Tool Should Fail    run_query    {"query": ".a", "colour": "red"}    expected=unknown argument `colour`
    Should Contain    ${text}    For example: {"query"
    ${text}=    Mcp Tool Should Fail    validate_json    {"input": {"file": 3}, "schema": {}}    expected=takes a string
    Should Contain    ${text}    For example:

TC-MCP-114 Through jsonquery-mcp, As QuickAI Calls, The JSON Itself Is Taken Too
    [Tags]    p2
    ${result}=    Bridge Tool Call    format_json    {"input": {"b": [1]}}
    Should Not Be True    ${result}[error]    msg=${result}[text]
    Should Contain    ${result}[text]    \\"b\\"
    ${result}=    Bridge Tool Call    workspace_save    {"path": "x", "content": {}}
    Should Be True    ${result}[error]
    Should Contain    ${result}[text]    needs the user to allow "Edit"

TC-MCP-115 A JSON File's Full Path Is Read As The File, With Edit
    [Documentation]    A string that is the full path of a .json file is that file: read with Edit, refused with Read (as
    ...    {"file": ...} is).
    [Tags]    p2
    [Setup]    Launch Mcp App Serving    access=edit
    ${path}=    Fixture Path    people.json
    ${info}=    Mcp Tool Should Succeed    document_info    ${{ {"input": $path} }}
    Should Be Equal    ${info}[source]    file
    ${made}=    Mcp Tool Should Succeed    create_schema    ${{ {"input": $path} }}
    Should Be Equal    ${made}[schema][type]    array
    Open Mcp Panel
    Choose Access    read
    Close Mcp Panel
    Mcp Tool Should Fail    document_info    ${{ {"input": $path} }}    expected=Edit

*** Keywords ***
Query Box Should Be Empty
    [Documentation]    The window's query box holds nothing and nothing was run in it (what the app says it shows, by
    ...    get_state), as in mcp_tools.robot.
    ${state}=    Mcp Tool Should Succeed    get_state
    Should Be Empty    ${state}[query][text]
    Should Be Equal    ${state}[query][results]    ${None}
