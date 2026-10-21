# The website button — test requirements

Source: `website_button` and the constants `WEBSITE_URL`, `WEBSITE_NAME` and `WEBSITE_ICON` in
`crates/app/src/app.rs`, with `App::status_bar` (where the buttons are put) and `info_window_contents` /
`INFO_SIZE` (the About window's row for the site). What a person sees of it is in the app's
README ("On the web") and `PRIVACY.md` ("Links").

The app tells whoever uses it that there is a website, https://jsonquery.dev, which runs the same query engine in
a browser with nothing to install:

- the **🌐** button at the right end of the status bar, **between the ⓘ and the ⚙** (from the right: ⓘ 🌐 ⚙, and
  with the Tools docked 🗗 after them), on every tab and in every window state;
- **one click** on it hands the address to the person's browser (`https://jsonquery.dev`; the app never
  contacts the site by itself, and nothing is opened by looking at the button);
- **held still under the pointer** it shows two short lines, not a paragraph: `jsonquery.dev — queries, tools and
  lessons in your browser` and `Click to open https://jsonquery.dev`;
- the **About** window names the site in a **Website:** row (a link, between Source and Issues) and says nothing
  more of it: what is there is for the hover to say. (It had a paragraph on it for a day, until it was taken out
  on request, 2026-10-11 night.) It opens 380 × 300, which is as tall as its text needs, and cannot be made
  smaller than 320 × 300.

## How the cases keep the browser away

A click on a link or on the 🌐 makes the app's browser crate (`webbrowser`) run `$BROWSER`, else `xdg-open`, else the
desktop's own opener (`gio open`, `gvfs-open`, `gnome-open`, `kde-open`, `exo-open`…), else `x-www-browser`. On a
desktop where a browser is already running, any of those hands the address to it as **a new tab**: a test run that
clicked the 🌐 would open jsonquery.dev in the browser of whoever ran it, once for every click. So the test library
(`resources/AppLibrary.py`, `BROWSER_OPENERS`) starts **every** app with

- `BROWSER` set to a stand-in script, which writes the address it was given (its last argument) and the name it
  was run under into a log, and opens nothing; and
- a `PATH` that holds nothing but stand-ins for every program the crate could try, all links to that script.

Two facts make this easy to get wrong, and the first was met on the day the 🌐 was added: the crate **skips a
`$BROWSER` that is not executable without a word** and goes on to `xdg-open` (a stand-in script that was not
executable let the first hand-made click through to a real browser, as a new tab), and, before the desktop's own
openers, it asks `xdg-settings` for the default browser's `.desktop` file, whose `Exec` line can be an absolute
path (so a stand-in for `xdg-open` alone is not enough, and the `PATH` holds nothing else). So the library checks that
the stand-ins are executable and runs one before the first case; a suite that cannot do that stops at its
set-up instead of going on. `Opened Addresses Should Be` (with no address, `Nothing
Should Have Been Opened`) reads the log: it waits for exactly those addresses, then a little longer for a second
one that should not come (a click that opens the site twice). The crate normalises the address it hands over, so
the log has `https://jsonquery.dev/`, with a slash.

The stand-in swallows what it is given, so a click that lands on a link or on the 🌐 **by mistake** would pass
unseen: the ⚙ was at x = 1152 until the 🌐 took the place, and every case that clicked there went on to open the
site instead of Settings. So **every** case is checked at its end: `Close Jsonquery App` fails the case when the app
handed the browser an address that no `Opened Addresses Should Be` (or `Nothing Should Have Been Opened`) of the case
asked about. No case other than the ones about the site asks, so a pixel that moves onto a link fails the case that
clicked it, in the teardown, with the address.

## Cases

`suites/website/website.robot` (TC-WEB), and the cases of two other areas that are about the site:
TC-SAT-024 to 026 in `suites/satellites/` ([14_tutorial_and_about_windows.md](14_tutorial_and_about_windows.md))
and TC-DOCK-041 in `suites/tools/tools_docked.robot` ([22_tools_docked.md](22_tools_docked.md)).

