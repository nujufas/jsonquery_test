//! Opening a document: `Document::load` and what it does with the bytes.
//!
//! Before the memory-mapped feature a file was mapped, parsed into a tree and the mapping kept;
//! after it, a file below 256 MiB is read and parsed, and one of 256 MiB or more is mapped, checked
//! once and indexed, and never parsed.

use super::*;
use crate::sysmem;

const ALL: &[&str] = &["records", "wide", "ndjson", "strings", "numbers", "nested"];

pub fn add(out: &mut Vec<Scenario>) {
    out.push(Scenario::new(
        "load.open",
        "load",
        "Open a file: read and parse it; from 256 MiB, where the revision has it, map and index it",
        ALL,
        |ctx, m| {
            let doc = m.time(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            Ok(fp_doc(&doc))
        },
    ));

    out.push(
        Scenario::new(
            "load.open_cold",
            "load",
            "Open a file whose pages are not in the page cache, so that it is read from the disk",
            ALL,
            |ctx, m| {
                if !sysmem::drop_cached(&ctx.file) {
                    m.note("the page cache could not be emptied; this is a warm open");
                }
                let doc = m.time_each(
                    || {
                        sysmem::drop_cached(&ctx.file);
                        Ok(())
                    },
                    |()| ctx.load(),
                )?;
                m.extra("doc", doc_info(&doc));
                Ok(fp_doc(&doc))
            },
        )
        .sizes(100, u64::MAX),
    );

    out.push(
        Scenario::new(
            "load.release",
            "load",
            "Let go of an open document (the one that is replaced when another file is opened)",
            ALL,
            |ctx, m| {
                let kids = m.time_each(
                    || {
                        let doc = ctx.load()?;
                        let kids = doc.child_count();
                        Ok((doc, kids))
                    },
                    |(doc, kids)| {
                        drop(doc);
                        Ok(kids)
                    },
                )?;
                Ok(Fingerprint::new("release", "children", kids as u64, kids as u64))
            },
        )
        .sizes(0, 400),
    );

    out.push(
        Scenario::new(
            "load.open_text",
            "load",
            "Parse JSON that is already in memory (pasted text): the same parser, no file",
            &["records", "wide", "nested"],
            |ctx, m| {
                let text = m.setup(|| std::fs::read_to_string(&ctx.file).map_err(Fail::err))?;
                let doc = m.time(|| api::load_text(&text))?;
                m.extra("doc", doc_info(&doc));
                Ok(fp_doc(&doc))
            },
        )
        .sizes(0, 100),
    );

    out.push(Scenario::new(
        "load.open_tiny",
        "load",
        "Open a tiny file a thousand times: what opening costs besides the bytes",
        &["tiny"],
        |ctx, m| {
            const TIMES: usize = 1000;
            m.ops = TIMES as u64;
            let kids = m.time(|| {
                let mut kids = 0;
                for _ in 0..TIMES {
                    kids += ctx.load()?.child_count();
                }
                Ok(kids)
            })?;
            Ok(Fingerprint::new("tiny", "children", kids as u64, kids as u64))
        },
    ));
}
