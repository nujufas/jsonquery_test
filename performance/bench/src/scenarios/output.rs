//! Getting a document, or a part of it, out: the Text view, "Copy to Clipboard" and "Save…". A
//! parsed document is serialized from its tree; one kept on disk is written out of its file a piece
//! at a time (and a copy of more than 64 MiB of it is refused, with "Save…" offered instead).

use super::*;

const SHAPES: &[&str] = &["records", "ndjson", "wide", "strings", "numbers", "nested"];

pub fn add(out: &mut Vec<Scenario>) {
    out.push(Scenario::new(
        "text.render_source",
        "output",
        "The Text view of the document: the first 20,000 nodes as indented text",
        SHAPES,
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let (text, truncated) = m.time(|| Ok(doc.text_view(TEXT_VIEW_NODE_BUDGET)))?;
            let mut fp = fp_text(&text, "text");
            fp.hash ^= u64::from(truncated);
            Ok(fp)
        },
    ));

    out.push(Scenario::new(
        "copy.row",
        "output",
        "\"Copy to Clipboard\" of one element from the middle of the root list",
        &["records", "ndjson", "numbers", "strings"],
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let path: NodePath = vec![PathSegment::Index(doc.child_count() / 2)];
            let text = m.time(|| doc.copy_text(Some(&path)))?;
            Ok(fp_text(&text, "copy"))
        },
    ));

    out.push(
        Scenario::new(
            "copy.document",
            "output",
            "\"Copy to Clipboard\" of the whole document",
            &["records", "wide", "strings", "nested"],
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let text = m.time(|| doc.copy_text(None))?;
                Ok(fp_text(&text, "copy"))
            },
        )
        .sizes(0, 400),
    );

    out.push(Scenario::new(
        "save.row",
        "output",
        "\"Save…\" of one element from the middle of the root list",
        &["records", "ndjson", "numbers", "strings"],
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let path: NodePath = vec![PathSegment::Index(doc.child_count() / 2)];
            let file = ctx.scratch("row.json");
            let written = m.time(|| {
                doc.save(Some(&path), &file)?;
                Ok(Scratch(file.clone()))
            })?;
            fp_file(&written.0, "save")
        },
    ));

    out.push(
        Scenario::new(
            "save.document",
            "output",
            "\"Save…\" of the whole document, pretty-printed, to a file",
            SHAPES,
            |ctx, m| {
                let doc = m.setup(|| ctx.load())?;
                m.extra("doc", doc_info(&doc));
                let file = ctx.scratch("document.json");
                let written = m.time(|| {
                    doc.save(None, &file)?;
                    Ok(Scratch(file.clone()))
                })?;
                fp_file(&written.0, "save")
            },
        )
        .sizes(0, 1100),
    );

    out.push(Scenario::new(
        "save.results",
        "output",
        "\"Save…\" of results: the first 50,000 records of a query, pretty-printed (the same code in every revision)",
        &["records"],
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let cancel = std::sync::atomic::AtomicBool::new(false);
            let run = doc.query(Kind::Jq, ".[0:50000]", &cancel)?;
            let results = serde_json::Value::Array(run.kept);
            let file = ctx.scratch("results.json");
            let written = m.time(|| {
                let out = std::fs::File::create(&file).map_err(Fail::err)?;
                serde_json::to_writer_pretty(std::io::BufWriter::new(out), &results)
                    .map_err(Fail::err)?;
                Ok(Scratch(file.clone()))
            })?;
            fp_file(&written.0, "save")
        },
    ));
}
