//! What a scenario made, boiled down to a count and a hash, so that two revisions can be
//! told to have given the same answer (or not) without keeping the answers.

use std::io;

use serde_json::Value;

/// FNV-1a, 64 bits: not for security, only for telling results apart, and it needs no crate.
pub struct Fnv(u64);

impl Fnv {
    pub fn new() -> Self {
        Self(0xcbf2_9ce4_8422_2325)
    }

    pub fn bytes(&mut self, bytes: &[u8]) {
        for &b in bytes {
            self.0 ^= u64::from(b);
            self.0 = self.0.wrapping_mul(0x0000_0100_0000_01b3);
        }
    }

    pub fn u64(&mut self, value: u64) {
        self.bytes(&value.to_le_bytes());
    }

    pub fn str(&mut self, text: &str) {
        self.u64(text.len() as u64);
        self.bytes(text.as_bytes());
    }

    pub fn value(&mut self, value: &Value) {
        // Writing to this never fails.
        let _ = serde_json::to_writer(&mut *self, value);
        self.u64(0);
    }

    pub fn finish(&self) -> u64 {
        self.0
    }
}

impl io::Write for Fnv {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        self.bytes(buf);
        Ok(buf.len())
    }

    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

/// The summary of what a scenario produced.
pub struct Fingerprint {
    /// Which sort of answer this is. Two fingerprints are compared only when their bases are
    /// the same: a list of rows that is grouped (a document kept on disk) is not the list a
    /// parsed document makes, and that is by design.
    pub basis: String,
    /// How many of whatever the scenario counts (results, matches, rows, bytes).
    pub count: u64,
    pub hash: u64,
    /// What the count is a count of, for whoever reads the JSON.
    pub unit: &'static str,
}

impl Fingerprint {
    pub fn new(basis: &str, unit: &'static str, count: u64, hash: u64) -> Self {
        Self {
            basis: basis.to_owned(),
            count,
            hash,
            unit,
        }
    }

    /// The same fingerprint counting something else (the hash is of the text, the count is what the
    /// scenario counts).
    pub fn with_count(mut self, count: u64, unit: &'static str) -> Self {
        self.count = count;
        self.unit = unit;
        self
    }

    pub fn to_json(&self) -> Value {
        serde_json::json!({
            "basis": self.basis,
            "unit": self.unit,
            "count": self.count,
            "hash": format!("{:016x}", self.hash),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_hash_is_the_published_fnv1a_one() {
        // Test vectors of FNV-1a 64 from the reference implementation.
        let mut h = Fnv::new();
        h.bytes(b"");
        assert_eq!(h.finish(), 0xcbf2_9ce4_8422_2325);
        let mut h = Fnv::new();
        h.bytes(b"a");
        assert_eq!(h.finish(), 0xaf63_dc4c_8601_ec8c);
        let mut h = Fnv::new();
        h.bytes(b"foobar");
        assert_eq!(h.finish(), 0x8594_4171_f739_67e8);
    }

    #[test]
    fn a_value_hashes_by_what_it_says_not_where_it_lives() {
        let a: Value = serde_json::from_str(r#"{"a": [1, 2.5, "x"]}"#).unwrap();
        let b: Value = serde_json::from_str(r#"{ "a" : [ 1 , 2.5 , "x" ] }"#).unwrap();
        let (mut ha, mut hb) = (Fnv::new(), Fnv::new());
        ha.value(&a);
        hb.value(&b);
        assert_eq!(ha.finish(), hb.finish());
        let c: Value = serde_json::from_str(r#"{"a": [1, 2.5, "y"]}"#).unwrap();
        let mut hc = Fnv::new();
        hc.value(&c);
        assert_ne!(ha.finish(), hc.finish());
    }
}
