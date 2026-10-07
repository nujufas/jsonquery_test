//! The things together: what a person waits for between choosing a file and having something to read.

use std::sync::atomic::AtomicBool;

use super::*;

pub fn add(out: &mut Vec<Scenario>) {
    out.push(Scenario::new(
        "workflow.open_browse_query",
        "workflow",
        "Open a file, make the first rows of its tree and ask two first queries: what a person waits for",
        &["records", "ndjson", "wide"],
        |ctx, m| {
            let (second, wide) = if ctx.meta.kind() == "wide" {
                (format!(".[\"{}\"]", ctx.meta.s("mid_key")), true)
            } else {
                (format!(".[{}]", ctx.meta.u("mid")), false)
            };
            m.extra("queries", serde_json::json!(["length", second]));
            let cancel = AtomicBool::new(false);
            let (doc, rows, first, second) = m.time(|| {
                let doc = ctx.load()?;
                let rows = doc.rows_initial();
                let first = doc.query(Kind::Jq, "length", &cancel)?;
                let second = doc.query(Kind::Jq, &second, &cancel)?;
                Ok((doc, rows, first, second))
            })?;
            m.extra("doc", doc_info(&doc));
            m.extra("rows", serde_json::json!(rows.len()));
            // The rows are not what is compared (a document kept on disk has them in runs): the answers are.
            let mut h = Fnv::new();
            h.u64(fp_query(&first).hash);
            h.u64(fp_query(&second).hash);
            h.u64(u64::from(wide));
            let fingerprint = Fingerprint::new("workflow", "results", first.items + second.items, h.finish());
            // Not freed: the process ends, and a parsed gigabyte takes seconds to free.
            std::mem::forget(doc);
            std::mem::forget(rows);
            Ok(fingerprint)
        },
    ));
}
