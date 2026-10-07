//! `jq-perf`: times what the app does with a document, one scenario in one process.
//!
//! ```text
//! jq-perf info                      the API of the revision this was built against
//! jq-perf list                      the scenarios, as JSON
//! jq-perf run --scenario ID --file F [--meta M] [--mode auto|parsed|lazy] [--work-dir D]
//!             [--warmup N] [--min-reps N] [--max-reps N] [--min-time-ms N] [--max-time-s N]
//! ```
//!
//! `run` prints one line of JSON: what was measured (see `perf.py` and `docs/results-format.md`).
//! It is built by `perf.py build` against a given revision of the app (`jsonquery-core` and
//! `jsonquery-query` of that revision), where `build.rs` finds out which API that revision has.

#[cfg(jq_lazy)]
#[path = "api_after.rs"]
mod api;
#[cfg(not(jq_lazy))]
#[path = "api_before.rs"]
mod api;

mod common;
mod fingerprint;
mod measure;
mod meta;
mod scenarios;
mod sysmem;

use std::path::PathBuf;
use std::time::Duration;

use serde_json::{json, Value};

use common::{Fail, Mode};
use measure::{stats, Config, Measurer};
use meta::Meta;
use scenarios::{Ctx, Scenario};

/// The harness's own version: a change in what or how it measures bumps it, and results of
/// different versions are not to be compared without a look.
const HARNESS_VERSION: u32 = 1;

struct Args {
    command: String,
    scenario: Option<String>,
    file: Option<PathBuf>,
    meta: Option<PathBuf>,
    mode: Mode,
    work_dir: PathBuf,
    cfg: Config,
}

fn parse_args() -> Result<Args, String> {
    let mut args = std::env::args().skip(1);
    let command = args.next().ok_or("usage: jq-perf info|list|run ...")?;
    let mut parsed = Args {
        command,
        scenario: None,
        file: None,
        meta: None,
        mode: Mode::Auto,
        work_dir: std::env::temp_dir(),
        cfg: Config::default(),
    };
    while let Some(flag) = args.next() {
        let mut value = |name: &str| args.next().ok_or_else(|| format!("{name} needs a value"));
        let number = |text: String, name: &str| {
            text.parse::<u64>()
                .map_err(|_| format!("{name} needs a number, not {text:?}"))
        };
        match flag.as_str() {
            "--scenario" => parsed.scenario = Some(value("--scenario")?),
            "--file" => parsed.file = Some(PathBuf::from(value("--file")?)),
            "--meta" => parsed.meta = Some(PathBuf::from(value("--meta")?)),
            "--work-dir" => parsed.work_dir = PathBuf::from(value("--work-dir")?),
            "--mode" => {
                let text = value("--mode")?;
                parsed.mode = Mode::parse(&text).ok_or(format!("unknown mode {text:?}"))?;
            }
            "--warmup" => parsed.cfg.warmup = number(value("--warmup")?, "--warmup")? as usize,
            "--min-reps" => parsed.cfg.min_reps = number(value("--min-reps")?, "--min-reps")? as usize,
            "--max-reps" => parsed.cfg.max_reps = number(value("--max-reps")?, "--max-reps")? as usize,
            "--min-time-ms" => {
                parsed.cfg.min_time =
                    Duration::from_millis(number(value("--min-time-ms")?, "--min-time-ms")?)
            }
            "--max-time-s" => {
                parsed.cfg.max_time =
                    Duration::from_secs(number(value("--max-time-s")?, "--max-time-s")?)
            }
            other => return Err(format!("unknown option {other}")),
        }
    }
    Ok(parsed)
}

fn info() -> Value {
    json!({
        "harness_version": HARNESS_VERSION,
        "api": api::FLAVOUR,
        "lazy_documents": cfg!(jq_lazy),
        "load_with": cfg!(jq_load_with),
        "threads_available": std::thread::available_parallelism().map(|n| n.get()).unwrap_or(1),
        "os": std::env::consts::OS,
        "arch": std::env::consts::ARCH,
    })
}

fn list() -> Value {
    let all = scenarios::catalogue();
    Value::Array(
        all.iter()
            .map(|s| {
                json!({
                    "id": s.id,
                    "group": s.group,
                    "title": s.title,
                    "kinds": s.kinds,
                    "min_mib": s.min_mib,
                    "max_mib": if s.max_mib == u64::MAX { Value::Null } else { json!(s.max_mib) },
                    "needs_lazy": s.needs_lazy,
                })
            })
            .collect(),
    )
}

