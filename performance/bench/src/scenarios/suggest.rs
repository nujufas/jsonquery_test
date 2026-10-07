//! Autocomplete: the query box looks into the open document for the names and indexes to offer. It
//! asks for them on every keystroke, so a document that makes it slow makes typing slow. A parsed
//! document is looked into whole; one kept on disk is given a small sample of itself instead.

use super::*;

fn add_case(out: &mut Vec<Scenario>, id: &str, title: &str, kinds: &[&'static str], text: &'static str) {
    out.push(Scenario::new(id, "suggest", title, kinds, move |ctx, m| {
        let doc = m.setup(|| ctx.load())?;
        m.extra("doc", doc_info(&doc));
        let found = m.time(|| Ok(doc.suggest(text)))?;
        let mut h = Fnv::new();
        for label in &found {
            h.str(label);
        }
        let basis = if doc.is_lazy() { "suggest/sample" } else { "suggest/whole" };
        Ok(Fingerprint::new(basis, "suggestions", found.len() as u64, h.finish()))
    }));
}

pub fn add(out: &mut Vec<Scenario>) {
    add_case(
        out,
        "suggest.field_of_element",
        "Complete a field name after `.[0].`",
        &["records", "ndjson"],
        ".[0].",
    );
    add_case(
        out,
        "suggest.field_of_all",
        "Complete a field name after `.[].` (what the elements of the list have)",
        &["records", "ndjson"],
        ".[].",
    );
    add_case(
        out,
        "suggest.object_keys",
        "Complete the key of a huge object after `.key_0`",
        &["wide"],
        ".key_0",
    );
    add_case(
        out,
        "suggest.nested_path",
        "Complete a name deep in a catalog after `.catalog.categories[0].prod`",
        &["nested"],
        ".catalog.categories[0].prod",
    );
}
