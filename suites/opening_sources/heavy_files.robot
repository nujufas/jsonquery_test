*** Settings ***
Documentation     Opening what is not an ordinary small file -- see docs/02_opening_sources.md
...               (TC-OPEN-029 to TC-OPEN-032). A file of 64 MiB or more is memory-mapped while it
...               is parsed and a smaller one is read; a pipe has to be read whatever size it says
...               it is; a download is parsed from memory when it is small and goes through a
...               temporary file, which is mapped and then deleted, when it is large.
Resource          ../../resources/keywords.resource
Force Tags        opening_sources
Suite Setup       Start Test Display
Suite Teardown    Stop Test Display
Test Setup        Launch Jsonquery App
Test Teardown     Close Jsonquery App

*** Variables ***
# The byte size the toolbar shows after a load ("80.0 MB"): between the Clear
# button and the icon buttons at the far right.
@{BYTE_SIZE_AREA}    940    0    135    20

*** Test Cases ***
TC-OPEN-029 A File Past The Mapping Size Opens Like Any Other
    [Documentation]    80 MiB, a small document and then blanks, so that parsing it costs
    ...    nothing: well past the 64 MiB from which the app maps a file instead of reading
    ...    it. It loads, the toolbar says its size and the Source pane shows its content.
    [Tags]    p2
    ${file}=    Make Heavy File    80
    Load Via Url    ${file}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    2 keys    timeout=20
    Wait Until Region Matches    @{BYTE_SIZE_AREA}    80\\.0 ?MB    timeout=5
    Region Should Not Contain Text    @{STATUS_BAR}    Load error

TC-OPEN-030 A Named Pipe Opens With What Is Written To It
    [Documentation]    A path typed into the source field that is a pipe -- one made with
    ...    mkfifo here, or /dev/stdin for an app started at the end of one. A pipe says it
    ...    is 0 bytes long however much it will hand over, and it used to load as an empty
    ...    array, whatever was written to it.
    [Tags]    p2
    ${pipe}=    Make Named Pipe That Says    {"from": "a named pipe", "items": [1, 2, 3]}
    Load Via Url    ${pipe}
    Wait Until Region Contains Text    @{SOURCE_PANEL}    a named pipe    timeout=10
    Region Should Contain Text    @{SOURCE_PANEL}    items
    Region Should Not Contain Text    @{STATUS_BAR}    Load error

TC-OPEN-031 A Small Download Leaves Nothing In The Temp Folder
    [Documentation]    A small response is parsed from memory. Before, every download was
    ...    written to a file in the temp folder, which was never deleted.
    [Tags]    p2
    ${before}=    App Temp Files
    ${base_url}=    Start Fixture Server    ${HTTP_FIXTURES_DIR}
    Load Via Url    ${base_url}/valid.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    3 items    timeout=5
    ${after}=    App Temp Files
    Should Be Equal    ${after}    ${before}
    [Teardown]    Run Keywords    Stop Fixture Server    AND    Close Jsonquery App

TC-OPEN-032 A Large Download Leaves Nothing In The Temp Folder
    [Documentation]    70 MiB, over the 64 MiB from which a response is written to a
    ...    temporary file to be mapped: the file is deleted once the document is parsed.
    ...    Before, it stayed in the temp folder for good, the size of the download.
    [Tags]    p2
    ${file}=    Make Heavy File    70
    ${folder}=    Evaluate    os.path.dirname($file)    modules=os
    ${before}=    App Temp Files
    ${base_url}=    Start Fixture Server    ${folder}
    Load Via Url    ${base_url}/heavy.json
    Wait Until Region Contains Text    @{SOURCE_PANEL}    2 keys    timeout=20
    ${after}=    App Temp Files
    Should Be Equal    ${after}    ${before}
    [Teardown]    Run Keywords    Stop Fixture Server    AND    Close Jsonquery App