| ID | Title | Priority |
|---|---|---|
| TC-WEB-001 | The Status Bar Has A Globe Between The Info And The Settings Buttons | P1 |
| TC-WEB-002 | Hovering The Globe Says What The Site Is And Where A Click Goes | P1 |
| TC-WEB-003 | Clicking The Globe Opens The Website In The Browser | P1 |
| TC-WEB-004 | Every Click On The Globe Opens The Site Once | P2 |
| TC-WEB-005 | The Info And The Settings Buttons Work Beside The Globe And Open Nothing In The Browser | P1 |

The buttons are read by their pixels (an icon is "something bright there": a glyph cannot be read by OCR), the
tooltip by OCR in the strip above the status bar, and every click is checked by what the stand-in browser was
asked to open. TC-WEB-001 is tagged `undocked-only`: it says that nothing is left of the ⚙ (at 1095, where the 🗗 is
docked: TC-DOCK-006 reads the docked bar, with the 🗗), and that the button of the workspace pane is at the other end of
the bar, the first thing at the left. The other four run docked as well (`./run_docked.sh`).

What moved because of the 🌐, in the cases that were already there: the ⚙ is at x = 1123 now (it was 1152, where
the 🌐 is), the 🗗 at 1095 (it was 1124); the status line that OCR reads stops at 1100 undocked, 1070 docked and
770 in a Tools-sized window, short of the leftmost icon (an icon in the region makes OCR misread the text beside
it: `resources/keywords.resource`, `docked_main.py`, `docked_tools.py`), and since the pane's button is at the left end
of the bar they begin at x = 36, after it; the About window's text is read over its
whole 380 × 300 (`@{ABOUT_TEXT}`; the About window was 380 × 366 for a few hours, with a paragraph on the site).

## What these cases do not reach

The cases are the whole path through the real window: a real click on the real button, a real tooltip, the
address as a program would receive it. Not here, because they are not about the window or cannot be seen from
outside: that the hover's text is exactly two lines of those words and no taller, that the 🌐 changes neither the
ⓘ nor the height of the bar, and that the About window fits its text at its smallest size (all in
`crates/app/src/app/layout_tests.rs`, "the website", on a harness that records `OpenUrl`); which glyph is drawn
(the cases only know that a button is there, TC-WEB-003 knows it is the one that opens the site); and what a real
browser does with the address, on this or any other system (the stand-in is the end of the road on purpose).

## Mutation checks

Twenty-three one-place faults were built into the app, one at a time, and the cases that should notice were run
against each (`TC-WEB`, `TC-SAT-024` to `026` and `TC-DOCK-041`, through the real window). Each of M01 to M21 was
killed by the case meant for it; N01 and N02 are kept to show what these cases do not see.

| | The fault | Failed |
|---|---|---|
| M01 | no 🌐 in the status bar | TC-WEB-001, 003, TC-DOCK-006, 041 |
| M02 | the 🌐 left of the ⚙ instead of between | TC-WEB-003, 005 |
| M03 | the 🌐 in the corner, the ⓘ beside it | TC-WEB-003, 005 |
| M04 | the address is `http`, not `https` | TC-WEB-003, TC-SAT-025, TC-DOCK-041 |
| M05 | the address is the repository's | TC-WEB-003, TC-SAT-025, TC-DOCK-041 |
| M06 | a click on the 🌐 opens nothing | TC-WEB-003, 004, TC-DOCK-041 |
| M07 | the 🌐 says nothing when hovered | TC-WEB-002 |
| M08 | the hover does not give the address | TC-WEB-002 |
| M09 | the hover does not say what the site is | TC-WEB-002 |
| M10 | the hover is long again (the whole description in it) | TC-WEB-002 |
| M11 | the 🌐 opens the site on hover | TC-WEB-002, 003 |
| M12 | a click opens the site twice | TC-WEB-003, 004, TC-DOCK-041 |
| M13 | no 🌐 while the Tools are docked | TC-DOCK-006, 007, 041 |
| M14 | a 🌐 only while the Tools are docked | TC-WEB-001, TC-DOCK-008 |
| M15 | no Website row in the About window | TC-SAT-024, 025 |
| M16 | the About window's link goes to the repository | TC-SAT-025 |
| M17 | *(retired)* no paragraph about the site in About | the paragraph was taken out, see below |
| M18 | About has its old sizes, the last link cut off | TC-SAT-026 (at the sizes of that day, 380 × 366) |
| M19 | *(retired)* the description leaves JMESPath out | with the paragraph |
| M20 | the About link reads differently | TC-SAT-024, 025 |
| M21 | the name is another domain | TC-SAT-024 (TC-WEB-002 looks for `jsonquery.dev` in the tip, and the address line has it too) |
| N01 | another globe glyph | survives: the cases know a button is there, and that it opens the site, not which glyph |
| N02 | About can be made too short | survives: `xdotool windowsize` does not ask the window manager for its minimum |

