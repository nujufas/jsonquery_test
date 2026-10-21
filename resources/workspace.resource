*** Settings ***
Documentation     The workspace pane and its windows, as the cases of `suites/workspace/` see them -- see
...               docs/25_workspace.md. Points and regions are those of the main window, 1200x800, Dark
...               theme, with the pane OPEN (256 px wide, at the left of the window): the main view is then
...               256 px to the right and 256 px narrower than it is with no pane (the query box is at
...               x 264-1192), and what is anchored at the right (the toolbar's icons, the engine picker,
...               the status bar's buttons) is where it always was.
...
...               The docked profile (run_docked.sh) moves what is under the toolbar down by the row of
...               tabs, which is right for the pane's header, filter, chips and list; what the window
...               anchors by itself does not move (the pane's details at the foot, and the windows the pane
...               opens: they are put at the top centre of the window), so those are in variables that
...               resources/docked_main.py gives the other value (`WS_FORM_DY`).
Library           Collections
Variables         workspace_fixture.py
Resource          keywords.resource

*** Variables ***
# ---- the pane (open): its header, its filter and chips, its list, the item that is picked -----------------
${WS_PANE_WIDTH}          256
${WS_HEADER_Y}            17
# Header buttons, from the left: save what is in the box, new folder, the menu (three dots), fold the pane.
${WS_SAVE_X}              140
${WS_FOLDER_X}            171
${WS_MENU_X}              203
${WS_FOLD_X}              235
@{WS_TITLE}               0      8      140     20
# The title in a pane that is as narrow as it can be (208): the room that is left of it before the first button (the floppy).
@{WS_TITLE_AT_LEAST}      0      8      80      20
@{WS_PATH_LINE}           0      30     256     16
${WS_FILTER_X}            127
${WS_FILTER_Y}            59
${WS_CHIPS_Y}             81
${WS_CHIP_ALL_X}          17
${WS_CHIP_QUERIES_X}      49
${WS_CHIP_SCHEMAS_X}      95
${WS_CHIP_PATCHES_X}      140
${WS_CHIP_DOCS_X}         177
${WS_LIST_TOP}            93
${WS_ROW_HEIGHT}          20
# A point of a row that is not on its name or its tag (a click there is a click on the row), and the
# colour of a row that is picked, and of one that is not.
${WS_ROW_X}               150
${WS_SELECTED_COLOR}      ${{ (13, 59, 77) }}
${WS_PLAIN_COLOR}         ${{ (27, 27, 27) }}
@{WS_LIST}                0      93     256    654
# A point in the last rows of the list (the list ends at 747, the details begin): a row that is carried there makes the list
# scroll. The foot of the pane is the window's, so the docked profile (which moves the rest down) puts it DY higher.
${WS_LIST_FOOT_Y}         738
# A point under the list, over what is said there (the foot of the pane is the window's too).
${WS_BELOW_LIST_Y}        760
# The item that is picked, and what is said under the list, reach into the last 30 px of the window:
# the docked profile leaves a region like that where it is.
@{WS_DETAILS}             0      600    256    177
# Rows of STANDARD (workspace_fixture.py), the pane open and Errors shut.
${ROW_LOGS}               0
${ROW_ERRORS}             1
${ROW_LOGINS}             2
${ROW_SERVICES}           3
${ROW_ORDERS}             4
${ROW_UPDATE}             5
${ROW_SCRATCH}            6

# What a row that is carried over a folder looks like: the folder is lit, with a bright border (192, 222, 255)
# and a fill of its own (16, 53, 67); what is picked is (13, 59, 77) without a border.
${WS_LIT_BORDER}          ${{ (192, 222, 255) }}
# The empty part of the list, under the last row of STANDARD.
${WS_EMPTY_Y}             400

# The list of places that the Move to of a row's menu opens, at the right of the menu.
${SUBMENU_X}              290
${SUBMENU_WIDTH}          130

# The menu of the three dots opens under it, at the right of the pane's header.
@{WS_MENU_AREA}           192    28     252    185

# ---- the strip of a folded pane, and the status bar's button -------------------------------------------
${WS_RAIL_X}              13
${WS_RAIL_UNFOLD_Y}       10
@{WS_RAIL}                0      0      26     60
# What the window holds, with the pane folded to its strip (26 wide): the Source label.
@{WS_SOURCE_LABEL_FOLDED}    26     0      80     24
# The button that shows the pane is the first thing at the left end of the status bar (24 by 21 points at x 8-31): the
# status text follows it, from x 41, and what is at the right (the ⚙, the 🌐, the ⓘ) is where it is without a pane.
${WS_STATUS_X}            20
${WS_STATUS_Y}            789
# Where the first pixel of each icon is (the top-left of the picture it is drawn as): the button's, the strip's, and the
# header's button that makes a folder.
${WS_STATUS_ICON_LEFT}    13
${WS_STATUS_ICON_TOP}     783
${WS_RAIL_ICON_LEFT}      6
${WS_RAIL_ICON_TOP}       25
${WS_NEWFOLDER_ICON_LEFT}    164
${WS_NEWFOLDER_ICON_TOP}     12

# ---- the main view with the pane open -------------------------------------------------------------------------
${WS_QUERY_X}             600
${WS_QUERY_Y}             80
${WS_RUN_X}               364
${WS_RUN_Y}               39
${WS_QUERY_SAVE_X}        446
${WS_QUERY_SAVE_Y}        39
@{WS_QUERY_ROW}           256    22     500    24
# With the pane folded to its strip (26 wide) the main view starts at x=26.
@{WS_QUERY_ROW_FOLDED}    26     22     500    24
# The paperclip of a row that has a sample.
${PAPERCLIP_X}            238
# The label that says where the query in the box came from, after "Save…" in the Query row.
@{QUERY_ORIGIN}           440    28     300    18
@{WS_QUERY_TEXTBOX}       264    52     928    60
${WS_SOURCE_PASTE_X}      490
${WS_SOURCE_PASTE_Y}      400
@{WS_SOURCE_PANEL}        256    156    470    579
@{WS_RESULTS_PANEL}       728    156    472    579
# A point in the middle of the Results, which is nothing that a row can be put on.
${WS_RESULTS_X}           960
${WS_RESULTS_Y}           400
# The status line at the foot of the window, from the button at its left end to the ⚙ (it reaches the last 30 px: not
# moved when docked).
@{WS_STATUS_LINE}         36     777    1050   23

# ---- the windows the pane opens: at the top centre of the window (so not moved by the docked profile) -----
# The suites' y is the window's own y plus WS_FORM_DY (0; -23 docked, where the library adds the row's 23).
${WS_FORM_DY}             0
${WS_FORM_TOP}            80
# Where each window is (x, y, width, height) with the top of the window at WS_FORM_TOP: a region as tight as
# the window makes OCR read it better (the text behind a window, in a wider one, is read with it). The
# `FORM_KIND` of a case says which window is meant (`Set Form Kind`); a window that was not told is `wide`.
&{FORM_REGIONS}           wide=${{ [350, 80, 500, 330] }}    save=${{ [350, 80, 500, 340] }}    export=${{ [364, 80, 480, 340] }}    import=${{ [364, 80, 480, 340] }}    newfolder=${{ [432, 80, 336, 160] }}    delete=${{ [420, 80, 360, 130] }}
# The "Choose folder…" buttons: right of the folder box of the Import window and of the Export window.
${IMPORT_CHOOSE_X}        779
${IMPORT_CHOOSE_Y}        148
${EXPORT_CHOOSE_X}        779
${EXPORT_CHOOSE_Y}        170
# The window that makes a folder (320 wide, its buttons under the Inside box, when it has no complaint to make).
${NEWFOLDER_MAKE_X}       462
${NEWFOLDER_CANCEL_X}     518
${NEWFOLDER_BUTTONS_Y}    213
# The Save window, 380 wide, with its tabs (what is saved), the Name box, the Folder box, the box for a new folder
# in it, the tick that keeps a sample, and its buttons under what it says of what is being saved.
${SAVE_TAB_Y}             130
${SAVE_TAB_QUERY_X}       476
${SAVE_TAB_SCHEMA_X}      547
${SAVE_TAB_PATCH_X}       611
${SAVE_TAB_SOURCE_X}      679
${SAVE_NAME_X}            600
${SAVE_NAME_Y}            173
${SAVE_FOLDER_X}          530
${SAVE_FOLDER_Y}          213
${SAVE_SUB_X}             665
${SAVE_SUB_Y}             234
${SAVE_SAMPLE_X}          417
${SAVE_SAMPLE_Y}          256
# The list that the Folder box opens, under it.
@{SAVE_FOLDER_LIST}       404    226    260    170

# The ink of a plain folder: 14 by 11 points; a dim one is as bright as 108, the buttons beside it 180: the threshold is
# between that and the button's own 60.
${FOLDER_INK}             90

# What the icons of the pane are, as pictures of whole pixels (`Icon Should Look Like`): X is ink, . is none and ? is
# either (the pixels at a rounded corner, which the threshold that is read with decides). The pane's button, in the status
# bar and in the strip: a window with its left column filled, 14 by 12; the header's button that makes a folder: a
# folder with a plus left out of it, 15 by 11 (the plus is no ink, and the button shows in it).
@{SIDE_PANEL}
...    ?XXXXXXXXXXX??
...    XXXXX.......??
...    XXXXX........X
...    XXXXX........X
...    XXXXX........X
...    XXXXX........X
...    XXXXX........X
...    XXXXX........X
...    XXXXX........X
...    XXXXX........X
...    XXXXX.......??
...    ?XXXXXXXXXXX??
@{NEW_FOLDER}
...    ?XXXX?.........
...    XXXXXX.........
...    XXXXXXXXXXXXXXX
...    XXXXXXXXXXXXXXX
...    XXXXXXX.XXXXXXX
...    XXXXXXX.XXXXXXX
...    XXXXX.....XXXXX
...    XXXXXXX.XXXXXXX
...    XXXXXXX.XXXXXXX
...    XXXXXXXXXXXXXXX
...    XXXXXXXXXXXXXXX
# The ink of the icons that are drawn bright (the pane is shown; any channel over this) and of those that are dim (a
# button's weak ink is 108 to 127 on its own 60: over this, and not over the other); in the light theme the ink is
# dark, and a pixel is ink when all its channels are under this.
${INK_BRIGHT}             150
${INK_DIM}                90
${INK_ON_LIGHT}           200
# The dim icon is no brighter than 127 (122 on the strip), the text of the app's windows is 140 and a bright icon is 180: a
# dim icon has nothing as bright as this.
${INK_DIM_LIMIT}          135

*** Keywords ***
Launch Workspace App
    [Documentation]    The app with the pane open and the files of `STANDARD` in the workspace (or other
    ...    settings or other files).
    [Arguments]    ${settings}=${PANE_OPEN}    ${files}=${STANDARD}
    Launch Jsonquery App    settings=${settings}    workspace=${files}
    Pane Should Be Open

Pane Should Be Open
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Contain Text    @{WS_TITLE}    Workspace

Pane Should Not Be Shown
    [Documentation]    No pane and no strip: the window as it was, with its Source label at the left.
    Wait Until Keyword Succeeds    5x    0.5s    Region Should Not Contain Text    @{WS_TITLE}    Workspace

Pane Should Be This Wide
    [Documentation]    The pane ends at this x (within a few points): its colour is at 12 points inside it and the main view's at 14
    ...    points outside.
    [Arguments]    ${width}
    ${inside}=    Get Pixel Color    ${{ ${width} - 12 }}    400
    ${outside}=    Get Pixel Color    ${{ ${width} + 14 }}    400
    Colors Should Match    ${inside}    ${WS_PLAIN_COLOR}    tolerance=6    msg=The pane ends before ${width}: ${inside} at ${width} - 12
    Colors Should Match    ${outside}    ${{ (10, 10, 10) }}    tolerance=6    msg=The pane is wider than ${width}: ${outside} at ${width} + 14

Form Y
    [Documentation]    The suites' y of a point of a window that the pane opens, given as the window has it.
    [Arguments]    ${y}
    ${at}=    Evaluate    int(${y}) + int(${WS_FORM_DY})
    RETURN    ${at}

Set Form Kind
    [Documentation]    The window that the next keywords look at: `save`, `export`, `import`, `newfolder` or `delete`.
    [Arguments]    ${kind}
    Set Test Variable    ${FORM_KIND}    ${kind}

Form Region
    [Documentation]    The (x, y, width, height) of the part of the window that the window of the pane that is open is in.
    ${kind}=    Get Variable Value    ${FORM_KIND}    wide
    ${region}=    Set Variable    ${FORM_REGIONS}[${kind}]
    ${top}=    Evaluate    int(${region}[1]) + int(${WS_FORM_DY})
    RETURN    ${region}[0]    ${top}    ${region}[2]    ${region}[3]

Row Y
    [Documentation]    The y of the middle of row `row` of the list (0 is the first).
    [Arguments]    ${row}
    ${y}=    Evaluate    int(${WS_LIST_TOP}) + int(${WS_ROW_HEIGHT}) * int(${row}) + int(${WS_ROW_HEIGHT}) // 2
    RETURN    ${y}

Row Should Have Tag Colour
    [Documentation]    The tag at the right of the row is this colour (the fill of the tag of that sort).
    [Arguments]    ${row}    ${r}    ${g}    ${b}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    ${y} - 7
    Region Should Contain Color    170    ${top}    80    14    ${r}    ${g}    ${b}    tolerance=6
    ...    msg=Row ${row} has no tag of ${r}, ${g}, ${b}

Row Should Not Have Tag Colour
    [Arguments]    ${row}    ${r}    ${g}    ${b}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    ${y} - 7
    Region Should Not Contain Color    170    ${top}    80    14    ${r}    ${g}    ${b}    tolerance=6

Tag Right Edge
    [Documentation]    The x at which the tag of this colour ends at the right of the row.
    [Arguments]    ${row}    ${r}    ${g}    ${b}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    ${y} - 7
    ${l}    ${t}    ${right}    ${bottom}=    Get Color Bounds    170    ${top}    80    14    ${r}    ${g}    ${b}    tolerance=6
    ${at}=    Evaluate    170 + ${right}
    RETURN    ${at}

Row Name Y
    [Documentation]    The y at which OCR reads the name in the list.
    [Arguments]    ${name}
    ${x}    ${y}=    Find Text In Region    @{WS_LIST}    ${name}
    RETURN    ${y}

Click Row
    [Documentation]    A click on a row (and the pointer put away: a row under it is lit, and that is not
    ...    what a case about the row's own colour reads).
    [Arguments]    ${row}
    ${y}=    Row Y    ${row}
    Click At    ${WS_ROW_X}    ${y}
    Sleep    0.4s
    Move Mouse To    600    400

Double Click Row
    [Arguments]    ${row}
    ${y}=    Row Y    ${row}
    Double Click At    ${WS_ROW_X}    ${y}
    Sleep    0.6s
    Move Mouse To    600    400

Right Click Row
    [Documentation]    Opens the menu of a row, and waits until it is there (a right click now and then does
    ...    not register).
    [Arguments]    ${row}
    ${y}=    Row Y    ${row}
    Wait Until Keyword Succeeds    3x    0.4s    Right Click And See Row Menu    ${y}

Right Click And See Row Menu
    [Arguments]    ${y}
    Right Click At    ${WS_ROW_X}    ${y}
    Sleep    0.5s
    ${top}=    Evaluate    int(${y}) + 4
    Region Should Contain Text    ${WS_ROW_X}    ${top}    110    ${{ int(${WS_ROW_HEIGHT}) * 12 }}    Rename

Pick From Row Menu
    [Documentation]    Clicks an item of the menu that is open, found by its text, which is read in the part
    ...    of the window under the row (the menu opens at the pointer, to the right and below).
    [Arguments]    ${item}    ${y}
    ${top}=    Evaluate    int(${y}) - 40
    Click Text In Region    ${WS_ROW_X}    ${top}    110    300    ${item}
    Sleep    0.5s

Row Should Be Selected
    [Arguments]    ${row}
    ${y}=    Row Y    ${row}
    ${color}=    Get Pixel Color    ${WS_ROW_X}    ${y}
    Colors Should Match    ${color}    ${WS_SELECTED_COLOR}    tolerance=8
    ...    msg=Row ${row} is not picked: its colour is ${color}

Row Should Not Be Selected
    [Arguments]    ${row}
    ${y}=    Row Y    ${row}
    ${color}=    Get Pixel Color    ${WS_ROW_X}    ${y}
    Colors Should Match    ${color}    ${WS_PLAIN_COLOR}    tolerance=8
    ...    msg=Row ${row} looks picked or lit: its colour is ${color}

List Should Show
    [Documentation]    Every name is somewhere in the list.
    [Arguments]    @{names}
    FOR    ${name}    IN    @{names}
        Wait Until Keyword Succeeds    4x    0.4s    Region Should Show Text    @{WS_LIST}    ${name}
    END

List Should Not Show
    [Documentation]    No name is in the list (the pointer is put away first).
    [Arguments]    @{names}
    Move Mouse To    600    400
    FOR    ${name}    IN    @{names}
        Region Should Not Show Text    @{WS_LIST}    ${name}
    END

Details Should Show
    [Arguments]    @{texts}
    FOR    ${text}    IN    @{texts}
        Wait Until Keyword Succeeds    4x    0.4s    Region Should Contain Text    @{WS_DETAILS}    ${text}
    END

Details Should Match
    [Documentation]    What is under the list matches this regular expression (OCR reads the small grey lines
    ...    with a letter wrong now and then: the expression says which letters may be).
    [Arguments]    ${pattern}
    ${x}    ${y}    ${w}    ${h}=    Set Variable    @{WS_DETAILS}
    Wait Until Region Matches    ${x}    ${y}    ${w}    ${h}    ${pattern}    timeout=4

Details Should Not Show
    [Arguments]    @{texts}
    FOR    ${text}    IN    @{texts}
        Region Should Not Contain Text    @{WS_DETAILS}    ${text}
    END

Click Header Button
    [Documentation]    `save`, `folder`, `menu` or `fold`.
    [Arguments]    ${button}
    ${x}=    Set Variable If    '${button}' == 'save'    ${WS_SAVE_X}
    ...    '${button}' == 'folder'    ${WS_FOLDER_X}
    ...    '${button}' == 'menu'    ${WS_MENU_X}
    ...    ${WS_FOLD_X}
    Click At    ${x}    ${WS_HEADER_Y}
    Sleep    0.5s

Pick Pane Menu Item
    [Documentation]    The menu of the three dots, and the item that says `item` (found by OCR).
    [Arguments]    ${item}
    Click Header Button    menu
    Click Text In Region    @{WS_MENU_AREA}    ${item}
    Sleep    0.7s
    Move Mouse To    600    400

Type In Filter
    [Documentation]    Types `text` in the filter box of the pane (over what is there).
    [Arguments]    ${text}
    Click At    ${WS_FILTER_X}    ${WS_FILTER_Y}
    Sleep    0.2s
    Press Keys    ctrl    a
    Type Text    ${text}
    Sleep    0.5s
    Move Mouse To    600    400

Clear The Filter
    Click At    ${WS_FILTER_X}    ${WS_FILTER_Y}
    Sleep    0.2s
    Press Keys    ctrl    a
    Press Key    delete
    Sleep    0.5s
    Move Mouse To    600    400

Click Chip
    [Documentation]    `all`, `queries`, `schemas`, `patches` or `docs`.
    [Arguments]    ${chip}
    ${x}=    Set Variable If    '${chip}' == 'all'    ${WS_CHIP_ALL_X}
    ...    '${chip}' == 'queries'    ${WS_CHIP_QUERIES_X}
    ...    '${chip}' == 'schemas'    ${WS_CHIP_SCHEMAS_X}
    ...    '${chip}' == 'patches'    ${WS_CHIP_PATCHES_X}
    ...    ${WS_CHIP_DOCS_X}
    Click At    ${x}    ${WS_CHIPS_Y}
    Sleep    0.5s
    Move Mouse To    600    400

Type In Query Box
    [Documentation]    The query box (with the pane open) holds `text`: put there with a paste, as typing sends
    ...    some characters wrong.
    [Arguments]    ${text}
    Set Clipboard    ${text}
    Click At    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Press Keys    ctrl    v
    Sleep    0.4s

Query Box Should Hold
    [Documentation]    The query box holds exactly `expected`: all of it is copied and compared (the click, the
    ...    selection and the copy are made again if the clipboard did not get it: a key sent while the window
    ...    is busy is lost now and then).
    [Arguments]    ${expected}
    Wait Until Keyword Succeeds    4x    0.8s    Query Box Holds    ${expected}

Query Box Holds
    [Arguments]    ${expected}
    Set Clipboard    nothing was copied
    Click At    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Press Keys    ctrl    c
    Sleep    0.4s
    ${text}=    Get Clipboard
    Should Be Equal    ${text}    ${expected}

Clipboard Should Be
    [Documentation]    The clipboard holds exactly `expected` once the app has put it there (a copy reaches it a frame
    ...    or two after the click: polled).
    [Arguments]    ${expected}
    Wait Until Keyword Succeeds    8x    0.3s    Clipboard Equals    ${expected}

Clipboard Equals
    [Arguments]    ${expected}
    ${text}=    Get Clipboard
    Should Be Equal    ${text}    ${expected}

Form Should Be Open
    [Documentation]    A window of the pane is open, with this title.
    [Arguments]    ${title}
    ${x}    ${y}    ${w}    ${h}=    Form Region
    Wait Until Keyword Succeeds    5x    0.4s    Region Should Contain Text    ${x}    ${y}    ${w}    ${h}    ${title}

Form Should Not Be Open
    [Arguments]    ${title}
    ${x}    ${y}    ${w}    ${h}=    Form Region
    Region Should Not Contain Text    ${x}    ${y}    ${w}    ${h}    ${title}

Form Should Show
    [Arguments]    @{texts}
    ${x}    ${y}    ${w}    ${h}=    Form Region
    FOR    ${text}    IN    @{texts}
        Wait Until Keyword Succeeds    4x    0.4s    Region Should Contain Text    ${x}    ${y}    ${w}    ${h}    ${text}
    END

Form Should Have Buttons
    [Documentation]    These buttons are in the window. Their labels are read as sparse text: the buttons have a fill of
    ...    their own, and the lines of text read as a page make nothing of them.
    [Arguments]    @{labels}
    ${x}    ${y}    ${w}    ${h}=    Form Region
    FOR    ${label}    IN    @{labels}
        Wait Until Keyword Succeeds    4x    0.4s    Region Should Contain Text    ${x}    ${y}    ${w}    ${h}    ${label}    psm=11
    END

Form Should Not Show
    [Arguments]    @{texts}
    ${x}    ${y}    ${w}    ${h}=    Form Region
    FOR    ${text}    IN    @{texts}
        Region Should Not Contain Text    ${x}    ${y}    ${w}    ${h}    ${text}
    END

Press Form Button
    [Documentation]    Clicks a button in the foot of the window of the pane that is open: `first` is the one at the left
    ...    (Save, Make it, Export, Import, Delete: what the window does) and `last` the one at the right (Cancel). The
    ...    buttons are found by their fill, the row of grey boxes at the foot of the window, and not by their labels,
    ...    which OCR reads badly (dark text on a fill) and the window's other words are read before.
    [Arguments]    ${which}=first
    ${x}    ${y}    ${w}    ${h}=    Form Region
    # (60: a button; 43: one that cannot be pressed now)
    ${segments}=    Get Lowest Color Segments    ${x}    ${y}    ${w}    ${h}    60    60    60    r2=43    g2=43    b2=43
    ${count}=    Get Length    ${segments}
    Should Be True    ${count} >= 1    msg=No button in the window
    ${wanted}=    Set Variable If    '${which}' == 'first'    ${segments}[0]    ${segments}[-1]
    Click At    ${wanted}[0]    ${wanted}[1]
    Sleep    0.6s

Form Should Have This Many Buttons
    [Documentation]    The row of buttons at the foot of the window of the pane that is open has this many (found by their fill).
    [Arguments]    ${count}
    ${x}    ${y}    ${w}    ${h}=    Form Region
    ${segments}=    Get Lowest Color Segments    ${x}    ${y}    ${w}    ${h}    60    60    60    r2=43    g2=43    b2=43
    ${found}=    Get Length    ${segments}
    Should Be Equal As Integers    ${found}    ${count}    msg=The window has ${found} buttons: ${segments}

Primary Button Width
    [Documentation]    How wide the first button of the window that is open is, found by its fill: a button is as wide as
    ...    its label (Save 34, Replace 53), which OCR reads badly in a button.
    ${x}    ${y}    ${w}    ${h}=    Form Region
    ${segments}=    Get Lowest Color Segments    ${x}    ${y}    ${w}    ${h}    60    60    60    r2=43    g2=43    b2=43
    ${first}=    Set Variable    ${segments}[0]
    ${width}=    Evaluate    int(${first}[3]) - int(${first}[2]) + 1
    RETURN    ${width}

Primary Button Should Be This Wide
    [Arguments]    ${least}    ${most}
    ${width}=    Primary Button Width
    Should Be True    ${least} <= ${width} <= ${most}    msg=The first button is ${width} wide, not ${least} to ${most}

Press Primary Button
    Press Form Button    first

Press Cancel Button
    Press Form Button    last

Press In Form
    [Documentation]    Clicks the lowest place in the form where this text is read: a button is under what the form
    ...    says, and the same word is in its title and its labels.
    [Arguments]    ${text}
    ${x}    ${y}    ${w}    ${h}=    Form Region
    # (sparse-text reading: the buttons have a fill of their own, and the lines of text read as a page
    # make nothing of their labels)
    ${hits}=    Find All Text In Region    ${x}    ${y}    ${w}    ${h}    ${text}    psm=11
    ${count}=    Get Length    ${hits}
    Should Be True    ${count} > 0    msg=No ${text} in the form
    ${last}=    Get From List    ${hits}    -1
    Click At    ${last}[0]    ${last}[1]
    Sleep    0.5s

Press In Details
    [Documentation]    Clicks the lowest place under the list where this text is read: the buttons of the item that is
    ...    picked are under what it says (its sample's name has the same words as the button that opens it).
    [Arguments]    ${text}
    ${x}    ${y}    ${w}    ${h}=    Set Variable    @{WS_DETAILS}
    ${hits}=    Find All Text In Region    ${x}    ${y}    ${w}    ${h}    ${text}    psm=11
    ${count}=    Get Length    ${hits}
    Should Be True    ${count} > 0    msg=No ${text} under the list
    ${last}=    Get From List    ${hits}    -1
    Click At    ${last}[0]    ${last}[1]
    Sleep    0.7s
    Move Mouse To    600    400

Details Buttons Should Be In Order
    [Documentation]    Of the buttons under the list the one that says `first` is left of the one that says `second` (the
    ...    lowest place of each is the button: a name higher up may have the same words).
    [Arguments]    ${first}    ${second}
    ${x}    ${y}    ${w}    ${h}=    Set Variable    @{WS_DETAILS}
    ${a}=    Find All Text In Region    ${x}    ${y}    ${w}    ${h}    ${first}    psm=11
    ${b}=    Find All Text In Region    ${x}    ${y}    ${w}    ${h}    ${second}    psm=11
    Should Be True    len($a) > 0    msg=No ${first} under the list
    Should Be True    len($b) > 0    msg=No ${second} under the list
    Should Be True    $a[-1][0] < $b[-1][0]    msg=${first} (at ${a}[-1]) is not left of ${second} (at ${b}[-1])

Press Leftmost In Details
    [Documentation]    The same, but of the places in the lowest row of them the one that is furthest left: `Open`,
    ...    which is the first of two buttons when the item has a sample (the second is `Open with sample`).
    [Arguments]    ${text}
    ${x}    ${y}    ${w}    ${h}=    Set Variable    @{WS_DETAILS}
    ${hits}=    Find All Text In Region    ${x}    ${y}    ${w}    ${h}    ${text}    psm=11
    ${count}=    Get Length    ${hits}
    Should Be True    ${count} > 0    msg=No ${text} under the list
    ${best}=    Set Variable    ${hits}[0]
    FOR    ${hit}    IN    @{hits}
        IF    ${hit}[1] > ${best}[1] + 5
            ${best}=    Set Variable    ${hit}
        ELSE IF    abs(${hit}[1] - ${best}[1]) <= 5 and ${hit}[0] < ${best}[0]
            ${best}=    Set Variable    ${hit}
        END
    END
    Click At    ${best}[0]    ${best}[1]
    Sleep    0.7s
    Move Mouse To    600    400

Notice Should Say
    [Documentation]    What is said under the list matches this regular expression (the line is small and
    ...    grey: OCR reads a digit as a letter now and then, and the expression says which).
    [Arguments]    ${pattern}
    ${x}    ${y}    ${w}    ${h}=    Set Variable    @{WS_DETAILS}
    Wait Until Region Matches    ${x}    ${y}    ${w}    ${h}    ${pattern}    timeout=5

Pick Row Menu Item
    [Documentation]    Opens the menu of the row and clicks the item that says `item` (found by OCR in the part of
    ...    the window under the pointer, where the menu is).
    [Arguments]    ${row}    ${item}
    Right Click Row    ${row}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    max(int(${y}) - 20, 0)
    Click Text In Region    ${WS_ROW_X}    ${top}    200    330    ${item}
    Sleep    0.6s
    Move Mouse To    600    400

Row Menu Should Offer
    [Documentation]    The menu of the row has all of these items. Closes it.
    [Arguments]    ${row}    @{items}
    Right Click Row    ${row}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    max(int(${y}) - 20, 0)
    FOR    ${item}    IN    @{items}
        Region Should Contain Text    ${WS_ROW_X}    ${top}    200    330    ${item}
    END
    Press Key    escape
    Sleep    0.4s

Row Menu Should Not Offer
    [Arguments]    ${row}    @{items}
    Right Click Row    ${row}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    max(int(${y}) - 20, 0)
    FOR    ${item}    IN    @{items}
        Region Should Not Contain Text    ${WS_ROW_X}    ${top}    200    330    ${item}
    END
    Press Key    escape
    Sleep    0.4s

Rename Row To
    [Documentation]    The menu's Rename, the name typed over the old one, Enter.
    [Arguments]    ${row}    ${name}
    Pick Row Menu Item    ${row}    Rename
    Press Keys    ctrl    a
    Type Text    ${name}
    Press Key    enter
    Sleep    0.8s

Engine Chip X
    [Arguments]    ${engine}
    ${x}=    Set Variable If    '${engine}' == 'jq'    ${ENGINE_JQ_X}
    ...    '${engine}' == 'pointer'    ${ENGINE_POINTER_X}
    ...    '${engine}' == 'jsonpath'    ${ENGINE_JSONPATH_X}
    ...    ${ENGINE_JMESPATH_X}
    RETURN    ${x}

Engine Chip Should Be Selected
    [Documentation]    `jq`, `pointer`, `jsonpath` or `jmespath` is the engine that is picked: its chip has the
    ...    colour of a selection.
    [Arguments]    ${engine}
    ${x}=    Engine Chip X    ${engine}
    ${left}=    Evaluate    int(${x}) - 16
    Region Should Contain Color    ${left}    32    32    12    0    92    128    tolerance=10
    ...    msg=The ${engine} chip is not picked

Engine Chip Should Not Be Selected
    [Arguments]    ${engine}
    ${x}=    Engine Chip X    ${engine}
    ${left}=    Evaluate    int(${x}) - 16
    Region Should Not Contain Color    ${left}    32    32    12    0    92    128    tolerance=10
    ...    msg=The ${engine} chip is picked

Status Line Should Match
    [Arguments]    ${pattern}
    ${x}    ${y}    ${w}    ${h}=    Set Variable    @{WS_STATUS_LINE}
    Wait Until Region Matches    ${x}    ${y}    ${w}    ${h}    ${pattern}    timeout=6

Open Item By Double Click
    [Arguments]    ${row}
    Double Click Row    ${row}

Click In Form
    [Documentation]    A click at the point of a window of the pane, given as the window has it.
    [Arguments]    ${x}    ${y}
    ${at}=    Form Y    ${y}
    Click At    ${x}    ${at}
    Sleep    0.4s

Open Save Form
    [Documentation]    The 💾 of the pane's header, and the window that saves what is in the box.
    Set Form Kind    save
    Click Header Button    save
    # (told by a line of its own: the title is dim when the window is not the one with the focus)
    Form Should Be Open    new folder in it

Save Query As
    [Documentation]    The window that saves, the name typed over what the Name box has (it has the focus when the
    ...    window opens; it has a name already when the box came from an item) and Enter.
    [Arguments]    ${name}
    Open Save Form
    Press Keys    ctrl    a
    Type Text    ${name}
    Sleep    0.3s
    Press Key    enter
    Sleep    0.9s

Choose Save Folder
    [Documentation]    The Folder box of the Save window, opened, and the folder in it that says `name`.
    [Arguments]    ${name}
    Click In Form    ${SAVE_FOLDER_X}    ${SAVE_FOLDER_Y}
    ${y}=    Form Y    ${SAVE_FOLDER_LIST}[1]
    Click Text In Region    ${SAVE_FOLDER_LIST}[0]    ${y}    ${SAVE_FOLDER_LIST}[2]    ${SAVE_FOLDER_LIST}[3]    ${name}
    Sleep    0.5s

Pick Engine
    [Documentation]    `jq`, `pointer`, `jsonpath` or `jmespath`: the chip of the engine picker.
    [Arguments]    ${engine}
    ${x}=    Engine Chip X    ${engine}
    Click At    ${x}    ${ENGINE_ROW_Y}
    Sleep    0.4s
    Move Mouse To    600    400

Paste In Source
    [Documentation]    The empty Source panel takes a document that is pasted into it.
    [Arguments]    ${text}
    Set Clipboard    ${text}
    Click At    ${WS_SOURCE_PASTE_X}    ${WS_SOURCE_PASTE_Y}
    Sleep    0.3s
    Press Keys    ctrl    v
    Sleep    0.8s

Type Name In Form
    [Documentation]    The Name box of the Save window, clicked (a click on a tab, a tick or a list took the
    ...    focus from it) and the name typed over what is in it.
    [Arguments]    ${name}
    Click In Form    ${SAVE_NAME_X}    ${SAVE_NAME_Y}
    Press Keys    ctrl    a
    Type Text    ${name}
    Sleep    0.3s

Drag Row
    [Documentation]    The left button pressed on row `from`, the pointer taken to row `onto` over half a second, and
    ...    the button let go: what a person does to move an item into a folder.
    [Arguments]    ${from}    ${onto}
    ${y1}=    Row Y    ${from}
    ${y2}=    Row Y    ${onto}
    Mouse Down At    ${WS_ROW_X}    ${y1}
    Move Mouse Slowly To    ${WS_ROW_X}    ${y2}    duration=0.6
    Mouse Up
    Sleep    0.6s
    Move Mouse To    600    400

Drag Row To
    [Documentation]    The same, to a point of the window.
    [Arguments]    ${from}    ${x}    ${y}
    ${y1}=    Row Y    ${from}
    Mouse Down At    ${WS_ROW_X}    ${y1}
    Move Mouse Slowly To    ${x}    ${y}    duration=0.6
    Mouse Up
    Sleep    0.6s
    Move Mouse To    600    400

Pick Up Row
    [Documentation]    The button pressed on row `from` and the pointer taken to `onto` (a row), the button kept down.
    [Arguments]    ${from}    ${onto}
    ${y1}=    Row Y    ${from}
    ${y2}=    Row Y    ${onto}
    Mouse Down At    ${WS_ROW_X}    ${y1}
    Move Mouse Slowly To    ${WS_ROW_X}    ${y2}    duration=0.6

Origin Label Right Edge
    [Documentation]    Where the label that says what the query box came from ends in the Query row.
    ${l}    ${t}    ${r}    ${b}=    Get Ink Bounds    @{QUERY_ORIGIN}    threshold=50
    ${edge}=    Evaluate    ${QUERY_ORIGIN}[0] + ${r}
    RETURN    ${edge}

Carry Row To
    [Documentation]    The button pressed on row `from` and the pointer taken to a point of the window over half a second, the button
    ...    kept down (what is carried is over the point).
    [Arguments]    ${from}    ${x}    ${y}
    ${y1}=    Row Y    ${from}
    Mouse Down At    ${WS_ROW_X}    ${y1}
    Move Mouse Slowly To    ${x}    ${y}    duration=0.6

Query Pane Should Be Lit
    [Documentation]    The Query pane has the bright outline that a folder has while a row that is carried would go into it, round
    ...    all of it (its bottom edge is read at the right, where the label that is carried does not cover it).
    Region Should Contain Color    256    23    944    5    192    222    255    tolerance=10    msg=The Query pane is not outlined above
    Region Should Contain Color    255    30    6    90    192    222    255    tolerance=10    msg=The Query pane is not outlined at the left
    Region Should Contain Color    1194    30    6    90    192    222    255    tolerance=10    msg=The Query pane is not outlined at the right
    Region Should Contain Color    900    119    300    8    192    222    255    tolerance=10    msg=The Query pane is not outlined under

Query Pane Should Not Be Lit
    Region Should Not Contain Color    256    23    944    5    192    222    255    tolerance=10    msg=The Query pane is outlined above
    Region Should Not Contain Color    255    30    6    90    192    222    255    tolerance=10    msg=The Query pane is outlined at the left
    Region Should Not Contain Color    900    119    300    8    192    222    255    tolerance=10    msg=The Query pane is outlined under

Row Should Be Lit
    [Documentation]    The row has the bright border that a folder has while a row that is carried would go into it.
    [Arguments]    ${row}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    ${y} - 9
    Region Should Contain Color    4    ${top}    248    18    192    222    255    tolerance=10
    ...    msg=Row ${row} is not lit

Row Should Not Be Lit
    [Arguments]    ${row}
    ${y}=    Row Y    ${row}
    ${top}=    Evaluate    ${y} - 9
    Region Should Not Contain Color    4    ${top}    248    18    192    222    255    tolerance=10
    ...    msg=Row ${row} is lit

Nothing Should Be Lit
    Region Should Not Contain Color    0    90    256    660    192    222    255    tolerance=10
    ...    msg=Something in the list is lit

Release And Close
    [Documentation]    A case that failed with the button down must not leave it down for the next.
    Run Keyword And Ignore Error    Mouse Up
    Close Jsonquery App

Query Box Should Be Empty
    [Documentation]    Nothing is in the query box: with the clipboard set to a marker, all of the box selected and
    ...    copied, the marker is still on the clipboard (copying nothing leaves it alone).
    Set Clipboard    nothing was copied
    Click At    ${WS_QUERY_X}    ${WS_QUERY_Y}
    Sleep    0.3s
    Press Keys    ctrl    a
    Press Keys    ctrl    c
    Sleep    0.4s
    ${text}=    Get Clipboard
    Should Be Equal    ${text}    nothing was copied

Form Should Match
    [Documentation]    A line of the window matches this regular expression (the lines that tell what a folder holds
    ...    or what is wrong are small, and OCR reads a letter wrong now and then).
    [Arguments]    ${pattern}
    ${x}    ${y}    ${w}    ${h}=    Form Region
    Wait Until Region Matches    ${x}    ${y}    ${w}    ${h}    ${pattern}    timeout=5

Open Pane Form
    [Documentation]    An item of the menu of the three dots, and the window it opens (told by a line that only it has).
    [Arguments]    ${menu_item}    ${token}
    Pick Pane Menu Item    ${menu_item}
    Form Should Be Open    ${token}

Open Export Form
    Set Form Kind    export
    Open Pane Form    Export the    To the folder

Open Import Form
    Set Form Kind    import
    Open Pane Form    Import a    From the folder

Open New Folder Form
    [Documentation]    The folder button of the pane's header, and the window that makes a folder.
    Set Form Kind    newfolder
    Click Header Button    folder
    Form Should Be Open    Inside

Open Delete Form
    [Documentation]    The menu of the row, its Delete…, and the question that asks before anything is deleted.
    [Arguments]    ${row}
    Set Form Kind    delete
    Pick Row Menu Item    ${row}    Delete
    Form Should Be Open    cannot be undone

Type In Export Folder
    [Documentation]    The folder box of the Export window, over what is in it (a place in the home of whoever runs
    ...    the cases: never exported to). `y` is 170, or 214 when the window has the choice of a folder above it.
    [Arguments]    ${path}    ${y}=170
    Click In Form    545    ${y}
    Press Keys    ctrl    a
    Type Text    ${path}
    Sleep    0.3s

Type In Import Folder
    [Documentation]    The folder box of the Import window, and the box left (a click on its label), which looks at the
    ...    folder: what it holds, or what is wrong with it, is said under the box.
    [Arguments]    ${path}
    Click In Form    545    148
    Press Keys    ctrl    a
    Type Text    ${path}
    Click In Form    420    128
    Sleep    0.8s

Make Export Folder
    [Documentation]    A folder that does not exist yet, to export to, in a temp directory.
    ${parent}=    Make Temp Directory
    RETURN    ${parent}${/}exported

Export To
    [Documentation]    The Export window, the folder typed over the default and the Export button.
    [Arguments]    ${path}    ${y}=170
    Type In Export Folder    ${path}    ${y}
    Press Primary Button
    Sleep    1.2s

Workspace Files Should Not Have Changed
    [Documentation]    The index that the workspace keeps is what it was: nothing was moved, renamed or written again.
    [Arguments]    ${before}
    ${after}=    Workspace Index
    Should Be Equal    ${after}[items]    ${before}[items]

Compare Indexes
    [Documentation]    Every item of `first` is in `second` with the same id and SHA-256.
    [Arguments]    ${first}    ${second}
    ${items}=    Set Variable    ${first}[items]
    FOR    ${path}    ${entry}    IN    &{items}
        Dictionary Should Contain Key    ${second}[items]    ${path}
        Should Be Equal    ${second}[items][${path}][id]    ${entry}[id]    msg=${path}: the id changed
        Should Be Equal    ${second}[items][${path}][sha256]    ${entry}[sha256]    msg=${path}: the SHA-256 changed
    END

Workspace Files Should Be
    [Documentation]    The files in the workspace (the app's own folder left out) are exactly these.
    [Arguments]    ${files}
    ${found}=    Workspace Files
    Lists Should Be Equal    ${found}    ${files}

Quit And Start Again
    [Documentation]    The window is closed as a person closes it (which is when the app writes what it keeps) and
    ...    the app is started again as the same user.
    ${ended}=    Quit Jsonquery App
    Should Be True    ${ended}    msg=The app did not end
    Close Jsonquery App    keep_home=${TRUE}
    Launch Jsonquery App    keep_home=${TRUE}
    Sleep    0.8s

Icon Should Be At
    [Documentation]    Something is drawn on the point: a button's icon, which OCR cannot read.
    [Arguments]    ${x}    ${y}
    ${left}=    Evaluate    int(${x}) - 10
    ${top}=    Evaluate    int(${y}) - 8
    Get Ink Bounds    ${left}    ${top}    20    16    threshold=60

Folder Should Be A Plain Folder At
    [Documentation]    The picture on the point is a folder as a file manager draws it: 14 by 11 points of one
    ...    colour, with the tab at the top left and nothing at the top right. Gives how bright it is.
    [Arguments]    ${x}    ${y}
    ${left}=    Evaluate    int(${x}) - 12
    ${top}=    Evaluate    int(${y}) - 9
    ${l}    ${t}    ${r}    ${b}=    Get Ink Bounds    ${left}    ${top}    24    18    threshold=${FOLDER_INK}
    ${width}=    Evaluate    ${r} - ${l} + 1
    ${height}=    Evaluate    ${b} - ${t} + 1
    Should Be True    13 <= ${width} <= 15    msg=A folder is 14 wide, this is ${width}
    Should Be True    10 <= ${height} <= 12    msg=A folder is 11 high, this is ${height}
    # The body: solid. The tab: the top left, which has ink; and the top right, which has none.
    ${centre_x}=    Evaluate    ${left} + ${l} + 7
    ${body_y}=    Evaluate    ${top} + ${t} + 7
    ${tab_x}=    Evaluate    ${left} + ${l} + 2
    ${tab_y}=    Evaluate    ${top} + ${t} + 1
    ${corner_x}=    Evaluate    ${left} + ${r} - 2
    ${corner_y}=    Evaluate    ${top} + ${t} + 1
    ${body}=    Get Pixel Color    ${centre_x}    ${body_y}
    ${tab}=    Get Pixel Color    ${tab_x}    ${tab_y}
    ${corner}=    Get Pixel Color    ${corner_x}    ${corner_y}
    ${bright}=    Evaluate    max($body)
    Should Be True    max($tab) >= ${FOLDER_INK}    msg=No tab at the top left: ${tab}
    Should Be True    max($corner) < ${FOLDER_INK}    msg=Ink at the top right, where there is no tab: ${corner}
    Colors Should Match    ${body}    ${tab}    tolerance=12    msg=The tab and the body are not one colour
    RETURN    ${bright}

Side Panel Icon Should Be At
    [Documentation]    The pane's button (the status bar's and the strip's) is drawn with its top-left pixel at (left, top), as the
    ...    picture of a window with its left column filled: bright when the pane is shown (`state` = shown), dim when it is not
    ...    (hidden); in the light theme (`light` = ${TRUE}) it is dark ink on the button.
    [Arguments]    ${left}    ${top}    ${state}=shown    ${light}=${FALSE}
    IF    ${light}
        ${ink}=    Set Variable If    '${state}' == 'shown'    ${INK_BRIGHT}    ${INK_ON_LIGHT}
        Icon Should Look Like    ${left}    ${top}    ${ink}    ${TRUE}    @{SIDE_PANEL}
    ELSE IF    '${state}' == 'shown'
        Icon Should Look Like    ${left}    ${top}    ${INK_BRIGHT}    ${FALSE}    @{SIDE_PANEL}
    ELSE
        Icon Should Look Like    ${left}    ${top}    ${INK_DIM}    ${FALSE}    @{SIDE_PANEL}
        ${region_left}=    Evaluate    int(${left}) - 2
        ${region_top}=    Evaluate    int(${top}) - 2
        Run Keyword And Expect Error    Nothing as bright as*
        ...    Get Ink Bounds    ${region_left}    ${region_top}    18    16    threshold=${INK_DIM_LIMIT}
    END

New Folder Icon Should Be At
    [Documentation]    The header's button that makes a folder is drawn with its top-left pixel at (left, top): a folder with a plus left
    ...    out of it (the plus is the button's own colour), 15 by 11. In the light theme (`light` = ${TRUE}) it is dark ink.
    [Arguments]    ${left}    ${top}    ${light}=${FALSE}
    ${ink}=    Set Variable If    ${light}    ${INK_ON_LIGHT}    ${INK_DIM}
    Icon Should Look Like    ${left}    ${top}    ${ink}    ${light}    @{NEW_FOLDER}

Tab Of The Save Window Should Be Picked
    [Documentation]    The tab of the Save window at this x (the one for a schema, a patch or the Source) has the colour of
    ...    a selection.
    [Arguments]    ${x}
    ${left}=    Evaluate    int(${x}) - 30
    ${top}=    Form Y    ${SAVE_TAB_Y}
    ${top}=    Evaluate    int(${top}) - 8
    Region Should Contain Color    ${left}    ${top}    60    16    0    92    128    tolerance=10
