//! What the generator wrote about a dataset beside the file (`<id>.meta.json`): how many records
//! it has and which values are in it, so that a scenario can ask for something that is there (or
//! is not) however big the file is.

use std::path::Path;

use serde_json::Value;

pub struct Meta(pub Value);

impl Meta {
    pub fn load(path: &Path) -> Result<Self, String> {
        let text = std::fs::read_to_string(path)
            .map_err(|e| format!("reading {}: {e}", path.display()))?;
        serde_json::from_str(&text)
            .map(Meta)
            .map_err(|e| format!("{} is not JSON: {e}", path.display()))
    }

    pub fn empty() -> Self {
        Meta(Value::Object(Default::default()))
    }

    pub fn kind(&self) -> String {
        self.s("kind")
    }

    pub fn id(&self) -> String {
        self.s("id")
    }

    /// A number the generator recorded, or 0.
    pub fn u(&self, key: &str) -> u64 {
        self.0.get(key).and_then(Value::as_u64).unwrap_or(0)
    }

    /// A text the generator recorded, or "".
    pub fn s(&self, key: &str) -> String {
        self.0
            .get(key)
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_owned()
    }
}
