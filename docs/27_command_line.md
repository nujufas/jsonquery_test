# The command line — test requirements

Source: `crates/app/src/cli.rs` (what the command line asks for, the help, the version, the name the program goes
by, the folder it was started in), `main.rs` (read before the window opens: what is printed ends the program),
`app.rs` (`App::launch`, `open_stdin`, `source_of_text` with `file://` addresses), `worker.rs` (`read_piped`, which
shares `load_stream` with the download), `tools.rs` (`Tools::open_files`) and each tool's page (a `use_file`/
`use_files` that loads and runs). What a person reads of it is the app's `docs/command-line.md`, the README's Usage and
`jsonquery_gui --help`.

The app takes a command line:

- **a document** — `jsonquery_gui data.json` opens a file (a relative path from the folder it was started in, as the
  shell calls that folder: `$PWD`, where it is the same folder, else the system's), `jsonquery_gui https://…` a web
  address, `… | jsonquery_gui -` what is piped in (as a download is: in memory, or from the size files are kept on disk
  from, in a temporary file nobody else can open; **Source** stays empty and the line beside it says
  `(standard input)`), and a `file://` address (which **Source** takes too now) the file it names;
- **a query** — `--query`/`-q` puts it in the query box, and it runs once the document has loaded, in the language
  `--lang`/`-l` names (`jq`, `jsonpath`, `jmespath`, `pointer`, as the MCP server takes them) or the one told from it;
  `--pointer`/`-p` is a query in the Pointer language; a file whose name ends in `.jq`, `.jsonpath`, `.jmespath` or
  `.jsonptr` beside the document is a query, as when it is dropped on the window;
- **several documents** go to Merge's list, as when they are dropped, and nothing is merged;
- **a tool's page** — `--diff`, `--merge`, `--patch`, `--validate`, `--format`, `--create-schema` fill the page with the
  files, in the order of its boxes, bring it to the front and run it once its boxes are full;
- `--help`/`-h` and `--version`/`-V` print and end, with no window; a command line that cannot be done is said on the
  error output with `See jsonquery_gui --help.`, and ends the program with 2, with no window; a document that cannot be
  opened is said in the window, as **Load** says it.

## How the cases work

`Launch Jsonquery App` takes the app's command line (`args`), the folder it is started in (`cwd`, with `$PWD` set to it
as a shell has it) and text to pipe into it (`stdin_text`: written from a thread, then the pipe closed, as `echo … |`
does). The cases of the main window start the app with its MCP server (`Launch Mcp App Serving`) and read what it has
through `get_state`, which is exact: the document's source and path, whether it is kept on disk, the query's text, its
language and whether that was picked, the count of its results, the error of a load. What a tool shows is read by OCR of
the Tools window, with the keywords of the Tools suites (`Tab Row Should Offer Changes`, `Status Should Read`).

What prints and opens no window is run by `Run Jsonquery Command Line`: on the suite's display, with a settings folder of
its own, input empty (or a terminal: `stdin_terminal`, a pty), and a timeout of 10 s — a run that opened its window
would still be running, and fails the case; so does one that wrote to its settings folder.

The suite is `suites/command_line/command_line.robot`, tagged `undocked-only` (its cases open the Tools window; one
starts with the Tools docked by its settings). TC-CLI-002 runs the build without the MCP server, which run.sh builds
into `target/nomcp` for this suite as for `suites/mcp`.

## Cases

| ID | Title | Priority |
|---|---|---|
| TC-CLI-001 | --version Prints The Version, And No Window Opens | P1 |
| TC-CLI-002 | The Build Without The MCP Server Says So In Its Version | P2 |
| TC-CLI-003 | --help Says How To Use It, Option By Option, And No Window Opens | P1 |
| TC-CLI-004 | A Command Line That Cannot Be Done Is Said, Ends With 2, And No Window Opens | P1 |
| TC-CLI-005 | A Dash With Nothing Piped In Is Said, And No Window Opens | P2 |
| TC-CLI-006 | A File Given Is Opened, As Load Opens It | P1 |
| TC-CLI-007 | A Relative Path Is Opened From The Folder The App Was Started In | P1 |
| TC-CLI-008 | A Query Given Is Put In The Box And Runs On The Document Once It Has Loaded | P1 |
| TC-CLI-009 | --lang Names The Query's Language, Which Is Picked | P1 |
| TC-CLI-010 | --pointer Shows The Value It Points At | P1 |
| TC-CLI-011 | A File Of A Query Beside The Document Is Put In The Box And Run, As When It Is Dropped | P1 |
| TC-CLI-012 | What Is Piped In Is Opened, With No Address In Source | P1 |
| TC-CLI-013 | A Large Pipe Is Kept On Disk And Queried From There | P2 |
| TC-CLI-014 | A Web Address Given Is Downloaded | P1 |
| TC-CLI-015 | A file:// Address Is The File It Names | P2 |
| TC-CLI-016 | A Document That Cannot Be Opened: The Window Opens And Says Why, And The Query Waits | P1 |
| TC-CLI-017 | Several Documents Go To Merge's List, As When They Are Dropped | P1 |
| TC-CLI-018 | --diff Compares The Left File With The Right | P1 |
| TC-CLI-019 | --validate Checks The Document Against The Schema | P1 |
| TC-CLI-020 | --patch Applies The Patch To The Document | P1 |
| TC-CLI-021 | --format Formats The File | P1 |
| TC-CLI-022 | --create-schema Makes The Schema Of The File | P1 |
| TC-CLI-023 | --merge Merges The Files | P1 |
| TC-CLI-024 | A Tool Given Fewer Files Than Boxes Fills What It Can, And Waits | P2 |
| TC-CLI-025 | With The Tools Docked, A Tool's Tab Comes To The Front | P2 |

