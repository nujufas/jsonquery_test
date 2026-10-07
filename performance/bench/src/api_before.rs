//! The adapter for a revision in which a document is always a parsed `Value` (the app as it was
//! before the memory-mapped, indexed documents). What each function does is what the app's
//! worker thread and tree widget do at that revision with the same words; see `api_after.rs` for
//! the same functions at a revision that has lazy documents.

use std::fs::File;
use std::io::{BufWriter, Write};
use std::path::Path;
use std::sync::atomic::AtomicBool;

use jsonquery_core::engine::QueryEvent;
use jsonquery_core::{
    flatten_visible, new_expanded_at_root, Document, ExpandState, ValueView,
};
use serde_json::Value;

use crate::common::*;

pub const FLAVOUR: &str = "before";

pub struct Doc(Document);

pub fn load(path: &Path, mode: Mode) -> Result<Doc, Fail> {
    match mode {
        // A file was always parsed.
        Mode::Auto | Mode::Parsed => jsonquery_core::load(path)
            .map(Doc)
            .map_err(|e| Fail::err(format!("{e:#}"))),
        Mode::Lazy => Err(Fail::Unsupported(
            "this revision cannot keep a file on disk: every document is parsed".into(),
        )),
    }
}

pub fn load_text(text: &str) -> Result<Doc, Fail> {
    jsonquery_core::load_text(text)
        .map(Doc)
        .map_err(|e| Fail::err(format!("{e:#}")))
}

impl Doc {
    pub fn is_lazy(&self) -> bool {
        false
    }

    pub fn byte_len(&self) -> u64 {
        self.0.byte_len
    }

    pub fn top_level_values(&self) -> usize {
        self.0.top_level_values
    }

    /// How long the loader says it took (reading and parsing).
    pub fn parse_ms(&self) -> f64 {
        self.0.parse_time.as_secs_f64() * 1e3
    }

    /// What the index of a lazy document takes: none here.
    pub fn index_bytes(&self) -> Option<usize> {
        None
    }

    pub fn kind(&self) -> ValueKind {
        ValueKind::of(&self.0.root)
    }

    pub fn child_count(&self) -> usize {
        (&self.0.root).child_count()
    }

    /// The whole document as a value, if it is one (it always is here).
    pub fn value(&self) -> Option<&Value> {
        Some(&self.0.root)
    }

    /// The first and the last child of the root, when they are small enough to be compared.
    pub fn probe(&self) -> (Option<Value>, Option<Value>) {
        let n = (&self.0.root).child_count();
        let take = |i: usize| {
            (&self.0.root).child_at(i).and_then(|v| {
                let mut budget = 10_000;
                is_small(v, &mut budget).then(|| v.clone())
            })
        };
        (take(0), take(n.saturating_sub(1)))
    }

    /// The rows the tree widget makes for a document that has just been opened.
    pub fn rows_initial(&self) -> Vec<RowInfo> {
        flatten_visible(&self.0.root, &new_expanded_at_root())
    }

    /// The rows after "Find in Source" has revealed `path`: every container on the way open.
    pub fn rows_reveal(&self, path: &NodePath) -> Vec<RowInfo> {
        let mut expand = new_expanded_at_root();
        for i in 0..=path.len() {
            expand.insert(path[..i].to_vec());
        }
        flatten_visible(&self.0.root, &expand)
    }

    /// The rows with each of `open` (and what is above it) expanded, as clicks make them.
    pub fn rows_expanded(&self, open: &[NodePath]) -> Vec<RowInfo> {
        let mut expand: ExpandState = new_expanded_at_root();
        for path in open {
            for i in 0..=path.len() {
                expand.insert(path[..i].to_vec());
            }
        }
        flatten_visible(&self.0.root, &expand)
    }

    /// The row text of the node at `path`, if it is a scalar.
    pub fn resolve_preview(&self, path: &NodePath) -> Option<String> {
        jsonquery_core::resolve(&self.0.root, path).and_then(|v| v.scalar_preview())
    }

