pub mod keyvalue;
pub mod score_database;

use gdnative::api::OS;
use serde::{Deserialize, Serialize};
use sled::IVec;
use std::ops::Deref;

use crate::error::DResult;

/// The database used for persistently keeping up with player's behavior and statistics
/// such as (non exhaustive) accuracy, playtime, and last weapon being used.
pub struct PersistentDatabase(sled::Db);

impl PersistentDatabase {
    pub fn new(db_file_name: String) -> Self {
        let os = OS::godot_singleton();
        let user_dir = os.get_user_data_dir().to_string();
        let db_path = format!("{}/{}", user_dir, db_file_name);

        let db = sled::open(db_path).expect("Unable to open database file");

        PersistentDatabase(db)
    }
}

impl Deref for PersistentDatabase {
    type Target = sled::Db;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

/// This is a trait to encapsulate and make sense of how to serde the key-value storage
pub trait SerdeKV<'a> {
    type Key: Deserialize<'a> + Serialize;
    type Value: Deserialize<'a> + Serialize;

    fn serialized(key: Self::Key, value: Self::Value) -> DResult<(Vec<u8>, Vec<u8>)> {
        Ok((bincode::serialize(&key)?, bincode::serialize(&value)?))
    }

    fn deserialized(key: &'a IVec, value: &'a IVec) -> DResult<(Self::Key, Self::Value)> {
        Ok((
            bincode::deserialize(key.as_ref())?,
            bincode::deserialize(value.as_ref())?,
        ))
    }
}
