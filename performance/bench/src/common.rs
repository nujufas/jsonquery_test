//! Types the scenarios and both adapters share.

use serde_json::Value;

pub use jsonquery_core::{NodePath, PathSegment, RowInfo, SourceMatches, ValueKind};
pub use jsonquery_query::Kind;

/// How a file is brought in: what the app does by itself (`Auto`: parsed below 256 MiB, kept on
/// disk from there), or forced one way, to compare the two on the same file.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Mode {
    Auto,
    Parsed,
    Lazy,
}

impl Mode {
    pub fn parse(text: &str) -> Option<Self> {
        match text {
            "auto" => Some(Mode::Auto),
            "parsed" => Some(Mode::Parsed),
            "lazy" => Some(Mode::Lazy),
            _ => None,
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            Mode::Auto => "auto",
            Mode::Parsed => "parsed",
            Mode::Lazy => "lazy",
        }
    }
}

/// Why a scenario made nothing.
#[derive(Debug)]
pub enum Fail {
    /// The revision under test refused, or went wrong. Worth reading.
    Error(String),
    /// The revision under test has no way to do this at all (a function that was not there yet).
    Unsupported(String),
}

impl Fail {
    pub fn err(text: impl std::fmt::Display) -> Self {
        Fail::Error(text.to_string())
    }
}

/// What the app keeps of a query's results (the "live preview"): the results panel holds this
/// many and counts the rest.
pub const LIVE_PREVIEW_CAP: usize = 50_000;
/// How many nodes the Text view renders of a document.
pub const TEXT_VIEW_NODE_BUDGET: usize = 20_000;
/// The largest "Copy to Clipboard" of a document kept on disk (the default of the setting).
#[allow(dead_code)] // only a revision that keeps documents on disk has such a limit
pub const COPY_LIMIT: usize = 64 * 1024 * 1024;

/// What a query made, as the results panel receives it.
#[derive(Default)]
pub struct QueryRun {
    /// Results, and per-item errors, counted all the way.
    pub items: u64,
    pub item_errors: u64,
    /// What the first of those errors said (a refusal, for a query the file cannot answer, comes as one).
    pub first_error: Option<String>,
    /// The first `LIVE_PREVIEW_CAP` results, which are what the panel holds.
    pub kept: Vec<Value>,
}

/// A node of a document, for a probe: the same small value in any revision, if it is small.
pub fn is_small(value: &Value, budget: &mut usize) -> bool {
    if *budget == 0 {
        return false;
    }
    *budget -= 1;
    match value {
        Value::Array(items) => items.iter().all(|v| is_small(v, budget)),
        Value::Object(map) => map.values().all(|v| is_small(v, budget)),
        _ => true,
    }
}
