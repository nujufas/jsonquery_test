//! Finding things in the tree: a node by its path, a child by its key, every child in turn. This is
//! what "Save…" and "Copy" of a row, the tree widget and the search stand on. A parsed document
//! answers in nanoseconds; one kept on disk answers from its index and then the file.

use super::*;

pub fn add(out: &mut Vec<Scenario>) {
    out.push(Scenario::new(
        "tree.resolve_random",
        "tree",
        "Find the node at a path (an element of the root list, and its name): many places picked at random",
        &["records", "ndjson", "numbers", "strings"],
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let n = doc.child_count() as u64;
            let kind = ctx.meta.kind();
            let ops: u64 = if kind == "strings" { 300 } else { 2000 };
            m.ops = ops;
            let mut rng = Lcg(42);
            let paths: Vec<NodePath> = (0..ops)
                .map(|_| {
                    let i = rng.next(n) as usize;
                    if kind == "records" || kind == "ndjson" {
                        vec![PathSegment::Index(i), PathSegment::Key("name".to_owned())]
                    } else {
                        vec![PathSegment::Index(i)]
                    }
                })
                .collect();
            let hash = m.time(|| {
                let mut h = Fnv::new();
                for path in &paths {
                    match doc.resolve_preview(path) {
                        Some(text) => h.str(&text),
                        None => h.u64(u64::MAX),
                    }
                }
                Ok(h.finish())
            })?;
            Ok(Fingerprint::new("resolve", "lookups", ops, hash))
        },
    ));

    out.push(Scenario::new(
        "tree.resolve_by_key",
        "tree",
        "Find the member of a huge object by its key (a few keys picked at random)",
        &["wide"],
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let members = ctx.meta.u("members");
            let ops = 20u64;
            m.ops = ops;
            let mut rng = Lcg(7);
            let paths: Vec<NodePath> = (0..ops)
                .map(|_| {
                    vec![
                        PathSegment::Key(format!("key_{:09}", rng.next(members))),
                        PathSegment::Key("v".to_owned()),
                    ]
                })
                .collect();
            let hash = m.time(|| {
                let mut h = Fnv::new();
                for path in &paths {
                    match doc.resolve_preview(path) {
                        Some(text) => h.str(&text),
                        None => h.u64(u64::MAX),
                    }
                }
                Ok(h.finish())
            })?;
            Ok(Fingerprint::new("resolve", "lookups", ops, hash))
        },
    ));

    out.push(Scenario::new(
        "tree.iterate_children",
        "tree",
        "Walk every child of the root, counting them by kind",
        &["records", "ndjson", "numbers", "strings", "wide"],
        |ctx, m| {
            let doc = m.setup(|| ctx.load())?;
            m.extra("doc", doc_info(&doc));
            let tally = m.time(|| Ok(doc.tally_children()))?;
            let mut h = Fnv::new();
            for n in tally {
                h.u64(n);
            }
            Ok(Fingerprint::new(
                "tally",
                "children",
                tally.iter().sum(),
                h.finish(),
            ))
        },
    ));
}
