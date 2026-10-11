"""Variable file for running the Tools suites (suites/tools/) with the Tools docked.

    JQ_TOOLS_PLACE=docked JQ_WINDOW_SIZE=900x580 ./run.sh suites/tools \
        --variablefile resources/docked_tools.py --exclude window-only --exclude main-layout

The main window is then as big as the Tools window and the page of a tool, in its tab, is
the Tools window's own pixel for pixel (checked: no differing pixel between y 23 and 557),
so the cases and their coordinates are unchanged. What differs is only what is around the
page: the row of tabs, which has the Json Query tab first and the theme and the tutorial at
its right end, and the status bar, which has three icons at its right end. The title the
cases look for is the main window's: the Tools are in it.
"""

TOOLS_PLACE = "docked"
TOOLS_WINDOW = "JsonQuery"

# The centre of each tab of the row, which begins with Json Query (43..77) and has no gap
# for the 🛠 button: 130 is the middle of "Merge JSON", and so on.
TAB_X = {"merge": 130, "format": 221, "diff": 304, "patch": 383, "validate": 480}

# What the status bar of the page says is at its left end; the icons are at x 815-892.
TOOLS_STATUS = [0, 558, 800, 22]
STATUS_LINE = [0, 560, 800, 18]
