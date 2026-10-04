# jsonquery_test

End-to-end GUI tests for [jsonquery gui](https://github.com/nujufas/jsonquery_gui), a desktop tool for
browsing and querying large JSON files with jq, JSON Pointer, JSONPath and JMESPath.

The suite starts the real application, clicks and types into it the way a person would, and reads the
screen back with OCR, pixel checks and the clipboard. It is written with
[Robot Framework](https://robotframework.org) and runs on a virtual X display of its own, so it never
touches your desktop. Status (October 2026): **369 test cases in 18 suites**.

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
sudo apt install xvfb fluxbox xdotool wmctrl xclip tesseract-ocr gnome-screenshot python3-venv python3-tk python3-dev
```

`run.sh` checks for the programs and prints the install command when one is missing. On a bare machine or in a
container the app itself also needs its runtime libraries: `libxkbcommon-x11-0 libxcb-xkb1 libgl1-mesa-dri
libegl1 mesa-vulkan-drivers libvulkan1` (the [CI job](#continuous-integration) installs them as well).

## Running tests

```sh
./run.sh                                                      # every suite (over an hour on one display)
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

A full run launches the app for every case. To go faster, run several lanes at once, each on its own display,
with its own results and a copy of the binary that a rebuild will not replace (the last full run used five
lanes):

```sh
(cd ../jsonquery_gui && cargo build -p jsonquery_gui)                 # build once
cp ../jsonquery_gui/target/debug/jsonquery_gui /tmp/jsonquery_gui-lane1
JQ_TEST_DISPLAY=:98 JQ_TEST_RESULTS=/tmp/results-lane1 \
  JQ_TEST_NO_BUILD=1 JQ_TEST_BINARY=/tmp/jsonquery_gui-lane1 ./run.sh suites/tools
# lane 2: another display (:97), its own results, its own copy of the binary, other suites
```

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
- **What it changes outside this directory.** It adds one rule to `~/.fluxbox/apps` (the app's window gets no
  title bar, which the click coordinates rely on) and creates an empty `~/.Xauthority` if there is none.

## Test suites

One directory per area of the app under `suites/`, each specified by a document in `docs/`:

| Suite | Covers | Specification |
|---|---|---|
| `launch_and_window` | default state, theme, placeholder text, no menu bar | [01](docs/01_launch_and_window.md) |
| `opening_sources` | paste, NDJSON, malformed JSON, Clear, the source field (URL, typed path, errors), replacing a loaded document | [02](docs/02_opening_sources.md) |
| `toolbar_and_status` | source label by kind, byte-size units, parse time and load errors in the status bar | [03](docs/03_toolbar_and_status_bar.md) |
| `query_engines` | the engine picker, auto-detect, each engine's own result and error behaviour | [04](docs/04_query_bar_and_engines.md) |
| `query_highlight` | colour-coding of the query box | [04](docs/04_query_bar_and_engines.md) |
| `query_box_layout` | a long query scrolls inside the box, a dragged height sticks | [04](docs/04_query_bar_and_engines.md) |
| `autocomplete` | the query box's suggestion popup (off by default, toggled with 💡) | the suite file |
| `tree_view` | row rendering and colours, expand/collapse, scrolling | [05](docs/05_tree_view.md) |
| `text_view` | Tree/Text toggles, editable paste and Apply, read-only text | [06](docs/06_text_view.md) |
| `context_menus` | row menus of the Source and Results panes, Copy JSON Path, Search... | [07](docs/07_context_menus.md) |
| `search` | the Find dialog, Find All, regex mode, Find in Source | [08](docs/08_search_and_find_in_source.md) |
| `saving` | the Save... buttons' enabled state (the dialogs themselves are [blocked](#known-gaps)) | [09](docs/09_saving.md) |
| `keyboard_shortcuts` | Ctrl+F, Ctrl+Enter, Enter | [10](docs/10_keyboard_shortcuts.md) |
| `popout` | the Query, Source and Results panes in windows of their own | [12](docs/12_popout_panes.md) |
| `tools` | the Tools window: Merge, Format, Diff, Patch, Validate (six files) | [13](docs/13_tools_window.md) |
| `satellites` | the tutorial and About windows | [14](docs/14_tutorial_and_about_windows.md) |
| `pane_headers` | the panes' titles and headers, checked in pixels | [15](docs/15_pane_headers.md) |
| `drag_and_drop` | files dropped on the main window, the Source window and the Tools pages | [16](docs/16_drag_and_drop.md) |

[11_error_and_edge_cases.md](docs/11_error_and_edge_cases.md) cross-references every error string in the app.

## Repository layout

```
run.sh                  the entry point: builds the app, sets up .venv/, starts Xvfb and fluxbox, runs Robot
requirements.txt        the Python dependencies
suites/<area>/          the Robot test cases, one directory per area
resources/
  AppLibrary.py         the Robot library: launching the app, windows, clicks, typing, OCR, pixels, clipboard, drops
  keywords.resource     shared layout constants and keywords
  tools.resource        layout constants and keywords of the Tools window
  xdnd.py               an XDND source, for dropping files on the app
  fixtures/             sample JSON files
docs/                   test strategy, a document per area, the traceability matrix
results/, .venv/        generated, and ignored by git
```

## Documentation

- [docs/writing_tests.md](docs/writing_tests.md): adding or changing cases, and the gotchas collected so far.
- [docs/00_test_strategy.md](docs/00_test_strategy.md): why the suite is built this way, what was ruled out,
  the tooling and the environment findings.
- [docs/99_traceability_matrix.md](docs/99_traceability_matrix.md): every test case ID with its status
  (`Passing`, `Blocked` or `Not implemented`, each with its reason).
- `docs/01_*.md` to `docs/16_*.md`: the requirements of each area, linked from the table above.

## Continuous integration

The app's repository runs this suite from its CI workflow
([ci.yml](https://github.com/nujufas/jsonquery_gui/blob/master/.github/workflows/ci.yml), job *GUI tests
(jsonquery_test)*): on demand from the Actions tab
([Run workflow](https://github.com/nujufas/jsonquery_gui/actions/workflows/ci.yml), optionally with just one
suite) and every Monday. The job checks this repository out beside the app on Ubuntu 24.04, installs the system
packages listed above and calls `./run.sh`; the report is kept as the `gui-test-results` artifact.

## Known gaps

- The native file dialogs (the `…` button beside the source field) and the Save dialogs hang or fail in every
  environment tried. The cases that need one to complete are marked **Blocked** in the traceability matrix;
  files get into the app by dropping them instead. Unblocking them needs an app-side change (building `rfd`
  with its `gtk3` feature instead of the default portal backend).
- A few cases are **Not implemented**: low-value P3s, or too timing-fragile to assert reliably from outside the
  process (a cancel-mid-query race, a sub-frame "Rendering…" transient).
- Native Wayland behaviour that cannot be seen under X (a window covered by another gets no redraw callbacks)
  is covered by the app's own tests, `crates/app/src/app/layout_tests.rs` in
  [jsonquery_gui](https://github.com/nujufas/jsonquery_gui).

Each of these is listed with its reason in the traceability matrix; none is a known defect of the app.

## Links

- App: [jsonquery_gui](https://github.com/nujufas/jsonquery_gui), with its
  [releases](https://github.com/nujufas/jsonquery_gui/releases) and
  [issues](https://github.com/nujufas/jsonquery_gui/issues)
- This repository: [jsonquery_test](https://github.com/nujufas/jsonquery_test)
- Robot Framework: [robotframework.org](https://robotframework.org),
  [user guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html)

## License

[MIT](LICENSE)
