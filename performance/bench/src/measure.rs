//! Timing and memory of one scenario.
//!
//! A scenario does its set-up (`setup`: load the document, which is not what it measures), then
//! hands what it measures to `time`. The first run is kept apart (`first`): it is what a person
//! sees the first time they ask, and it is the run whose memory is watched (a thread reads the
//! process's resident memory every few milliseconds while it runs). Runs after it are the
//! steady state, and are timed with nothing else going on in this process.

use std::mem::ManuallyDrop;
use std::ops::Deref;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};

use crate::common::Fail;
use crate::sysmem;

/// How many runs, and for how long.
#[derive(Clone, Debug)]
pub struct Config {
    /// Runs made and thrown away before the timed ones (the very first run is always made and
    /// kept apart, so this is how many more).
    pub warmup: usize,
    /// At least this many timed runs, unless they are slow (`max_time`)...
    pub min_reps: usize,
    /// ... at most this many...
    pub max_reps: usize,
    /// ... and once this long has been spent timing, at least `min_reps` have been made.
    pub min_time: Duration,
    /// A scenario that has taken this long, including set-up, stops with what it has (two timed
    /// runs at least, or one if a run is longer than this).
    pub max_time: Duration,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            warmup: 0,
            min_reps: 5,
            max_reps: 50,
            min_time: Duration::from_millis(500),
            max_time: Duration::from_secs(90),
        }
    }
}

/// A value that is not dropped: a document that a scenario is done with is left to the
/// process's end (dropping a parsed gigabyte takes seconds, and is measured by a scenario of
/// its own).
pub struct Keep<T>(ManuallyDrop<T>);

impl<T> Deref for Keep<T> {
    type Target = T;
    fn deref(&self) -> &T {
        &self.0
    }
}

#[derive(Clone, Copy, Debug, Default)]
pub struct MemoryRecord {
    /// At the start of the process.
    pub start: sysmem::Status,
    /// After the set-up, before the first run.
    pub after_setup: sysmem::Status,
    /// The highest `rss` during the first run, which is exact (`VmHWM`, started over after the
    /// set-up).
    pub first_peak_rss: u64,
    /// The highest anonymous memory seen during the first run (sampled).
    pub first_peak_anon: u64,
    pub first_peak_file: u64,
    /// Right after the first run, with what it made still alive: what a person who opened a file once
    /// has (a later run can leave freed memory in the process that the first did not).
    pub after_first: sysmem::Status,
    /// After the last run, with what it made still alive.
    pub end: sysmem::Status,
}

pub struct Measurer {
    pub cfg: Config,
    pub started: Instant,
    pub setup_ms: f64,
    pub setup_cpu_ms: f64,
    pub first_ms: f64,
    pub first_cpu_ms: f64,
    pub samples_ms: Vec<f64>,
    pub cpu_ms: Vec<f64>,
    /// How many operations one run stands for (a run that looks up 2000 places is 2000).
    pub ops: u64,
    pub mem: MemoryRecord,
    pub notes: Vec<String>,
    /// Facts about the document or the run that a scenario wants in the record.
    pub extra: serde_json::Map<String, serde_json::Value>,
}

/// Reads the process's resident memory every few milliseconds, and keeps the highest.
struct Sampler {
    stop: Arc<AtomicBool>,
    anon: Arc<AtomicU64>,
    file: Arc<AtomicU64>,
    handle: Option<std::thread::JoinHandle<()>>,
}

impl Sampler {
    fn start() -> Self {
        let stop = Arc::new(AtomicBool::new(false));
        let anon = Arc::new(AtomicU64::new(0));
        let file = Arc::new(AtomicU64::new(0));
        let (s, a, f) = (stop.clone(), anon.clone(), file.clone());
        let handle = std::thread::spawn(move || {
            while !s.load(Ordering::Relaxed) {
                let now = sysmem::status();
                a.fetch_max(now.anon, Ordering::Relaxed);
                f.fetch_max(now.file, Ordering::Relaxed);
                std::thread::sleep(Duration::from_millis(4));
            }
        });
        Self {
            stop,
            anon,
            file,
            handle: Some(handle),
        }
    }

    fn finish(mut self) -> (u64, u64) {
        self.stop.store(true, Ordering::Relaxed);
        if let Some(handle) = self.handle.take() {
            let _ = handle.join();
        }
        (self.anon.load(Ordering::Relaxed), self.file.load(Ordering::Relaxed))
    }
}

