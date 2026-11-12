# The MCP server — test requirements

Source: the app's cargo feature `mcp` — `crates/mcp` (the protocol, the HTTP server, the tools' list, `jsonquery-mcp`)
and `crates/app/src/app/mcp.rs` with `app/mcp/` (the 🔌 and its panel, `mcp.json`, what the tools do in the app). What
a person reads of it is the app's `docs/mcp.md`, the README ("With an MCP server, for AI assistants") and `PRIVACY.md`
("The build with the MCP server").

The build with **mcp** in its name (a GitHub release download only, never the stores) is the app with a
[Model Context Protocol](https://modelcontextprotocol.io) server that an AI assistant can use:

- a **🔌** at the right of the status bar, the last of its buttons there (left of the ⚙, or of the 🗗 with the Tools
  docked), so that every other button is where it is in the build without MCP; grey while the server is off, green
  while it runs, with a spinner at its left while an assistant's call is answered;
- one click opens a **panel** above it that keeps one size and the same rows whatever happens (Start and Stop are in
  the same place): Start/Stop, the address (`http://127.0.0.1:<port>/mcp`, the port editable while stopped, 7457 at
  first), **Allow** (Read, the default; Edit) and **Always allow** (greyed out with Read), **Answers** (the most an
  answer holds: 4, 8, 16, 24, 64 or 200 KB, 24 at first, with about how many tokens that is), **Add to** buttons that
  copy what adds the server to Claude Code, Claude Desktop, VS Code, QuickAI or any other assistant (JSON), **Start it
  with JsonQuery**, who is connected, how many calls and the last five (a refused one in red), and **New token**;
- with Edit, a **question** over the main window before anything is deleted or replaced, written outside the
  workspace, or fetched from the web — Allow, Always allow (which ticks the panel's box), Don't allow, Escape — unless
  Always allow is ticked;
- the tools that only read work **out of sight**, on any document (the open one, the results, a file, a workspace item,
  JSON given, or `"last"`: what the assistant's last query or tool of the Tools made), and every answer is a page of
  at most the size the user set;
- the server listens on 127.0.0.1 only, answers only with its token, refuses web pages and other hosts, and keeps its
  port, token, access and start-with-app in `mcp.json` beside `settings.json`, mode 600;
- **`jsonquery-mcp`**, a program beside the app, is what Claude Desktop and llama-server (QuickAI) start: it answers the
  handshake and the list of tools by itself and takes each call to the app, with the token of `mcp.json`.

## How the cases work

- **The build.** `run.sh` builds the MCP variant too (`cargo build -p jsonquery_gui -p jsonquery-mcp --features
  jsonquery_gui/mcp --target-dir target/mcp`) when the run takes `suites/mcp/` in, so it never takes the place of the
  usual binary; `run_parallel.sh` builds both and freezes both, the app and `jsonquery-mcp` together (the app looks for
  the program beside itself). `Launch Jsonquery App  build=mcp` starts it (`JQ_TEST_MCP_BINARY`), and `home_files=`
  puts an `mcp.json` in the launch's settings folder first.
- **A port of its own.** `Launch Mcp App` gives every app an `mcp.json` with a port nothing listens on (`Free Port`), so
  that the lanes of a run, and the JsonQuery of whoever runs the suite, never meet on 7457. TC-MCP-004 starts without
  one, to see the defaults, and starts nothing.
- **An assistant.** `resources/mcp_client.py` talks to the server as an assistant does — `initialize`, `tools/list`,
  `tools/call` over HTTP with the token of `mcp.json` — and runs `jsonquery-mcp` as Claude Desktop does, one JSON-RPC
  message to a line on its stdin (`Bridge Exchange`, `Bridge Tool Call`). What the window shows is read as in the other
  suites; what the assistant was told is checked from its answer.
- **The panel's points are fixed** (`resources/mcp.resource`): it hangs from the status bar and keeps its size, which the
  app's layout test `the_plug_comes_last_in_the_status_bar_and_opens_the_mcp_panel` holds it to. The docked profile
  moves the main window's points by the row of tabs, which does not move the panel, so the suites are tagged
  `undocked-only`; TC-MCP-031 docks the app itself and reads the plug and the panel 29 pixels further left.
- **Its lines are read by OCR**, the weak ones too ("Not running", "No calls yet"): at this size they read well. A
  button under the pointer is lit and its label is not read, so the keywords take the pointer off Start and Stop
  before they read the title row. `workspace_list` is read as "workspace list". The sizes of the Answers row are read
  by their fill (the chosen one is the selection's blue), not by OCR, which reads "24 KB" as "24KB"; its "≈ 6,000
  tokens" comes back as "6 000" at times (`Tokens Should Say` takes both).
- **The rows above Answers moved up by one** when the row came (2026-11-12): the title, the address and Allow are 24
  pixels higher than before, and the panel is 332 high; the rows from "Add to" down did not move.
- **The question** is found by its buttons' fill (`Question Buttons`, `resources/mcp_client.py`): OCR does not read
  their small labels on the dimmed window. It is as tall as what it asks, so the buttons are looked for, not at a fixed
  point, and its text is read above them. A call that asks waits for the answer: it is made on a thread of its own
  (`Start Mcp Call`), answered, then waited for. A call that must ask nothing is made with `timeout=10`, which a
  question would outlast.

## Cases

`suites/mcp/mcp_panel.robot` (the 🔌 and the panel), `mcp_calls.robot` (an assistant's calls, seen in the window),
`mcp_bridge.robot` (`jsonquery-mcp`), `mcp_edit.robot` (what Edit changes of what is kept, and the questions),
`mcp_tools.robot` (the Tools as tools, out of sight, `"last"`, `document_info`, pages).

| ID | Title | Priority |
|---|---|---|
| TC-MCP-001 | The Plug Is The Last Of The Buttons At The Right Of The Status Bar | P1 |
| TC-MCP-002 | Hovering The Plug Says What It Is For And That A Click Sets It Up | P1 |
| TC-MCP-003 | A Click On The Plug Opens Its Panel And A Click Elsewhere Closes It | P1 |
| TC-MCP-004 | The Panel Of A First Start: Off, On Port 7457, Read, Answers Of 24 KB, And Nothing Written | P1 |
| TC-MCP-005 | Start Makes The Server Answer On Its Address, Turns The Plug Green And Writes mcp.json For Its Owner | P1 |
| TC-MCP-006 | Stop Stops The Server, Greys The Plug And Says Not Running | P1 |
| TC-MCP-007 | Hovering The Plug While The Server Runs Gives Its Address | P2 |
| TC-MCP-008 | The Port Is Changed While The Server Is Stopped, Kept, And Listened On | P1 |
| TC-MCP-009 | What Is Not A Port Is Not Taken | P2 |
| TC-MCP-010 | A Port Another Program Holds Is Said In Red, And The Plug Stays Grey | P1 |
| TC-MCP-011 | Read, The Default, Lets The Assistant Look But Not Change What The Window Shows | P1 |
| TC-MCP-012 | Edit, Chosen While The Server Runs, Works From The Next Call And Is Kept | P1 |
| TC-MCP-013 | Going Back To Read Refuses The Next Call That Would Show | P2 |
| TC-MCP-014 | Claude Code's Button Copies The Command That Adds The Server, With Its Token | P1 |
| TC-MCP-015 | VS Code's And JSON's Buttons Copy Entries Of Type http With The Address And The Token | P1 |
| TC-MCP-016 | Claude Desktop's And QuickAI's Buttons Copy What Starts jsonquery-mcp, With No Token | P1 |
| TC-MCP-017 | What Claude Code's Command Holds Reaches The Server | P2 |
| TC-MCP-018 | Copied Is Said At The End Of The Last Row For A Few Seconds, And Nothing Moves | P2 |
| TC-MCP-019 | Without jsonquery-mcp Beside The App, Claude Desktop And QuickAI Are Greyed Out And Say Why | P1 |
| TC-MCP-020 | Start It With JsonQuery Is Kept, And The Next Start Of The App Starts The Server | P1 |
| TC-MCP-021 | Without It, The Next Start Leaves The Server Off, Even If It Ran When The App Was Closed | P1 |
| TC-MCP-022 | The Panel Names The Assistant That Connected And Counts Its Calls | P1 |
| TC-MCP-023 | The Last Calls Are Listed Newest First, A Refused One In Red | P1 |
| TC-MCP-024 | Only The Last Five Calls Are Listed, All Of Them Counted | P3 |
| TC-MCP-025 | New Token: The Old One Is Refused, The New One Taken, And The Server Goes On | P1 |
| TC-MCP-026 | The Token Is Kept Between Starts Of The App | P2 |
| TC-MCP-027 | A Request Without The Token, From A Web Page Or For Another Host Is Refused | P1 |
| TC-MCP-028 | A Spinner Turns Beside The Plug While An Assistant's Call Runs | P2 |
| TC-MCP-029 | Closing The App Stops The Server | P2 |
| TC-MCP-030 | An mcp.json That Cannot Be Used Is Said In The Panel, And The Defaults Stand In | P2 |
| TC-MCP-031 | With The Tools Docked The Plug Is Left Of The Undock Button, And Its Panel Opens Above It | P2 |
| TC-MCP-032 | Answers: A Size Chosen Is Said In Tokens, Kept, And Used From The Next Call | P1 |
| TC-MCP-033 | Always Allow Is Greyed Out With Read, Is Ticked With Edit, And Is Kept | P1 |
| TC-MCP-040 | get_state Says What The Window Shows: The Document, The Query And Its Results | P1 |
| TC-MCP-041 | run_query Answers The Assistant And Changes Nothing In The Window | P1 |
| TC-MCP-042 | set_query Puts The Query In The Box And Runs It, And get_results Gives What The Window Shows | P1 |
| TC-MCP-043 | set_query In JSONPath Picks JSONPath In The Window | P2 |
| TC-MCP-044 | open_document Opens A File As The Source, And The Window Shows It | P1 |
| TC-MCP-045 | open_document With JSON Text Shows It As The Source | P2 |
| TC-MCP-046 | open_document Refuses A Web Address And A Relative Path, And The Window Keeps Its Document | P2 |
| TC-MCP-047 | reveal Opens The Source Tree Down To A Value | P1 |
| TC-MCP-048 | workspace_list Gives The Saved Queries, And workspace_open Opens One In The Query Box | P1 |
| TC-MCP-049 | workspace_open Never Loads A Web Address, And workspace_read Gives It | P1 |
| TC-MCP-050 | A Call That Shows Something Works While The Window Is Minimized | P1 |
| TC-MCP-051 | The User's Own Query Runs While The Assistant's Long Query Runs | P2 |
| TC-MCP-052 | search Finds A Value With Its Pointer | P2 |
| TC-MCP-053 | describe Gives The Shape Of The Document Without Its Data | P2 |
| TC-MCP-054 | query_help Gives The App's Lessons And Where Its jq Differs From jq | P3 |
| TC-MCP-055 | Read Refuses Every Call That Would Change The Window, And The Panel Lists Them In Red | P1 |
| TC-MCP-056 | A Long Answer Comes A Page At A Time | P3 |
| TC-MCP-070 | jsonquery-mcp Answers The Handshake And Lists The Tools While The App Is Closed | P1 |
| TC-MCP-071 | A Call Before The Server Was Ever Set Up Says How To Set It Up | P1 |
| TC-MCP-072 | A Call While The App Is Closed Says That JsonQuery Is Not Running | P1 |
| TC-MCP-073 | A Call Through jsonquery-mcp Reaches The Running App, Which Shows It And Names The Assistant | P1 |
| TC-MCP-074 | jsonquery-mcp Follows A New Token And A New Port By Itself | P2 |
| TC-MCP-075 | jsonquery-mcp Says What It Is When Run By Hand | P3 |
| TC-MCP-076 | Through jsonquery-mcp An Answer Is Kept To The Size Of Page The User Set | P2 |
| TC-MCP-080 | Deleting From The Workspace Is Asked First, And Don't Allow Keeps The Item | P1 |
| TC-MCP-081 | Allow Deletes It: A Folder With What Is In It | P1 |
| TC-MCP-082 | Escape Is Don't Allow | P2 |
| TC-MCP-083 | Always Allow In The Question Does It, Ticks The Panel's Box, And Nothing Is Asked After | P1 |
| TC-MCP-084 | With Always Allow Ticked Nothing Is Asked, And Unticking It Brings The Questions Back | P2 |
| TC-MCP-085 | A New Item Is Saved Without A Question, And Replacing One Is Asked First | P1 |
| TC-MCP-086 | Folders Are Made, And Items Moved And Renamed, Without A Question | P2 |
| TC-MCP-087 | A File Is Saved After The User Allows It, As Indented As Asked, And Replaced Only With replace | P1 |
| TC-MCP-088 | A Web Address Is Loaded As The Source Only When The User Allows It | P1 |
| TC-MCP-089 | A Page Of The Tools Is Shown With The Assistant's Values In Its Boxes, Run | P1 |
| TC-MCP-090 | With Read Nothing Is Written, Moved, Deleted, Fetched Or Shown, And Nothing Is Asked | P1 |
| TC-MCP-091 | While A Question Waits The Panel Says So | P2 |
| TC-MCP-100 | format_json Gives The Document Formatted, And The Window Keeps What It Shows | P2 |
| TC-MCP-101 | diff_documents Gives The Differences By Pointer, And Its Patch, Kept As last, Turns The Left Into The Right | P1 |
| TC-MCP-102 | merge_documents Appends Or Merges Deep, And Keeps The Merge As last | P2 |
| TC-MCP-103 | validate_json Says What Is Wrong And Where, A Page At A Time | P1 |
| TC-MCP-104 | create_schema Describes The Document, And The Schema Kept As last Checks It | P2 |
| TC-MCP-105 | document_info Says What The Open Document Is, Without Its Data | P1 |
| TC-MCP-106 | A File Is Read Out Of Sight, And The Window Keeps Its Own Document | P1 |
| TC-MCP-107 | What run_query Gives Is Kept As last: Queried Again, And Saved Without Passing Through The Answer | P1 |
| TC-MCP-108 | With Answers Of 4 KB Every Long Answer Is A Page Of 4 KB At Most, And Its Pages Give All Of It | P1 |
| TC-MCP-109 | What A Model Reads Of The Tools Before It Does Anything Is Short | P3 |

## What these cases do not reach

What the answers say in detail — the shapes `describe` gives and the levels it drops to fit a page, every tool's
errors, the protocol versions and the 2026-07-28 probe, cancelling, a document kept on disk, batches, the 16 MB that
`run_query` keeps as `"last"` at most, the 10 seconds `document_info` counts for — is the Rust tests' (`crates/mcp`,
`crates/app/src/app/mcp/tests.rs`), and so are the panel's own layout and `mcp.json`'s rules. A question that is not
answered is taken back after two minutes (three seconds in the Rust tests, which check it); the window flashing in the
task bar when a question comes is the window manager's, and not looked at. The Python and TypeScript SDKs of MCP and a real
model (QuickAI's) were used against the real app by hand on 2026-11-11, not in this suite.

## What the runs found

Three faults of the app, all fixed (each with a Rust test that fails without the fix):

- **The panel named nobody for Claude Desktop or QuickAI.** `jsonquery-mcp` answered the handshake itself, so the app
  never learnt who was calling: the panel said "No assistant has connected yet" beside "1 call" (found writing
  TC-MCP-073). The program now hands the assistant's own handshake to the app before each call.
- **The port box took every port it passed through.** Typing 70000 left the port at 7000 (each keystroke that made a
  port was taken). It is taken whole now, when the box is left or Start is clicked (TC-MCP-009).
- **Stop was 3 pixels lower than Start.** The port's box is taller than the address that takes its place, and the panel
  grows upwards; the row keeps one height now (the calibration pictures, and the layout test, which compares the rows
  with the pointer off the 🔌: egui draws a hovered button a pixel bigger, and the panel hangs from it).

And in the cases themselves: Robot turns `NONE` into Python's `None` for an argument whose default is `None` (a request
"without the token" sent the token; `send_token=${False}` now); the app names `jsonquery-mcp` by its own path with the
links resolved (`std::env::current_exe`), so `Bridge Path` resolves them too; a failed case whose teardown did not close
its app left two apps on the display for the next case (the teardowns are the suite's own now).

The last runs (2026-11-11, the debug build, three lanes): 54 of 54 against the build of the phase that has them; against
the build that adds Full, 53 of 54 — TC-MCP-001, the first case of its lane, looked at the status bar before the first app on
a new display had drawn its icons (it passed 3 of 3 alone, and waits for the ⓘ now).

**2026-11-12, the second round** (Read and Edit with Always allow, the Answers row, the questions, the tools of
Edit, out of sight, `"last"`, `document_info`, pages): the cases found no fault of the app. Probing the window before
the round found one: a drop-down for the size of an answer closed the whole panel (egui keeps one popup open, and the
drop-down's list took the panel's place), so the Answers row is a row of sizes. In the cases themselves: OCR reads
"≈ 6,000 tokens" as "6 000" at times, `workspace_delete` as "workspace delete" or "workspace _delete", "It" as "lt"; a
click on the question's button closes the panel, as any click outside it does (TC-MCP-091 opens it again); a Robot
variable table does not take `\"` in an inline Python value (`&{WORKSPACE}` is a dictionary of plain items); and in
`Evaluate`, a module is not seen inside a generator (`__import__("json")`).

Twelve faults were planted in the app, one at a time (the box Always allow usable with Read; Always allow of the
question not kept; Escape not refusing; a size of page kept but not used until a restart; nothing asked; the tally
counting the top only; a file read as the open document; the page the user set not given to the tools; `run_query`
keeping nothing; the tokens said wrong; `show_in_tool` showing nothing; a new item asked about): each made its case fail,
for its own reason.

The last runs (2026-11-12, the debug build, five lanes, one to a suite file): 79 of 79.