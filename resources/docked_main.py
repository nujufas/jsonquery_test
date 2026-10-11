"""The main window with the Tools docked, as the suites of the main view see it.

The suites' coordinates (resources/keywords.resource and the cases) are those of the main
window with the Tools in a window of their own. Docked, the window has a row of tabs on top
(y 0-22, with its rule), under it the source field as the first row of the Json Query tab, and
everything else of the main view is as it was and 23 px lower, up to the status bar, which is
at the foot of the window and stays where it was. The test library moves a point or a region
by `JQ_DOCKED_DY` (or `Set Layout Shift`) for the main window while this profile is on (see
`AppLibrary._profile_y`), so a suite goes on saying "the source field is at y=11"; this file
is for what the move does not make right: the row of tabs, which has no counterpart in the
window and is *above* the suites' origin (so its y is negative: the row's middle, 11, less the
23 the library adds), the icons that moved from the toolbar into it or into the source row,
and what is wider or narrower than it was.

    JQ_TOOLS_PLACE=docked JQ_DOCKED_DY=23 ./run.sh suites/<a suite of the main view> \
        --variablefile resources/docked_main.py --exclude undocked-only

A suite that goes between the Json Query tab and the pages of the tools (suites/tools/
tools_docked.robot) imports this file with `Variables` before its resources, so that these
values are the ones it sees, and turns the move on and off with `Set Layout Shift`.
"""

DY = 23

# The row of tabs: y of its middle in the suites' coordinates (11 in the window, less DY).
TAB_ROW_Y = 11 - DY

# The centre of each tab. The first is the Json Query tab, which is the main view.
DOCKED_TAB_X = {"json": 44, "merge": 130, "format": 221, "diff": 304, "patch": 383, "validate": 480}

# The theme and the tutorial buttons are at the right end of the row of tabs, the tutorial
# beside the theme (the 🛠 button is gone, and the 💡 is not here but in the source row).
THEME_TOGGLE_X = 1182
THEME_TOGGLE_Y = TAB_ROW_Y
TUTORIAL_BUTTON_X = 1151
TUTORIAL_BUTTON_Y = TAB_ROW_Y
# (satellites.robot names its own copy of the same point)
TUTORIAL_X = TUTORIAL_BUTTON_X
TUTORIAL_Y = TAB_ROW_Y

# The 💡 is the last thing in the source row (x 1171-1192), and its probe pixel is the glyph's
# own, at the same place in the button as it is in the toolbar's.
AUTOCOMPLETE_TOGGLE_X = 1182
AUTOCOMPLETE_TOGGLE_Y = 11
AUTOCOMPLETE_ICON_PROBE_X = 1177
AUTOCOMPLETE_ICON_PROBE_Y = 10

# The source row has the room the 🛠 📖 💡 🌙 took in the toolbar: the field is 90 px wider
# (x 60-902), so "…", Load and Clear are 90 px to the right, and what is loaded ("(pasted
# JSON) 79 B") is after the divider, before the 💡. The group of buttons and label is as wide as the
# label is long (the field gives way), as it is in the toolbar: the region is the toolbar's, 90 px
# on, ending where the 💡 begins.
LOAD_BUTTON_X = 957
CLEAR_BUTTON_X = 1001
STATUS_AREA = [790, 0, 380, 20]

# The status bar has the 🗗 as well, at x 1086-1105 (left of the ⚙, the 🌐 and the ⓘ): with it in
# the region OCR misreads the text beside it (as it did with the ⚙ and the ⓘ, see keywords.resource).
STATUS_BAR = [0, 705, 1070, 95]

# The "..." button that opens the file dialog is in the source row too: 90 px to the right.
BROWSE_X = 920

# The size of a loaded file ("270.0 MB") is read between the divider that begins the group
# at the right end of the source row and the 💡 (heavy_files.robot's and opening_dialog.robot's own
# copies of the point).
BYTE_SIZE_AREA = [1038, 0, 135, 20]
FILE_SIZE_AREA = [1038, 0, 95, 22]

# What the app places by the window and not by the toolbar is where it was without the row of
# tabs, so in the suites' coordinates, which the library moves down by DY, it is DY higher: the
# Search dialog (near the window's top-left corner), and the list of hits, anchored to the foot
# (search.robot's own copy of its rows).
POPUP_DIALOG_AREA = [15, 15 - DY, 345, 130]
SEARCH_FIND_FIELD_Y = 84 - DY
SEARCH_REGEX_CHECKBOX_Y = 106 - DY
SEARCH_FIND_Y = 127 - DY
SEARCH_FIND_ALL_Y = 127 - DY
SEARCH_CANCEL_Y = 127 - DY
SEARCH_STATUS_AREA = [20, 136 - DY, 330, 22]
HIT_ROW_1_Y = 628 - DY
HIT_ROW_2_Y = 646 - DY
HIT_ROW_3_Y = 664 - DY

# The button that brings every popped-out pane back is in the source row, left of the 💡 (it is
# beside the 🛠 in the toolbar).
DOCK_ALL_X = 1153
DOCK_ALL_Y = 11