## What these cases do not reach

- **Every way a command line can be wrong**, the parsing of each option, a path that is not text, the program's name in
  a snap or an AppImage, and the folder through a link: the app's Rust tests (`cli.rs`, 15 of them, and one of `file://` addresses in `app.rs`). What each tool
  does with one file or two, a file it cannot read, a query that waits for a document that failed: the app's layout
  tests (`app/layout_tests/launch_tests.rs`, 17). What is piped in, small, large, over the limit and broken: the
  worker's (4).
- **Windows.** There the app is a program with windows, which borrows the console of the terminal it was started from
  to print `--help`, `--version` and its errors (`AttachConsole`); it is checked by clippy for Windows and by the CI's
  tests on Windows, not run here.
- **macOS** hands a file opened from the Finder to the app as an event, not as an argument; the app does not take that
  event yet (said in `docs/command-line.md`).
- **The desktops' "Open With"**: the menu entries of the AppImage, the snap and the AUR say that the app opens JSON
  (`MimeType=application/json;`) and hand it the files (`%F`, the snap's `%U`); `build/verify.sh` checks the AppImage's
  entry and runs `--version` through its AppRun and the tarballs' binaries. A file manager is not driven.
- **An app that is already running** is not handed the document: a second launch opens a second app, as before.

## What the runs found

The first run, on the debug build, passed 16 of 25. Eight failures were the cases': five did not find
`Run Jsonquery Command Line`, which lacked its `@keyword`; TC-CLI-017 and 024 read `in_front` from `get_state`, which
names a tool only when the Tools are docked (with their window open it is `Json Query`: they look at the window's tab
now); TC-CLI-012 copied the empty Source field, which copies nothing (it reads the field's hint now). One was the app's:

- **A relative path was made whole from the folder as the system names it.** Started in a folder reached through a
  link, the app opened `/run/media/…/people.json` where the shell that started it named the folder through the link
  (TC-CLI-007). The app takes `$PWD` now when it is the same folder as the system's, and the system's otherwise
  (`cli::working_folder`, with a Rust test through a link).

Then 25 of 25. Twenty faults were put into the app one at a time, each run against the case meant for it, and **all were killed**:

| Fault | Killed by |
|---|---|
| `--version` opens the window | TC-CLI-001 |
| the build without the server does not say so | TC-CLI-002 |
| the help leaves `--pointer` out | TC-CLI-003 |
| an option that is not one is taken for a file | TC-CLI-004 |
| a command line that cannot be done ends with 1 | TC-CLI-004 |
| no check for a terminal behind `-` | TC-CLI-005 |
| a relative path is not made whole | TC-CLI-007 |
| the query is not run once the document has loaded | TC-CLI-008 |
| `--lang` does not pick the language | TC-CLI-009 |
| `--pointer` does not pick Pointer | TC-CLI-010 |
| a file of a query is not read | TC-CLI-011 |
| nothing is read from the pipe | TC-CLI-012 |
| a large pipe is never kept on disk | TC-CLI-013 |
| a web address is taken for a file | TC-CLI-014 |
| a `file://` address is not decoded | TC-CLI-015 |
| several documents are merged at once | TC-CLI-017 |
| Diff is filled and not run | TC-CLI-018 |
| Validate's document and schema are swapped | TC-CLI-019 |
| Merge is filled and not run | TC-CLI-023 |
| a tool's page is not shown | TC-CLI-025 |

