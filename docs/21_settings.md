# Settings — test requirements

The app keeps one small file of settings, `settings.json` in the folder `.jsonquery` of the
person's home (`%USERPROFILE%\.jsonquery` on Windows), and a window to change part of it: the ⚙ at the
right end of the status bar opens "jsonquery — Settings", a small window (430 × 190) with the one limit on
the size of files that is shown, from what size a file is kept on disk, an **Advanced** header inside the
window which, clicked, shows the other eight (the window grows to 372 high for them and goes back when it is
shut), Reset for a limit, Restore defaults for all nine, and at the foot the file they are kept in. The
window explains nothing in writing: what a limit is for, and what it is by default, is a tooltip over its
name. Beside the limits, the app remembers how it was left: the theme, whether
autocomplete (💡) is on, the size of the window and whether it was maximized, and the size of the
panes. What the file may hold, and why only what differs from the defaults is written, is in the
app's `docs/settings.md`.

These cases check what a person can see and what the file says: the window and its rows, Advanced and
the height of the window, a tooltip, a limit typed (a size such as `512 MB`, or what is no size), what is
kept for the next start, what the limit on keeping a file on disk does to a file that is opened, and a
file that has something wrong in it. Words are read by OCR; the file is read as it is (`Settings Value`, `Settings Value Should
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
| TC-SET-013 | Advanced Is Closed At First And The Window Follows It | P1 |
| TC-SET-014 | Hovering The Name Of A Limit Says What It Is For | P1 |
| TC-SET-015 | Advanced Says How Many Of Its Limits Are Not The Default | P1 |
| TC-SET-016 | A Window Opened With Many Complaints Is Tall Enough For Them | P2 |
| TC-SET-020 | The Theme Is Kept For The Next Start | P1 |
| TC-SET-021 | The Theme Is Kept Though The App Ends At Once | P2 |
| TC-SET-022 | Autocomplete On Is Kept For The Next Start | P2 |
| TC-SET-023 | The Size Of The Window Is Kept For The Next Start | P1 |
| TC-SET-024 | A Maximized Window Is Maximized The Next Time | P2 |
| TC-SET-025 | The Size Of The Panes Is Kept | P2 |
| TC-SET-026 | The Panes Are As They Were Left | P2 |

(TC-SET-017 to 019 are left free for more cases about the file and the limits.)

## Mutation checks

**This first table is of before the window was made small** (one limit, Advanced, tooltips): the cases
were recalibrated afterwards, and the second table, below it, is what was run against the new window.
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

### The small window (2026-10-07)

Nine more mutants, each applied alone or with others whose cases are not the same, and each run against
only the cases meant for it. All nine were killed, each at the intended assertion.

| Mutant | What is broken | Killed by (and how) |
|---|---|---|
| M18 | Advanced never opens | TC-SET-013, 002: the window stays 190 high |
| M19 | the window never grows for what does not fit | TC-SET-013: the window stays 190 high |
| M20 | the window does not go back when Advanced is shut | TC-SET-013: "The window is 372 high" |
| M21 | Advanced stays open when the window is opened again | TC-SET-013: it opens 372 high |
| M22 | there are no tooltips | TC-SET-014: no "indexed once" under the row |
| M23 | Advanced never says how many of its limits are changed | TC-SET-011, 015: "Advanced" for "1 changed" and "2 changed" |
| M24 | Advanced counts the limit that is shown as well | TC-SET-015: "Advanced (3 changed)" for 2 |
| M25 | the window does not grow for the complaints it opens with | TC-SET-016: the window stays 190 high |
| M28 | Restore defaults puts back only the limit that is shown | TC-SET-007 (the Copy limit stays 8 MB), 015 |

M25 survived TC-SET-011 at first: its file has two things wrong, and two complaints do not cover the
Advanced header in a window 190 high, so the case could not tell a window that grew from one that did not.
TC-SET-016 has four, and was run against the clean build (passes) and M25 (fails: "The window is 190
high"). The unit tests of the app (`layout_tests.rs`) check the same behaviour without a display: the
`InnerSize` the window asks for, and that it is not asked for twice, nor on a window that is tall enough.

(M10 was never made. The ids are the ones of the mutation scripts, not a count.) What they found in the
cases, not the app: M9 survived TC-SET-023 at first, because its check that the usual size was not
written ran before a late write could have happened (the three cases that look for a file at all
killed it); the case now waits as TC-SET-003 does, and TC-SET-025 likewise (M17). And M6 survived
TC-SET-025, which reads only what is written, so there was no case for the panes coming back:
TC-SET-026 was added.

## Notes

- **The window is small, so a few things are done on purpose.** The window manager of the suite (fluxbox)
  opens a window where the pointer is, which for the ⚙ is the corner of the screen, and does not move it
  when it grows; a desktop keeps it where there is room. `Open Settings` therefore moves the window clear
  of the corner (`Move Window`), or the rows under Advanced would be off the display and OCR would read
  nothing there. A box under the pointer has a bright outline, which at this size OCR takes for part of
  "512 MB"; `Type In Box` takes the pointer off it, and the box is 90 px wide, not 78, to leave room.
- TC-SET-013 reads the height of the window (`Get Window Size`), not a picture of it: at most 230 shut,
  more than 300 open, and shut again after a click or after the window is closed and opened. TC-SET-011 and
  012 first `Wait For Window To Settle`: a window opened with complaints in it grows once, a moment after it
  opens, to hold them, and the foot (where the complaints are) is read from the bottom of the window
  (`Foot Region`), wherever that is.
- TC-SET-014 is the only case that reads a tooltip: the pointer is put on the name of the limit and left
  still for a second and a half (egui shows a tooltip only for a pointer that is still), and the words
  "indexed once" and "Default: 256 MB" are read in the region under the row. Away from it, over nothing,
  they are gone. It then changes the limit and reads what Reset's tooltip says it puts back.
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
