# Workspace — test requirements

Source: the app's `crates/app/src/workspace.rs` and `workspace/` (the folder as data: `names.rs`, `files.rs`,
`ids.rs`, `index.rs`, `store.rs`, `transfer.rs`), `workspace_pane.rs` and `workspace_pane/` (`tree.rs` the list,
`drag.rs` moving by dragging, `forms.rs` the windows, `icons.rs` the pictures), `settings.rs` (how much of the pane
is shown), where the pane is drawn and asked for things (`app.rs`, `tools/validate.rs`, `tools/patch.rs`), and what
`app.rs` does with a file that is dropped on the window (`take_dropped_file`, `use_query_file`, `put_query`). The user's
guide is the app's `docs/workspace.md`.

The **workspace** is a folder on the computer — an ordinary one, `workspace` in the folder the app keeps its
settings in unless the user chose another — and the **pane** at the left of the window is how it is looked
through. What is in it:

- **Items**, by the end of the file's name: a query (`.jq`, `.jsonpath`, `.jmespath`, `.jsonptr`), a schema
  (`.schema.json`), a patch (`.patch.json`), a document (`.json`, `.ndjson`, `.jsonl`). An item can have a **sample**,
  `<name>.sample.json` beside it, which the items of one name share. A name that starts with a dot, a text file and
  anything else is not an item.
- **Folders**, to any depth, which the user makes, renames, moves and deletes.
- **An index**, `.jsonquery/index.json`, hidden from the person who uses the app: the **id** (a UUID of version 4) that
  each item was given when it was first stored and keeps whatever becomes of its name, place or text, and the
  **SHA-256** of what it holds (and of its sample), made right again at every read of the folder. It is what later
  work — keeping two workspaces in step, knowing that an item is the one that was shared — will go by.