    /// The node at `path` as a value, when it is small.
    pub fn resolve_value(&self, path: &NodePath) -> Option<Value> {
        jsonquery_core::resolve(&self.0.root, path).map(|v| v.clone())
    }

    /// How many children of the root there are of each kind, walking all of them:
    /// null, bool, number, string, array, object.
    pub fn tally_children(&self) -> [u64; 6] {
        let mut tally = [0u64; 6];
        for (_, child) in (&self.0.root).iter_children() {
            tally[kind_slot(child.kind())] += 1;
        }
        tally
    }

    pub fn query(&self, kind: Kind, text: &str, cancel: &AtomicBool) -> Result<QueryRun, Fail> {
        let mut run = QueryRun::default();
        let mut on_event = |event: QueryEvent| match event {
            QueryEvent::Item(value) => {
                run.items += 1;
                if run.kept.len() < LIVE_PREVIEW_CAP {
                    run.kept.push(value);
                }
            }
            QueryEvent::ItemError(error) => {
                run.item_errors += 1;
                run.first_error.get_or_insert(error);
            }
        };
        kind.engine()
            .run(&self.0.root, text, cancel, &mut on_event)
            .map_err(Fail::err)?;
        Ok(run)
    }

    pub fn search(&self, text: &str, regex: bool) -> Result<Vec<NodePath>, Fail> {
        jsonquery_core::search(&self.0.root, text, regex).map_err(|e| Fail::err(format!("{e:#}")))
    }

    pub fn locate(&self, target: &Value, nth: usize, rel: &NodePath) -> SourceMatches {
        jsonquery_core::locate(&self.0.root, target, nth, rel)
    }

    /// The Text view's rendering of the document.
    pub fn text_view(&self, nodes: usize) -> (String, bool) {
        jsonquery_core::pretty_print_bounded(&self.0.root, nodes)
    }

    /// What "Copy to Clipboard" makes of the document, or of the node at `path`.
    pub fn copy_text(&self, path: Option<&NodePath>) -> Result<String, Fail> {
        let value = match path {
            Some(p) => jsonquery_core::resolve(&self.0.root, p)
                .ok_or_else(|| Fail::err("that value is no longer part of the document"))?,
            None => &self.0.root,
        };
        serde_json::to_string_pretty(value).map_err(Fail::err)
    }

    /// What "Save…" does with the document, or the node at `path`: returns the bytes written.
    pub fn save(&self, path: Option<&NodePath>, out: &Path) -> Result<u64, Fail> {
        let value = match path {
            Some(p) => jsonquery_core::resolve(&self.0.root, p)
                .ok_or_else(|| Fail::err("that value is no longer part of the document"))?,
            None => &self.0.root,
        };
        let file = File::create(out).map_err(Fail::err)?;
        serde_json::to_writer_pretty(BufWriter::new(file), value).map_err(Fail::err)?;
        std::fs::metadata(out).map(|m| m.len()).map_err(Fail::err)
    }

    /// What the query box offers as completions of `text` (the cursor at its end).
    pub fn suggest(&self, text: &str) -> Vec<String> {
        jsonquery_query::suggest(text, text.len(), None, Some(&self.0.root))
            .into_iter()
            .map(|s| s.label)
            .collect()
    }

    /// The Tools window's Format of a document kept on disk, written a piece at a time. There is
    /// no such thing here.
    pub fn format_stream(&self, _out: &mut dyn Write) -> Result<u64, Fail> {
        Err(Fail::Unsupported(
            "no document is kept on disk in this revision, so none is formatted from its file".into(),
        ))
    }
}

pub fn kind_slot(kind: ValueKind) -> usize {
    match kind {
        ValueKind::Null => 0,
        ValueKind::Bool => 1,
        ValueKind::Number => 2,
        ValueKind::String => 3,
        ValueKind::Array => 4,
        ValueKind::Object => 5,
    }
}
