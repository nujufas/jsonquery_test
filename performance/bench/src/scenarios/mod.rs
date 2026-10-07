//! The catalogue of scenarios: each is one thing the app does with a document, timed.
//!
//! A scenario names the kinds of dataset it makes sense on (and how big they may be), builds what
//! it needs (not timed), and hands the one thing it measures to the `Measurer`. What it made is
//! boiled down to a [`Fingerprint`], so that two revisions can be told to agree.

mod load;
mod output;
mod query;
mod rows;
mod search;
mod suggest;
mod tools;
mod tree;
mod workflow;

use std::path::PathBuf;

use crate::api::{self, kind_slot};
use crate::common::*;
use crate::fingerprint::{Fingerprint, Fnv};
use crate::measure::Measurer;
use crate::meta::Meta;

/// What a scenario is run with.
pub struct Ctx {
    pub file: PathBuf,
    pub meta: Meta,
    pub mode: Mode,
    /// A folder on disk for what a scenario writes.
    pub work_dir: PathBuf,
}

impl Ctx {
    /// The document, brought in as the app does (or as `mode` forces).
    pub fn load(&self) -> Result<api::Doc, Fail> {
        api::load(&self.file, self.mode)
    }

    /// A name for a file that is this process's own.
    pub fn scratch(&self, name: &str) -> PathBuf {
        self.work_dir.join(format!("jq-perf-{}-{name}", std::process::id()))
    }
}

pub type RunFn = Box<dyn Fn(&Ctx, &mut Measurer) -> Result<Fingerprint, Fail>>;

pub struct Scenario {
    pub id: String,
    pub group: &'static str,
    pub title: String,
    /// The kinds of dataset this makes sense on.
    pub kinds: Vec<&'static str>,
    /// ... and how big, in MiB.
    pub min_mib: u64,
    pub max_mib: u64,
    /// Only a revision with documents kept on disk can do this at all.
    pub needs_lazy: bool,
    pub run: RunFn,
}