impl Measurer {
    pub fn new(cfg: Config) -> Self {
        Self {
            cfg,
            started: Instant::now(),
            setup_ms: 0.0,
            setup_cpu_ms: 0.0,
            first_ms: f64::NAN,
            first_cpu_ms: f64::NAN,
            samples_ms: Vec::new(),
            cpu_ms: Vec::new(),
            ops: 1,
            mem: MemoryRecord {
                start: sysmem::status(),
                ..MemoryRecord::default()
            },
            notes: Vec::new(),
            extra: serde_json::Map::new(),
        }
    }

    pub fn note(&mut self, text: impl Into<String>) {
        self.notes.push(text.into());
    }

    pub fn extra(&mut self, key: &str, value: serde_json::Value) {
        self.extra.insert(key.to_owned(), value);
    }

    /// Run the set-up of a scenario: what it needs and does not measure.
    pub fn setup<T>(&mut self, f: impl FnOnce() -> Result<T, Fail>) -> Result<Keep<T>, Fail> {
        let (t0, c0) = (Instant::now(), sysmem::cpu_ms());
        let value = f()?;
        self.setup_ms = t0.elapsed().as_secs_f64() * 1e3;
        self.setup_cpu_ms = sysmem::cpu_ms() - c0;
        self.mem.after_setup = sysmem::status();
        Ok(Keep(ManuallyDrop::new(value)))
    }

    /// Time `f`: once to see (the first run, with the memory watched), then as many more times as
    /// the configuration says. What the last run made is handed back (what the runs before it
    /// made is dropped, outside the timing, before the next run starts).
    pub fn time<T>(&mut self, mut f: impl FnMut() -> Result<T, Fail>) -> Result<T, Fail> {
        self.time_each(|| Ok(()), |()| f())
    }

    /// Like [`time`](Self::time), for a run that says itself how long the thing it measures took: a
    /// run that cancels a query after a while measures the time from the cancel to the end, not the
    /// whole run.
    pub fn time_reported<T>(
        &mut self,
        mut f: impl FnMut() -> Result<(T, Duration), Fail>,
    ) -> Result<T, Fail> {
        self.measure(|| Ok(()), |()| f().map(|(value, took)| (value, Some(took))))
    }

    /// Like [`time`](Self::time), with a set-up for each run that is not timed (the page cache
    /// emptied, a document loaded to be dropped).
    pub fn time_each<S, T>(
        &mut self,
        setup: impl FnMut() -> Result<S, Fail>,
        mut run: impl FnMut(S) -> Result<T, Fail>,
    ) -> Result<T, Fail> {
        self.measure(setup, |state| run(state).map(|value| (value, None)))
    }

    /// The loop of all of them: `run` makes a value, and may say how long it took (else the time
    /// it took to run is what is kept).
    fn measure<S, T>(
        &mut self,
        mut setup: impl FnMut() -> Result<S, Fail>,
        mut run: impl FnMut(S) -> Result<(T, Option<Duration>), Fail>,
    ) -> Result<T, Fail> {
        // The first run.
        let state = setup()?;
        if self.mem.after_setup.rss == 0 {
            self.mem.after_setup = sysmem::status();
        }
        sysmem::reset_peak();
        let sampler = Sampler::start();
        let (c0, t0) = (sysmem::cpu_ms(), Instant::now());
        let first = run(state);
        let measured = t0.elapsed();
        let cpu = sysmem::cpu_ms() - c0;
        let (anon, file) = sampler.finish();
        let peak = sysmem::status();
        self.mem.after_first = peak;
        self.mem.first_peak_rss = peak.hwm;
        self.mem.first_peak_anon = anon.max(peak.anon);
        self.mem.first_peak_file = file.max(peak.file);
        let wall = match &first {
            Ok((_, Some(took))) => *took,
            _ => measured,
        };
        self.first_ms = wall.as_secs_f64() * 1e3;
        self.first_cpu_ms = cpu;
        let mut last = first?.0;

        // The runs after it. Each starts from nothing the one before made.
        let mut spent = Duration::ZERO;
        let mut warmups = self.cfg.warmup;
        loop {
            let reps = self.samples_ms.len();
            // Out of time: no more warm-ups, and as many timed runs as there are by now (none,
            // if the first run used it all: then the first run is the figure).
            let exhausted = self.started.elapsed() >= self.cfg.max_time;
            if exhausted {
                warmups = 0;
            }
            if warmups == 0 {
                if reps >= self.cfg.max_reps || exhausted {
                    break;
                }
                if reps >= self.cfg.min_reps && spent >= self.cfg.min_time {
                    break;
                }
            }
            drop(last);
            let state = setup()?;
            let (c0, t0) = (sysmem::cpu_ms(), Instant::now());
            let result = run(state);
            let measured = t0.elapsed();
            let cpu = sysmem::cpu_ms() - c0;
            let (value, took) = result?;
            last = value;
            let wall = took.unwrap_or(measured);
            if warmups > 0 {
                warmups -= 1;
                continue;
            }
            spent += wall;
            self.samples_ms.push(wall.as_secs_f64() * 1e3);
            self.cpu_ms.push(cpu);
        }
        self.mem.end = sysmem::status();
        Ok(last)
    }
}

