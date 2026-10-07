//! Queries, in the four languages the app has. On a parsed document the query runs on the whole
//! value (jq: after the document is turned into jaq's own values, which takes time in proportion to
//! its size whatever the query is); on one kept on disk the query is planned and the parts that can
//! be are walked in the file, with threads.
//!
//! The queries are the sort a person types into the query box: a place in a list, a count, a
//! filter, a sort, a group, a stream of all the values of a field.

use super::*;
use crate::meta::Meta;

type Text = fn(&Meta) -> String;

struct Q {
    id: &'static str,
    engine: Kind,
    kinds: &'static [&'static str],
    title: &'static str,
    text: Text,
    /// Limits on the size of the dataset (MiB).
    sizes: (u64, u64),
}

const RECORDS: &[&str] = &["records", "ndjson"];
const R: &[&str] = &["records"];
const ANY: (u64, u64) = (0, u64::MAX);

fn mid(meta: &Meta) -> u64 {
    meta.u("mid")
}

fn queries() -> Vec<Q> {
    use Kind::*;
    vec![
        // ---- jq on a list of records ----------------------------------------------------
        Q { id: "query.jq.index_mid", engine: Jq, kinds: RECORDS, title: "jq: one element from the middle of the list", text: |m| format!(".[{}]", mid(m)), sizes: ANY },
        Q { id: "query.jq.index_last", engine: Jq, kinds: R, title: "jq: the last element", text: |_| ".[-1]".into(), sizes: ANY },
        Q { id: "query.jq.length", engine: Jq, kinds: RECORDS, title: "jq: how many elements", text: |_| "length".into(), sizes: ANY },
        Q { id: "query.jq.slice_head", engine: Jq, kinds: R, title: "jq: the first hundred elements", text: |_| ".[0:100]".into(), sizes: ANY },
        Q { id: "query.jq.first_early", engine: Jq, kinds: R, title: "jq: first(...) that is found almost at once", text: |_| "first(.[] | select(.qty == 50))".into(), sizes: ANY },
        Q { id: "query.jq.first_mid", engine: Jq, kinds: R, title: "jq: first(...) that is found in the middle", text: |m| format!("first(.[] | select(.id == {}))", mid(m)), sizes: ANY },
        Q { id: "query.jq.limit_active", engine: Jq, kinds: R, title: "jq: limit(100; ...) over a filter", text: |_| "limit(100; .[] | select(.active))".into(), sizes: ANY },
        Q { id: "query.jq.select_one", engine: Jq, kinds: RECORDS, title: "jq: filter the whole list for one record and take a field", text: |m| format!(".[] | select(.id == {}) | .name", mid(m)), sizes: ANY },
        Q { id: "query.jq.select_count", engine: Jq, kinds: R, title: "jq: count the records that pass a filter", text: |_| "map(select(.qty > 90)) | length".into(), sizes: ANY },
        Q { id: "query.jq.map_len", engine: Jq, kinds: R, title: "jq: map a field over every record", text: |_| "map(.id) | length".into(), sizes: ANY },
        Q { id: "query.jq.sum", engine: Jq, kinds: R, title: "jq: add up a field of every record", text: |_| "map(.score) | add".into(), sizes: ANY },
        Q { id: "query.jq.sort_by_head", engine: Jq, kinds: RECORDS, title: "jq: sort_by a field and take the first three", text: |_| "sort_by(.score) | .[0:3]".into(), sizes: ANY },
        Q { id: "query.jq.group_by_count", engine: Jq, kinds: RECORDS, title: "jq: group_by a field and count the groups", text: |_| "group_by(.k) | length".into(), sizes: ANY },
        Q { id: "query.jq.unique_count", engine: Jq, kinds: R, title: "jq: the distinct values of a field", text: |_| "map(.k) | unique | length".into(), sizes: ANY },
        Q { id: "query.jq.min_by", engine: Jq, kinds: R, title: "jq: the record with the lowest value of a field", text: |_| "min_by(.score) | .id".into(), sizes: ANY },
        Q { id: "query.jq.stream_names", engine: Jq, kinds: RECORDS, title: "jq: a stream of one field of every record (the panel keeps the first 50,000)", text: |_| ".[] | .name".into(), sizes: ANY },
        Q { id: "query.jq.regex_count", engine: Jq, kinds: R, title: "jq: a regular expression over a field of every record", text: |_| "[.[] | select(.name | test(\"-12345$\"))] | length".into(), sizes: ANY },
        Q { id: "query.jq.object_compose", engine: Jq, kinds: R, title: "jq: an object made of a few parts of the list", text: |_| "{count: length, first: .[0].id, last: .[-1].id}".into(), sizes: ANY },
        Q { id: "query.jq.first_keys", engine: Jq, kinds: R, title: "jq: the keys of the first record", text: |_| ".[0] | keys".into(), sizes: ANY },
        Q { id: "query.jq.recursive_find", engine: Jq, kinds: R, title: "jq: first(..) over the whole document for a string", text: |m| format!("first(.. | select(type == \"string\" and . == \"{}\"))", m.s("mid_name")), sizes: ANY },
        // ---- jq on the other shapes -----------------------------------------------------
        Q { id: "query.jq.num_add", engine: Jq, kinds: &["numbers"], title: "jq: add up a list of numbers", text: |_| "add".into(), sizes: ANY },
        Q { id: "query.jq.num_max", engine: Jq, kinds: &["numbers"], title: "jq: the largest of a list of numbers", text: |_| "max".into(), sizes: ANY },
        Q { id: "query.jq.num_length", engine: Jq, kinds: &["numbers"], title: "jq: how many numbers", text: |_| "length".into(), sizes: ANY },
        Q { id: "query.jq.num_index_mid", engine: Jq, kinds: &["numbers"], title: "jq: a number from the middle", text: |m| format!(".[{}]", mid(m)), sizes: ANY },
        Q { id: "query.jq.num_map_add", engine: Jq, kinds: &["numbers"], title: "jq: double every number and add them up", text: |_| "map(. * 2) | add".into(), sizes: ANY },
        Q { id: "query.jq.str_length_one", engine: Jq, kinds: &["strings"], title: "jq: the length of one long string", text: |m| format!(".[{}] | length", m.u("needle_index")), sizes: ANY },
        Q { id: "query.jq.str_slice", engine: Jq, kinds: &["strings"], title: "jq: the start of one long string", text: |m| format!(".[{}] | .[0:40]", m.u("needle_index")), sizes: ANY },
        Q { id: "query.jq.str_lengths_sum", engine: Jq, kinds: &["strings"], title: "jq: the length of every long string, added up", text: |_| "map(length) | add".into(), sizes: ANY },
        Q { id: "query.jq.str_select_needle", engine: Jq, kinds: &["strings"], title: "jq: the strings that contain a text", text: |_| ".[] | select(contains(\"needle-\")) | length".into(), sizes: ANY },
        Q { id: "query.jq.obj_key_mid", engine: Jq, kinds: &["wide"], title: "jq: one member of a huge object by its key", text: |m| format!(".[\"{}\"]", m.s("mid_key")), sizes: ANY },
        Q { id: "query.jq.obj_keys_len", engine: Jq, kinds: &["wide"], title: "jq: how many keys a huge object has", text: |_| "keys | length".into(), sizes: ANY },
        Q { id: "query.jq.obj_values_count", engine: Jq, kinds: &["wide"], title: "jq: gather every member of a huge object", text: |_| "[.[]] | length".into(), sizes: ANY },
        Q { id: "query.jq.tree_path", engine: Jq, kinds: &["nested"], title: "jq: a path of constant steps into a catalog", text: |_| ".catalog.categories[3].products[10].title".into(), sizes: ANY },
        Q { id: "query.jq.tree_prices_over", engine: Jq, kinds: &["nested"], title: "jq: count the products over a price", text: |_| "[.catalog.categories[].products[] | select(.price > 90)] | length".into(), sizes: ANY },
        Q { id: "query.jq.tree_all_skus", engine: Jq, kinds: &["nested"], title: "jq: every sku, found by recursive descent", text: |_| "[.. | .sku? // empty] | length".into(), sizes: ANY },
        // ---- JSON Pointer ---------------------------------------------------------------
        Q { id: "query.pointer.record", engine: JsonPointer, kinds: RECORDS, title: "Pointer: a field of a record in the middle", text: |m| format!("/{}/name", mid(m)), sizes: ANY },
        Q { id: "query.pointer.member", engine: JsonPointer, kinds: &["wide"], title: "Pointer: a member of a huge object", text: |m| format!("/{}/v", m.s("mid_key")), sizes: ANY },
        Q { id: "query.pointer.deep", engine: JsonPointer, kinds: &["nested"], title: "Pointer: a deep path into a catalog", text: |_| "/catalog/categories/3/products/10/title".into(), sizes: ANY },
        // ---- JSONPath -------------------------------------------------------------------
        Q { id: "query.jsonpath.index_field", engine: JsonPath, kinds: R, title: "JSONPath: a field of a record in the middle", text: |m| format!("$[{}].name", mid(m)), sizes: ANY },
        Q { id: "query.jsonpath.filter", engine: JsonPath, kinds: R, title: "JSONPath: a filter over the whole list", text: |_| "$[?(@.qty > 98)].id".into(), sizes: ANY },
        Q { id: "query.jsonpath.wildcard", engine: JsonPath, kinds: R, title: "JSONPath: a field of every record", text: |_| "$[*].id".into(), sizes: ANY },
        Q { id: "query.jsonpath.descendants", engine: JsonPath, kinds: &["nested"], title: "JSONPath: every sku, found by recursive descent", text: |_| "$..sku".into(), sizes: ANY },
        Q { id: "query.jsonpath.deep", engine: JsonPath, kinds: &["nested"], title: "JSONPath: the titles of the products of one category", text: |_| "$.catalog.categories[3].products[*].title".into(), sizes: ANY },
        // ---- JMESPath -------------------------------------------------------------------
        Q { id: "query.jmespath.index_field", engine: JmesPath, kinds: R, title: "JMESPath: a field of a record in the middle", text: |m| format!("[{}].name", mid(m)), sizes: ANY },
        Q { id: "query.jmespath.length", engine: JmesPath, kinds: R, title: "JMESPath: how many elements", text: |_| "length(@)".into(), sizes: ANY },
        Q { id: "query.jmespath.filter_count", engine: JmesPath, kinds: R, title: "JMESPath: filter the whole list and count", text: |_| "[?qty > `98`].id | length(@)".into(), sizes: ANY },
        Q { id: "query.jmespath.project", engine: JmesPath, kinds: R, title: "JMESPath: a field of every record, and how many", text: |_| "[*].id | length(@)".into(), sizes: ANY },
        Q { id: "query.jmespath.max_by", engine: JmesPath, kinds: R, title: "JMESPath: the record with the highest value of a field (needs the whole list)", text: |_| "max_by(@, &score).id".into(), sizes: ANY },
        Q { id: "query.jmespath.deep", engine: JmesPath, kinds: &["nested"], title: "JMESPath: a deep path into a catalog", text: |_| "catalog.categories[3].products[10].title".into(), sizes: ANY },
    ]
}

