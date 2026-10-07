//! The adapter for a revision that has lazy documents: a file of 256 MiB or more is memory-mapped
//! and indexed, not parsed (`jsonquery_core::Content`, `Root`, `lazy`). What each function does is
//! what the app's worker thread and tree widget do at that revision, with the same words; see
//! `api_before.rs` for the same functions where every document is a parsed value.

use std::fs::File;
use std::io::{BufWriter, Write};
use std::path::Path;
use std::sync::atomic::AtomicBool;

use jsonquery_core::engine::QueryEvent;
use jsonquery_core::lazy::{Indent, PrettyLimits, Style};
use jsonquery_core::{
    flatten_grouped, flatten_visible, groups_containing, new_expanded_at_root, Content, Document,
    ExpandState, GroupState, Root, ValueView,
};
use serde_json::Value;

use crate::common::*;

pub const FLAVOUR: &str = "after";

/// What the Text view shows of a document kept on disk, besides the number of nodes: as much text
/// as this, and of a string as much as that (`worker.rs`).
const TEXT_VIEW_BYTES: usize = 4 * 1024 * 1024;
const TEXT_VIEW_STRING_BYTES: usize = 4096;

pub struct Doc(Document);

pub fn load(path: &Path, mode: Mode) -> Result<Doc, Fail> {
    let loaded = match mode {
        Mode::Auto => jsonquery_core::load(path),
        #[cfg(jq_load_with)]
        Mode::Parsed => jsonquery_core::load_with(
            path,
            jsonquery_core::LoadLimits {
                lazy_threshold: u64::MAX,
                ..jsonquery_core::LoadLimits::default()
            },
        ),
        #[cfg(jq_load_with)]
        Mode::Lazy => jsonquery_core::load_with(
            path,
            jsonquery_core::LoadLimits {
                lazy_threshold: 1,
                ..jsonquery_core::LoadLimits::default()
            },
        ),
        #[cfg(not(jq_load_with))]
        Mode::Parsed | Mode::Lazy => {
            return Err(Fail::Unsupported(
                "this revision has no way to choose how a file is brought in".into(),
            ))
        }
    };
    loaded.map(Doc).map_err(|e| Fail::err(format!("{e:#}")))
}

pub fn load_text(text: &str) -> Result<Doc, Fail> {
    jsonquery_core::load_text(text)
        .map(Doc)
        .map_err(|e| Fail::err(format!("{e:#}")))
}

/// A node as a value, when it is small enough to compare.
fn small_value(root: Root<'_>) -> Option<Value> {
    match root {
        Root::Tree(value) => {
            let mut budget = 10_000;
            is_small(value, &mut budget).then(|| value.clone())
        }
        Root::Lazy(node) => {
            if node.byte_len() > 1024 * 1024 {
                None
            } else {
                node.to_value(usize::MAX).ok()
            }
        }
    }
}

impl Doc {
    pub fn is_lazy(&self) -> bool {
        self.0.is_lazy()
    }

    pub fn byte_len(&self) -> u64 {
        self.0.byte_len
    }

    pub fn top_level_values(&self) -> usize {
        self.0.top_level_values
    }

    /// How long the loader says it took (reading and parsing, or scanning and indexing).
    pub fn parse_ms(&self) -> f64 {
        self.0.parse_time.as_secs_f64() * 1e3
    }

    /// What the index of a lazy document takes.
    pub fn index_bytes(&self) -> Option<usize> {
        self.0.lazy().map(|tree| tree.index_bytes())
    }

    pub fn kind(&self) -> ValueKind {
        self.0.root().kind()
    }

    pub fn child_count(&self) -> usize {
        self.0.root().child_count()
    }

    /// The whole document as a value, if it is one (a lazy one is not).
    pub fn value(&self) -> Option<&Value> {
        self.0.tree()
    }

    /// The first and the last child of the root, when they are small enough to be compared.
    pub fn probe(&self) -> (Option<Value>, Option<Value>) {
        let root = self.0.root();
        let n = root.child_count();
        (
            root.child_at(0).and_then(small_value),
            root.child_at(n.saturating_sub(1)).and_then(small_value),
        )
    }

    /// The rows the tree widget makes for a document that has just been opened: in runs for a
    /// document kept on disk, which has lists no one could scroll (`TreeView::refresh`).
    pub fn rows_initial(&self) -> Vec<RowInfo> {
        let expand = new_expanded_at_root();
        if self.is_lazy() {
            flatten_grouped(self.0.root(), &expand, &GroupState::new())
        } else {
            flatten_visible(self.0.root(), &expand)
        }
    }

    /// The rows after "Find in Source" has revealed `path`: every container on the way open, and
    /// for a document kept on disk the runs that hold it.
    pub fn rows_reveal(&self, path: &NodePath) -> Vec<RowInfo> {
        let mut expand = new_expanded_at_root();
        for i in 0..=path.len() {
            expand.insert(path[..i].to_vec());
        }
        let root = self.0.root();
        if self.is_lazy() {
            let groups: GroupState = groups_containing(root, path).into_iter().collect();
            flatten_grouped(root, &expand, &groups)
        } else {
            flatten_visible(root, &expand)
        }
    }

