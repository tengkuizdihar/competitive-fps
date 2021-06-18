use crate::_prelude::*;
use serde::{Deserialize, Serialize};

/// A pair of key and value of Score
/// NOTE: use this to serialize and deserialize Score key and value
pub type ScorePair = (ScoreKey, ScoreValue);

/// Key being used to refer to a value in the K-V database
#[derive(Debug, Serialize, Deserialize)]
pub struct ScoreKey(#[serde(with = "chrono::serde::ts_seconds")] chrono::DateTime<chrono::Utc>);

/// Data that's used for the scoring system when interacting with the persistent database
#[derive(Debug, Serialize, Deserialize)]
pub struct ScoreValue {
    pub miss_count: i64,
    pub hit_count: i64,
}

impl Default for ScoreKey {
    fn default() -> Self {
        ScoreKey(chrono::Utc::now())
    }
}

impl SerdeKV<'_> for ScorePair {
    type Key = ScoreKey;

    type Value = ScoreValue;
}
