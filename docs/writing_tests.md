# Writing and changing test cases

What to know before adding or changing a case: what the investigation confirmed, how a case is
specified and implemented, and the gotchas collected while building the suite. The reasoning
behind the whole approach is in [00_test_strategy.md](00_test_strategy.md); every case is indexed
in [99_traceability_matrix.md](99_traceability_matrix.md).

## What was confirmed

- **Confirmed**: accessibility-tree automation doesn't work on this app/stack
  (empirically investigated, not assumed).
- **Confirmed**: real-desktop screen capture is blocked on GNOME/Wayland —
  the suite runs against an isolated Xvfb display instead (`run.sh`
  handles this), with a minimal window manager (`fluxbox`) alongside it,
  because bare Xvfb silently breaks keyboard focus.
- **Confirmed, then overcome**: the native file dialogs (the `…` button beside the source field, every
  `Save…`) hang or fail before showing anything usable under every real portal tried — an
  `rfd`-versus-non-GTK-toolkit gap. The cases that depend on them were **Blocked** until 2026-10-06,
  when the harness started answering the dialogs itself with a stand-in for the desktop's file-chooser
  portal (`resources/fake_portal.py`). See [Writing a case that uses a file dialog](#writing-a-case-that-uses-a-file-dialog)
  and "Native OS dialogs" in [00_test_strategy.md](00_test_strategy.md).

## Adding or changing a case

1. **Specify it** in the document of its area, `docs/NN_<area>.md`: an ID of the form
   `TC-<AREA>-NNN` with Preconditions, Steps, Expected, Automation notes and Priority. The fields
   are explained at the end of [00_test_strategy.md](00_test_strategy.md#test-case-fields-used-consistently-in-every-feature-doc).
2. **Implement it** in the suite of that area, `suites/<area>/`. The case is named
   `TC-<AREA>-NNN <Title>` and tagged with its priority, `p1`, `p2` or `p3`. A new suite file
   starts with the settings every file needs (Robot does not allow them in a `.resource` file):

   ```robot
   *** Settings ***
   Resource          ../../resources/keywords.resource
   Force Tags        <area>
   Suite Setup       Start Test Display
   Suite Teardown    Stop Test Display
   Test Setup        Launch Jsonquery App
   Test Teardown     Close Jsonquery App
   ```

3. **Index it**: give its row in the [traceability matrix](99_traceability_matrix.md) a status,
   `Passing`, `Blocked` or `Not implemented`, with the reason. For a new suite file,
   `python scripts/robot_cases.py --matrix suites/<area>/ suites/<area>/<file>.robot` prints the rows
   (without `--matrix`, a table of ID, title and priority for the feature document).

Shared keywords and layout constants are in `resources/keywords.resource` (and
`resources/tools.resource` for the Tools window, `resources/results.resource` for the Results pane,
the CSV/TSV note and the file dialogs, `resources/tutorial.resource` for the lessons); the low-level
keywords (clicks, typing, OCR, pixels, the clipboard, windows, drops, the stand-in portal) are in
`resources/AppLibrary.py`. Every region and click
point is relative to the app window and calibrated against the default 1200x800 window in the
Dark theme. When the app's layout changes, recalibrate from screenshots rather than from layout
arithmetic (see *Redesign pass* in [00_test_strategy.md](00_test_strategy.md)).

While writing a case, run just that one:

```sh
./run.sh suites/<area>/<file>.robot --test 'TC-XXX-NNN*'
```

and check that it can fail: run it against a build with the behaviour broken and confirm that it
fails at the intended assertion (*Mutation checks* in [00_test_strategy.md](00_test_strategy.md)).

## Writing a case that uses a file dialog

The app asks the desktop's file-chooser portal; `Start Test Display` starts a stand-in on a private bus
and every app the suite launches is pointed at it. A case says what the person does *before* the click
that opens the dialog, and the stand-in answers it:

```robot
${dir}=    Make Temp Directory
Save Results Suggested In    ${dir}                # Save..., accept the name the app suggests
Wait Until File Has Lines    ${dir}/results.csv    3
```

| Keyword | What the person does |
|---|---|
| `Portal Will Save To  path` | types that name and presses Save |
| `Portal Will Accept Suggested Name In  dir` | presses Save without typing: the file is `dir/<the name the app offered>` |
| `Portal Will Pick  path...` | picks one file, or several for Add files… |
| `Portal Will Cancel` | closes the dialog (a dialog with no answer queued is cancelled too) |
| `Get Portal Requests` | what the app asked, one dict per dialog: `method` (`OpenFile` or `SaveFile`), `title`, `current_name`, `current_folder`, `filters`, `multiple`, `directory` |

`Browse And Choose path` (results.resource) is the whole open journey; `Save Results Suggested In dir` and
the other `… Suggested In` keywords are the save ones. A few rules, all learned the hard way:

- **A click sent while a dialog is open is lost** — the UI thread is inside the call.
  `Wait Until Portal Is Asked` waits for the answer and for the app to carry on; the keywords above
  already call it. A case with several dialogs counts them (`Portal Request Count`, `Wait For Dialog After`).
- **The stand-in answers after 0.4 s on purpose.** `rfd` freezes for good if the answer arrives together
  with the method reply (it is then in a queue nobody reads); a real portal answers when a person has
  chosen. Do not "speed it up".
- The file is written by the app's worker thread a moment after the dialog closes: read it with
  `Wait Until Keyword Succeeds … File Should Be …` or, for a big file, with `Wait Until File Has Lines`
  / `Wait Until File Holds Json`, which wait for *progress* (a busy machine can write a 25,000-line file at
  a few hundred lines a second) instead of a fixed budget.
- The dialogs themselves — their look, the folder they open in — belong to the desktop and are not tested.

## Writing a case about a link (or the 🌐)

A link in the app, and the 🌐 in the status bar, hand an address to the person's browser. The app's browser
crate runs `$BROWSER`, else `xdg-open`, else the desktop's own opener, and a browser that is already running
takes the address as a new tab: a case that clicks one on a real desktop would open a page on the desk of whoever
ran the suite. So every app the suite launches gets a stand-in (`BROWSER_OPENERS` in `resources/AppLibrary.py`):
`$BROWSER` is a script that writes the address and opens nothing, and the app's `PATH` holds only links to it,
named like each program the crate could try ([23_website.md](23_website.md), "How the cases keep the browser
away"). A case says what it expects the app to have opened:

```robot
Click At    ${GLOBE_X}    ${BAR_Y}
Opened Addresses Should Be    https://jsonquery.dev/              # exactly this, once, in this order
Nothing Should Have Been Opened                                  # after a hover, a click beside the link...
```

- **The address has a slash at the end**: the crate normalises `https://jsonquery.dev` to `https://jsonquery.dev/`.
- **The stand-in runs after the click**, in the background; `Opened Addresses Should Be` waits for the addresses
  and then a little longer (`settle`, 0.6 s) for one that should not come (a click that opens the site twice), and
  `Nothing Should Have Been Opened` waits too, before it says that nothing came. Read the list (`Opened
  Addresses`) only when a case needs it to be exact at an instant.
- **The list is the launch's**: it is emptied by every `Launch Jsonquery App`, so a case sees what its own app
  opened. It counts everything: two clicks are two addresses.
- **A case must ask about every address its app opened**: `Close Jsonquery App` (the teardown) fails the case
  when the stand-in was given one that no `Opened Addresses Should Be` looked for. A case about something else
  therefore fails, with the address, if one of its clicks lands on a link or on the 🌐 by mistake; a case that
  clicks one on purpose asks (the count is what it asked for last, so ask again after the next click).
- **A pixel that moves is a link or a button that is not the one meant**: the 🌐 took the ⚙'s place (x = 1152),
  and a case that still clicked there opened the site, not Settings. Before a click near the right end of the
  status bar, read the constants in `resources/docked.resource` (`SB_*`), not an older case.
- The stand-in is checked when the display starts (executable, runs, writes its log), because the crate skips a
  `$BROWSER` that is not executable **without a word** and falls through to the real default browser; a suite
  whose stand-in does not work stops at its set-up.

## Writing a case about what the app keeps (settings)

The app keeps `settings.json` in a folder of its own, and every `Launch Jsonquery App` gives it a new
one (`JSONQUERY_HOME`, empty, removed when the app is closed), so a case starts as the first start of a
new user and never sees what an earlier case left, nor the `~/.jsonquery` of whoever runs the suite.
A case reads the file rather than OCR: the app writes it a moment after the change, so wait for it.

| Keyword | What it does |
|---|---|
| `Launch Jsonquery App  settings=<text>` | starts with that text as the `settings.json` (valid, wrong or not JSON at all) |
| `Quit Jsonquery App` | closes the window as a person does and waits for the app to end; true if it did (what the app writes as it ends is only written then) |
| `Close Jsonquery App  keep_home=${TRUE}` then `Launch Jsonquery App  keep_home=${TRUE}` | the next start, as the same user: the folder of the last launch is used again |
| `Settings Value  path` | what the file has at a dotted path (`limits.copy`, `window.width`), or `None` for no file or nothing there |
| `Settings Value Should Be  path  expected` | the same as an assertion: text as it is, a number as a number, `None` for nothing |
| `Settings File Exists` | whether there is a file (a start that changes nothing writes none) |
| `App Home` | the settings folder of the running app, to read the file as it is |
| `Resize Window  title  w  h`, `Maximize Window  title` | what dragging the edge, or the maximize button, does (through the window manager) |

Wrap the read in `Wait Until Keyword Succeeds` (the suite does, as `Setting Should Be`). The first case,
[TC-SET-001](21_settings.md), shows opening the window; the regions and rows of the Settings window are
variables at the top of `suites/settings/settings.robot`.

## Writing a case about a text's right-click menu

A text box, a read-only text and the lines of some lists have a right-click menu
([24_text_menus.md](24_text_menus.md)). A case clicks the item by its distance under the pointer and reads
what it did from the clipboard:

```robot
Set Clipboard    nothing was copied                    # a menu that did nothing fails
Open Text Menu    ${x}    ${y}    Select All           # right-click, wait for a bright word of the menu
Pick Menu Item    ${x}    ${y}    ${offset}            # Cut 16, Copy 37, Paste 58, Select All 79 (21 apart)
Clipboard Should Be    the text                         # polled: a copy reaches the clipboard a frame or two later
```

(`Open Text Menu`, `Pick Menu Item`, `Choose From Text Menu`, `Clipboard Should Be` and the other keywords are
in the suites' own `*** Keywords ***` sections, `suites/text_menus/` and `suites/tools/tools_menus.robot`.)
The rules, learned on the way:

- **The menu opens with its top-left corner at the pointer**, and the first item is 16 px under it. A menu of
  a text that is only shown has two items (Copy, Select All), a line of a list has what it can give, the
  menu of a changed side-by-side line has a separator after its two moves (Copy path is then 67 px under).
  Near the foot of the window the menu opens *above* the pointer (the status bar's messages): find the item by
  OCR (`Click Text In Region`) in a region that reaches above and below the point.
- **Only a word that is bright is read.** Cut and Copy are dim until something is selected, Select All is dim in
  an empty box: ask for `Paste` of a box, `Select All` of a text that is only shown.
- **A click on a dim item closes the menu and does nothing**: a case about "Copy is dim" clicks it and checks
  that the clipboard is still the marker.
- **A menu of one item is narrow** (a message, a link): click 20 px right of the pointer, not at its x.
- **Paste and Cut take a frame**: the window system answers with the event of the key. Wait 0.5 s after the
  click.
- **To read a box that should be empty**, set the clipboard to the marker, click in the box, Ctrl+A, Ctrl+C: the
  marker is still on the clipboard (`Query Box Should Be Empty`, `Box Should Be Empty`).
- **Find a link by its last word**: `Find Text In Region` finds a single word first and, failing that, the
  words of a whole line joined, and answers with the middle of the line.
- **A list anchored to the foot of the window** (the hits of Find All) does not move in the docked run: read
  its row from a variable that `resources/docked_main.py` knows (`${HIT_ROW_1_Y}`).

## Writing a case about the workspace (the pane at the left)

The pane is a view of a folder on the computer ([25_workspace.md](25_workspace.md)), so a case makes the folder
before the app starts and reads it afterwards, in Python, and uses the screen only for what a person sees:

```robot
Launch Workspace App                                  # the pane open, the files of STANDARD in the workspace
Launch Workspace App    files=${MANY}                 # another dictionary of "path with / -> text"
Pick Up Row    ${ROW_SCRATCH}    ${ROW_SERVICES}      # press on a row, carry it over another (real mouse, in steps)
Mouse Up
Workspace File Should Exist    Services/scratch.jq    # the folder, not the screen
${item}=    Workspace Item    Services/scratch.jq      # the index's entry: id, sha256, bytes, sample
```

- **Rows are counted, not found.** A row is 20 points high from y = 93 and `${ROW_...}` (or its number) is
  its place in `STANDARD`; `Row Y` gives its middle. Names are chosen so that OCR reads them (`update`, not `bump`),
  and the order is the app's (folders first, then by name; `.patch.json` before `.schema.json`).
- **A drag is three steps**: `Mouse Down At`, `Move Mouse Slowly To` (half a second, in steps: a jump is not reliably
  seen as a drag) and `Mouse Up`. A press that moves a little is a click (`Click With Wobble`). What is lit while a row
  is carried is read in pixels (`192, 222, 255` is the bright border), what is said beside the pointer by OCR.
- **The pointer is put away** (`Move Mouse To 600 400`) before a colour or a small grey text is read: a row under the
  pointer is lit, and a button under it has a tooltip, which covers the line under the title (TC-WSP-217 found that).
- **The windows of the pane are told to the keywords** by `Set Form Kind` (`save`, `newfolder`, `export`, `import`,
  `delete`), so that OCR is asked about a region as tight as the window; their buttons are found by their fill, not
  by their label (`Press Primary Button`, `Press Cancel Button`): OCR reads a button's label badly among the lines of
  a window.
- **A button is told by its width when OCR cannot read it**: `Primary Button Should Be This Wide  28  42` (Save is 34
  wide, Replace 53); the order of two buttons under the list by `Details Buttons Should Be In Order  schema  sample`.
  A word in a message is not checked by the word alone when the message ends with a path that may contain it: the case
  for the export asked for `Exported` and passed for a message that said `Copied`, because the folder was called
  `exported` (`Exported +[^ ]{1,3} +ite` is the number after it).
- **A name is read in its own row** (`Region Should Show Text  0  <row y - 10>  256  20  scratch`), not in the whole list:
  the details under the list say the name of the item that is picked as well.
- **Which window is in front is the window manager's to say** (`Active Window Title`): `Switch To Window` and
  `Switch To Main Window` raise the window they are told to, so a case that must know that the *app* brought a window
  forward (TC-WSP-240) reads the title before it switches.
- **A point that the window anchors by itself does not move when the Tools are docked** (the foot of the list, the
  windows the pane opens, the status bar): say it by a variable (`${WS_LIST_FOOT_Y}`) that `resources/docked_main.py`
  overrides, as for the other anchored points above.
- **A file that a script cut and pasted** (moving keywords between files) can be left with a case or a keyword twice, or a
  `*** Keywords ***` section inside another: Robot does not always say so (it ran such a suite, with one case in the
  keywords). `scripts/robot_lint.py suites/workspace resources/workspace.resource` finds a case id or a keyword that is
  there twice, a section header that is there twice and a keyword name that has arguments in it.
- **In an `Evaluate`, write a backslash twice** (`b"\\xff\\x00"`): Robot turns `\x00` into the character before Python
  sees the expression, and a NUL in the source is an error (TC-WSP-209).
- **An icon is a picture, and the case says it as one** (`Icon Should Look Like  left  top  threshold  dark  @{rows}`;
  `Side Panel Icon Should Be At`, `New Folder Icon Should Be At`): rows of `X` (ink), `.` (none) and `?` (either), read
  from the pixels of the region with two clear pixels round it. `?` is for the pixels at a rounded corner, which the
  threshold decides: the same icon on a button (60) and on the strip's ground (27) has different pixels over 90 at its
  corners. The bright icon is read over 150 and the dim one over 90, and "dim" is also "nothing as bright as 150"
  (`Run Keyword And Expect Error  Nothing as bright as*  Get Ink Bounds ...`). Measure the picture first, from a
  screenshot of the real window (a script that prints `Get Ink Art` for the region), and not from the drawing code.
- **A screenshot probe that takes the whole bar takes its rule and its neighbours**: the status bar has a rule at its top
  that is as bright as a button (60), and the Source box's edge is over 90 above the bar when the bar is short; the
  region of a probe begins under what is not the thing, and for a button it is its *picture* (over 90) that is measured, not
  its fill (TC-WSP-246 failed twice on that, and once on the splitter between two panes, which is white while the
  pointer is on it).
- **What begins at the left end of the status bar is read from x = 36**: the pane's button is at x 8-31 and the text is
  from x 41, so the regions that read the text (`@{STATUS_BAR}`, `@{WS_STATUS_LINE}`, the docked profiles') begin after
  the button, for the reason that they stop before the icons at the right: OCR reads an icon beside a word as noise.
- **A file is dropped by name, in the middle of the window**: the app is never told where it was let go (TC-WSP-261 and
  [16_drag_and_drop.md](16_drag_and_drop.md)), so a case does not try a pane, and does not drop a file that is not there:
  the toolkit drops the drop. A file that is too big is made without the text going through the log
  (`A Query File Of Dots`: `Evaluate  pathlib.Path($path).write_text('.' * int($size))`).
- **A message in the status bar is read with a pattern that allows the space OCR loses** (`Load error.{0,3} ?big\.? ?jq`,
  `?as ?the ?query`), and a file extension is not trusted to be read right: `.jq` came back as `.ja`.
- **That a message is gone is checked beside something that is still there**: `Region Should Not Contain Text` passes
  just as well when OCR read nothing of the bar, so TC-WSP-291 reads "Parsed" (what the bar says of the document)
  before and after, and retries the missing message until the window has been redrawn. A test of the app that clears
  the state it is about to look at (`load_error = None` before the good file is dropped) cannot see a message that
  stays: that is how the stale "Load error" of a failed query-file drop went unseen for a round.
- **A web address is loaded from a server of the case's own** (`Launch With Web Addresses  ${SERVED}  ${{ {"Sources/feed.url": "/valid.json"} }}`
  gives its address): the server is on 127.0.0.1, on a port of its own, and writes down what it is asked for, so a case
  says that a click that only picks asked for nothing and that a load asked once, for this path with this query
  (`Fixture Server Should Have Been Asked For  /v1/orders.json?page=2`, which waits for what should come and then a moment for what
  should not). The suite's teardown stops it (`Stop Server And Close App`). The Source field is read by copying it
  (`Source Field Should Hold`): OCR reads a port number badly.
- **The bytes of a file are read as bytes** when the line end is the point: `Workspace File Should Be` reads text, and Python's text
  mode makes a CR LF one `\n`, so a `.url` file written with LF would have been the file a case expected
  (`Workspace File Should Hold Bytes`).
- **A box of a window is read by copying it, not by OCR**: the address and the name of the Save window (`Address In Save Form Should Be`,
  `Name In Save Form Should Be`); an empty box is the marker that is still on the clipboard. A box that is typed into without a click
  in it is a case about the focus (TC-WSP-301, 317): the choice is clicked and the keys are sent at once.
- **A window that grows moves what a case clicked**: the Save window is 13 points wider with its fifth choice, so its cross and its choices moved
  (TC-WSP-071 and 077 failed on it), and with the Web address chosen it is 40 points taller. Read the window again (a screenshot with a
  grid is enough) when a choice is added.
- **A tag is told by its fill and its width**: the tag of a web address is 19 points wide, that of a document 24 and that of a jq query 15
  (`Tag Width`); a paperclip is told by where the tag ends (242 without one, 229 with), because the paperclip's place is where the
  tag of an item with no sample ends.
- **Run lanes from a frozen copy of the test repository** while editing: Robot reads a `.resource` file when the
  suite that imports it starts, so a keyword that is changed under a lane that is running breaks the lane (a
  half-written file is a suite that does not parse). A copy with `rsync` (without `results` and `.git`, `.venv`
  linked) is what a long run reads.

## Writing a case that also runs with the Tools docked

`./run_docked.sh` runs the suites a second time with the Tools docked in the main window as tabs
([22_tools_docked.md](22_tools_docked.md), "The other suites, docked"), without a word changed in a case.
What a case has to do for that is little:

- **Say where a point is by a variable** when it is a button of the toolbar (the theme, the tutorial, the 💡, the
  source row's `…`, Load and Clear, the loaded source's label), a point of a dialog the app puts by the window
  (the Search dialog, the list of hits at the foot) or a region of the status bar: the docked pass overrides the
  variable (`resources/docked_main.py`, `resources/docked_tools.py`), and a number written into a case cannot be
  overridden. A new constant is a variable in the suite that owns it (`${BROWSE_X}`, `@{STATUS_LINE}`).
- **Do not read the window's content under the toolbar from the first row of the window**: the library moves a
  point by the height of the row of tabs for the main window and for no other window, and does not move one in
  the strip at the foot (30 px), or a region that reaches into it. So `Click At 100 58` is the query box in both
  places, and `Get Pixel Color 1181 789` is the ⓘ in both.
- **Tag the case when it cannot be the same case docked**: `window-only` (it is about the Tools *window*: the 🛠
  button, closing or maximizing the window, its size, several windows at once), `main-layout` (it reads the main
  window's own layout in the middle of a tool's case: a document opened in the main window, the toolbar's
  status area), `undocked-only` (it is about the toolbar or about a settings file that is not there before
  something changes), `uses-tools` (a case of another suite that the *tools* pass runs). A tag is a promise
  that the docked suite has the counterpart.
- **A case of `tools_docked*.robot`** goes between the Json Query tab and a tool's page, which have different
  layouts: `Show Docked Tab    <json|merge|format|diff|patch|validate>` clicks the tab and says which layout
  the points are in from then on (`Set Layout Shift 0` for a page, the shift for the Json Query tab), and
  `Without Layout Shift` runs a keyword with the shift off for a point of the row of tabs or the status bar.

The shift is a test-library setting of one run (`JQ_DOCKED_DY`) or of a case (`Set Layout Shift`), and every app the
library starts begins with the run's. It is not in the app: the app has no test mode.

## Gotchas

The OCR- and coordinate-based interaction technique that works, and a growing list of sharp,
non-obvious findings, worth reading before extending any suite:

- pyautogui's key name for Enter is `enter`, not `Return`.
- `pyautogui.hotkey()` needs an explicit `interval` between keys (0.05s) —
  the default (all keys sent essentially at once) is a real source of
  "Ctrl+Enter sometimes doesn't register" flakiness.
- A region cropped too tightly to one line of text can make Tesseract's
  layout analysis fail outright (pure noise, not just a bad read) — add
  vertical margin rather than cropping exactly to the text.
- Tesseract, at this font size, sometimes reads "0" as "O" and "jq" as
  "iq", and can insert a stray space around punctuation (e.g. splitting
  "valid.json" into two word-boxes). `AppLibrary._text_contains` has
  permissive fallbacks for the first and third; the second is worked
  around per-assertion.
- `ui.weak()`-styled (low-contrast) text — placeholder hints, match
  counts, "No matches found." — is confirmed unreliable for OCR even with
  plenty of crop margin. Assert on adjacent normal-contrast content
  instead of chasing it.
- A right-click, or a click immediately after typing into a field (the
  Search dialog's submit buttons), occasionally doesn't register
  on the first attempt. The shared keywords (`Open Row Context Menu`,
  `Load Via Url`, `Search For`) all retry-and-verify rather than assuming
  one attempt always works.
- Some panels (confirmed: the bottom hit-list panel) size themselves to
  their content rather than staying a fixed height/position — don't
  calibrate a fixed y-coordinate against only one content size; use one
  wide region plus OCR-based lookups (`Click Text In Region`) instead.
- Pasting only loads anything while the empty-state "Paste JSON here…" box
  is showing — once a document is loaded there's no box left to paste
  into, so Ctrl+V silently does nothing. Loading a *second* document over
  an already-loaded one needs `Load Via Url` instead.
- A pane popped out into its own window is a second X window of the
  app (`popout/`). `Switch To Window` / `Switch To Main Window` retarget
  every click and read; `Close Window` closes one through the window
  manager (the windows are undecorated, like the main one, so there is no
  close button to click); `Maximize Window` maximizes one, and its icon in
  the corner is then at `Get Window Size` width − 16, not at a fixed pixel.
  `xdotool search --name` can't match the em dash in
  "JsonQuery — Query" literally — `AppLibrary` wildcards non-ASCII runs.
- Keep the header rows out of OCR regions that read *content*: the Source
  and Results headers each have a small icon button, and with it inside a
  600x600 crop Tesseract's `--psm 6` layout analysis flipped for some
  content (a third result row read as garbage; the same screenshot read
  fine with the icon erased, or the header cropped off). `@{SOURCE_PANEL}`
  and `@{RESULTS_PANEL}` therefore start below the header.
- A multi-line paste (`Set Clipboard` + Ctrl+V) is the quick way to put a
  long query in the box; a Robot cell that starts with `#` is a comment, so
  escape it (`\#`) when typing one.
- **Exact text goes through the clipboard, not OCR.** Press a result's Copy
  button and compare `Get Clipboard` with the whole expected text
  (`Copy Should Give`, which sets a marker first so a dead button fails).
  OCR reads small monospace punctuation badly (`"b": 1,`, `)` after a digit,
  `1 of 2` as `1o0f2`, the `.` of `broken.json`): ask it for words and for the
  status bar, and use pixels for state — `Get Ink Bounds` (is a button's label
  dim, ~112, or bright, ~180–240; how tall is this title), `Region Should Be
  Plain` (nothing drawn here: no line), `Get Rows With Color`.
- **Files can be dropped.** `Drop Files On Window x y path...` is a real XDND
  source (`resources/xdnd.py`, python-xlib): it reaches what `xdotool` can't — the
  Merge page's list, "drop a file anywhere", the Tools boxes. See
  [16_drag_and_drop.md](16_drag_and_drop.md). Fixtures for it are in `resources/fixtures/merge/`.
- A window the main window covers completely is not redrawn by eframe, and
  ignores a close request. `Switch To Window`, `Switch To Main Window` and
  `Close Window` therefore raise the window (`wmctrl -a`: with fluxbox
  `xdotool windowraise` only reorders the client inside its frame). The
  tutorial and the Tools window open over the main window, so reading the main
  window while one is open reads that window unless the main one is raised.
- A crop much taller than the one line of text in it reads as noise (a box 220px
  tall round a one-line JSON text read as `''`): read the top 40px of a box.
  A caret or a pointer hovering a field can also blank a crop; grey text on a
  grey row (the Merge list's file names) reads as nothing — count rows by pixels.
- A tinted query box reads badly even for `.name` (`.-hame`): `Query Text Should
  Be` selects all, copies and compares the clipboard.
- Never launch the app by hand outside `run.sh`/`AppLibrary` — not even
  `--help`: a shell on this machine has the real `WAYLAND_DISPLAY`, and the app
  opens a window on the live session. Kill test processes by PID or `pkill -x`,
  never `pkill -f` (it matches its own shell and other projects' runs).

### Found while writing the CSV, jq-function, tutorial and workflow suites

- **A query that ends in `@csv` or `@tsv` is not JSON.** Copy to Clipboard, the Text view and Save…
  then write its rows as text, so `Results Should Be Json` fails for it by design; compare with
  `Results Should Be Text` / `Copy Should Give` (see [18_output_formats.md](18_output_formats.md)). Wrap the
  call in `try … catch .` to get JSON back when the case is about an error.
- **Expected values come from jq 1.8.1** (`jq -c '[ QUERY ]'`), written into the case, so the suite
  needs no jq. Its wording of errors differs from jq 1.7 and from the app's: assert the part the two share.
- **Menu items are clicked by their distance from the pointer**, not read: a context menu laid over a row of
  backslashes defeats OCR. From the right-click point: Save… +55/+16, Copy to Clipboard +37,
  Copy JSON Path +58 (`Copy All Results`, `Copy Result Row`).
- **Dim text is only readable from a crop one line high with `psm=7`** (the status line's "Saved to …"). The CSV/TSV
  note is too dim even for that: its presence is a pixel probe (`Get Ink Bounds`, `Region Should Be Plain`)
  and its words are read from its tooltip.
- **White on blue is unreadable**: a selected popup row, the tutorial's ▶ Try it. Accept the suggestion with Enter
  and read the query box back (`Query Text Should Be`); find the button by its fill (`Find Color Blocks`,
  `First Block Below`).
- **A selectable label is only as wide as its text**: a click at the middle of the tutorial's row for "IN" (which ends at
  x=43) missed; the lesson list is clicked at x=36.
- **Do not press an engine button twice in one case**: clicking the selected engine deselects it and goes
  back to auto-detect. The jq-function cases leave the engine on auto-detect, as a person does.
- **Never reuse a display while an earlier run on it is alive**, and never kill an Xvfb under a run: the run
  goes on and fails in ways that look like app bugs. Give every lane a fresh display.
- A Robot cell splits at two spaces; a backslash is written doubled (`\\"`, `\\n`); `Evaluate` cannot see
  `$variables` inside a generator expression (use a keyword); `--test` globs know only `*` and `?`.

### Found while writing the settings suite

- **Do not OCR across icons.** An icon-only button reads as noise (`©`, `2`, `0)`), and noise at the end of a
  line changes how Tesseract reads the text before it: with the ⚙ beside the ⓘ it read `[JSONPath` as
  `SSONPath` (TC-QRY-012), while either icon alone was harmless. `@{STATUS_BAR}` therefore stops short of them.
  To find out which part of a region does it, replay the saved screenshot of the failure through the same
  call (`resize` ×5, `pytesseract.image_to_data --psm 6`) with parts painted over; the result is the same on every run.
- **A check that something was *not* written has to wait.** The app writes a moment after a change (the layout
  has to hold still for a quarter of a second, then be unchanged for half), so "nothing is in the file" looked
  at once passes against an app that writes late — a mutant did exactly that to TC-SET-023. Wait as long as a
  wrong write would take (1.5 s) and then look.
- **Read what the app kept from the file, not from the screen.** A long path in small type loses its dot
  (`settings json`), and a warning in amber is read differently on every run; the file is exact and the
  warning is found by its colour (`Region Should Contain Color`, TC-SET-012).
- **"The next start" is the same folder, a new process.** `Quit Jsonquery App` (close as a person does, and wait),
  then `Close Jsonquery App keep_home=${TRUE}` and `Launch Jsonquery App keep_home=${TRUE}`. Killing the app
  would test what it writes when it is killed, which is nothing.
- **fluxbox does not honour a window's request to start maximized**, so a case about a window that starts
  maximized only passes if the app asks again once it exists (TC-SET-024: without it the window is 1000 wide).
- **Xvfb needs room in `/tmp`** even when everything else is on disk — see "Isolation" in
  [00_test_strategy.md](00_test_strategy.md).