The paragraph under the About window's rows was taken out on request (2026-10-11, night), and TC-SAT-024 turned
round: it now fails if the words of the paragraph ("nothing to install", "query engine") are read anywhere in the
window. Run against the build from before, which still has the paragraph, it fails with the paragraph in the message;
on the new build TC-SAT-024 to 026 pass (380 × 300 when it opens, 320 × 300 the least). The other rows were not run
again.

M10 (the hover grown back to a paragraph) is caught by the strip of the window above the tip that TC-WEB-002 reads
(`@{ABOVE_THE_TIP}`), which stays empty when the tip is two lines. The faults were put in `crates/app/src/app.rs`
by a script that builds each (debug), runs the cases on a private display and puts the file back, checking its hash.

## What the runs found

- **The ⚙ was where the 🌐 is now.** Every case that clicked at x = 1152 for the ⚙ went on to open the site and not
  Settings, and with the stand-in browser swallowing the address nothing showed it. That is why `Close Jsonquery App`
  fails a case whose app handed the browser an address that the case did not ask about: a pixel that moves onto a
  link is caught in the teardown, with the address in the message (proved with a scratch case that clicks the 🌐 and
  says nothing about it).
- **A non-executable `$BROWSER` is skipped by the crate without a word.** The first stand-in script was not
  executable, and one hand-made click on the 🌐 opened a tab in the browser of the person running it. The library
  makes it executable, checks it and runs it once before the first case, and starts every app with a `PATH` of
  stand-ins only (the crate asks `xdg-settings`, then the desktop's own openers).
- **`xdotool windowsize` does not ask the window manager for its minimum,** so a case cannot ask for a window smaller
  than the app allows; TC-SAT-026 reads the sizes the About window has and the text at both of them instead (the
  minimum itself is checked by the app's own window tests: N02).
- **The 🌐 moved the other icons 29 pixels to the left.** Three icons at the right end of the status bar (⚙ 🌐 ⓘ) now
  reach into the strip that OCR reads, so the regions of the status bar end at 1100 (1070 docked, 770 in a Tools-sized window); an
  icon in a region makes OCR misread the text beside it (the TC-QRY-012 trap, which two icons made worse).
- **The last full runs** (2026-10-11 evening, 689 cases, the debug build): `run_parallel.sh -j 5`, 688 of 689;
  `run_docked.sh -j 5`, the tools pass 151 of 151 and the main-view pass 467 of 468. The one failure, the same case
  in both profiles, was TC-OPEN-036 (a file of 272 MB; `to_entries` says it needs the whole list): OCR read `0 result(s)`
  as `0O result{s)` in the narrower region, and `resulkt{s)` from x = 0 or `resulk(s)` in the part with the count
  alone, depending on the digits of the time, because that line goes on with a long error in orange that runs under
  the icons. The case now reads the part with the count and accepts a `t` or a `k` (3 of 3 passes undocked and 2 of 2
  docked; the whole file of heavy-file cases had passed but this one). The app did what it should.
- **The app had no defect to fix.** One thing seen in the failing picture: that long error message is laid out across
  the whole width and the icons are drawn over its end, hiding a few words of it. It was so before the 🌐 (the ⚙ and the
  ⓘ did it); the 🌐 makes the covered stretch 29 pixels longer. Not changed.
