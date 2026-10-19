# Tutorial and About windows — test requirements

Source: `crates/app/src/tutorial.rs` (the tutorial's content and window),
`InfoWindow` in `crates/app/src/app.rs` (About), and `crates/app/src/app/satellites.rs`
(how both, and the Tools window, are shown).

The **📖** button in the toolbar opens the tutorial in a window of its own (titled
"JsonQuery — Tutorial", 1040×720): a tab for each query language (jq, JSON
Pointer, JSONPath, JMESPath), a lesson list with a filter box on the left, the
lesson on the right with its sample data and its examples. Each example has
**▶ Try it** (loads the sample data and the query into the main window and runs
it), **Load query**, **Load data** and **Copy query**, and shows its live result.
The **ⓘ** button at the right end of the status bar opens About ("JsonQuery —
About", 380×330): the name and version, the license, links (the source, the
**website** — a "Website:" row with a link to jsonquery.dev between Source and Issues —
the issues, the privacy policy), the known limitations and a last link to the README, and
under them a header **Known issues (N)**. A click on it opens the list of the jq programs that run
differently here (N is the number of issues in `crates/query/src/known_issues/list.rs`; the
page `docs/known-issues.md` is made from the list, a line in bold for each): the window is made
640 wide, as tall as the list needs but not taller than 9/10 of the screen (the rest scrolls),
each line shows an example while the pointer rests on it, and a link at the foot opens the
page with the smaller issues too. A second click closes the list and the window goes back to
the size it had. The 🌐 button beside the ⓘ is in [23_website.md](23_website.md).

Both are *deferred* viewports (`satellites.rs`): eframe redraws each by itself and
the app answers through a lock, so they keep working when the main window is not
being redrawn — which on GNOME/Wayland is the case once something covers the main
window completely. That cannot be seen under X; the cases below drive the flows
that bug broke, on real windows (open, use, hand an example over, maximize, close).

## Cases (`suites/satellites/`)

| ID | Title | Priority |
|---|---|---|
| TC-SAT-001 | The tutorial button opens the tutorial window | P1 |
| TC-SAT-002 | The tutorial opens on the first lesson | P1 |
| TC-SAT-003 | Picking another lesson shows it | P1 |
| TC-SAT-004 | Another language has lessons of its own | P1 |
| TC-SAT-005 | Typing in the filter narrows the lessons | P1 |
| TC-SAT-006 | Try it hands the example to the main window | P1 |
| TC-SAT-007 | Load query puts only the query in the main window | P1 |
| TC-SAT-008 | Load data puts only the sample in the main window | P1 |
| TC-SAT-009 | Copy query copies the query | P2 |
| TC-SAT-010 | Closing the tutorial and pressing the button again reopens it | P1 |
| TC-SAT-011 | A second press does not open a second tutorial | P2 |
| TC-SAT-012 | A maximized tutorial still responds and closes | P1 |
| TC-SAT-013 | The main window works with the tutorial open | P2 |
| TC-SAT-014 | The tutorial follows the main window's theme | P2 |
| TC-SAT-020 | The info button opens the About window | P1 |
| TC-SAT-021 | About says the version of the build | P1 |
| TC-SAT-022 | Closing About and pressing the button again reopens it | P1 |
| TC-SAT-023 | The main window works with About open | P2 |
| TC-SAT-024 | About has a Website row and nothing more about the site | P1 |
| TC-SAT-025 | The website in About is a link that opens the site | P1 |
| TC-SAT-026 | About shows all it says down to the last link | P2 |
| TC-SAT-040 | About has a Known issues header, shut, with the number of issues | P1 |
| TC-SAT-041 | Opening the known issues shows the list and makes the window bigger | P1 |
| TC-SAT-042 | Closing the list shuts it and the window goes back to its size | P1 |
| TC-SAT-043 | The list can be opened again after it was shut | P2 |
| TC-SAT-044 | A window opened afresh has the list shut | P1 |
| TC-SAT-045 | A window wider than the list needs keeps its width and gets its size back | P2 |
| TC-SAT-046 | A line of the list shows an example while the pointer rests on it | P2 |
| TC-SAT-047 | The link under the list opens the page with all the issues | P1 |
| TC-SAT-048 | A window too small for the list scrolls to its end | P2 |
| TC-SAT-030 | All the windows can be open together | P1 |
| TC-SAT-031 | Closing one window leaves the others | P2 |

TC-SAT-021 reads the version from the workspace `Cargo.toml` and compares it with
what About says, so a release that forgets one of them fails here.

TC-SAT-024 to 026 are about the website: the row is read over the whole window (OCR,
`@{ABOUT_TEXT}` and the strip of it), and the text of a paragraph is looked for in the
whole window and must not be there; the order of the rows by where
OCR finds their labels, and the link by clicking it: the address goes to a stand-in for
the browser, which writes it down and opens nothing ([23_website.md](23_website.md), "How
the cases keep the browser away"; every app the suite starts has it). TC-SAT-026 reads
the window's size when it opens (380×330) and after it is set to the least the app lets
it be (320×330), and both times reads the last link, "More in the README", and the header
of the known issues under it. It does not
try for a smaller window: `xdotool windowsize` asks no window manager, so a window can
be made 300×300 that a hand on its edge could not (the first version of the case tried,
and found it); that the app asks for that minimum is in its layout tests.

TC-SAT-040 to 048 are about the list. The number in the header is the number of bold lines
of the page in the app's repository (so the case follows the list, and the test in the app that
keeps the page current keeps the list and the header together); the titles of the groups are
the page's headings; a line of the list is looked for by OCR and hovered where it is found; the
foot of the list (the link, "N smaller ones, and more examples, in the full list") is only
readable when the window is as tall as the list needs, which is how the cases know it was made so.
What the cases do not see: the window's *height cap*. The list at 640 wide is 731 high and the
test display has 900, so the 9/10 of the screen that caps the height is never reached
(the cap is a mutant that survives, below).

## Mutation checks

One thing broken at a time in a build of the app (a scratch copy; `crates/app/src/app/issues_view.rs`
and `app.rs`), and the cases that should see it, run on that build. 16 mutants of the list and its window:
12 are killed, 4 are not, and each of those is said why.

| Mutant | What is broken | Killed by |
|---|---|---|
| S1 | the window is not made wider for the list (`OPEN_WIDTH` 380) | TC-SAT-041, 043 |
| S2 | the window does not go back to its size when the list is shut | TC-SAT-042, 045 |
| S3 | the window goes back to 380 by 330, whatever size it had | TC-SAT-045 |
| S4 | the header has no count | TC-SAT-040, 042 |
| S5 | a line shows no example on hover | TC-SAT-046 |
| S6 | the link goes to another branch (`main` for `master`) | TC-SAT-047 |
| S7 | the window is made wider but not taller | TC-SAT-041, 043 |
| S8 | the window opens 300 high | TC-SAT-026, 040 |
| S9 | the tip says nothing of what the app gives | TC-SAT-046 |
| S10 | the first group is left out | TC-SAT-041 |
| S11 | no line about the list | TC-SAT-041, 043, 045 |
| S12 | the window does not scroll (`min_scrolled_height` 2000) | TC-SAT-048 |
| S13 | the header is the same one when the window is opened again | **not killed:** the header then slides shut for a fifth of a second on a window opened with the list shut, and the cases read it after that |
| S14 | a window wider than 640 is made 640 | **not killed, and nothing to kill:** the window is only resized when 640 is wider than it is |
| S15 | the window may be taller than the display (the 9/10 of the screen) | **not killed:** the list is 731 high and the test display 900, so the cap is never reached |
| S16 | the window may be made lower than 330 (`INFO_MIN_SIZE`) | **not killed:** `xdotool windowsize` asks no window manager, so the case sets the size itself |

S15 and S16 need a smaller display and a window manager that is asked; S13 needs a picture taken in the
first fifth of a second. They are worth a unit test in the app (the size rules of `issues_view.rs`), not more
Robot.

## Lessons from writing them

- **The window manager puts About at the corner of the screen the pointer is at** (fluxbox:
  under the ⓘ, at the bottom right), and a window made 640 wide and 731 high from there
  reaches beyond the display: what is outside it cannot be read or clicked. A person drags
  the window up first, and so do the cases that open the list (`Open About Up In The Corner`).
  (The app does not move the window; on a real desktop it is the window manager that keeps it in.)

- **A window the main window covers completely is not drawn — and does not even
  notice a close request.** X11 sends `VisibilityNotify(FullyObscured)`, winit turns
  it into `Occluded(true)`, and eframe 0.36 then runs *no UI pass at all* for that
  viewport (`ViewportInfo::visible()` is false when occluded, and
  `run_ui_and_paint` returns before calling the app: traced with a patched eframe,
  `is_visible=false show_ui=false`). A test that closed the tutorial while the
  main window (which clicking its buttons had raised) lay completely over it saw it
  stay open for ever. It is the toolkit's rule, not the app's, and a user cannot
  close a window they cannot see; so `Close Window` raises the window first (as
  the user's click on its close button would have), and `Switch To Window` /
  `Switch To Main Window` raise the window they make current. They use
  `wmctrl -a`: with a reparenting window manager (fluxbox) `xdotool windowraise`
  only reorders the client inside its frame.
- The tutorial opens over the main window (both at the display's top left), so a
  test that reads the main window's screen area while the tutorial is open reads the
  tutorial: raise the main window first.
- OCR of the query box (`.name`) is unreliable under its tints (it came back as
  `.-hame`): `Query Text Should Be` selects all, copies and compares the clipboard.

## Not reachable

Native Wayland: the redraw-on-its-own behaviour of these windows when the main
window is completely covered (see [13_tools_window.md](13_tools_window.md), "Not
reachable"). `layout_tests.rs` covers it with a harness that runs the app the way
eframe does.
