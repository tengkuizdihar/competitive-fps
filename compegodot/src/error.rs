use thiserror::Error;

#[derive(Error, Debug)]
pub enum ErrorKind {
    #[error("A binary serialization error happened.")]
    BinSerdeError(#[from] bincode::Error),
}

/// General error used for the whole application.
pub type DResult<T> = std::result::Result<T, ErrorKind>;
