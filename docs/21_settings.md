# Settings — test requirements

The app keeps one small file of settings, `settings.json` in the folder `.jsonquery` of the
person's home (`%USERPROFILE%\.jsonquery` on Windows), and a window to change part of it: the ⚙ at the
right end of the status bar opens "jsonquery — Settings", with the nine limits on the size of files
(each with its default), Reset for one of them, Restore defaults for all, and at the foot the file
they are kept in. Beside the limits, the app remembers how it was left: the theme, whether
autocomplete (💡) is on, the size of the window and whether it was maximized, and the size of the
panes. What the file may hold, and why only what differs from the defaults is written, is in the
app's `docs/settings.md`.

These cases check what a person can see and what the file says: the window and its rows, a limit
typed (a size such as `512 MB`, or what is no size), what is kept for the next start, what the
limit on keeping a file on disk does to a file that is opened, and a file that has something wrong
in it. Words are read by OCR; the file is read as it is (`Settings Value`, `Settings Value Should
Be`), because it is what the app promises and OCR can not be trusted with a long path in small type.

## How the cases are isolated

A test that changed the person's own settings, or saw the settings of the one before, would be
worthless. Every `Launch Jsonquery App` therefore gives the app a folder of its own (the app's
`JSONQUERY_HOME` is the folder itself, not the home of the person): empty, as the first start of a new
user, and removed when the app is closed. `Launch Jsonquery App settings=<text>` starts the folder
with that `settings.json`; `keep_home=${TRUE}` (with `Close Jsonquery App keep_home=${TRUE}`) starts
again in the folder of the last launch, which is how "the next start" is tested.
`Quit Jsonquery App` closes the window as a person does and waits for the app to end, since what is
written as the app ends is part of what is promised (TC-SET-021).

## Cases (`suites/settings/`)

| ID | Title | Priority |
|---|---|---|
| TC-SET-001 | The Gear Opens The Settings Window | P1 |
| TC-SET-002 | Every Limit Is There With Its Default | P1 |
| TC-SET-003 | Nothing Is Written Until Something Is Changed | P1 |
| TC-SET-004 | A Limit Typed And Confirmed Is Kept In The File | P1 |
| TC-SET-005 | What Is Not A Size Is Said So And Not Kept | P1 |
| TC-SET-006 | Reset Puts One Limit Back | P1 |
| TC-SET-007 | Restore Defaults Puts Every Limit Back | P1 |
| TC-SET-008 | A Limit Is Kept For The Next Start | P1 |
| TC-SET-009 | A Limit That Was Typed But Not Confirmed Is Kept When The Window Is Closed | P2 |
| TC-SET-010 | The Limit On Keeping A File On Disk Decides How A File Opens | P1 |
| TC-SET-011 | A Settings File With Something Wrong In It Does Not Stop The App | P1 |
| TC-SET-012 | A File That Is Not JSON Does Not Stop The App Either | P2 |
| TC-SET-020 | The Theme Is Kept For The Next Start | P1 |
| TC-SET-021 | The Theme Is Kept Though The App Ends At Once | P2 |
| TC-SET-022 | Autocomplete On Is Kept For The Next Start | P2 |
| TC-SET-023 | The Size Of The Window Is Kept For The Next Start | P1 |
| TC-SET-024 | A Maximized Window Is Maximized The Next Time | P2 |
| TC-SET-025 | The Size Of The Panes Is Kept | P2 |
| TC-SET-026 | The Panes Are As They Were Left | P2 |

(TC-SET-013 to 019 are left free for more cases about the file and the limits.)

## Mutation checks

Each case was run against builds of the app with one thing broken (a one-place source change); a
case that cannot fail checks nothing. All 16 mutants below were killed, each at the intended
assertion (the failure message is the difference the mutant makes: a value missing from the file,
"Parsed in" where "Indexed in" was due, no complaint under the box, the window still 1000 wide).

