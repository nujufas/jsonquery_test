//! "Search…" and "Find in Source": looking through the whole tree for a key or a value. A parsed
//! document is walked as values (every string lower-cased to be compared); one kept on disk is
//! looked at where it is in the file, with `memchr` on the bytes of a key or a string.

use super::*;
use crate::meta::Meta;

type Text = fn(&Meta) -> String;

fn search_case(
    out: &mut Vec<Scenario>,
    id: &str,
    title: &str,
    kinds: &[&'static str],
    regex: bool,
    text: Text,
) {
    out.push(Scenario::new(id, "search", title, kinds, move |ctx, m| {
        let doc = m.setup(|| ctx.load())?;
        m.extra("doc", doc_info(&doc));
        let needle = text(&ctx.meta);
        m.extra("needle", serde_json::Value::String(needle.clone()));
        let hits = m.time(|| doc.search(&needle, regex))?;
        Ok(fp_paths(&hits, "search"))
    }));
}

pub fn add(out: &mut Vec<Scenario>) {
    search_case(
        out,
        "search.key_common",
        "Search for a key that every record has (the search stops at its 5,000th hit)",
        &["records", "ndjson"],
        false,
        |_| "geo".to_owned(),
    );
    search_case(
        out,
        "search.value_once",
        "Search for a text that is in the document once, in the middle of it",
        &["records", "ndjson", "strings", "nested"],
        false,
        |meta| match meta.kind().as_str() {
            "strings" => meta.s("needle"),
            "nested" => meta.s("sku_mid"),
            _ => meta.s("mid_name"),
        },
    );
    search_case(
        out,
        "search.key_once",
        "Search for a key that is in a huge object once, in the middle of it",
        &["wide"],
        false,
        |meta| meta.s("mid_key"),
    );
    search_case(
        out,
        "search.value_absent",
        "Search for a text that is not in the document, so that all of it is looked at",
        &["records", "ndjson", "strings", "nested", "wide", "numbers"],
        false,
        |meta| meta.s("absent"),
    );
    search_case(
        out,
        "search.regex_once",
        "Search with a regular expression that matches one text, in the middle of the document",
        &["records", "ndjson", "strings", "nested"],
        true,
        |meta| match meta.kind().as_str() {
            "strings" => "needle-[0-9a-f]{8}".to_owned(),
            "nested" => format!("^{}$", meta.s("sku_mid")),
            _ => format!("^{}$", meta.s("mid_name")),
        },
    );
    search_case(
        out,
        "search.regex_absent",
        "Search with a regular expression that matches nothing, so that all of it is looked at",
        &["records", "ndjson", "strings", "nested", "wide", "numbers"],
        true,
        |_| "zzz[0-9]+absent".to_owned(),
    );

    out.push(
        Scenario::new(
            "search.locate_equal",
            "search",
            "\"Find in Source\" for a result that is a whole record from the middle: every node that equals it",
            &["records", "ndjson"],
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let mid = ctx.meta.u("mid") as usize;
                let target = doc
                    .resolve_value(&vec![PathSegment::Index(mid)])
                    .ok_or_else(|| Fail::err("no record in the middle of the document"))?;
                let rel: NodePath = Vec::new();
                let found = m.time(|| Ok(doc.locate(&target, 0, &rel)))?;
                let mut fp = fp_paths(&found.paths, "locate");
                let mut h = Fnv::new();
                h.u64(fp.hash);
                h.str(found.searched_for.as_deref().unwrap_or(""));
                fp.hash = h.finish();
                Ok(fp)
            },
        )
        .sizes(0, 1100),
    );
}