impl Scenario {
    pub fn new(
        id: impl Into<String>,
        group: &'static str,
        title: impl Into<String>,
        kinds: &[&'static str],
        run: impl Fn(&Ctx, &mut Measurer) -> Result<Fingerprint, Fail> + 'static,
    ) -> Self {
        Self {
            id: id.into(),
            group,
            title: title.into(),
            kinds: kinds.to_vec(),
            min_mib: 0,
            max_mib: u64::MAX,
            needs_lazy: false,
            run: Box::new(run),
        }
    }

    pub fn sizes(mut self, min_mib: u64, max_mib: u64) -> Self {
        self.min_mib = min_mib;
        self.max_mib = max_mib;
        self
    }

    pub fn lazy_only(mut self) -> Self {
        self.needs_lazy = true;
        self
    }
}

pub fn catalogue() -> Vec<Scenario> {
    let mut all = Vec::new();
    load::add(&mut all);
    rows::add(&mut all);
    tree::add(&mut all);
    search::add(&mut all);
    query::add(&mut all);
    output::add(&mut all);
    tools::add(&mut all);
    suggest::add(&mut all);
    workflow::add(&mut all);
    all
}

/// What to say in the record about the document that was opened.
pub fn doc_info(doc: &api::Doc) -> serde_json::Value {
    serde_json::json!({
        "lazy": doc.is_lazy(),
        "bytes": doc.byte_len(),
        "top_level_values": doc.top_level_values(),
        "loader_ms": doc.parse_ms(),
        "index_bytes": doc.index_bytes(),
    })
}

// ---- fingerprints ---------------------------------------------------------------------------

fn hash_segment(h: &mut Fnv, segment: &PathSegment) {
    match segment {
        PathSegment::Key(key) => {
            h.u64(0);
            h.str(key);
        }
        PathSegment::Index(i) => {
            h.u64(1);
            h.u64(*i as u64);
        }
    }
}

pub fn hash_path(h: &mut Fnv, path: &[PathSegment]) {
    h.u64(path.len() as u64);
    for segment in path {
        hash_segment(h, segment);
    }
}

/// What opening a document made: how big it is, what its root is and what is at both ends of it.
pub fn fp_doc(doc: &api::Doc) -> Fingerprint {
    let mut h = Fnv::new();
    h.u64(doc.byte_len());
    h.u64(doc.top_level_values() as u64);
    h.u64(kind_slot(doc.kind()) as u64);
    h.u64(doc.child_count() as u64);
    let (first, last) = doc.probe();
    for end in [first, last] {
        match end {
            Some(value) => h.value(&value),
            None => h.u64(u64::MAX),
        }
    }
    Fingerprint::new("document", "children", doc.child_count() as u64, h.finish())
}

/// The rows of a tree: how many, and what the first of them say.
pub fn fp_rows(rows: &[RowInfo], basis: &str) -> Fingerprint {
    let mut h = Fnv::new();
    h.u64(rows.len() as u64);
    for row in rows.iter().take(300) {
        hash_path(&mut h, &row.path);
        h.u64(row.depth as u64);
        h.u64(kind_slot(row.kind) as u64);
        h.u64(row.child_count as u64);
        h.u64(u64::from(row.expanded));
        match &row.scalar_preview {
            Some(text) => h.str(text),
            None => h.u64(u64::MAX),
        }
    }
    Fingerprint::new(basis, "rows", rows.len() as u64, h.finish())
}

/// What a query made: how many results and errors, and the results the panel holds.
pub fn fp_query(run: &QueryRun) -> Fingerprint {
    let mut h = Fnv::new();
    h.u64(run.items);
    h.u64(run.item_errors);
    h.u64(run.kept.len() as u64);
    for value in &run.kept {
        h.value(value);
    }
    Fingerprint::new("query", "results", run.items, h.finish())
}

/// The nodes a search or a locate found.
pub fn fp_paths(paths: &[NodePath], basis: &str) -> Fingerprint {
    let mut h = Fnv::new();
    h.u64(paths.len() as u64);
    for path in paths {
        hash_path(&mut h, path);
    }
    Fingerprint::new(basis, "matches", paths.len() as u64, h.finish())
}

/// A text, whole.
pub fn fp_text(text: &str, basis: &str) -> Fingerprint {
    let mut h = Fnv::new();
    h.bytes(text.as_bytes());
    Fingerprint::new(basis, "bytes", text.len() as u64, h.finish())
}

/// A file that was written: how long it is, and its first and last bytes.
pub fn fp_file(path: &std::path::Path, basis: &str) -> Result<Fingerprint, Fail> {
    use std::io::{Read, Seek, SeekFrom};
    let mut file = std::fs::File::open(path).map_err(Fail::err)?;
    let len = file.metadata().map_err(Fail::err)?.len();
    let mut h = Fnv::new();
    h.u64(len);
    let mut buf = vec![0u8; 64 * 1024];
    let n = file.read(&mut buf).map_err(Fail::err)?;
    h.bytes(&buf[..n]);
    if len > buf.len() as u64 {
        file.seek(SeekFrom::End(-(buf.len() as i64))).map_err(Fail::err)?;
        file.read_exact(&mut buf).map_err(Fail::err)?;
        h.bytes(&buf);
    }
    Ok(Fingerprint::new(basis, "bytes", len, h.finish()))
}

/// A file that is removed when it goes out of scope: the runs of a scenario that writes one each
/// make one, and the one before is removed (outside the timing) before the next.
pub struct Scratch(pub PathBuf);

impl Drop for Scratch {
    fn drop(&mut self) {
        let _ = std::fs::remove_file(&self.0);
    }
}

/// A pseudo-random sequence that is the same everywhere (a scenario that looks up places picks the
/// same places in every revision).
pub struct Lcg(pub u64);

impl Lcg {
    pub fn next(&mut self, below: u64) -> u64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 33) % below.max(1)
    }
}
