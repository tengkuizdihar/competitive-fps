pub mod database;
pub mod error;
pub(crate) mod _prelude {
    pub use crate::database::{PersistentDatabase, SerdeKV};
    pub use crate::error::*;
}

use crate::database::score_database::ScoreDatabase;
use gdnative::prelude::*;

fn init(handle: InitHandle) {
    handle.add_class::<ScoreDatabase>();
}

godot_init!(init);