/// How long a query is let run before it is cancelled.
const CANCEL_AFTER: std::time::Duration = std::time::Duration::from_millis(50);

pub fn add(out: &mut Vec<Scenario>) {
    // Cancelling: the results panel's Cancel stops a query that is taking long. A document that is
    // a value is first turned into jq's own values, which cannot be stopped half way, so it stops
    // when that is done; a document kept on disk is looked at in pieces, and stops at the next.
    out.push(
        Scenario::new(
            "query.cancel_latency",
            "query",
            "Cancel a query that reads the whole list after 50 ms: how long until it stops",
            R,
            |ctx, m| {
                use std::sync::atomic::{AtomicBool, Ordering};
                use std::time::Instant;

                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let program = ".[] | select(.id == -1)";
                m.extra("query", serde_json::Value::String(program.to_owned()));
                m.extra("cancelled_after_ms", serde_json::json!(CANCEL_AFTER.as_millis() as u64));
                let items = m.time_reported(|| {
                    let cancel = AtomicBool::new(false);
                    let (result, latency) = std::thread::scope(|scope| {
                        let flag = &cancel;
                        let canceller = scope.spawn(move || {
                            std::thread::sleep(CANCEL_AFTER);
                            let at = Instant::now();
                            flag.store(true, Ordering::SeqCst);
                            at
                        });
                        let result = doc.query(Kind::Jq, program, &cancel);
                        let finished = Instant::now();
                        let at = canceller.join().expect("the thread that cancels does not panic");
                        (result, finished.saturating_duration_since(at))
                    });
                    Ok((result?.items, latency))
                })?;
                Ok(Fingerprint::new("cancel", "results", items, items))
            },
        )
        .sizes(16, u64::MAX),
    );

    for q in queries() {
        let Q { id, engine, kinds, title, text, sizes } = q;
        let scenario = Scenario::new(id, "query", title, kinds, move |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let program = text(&ctx.meta);
            m.extra("query", serde_json::Value::String(program.clone()));
            let cancel = std::sync::atomic::AtomicBool::new(false);
            let run = m.time(|| doc.query(engine, &program, &cancel))?;
            if run.item_errors > 0 {
                // Not a failure of the scenario: the results panel shows such an error where a result would be.
                m.extra("item_errors", serde_json::json!(run.item_errors));
                m.extra("first_item_error", serde_json::json!(run.first_error));
            }
            Ok(fp_query(&run))
        })
        .sizes(sizes.0, sizes.1);
        out.push(scenario);
    }
}