- **The pane**: hidden until the **button** at the left end of the status bar is pressed (so the window is as it always
  was), then at the left of the window, 256 points wide or as wide as it was dragged to (at least 208, the room that its
  title and four buttons need, and at most half of the window), or folded to a strip of 26. The button is the first
  thing in the status bar and its text begins after it; the ⚙, the 🌐 and the ⓘ at the other end are where they were
  before there was a pane. **Three pictures**: a window with its left column filled is the pane (the status bar's button
  and the strip's: bright while the pane is shown, dim while it is not), a folder with a plus left out of it is the
  button that makes a folder, and the rows of the list have the plain folder. Each is drawn on whole pixels, and the cases
  read it as the picture it is.
- **Moving by dragging**: a row is picked up with the main button and carried over the list; the folder it would go
  into is lit (a folder row, or the row of an item, which stands for its folder, or the whole list for the top), a
  label beside the pointer says where (`Move “scratch” into “Logs / Errors”`), a shut folder that it rests on opens
  after 0.7 s, the list scrolls near its top or foot, and Escape, a release outside the list or over the folder it is
  in does nothing. The move is the menu's *Move to*: the item keeps its id and its SHA-256.
- **A query carried onto the query pane**: a query row that is carried over the Query pane lights the pane, the label
  beside the pointer says `Open “logins” as the query`, and let go there the query is opened as a double click opens it
  (the text, the language, the item picked, the Query row says where the box came from). A schema, a patch, a document and
  a folder are not opened that way; there is no such pane to put a query on with the page of a tool in front or the Query
  pane in a window of its own.
- **A query file dropped on the window**: a file whose name ends `.jq`, `.jsonpath`, `.jmespath` or `.jsonptr` (whatever
  the case, hidden or not) is the query: its text goes in the box, in its language, and what was there is gone; any other
  file is opened as the Source, as it always was, and several go to Merge. The window is not told where in it a file is
  let go (the toolkit under the app drops the position, which X11 sends), so the **name** of the file says where it goes.
  Held over the window and not yet let go, a query file outlines the query box in the colour of a link and the empty Source
  says `Drop to use as the query`. A file that is too big to be a query (over a mebibyte), or not text, is said in the status
  bar and the box is left alone; a file from the workspace's own folder is the item the box came from.

The cases are about all of it from the outside: the real window, the real mouse and keys, and the folder on disk before
and after. What the unit and window tests of the app check (the names that a file may have, the atomic writes, the
store's every refusal) is checked there, in the app repository; what these cases add is that a person can do it.

## How the cases are written

- **The files are made before the app starts**: `Launch Jsonquery App    workspace=${files}` writes a dictionary of
  `path with / → text` into the workspace of that launch (`resources/workspace_fixture.py`: `STANDARD`, and
  variations of it for what a case is about). `STANDARD` is drawn, with the pane open, as

  | Row | y | Is |
  |---|---|---|
  | 0 | 103 | **Logs** (open) |
  | 1 | 123 | **Errors** (shut: `failures.jq` and its sample are in it) |
  | 2 | 143 | logins (JMESPath) |
  | 3 | 163 | **Services** (open) |
  | 4 | 183 | orders (a schema, with a sample) |
  | 5 | 203 | update (a patch) |
  | 6 | 223 | scratch (a jq query) |

  (Rows are 20 high from y = 93; a case clicks a row by its number, `${ROW_...}` in `resources/workspace.resource`.
  The names are chosen so that OCR reads them: `bump` was read as `burnp`, `update` as `uocate` by the flattened reading
  below, and the sorting puts `orders` before `update`, `.patch.json` before `.schema.json`.)
- **The folder is read from Python**, not from the screen: `Workspace Files`, `Workspace File Should Be`,
  `Workspace Item` (the index's entry: `id`, `sha256`, `bytes`, `sample`), `Workspace Index`, `Files In Folder` and
  `Index Of Folder` (an export), and what another program does to it behind the app's back: `Write Workspace File`,
  `Move Workspace File`, `Delete Workspace File`, `Link Workspace Path`. So "the item was moved" means the file is
  there and not here, with the id and SHA-256 it had.
- **The mouse is real**: a drag is `Mouse Down At`, `Move Mouse Slowly To` (over half a second, in steps: a jump is not
  reliably seen as a drag) and `Mouse Up`; a click that is not quite still is `Click With Wobble`. What is lit while a
  row is carried is read in pixels (the bright border, `192, 222, 255`), and what is said beside the pointer by OCR.
- **A file is dropped for real**: `Drop Files On Window` plays the file manager through the X11 drag-and-drop protocol
  (`resources/xdnd.py`), and `Start Hovering Files` holds it over the window without letting go (what the window shows
  while a file is carried). The files are made in a folder of their own by the case. What is not delivered is not a case:
  a file that is gone when it is let go is dropped by the toolkit, so the window never hears of it (TC-WSP-261).
- **An icon is read as a picture**: `Icon Should Look Like` takes the pixels of the region where an icon is drawn and
  compares them with rows of `X` (ink), `.` (no ink) and `?` (either: the corner pixels that a rounded shape shares with
  the ground, which the threshold decides), the two pixels round it having to be clear. The pictures are in
  `resources/workspace.resource` (`@{SIDE_PANEL}`, `@{NEW_FOLDER}`), and what is read as ink is a channel over a threshold
  (bright: 150, dim: 90, in the light theme dark ink under 200): the bright button has ink over 150 (180), and the dim one has none as bright as 135 (127; the text of the app is 140).
- **Points and regions** are those of the 1200×800 window, Dark theme, with the pane open
  (`resources/workspace.resource`): the main view is 256 to the right of where it is with no pane (the query box at
  x 264–1192). With the Tools docked the pane is under the row of tabs and the library moves it down with the rest;
  what the window anchors by itself does not move, and `resources/docked_main.py` says it (`WS_FORM_DY`, the height of
  the list). The status bar is at the foot of the window and is not moved: the pane's button is at x 8–31, and the regions
  that read what the bar says begin at x 36, after it (`@{STATUS_BAR}`, `@{WS_STATUS_LINE}`, the docked profiles').
- **The windows of the pane** (Save, New folder, Export, Import, Delete) are put at the top centre of the window, so a
  case says where a point of one is by `Form Y`; a window is told to the keywords by `Set Form Kind` so that OCR is
  asked about a region as tight as the window.

### What OCR reads here, and what it does not

- **The list is read as a page**, as it is, and only then with the tinted backgrounds flattened
  (`Region Should Show Text`): read as a page it gets 32 of 32 names right, the flattened reading garbles half of them
  (`Caily`, `sare oles`), but a **picked row** (the selection's blue under the text) is read badly as a page and well
  flattened.
- **Small grey text is not read**: the line under the title, the counts, the details of a folder, the notice under the
  list (`Copied as “scratch (2)”`) come back with a letter wrong (`Sitems`, `[S items`, `scratch {2)`) or not at all. A
  case asks for them with a regular expression that says which letters may be wrong (`[5S] items`), or sees that
  something is drawn there (`Get Ink Bounds`), and the layout tests of the app read the words.
- **A button's label is read badly**, among the lines of a window, by every setting: the buttons of a window are found by
  their **fill** (the row of grey boxes at its foot, `60, 60, 60`, or `43, 43, 43` while the button cannot be pressed:
  `Get Lowest Color Segments`, `Press Primary Button`, `Press Cancel Button`) and not by what they say. A band is
  scanned a row below its top: through the middle of a button the label breaks the fill into pieces. The label of a
  button that sits alone at the right of a field (`Choose folder…`) is read when the crop is tight and not in a window, so
  the case clicks its place.
- **The title of a window goes dim** while the window is not the one with the focus (after Enter in a box that did
  nothing), and a dim title is not read: a window is told by a line of its own (`new folder in it`, `To the folder`,
  `From the folder`, `cannot be undone`).
- **A box that the query came from keeps its name**: the Name box of the Save window opens with the name of the item
  the query box came from, so a case selects all (Ctrl+A) before it types.
- **Colours are read at a point that is not on a glyph**: a picked row is `13, 59, 77` (not `27, 27, 27`, nor the lit
  `16, 53, 67` with its bright border), the picked chip `0, 92, 128`, the tag of a jq query `31, 53, 85`, JMESPath
  `74, 48, 18`, a schema `23, 72, 75`, a patch `82, 32, 47`, a document `56, 56, 56`.

## Cases

### The pane: the button in the status bar, the strip, the list, the filter and the chips, what is picked (`suites/workspace/workspace_pane.robot`, 39 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-001 | The Workspace Is Not There Until It Is Asked For | P1 |
| TC-WSP-002 | The Button In The Status Bar Shows The Pane And Hides It Again | P1 |
| TC-WSP-003 | The Button Is A Window With Its Left Column Filled, Dim While The Pane Is Not Shown | P1 |
| TC-WSP-004 | The Button That Makes A Folder Is A Folder With A Plus In It | P1 |
| TC-WSP-005 | A Folder In The List Is The Same Plain Folder Whether It Is Open Or Shut | P2 |
| TC-WSP-006 | The List Has The Top Folders Open And The Rest Shut | P1 |
| TC-WSP-007 | A Click On A Folder Opens It And A Click On It Again Shuts It | P1 |
| TC-WSP-008 | A Click Picks A Row And The Details Under The List Say What It Is | P1 |
| TC-WSP-009 | What A Folder Holds Is Said Under The List When It Is Picked | P2 |
| TC-WSP-010 | What Is Typed In The Filter Narrows The List By Name | P1 |
| TC-WSP-011 | The Filter Looks At The Name Of The Folder As Well As The Name Of The Item | P2 |
| TC-WSP-012 | The Filter Does Not Mind The Case | P2 |
| TC-WSP-013 | A Filter That Matches Nothing Says So And Shows Nothing | P2 |
| TC-WSP-014 | The Chips Narrow The List To One Sort Of Item | P1 |
| TC-WSP-015 | The Docs Chip Shows The JSON And NDJSON Files And Not The Other Sorts | P2 |
| TC-WSP-016 | A Chip That Has Nothing Under It Says So | P3 |
| TC-WSP-017 | A Chip And A Filter Narrow The List Together | P2 |
| TC-WSP-018 | The Fold Button Folds The Pane To A Strip And The Strip's Button Opens It Again | P1 |
| TC-WSP-019 | The Strip Has A Button And The Pane's Icon, And The Window Takes The Room | P2 |
| TC-WSP-020 | The Menu Has An Item That Hides The Workspace | P1 |
| TC-WSP-021 | How Much Of The Pane Is Shown Is Kept | P1 |
| TC-WSP-022 | The Pane Is As Wide As It Was Dragged To And That Is Kept | P2 |
| TC-WSP-023 | The Pane Cannot Be Made Narrower Than A Least Width | P3 |
| TC-WSP-024 | In A Window Too Narrow For It Only The Strip Is Shown | P2 |
| TC-WSP-025 | A Workspace With Nothing In It Says So | P2 |
| TC-WSP-026 | A Folder That Was Chosen And Is Gone Is Said And Is Not Made Again | P2 |
| TC-WSP-027 | Use The Usual One Goes Back To The Usual Workspace | P2 |
| TC-WSP-028 | The Line Under The Title Says Where The Workspace Is And How Much Is In It | P2 |
| TC-WSP-029 | Every Sort Of Item Has Its Own Tag | P1 |
| TC-WSP-030 | What Is Not An Item Is Not Shown | P1 |
| TC-WSP-031 | A Row That Has A Sample Has A Paperclip And Its Tag Is Moved Over For It | P2 |
| TC-WSP-032 | Folders Come Before Items And Every One Is In Alphabetical Order | P2 |
| TC-WSP-033 | A List Longer Than The Pane Scrolls | P2 |
| TC-WSP-034 | The Arrow Of A Folder Points Right When It Is Shut And Down When It Is Open | P2 |
| TC-WSP-035 | The Button That Folds The Pane Points Left And The One That Opens It Points Right | P2 |
| TC-WSP-036 | The Three Dots Of The Menu Button Are One Over The Other | P3 |
| TC-WSP-037 | What Is In A Folder Is Indented Under It And The Names Line Up | P2 |
| TC-WSP-038 | A Folder Says How Many Items Are In It At The Right Of Its Row | P3 |
| TC-WSP-039 | The Details Show The First Lines Of What The Item Holds | P2 |

### The button at the left end of the status bar, and the bar around it (`suites/workspace/workspace_statusbar.robot`, 5 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-243 | The Button Is The First Thing At The Left End Of The Status Bar And The Text Begins After It | P1 |
| TC-WSP-244 | The Button Is Where It Is Whether The Pane Is Shown, Folded Or Hidden | P1 |
| TC-WSP-245 | Held Still Under The Pointer The Button Says What It Is And What A Click Does | P2 |
| TC-WSP-246 | A Message Too Long For One Line Wraps Beside The Button And Leaves It At The Left End | P1 |
| TC-WSP-247 | The Buttons At The Right End Are Where They Were Before There Was A Pane | P1 |

### An item: opening it, the menu of a row, rename, copy, delete (`suites/workspace/workspace_items.robot`, 33 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-040 | A Double Click On A Query Opens It In The Query Box In Its Language | P1 |
| TC-WSP-041 | A Query That Ends .jmespath Is Opened As JMESPath | P1 |
| TC-WSP-042 | A JSONPath Query And A JSON Pointer Query Are Opened In Their Own Language | P2 |
| TC-WSP-043 | The Open Button Under The List Opens The Item That Is Picked | P1 |
| TC-WSP-044 | A Query That Was Changed Since It Was Opened Is Marked | P2 |
| TC-WSP-096 | A Click Only Picks: What Is In The Query Box Stays Until Something Is Opened | P1 |
| TC-WSP-045 | Open With Sample Opens The Sample As The Source And Runs The Query | P1 |
| TC-WSP-046 | A Query With No Sample Has No Button For One | P2 |
| TC-WSP-047 | A Document Is Opened As The Source | P1 |
| TC-WSP-048 | The Button Under The List Opens A Document As The Source | P2 |
| TC-WSP-049 | The Menu Of An Item Has What Can Be Done With It | P1 |
| TC-WSP-050 | An Item That Has A Sample Has One More Item In Its Menu | P2 |
| TC-WSP-051 | The Menu Of A Folder Has What Can Be Done With A Folder | P1 |
| TC-WSP-052 | A Right Click Picks The Row It Is On | P2 |
| TC-WSP-053 | Open In The Menu Opens The Query | P2 |
| TC-WSP-054 | Rename In The Menu Gives An Item Another Name And Keeps Its Id | P1 |
| TC-WSP-055 | Renaming An Item Takes Its Sample With It | P2 |
| TC-WSP-056 | A Name That Is Typed And Then Escape Is Not A Rename | P2 |
| TC-WSP-057 | A Name That Is Taken Is Said And The Item Is Not Renamed | P1 |
| TC-WSP-058 | A Name That A File Cannot Have Is Said And The Item Is Not Renamed | P2 |
| TC-WSP-059 | A Folder Is Renamed And Everything In It Keeps Its Id | P1 |
| TC-WSP-060 | Duplicate Makes A Copy With Its Sample And An Id Of Its Own | P1 |
| TC-WSP-061 | Duplicate Twice Makes Two Copies With Numbers | P3 |
| TC-WSP-062 | Copy Text Puts The Text Of The Item On The Clipboard | P1 |
| TC-WSP-063 | Show In The File Manager Opens The Folder The Item Is In | P2 |
| TC-WSP-064 | Show In The File Manager On A Folder Opens That Folder | P2 |
| TC-WSP-065 | Delete Asks Before It Deletes And Cancel Keeps The Item | P1 |
| TC-WSP-066 | Escape Closes The Question And Keeps The Item | P2 |
| TC-WSP-067 | Delete Deletes The File And The Id The Workspace Kept Of It | P1 |
| TC-WSP-068 | Deleting An Item Deletes Its Sample Too | P1 |
| TC-WSP-069 | Deleting A Folder Deletes What The Workspace Put In It | P1 |
| TC-WSP-070 | A Folder That Has A File That Is Not The Workspace's Keeps It | P1 |
| TC-WSP-168 | A Message Under The List Goes After A Few Seconds | P3 |

### Saving what is in the query box (`suites/workspace/workspace_save.robot`, 25 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-071 | The Pane's Save Button Opens The Window That Saves What Is In The Query Box | P1 |
| TC-WSP-072 | Nothing Is Saved Until There Is A Name | P1 |
| TC-WSP-073 | The Window Says What The File Will Be Called As The Name Is Typed | P2 |
| TC-WSP-074 | Enter In The Name Box Saves The Query Under That Name | P1 |
| TC-WSP-075 | What Is Kept Of The Query Is An Id And A SHA-256 Of What It Holds | P1 |
| TC-WSP-076 | The Save Button Of The Window Saves Too | P2 |
| TC-WSP-077 | Escape And Cancel And The Cross Close The Window And Save Nothing | P1 |
| TC-WSP-078 | The Save Button Beside Run Opens The Same Window | P1 |
| TC-WSP-079 | The Query Can Be Saved In A Folder That Is Chosen In The Window | P1 |
| TC-WSP-080 | A New Folder Is Made For The Query By Typing Its Name | P1 |
| TC-WSP-081 | A Folder Is Chosen And A New One Is Made In It | P2 |
| TC-WSP-082 | A Name That A File Cannot Have Is Said In Red And Nothing Is Saved | P1 |
| TC-WSP-083 | A Name That Is Taken Asks To Replace And Replacing Keeps The Id | P1 |
| TC-WSP-084 | A Query That Came From The Workspace Is Offered Back Under Its Own Name | P1 |
| TC-WSP-085 | The Language The Query Is In Gives The File Its End | P1 |
| TC-WSP-086 | Nothing Can Be Saved From An Empty Query Box | P2 |
| TC-WSP-087 | The Source Can Be Kept As The Sample Of The Query | P1 |
| TC-WSP-088 | The Tick For A Sample Is Dim When There Is No Source | P2 |
| TC-WSP-089 | Without The Tick No Sample Is Kept | P2 |
| TC-WSP-090 | The Source Is Saved As A Document Of The Workspace | P1 |
| TC-WSP-091 | The Folder That Is Picked In The List Is The One The Window Offers | P2 |
| TC-WSP-092 | An Item That Is Picked Offers The Folder It Is In | P2 |
| TC-WSP-093 | After A Query Is Saved The Box Came From It And The Window Offers Its Name Again | P3 |
| TC-WSP-094 | A Query Saved With The Pane Folded Is In The Workspace All The Same | P2 |
| TC-WSP-095 | The Menu Of A Folder Saves The Query In That Folder | P2 |

### Moving: dragging a row, and Move to (`suites/workspace/workspace_move.robot`, 30 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-100 | A Row Dragged Onto A Folder Goes Into It And Is The Same Item Afterwards | P1 |
| TC-WSP-101 | While A Row Is Carried The Folder It Would Go Into Is Lit And The Label Says Where | P1 |
| TC-WSP-102 | A Row Takes Its Sample With It | P1 |
| TC-WSP-103 | A Folder Dragged Onto A Folder Takes Everything In It With The Ids Unchanged | P1 |
| TC-WSP-104 | A Row Put Down On An Item Goes Into The Folder That Item Is In | P1 |
| TC-WSP-105 | A Row Put Down On The Empty Part Of The List Goes To The Top | P1 |
| TC-WSP-106 | The Empty Part Of The List Is Lit As The Place Where A Row Would Go To The Top | P2 |
| TC-WSP-107 | A Row Put Down On The Folder It Is In Stays Where It Is | P1 |
| TC-WSP-108 | A Row That Is Not Over Anything It Can Go Into Is Not Lit | P2 |
| TC-WSP-109 | A Folder Is Not Put Into A Folder In It | P1 |
| TC-WSP-110 | A Name That Is Taken In The Folder Is Said And Nothing Moves | P1 |
| TC-WSP-111 | A Folder Of The Same Name In The Folder Is Said And Nothing Moves | P2 |
| TC-WSP-112 | Escape Puts The Row Back | P1 |
| TC-WSP-113 | A Row Let Go Outside The List Stays Where It Is | P1 |
| TC-WSP-114 | A Press That Moves A Little Is A Click And Carries Nothing | P2 |
| TC-WSP-115 | A Shut Folder That A Row Rests On Opens After A Moment | P2 |
| TC-WSP-116 | A Shut Folder That A Row Only Passes Over Does Not Open | P2 |
| TC-WSP-127 | A Folder Is Not Put Into Itself | P1 |
| TC-WSP-128 | The Label Says The Way To A Folder That Is In Another | P2 |
| TC-WSP-129 | A Row Held Below The List Does Not Scroll It | P2 |
| TC-WSP-117 | The List Scrolls While A Row Is Held Near Its Foot | P2 |
| TC-WSP-118 | An Item That Was Opened Is Still Said To Be Where The Box Came From After It Is Moved | P2 |
| TC-WSP-119 | A Folder That Is Open Is Open Where It Is Put Down | P2 |
| TC-WSP-120 | The Menu's Move To Lists The Top And The Folders | P1 |
| TC-WSP-121 | Move To In The Menu Moves The Item Into The Folder | P1 |
| TC-WSP-122 | Move To The Top In The Menu Takes An Item Out Of Its Folder | P2 |
| TC-WSP-123 | Move To In The Menu Of A Folder Moves The Folder | P2 |
| TC-WSP-124 | The Folder An Item Is In Cannot Be Chosen In Its Move To | P3 |
| TC-WSP-125 | A Folder Cannot Be Moved Into Itself In The Menu | P3 |
| TC-WSP-126 | A Row Put Down On A Shut Folder Goes In And The Folder Opens To Show It | P1 |

### A query carried onto the Query pane (`suites/workspace/workspace_carry.robot`, 9 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-271 | A Query Carried Onto The Query Pane Lights It, Says What It Opens As, And Is Opened When It Is Let Go | P1 |
| TC-WSP-272 | Each Language Is Opened In Its Own Engine, As A Double Click Opens It | P2 |
| TC-WSP-273 | A Schema Or A Patch Carried Onto The Query Pane Is Not Lit And Is Not Opened | P1 |
| TC-WSP-274 | A Folder Carried Onto The Query Pane Is Not Lit And Is Not Opened | P2 |
| TC-WSP-275 | A Document Carried Onto The Query Pane Is Not Lit And Is Not Opened | P2 |
| TC-WSP-276 | Escape While A Query Is Over The Query Pane Opens Nothing | P1 |
| TC-WSP-277 | A Query Taken Over The Query Pane And Back Over A Folder Is Moved As Before | P1 |
| TC-WSP-278 | A Press That Is Not Carried Anywhere Opens Nothing | P3 |
| TC-WSP-290 | A Query That Has A Sample Is Opened Without It When It Is Carried Onto The Query Pane | P2 |

### A file dropped on the window: the query file (`suites/workspace/workspace_drop.robot`, 25 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-249 | A File From Anywhere Else Is Nobody's And The Row Forgets The Item It Had | P2 |
| TC-WSP-250 | A File That Ends .jq Dropped On The Window Is A jq Query In The Query Box | P1 |
| TC-WSP-251 | A File That Ends .jsonpath Is A JSONPath Query, .jmespath A JMESPath Query And .jsonptr A JSON Pointer | P1 |
| TC-WSP-252 | The End Of The Name Is All That Says It Is A Query, Whatever Its Case Or Where It Is Hidden | P2 |
| TC-WSP-253 | A Document Is Opened As The Source And The Query Box Is Left Alone | P1 |
| TC-WSP-254 | A Text File Is Not A Query Whatever Is In It | P2 |
| TC-WSP-255 | A Schema Or A Patch Is A Document Here, Not A Query | P2 |
| TC-WSP-256 | A Query File Takes The Place Of What Was In The Box | P1 |
| TC-WSP-257 | A Byte-Order Mark At The Start Of The File Is Not In The Box | P2 |
| TC-WSP-258 | A Query File Of More Than A Mebibyte Is Said To Be Too Big And The Box Is Left Alone | P1 |
| TC-WSP-260 | A Query File That Is Not Text Is Said Not To Be Readable And The Box Is Left Alone | P2 |
| TC-WSP-261 | A File That Is Gone When It Is Let Go Is Not Seen At All | P3 |
| TC-WSP-262 | A Good Query File After One That Could Not Be Used Is Used And Takes The Message Away | P2 |
| TC-WSP-263 | A Dropped Query File Is Not Run And Does Not Touch The Source, And Run Uses It | P1 |
| TC-WSP-264 | Several Files Go To Merge, Query Files Too, And The Query Box Is Left Alone | P1 |
| TC-WSP-265 | A Query File Held Over The Window Outlines The Query Box And The Empty Source Says What It Would Be | P1 |
| TC-WSP-266 | A Document Held Over The Window Says Drop To Open And Outlines Nothing | P1 |
| TC-WSP-267 | The Outline And The Words Go When The File Is Taken Away | P1 |
| TC-WSP-268 | Several Files Held Over The Window Are Not Outlined As A Query | P2 |
| TC-WSP-269 | With A Document Loaded A Query File Held Over The Window Still Outlines The Box | P2 |
| TC-WSP-270 | A File Let Go From The Workspace's Own Folder Is The Item The Box Came From | P1 |
| TC-WSP-287 | A Query File With Windows Line Ends Is Put In The Box As It Is And Runs | P2 |
| TC-WSP-288 | A Name With Spaces, Brackets And Accents Is A Query All The Same | P2 |
| TC-WSP-289 | A File From A Workspace That Is Reached Through A Link Is The Item All The Same | P2 |
| TC-WSP-291 | With A Document Loaded A Good Query File Takes The Message Away And The Document Stays | P2 |

### The windows of the pane, and the other folder (`suites/workspace/workspace_transfer.robot`, 37 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-130 | The Folder Button Opens The Window That Makes A Folder | P1 |
| TC-WSP-131 | A Folder Is Made By Typing Its Name And Enter And It Is Open And Picked | P1 |
| TC-WSP-132 | The Make It Button Makes The Folder | P2 |
| TC-WSP-133 | A Folder Is Made Inside The Folder That Is Picked | P1 |
| TC-WSP-134 | The Menu Of The Three Dots Makes A Folder Too | P2 |
| TC-WSP-135 | The Menu Of A Folder Makes A Folder Inside It | P2 |
| TC-WSP-136 | A Folder Is Made Inside A Folder That Is Chosen In The Window | P2 |
| TC-WSP-137 | A Name That A Folder Cannot Have Is Said And No Folder Is Made | P1 |
| TC-WSP-138 | A Folder That Is There Already Is Said And Nothing Is Made | P2 |
| TC-WSP-139 | Escape And Cancel Make Nothing | P2 |
| TC-WSP-140 | The Export Window Says What Is Exported And Where To | P1 |
| TC-WSP-141 | Export Makes A Copy Of The Workspace With The Ids It Kept | P1 |
| TC-WSP-142 | Without The Samples Only The Items Are Copied | P1 |
| TC-WSP-143 | A Folder Is Exported Alone | P1 |
| TC-WSP-144 | The Menu Of A Folder Exports That Folder | P2 |
| TC-WSP-145 | A Folder That Has Something In It Is Not Exported To | P1 |
| TC-WSP-146 | The Workspace Is Not Exported Into Itself | P1 |
| TC-WSP-147 | Cancel Exports Nothing | P3 |
| TC-WSP-150 | The Import Window Asks For A Folder And Where To Put What Is In It | P1 |
| TC-WSP-151 | A Folder That Is Typed Is Looked At When The Box Is Left | P1 |
| TC-WSP-152 | Import Brings The Items In A New Folder Named For The Folder They Came In | P1 |
| TC-WSP-153 | The Ids That Were Kept In The Folder Are The Ids Of The Items After The Import | P1 |
| TC-WSP-154 | The Name Of The New Folder Can Be Typed | P2 |
| TC-WSP-155 | A Folder That Is Not One Is Said In Red And Nothing Is Imported | P1 |
| TC-WSP-156 | A Folder With Nothing In It That The Workspace Can Use Is Said | P2 |
| TC-WSP-157 | Import Among What Is In A Folder Keeps Both When A Name Is Taken | P1 |
| TC-WSP-158 | Import With Replace Puts The New Text Over The Old | P1 |
| TC-WSP-159 | Import With Leave Out Keeps What Is There | P2 |
| TC-WSP-160 | An Item That Is The Same As The One There Is Not Brought In Again | P2 |
| TC-WSP-161 | Choose Folder Fills In The Folder From The File Dialog | P2 |
| TC-WSP-162 | Another Folder Can Be The Workspace | P1 |
| TC-WSP-163 | What Is Saved Goes To The Folder That Was Chosen | P2 |
| TC-WSP-164 | The Usual Workspace Comes Back From The Menu | P2 |
| TC-WSP-165 | Show It In The File Manager Opens The Folder Of The Workspace | P2 |
| TC-WSP-166 | Read It Again Shows What Another Program Did To The Folder | P1 |
| TC-WSP-148 | With A Folder Picked The Export Window Still Offers The Whole Workspace First | P2 |
| TC-WSP-167 | The Menu Does Not Offer The Usual Workspace While It Is The One In Use | P2 |

### The Tools: Validate and Patch (`suites/workspace/workspace_tools.robot`, 15 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-170 | Save Schema Saves What Is In The Schema Box As A Schema Of The Workspace | P1 |
| TC-WSP-183 | Save Schema Offers The Schema When The Patch Box Of The Other Page Has Something Too | P2 |
| TC-WSP-184 | Save Patch Offers The Patch When The Schema Box Of The Other Page Has Something Too | P2 |
| TC-WSP-171 | The Document Box Of Validate Can Be Kept As The Sample Of The Schema | P1 |
| TC-WSP-172 | Save Schema Does Nothing While The Schema Box Is Empty | P2 |
| TC-WSP-173 | Saved Schemas Narrows The List To The Schemas | P1 |
| TC-WSP-174 | Saved Schemas Shows The Pane When It Was Hidden | P1 |
| TC-WSP-175 | Use As Schema Puts The Schema In The Schema Box Of Validate | P1 |
| TC-WSP-176 | Use As Schema With Its Sample Puts The Sample In The Document Box And Checks It | P1 |
| TC-WSP-177 | The Button Under The List Does The Same As The Menu | P2 |
| TC-WSP-178 | Save Patch Saves What Is In The Patch Box As A Patch Of The Workspace | P1 |
| TC-WSP-179 | The Document Box Of Patch Can Be Kept As The Sample Of The Patch | P2 |
| TC-WSP-180 | Saved Patches Narrows The List To The Patches | P1 |
| TC-WSP-181 | Use As Patch Puts The Patch In The Patch Box Of Patch | P1 |
| TC-WSP-182 | A Document Item Is Opened As The Source Of The Main Window | P2 |

### What is kept: the ids, the SHA-256s, the folder and what is done to it (`suites/workspace/workspace_files.robot`, 25 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-190 | The First Read Of A Workspace That Has Files Gives Every Item An Id And A SHA-256 | P1 |
| TC-WSP-191 | Nothing Is Made For A Workspace That Has Nothing In It | P1 |
| TC-WSP-192 | What Is Not An Item Has No Id | P2 |
| TC-WSP-193 | Another Program Changes An Item And It Keeps Its Id With A New SHA-256 | P1 |
| TC-WSP-194 | Another Program Renames An Item And It Is Found Again By What It Holds | P1 |
| TC-WSP-195 | Another Program Moves An Item To Another Folder And It Keeps Its Id | P2 |
| TC-WSP-196 | An Item That Another Program Deleted Is Taken Out Of The Index | P2 |
| TC-WSP-197 | An Item That Another Program Added Gets An Id | P2 |
| TC-WSP-198 | Two Items That Hold The Same Text Have Ids Of Their Own | P2 |
| TC-WSP-199 | The Ids Are The Same When The App Is Started Again | P1 |
| TC-WSP-200 | A Damaged Index Is Set Aside And Made Again From The Folder | P2 |
| TC-WSP-201 | A Link Is Not Followed | P1 |
| TC-WSP-202 | A Name That Differs From One That Is There Only By Its Case Is The Same Name | P2 |
| TC-WSP-203 | Items That Share A Name Share The Sample | P1 |
| TC-WSP-204 | A Save Leaves Nothing Of Its Own Behind | P2 |
| TC-WSP-205 | What Another Program Did Is Seen When The Window Gets The Focus Back | P2 |
| TC-WSP-206 | The Index Is Written Again Only When It Changes | P3 |
| TC-WSP-207 | A Folder That Cannot Be Written To Says So And Saves Nothing | P2 |
| TC-WSP-208 | An Item That Is Too Big For The Box Is Said And The Box Is Not Touched | P2 |
| TC-WSP-209 | An Item That Is Not Text Is Said When It Is Opened | P2 |
| TC-WSP-213 | An Item With A Byte-Order Mark Is Opened Without It | P3 |
| TC-WSP-214 | A Workspace That Is A Link To Another Folder Is Used | P2 |
| TC-WSP-215 | A Name Longer Than The Row Is Cut Short And The Tag Stays | P3 |
| TC-WSP-216 | A Name With Letters Of Other Languages Is Kept As It Is | P3 |
| TC-WSP-217 | Three Thousand Items Are Read And Listed | P3 |

### The pane in other states of the window (`suites/workspace/workspace_variants.robot`, 21 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-220 | In The Light Theme A Picked Row Has The Colour Of A Selection There | P2 |
| TC-WSP-221 | In The Light Theme Every Sort Of Item Has Its Light Tag | P2 |
| TC-WSP-222 | In The Light Theme The Icons Are In Dark Ink | P2 |
| TC-WSP-223 | In The Light Theme A Row That Is Carried Lights The Folder With The Light Border | P2 |
| TC-WSP-285 | In The Light Theme A Query Carried Onto The Query Pane Lights It With The Light Border | P3 |
| TC-WSP-286 | In The Light Theme A Query File Held Over The Window Outlines The Query Box In The Link Colour Of That Theme | P3 |
| TC-WSP-224 | In The Light Theme A Query Is Saved From The Window | P3 |
| TC-WSP-225 | A Shorter Window Has A Shorter List And The Details Stay At Its Foot | P2 |
| TC-WSP-226 | A Pane That Was Made Wider Has Rows As Wide | P2 |
| TC-WSP-227 | The Pane Is At Most Half As Wide As The Window | P3 |
| TC-WSP-228 | A Setting That Says Nothing The App Knows Shows No Pane | P2 |
| TC-WSP-229 | A Width In The Settings Is Brought Into What The Pane Can Be | P3 |
| TC-WSP-230 | A Workspace Under The Home Is Written With A Tilde | P3 |
| TC-WSP-231 | A Row Under The Pointer Is Lit Grey | P3 |
| TC-WSP-232 | In The Light Theme A Row Under The Pointer Is Lit Light Grey | P3 |
| TC-WSP-233 | Folders Nested Eight Deep Are Each Indented And The Item At The Bottom Still Has Its Tag | P3 |
| TC-WSP-234 | A Taller Window Has A Taller List And The Details Stay At Its Foot | P2 |
| TC-WSP-235 | A Wider Window Gives The Room To What Is Beside The Pane And Not To The Pane | P3 |
| TC-WSP-236 | A Click On The Strip's Button In A Window Too Narrow For The Pane Does Not Open It For Later | P3 |
| TC-WSP-237 | The Theme Button Changes The Pane Too While The App Runs | P2 |
| TC-WSP-238 | The Pane Is Shown In A Window Of 900 Points And Only The Strip In One Of 899 | P3 |

### The pane with another pane of the window in a window of its own (`suites/workspace/workspace_panes.robot`, 5 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-240 | The Button Beside Run Saves The Query From The Pane In Its Own Window | P2 |
| TC-WSP-241 | An Item Opened From The Pane Goes To The Query Pane That Is In Its Own Window | P2 |
| TC-WSP-242 | A Document Opened From The Pane Goes To The Source Pane That Is In Its Own Window | P2 |
| TC-WSP-283 | A Query File Dropped On The Query Pane That Is In Its Own Window Goes In The Box There | P2 |
| TC-WSP-284 | A Query Carried Out Of The List Opens Nothing While The Query Pane Is In A Window Of Its Own | P2 |

### With the Tools docked (`suites/workspace/workspace_docked.robot`, 7 cases)

| ID | Title | Priority |
|---|---|---|
| TC-WSP-210 | With The Tools Docked The Pane Is Under The Row Of Tabs | P1 |
| TC-WSP-211 | The Chips Follow The Page That Is In Front | P1 |
| TC-WSP-212 | A Chip That Was Picked By Hand Stays While The Same Page Is In Front | P2 |
| TC-WSP-279 | With The Page Of A Tool In Front The Status Bar Has The Button First And The Text Of The Page After It | P1 |
| TC-WSP-280 | With The Page Of A Tool In Front A Query File Dropped On The Window Is The Page's And Not The Query Box's | P1 |
| TC-WSP-281 | With The Page Of A Tool In Front A Query Carried Out Of The List Has No Query Pane To Go On | P1 |
| TC-WSP-282 | A Query Opened From The List While The Page Of A Tool Is In Front Brings The Json Query Tab Forward | P1 |

## Run both ways

The suites run with the Tools in a window of their own (`./run_parallel.sh`) and with them docked
(`./run_docked.sh`, the main-view pass: `resources/docked_main.py` has what the move does not make right). The
cases that need the **Tools window** — `Save schema…` on Validate, `Use as schema` and the like, which bring a window
forward, and the files that go to Merge — are tagged `window-only` and run in a window of their own only;
`workspace_docked.robot` has the cases that are about the docked Tools and the pane (the pane is under the row of tabs;
the chips follow the page in front; with a page in front there is no Query pane, a dropped file is the page's, and the
button of the status bar is first with the page's text after it). `undocked-only` is TC-WSP-247, which reads the right end
of the status bar as it is without the 🗗.

**2026-10-21, the debug build.** The pane adds a button to the status bar, which several older cases read, so the **whole
suite** was run again in both ways, and the suites of the pane by themselves after the last case was changed:

| Run | Cases | Passed |
|---|---|---|
| `./run_parallel.sh -j 6`, every suite, the Tools in a window (the second full run) | 990 | 987 |
| `./run_docked.sh -j 6`, the tools pass | 164 | 164 |
| `./run_docked.sh -j 6`, the main-view pass | 739 | 739 |
| `./run_parallel.sh -j 4 --include workspace`, after the last case was changed | 229 | 229 |
| `./run_docked.sh -j 4 main --include workspace` (the other 15 are `window-only`) | 214 | 214 |

What failed on the way, and what was done:

- **The first full run, 982 of 988.** TC-WEB-001, TC-DOCK-006, 008 and 009 had assumed that nothing is left of the ⚙ (or of
  the 🗗) in the status bar, where the folder button is now: they say where it is (`resources/docked.resource`:
  `SB_FOLDER_X` 1094, and 1066 with the 🗗 that pushes it left). TC-TWIN-007 and TC-DIF-014 failed on a slow lane and passed
  alone.
- **The first docked tools pass, 160 of 164.** TC-MRG-001, TC-DIF-001, 004 and 014 look at the line of the status bar that
  has to be blank, which ended at x = 770 in the window of 900; the folder button is at 754 to 778. It ends at 745 now
  (`resources/docked_tools.py`), and the four passed.
- **The second full run, 987 of 990.** TC-WSP-097 (Ctrl+Z after an open: now a test of the app, see "What came out of
  the cases about the cases"), TC-OPEN-003 (OCR read `vaLlid. json`) and TC-TDLG-002 (a file dialog that was not answered
  in time) failed on a lane that was busy, and the last two passed alone. The suite had 989 cases without TC-WSP-097.

No older case needed a change for any other reason, and the app had no fault from the new button: the older cases that
changed are the ones about the status bar's buttons and the line beside them.

**The second round of the day: the pane's pictures, the button at the left end of the status bar, the query files dropped
on the window, the queries carried onto the Query pane** (the user had looked at the window and said it was right). 46 cases
are new (TC-WSP-243 to 247, 249 to 258 and 260 to 290: three new files, `workspace_statusbar.robot`,
`workspace_drop.robot` and `workspace_carry.robot`, and cases in the files of the docked pane, of the panes in windows of
their own and of the other states of the window), nine of the 229 that were there changed, and the suite has 1035 cases.

| Run | Cases | Passed |
|---|---|---|
| `./run_parallel.sh -j 6`, every suite, before the new cases were written (the new button and pictures against the old cases) | 989 | 988 |
| `./run_docked.sh -j 6`, the tools pass | 164 | 164 |
| `./run_docked.sh -j 6`, the main-view pass (with the new cases) | 782 | 780 |
| `./run_parallel.sh -j 6 --include workspace`, with every case in its last form | 275 | 275 |
| `./run_docked.sh -j 6 main --include workspace`, with every case in its last form | 258 | 258 |

What failed on the way, and what was done:

- **The 229 that were there, against the new window: 220.** Nine failed, each for what had changed and nothing else:
  TC-WSP-002, 003, 019, 020 and 021 (the button is at the left end now, and a picture of a window with its left column
  filled and not a folder), TC-WSP-004 and 222 (the button that makes a folder is a folder with a plus left out), TC-WSP-210
  (the same, docked) and TC-WSP-113 (a query let go over the query box is opened now: it is let go over the Results). The
  older cases that read the status bar (TC-WEB-001, TC-DOCK-006, 008, 009) say where the buttons are now, and the regions that
  read what the bar says begin at x 36, after the button (`@{STATUS_BAR}` and the docked profiles').
- **The old suites, 988 of 989**: TC-DIF-026 (the arrows in the gutter of Diff) did not find its text on a busy lane and passed
  twice alone. Nothing in the other suites needed a change for the new button.
- **The new cases, the first time they ran.** The drop cases, 16 of 19: TC-WSP-255 looked for a word that was in a tree that
  was shut, and TC-WSP-261 and 262 dropped a file that is not there, which the toolkit under the app does not hand over at all
  (TC-WSP-261 says that now, and TC-WSP-262 uses a file that is there but is not text). The status-bar cases, 4 of 5:
  TC-WSP-246 measured the button with a probe that took the rule of the bar, then the edge of the Source box, then the
  splitter between two panes (it is white while the pointer is on it). The carried queries, 7 of 8: TC-WSP-271 read
  `asthe query` for `as the query`. The docked, popped-out and light cases passed at once.
- **The main-view pass, docked: 780 of 782.** TC-WSP-246 clicked the button where the bar had grown to, a point that the docked
  profile moves down by the row of tabs and the bar does not (it says where the window has it now), and TC-QRY-031 read
  `'/'` as `'/` once and passed 3 of 3 alone in the same profile.
- **A fault of the app, found by TC-WSP-289** (a file let go from a workspace that is reached through a link is not the item
  it is: "What the cases found", 7): fixed, and the case passes on the app as it is.

**The third round of the night: a good query file takes away the message about a bad one** (the user's answer to the question that the second
round ended with: "yes, a successful drop should clear it"). One line of the app (`use_query_file`), a test of the app that no
longer clears the message by itself before it drops the good file, a second one with a document loaded, TC-WSP-262 now asking
that the status bar does not say any more that the first file could not be read, and one new case, TC-WSP-291 (the same with a
document loaded, which stays): the suite of the pane has 276 cases and the whole suite 1036.

| Run | Cases | Passed |
|---|---|---|
| `./run_parallel.sh -j 6 --include workspaceORdrag_and_drop` (the cases of the pane and the files dropped that are not queries) | 294 | 294 |
| `./run_docked.sh -j 6 main --include workspaceORdrag_and_drop` | 268 | 268 |

The rest of the suite was not run again: the line that was added is in the function that only a query file that is dropped
on the window calls. The tests of the app: 109 + 453 + 823 passed (the one that was changed and the new one fail on the app
as it was), `cargo fmt --check` and `clippy -D warnings` clean for Linux, Windows and macOS. Nothing failed on the way.

## Faults put into the app, one at a time

One thing broken at a time in a scratch copy of the app (the pane and its files, `app.rs`, `workspace/*.rs`), built, and
the cases that should see it run on that build: the fault is **killed** when one of them fails. 197 faults, **all 197 are
killed**; the cases that failed are named for each (where there are several, each of them failed). The first run killed
129 of 146: the 15 that survived and the 2 that did not compile were each looked at, and what was missing or too weak in
the cases is in "Faults of the cases" below (new cases: TC-WSP-096, 127, 128, 129, 183, 184, 236, 238, and stricter
checks in a dozen more). The faults for the new states of the window (x01 to x06) were made together with the cases that
see them. The table is as of the last run of each fault.

The second round of the day (the pane's button and the button that makes a folder drawn again and the first moved to the
left end of the status bar, the query files dropped on the window, the queries carried onto the Query pane) put in 42 faults
more (q01 to q52) and ran again the 19 older ones that the cases that were changed for it are to kill. 50 of the 52 were
killed at once; the two that were not: **q08**, the strip's icon drawn in the text's colour (140) and not the dim one
(122), got through a check that said "nothing as bright as 150", and a limit of 135, between the two, was added to it; and
**q13**, a change in how the status bar shares its width between the text and the buttons, was taken out again: it is not
a thing of this round (the bar was laid out so before the pane), and a message that is long enough to reach the buttons
runs under them with the fault and without it. **q51** was put in after TC-WSP-289 had found a fault of the app (a file let
go from a workspace that is reached through a link was not its item): the case fails on the app as it was and passes on the
app as it is, and **q52** (a query that is carried is opened with its sample) was put in with TC-WSP-290. **q53** to
**q55** were put in with the owner's answer that a good query file takes away what was said of a bad one (the
message stays, the document is unloaded, the message goes only while no document is loaded: TC-WSP-291 is the only
case that sees the last): all three were killed at once.

The tests of the app, which are faster and see more, were asked the same about the pane: **62 of 62** faults of the
pictures, the dragging, the strip, what a folder keeps open, the message that goes, the least width, the window that
saves and the notices of a delete are killed by them (the cases above see the same from outside, and some of the faults
are seen there only through a second check: f21, a folder that was deleted but stays is still picked, was seen by the
tests of the app first and by TC-WSP-070 after the case was made to look at the row), and **39 of 39** of the second
round (the two new pictures at five scales, the files that are dropped and what they do, the query pane that is carried
onto and what is lit). One of those is not seen from outside: how thick the outline of the Query pane is (1.5 points, which is
a bright pixel and a fainter one). 117 faults of what is under the pane (names, files, ids, the index, the store, export and
import, the settings) were killed by the tests of the app before any case was written, and are not repeated here.

#### The pictures

| Mutant | What is broken | Killed by |
|---|---|---|
| c01 | a folder's arrow points the wrong way | TC-WSP-034 |
| c02 | the fold button points right | TC-WSP-035 |
| c03 | a folder is 11 wide | TC-WSP-005, 222 |
| c04 | a folder has no notch beside its tab | TC-WSP-005, 222 |
| c05 | a folder has no tab | TC-WSP-005, 222 |
| c06 | a folder is 8 high | TC-WSP-005, 222 |
| c07 | the menu has two dots | TC-WSP-036 |
| c08 | the dots are side by side | TC-WSP-036 |
| c09 | a button of the pane is 20 wide | TC-WSP-004 |
| c10 | the body of a folder is an outline | TC-WSP-005, 222 |
| c11 | the strip is cut off at the right | TC-WSP-019, 035 |
| c12 | the strip has no icon of the pane | TC-WSP-019 |
| c13 | the status bar's button is dim while the pane is shown | TC-WSP-003 |
| c14 | the new folder button has the dots | TC-WSP-004 |

#### The pane

| Mutant | What is broken | Killed by |
|---|---|---|
| g01 | Hide the workspace folds it to the strip | TC-WSP-020 |
| g02 | the fold button hides the pane | TC-WSP-018 |
| g03 | the strip's button does not open the pane | TC-WSP-018 |
| g04 | the menu offers the usual workspace when it is in use | TC-WSP-167 |
| g05 | the line under the title counts one too many | TC-WSP-028 |
| g06 | the warning sign is never shown | TC-WSP-201 |
| g07 | a chip does not narrow the list | TC-WSP-014 |
| g08 | Validate in front does not narrow the list to the schemas | TC-WSP-211 |
| g09 | the folder is not read again when the window gets the focus back | TC-WSP-205 |
| g11 | an item that is picked does not offer its folder | TC-WSP-092 |
| g12 | a query is marked changed when it is not | TC-WSP-044 |
| g13 | Save beside Run does not open the window | TC-WSP-078 |
| g14 | the folder in the status bar does nothing | TC-WSP-002 |
| g15 | the pane can be made 100 wide | TC-WSP-023 |
| g15b | the pane can be made 180 wide: a button over the title | TC-WSP-023, 229 |
| g16 | the pane has room in a window of 800 | TC-WSP-024 |
| g17 | the strip's button works where there is no room | TC-WSP-236 |
| g18 | another folder chosen keeps the old workspace | TC-WSP-162 |
| g19 | the sample of a save is not waited for | TC-WSP-087 |
| g20 | Save never opens the window | TC-WSP-071, 078 |
| g22 | a message waits for the next touch of the mouse to go | TC-WSP-168 |
| g21 | a message stays for ever | TC-WSP-168 |

#### The list and its menus

| Mutant | What is broken | Killed by |
|---|---|---|
| h01 | a click opens a folder that is open | TC-WSP-007 |
| h02 | a click on a folder does not open it | TC-WSP-007 |
| h03 | a click does not pick a row | TC-WSP-008 |
| h04 | a double click opens a folder and not an item | TC-WSP-040 |
| h05 | a right click does not pick the row | TC-WSP-052 |
| h06 | the filter minds the case | TC-WSP-012 |
| h07 | the filter does not look at the folder | TC-WSP-011 |
| h08 | a narrowed list has its folders shut | TC-WSP-014, 017 |
| h09 | a folder with none of the sort is shown | TC-WSP-014 |
| h10 | a jq query has the tag of a JMESPath query | TC-WSP-029 |
| h11 | a sample is not marked | TC-WSP-031 |
| h12 | a folder indents by 10 | TC-WSP-037 |
| h13 | a row is 22 high | TC-WSP-008 |
| h14 | a picked row is brighter | TC-WSP-008 |
| h15 | the details do not say where the item is | TC-WSP-008 |
| h16 | the details have no button for the sample | TC-WSP-045 |
| h17 | the buttons of a schema are swapped | TC-WSP-177 |
| h18 | the details show none of the text | TC-WSP-039 |
| h19 | a rename starts with an empty name | TC-WSP-056 |
| h20 | a name that is taken is not said | TC-WSP-057, 058 |
| h21 | the copy is not picked | TC-WSP-060 |
| h22 | a copy says nothing | TC-WSP-060 |
| h23 | Delete asks nothing and does nothing | TC-WSP-065 |
| h24 | Copy text copies the path | TC-WSP-062 |
| h25 | Show in the file manager shows the workspace | TC-WSP-063 |
| h26 | Save the query here does not open the window | TC-WSP-095 |
| h27 | New folder in a folder makes it at the top | TC-WSP-135 |
| h28 | Export this folder exports everything | TC-WSP-144 |
| h29 | Import into a folder imports at the top | TC-WSP-157 |
| h30 | Move to has no top | TC-WSP-120, 122 |
| h31 | a folder may be moved into itself by the menu | TC-WSP-125 |
| h32 | an item may be moved to the folder it is in by the menu | TC-WSP-124 |
| h33 | a patch goes to Validate | TC-WSP-181 |
| h34 | a document is opened from another path | TC-WSP-047 |
| h35 | an empty workspace says something else | TC-WSP-025 |
| h36 | the usual one is not used | TC-WSP-027 |
| h37 | the tags of the light theme are the dark ones | TC-WSP-029, 221 |
| h38 | a row under the pointer is not lit | TC-WSP-231 |
| a09 | an open pane is read as a folded one | TC-WSP-021, 229 |
| a10 | a width that is not one is taken | TC-WSP-229 |
| a11 | the pane can be nine tenths of the window | TC-WSP-227 |
| a12 | the home is written with a hash | TC-WSP-230 |

#### What is carried

| Mutant | What is broken | Killed by |
|---|---|---|
| d01 | a row may be put down on the folder it is in | TC-WSP-107, 108 |
| d02 | a folder may be put into one in it | TC-WSP-109 |
| d03 | a folder may be put into itself | TC-WSP-127 |
| d04 | the way to a folder is said without slashes | TC-WSP-128 |
| d05 | the label does not say a row goes to the top | TC-WSP-106 |
| d06 | the notice does not say it went to the top | TC-WSP-105 |
| d07 | a folder opens at once | TC-WSP-116 |
| d08 | a folder opens after seven seconds | TC-WSP-115 |
| d09 | the list scrolls with the pointer outside it | TC-WSP-129 |
| d10 | the list scrolls up near its foot | TC-WSP-117 |
| d11 | the list scrolls only at the very edge | TC-WSP-117 |
| d12 | the list scrolls very slowly | TC-WSP-117 |
| d13 | a lit folder has no border | TC-WSP-101 |
| d14 | the outline of the list is far inside it | TC-WSP-106 |
| d15 | the label is far from the pointer | TC-WSP-101 |
| t01 | a row cannot be dragged | TC-WSP-100, 101 |
| t04 | an item is a place of its own | TC-WSP-104 |
| t07 | a row let go outside the list is put down in it | TC-WSP-113 |
| t08 | a row is put down where it cannot go | TC-WSP-107, 109 |
| t09 | the empty part of the list is not the top | TC-WSP-105 |
| t13 | nothing is said beside the pointer | TC-WSP-101 |
| t14 | the list does not scroll | TC-WSP-117 |
| t16 | a folder is not opened | TC-WSP-115 |
| t17 | a folder that is moved is shut | TC-WSP-119 |
| t18 | a move says nothing | TC-WSP-100 |
| t19 | the folder a row is put in is not opened | TC-WSP-126 |
| t20 | a folder that is renamed is shut | TC-WSP-059 |
| t23 | the row that moved is not picked | TC-WSP-100 |

#### The windows of the pane

| Mutant | What is broken | Killed by |
|---|---|---|
| f01 | a name that is taken does not say Replace | TC-WSP-083 |
| f02 | a name that differs by its case is not taken | TC-WSP-202 |
| f03 | the new folder is not made for the query | TC-WSP-080 |
| f04 | the Source is not kept as the sample | TC-WSP-087 |
| f05 | the sample is kept without the tick | TC-WSP-089 |
| f06 | the sample of a schema is the Document box of Patch | TC-WSP-171 |
| f07 | Save schema offers a patch | TC-WSP-183 |
| f08 | a query from the workspace is not offered under its name | TC-WSP-084 |
| f09 | the folder that is picked is not the one offered | TC-WSP-091 |
| f10 | what was saved is not picked | TC-WSP-074 |
| f11 | the box does not come from what was saved | TC-WSP-074 |
| f12 | the folder that was made is not picked | TC-WSP-131 |
| f13 | a folder is made at the top | TC-WSP-133 |
| f14 | a folder that was typed is not looked at | TC-WSP-151 |
| f15 | the new folder is not named for the one that comes in | TC-WSP-152 |
| f16 | an import replaces unless it is told to keep both | TC-WSP-157 |
| f17 | an import does not say Imported | TC-WSP-152 |
| f18 | an export leaves the samples out unless it is told | TC-WSP-141 |
| f19 | an export of a picked folder exports the folder unless it is told | TC-WSP-148 |
| f20 | an export does not say Exported | TC-WSP-141 |
| f21 | what was deleted is still picked | TC-WSP-070 |
| f22 | a delete does not say Deleted | TC-WSP-067 |
| f23 | a delete does not say that the folder is left | TC-WSP-070 |
| f24 | a name that cannot be a file name is not said | TC-WSP-082 |

#### The window and the settings

| Mutant | What is broken | Killed by |
|---|---|---|
| a01 | a narrow window has the pane | TC-WSP-024 |
| a02 | the width of the pane is not kept | TC-WSP-022 |
| a03 | the folder that was chosen is not kept | TC-WSP-162 |
| a04 | Show in the file manager does nothing | TC-WSP-063 |
| a05 | an opened query does not choose its language | TC-WSP-041 |
| a06 | a document is not opened | TC-WSP-047 |
| a07 | the folder button shows the strip | TC-WSP-002 |
| a08 | Save is beside Run while the pane is hidden | TC-WSP-001, 002 |

#### What is kept

| Mutant | What is broken | Killed by |
|---|---|---|
| s01 | a move leaves the sample behind | TC-WSP-102 |
| s02 | a rename leaves the sample behind | TC-WSP-055 |
| s03 | a delete leaves the sample | TC-WSP-068 |
| s04 | a copy has no sample | TC-WSP-060 |
| s05 | a copy has the id of the original | TC-WSP-060 |
| s06 | a replaced item gets a new id | TC-WSP-083 |
| s07 | items of one name do not share the sample | TC-WSP-203 |
| s08 | the index is written at every read | TC-WSP-206 |

#### The pane's pictures, the status bar's button, the files dropped on the window and the queries carried onto the Query pane

| Mutant | What is broken | Killed by |
|---|---|---|
| q01 | the plus of the new folder button has a left arm that is one short | TC-WSP-004, 210, 222 |
| q02 | the filled column of the pane's button is one too narrow | TC-WSP-003, 019, 222 |
| q03 | the new folder button has no foot | TC-WSP-004, 210, 222 |
| q04 | the outline of the pane's button is drawn outside its box | TC-WSP-003, 019 |
| q05 | the pane's button is as bright when the pane is hidden | TC-WSP-003, 020 |
| q06 | the strip has a plain folder where the pane's icon is | TC-WSP-019 |
| q07 | the button that makes a folder is the plain folder | TC-WSP-004, 210, 222 |
| q08 | the strip's icon is as bright as a shown pane's | TC-WSP-019 |
| q09 | the tooltip of the button says what it does the other way round | TC-WSP-245 |
| q10 | the pane's button is not in the status bar | TC-WSP-002, 243 |
| q11 | the button is after the status text | TC-WSP-243, 244 |
| q12 | the button is at the right end again, left of the ⚙ | TC-DOCK-006, TC-DOCK-008, TC-WEB-001, TC-WSP-243, 247 |
| q20 | a query file is opened as the Source | TC-WSP-250, 251 |
| q21 | a dropped file is nobody's item, from the workspace's folder too | TC-WSP-270 |
| q22 | a query that is put in the box does not choose its language | TC-WSP-250, 251, 271, 272 |
| q23 | a query file held over the window is not told from a document | TC-WSP-265, 267, 269 |
| q24 | a query file that cannot be used is not said | TC-WSP-258, 260, 262 |
| q25 | the Source says Drop to open for a query file | TC-WSP-265 |
| q26 | the query box is not outlined for a query file | TC-WSP-265, 267, 269 |
| q27 | a query file of a mebibyte and a byte is not too big | TC-WSP-258 |
| q28 | several files held over the window are outlined as a query | TC-WSP-268 |
| q29 | a file that is not a query is not opened | TC-WSP-253, 254, 255 |
| q30 | the end of the name is read with its case | TC-WSP-252 |
| q31 | the window opens every file as the Source | TC-WSP-250 |
| q32 | the byte-order mark of a file is in the box | TC-WSP-257 |
| q33 | a file from anywhere else leaves the box with the item it came from before | TC-WSP-249 |
| q34 | with a page in front the main window takes the file too | TC-WSP-280 |
| q35 | a pane in a window of its own takes no file | TC-WSP-283 |
| q36 | a query that is opened does not bring the Json Query tab forward | TC-WSP-282 |
| q40 | a row that is not a query is opened on the query pane | TC-WSP-273, 274, 275 |
| q41 | a query let go on the query pane is picked and not opened | TC-WSP-271, 272 |
| q42 | a query let go on the query pane is opened and not picked | TC-WSP-271 |
| q43 | the query pane is not lit | TC-WSP-271, 276, 277 |
| q44 | the label beside the pointer does not say what letting go opens | TC-WSP-271 |
| q45 | a patch is a query that can be put on the query pane | TC-WSP-273 |
| q46 | the pane does not know where the query pane is | TC-WSP-271, 272 |
| q47 | the query pane is never where a query can be put down | TC-WSP-271 |
| q48 | a query pane that is not there is still a place to put a query | TC-WSP-281, 284 |
| q49 | a query let go on the query pane is dropped on the floor | TC-WSP-271, 272 |
| q50 | a query is opened wherever it is let go | TC-WSP-113, 277 |
| q51 | a file from a workspace that is reached through a link is nobody's | TC-WSP-289 |
| q52 | a query that is carried onto the query pane is opened with its sample | TC-WSP-290 |
| q53 | a query file that is used leaves what was said of the one before | TC-WSP-262, 291 |
| q54 | a query file that is used unloads the document | TC-WSP-263, 291 |
| q55 | a query file that is used takes the message away only while no document is loaded | TC-WSP-291 |

#### The states of the window

| Mutant | What is broken | Killed by |
|---|---|---|
| x01 | the indent stops at three levels | TC-WSP-233 |
| x02 | the list is never taller than 400 | TC-WSP-234 |
| x03 | the pane is a quarter of the window | TC-WSP-235 |
| x04 | Save in a window of its own does not bring the main window forward | TC-WSP-240 |
| x05 | the pane is not shown in a window of exactly 900 | TC-WSP-238 |
| x06 | the pane is shown in a window of 899 | TC-WSP-238 |

## What the cases found

### Faults of the app

Found by the cases and the layout tests while the pane was tested. Every one is fixed, and the app has a test now that
fails without the fix:

1. **The strip of a folded pane cut off its button and its folder** (TC-WSP-019, 035). The strip is 26 points wide and
   its panel had the usual frame margin of 8: nothing was left of the room. Only a real window shows it (a layout test
   draws the button where it is told to). The margin is 1 now, and a test of the app asks that the button and the folder
   are inside the strip.
2. **A folder that was renamed or moved shut itself** (TC-WSP-059, 119). The open folders were kept by path, and the path
   had changed. They follow the folder now (`follow_open_folders`), the folders in it too.
3. **A message under the list stayed until the pointer was moved** (TC-WSP-168). egui forgets a repaint that it was asked
   for at the next frame, so a window that nobody touched never drew the frame in which the message is due to go. The
   pane asks for it in every frame that the message is shown; the harness of the layout tests reads what was asked for.
4. **The buttons of the header were drawn over the title when the pane was narrow** (TC-WSP-023, 229): at 180 points
   the 💾 was on top of "Workspace". The least width is 208 now, and a test of the app finds where the title ends and
   where the first button begins at the least width, at widths under it and at others up to 400.
5. **Save… in a Query pane that is in a window of its own opened the window that saves behind that window** (TC-WSP-240).
   The window that saves is the main window's, and nothing brought the main window forward: the person pressed the button
   and nothing seemed to happen. Found by putting the app in another of its states (a pane popped out), not by a case that
   was written for it. The main window is asked to come forward when the window that saves opens
   (`WorkspacePane::windows`), a test of the app (`Windows`, the harness with more than one window) reads the command, and
   TC-WSP-240 reads the window that the window manager says is in front **before** it switches to the main window itself
   (`Switch To Main Window` raises it: a case that did not look first would have passed with the fault).
6. Seen while the drag was made, before the cases were written: a drag with the **right** button carried a row too
   (egui's `drag_started()` is true for any button), the label that says where a row would go **broke into four lines**
   in the real window (it is `extend()`ed now: TC-WSP-101 reads it), and the list that was carried to its foot scrolled
   too slowly because the scroll was animated.

7. **A file that was let go from a workspace that is reached through a link was not the item it is** (TC-WSP-289). The
   toolkit hands the path of a dropped file over with its links resolved (`canonicalize` in `winit` 0.30,
   `x11/dnd.rs`), and the app looked for the file under the folder it had been told to use, which has the link in its
   name: the box got the text and the language, but the Query row said no item and never marked the box changed. Found by
   a case that makes the workspace a link to a folder (the same case passes on a folder that is not a link, so it was
   not the case that was wrong); `WorkspacePane::note_dropped` looks under the resolved folder as well, and a test of the
   app (`a_file_from_a_workspace_that_is_reached_through_a_link_is_the_item_all_the_same`) fails without it.

8. **A message about a query file stayed after a good file was dropped** (TC-WSP-262, 291). `Load error: big.jq is too big
   to put in a box` is the one place the app has for what could not be loaded, and it was shown until something was
   loaded or the Source was cleared, as every load error is: a query file that was dropped afterwards and was used did
   not take it away. The cases and the test of the app had not seen it because none of them asked: the test of the app
   cleared the message by itself before it dropped the good file, and TC-WSP-262 read that the good file was used and
   nothing more. The owner said that a good drop should clear it: `use_query_file` takes the message away when it uses a
   file (a document that is loaded stays, and so does everything else; a message about a Source that could not be
   loaded goes too, as it goes when anything is loaded). The test of the app does not clear it by itself any more and a
   second one has a document loaded, TC-WSP-262 asks that the status bar does not say it any more, and TC-WSP-291 asks
   the same with a document loaded; three faults (q53 to q55) were put in for it.

Seen, **not changed**:

- **A file that is gone when it is let go is not delivered to the window at all** (the same `canonicalize` fails and the
  drop is dropped), so nothing is said (TC-WSP-261, which says what the window does now and will fail if the toolkit is
  ever changed to deliver it).
- **A query that is opened from the pane's list does not take the message away**, as one that is dropped on the window
  does now: only the drop was asked for.

Not changed, on purpose: the ⚠ that says an index was damaged is gone at the next read of the folder, which is the first
time the window gets the focus after it opens: the first read made the index again, so there is nothing left to warn
of (TC-WSP-200 reads the index and the set-aside file; TC-WSP-201 sees the warning where it stays, for a link in the
folder).

### Faults of the cases

Found by the faults that were put into the app (the tables above): each of these was a fault that **survived** the cases
the first time round, and a case was written or made stricter for it. Fifteen of the 146 survived the first run and two
did not compile; of the 21 that were put in again against the stricter cases (and the 4 that were made for the new states)
two still survived, and a check was added for each. None of them was a fault of the app: every one was a check that was
missing or too weak.

- **A check that could not fail.** The export case asked for `Exported` under the list and passed for a message that said
  `Copied`: the folder that the test made was called `exported`, the message ends with where it is, and the word was in
  that (TC-WSP-141). The expression asks for the number after the word now. In the same way the name of an item is also
  said in the details under the list: the case that the box for a new name starts with the old name read the name in the
  whole list and found it in the details too (TC-WSP-056, now read in the row).
- **A check that did not look at what the fault changed.** The filter case typed capitals over names in small letters,
  which a filter that minds the case also finds (TC-WSP-012: an item with capitals in its name now); the case that a row
  let go outside the list stays carried an item that was at the top, where "to the top" is where it was (TC-WSP-113: one
  in a folder now); a folder carried over its own row (TC-WSP-127), a label with the way to a folder in a folder
  (TC-WSP-128, with the spaces round the slash), the label of the top (TC-WSP-106) and a row held under the list
  (TC-WSP-129) were not seen at all; the second button of a schema was found by its words and not by where it is
  (TC-WSP-177); `Replace` was in the sentence of the window as well as on the button (TC-WSP-083 reads the button's
  width, 53 and not 34); a schema that is saved while a patch is in the other page's box (TC-WSP-183, 184).
- **A fault that cannot be seen from outside.** A folder that is deleted but stays (another program's file is in it) is
  not the one that is picked any more: the screen shows it only for that folder, and the layout test and TC-WSP-070 both
  look at it now.
- **A check that was not strict where the fault was** (the second round of the day): the strip's icon was said to be dim by
  "nothing as bright as 150", and the text's own colour (140) is under that, so an icon drawn in it was dim to the case
  (q08): the limit is 135 now, between the dim ink (127, and 122 on the strip) and the text's. The long message of the
  status bar (TC-WSP-246) did not look at the buttons at the other end of the bar; it does now.
- **The state of the window that no case was in:** the strip's button in a window too narrow for the pane
  (TC-WSP-236: it must not leave the pane open for later), items nested eight deep (233), a taller and a wider window
  (234, 235).

### What came out of the cases about the cases

(Also in [writing_tests.md](writing_tests.md).)

- **A pointer left over a button has a tooltip** that covers the line under the title (TC-WSP-217 failed on it the first
  time); a case that reads small text puts the pointer away first.
- **A point that the window anchors by itself is not moved by the docked run**: the foot of the list (TC-WSP-117) and
  the place under it (TC-WSP-129) are variables that `docked_main.py` knows, like the windows that the pane opens.
- **OCR reads the line under the title differently from run to run** (`5 items`, `5 ems`, `Avorkspace`): the case asks
  for the number and for letters after it.
- **A file that a script moved keywords out of** had a case twice and a keyword twice, and `scripts/robot_lint.py` finds
  that now.
- **An icon is read as a picture, with a `?` where a rounded corner decides** (`Icon Should Look Like`): the same icon over the
  button (60) and over the strip's ground (27) has different pixels over 90 at its corners, so a corner is either, and a case
  that took a bounding box would have passed an icon that was a pixel off.
- **A probe that takes the whole bar takes its rule**: the status bar has a rule at its top as bright as a button, the Source
  box's edge is over 90 above a short bar, and the splitter between two panes is white while the pointer is on it; the
  region of a probe begins under them and the button is measured by its picture, not its fill (TC-WSP-246 failed three
  times on that before it was right).
- **OCR reads `.jq` as `.ja`** in the Query row, and a label that has no space in it loses the one between the words
  (`asthe query`): the pattern says so (`mine\.j[qa]`, `?as ?the ?query`).
- **The toolkit decides what a drop is**: it gives a file's path with the links resolved (TC-WSP-289, a fault of the app
  found by it) and drops the drop of a file that is not there (TC-WSP-261): a case that wants either has to know it.
- **`\x00` in an `Evaluate`** is a NUL for Python before it is anything else: write the backslash twice (TC-WSP-209).
- **Ctrl+Z after an open is not a case**: the text box keeps a step to go back to only when the text has been still for a
  second while frames are drawn, and selecting the text to read it is a step of its own; a case that reads the box between
  the open and the key, or is slow, gets the wrong step (a case was written, passed twice and failed three times in a row
  with a retry added). The check is a test of the app, with the clock of the test
  (`ctrl_z_in_the_query_box_brings_back_the_text_that_an_open_replaced`).

## Not reachable

- **Native Wayland, Windows and macOS** are not run ([00_test_strategy.md](00_test_strategy.md)). The app is checked there
  by `cargo clippy -D warnings` for `x86_64-pc-windows-gnu` and `aarch64-apple-darwin`, and a window brought forward by the
  app (TC-WSP-240) is the window manager's to honour: on X11 under the test's window manager it is.
- **A screen that is not 1 point to the pixel** cannot be had on the test display, so a case sees the pane at one scale
  only; the tests of the app draw the folder, the pane's button and the button that makes a folder at 1, 1.25, 1.5, 2
  and 3 and ask that their edges are on whole pixels and their lines at least one pixel thick.
- **A display bigger than 1280 × 900**: the window is made as wide and as tall as that at most (TC-WSP-234, 235).
- **The keyboard in the list**: there are no keys that move through the list, none are tested (Enter and Escape in the
  windows of the pane and in a name that is being typed are).
- **The web** has no pane yet; nothing here is about it.
- **Where in the window a file is let go**: the toolkit under the app drops the position that X11 sends with a drop (and
  has no position at all for a file that is dragged over the window), so the app cannot know which pane a file is let go
  on, and no case can say it: the name of the file is what decides, and the cases let go in the middle of the window.
- **A file that cannot be read at all**: the toolkit resolves the path of a dropped file before it hands it over, and drops
  the drop when it cannot (a file that was taken away while it was carried), so only the files that are there but cannot be
  used (too big, not text) are said; the message for a path that cannot be read is a test of the app, fed the path
  directly (`a_query_file_that_cannot_be_used_is_said_and_the_box_is_left_alone`).
- **A box that was undone after a drop** (Ctrl+Z): the text box keeps a step to go back to only when the text has been still
  for a second while frames are drawn, as with an item that is opened (TC-WSP-097 was retired for it); the test of the app
  has the clock (`a_query_file_takes_the_place_of_what_was_in_the_box_and_the_undo_brings_that_back`).
- **How thick the outline of the Query pane is** while a query is carried over it (1.5 points, which is one bright pixel
  and a fainter one): a case reads that the pane is outlined all round, and a test of the app reads the width.
- **Where the box scrolls to, and whether the suggestions of an autocomplete are shut**, after a query is put in the box
  (`put_query`): the caret of the box is a thing of the window's inside, and the tests of the app read it.
