//! The data layer of the tree widget: the rows it draws. The widget builds them again whenever the
//! document or what is expanded changes; a document kept on disk has them in runs of a thousand
//! (`flatten_grouped`), a parsed one has a row for every child of an open container.

use super::*;

const ALL: &[&str] = &["records", "wide", "ndjson", "strings", "numbers", "nested"];

fn basis(doc: &api::Doc) -> &'static str {
    if doc.is_lazy() {
        "rows/grouped"
    } else {
        "rows/flat"
    }
}

pub fn add(out: &mut Vec<Scenario>) {
    out.push(Scenario::new(
        "rows.initial",
        "rows",
        "The rows of the tree for a document that has just been opened (its root open)",
        ALL,
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let rows = m.time(|| Ok(doc.rows_initial()))?;
            Ok(fp_rows(&rows, basis(&doc)))
        },
    ));

    out.push(Scenario::new(
        "rows.reveal_middle",
        "rows",
        "The rows after \"Find in Source\" reveals an element in the middle of the root list",
        &["records", "ndjson", "numbers", "strings"],
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let path: NodePath = vec![PathSegment::Index(doc.child_count() / 2)];
            let rows = m.time(|| Ok(doc.rows_reveal(&path)))?;
            Ok(fp_rows(&rows, basis(&doc)))
        },
    ));

    out.push(Scenario::new(
        "rows.deep_expand",
        "rows",
        "The rows with a branch opened down to a product's variants (a few clicks into a catalog)",
        &["nested"],
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let key = |k: &str| PathSegment::Key(k.to_owned());
            let open: Vec<NodePath> = vec![
                vec![key("catalog"), key("categories")],
                vec![key("catalog"), key("categories"), PathSegment::Index(3)],
                vec![
                    key("catalog"),
                    key("categories"),
                    PathSegment::Index(3),
                    key("products"),
                ],
                vec![
                    key("catalog"),
                    key("categories"),
                    PathSegment::Index(3),
                    key("products"),
                    PathSegment::Index(10),
                    key("variants"),
                ],
            ];
            let rows = m.time(|| Ok(doc.rows_expanded(&open)))?;
            Ok(fp_rows(&rows, basis(&doc)))
        },
    ));
}