/// The figures of a list of timings.
pub struct Stats {
    pub n: usize,
    pub min: f64,
    pub median: f64,
    pub mean: f64,
    pub p90: f64,
    pub max: f64,
    pub stdev: f64,
    /// Median absolute deviation over the median: how much the runs differ among themselves,
    /// without letting one slow outlier decide.
    pub rel_mad: f64,
}

pub fn stats(samples: &[f64]) -> Option<Stats> {
    if samples.is_empty() {
        return None;
    }
    let mut v: Vec<f64> = samples.to_vec();
    v.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
    let n = v.len();
    let median = quantile(&v, 0.5);
    let mean = v.iter().sum::<f64>() / n as f64;
    let var = if n > 1 {
        v.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / (n as f64 - 1.0)
    } else {
        0.0
    };
    let mut dev: Vec<f64> = v.iter().map(|x| (x - median).abs()).collect();
    dev.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
    let mad = quantile(&dev, 0.5);
    Some(Stats {
        n,
        min: v[0],
        median,
        mean,
        p90: quantile(&v, 0.9),
        max: v[n - 1],
        stdev: var.sqrt(),
        rel_mad: if median > 0.0 { mad / median } else { 0.0 },
    })
}

/// A quantile of a sorted list, by linear interpolation.
fn quantile(sorted: &[f64], q: f64) -> f64 {
    let n = sorted.len();
    if n == 1 {
        return sorted[0];
    }
    let pos = q * (n as f64 - 1.0);
    let (lo, hi) = (pos.floor() as usize, pos.ceil() as usize);
    sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo as f64)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_median_of_an_even_list_is_between_the_middle_two() {
        let s = stats(&[4.0, 1.0, 3.0, 2.0]).unwrap();
        assert_eq!((s.min, s.median, s.max), (1.0, 2.5, 4.0));
        assert!((s.mean - 2.5).abs() < 1e-12);
    }

    #[test]
    fn one_slow_run_does_not_move_the_median_or_the_deviation_much() {
        let s = stats(&[10.0, 10.1, 9.9, 10.0, 10.05, 500.0]).unwrap();
        assert!((s.median - 10.025).abs() < 0.1, "{}", s.median);
        assert!(s.rel_mad < 0.01, "{}", s.rel_mad);
        assert!(s.stdev > 100.0);
    }

    #[test]
    fn no_runs_no_figures() {
        assert!(stats(&[]).is_none());
        let one = stats(&[7.0]).unwrap();
        assert_eq!((one.median, one.stdev, one.rel_mad), (7.0, 0.0, 0.0));
    }

    #[test]
    fn time_makes_a_first_run_and_then_the_timed_ones() {
        let mut m = Measurer::new(Config {
            min_reps: 3,
            min_time: Duration::ZERO,
            max_reps: 3,
            ..Config::default()
        });
        let mut calls = 0;
        let last = m
            .time(|| {
                calls += 1;
                Ok(calls)
            })
            .unwrap();
        assert_eq!(calls, 4, "the first run and three more");
        assert_eq!(last, 4);
        assert_eq!(m.samples_ms.len(), 3);
        assert!(m.first_ms >= 0.0);
    }

    #[test]
    fn a_warmup_is_run_and_not_counted() {
        let mut m = Measurer::new(Config {
            warmup: 2,
            min_reps: 2,
            max_reps: 2,
            min_time: Duration::ZERO,
            ..Config::default()
        });
        let mut calls = 0;
        m.time(|| {
            calls += 1;
            Ok(())
        })
        .unwrap();
        assert_eq!(calls, 1 + 2 + 2);
        assert_eq!(m.samples_ms.len(), 2);
    }
}
