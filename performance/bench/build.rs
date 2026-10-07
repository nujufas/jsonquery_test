//! Works out which API the revision under test has, so that one harness can be built
//! against revisions that differ (see `src/api_before.rs` and `src/api_after.rs`):
//!
//! - `jq_lazy`: `jsonquery_core` has the lazy, memory-mapped document (`Content`, `Root`,
//!   `lazy::LazyTree`). Without it a `Document` is a parsed `Value` (`doc.root`).
//! - `jq_load_with`: `jsonquery_core::load_with` and `LoadLimits` exist, which is how a
//!   file is made to be parsed or kept on disk whatever its size.

use std::env;
use std::fs;
use std::path::Path;

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rustc-check-cfg=cfg(jq_lazy)");
    println!("cargo:rustc-check-cfg=cfg(jq_load_with)");

    let manifest = env::var("CARGO_MANIFEST_DIR").expect("cargo sets CARGO_MANIFEST_DIR");
    let core = Path::new(&manifest).join("../core/src");
    println!("cargo:rerun-if-changed={}", core.display());

    if core.join("lazy").join("mod.rs").exists() || core.join("lazy.rs").exists() {
        println!("cargo:rustc-cfg=jq_lazy");
    }
    if let Ok(text) = fs::read_to_string(core.join("document.rs")) {
        if text.contains("pub fn load_with(") {
            println!("cargo:rustc-cfg=jq_load_with");
        }
    }
}
