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
  "jsonquery — Query" literally — `AppLibrary` wildcards non-ASCII runs.
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
