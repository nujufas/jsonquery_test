//! What the process knows about itself: its memory (from `/proc/self/status`), the CPU time it
//! has used, and the page cache. Linux only; elsewhere everything reads as unknown.

use std::fs;
use std::path::Path;

/// The memory of this process, in KiB (what `/proc` calls kB).
#[derive(Clone, Copy, Debug, Default)]
pub struct Status {
    /// Resident set: `anon + file + shmem`.
    pub rss: u64,
    /// The highest `rss` since the process started or the mark was last reset.
    pub hwm: u64,
    /// Resident memory that belongs to no file: the heap, what is allocated. The cost of a
    /// parsed document, and what a mapped one does not have.
    pub anon: u64,
    /// Resident pages of files that are mapped (a mapped document's pages). Clean, shared with
    /// the page cache, and let go by the kernel when memory is wanted.
    pub file: u64,
    pub shmem: u64,
}

fn field(text: &str, name: &str) -> u64 {
    text.lines()
        .find_map(|line| line.strip_prefix(name))
        .and_then(|rest| rest.trim_start_matches(':').split_whitespace().next())
        .and_then(|number| number.parse().ok())
        .unwrap_or(0)
}

pub fn status() -> Status {
    match fs::read_to_string("/proc/self/status") {
        Ok(text) => Status {
            rss: field(&text, "VmRSS"),
            hwm: field(&text, "VmHWM"),
            anon: field(&text, "RssAnon"),
            file: field(&text, "RssFile"),
            shmem: field(&text, "RssShmem"),
        },
        Err(_) => Status::default(),
    }
}

/// Start the "highest resident size" over from the size now (Linux 4.0 and later).
pub fn reset_peak() {
    let _ = fs::write("/proc/self/clear_refs", "5");
}

#[cfg(all(target_os = "linux", target_pointer_width = "64"))]
mod sys {
    #[repr(C)]
    pub struct Timespec {
        pub tv_sec: i64,
        pub tv_nsec: i64,
    }

    extern "C" {
        pub fn clock_gettime(clock: i32, out: *mut Timespec) -> i32;
        pub fn posix_fadvise(fd: i32, offset: i64, len: i64, advice: i32) -> i32;
    }

    pub const CLOCK_PROCESS_CPUTIME_ID: i32 = 2;
    pub const POSIX_FADV_DONTNEED: i32 = 4;
}

/// CPU time used by the whole process (every thread), in milliseconds.
pub fn cpu_ms() -> f64 {
    #[cfg(all(target_os = "linux", target_pointer_width = "64"))]
    {
        let mut ts = sys::Timespec {
            tv_sec: 0,
            tv_nsec: 0,
        };
        // SAFETY: `ts` is a valid timespec and the clock id is a constant the kernel knows.
        let rc = unsafe { sys::clock_gettime(sys::CLOCK_PROCESS_CPUTIME_ID, &mut ts) };
        if rc == 0 {
            return ts.tv_sec as f64 * 1e3 + ts.tv_nsec as f64 / 1e6;
        }
    }
    f64::NAN
}

/// Ask the kernel to forget the cached pages of a file, so that the next read comes from the
/// disk. Only clean pages go (the file must have been written out). Returns whether it was
/// accepted, which it is not where there is no such call.
pub fn drop_cached(path: &Path) -> bool {
    #[cfg(all(target_os = "linux", target_pointer_width = "64"))]
    {
        use std::os::fd::AsRawFd;
        if let Ok(file) = fs::File::open(path) {
            // SAFETY: the descriptor is open for as long as `file` lives.
            let rc = unsafe { sys::posix_fadvise(file.as_raw_fd(), 0, 0, sys::POSIX_FADV_DONTNEED) };
            return rc == 0;
        }
    }
    let _ = path;
    false
}