fn status_json(s: sysmem::Status) -> Value {
    json!({"rss": s.rss, "hwm": s.hwm, "anon": s.anon, "file": s.file, "shmem": s.shmem})
}

fn stats_json(samples: &[f64]) -> Value {
    match stats(samples) {
        Some(s) => json!({
            "n": s.n, "min": s.min, "median": s.median, "mean": s.mean,
            "p90": s.p90, "max": s.max, "stdev": s.stdev, "rel_mad": s.rel_mad,
        }),
        None => Value::Null,
    }
}

/// Run one scenario and describe what happened as one JSON object.
fn run(args: Args) -> Result<Value, String> {
    let id = args.scenario.clone().ok_or("run needs --scenario")?;
    let file = args.file.clone().ok_or("run needs --file")?;
    let meta = match &args.meta {
        Some(path) => Meta::load(path)?,
        None => Meta::empty(),
    };
    let all = scenarios::catalogue();
    let scenario: &Scenario = all
        .iter()
        .find(|s| s.id == id)
        .ok_or_else(|| format!("no scenario {id:?} (jq-perf list shows them)"))?;

    let ctx = Ctx {
        file,
        meta,
        mode: args.mode,
        work_dir: args.work_dir.clone(),
    };
    let mut m = Measurer::new(args.cfg.clone());

    let outcome = if scenario.needs_lazy && !cfg!(jq_lazy) {
        Err(Fail::Unsupported(
            "this revision has no documents kept on disk".to_owned(),
        ))
    } else {
        let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| (scenario.run)(&ctx, &mut m)));
        match result {
            Ok(r) => r,
            Err(panic) => {
                let text = panic
                    .downcast_ref::<&str>()
                    .map(|s| (*s).to_owned())
                    .or_else(|| panic.downcast_ref::<String>().cloned())
                    .unwrap_or_else(|| "a panic".to_owned());
                Err(Fail::Error(format!("panicked: {text}")))
            }
        }
    };

    let (status, error, fingerprint) = match outcome {
        Ok(fp) => ("ok", Value::Null, fp.to_json()),
        Err(Fail::Error(text)) => ("error", Value::String(text), Value::Null),
        Err(Fail::Unsupported(text)) => ("unsupported", Value::String(text), Value::Null),
    };

    Ok(json!({
        "scenario": scenario.id,
        "group": scenario.group,
        "dataset": ctx.meta.id(),
        "kind": ctx.meta.kind(),
        "mode": ctx.mode.name(),
        "api": api::FLAVOUR,
        "status": status,
        "error": error,
        "setup_ms": m.setup_ms,
        "setup_cpu_ms": m.setup_cpu_ms,
        "first_ms": m.first_ms,
        "first_cpu_ms": m.first_cpu_ms,
        "samples_ms": m.samples_ms,
        "cpu_ms": m.cpu_ms,
        "stats": stats_json(&m.samples_ms),
        "cpu_stats": stats_json(&m.cpu_ms),
        "ops": m.ops,
        "memory_kib": {
            "start": status_json(m.mem.start),
            "after_setup": status_json(m.mem.after_setup),
            "first_peak_rss": m.mem.first_peak_rss,
            "first_peak_anon": m.mem.first_peak_anon,
            "first_peak_file": m.mem.first_peak_file,
            "after_first": status_json(m.mem.after_first),
            "end": status_json(m.mem.end),
        },
        "fingerprint": fingerprint,
        "extra": Value::Object(m.extra),
        "notes": m.notes,
        "wall_total_ms": m.started.elapsed().as_secs_f64() * 1e3,
    }))
}

fn main() {
    let args = match parse_args() {
        Ok(args) => args,
        Err(message) => {
            eprintln!("jq-perf: {message}");
            std::process::exit(2);
        }
    };
    let result = match args.command.as_str() {
        "info" => Ok(info()),
        "list" => Ok(list()),
        "run" => run(args),
        other => Err(format!("unknown command {other:?}")),
    };
    match result {
        Ok(value) => {
            println!("{}", serde_json::to_string(&value).expect("a JSON value serializes"));
            // Not the drop of what the scenario kept: a parsed gigabyte takes seconds to free.
            std::process::exit(0);
        }
        Err(message) => {
            eprintln!("jq-perf: {message}");
            std::process::exit(2);
        }
    }
}
