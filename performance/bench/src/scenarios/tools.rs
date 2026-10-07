//! The Tools window: Format, Diff, Patch, Validate and Merge work on whole values in memory, so they
//! only take a document that is parsed (the app refuses one of more than 128 MB). Their algorithms
//! are the same code in every revision; what they stand on is how the document was loaded, and these
//! scenarios are there to show that nothing changed under them. Format of a document kept on disk is
//! new: it is written out of the file a piece at a time.

use std::sync::atomic::AtomicBool;

use jsonquery_query::reformat::{self, Indent, Options};
use serde_json::{json, Value};

use super::*;

const SHAPES: &[&str] = &["records", "ndjson", "wide", "nested"];

/// The parsed value of a document, or the reason there is none.
fn value_of(doc: &api::Doc) -> Result<&Value, Fail> {
    doc.value()
        .ok_or_else(|| Fail::err("the document is kept on disk, and the Tools do not take one"))
}

/// A copy of `value` with some of its elements changed, for Diff and Patch: every 997th element
/// of a list at the root of `records`, or the first few members of anything else.
fn edited(value: &Value) -> Value {
    let mut copy = value.clone();
    match &mut copy {
        Value::Array(items) => {
            for (i, item) in items.iter_mut().enumerate() {
                if i % 997 == 0 {
                    if let Value::Object(map) = item {
                        map.insert("edited".to_owned(), Value::Bool(true));
                    }
                }
            }
        }
        Value::Object(map) => {
            let keys: Vec<String> = map.keys().take(5).cloned().collect();
            for key in keys {
                map.insert(key, json!("edited"));
            }
        }
        _ => {}
    }
    copy
}

pub fn add(out: &mut Vec<Scenario>) {
    out.push(
        Scenario::new(
            "tools.format_parsed",
            "tools",
            "Format: lay a parsed document out as text (two spaces, keys as they are)",
            SHAPES,
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let value = value_of(&doc)?;
                let options = Options::default();
                let text = m.time(|| Ok(reformat::render(value, &options)))?;
                Ok(fp_text(&text, "format"))
            },
        )
        .sizes(0, 128),
    );

    out.push(
        Scenario::new(
            "tools.format_sorted",
            "tools",
            "Format: the same, with every object's keys put in order",
            &["records", "nested"],
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let value = value_of(&doc)?;
                let options = Options {
                    indent: Indent::Spaces(4),
                    sort_keys: true,
                    ascii_only: false,
                };
                let text = m.time(|| Ok(reformat::render(value, &options)))?;
                Ok(fp_text(&text, "format-sorted"))
            },
        )
        .sizes(0, 64),
    );

    out.push(
        Scenario::new(
            "tools.format_stream",
            "tools",
            "Format of a document kept on disk: laid out from the file and written a piece at a time",
            &["records", "ndjson", "wide", "strings", "numbers", "nested"],
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let bytes = m.time(|| doc.format_stream(&mut std::io::sink()))?;
                Ok(Fingerprint::new("format-stream", "bytes", bytes, bytes))
            },
        )
        .sizes(256, u64::MAX)
        .lazy_only(),
    );

    out.push(
        Scenario::new(
            "tools.diff",
            "tools",
            "Diff: two documents that differ in a few places, compared and laid out side by side",
            &["records", "nested"],
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let a = value_of(&doc)?;
                let b = m.setup(|| Ok(edited(a)))?;
                let cancel = AtomicBool::new(false);
                let comparison = m.time(|| {
                    jsonquery_query::diff::compare(a, &b, &cancel).map_err(|_| Fail::err("cancelled"))
                })?;
                let mut h = Fnv::new();
                h.value(&comparison.diff.patch());
                Ok(Fingerprint::new(
                    "diff",
                    "changes",
                    comparison.diff.total() as u64,
                    h.finish(),
                ))
            },
        )
        .sizes(0, 16),
    );

    out.push(
        Scenario::new(
            "tools.patch",
            "tools",
            "Patch: apply fifty replace operations (RFC 6902) to a document",
            &["records"],
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let value = value_of(&doc)?;
                let n = ctx.meta.u("count").max(1);
                let operations: Vec<Value> = (0..50u64)
                    .map(|i| {
                        json!({
                            "op": "replace",
                            "path": format!("/{}/name", i * (n / 50)),
                            "value": "patched"
                        })
                    })
                    .collect();
                let patch = Value::Array(operations);
                let patched = m.time_each(
                    || Ok(value.clone()),
                    |copy| {
                        jsonquery_query::patch::apply(copy, &patch)
                            .map_err(|e| Fail::err(e.to_string()))
                    },
                )?;
                let mut h = Fnv::new();
                for i in 0..50u64 {
                    h.value(&patched[(i * (n / 50)) as usize]);
                }
                Ok(Fingerprint::new("patch", "operations", 50, h.finish()))
            },
        )
        .sizes(0, 64),
    );

    out.push(
        Scenario::new(
            "tools.validate",
            "tools",
            "Validate: check every record of a list against a JSON Schema",
            &["records"],
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let value = value_of(&doc)?;
                let schema = json!({
                    "type": "array",
                    "items": {
                        "type": "object",
                        "required": ["id", "name", "k"],
                        "properties": {
                            "id": {"type": "integer", "minimum": 0},
                            "name": {"type": "string"},
                            "qty": {"type": "integer", "maximum": 98}
                        }
                    }
                });
                let cancel = AtomicBool::new(false);
                let report = m.time(|| {
                    jsonquery_query::schema::validate(
                        &schema,
                        value,
                        jsonquery_query::schema::Options::default(),
                        &cancel,
                    )
                    .map_err(|e| Fail::err(e.to_string()))
                })?;
                let mut h = Fnv::new();
                h.u64(report.problems.len() as u64);
                for problem in &report.problems {
                    h.str(&format!("{problem:?}"));
                }
                Ok(Fingerprint::new(
                    "validate",
                    "problems",
                    report.problems.len() as u64,
                    h.finish(),
                ))
            },
        )
        .sizes(0, 64),
    );

    out.push(
        Scenario::new(
            "tools.merge",
            "tools",
            "Merge: append two copies of a document with jq's add, and render the preview",
            &["records"],
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let value = value_of(&doc)?;
                let names = vec!["a.json".to_owned(), "b.json".to_owned()];
                let cancel = AtomicBool::new(false);
                let (outputs, preview) = m.time_each(
                    || Ok(vec![value.clone(), value.clone()]),
                    |inputs| {
                        let merged = jsonquery_query::merge::merge(inputs, &names, "add", &cancel)
                            .map_err(|e| Fail::err(e.to_string()))?;
                        let (preview, _) = jsonquery_core::pretty_print_bounded(&merged.value, 600);
                        Ok((merged.outputs, preview))
                    },
                )?;
                Ok(fp_text(&preview, "merge").with_count(outputs as u64, "outputs"))
            },
        )
        .sizes(0, 64),
    );
}
