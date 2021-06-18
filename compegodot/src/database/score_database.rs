use crate::{
    _prelude::*,
    database::keyvalue::{ScorePair, ScoreValue},
};
use gdnative::prelude::*;

/// Will be triggered everytime the score is changed
pub const SCORE_CHANGED_SIGNAL: &'static str = "score_changed";

/// Constant for the score database's tree name.
pub const DB_SCORE_TREE: &'static str = "SCORE";

/// Database struct that would manage the player's score throughout his training
#[derive(NativeClass)]
#[inherit(Node)]
#[register_with(Self::register)]
pub struct ScoreDatabase {
    pub current_score: i64,
    pub db: PersistentDatabase,
}

#[methods]
impl ScoreDatabase {
    fn new(_owner: &Node) -> Self {
        Self {
            current_score: 0,
            db: PersistentDatabase::new("score_database.sled".into()),
        }
    }

    fn register(builder: &ClassBuilder<Self>) {
        builder.add_signal(Signal {
            name: SCORE_CHANGED_SIGNAL,
            args: &[SignalArgument {
                name: "data",
                default: 0i64.to_variant(),
                export_info: ExportInfo::new(VariantType::I64),
                usage: PropertyUsage::DEFAULT,
            }],
        });
    }

    #[export]
    fn _ready(&self, _owner: &Node) {
        godot_print!("SCORE DATABASE START!");
    }

    /// Internally used to change the score of the scoreboard and then signal it
    #[export]
    pub fn _change_score(&mut self, owner: &Node, score: i64) -> i64 {
        self.current_score = score;
        owner.emit_signal(SCORE_CHANGED_SIGNAL, &[self.current_score.to_variant()]);

        self.current_score
    }

    /// Add the score to the database, by default it will add 1 to the score
    #[export]
    pub fn add_score(&mut self, owner: &Node, #[opt] score: Option<i64>) -> i64 {
        match score {
            Some(s) => self._change_score(owner, self.current_score + s),
            None => self._change_score(owner, self.current_score + 1),
        };

        self.current_score
    }

    /// Reset the current score without saving it to the database
    #[export]
    pub fn reset_score(&mut self, owner: &Node) {
        self._change_score(owner, 0);
    }

    /// Save the current score to database
    #[export]
    pub fn save_current_score(&self, _owner: &Node) {
        let tree = self
            .db
            .open_tree(DB_SCORE_TREE)
            .expect("Tree failed to open");

        let (key, value) = ScorePair::serialized(
            Default::default(),
            ScoreValue {
                miss_count: 0,
                hit_count: self.current_score,
            },
        )
        .expect("Unable to serialize ScoreData");

        tree.insert(key, value)
            .expect("Unable to insert to persistent database.");
    }

    #[export]
    pub fn print_latest_score_saved(&self, _owner: &Node) {
        let tree = self
            .db
            .open_tree(DB_SCORE_TREE)
            .expect("Tree failed to open");

        match tree.last() {
            Ok(db_result) => {
                match db_result {
                    Some((k, v)) => {
                        let (key, value) = ScorePair::deserialized(&k, &v).expect(
                            "Serde Error: Given k-v is not compatible with score key and value.",
                        );

                        godot_print!("KEY: {:?} || VALUE: {:?}", key, value);
                    }
                    None => {
                        godot_warn!("There's no score in the database yet.")
                    }
                };
            }
            Err(_) => {
                godot_error!("Failed getting latest score from database.");
            }
        };
    }
}