    /// The rows with each of `open` (and what is above it) expanded, as clicks make them.
    pub fn rows_expanded(&self, open: &[NodePath]) -> Vec<RowInfo> {
        let mut expand: ExpandState = new_expanded_at_root();
        for path in open {
            for i in 0..=path.len() {
                expand.insert(path[..i].to_vec());
            }
        }
        let root = self.0.root();
        if self.is_lazy() {
            flatten_grouped(root, &expand, &GroupState::new())
        } else {
            flatten_visible(root, &expand)
        }
    }

    /// The row text of the node at `path`, if it is a scalar.
    pub fn resolve_preview(&self, path: &NodePath) -> Option<String> {
        jsonquery_core::resolve(self.0.root(), path).and_then(|r| r.scalar_preview())
    }

    /// The node at `path` as a value, when it is small.
    pub fn resolve_value(&self, path: &NodePath) -> Option<Value> {
        jsonquery_core::resolve(self.0.root(), path).and_then(small_value)
    }

    /// How many children of the root there are of each kind, walking all of them:
    /// null, bool, number, string, array, object.
    pub fn tally_children(&self) -> [u64; 6] {
        let mut tally = [0u64; 6];
        for (_, child) in self.0.root().iter_children() {
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
        match &self.0.content {
            Content::Tree(value) => kind.engine().run(value, text, cancel, &mut on_event),
            Content::Lazy(tree) => {
                jsonquery_query::lazy::run(kind, tree, text, cancel, &mut on_event)
            }
        }
        .map_err(Fail::err)?;
        Ok(run)
    }

    pub fn search(&self, text: &str, regex: bool) -> Result<Vec<NodePath>, Fail> {
        match self.0.root() {
            Root::Tree(value) => jsonquery_core::search(value, text, regex),
            Root::Lazy(node) => jsonquery_core::lazy::search(node, text, regex),
        }
        .map_err(|e| Fail::err(format!("{e:#}")))
    }

    pub fn locate(&self, target: &Value, nth: usize, rel: &NodePath) -> SourceMatches {
        jsonquery_core::locate(self.0.root(), target, nth, rel)
    }

    /// The Text view's rendering of the document.
    pub fn text_view(&self, nodes: usize) -> (String, bool) {
        match self.0.root() {
            Root::Tree(value) => jsonquery_core::pretty_print_bounded(value, nodes),
            Root::Lazy(node) => node.to_pretty_string(PrettyLimits {
                nodes,
                bytes: TEXT_VIEW_BYTES,
                string_bytes: TEXT_VIEW_STRING_BYTES,
            }),
        }
    }

    fn resolve_root(&self, path: Option<&NodePath>) -> Result<Root<'_>, Fail> {
        match path {
            Some(p) => jsonquery_core::resolve(self.0.root(), p)
                .ok_or_else(|| Fail::err("that value is no longer part of the document")),
            None => Ok(self.0.root()),
        }
    }

    /// What "Copy to Clipboard" makes of the document, or of the node at `path`.
    pub fn copy_text(&self, path: Option<&NodePath>) -> Result<String, Fail> {
        match self.resolve_root(path)? {
            Root::Tree(value) => serde_json::to_string_pretty(value).map_err(Fail::err),
            Root::Lazy(node) => {
                if node.byte_len() > COPY_LIMIT {
                    return Err(Fail::err(format!(
                        "that value is {} bytes, too big to copy: use Save… to write it to a file",
                        node.byte_len()
                    )));
                }
                Ok(node.to_pretty_string(PrettyLimits::default()).0)
            }
        }
    }

    /// What "Save…" does with the document, or the node at `path`: returns the bytes written.
    pub fn save(&self, path: Option<&NodePath>, out: &Path) -> Result<u64, Fail> {
        match self.resolve_root(path)? {
            Root::Tree(value) => {
                let file = File::create(out).map_err(Fail::err)?;
                serde_json::to_writer_pretty(BufWriter::new(file), value).map_err(Fail::err)?;
            }
            Root::Lazy(node) => {
                let file = File::create(out).map_err(Fail::err)?;
                let mut writer = BufWriter::with_capacity(1 << 20, file);
                node.write_pretty(&mut writer, PrettyLimits::default())
                    .and_then(|_| writer.flush())
                    .map_err(Fail::err)?;
            }
        }
        std::fs::metadata(out).map(|m| m.len()).map_err(Fail::err)
    }

    /// What the query box offers as completions of `text` (the cursor at its end).
    pub fn suggest(&self, text: &str) -> Vec<String> {
        jsonquery_query::suggest(text, text.len(), None, Some(self.0.suggestion_root()))
            .into_iter()
            .map(|s| s.label)
            .collect()
    }

    /// The Tools window's Format of a document kept on disk, written a piece at a time
    /// (two spaces to a level): returns the bytes written.
    pub fn format_stream(&self, out: &mut dyn Write) -> Result<u64, Fail> {
        let Root::Lazy(node) = self.0.root() else {
            return Err(Fail::Unsupported(
                "this document is in memory, and is formatted there".into(),
            ));
        };
        let style = Style {
            indent: Indent::Spaces(2),
            ascii_only: false,
        };
        let mut out = BufWriter::with_capacity(1 << 20, out);
        let written = node
            .write_styled(&mut out, style, PrettyLimits::default())
            .map_err(Fail::err)?;
        out.flush().map_err(Fail::err)?;
        Ok(written.bytes as u64)
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
