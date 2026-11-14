# Tutorial pages for the jq functions — test requirements

Source: `crates/query/src/tutorial/jq.rs` (the lessons) and `crates/app/src/tutorial.rs` (the
window) in [jsonquery_gui](https://github.com/nujufas/jsonquery_gui); the help tabs (at the end of this document) are
`crates/app/src/tutorial/help.rs` and `help_tab.rs`. The window itself — opening,
closing, tabs, the buttons' hand-off, themes — is covered by `satellites`
([14_tutorial_and_about_windows.md](14_tutorial_and_about_windows.md)); this document is about the
**lessons** that teach the functions the app adds ([17_jq_functions.md](17_jq_functions.md),
[18_output_formats.md](18_output_formats.md)).

## The pages

The jq tab has two topics for them, one page per feature, and two cheat-sheet rows:

| Topic | Pages |
|---|---|
| **Tables & lookups** | CSV & TSV · Records to a table · Quoting & escaping · Copy & save as CSV or TSV · IN · INDEX & JOIN |
| **Event streams** | tostream · fromstream & truncate_stream |
| *Reference* | the **Cheat sheet** has rows for `@csv`, `INDEX`, `IN` and `tostream`; **jq here vs jq 1.7** says jsonquery adds the functions jaq lacks and lists what is still missing |

Each page has a short summary, one to three examples (a caption, the query with its explained
fragments tinted, four buttons — ▶ Try it, Load query, Load data, Copy query — the live result
and an explanation) and a few *Good to know* tips. The examples run on the real engine, so the
result on the page is not a pasted copy; the app's own test `every_filter_jsonquery_adds_has_a_lesson`
fails if one of the functions loses its page.

## How a case checks

- **Finding a page.** The filter box leaves only the lessons that mention the typed text (title,
  summary, an example's query or caption, a cheat-sheet row). `Show Lesson` types a text that only
  one lesson has and clicks the first row. The row's click point is at x=36: a selectable label is
  only as wide as its title, and "IN" ends at x=43.
- **What OCR reads.** The big title and the example captions are read. A two-letter title (`IN`)
  is not read reliably, nor is the jq/iq label, nor the small grey summary: for those the body is
  checked instead.
- **Every example is run in the main window, exactly.** `Try Example` finds the example by its
  caption, scrolls to it, presses its ▶ Try it, waits until the query has run in the main window
  and `Results Should Be Json` / `Results Should Be Text` read the results back through
  Copy to Clipboard. The expected values are what jq 1.8.1 prints for the same query over the
  tutorial's data.
- **The buttons are found by colour.** ▶ Try it is the only control filled with the selection
  blue; OCR reads its white-on-blue label as "Tryit" or not at all. The other three buttons are at
  fixed distances to its right.
- **A cheat-sheet row** is found by its description and its own ▶ (at the row's left, x=294) is
  pressed.

## Cases (`suites/tutorial_pages/`)

| ID | Title | Priority |
|---|---|---|
| TC-TUT-001 | The @csv Filter Lists The Four Table Pages | P1 |
| TC-TUT-002 | The tostream Filter Lists The Event Stream Pages | P1 |
| TC-TUT-003 | The INDEX Filter Finds The Page And The Cheat Sheet | P2 |
| TC-TUT-004 | Another Language Has No Table Pages | P2 |
| TC-TUT-005 | Both Topics Are In The List | P1 |
| TC-TUT-006 | Next Goes From CSV & TSV To Records To A Table | P1 |
| TC-TUT-007 | Next Goes On From The Last Table Page Into The Next Topic | P2 |
| TC-TUT-008 | Previous Goes Back From The First Event Stream Page | P2 |
| TC-TUT-009 | The Last Event Stream Page Leads On To Errors | P3 |
| TC-TUT-010 | CSV & TSV Opens With Its Examples And Tips | P1 |
| TC-TUT-011 | Records To A Table Opens With Its Examples And Tips | P1 |
| TC-TUT-012 | Quoting & Escaping Opens With Its Examples And Tips | P1 |
| TC-TUT-013 | Copy & Save As CSV Or TSV Opens With Its Examples And Tips | P1 |
| TC-TUT-014 | IN Opens With Its Examples And Tips | P1 |
| TC-TUT-015 | INDEX & JOIN Opens With Its Examples And Tips | P1 |
| TC-TUT-016 | tostream Opens With Its Examples And Tips | P1 |
| TC-TUT-017 | fromstream & truncate_stream Opens With Its Examples And Tips | P1 |
| TC-TUT-018 | The Compatibility Page Says The Functions Are Added | P2 |
| TC-TUT-020 | CSV & TSV: One CSV Row Per Member | P1 |
| TC-TUT-021 | CSV & TSV: A Header Row First Tab-Separated | P1 |
| TC-TUT-022 | CSV & TSV: Missing Values Are Empty Fields | P1 |
| TC-TUT-023 | Records: Header And Rows From One List Of Columns | P1 |
| TC-TUT-024 | Records: A List In One Cell | P1 |
| TC-TUT-025 | Records: An Object As Two Columns | P2 |
| TC-TUT-026 | Quoting: CSV Quotes Strings And Doubles The Quotes Inside | P1 |
| TC-TUT-027 | Quoting: TSV Quotes Nothing And Escapes Instead | P1 |
| TC-TUT-028 | Quoting: Only An Array Makes A Row | P2 |
| TC-TUT-029 | Copy & Save: The Last Step @csv Makes Rows | P1 |
| TC-TUT-030 | Copy & Save: Not The Last Step Is Still JSON | P1 |
| TC-TUT-031 | IN: Members Whose Role Is One Of Several | P1 |
| TC-TUT-032 | IN: Is Any Member In QA | P1 |
| TC-TUT-033 | IN: Skills That Are Not On A List | P1 |
| TC-TUT-034 | INDEX: A Lookup Table By Code | P1 |
| TC-TUT-035 | INDEX: Look Up The Customer Of Every Order | P1 |
| TC-TUT-036 | INDEX: JOIN Does The Matching | P1 |
| TC-TUT-037 | tostream: The Events Of A Small Value | P1 |
| TC-TUT-038 | tostream: Every Leaf As Path = Value | P1 |
| TC-TUT-039 | tostream: Where Is A Value | P1 |
| TC-TUT-040 | fromstream: Events Written By Hand | P1 |
| TC-TUT-041 | fromstream: Drop A Field From Every Record | P1 |
| TC-TUT-042 | fromstream: One Result Per Order | P1 |
| TC-TUT-050 | Load Query Puts The CSV Query In The Main Window And Nothing Else | P1 |
| TC-TUT-051 | Load Data Opens The Sample Document | P1 |
| TC-TUT-052 | Copy Query Copies The Query Exactly | P1 |
| TC-TUT-053 | Try It Replaces The Open Document And Query | P1 |
| TC-TUT-054 | A Page's Rows Can Be Saved As They Are | P1 |
| TC-TUT-060 | Cheat Sheet: One CSV Row Per Member | P1 |
| TC-TUT-061 | Cheat Sheet: A Lookup Table Keyed By Name | P1 |
| TC-TUT-062 | Cheat Sheet: Keep When The Value Is One Of Several | P1 |
| TC-TUT-063 | Cheat Sheet: The Value As Events | P1 |

## Findings

- **Two lessons mention the same words.** The first filter for the Copy & save page was "save as
  csv", which the CSV & TSV page also contains (it names the other page in its summary), so the
  first row was the wrong lesson; the heading check caught it. The filters now are phrases of an
  example caption that no other lesson has.
- **The tutorial lists `IN` as the only title narrower than its own click target.** A click at
  the middle of the row missed it, so no page opened. See the click point above.
- The pager's *Next* and *Previous* buttons cross the topic boundaries as the doc says
  (TC-TUT-006 to 009).

## Mutation checks

| Mutant | What is broken | Killed by |
|---|---|---|
| M6 | `@csv` does not double a quote | TC-TUT-026 |
| M7 | `IN` asks the opposite question | TC-TUT-031, 033, 062 |
| M8 | `tostream` leaves out its closing events | TC-TUT-037, 041, 042, 063 |
| M9 | `INDEX` keeps the first of several elements with one key | **survives**: every example of the page has distinct keys (TC-JQX-023 kills it) |
| M10 | the page "INDEX & JOIN" is called "INDEX and JOIN" | TC-TUT-003, 007, 015, 034, 035, 036 |

## The Tools tab (`suites/tutorial_pages/tutorial_tools.robot`)

The tutorial window has a fifth tab, **Tools**, after the four query languages (x = 420): a topic
*Getting started* and one for each tool (Merge JSON, Format JSON, Diff JSON, Patch JSON, Validate
Schema, Create Schema), each lesson with examples whose samples are the documents the tool's page
takes (for Merge, files the app writes into its temp folder). **▶ Try it** puts the samples in the
tool's page, sets it as the lesson says and runs it, and the Tools window opens on that page (with
the Tools docked, the tool's tab comes to the front: TC-DOCK-045); **Load samples**, 79 points right
of it, does the same without running. The lesson's *Result — …* is what the tool makes of them.

A case finds a lesson as the other cases do (the filter, the first row), presses the example's
button by its fill (▶ Try it is filled with the selection blue), and reads the Tools window's status
bar and its marked tab. The suite is a file of its own because `tools.resource` and
`tutorial.resource` both have a `${TAB_Y}`; the few points of the Tools window it needs are its
own. The cases that press Try it are tagged `window-only` (they wait for the Tools window), so the
docked main-view pass leaves them out.

| ID | Title | Priority |
|---|---|---|
| TC-TUT-064 | The Tools Tab Has A Topic For Each Tool | P1 |
| TC-TUT-065 | Try It Makes The Schema Of A Lesson's Sample | P1 |
| TC-TUT-066 | Load Samples Puts The Sample In Without Running It | P1 |
| TC-TUT-067 | Try It On A Validate Lesson Lists The Problems | P1 |
| TC-TUT-068 | Try It On A Merge Lesson Merges Its Files | P2 |
| TC-TUT-069 | Try It On A Format Lesson Formats The Sample | P2 |
| TC-TUT-070 | Try It On A Diff Lesson Compares The Two Samples | P2 |
| TC-TUT-071 | Try It On A Patch Lesson Patches The Sample | P2 |
| TC-TUT-072 | A Second Try It Goes To The Window That Is Open | P2 |
| TC-TUT-073 | A Filter Finds The Lessons Of The Tools | P2 |
| TC-TUT-074 | The Tools Tab Keeps Its Lesson | P3 |

Mutation check (2026-10-29, with the faults of [13_tools_window.md](13_tools_window.md)): R22, Load samples that
runs the tool, is killed by TC-TUT-066; R24, Try it on a Create Schema lesson that only loads the sample, by
TC-TUT-065.

## The help tabs (`suites/tutorial_pages/tutorial_help.robot`)

After Tools, the tutorial has two tabs of help on what only the desktop app has (none of it is on the website): **AI
assistants** (x = 515; only in the builds with the MCP server) and **General**, last (x = 618; at 500, after Tools, in
the build without the server).

| Tab | Topics and lessons |
|---|---|
| AI assistants | *Getting started*: What MCP is (MCP, and the server's 27 tools in groups), Start the server, Read or Edit · *Add it to an assistant*: Claude Code, Claude Desktop, VS Code, QuickAI, Other assistants · *Using it*: What to ask, Large documents |
| General | *Command line*: Open a document as the app starts, Run a query as it opens, Open a tool, Help, the version, and mistakes · *Working with the app*: Keys, Big files, The Workspace, Read more |

A lesson is a summary, links, commands (each in a box with a **Copy** button at its right, which puts it on the
clipboard and says "Copied." in the status line), *Good to know* tips and pictures over their captions; nothing in it
runs anything. Claude Code's lesson has a picture, VS Code's and QuickAI's two each. The status line of the AI
assistants tab begins with the server's icon (the plug with "AI", as the main window's status bar has it) and says it
opens the server's panel; General's says what Copy does. The *Start the server* lesson shows the icon too, where it
speaks of it, in place of words for it.

### How a case checks

- **It does what the help says.** A command is copied with its Copy button (the buttons are found by OCR in their
  column, x 960–1040, top to bottom) and run as the app's command line, in a folder with the files the commands name:
  `Shell Words` splits it as a shell does (quotes, and a `|` that is not quoted), the app's words are those after the
  last pipe, and the app under test takes the place of `jsonquery_gui`. What the window then has is read through the
  MCP server (`get_state`, `get_results`); a tool's command opens the Tools window, whose tab and status bar are read;
  `--help` and `--version` are run where printing is all they should do. For the pipe's command the file's text is
  piped in for what curl prints. git's difftool line is checked as git runs it — the command given to `-x`, with the
  two versions after it — not by running git: the app is started with nothing on its PATH but the stand-in for the
  browser.
- **A link** is found by its colour (egui's dark hyperlink blue, 90 170 255) and clicked; the stand-in for the browser
  writes the address down. The opener writes a bare host's address with its slash (`https://quickai.everybodyai.dev/`),
  as it does the website's.
- **What the help says of the server** is checked against the server: the number of tools in *What MCP is* and each
  tool's name against `tools/list`; the address in *Start the server* against the panel of a first start (no
  `mcp.json`: 7457, and nothing started); QuickAI's "about 7K tokens before the first question" against what the
  server gives before a question — its instructions and the list of its tools, 27,198 characters on 2026-11-14 — at the
  panel's four bytes a token, rounded to thousands (`Mcp Characters Before A Question`); its "6K more with *Answers*
  at 24 KB" and its 8 KB against the panel's ≈ 6,000 and ≈ 2,000 tokens.
- **The tools' names** are on chips, which OCR reads only once their grey is made black (`flatten_tints`); a name is
  read when a word of the text, or two (an underscore read as a space), is 0.92 alike or more (`Words Not Read`),
  which forgives "workspace_lList" and does not take `workspace_move` for `workspace_open` (0.86).
- **A picture** is a bright block at least 120 rows high on the dark window (`Find Bright Blocks`); its caption is the
  first line of text under it, found by its pixels and read alone with a margin of window around it (`Picture
  Caption Should Be Read`). The lesson is scrolled down until it is so.
- **The icon** cannot be read by OCR: the cases see ink at the start of the line and the word "plug" nowhere. That it
  is the status bar's icon (the plug with its "AI", not a glyph) is the app's layout test
  `the_help_shows_the_icon_where_it_speaks_of_it`.
- **OCR's misreadings**, met here: "QuickAI" is read "QuickAl" (the cases look for "Quick"), "General" at 720 wide
  "Generel" ("Gener"), the italic "9B" of the model "98"; a region with a picture in it reads little of the text beside
  it, so the QuickAI lesson's text is read above its pictures (`Lesson Text Above Its Pictures`); a caption's weak text
  (about 95 on 27) is not read in a strip that has the picture's frame or the next picture's edge in it.
- A help lesson is short: its pager is right under it, and is found by the title of the lesson it goes to.

| ID | Title | Priority |
|---|---|---|
| TC-TUT-075 | The Help Tabs Come After Tools, General Last | P1 |
| TC-TUT-076 | Each Help Tab's Status Line Says What Is There To Do | P2 |
| TC-TUT-077 | Copy Puts The Command On The Clipboard As It Is Shown, And Says So | P1 |
| TC-TUT-078 | The Commands That Open A Document Open It | P1 |
| TC-TUT-079 | The Commands That Run A Query Run It As The Lesson Says | P1 |
| TC-TUT-080 | The Commands That Open A Tool Fill Its Page And Run It | P2 |
| TC-TUT-081 | The Help And Version Commands Print And Open No Window | P2 |
| TC-TUT-082 | The Keys Lesson's F1 Opens The Tutorial | P3 |
| TC-TUT-083 | What MCP Is Says As Many Tools As The Server Has, And Names Each | P1 |
| TC-TUT-084 | Start The Server Shows The Icon And The Panel's Own Address | P2 |
| TC-TUT-085 | The QuickAI Lesson Names The Model And The Context, And Links To QuickAI | P1 |
| TC-TUT-086 | The QuickAI Lesson's Numbers Are The Server's And The Panel's | P3 |
| TC-TUT-087 | The Assistants' Lessons Show Their Pictures | P2 |
| TC-TUT-088 | The Read More Links Open The Docs | P2 |
| TC-TUT-089 | What To Ask: Copy Copies The Question As It Is | P3 |
| TC-TUT-090 | The Filter Finds A Help Lesson On Either Tab | P2 |
| TC-TUT-091 | Next And Previous Walk The Help Lessons Across Their Topics | P2 |
| TC-TUT-092 | Each Help Tab Keeps Its Lesson | P3 |
| TC-TUT-093 | The Build Without The Server Has No AI Assistants Tab | P1 |
| TC-TUT-094 | Every Tab Is In The Tutorial At Its Narrowest | P3 |

TC-TUT-080 waits for the Tools window (`window-only`); TC-TUT-083, 084 and 086 open the MCP panel, whose points are
the undocked window's (`undocked-only`). TC-TUT-093 runs the build without the server, which `run.sh` now builds
for a run that takes `suites/tutorial_pages/` in.

### Findings

- **A character no font of the window has.** The summary of *Read more* named the About button `ⓘ` (U+24D8), which
  the tutorial drew as an empty box (seen in the first screenshots of the tab, not by a case). It is `ℹ` now, the
  button's own, and the app has a test that checks every text of every tab against the fonts it is drawn in — a
  label's against the proportional font, a prose's too but for its arrows, which it draws in the monospace font, and a
  command's, a query's or a sample's against the monospace one (`every_character_the_tutorial_shows_has_a_glyph`). It
  found no other.
- **The build without the server linked to the server's page.** Its *Read more* had "The MCP server, all of it"; the
  link is only in the builds with the server now (TC-TUT-093).
- **What the help says of the server holds**: 27 tools, each named; 7457; about 7K tokens before a question (27,198
  characters, 6.8K at four a token); 6,000 tokens at 24 KB.
- The app's layout test said the tabs take two rows at the narrowest window; the window has one row at 720 (the test
  checks that General is in it), and its name says so now.
- During the round the owner had the *Start the server* lesson show the icon instead of describing it ("The button
  with a plug and *AI*, left of the ⚙…"); the AI assistants tab's status line does the same.

### Mutation checks

One fault at a time in a build of the app, and the cases meant to see it run on that build (the runner restores the
file and touches it, so that cargo does not keep the fault). **34 faults, all killed.**

| Fault | What is broken | Killed by |
|---|---|---|
| H1 | General comes before AI assistants | TC-TUT-075 |
| H2 | the AI assistants tab is called "MCP" | TC-TUT-075 |
| H3 | the AI assistants tab's line under the tabs says something else | TC-TUT-075 |
| H4 | the AI assistants tab's status line has words for the icon and no icon | TC-TUT-076 |
| H5 | Copy copies a command without the program's name | TC-TUT-077 |
| H6 | Copy says nothing in the status line | TC-TUT-077 |
| H7 | the pipe's command ends without its `-` | TC-TUT-077, 078 |
| H8 | "A jq query" says `--querry` | TC-TUT-079 |
| H9 | the JSONPath query's `--lang` names jmespath | TC-TUT-079 |
| H10 | the JSON Pointer is `/items/1` | TC-TUT-079 |
| H11 | the file of a query is named `names.json` | TC-TUT-079 |
| H12 | Validate's two files are given the other way round | TC-TUT-080 |
| H13 | git's difftool is given `--merge` | TC-TUT-080 |
| H14 | the version's command is `-v` | TC-TUT-081 |
| H15 | the tutorial's key is F2 | TC-TUT-082 |
| H16 | What MCP is says 26 tools | TC-TUT-083 |
| H17 | What MCP is leaves out `reveal` | TC-TUT-083 |
| H18 | Start the server gives the port 7458 | TC-TUT-084 |
| H19 | Start the server has words for the icon | TC-TUT-084 |
| H20 | QuickAI's model is a 4B one | TC-TUT-085 |
| H21 | QuickAI's context is 16K | TC-TUT-085 |
| H22 | QuickAI's link goes to a `.com` | TC-TUT-085 |
| H23 | QuickAI's tools take "about 5K tokens" | TC-TUT-086 |
| H24 | no lesson draws its pictures | TC-TUT-087 |
| H25 | a picture's PNG is not decoded (its caption is drawn alone) | TC-TUT-087 |
| H26 | a picture is drawn a quarter as wide | TC-TUT-087 |
| H27 | Read more's command-line link goes to `cli.md` | TC-TUT-088 |
| H28 | What to ask copies a shorter question | TC-TUT-089 |
| H29 | the filter looks at the help lessons' titles only | TC-TUT-090 |
| H30 | the help lessons' pager does nothing | TC-TUT-091 |
| H31 | both help tabs keep one lesson between them | TC-TUT-092 |
| H32 | the build without the server links to the MCP server's page | TC-TUT-093 |
| H33 | the build without the server has no General tab | TC-TUT-093 |
| H34 | the tabs are wider and on one row, whatever the window's width | TC-TUT-094 |

That the icon in *Start the server* is the status bar's (the plug with its "AI") and not the 🔌 glyph alone is not
seen from outside: OCR cannot read it, and the glyph leaves ink where the icon does. The app's layout test
`the_help_shows_the_icon_where_it_speaks_of_it` sees it.
