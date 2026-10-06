# Opening a JSON source — test requirements

Source: `crates/app/src/app.rs` (§the toolbar's source field / paste / drag-drop),
`crates/core/src/document.rs`, `crates/app/src/worker.rs`.

Covers every way a document gets loaded, plus the load-time edge cases
(NDJSON, empty file, malformed JSON, oversized URL download). See
[00_test_strategy.md](00_test_strategy.md) ("Native OS dialogs") for how the
`…` (browse) button's dialog is answered by a stand-in for the desktop's file-chooser
portal, which the cases of that button depend on.

## Preconditions common to this area

- Fresh app launch per test unless a case explicitly says "with a document
  already loaded" (for the Clear/replace cases).
- A small fixture-file directory under (future) `resources/fixtures/`
  will hold the JSON files these cases reference — named here descriptively;
  actual filenames are an implementation detail.

## Test cases

### TC-OPEN-001 — Open a valid JSON file via the file dialog
Priority: P1
Steps:
1. Click the `…` (browse) button beside the toolbar's source field.
2. In the native dialog, navigate to / type the path of a small valid JSON
   object fixture, confirm.
Expected:
- The source field shows the file's path, and the toolbar's status area its
  human-readable byte size (e.g. `512 B`), no NDJSON-record count suffix.
- Status bar shows `Parsed in {duration}`.
- Source panel's Tree view shows the parsed content, root expanded.
- Window title is still exactly `jsonquery` (unchanged by loading — confirms
  the "title never changes" fact from TC-WIN-001 under a loaded-doc state).
Automation notes: the stand-in portal answers the dialog with the fixture's path
(`Browse And Choose`); byte-size and duration text via OCR, "contains/matches pattern"
not exact equality (duration is nondeterministic). **Passing**
(`suites/opening_sources/opening_dialog.robot`; it was Blocked until 2026-10-06).

### TC-OPEN-002 — File dialog filters to JSON-ish extensions
Priority: P2
Steps: Open the `…` button's dialog and inspect the file-type filter.
Expected: exactly one filter group, labeled `JSON`, matching extensions
`json, ndjson, jsonl, log, txt`.
Automation notes: what the app *asks for* is read back from the stand-in portal (the
request's `filters`, `multiple` and `directory`), not from the dialog's own dropdown, which
belongs to the desktop. **Passing**; it also checks that one file is chosen, not several,
and no folder.

### TC-OPEN-003 — Open a JSON source via URL
Priority: P1
Preconditions: a small local HTTP server (implementation detail) serving a
known-good JSON fixture, so the test doesn't depend on network access.
Steps:
1. Click into the toolbar's source field.
2. Type the fixture server's URL into it.
3. Press Enter (the `Load` button is TC-OPEN-018).
Expected:
- The source field keeps the URL as the source label; a `Loading…` spinner
  may appear briefly before the doc renders.
- Same downstream assertions as TC-OPEN-001 once loaded.
Automation notes: race — assert on the post-load state via
`Wait Until Keyword Succeeds`, don't assume the spinner is observable (it may
resolve faster than a screenshot cadence for small fixtures).

### TC-OPEN-004 — Load button is disabled while the source field is blank
Priority: P3
Steps: With the source field blank, inspect `Load`; type a character, inspect
again; delete it, inspect once more.
Expected: `Load` is disabled (no click effect) while the field is blank —
whitespace alone counts as blank — enabled while it has text, and disabled
again once emptied.

### TC-OPEN-005 — URL: request failure surfaces a load error
Priority: P1
Steps: Load a URL that will fail to connect (e.g. an unroutable address or a
closed local port).
Expected: status bar shows red text starting with `Load error: requesting
{url}: `.
Automation notes: OCR "starts with" match; the trailing OS/library error text
is not worth asserting exactly.

### TC-OPEN-006 — URL: non-JSON response body surfaces a parse error
Priority: P2
Steps: Load a URL for a fixture server endpoint returning plain text/HTML.
Expected: status bar shows red text starting with `Load error: parsing data
from {url}: parsing JSON: `.

### TC-OPEN-007 — URL: oversized download is rejected, not truncated
Priority: P3
Steps: Load a URL for a fixture endpoint that would exceed the 4 GiB cap.
Expected: status bar shows red `Load error: downloading {url}: ` — the app
must fail, not silently load a truncated 4 GiB document.
Automation notes: this test is expensive to run for real (needs an endpoint
that actually reaches the cap, or a way to shrink the cap for testing).
**Flag during implementation**: consider whether this is worth a real 4 GiB
transfer in CI, versus documenting it as untested-at-full-scale and instead
unit-testing the cap logic directly in Rust (outside this Robot Framework
suite). Marking P3 pending that decision.

### TC-OPEN-008 — Paste JSON auto-loads on Ctrl+V, no button
Priority: P1
Steps:
1. With no document loaded, click into the left-panel paste textarea.
2. Paste (Ctrl+V) valid JSON text (pre-seed the OS clipboard as part of test
   setup).
Expected: document loads immediately, no explicit submit action; the source
field is empty and the toolbar's status area shows `(pasted JSON)` as the
source label.
Automation notes: clipboard must be seeded before the paste — use the same
clipboard library as the Copy JSON Path verification
([07_context_menus.md](07_context_menus.md)), just in the write direction.

### TC-OPEN-009 — Paste JSON via Ctrl+Enter while the paste field is focused
Priority: P2
Steps: Type (not paste) valid JSON directly into the paste textarea, then
press Ctrl+Enter while it has focus.
Expected: same load result as TC-OPEN-008.

### TC-OPEN-010 — Drag-and-drop opens a file
Priority: P3 (skip on pure Wayland test hosts — see strategy doc)
Steps: Drag a fixture JSON file from a file manager onto the app window.
Expected: loads exactly as a typed path would; only the first file loads if
multiple are dropped simultaneously (separate sub-case).
Automation notes: requires Xorg/XWayland; document the skip condition rather
than treating a Wayland failure here as a real bug.

### TC-OPEN-011 — Drop-hover overlay only appears when no document is loaded
Priority: P3 (same Wayland caveat as TC-OPEN-010)
Steps: (a) with no doc loaded, drag a file over the window without releasing
— observe; (b) with a doc already loaded, repeat.
Expected: (a) shows a full-panel `Drop to open` heading; (b) shows no such
overlay, even though releasing would still replace the document.

### TC-OPEN-012 — NDJSON / concatenated JSON wraps into one array
Priority: P2
Steps: Open a fixture file containing 3 newline-separated top-level JSON
values.
Expected: loads as a single array of 3 elements; toolbar shows
`(3 NDJSON records)` appended after the byte size.

### TC-OPEN-013 — Empty file loads as an empty array, no error
Priority: P2
Steps: Open a 0-byte fixture file.
Expected: loads successfully; Tree view shows an empty array at the root; no
`Load error` text anywhere; byte size shows as the empty case (confirm exact
`human_bytes` rendering for 0, e.g. `0 B`, during implementation).

### TC-OPEN-014 — Malformed JSON surfaces a parse error
Priority: P1
Steps: Open a fixture file with invalid JSON syntax (e.g. a trailing comma or
unquoted key).
Expected: status bar shows red text starting with `Load error: parsing JSON:
`; no document is loaded (Source panel stays in its prior/empty state).

### TC-OPEN-015 — Loading a new source replaces the current one, and cancels
any in-flight query
Priority: P2
Preconditions: a document is loaded and a query is currently running (use a
large-enough fixture / slow-enough query to keep it running momentarily —
implementation detail).
Steps: While the query is running, load a different source via the source
field.
Expected: new document loads and replaces the old one; results panel and
search state are cleared; the query **text box** and **engine-picker
selection** are preserved unchanged (this is the one piece of state that
survives a source swap — don't assert it gets cleared).

### TC-OPEN-016 — `Clear` button resets to the no-document state, with two
specific exceptions
Priority: P1
Preconditions: a document is loaded, a query has been run with a non-default
engine explicitly selected, and a search has been performed.
Steps: Click `Clear`.
Expected:
- Reverts to the TC-WIN-003 empty-state placeholder; load/save errors,
  find state, search panel, and both trees/text caches are all cleared.
- Query text box content is **unchanged**.
- Engine-picker selection is **unchanged**.
Automation notes: this pair of "does NOT clear" assertions is easy to get
backwards — write them as explicit positive checks (the text/selection is
still exactly what it was), not just "no error occurred".

### TC-OPEN-017 — `Clear` is disabled with nothing to clear
Priority: P3
Steps: On fresh launch (no doc, not loading, no load error, empty source
field), inspect `Clear`.
Expected: disabled (click has no effect). It lights up once a document loads —
or a load error appears, or the field has text (TC-OPEN-021).

### TC-OPEN-018 — The `Load` button loads what is in the source field
Priority: P2
Steps: Type a fixture server's URL into the source field, click `Load`.
Expected: same result as pressing Enter (TC-OPEN-003).

### TC-OPEN-019 — A local path typed into the source field loads that file
Priority: P1
Steps: Type the absolute path of a small valid JSON fixture into the source
field, press Enter.
Expected: the document loads, the field shows the path, and the `(pasted
JSON)` note is not shown. Anything that isn't an `http://` / `https://`
address is a local path; a leading `~` expands to the home directory, and one
pair of surrounding quotes (as a file manager's "Copy as path" adds) is
ignored — both covered by unit tests in `app.rs`, not here.
Automation notes: the `…` button hands its path to the same loader; its own journey, through
the dialog, is TC-OPEN-001.

### TC-OPEN-020 — A path that doesn't exist shows a load error and keeps the text
Priority: P2
Steps: Type a path that doesn't exist into the source field, press Enter.
Expected: status bar shows red `Load error: opening {path}: No such file or
directory (os error 2)`; the source field still holds the path, so it can be
corrected rather than retyped.

### TC-OPEN-021 — `Clear` also empties text that was typed but never loaded
Priority: P3
Steps: With nothing loaded, type text into the source field, click `Clear`.
Expected: `Clear` is enabled as soon as the field has text; clicking it empties
the field (and, with nothing loaded, touches nothing else).

### TC-OPEN-022 — Closing the dialog loads nothing
Priority: P1
Steps: Click `…` and close the dialog without choosing a file.
Expected: nothing changes — the paste box is still waiting ("Paste JSON here…"), the status bar
shows no `Parsed` and no `Load error`.
Automation notes: `Portal Will Cancel`. **Passing.**

### TC-OPEN-023 — A file chosen replaces the document on show
Priority: P1
Steps: Paste a document, then choose another file with `…`.
Expected: the `(pasted JSON)` note goes and the file's content is on show.
**Passing.**

### TC-OPEN-024 — A line-delimited file becomes one array
Priority: P2
Steps: Choose `records.ndjson` (three JSON values, one to a line).
Expected: the Source pane shows an array of three items and the toolbar says `3 NDJSON records`.
**Passing.**

### TC-OPEN-025 — A file that is not JSON shows a load error
Priority: P1
Steps: Choose a file that is not JSON.
Expected: red `Load error` in the status bar; the field shows the file's name. **Passing.**

### TC-OPEN-026 — A file chosen can be queried at once
Priority: P1
Steps: Choose `people.json`, run `.[] | [.name, .role] | @csv`, read the rows.
Expected: the three rows, exactly (through Copy to Clipboard). **Passing.**

### TC-OPEN-027 — Choosing a file twice loads the second
Priority: P2
Steps: Choose one file, then another.
Expected: the second is loaded and named in the field. **Passing.**

### TC-OPEN-028 — Each press asks the dialog once
Priority: P3
Steps: Click `…` twice, each time closing the dialog.
Expected: the first press opens one dialog (not two), the second opens the next. **Passing.**

### TC-OPEN-029 — A file past the mapping size opens like any other
Priority: P2
Steps: Type the path of an 80 MiB file — `{"heavy": ["a", "b", "c"], "n": 1}` and then blanks, so that
parsing costs nothing — into the source field and press Enter.
Expected: the document loads: the toolbar says `80.0 MB` and the Source pane shows the object
(`2 keys`); no load error. The app maps a file of 64 MiB or more while it parses it
(`jsonquery_core::MAP_THRESHOLD`) and reads a smaller one, so this is the mapped way in, end to end.
Automation notes: `Make Heavy File` writes the file into a temp directory that goes with the display.
The case does not tell the mapped way from the read one by itself — the unit tests of
`crates/core` do (`Document::mapped`) — it is what keeps the heavy path working in the real window.
**Passing.**

### TC-OPEN-030 — A named pipe opens with what is written to it
Priority: P2
Steps: Make a named pipe (`mkfifo`) and have something write a JSON document into it as soon as it is
opened; type its path into the source field and press Enter.
Expected: the document that was written is loaded (`from` and `items` in the Source pane). A pipe says
it is 0 bytes long however much it will hand over; the app used to believe it and load an empty array,
`0 B`, whatever was written, and the same for `/dev/stdin` of an app started at the end of a pipe and
for the files of `/proc`.
Automation notes: `Make Named Pipe That Says` starts the writer in a thread, which waits (opening a
pipe for writing does) until the app opens it. **Passing.**

### TC-OPEN-031 — A small download leaves nothing in the temp folder
Priority: P2
Steps: Load a URL (the fixture server's `valid.json`), then look in the temp folder for
`jsonquery_gui-*` files.
Expected: the document is loaded and the temp folder holds nothing it did not hold before. A response
of under 64 MiB is parsed from memory; before, every download was written to a file there, which
nothing deleted.
Automation notes: `App Temp Files` lists the folder (`TMPDIR`, which the app inherits, or `/tmp`) before
and after, and the case compares the two lists rather than expect none, as a shared `/tmp` may hold
what older builds left. The file would be gone by the time the document shows: it is deleted when the
download function returns, before the worker reports the document. **Passing.**

### TC-OPEN-032 — A large download leaves nothing in the temp folder
Priority: P2
Steps: Serve a 70 MiB file over HTTP, load its URL, then look in the temp folder.
Expected: the document is loaded and the temp folder holds nothing new. A response of 64 MiB or more is
streamed into a temporary file (readable by its owner only), mapped for the parse, and deleted
afterwards, whether the parse worked or not; before, the file — 70 MiB here — stayed there for good and
the app still held it mapped.
Automation notes: as TC-OPEN-031; the fixture server serves the temp directory `Make Heavy File` made.
**Passing.**

## Mutation checks

TC-OPEN-029 to 032 were run against the build from before the change that made them
(2026-10-06): TC-OPEN-030 fails (`(0 items)` for a pipe that was written to), TC-OPEN-031 and 032 fail
(the `jsonquery_gui-*` files a download left are named in the message), and TC-OPEN-029 passes — that
build mapped every file as well, so it is a guard for the mapped way in and not a difference between
the builds. The unit tests of `crates/core` and of the worker's download tell the ways in apart.

Leaving `.jsonl` out of the `…` button's file filter fails TC-OPEN-002 and nothing else (the case
compares the whole list of extensions the app asks the dialog for).
