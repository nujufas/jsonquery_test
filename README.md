# jsonquery_test

End-to-end GUI tests for [jsonquery gui](https://github.com/nujufas/jsonquery_gui), a desktop tool for
browsing and querying large JSON files with jq, JSON Pointer, JSONPath and JMESPath.

The suite starts the real application, clicks and types into it the way a person would, and reads the
screen back with OCR, pixel checks and the clipboard. It is written with
[Robot Framework](https://robotframework.org) and runs on a virtual X display of its own, so it never
touches your desktop. Status (October 2026): **640 test cases in 24 suites**.

Beside the GUI suite is [performance/](performance/README.md), which does not use a display: it measures how fast the
app's functions are, and how much memory they take, on files of up to a gigabyte at any revision of the app, and keeps the
results as JSON so that one revision can be compared with another.

## Quick start

Install the [requirements](#requirements), then clone the app and this repository side by side and run the
smoke suite:

```sh
git clone https://github.com/nujufas/jsonquery_gui.git
git clone https://github.com/nujufas/jsonquery_test.git
cd jsonquery_test
./run.sh suites/launch_and_window/     # four cases: is everything set up?
```

The first run builds the app (a debug build: it takes a while and needs several GB of disk space), creates a
Python virtual environment in `.venv/` and installs the dependencies; later runs reuse both. Afterwards
`results/report.html` has the summary and `results/log.html` the detail.

`./run.sh` on its own runs every suite, which takes over an hour on one display; see
[Running faster in parallel](#running-faster-in-parallel).

## Requirements

- **Linux** with X11 libraries. The suite brings its own X server, so it works on a Wayland desktop too. It is
  developed on Ubuntu with GNOME on Wayland and runs in CI on Ubuntu 24.04. Windows and macOS are not
  supported.
- **The app's sources**, to build it: [jsonquery_gui](https://github.com/nujufas/jsonquery_gui) and a Rust
  toolchain ([rustup](https://rustup.rs)). Its README has the details under
  [Build from source](https://github.com/nujufas/jsonquery_gui#build-from-source).
- **Python 3.12** with `venv`. The pinned libraries are confirmed against 3.12, and newer Pythons may not have
  wheels for them. `run.sh` uses pyenv's 3.12.3 when it finds it and `python3` otherwise.
- **System packages** (Debian/Ubuntu names):

```sh
sudo apt install xvfb fluxbox xdotool wmctrl xclip tesseract-ocr gnome-screenshot dbus-daemon python3-venv python3-tk python3-dev
```

`run.sh` checks for the programs and prints the install command when one is missing (`dbus-daemon` is for the
stand-in that answers the app's file dialogs, see [How it works](#how-it-works)). On a bare machine or in a
container the app itself also needs its runtime libraries: `libxkbcommon-x11-0 libxcb-xkb1 libgl1-mesa-dri
libegl1 mesa-vulkan-drivers libvulkan1` (the [CI job](#continuous-integration) installs them as well).

## Running tests

```sh
./run.sh                                                      # every suite (over an hour on one display)
./run_parallel.sh                                             # every suite, in 6 lanes at once (about 15 minutes)
./run.sh suites/query_engines/                                # one suite (the target path comes FIRST)
./run.sh suites/tools/tools_diff.robot                        # one file
./run.sh suites/tools/tools_diff.robot --test 'TC-DIF-007*'   # one case
./run.sh suites --include p1                                  # only the cases tagged p1
```

Everything after the target path goes to Robot, so its other options work too (`--exclude`, `--loglevel`, ...).
Every case is tagged with its priority, `p1` (core correctness, must pass before a release), `p2` or `p3`, and
every suite file with the name of its area (`search`, `popout`, `tools`, `diff`, ...).

### Choosing the build to test

`run.sh` uses the app checkout in `$JQ_APP_DIR` if you set it, and otherwise the one beside this repository:
`../jsonquery_gui` (where `git clone` puts it) or `../jsonquery`. It builds a debug binary there with
`cargo build -p jsonquery_gui` and tests `target/debug/jsonquery_gui`.

```sh
JQ_APP_DIR=~/src/jsonquery_gui ./run.sh                              # a checkout somewhere else
JQ_TEST_NO_BUILD=1 JQ_TEST_BINARY=/path/to/jsonquery_gui ./run.sh    # a binary you built yourself, e.g. a release build
```

A checkout of the app is still needed with `JQ_TEST_BINARY`: one case reads the version it expects from its
`Cargo.toml`. Use a plain executable, not an AppImage, which registers itself with your desktop when it starts.

### Running faster in parallel

A full run launches the app for every case. `run_parallel.sh` builds the app once, makes one copy of the binary
that a rebuild will not replace, splits the suite files over the lanes by their number of cases, runs each lane
on a display and a results directory of its own, and merges the lanes' results into one report:

```sh
./run_parallel.sh                  # 6 lanes, results in results/parallel/ (report.html, log.html, lane<N>/)
./run_parallel.sh -j 8             # 8 lanes
./run_parallel.sh -j 4 --include p1
```

Six lanes ran the 578 cases in about 15 minutes on a 20-thread machine with 64 GB (an hour of lane time). A lane
needs 1-2 GB of memory with a debug build of the app. Six lanes suit a 16-thread machine with 32 GB; with
more than the machine can feed, the cases that wait for a file or an OCR read get slower and, in the end, flaky.
By hand, a lane is `run.sh` with a display, a results directory and a binary of its own:

```sh
(cd ../jsonquery_gui && cargo build -p jsonquery_gui)                 # build once
cp ../jsonquery_gui/target/debug/jsonquery_gui /tmp/jsonquery_gui-lane1
JQ_TEST_DISPLAY=:98 JQ_TEST_RESULTS=/tmp/results-lane1 \
  JQ_TEST_NO_BUILD=1 JQ_TEST_BINARY=/tmp/jsonquery_gui-lane1 ./run.sh suites/tools
# lane 2: another display (:97), its own results, its own copy of the binary, other suites
```

Never start a second run on a display an earlier run is still using, and never kill an Xvfb under a run.

## Results

Robot writes to `results/` (or `$JQ_TEST_RESULTS`):

- `report.html`: the summary, by suite and by tag;
- `log.html`: every step of every case, with a screenshot of the app window taken at the end of each case;
- `output.xml`: the same, machine-readable;
- `screenshots/<case>/`: the images behind the log.

## Configuration

All optional; unset, nothing changes.

| Variable | Default | Meaning |
|---|---|---|
| `JQ_APP_DIR` | `../jsonquery_gui`, else `../jsonquery` | Checkout of the app: built by `run.sh`, and its `Cargo.toml` is read by one case. |
| `JQ_TEST_BINARY` | `$JQ_APP_DIR/target/debug/jsonquery_gui` | The binary under test. |
| `JQ_TEST_NO_BUILD` | unset | Set it (to anything) to skip `cargo build`. |
| `JQ_TEST_DISPLAY` | `:99` | The X display to start (or to reuse, if an Xvfb is already running there). |
| `JQ_TEST_RESULTS` | `results/` | Where Robot writes its output. |
| `JQ_TEST_APP_LOG` | unset | File that receives the app's stderr (the tracing of a debug build). |
| `JQ_PARALLEL_DISPLAY_BASE` | `120` | `run_parallel.sh` only: the first display; lane *n* uses base + *n* - 1. |

## Troubleshooting

- **"Missing required system packages"**: run the `apt install` line it prints.
- **"The app is not beside this repository"**: clone [jsonquery_gui](https://github.com/nujufas/jsonquery_gui)
  next to this repository, or set `JQ_APP_DIR`.
- **Installing the Python requirements fails**: they are only confirmed on Python 3.12. Create the environment
  yourself, for example `python3.12 -m venv .venv && .venv/bin/pip install -r requirements.txt`; `run.sh` uses
  `.venv/` as soon as it holds `bin/robot`.
- **`XauthError` when Robot starts**: python-xlib (under pyautogui) wants an Xauthority file even for Xvfb.
  `run.sh` creates an empty one if it is missing; if you run Robot yourself, `touch ~/.Xauthority`.
- **The display is taken**: `run.sh` reuses a live Xvfb on the display and clears a stale socket; to run beside
  something else, pick another display with `JQ_TEST_DISPLAY`.
- **Cases fail with "Disk quota exceeded" or "No space left on device"**: the temporary files (OCR images, the files
  the cases save, the app's own) go to `/tmp`, which is often a small tmpfs, and a quota there is shared with
  everything else you run. Point `TMPDIR` at a disk, for example `TMPDIR=$HOME/tmp ./run.sh ...`;
  `run_parallel.sh` does it for every lane itself.
- **Robot stops at once with "Can't connect to display" while importing `AppLibrary.py`, or every case fails with
  "No keyword with name 'Start Test Display' found"**: the X server did not come up. When `/tmp` has no room
  Xvfb dies after printing `Cannot close "/tmp/server-<n>.xkm" properly (not enough space?)` (it compiles its
  keyboard map there, and `TMPDIR` does not move that). Free room in `/tmp`, or run the suite in a mount namespace
  with a folder on disk bound over `/tmp`; nothing in the suite needs the real one.
- **A file-dialog case fails with "The app opened 0 file dialog(s)"**: the app did not reach the stand-in portal.
  Check that `dbus-daemon` is installed and that the venv has `jeepney` (`run.sh` installs it when it is missing),
  and read the dialog log that a failed dialog case prints.
- **A case fails once and passes when run again**: the app works asynchronously and the suite reads pixels and
  OCR, so a few cases are timing-sensitive. Run that case alone with `--test` before suspecting the app.
- **Everything is off by a few pixels**: the click points are calibrated for the app's default 1200x800 window in
  the Dark theme; see [docs/writing_tests.md](docs/writing_tests.md) for recalibrating after a layout change.

## How it works

- **A display of its own.** `run.sh` starts [Xvfb](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml)
  (1280x900, display `:99` unless you choose another) and the [fluxbox](http://fluxbox.org) window manager,
  without which keyboard focus does not work. Screen capture of a real GNOME/Wayland desktop is blocked, and
  this way the tests never touch your session.
- **The real binary.** Each case launches a fresh app, with `WAYLAND_DISPLAY` unset so that it runs through X11
  on that display, and closes it afterwards.
- **Like a person.** Mouse clicks are placed relative to the app window (found with `xdotool`); typing and key
  presses go through [pyautogui](https://pyautogui.readthedocs.io). What is on screen is read with
  [Tesseract](https://github.com/tesseract-ocr/tesseract) OCR on cropped regions, with pixel checks and, when
  the text must be exact, through the app's Copy buttons and the clipboard. The app is drawn with egui, which
  has no accessibility tree to query; [docs/00_test_strategy.md](docs/00_test_strategy.md) has the
  investigation behind these choices.
- **The file dialogs are answered by a stand-in.** The app asks the desktop's file-chooser portal over D-Bus, which
  does not work with a window that is not GTK's and has nobody to answer under Xvfb. So every app the suite
  launches is pointed at a private `dbus-daemon` with a small portal of the suite's own on it
  (`resources/fake_portal.py`, written with [jeepney](https://pypi.org/project/jeepney/)). A case says which file
  the person chooses, or that they close the dialog, and reads back what the app asked for: the suggested file
  name, the file types, one file or several. The file the app writes is then read from disk. This also keeps the
  app away from the session bus of the desktop the tests are run from.
- **What it changes outside this directory.** It adds one rule to `~/.fluxbox/apps` (the app's window gets no
  title bar, which the click coordinates rely on), creates an empty `~/.Xauthority` if there is none, and keeps
  a temporary directory per run for the D-Bus configuration and the files the cases save (removed at the end).
  The app itself is given a settings folder of its own for each launch (`JSONQUERY_HOME`, see
  [docs/21_settings.md](docs/21_settings.md)), so the `~/.jsonquery` of whoever runs the suite is neither read nor written.

## Test suites

One directory per area of the app under `suites/`, each specified by a document in `docs/`:

| Suite | Covers | Specification |
|---|---|---|
| `launch_and_window` | default state, theme, placeholder text, no menu bar | [01](docs/01_launch_and_window.md) |
| `opening_sources` | paste, NDJSON, malformed JSON, Clear, the source field (URL, typed path, errors), replacing a loaded document, and the `…` button's file dialog | [02](docs/02_opening_sources.md) |
| `toolbar_and_status` | source label by kind, byte-size units, parse time and load errors in the status bar | [03](docs/03_toolbar_and_status_bar.md) |
| `query_engines` | the engine picker, auto-detect, each engine's own result and error behaviour | [04](docs/04_query_bar_and_engines.md) |
| `query_highlight` | colour-coding of the query box | [04](docs/04_query_bar_and_engines.md) |
| `query_box_layout` | a long query scrolls inside the box, a dragged height sticks | [04](docs/04_query_bar_and_engines.md) |
| `autocomplete` | the query box's suggestion popup (off by default, toggled with 💡), including the stream functions and the `@` format names | the suite file, [17](docs/17_jq_functions.md) |
| `tree_view` | row rendering and colours, expand/collapse, scrolling | [05](docs/05_tree_view.md) |
| `text_view` | Tree/Text toggles, editable paste and Apply, read-only text | [06](docs/06_text_view.md) |
| `context_menus` | row menus of the Source and Results panes, Copy JSON Path, Search... | [07](docs/07_context_menus.md) |
| `search` | the Find dialog, Find All, regex mode, Find in Source | [08](docs/08_search_and_find_in_source.md) |
| `saving` | the Save... buttons and menu items through the file dialog: default names, file types, the file written, errors, Ctrl+S | [09](docs/09_saving.md) |
| `keyboard_shortcuts` | Ctrl+F, Ctrl+Enter, Enter | [10](docs/10_keyboard_shortcuts.md) |
| `popout` | the Query, Source and Results panes in windows of their own | [12](docs/12_popout_panes.md) |
| `tools` | the Tools window: Merge, Format, Diff, Patch, Validate, and their file dialogs (seven files) | [13](docs/13_tools_window.md) |
| `satellites` | the tutorial and About windows | [14](docs/14_tutorial_and_about_windows.md) |
| `pane_headers` | the panes' titles and headers, checked in pixels | [15](docs/15_pane_headers.md) |
| `drag_and_drop` | files dropped on the main window, the Source window and the Tools pages | [16](docs/16_drag_and_drop.md) |
| `jq_functions` | `IN`, `INDEX`, `JOIN`, `tostream`, `fromstream`, `truncate_stream`, `@csv` and `@tsv`, which the app adds to its jq engine, read back exactly | [17](docs/17_jq_functions.md) |
| `output_formats` | a query ending in `@csv` or `@tsv`: the CSV/TSV note, the Text view, Copy to Clipboard and Save... write rows, not JSON | [18](docs/18_output_formats.md) |
| `tutorial_pages` | the eight tutorial pages for those functions: every example run, the buttons, the cheat sheet | [19](docs/19_tutorial_pages.md) |
| `workflows` | whole journeys: a file chosen in the dialog, a lesson, a query, rows or JSON saved to disk | [20](docs/20_workflows.md) |
| `settings` | the ⚙ Settings window (the limit on keeping a file on disk, the other eight under Advanced, the explanations as tooltips) and what the app keeps for the next start: the theme, 💡, the size of the window and of the panes | [21](docs/21_settings.md) |

[11_error_and_edge_cases.md](docs/11_error_and_edge_cases.md) cross-references every error string in the app.

## Performance tests

[performance/](performance/README.md) is a separate suite, with its own tooling (`performance/perf.py`, standard-library
Python, and a harness in Rust that is built against the revision of the app under test). Where the Robot suite asks
whether the app works, this asks how fast and how heavy: opening, the rows of the tree, queries in all four languages,
search, Copy and Save, autocomplete and the Tools window, on datasets from a few kilobytes to a gigabyte. A run is one JSON
file in `performance/runs/` with the machine, the revision and every sample, and `perf.py compare` says what changed
between two. [performance/PLAN.md](performance/PLAN.md) says what is measured and why, and
[performance/FINDINGS.md](performance/FINDINGS.md) what the comparison of the app before and after files of 256 MiB or
more were memory-mapped and indexed found.

```sh
python3 performance/perf.py run --rev before=<commit> --rev after=<commit> --profile standard --passes 3
python3 performance/perf.py compare performance/runs/<before>.json performance/runs/<after>.json
```

## Repository layout

```
run.sh                  the entry point: builds the app, sets up .venv/, starts Xvfb and fluxbox, runs Robot
run_parallel.sh         the same for every suite at once, in lanes, with the results merged
requirements.txt        the Python dependencies
suites/<area>/          the Robot test cases, one directory per area
resources/
  AppLibrary.py         the Robot library: launching the app, windows, clicks, typing, OCR, pixels, clipboard, drops, files
  fake_portal.py        the stand-in for the desktop's file-chooser portal (a private D-Bus), which answers the file dialogs
  keywords.resource     shared layout constants and keywords
  tools.resource        layout constants and keywords of the Tools window
  results.resource      the Results pane, the CSV/TSV note, the file dialogs
  tutorial.resource     the tutorial window's lessons and buttons
  xdnd.py               an XDND source, for dropping files on the app
  fixtures/             sample JSON files
scripts/robot_cases.py  prints the case tables for docs/ from the Robot files
performance/            the performance tests: plan, harness, tooling, and the results kept as JSON (see its README)
docs/                   test strategy, a document per area, the traceability matrix
results/, .venv/        generated, and ignored by git
```

## Documentation

- [docs/writing_tests.md](docs/writing_tests.md): adding or changing cases, and the gotchas collected so far.
- [docs/00_test_strategy.md](docs/00_test_strategy.md): why the suite is built this way, what was ruled out,
  the tooling and the environment findings.
- [docs/99_traceability_matrix.md](docs/99_traceability_matrix.md): every test case ID with its status
  (`Passing`, `Blocked` or `Not implemented`, each with its reason; nothing is blocked now).
- `docs/01_*.md` to `docs/20_*.md`: the requirements of each area, linked from the table above.

## Continuous integration

The app's repository runs this suite from its CI workflow
([ci.yml](https://github.com/nujufas/jsonquery_gui/blob/master/.github/workflows/ci.yml), job *GUI tests
(jsonquery_test)*): on demand from the Actions tab
([Run workflow](https://github.com/nujufas/jsonquery_gui/actions/workflows/ci.yml), optionally with just one
suite) and every Monday. The job checks this repository out beside the app on Ubuntu 24.04, installs the system
packages listed above and calls `./run.sh`; the report is kept as the `gui-test-results` artifact.

## Known gaps

- The file dialogs are answered by a stand-in for the desktop's file-chooser portal (see
  [How it works](#how-it-works)): the cases check what the app asks for and what it does with the answer. The
  dialog's own look, which belongs to the desktop, and the `zenity` fallback the app uses when no portal answers
  are not covered.
- A few cases are **Not implemented**: low-value P3s, or too timing-fragile to assert reliably from outside the
  process (a cancel-mid-query race, a save racing a document change, a sub-frame "Rendering…" transient).
- **One finding is open, not a gap in the suite**: Save… pressed while a query is still running writes a file with only
  the results that had arrived by then, once the query has ended, and says "Saved to …"
  ([docs/09_saving.md](docs/09_saving.md), TC-SAVE-011). No case pins it until the app's behaviour is decided.
- Native Wayland behaviour that cannot be seen under X (a window covered by another gets no redraw callbacks)
  is covered by the app's own tests, `crates/app/src/app/layout_tests.rs` in
  [jsonquery_gui](https://github.com/nujufas/jsonquery_gui).

Each of these is listed with its reason in the traceability matrix; apart from the finding above, none is a known defect of the app.

## Links

- App: [jsonquery_gui](https://github.com/nujufas/jsonquery_gui), with its
  [releases](https://github.com/nujufas/jsonquery_gui/releases) and
  [issues](https://github.com/nujufas/jsonquery_gui/issues)
- This repository: [jsonquery_test](https://github.com/nujufas/jsonquery_test)
- Robot Framework: [robotframework.org](https://robotframework.org),
  [user guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html)

## License

[MIT](LICENSE)
