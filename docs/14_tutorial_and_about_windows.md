# Tutorial and About windows — test requirements

Source: `crates/app/src/tutorial.rs` (the tutorial's content and window),
`InfoWindow` in `crates/app/src/app.rs` (About), and `crates/app/src/app/satellites.rs`
(how both, and the Tools window, are shown).

The **📖** button in the toolbar opens the tutorial in a window of its own (titled
"jsonquery — Tutorial", 1040×720): a tab for each query language (jq, JSON
Pointer, JSONPath, JMESPath), a lesson list with a filter box on the left, the
lesson on the right with its sample data and its examples. Each example has
**▶ Try it** (loads the sample data and the query into the main window and runs
it), **Load query**, **Load data** and **Copy query**, and shows its live result.
The **ⓘ** button at the right end of the status bar opens About ("jsonquery —
About"): the name and version, the license, links, the known limitations.

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
| TC-SAT-030 | All the windows can be open together | P1 |
| TC-SAT-031 | Closing one window leaves the others | P2 |

TC-SAT-021 reads the version from the workspace `Cargo.toml` and compares it with
what About says, so a release that forgets one of them fails here.

## Lessons from writing them

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
