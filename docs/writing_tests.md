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
- **Confirmed, and a real limit on scope**: the native file dialog (the `…`
  button beside the source field) and the Save dialogs hang or fail before
  showing anything usable, in every environment tried, due to an `rfd`-vs-non-GTK-toolkit integration gap. Every test case
  that depends on one of those dialogs completing is marked **Blocked** in
  the traceability matrix, not implemented as a false pass — all of them
  need an app-side `Cargo.toml` change to ever unblock.

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
   `Passing`, `Blocked` or `Not implemented`, with the reason.

Shared keywords and layout constants are in `resources/keywords.resource` (and
`resources/tools.resource` for the Tools window); the low-level keywords (clicks, typing, OCR,
pixels, the clipboard, windows, drops) are in `resources/AppLibrary.py`. Every region and click
point is relative to the app window and calibrated against the default 1200x800 window in the
Dark theme. When the app's layout changes, recalibrate from screenshots rather than from layout
arithmetic (see *Redesign pass* in [00_test_strategy.md](00_test_strategy.md)).

While writing a case, run just that one:

```sh
./run.sh suites/<area>/<file>.robot --test 'TC-XXX-NNN*'
```

and check that it can fail: run it against a build with the behaviour broken and confirm that it
fails at the intended assertion (*Mutation checks* in [00_test_strategy.md](00_test_strategy.md)).

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