| Mutant | What is broken | Killed by |
|---|---|---|
| M1 | the theme is never written | TC-SET-020, 021 |
| M2 | the limit on keeping a file on disk is ignored when a file is opened | TC-SET-010 |
| M3 | a value that is no size is not complained about | TC-SET-005 |
| M4 | the settings are written as soon as the app starts, changed or not | TC-SET-003, 005, 012 |
| M5 | the size of the window is never written | TC-SET-023, 024 |
| M6 | the panes start in the middle whatever was kept | TC-SET-026 (025 reads only the file) |
| M7 | a window kept maximized is not asked to maximize | TC-SET-024 |
| M8 | a file that is not JSON is written over at the start | TC-SET-012 |
| M9 | the usual size of the window (1200 × 800) is written as well | TC-SET-003, 005, 012 and, since it waits, 023 |
| M11 | Reset does not put the limit back | TC-SET-006 |
| M12 | Restore defaults does not restore | TC-SET-007 |
| M13 | what was typed is lost when the window is closed | TC-SET-009 |
| M14 | autocomplete is never noted | TC-SET-022 |
| M15 | nothing is written as the app ends | TC-SET-021 |
| M16 | the sizes of the panes are never written | TC-SET-025, 026 |
| M17 | the usual sizes of the panes are written as well | TC-SET-025 |

(M10 was never made. The ids are the ones of the mutation script, not a count.) What they found in the
cases, not the app: M9 survived TC-SET-023 at first, because its check that the usual size was not
written ran before a late write could have happened (the three cases that look for a file at all
killed it); the case now waits as TC-SET-003 does, and TC-SET-025 likewise (M17). And M6 survived
TC-SET-025, which reads only what is written, so there was no case for the panes coming back:
TC-SET-026 was added.

## Notes

- TC-SET-003 is the promise that the app does not leave a file in the home of someone who never
  changed a thing: starting, and opening the Settings window, write nothing. TC-SET-004 and 006 show
  the other side — only what differs from the default is in the file, and a limit put back to its
  default leaves the file.
- TC-SET-010 is the one that shows a limit *working*: a file of 3 KB is parsed in full (the status
  bar says "Parsed in") by the default limit of 256 MB; with the limit at 1 KB, the same file is kept on
  disk and indexed ("Indexed in"). The behaviour for the rest of the limits (downloads, copies, the
  Tools window, the query engines) is checked by the app's own unit tests, where a limit of a few
  bytes can be set and a few bytes exceeded; here a real file of that size would be needed.
- TC-SET-012 reads the warning of the footer by its colour (amber, `255 143 0`) over the line that
  names the file, not by its words: the words are small, coloured and followed by a long path, and
  OCR read them differently on each run. What the warning says is checked in TC-SET-011, where it is
  short. The case also reads the file back: a file that could not be read is not rewritten by looking
  at it.
- TC-SET-020 compares one pixel of the main window before and after (a dark theme against a light
  one), and ends in dark again: the theme that is the default is not written, so the file has no
  `theme` and nothing is left.
- TC-SET-023 and 024 ask the window manager for the size and the maximized state (`Resize Window`,
  `Maximize Window`) and read what the app kept. The app does not keep where the window is, on
  purpose: a window put on a screen that is no longer there can not be found. It keeps the size the
  window had before it was maximized, so that un-maximizing again is not a different window.
- TC-SET-024: fluxbox, the window manager of the suite, ignores a window's request to start
  maximized, so the app asks to be maximized once its window exists, and the case waits for the
  window to become wider (`Window Should Be Wider Than`) rather than for a fixed time.
- TC-SET-025 drags the edge between Source and Results to the left and reads `panes.source_share`
  from the file (less than 0.4). The sizes are only kept for a window that is neither maximized nor
  minimized, and only once they have held still for a moment.
- TC-SET-026 is the other half: after the same drag and a new start, the title "Results" is read in
  the strip of the headers (`@{LEFT_OF_RESULTS}`, x 360 to 520) where, with the edge in the middle,
  only the Source header is; before the drag the case checks it is not there. Without it a mutant
  that keeps the share but starts every time with the panes in the middle would pass TC-SET-025.
