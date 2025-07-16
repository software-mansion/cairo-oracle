//! This crate provides a framework for building Cairo
//! [oracles](https://scarbs.xyz/packages/oracle) in Rust.
//! It handles transport protocol interaction and input/output (de)serialization, letting you
//! focus on the logic of your oracle.
//!
//! ## What is an oracle?
//!
//! An oracle is an external process (like a script, binary, or web service) that exposes custom
//! logic or data to a Cairo program. You use it to perform tasks the Cairo VM cannot, such as
//! accessing real-world data or executing complex, non-provable computations.
//!
//! **IMPORTANT:** The execution of an oracle occurs **outside** of the Cairo VM. Consequently, its
//! operations are **not included** in the execution trace and are **not verified by the proof**.
//! The proof only validates that a call was made to an oracle and that your program correctly
//! handled the data it received. It provides no guarantee whatsoever that the data itself is
//! accurate or legitimate.
//!
//! ## How are oracles executed?
//!
//! Oracle execution is managed by the Cairo runtime (e.g., the `scarb execute`). The runtime is
//! responsible for interpreting the connection string and facilitating the communication between
//! the Cairo program and the external process.
//!
//! This library builds oracles that operate on the `stdio` protocol, which means they are
//! executed as separate processes and communicate via stdin and stdout.
//!
//! # Example oracle implementation
//! ```no_run
//! # use anyhow::ensure;
//! # use cairo_oracle_server::Oracle;
//! # use std::process::ExitCode;
//! fn main() -> ExitCode {
//!     Oracle::new()
//!         .provide("funny_hash", |value: u64| {
//!             ensure!(value % 2 == 0, "value must be even");
//!             Ok(value * value)
//!         })
//!         .run()
//! }
//! ```
//!
//! # Example use in Cairo program
//! ```cairo
//! mod my_oracle {
//!     pub fn funny_hash(x: u64) -> oracle::Result<Span<u64>> {
//!         oracle::invoke(
//!             "stdio:cargo -q run --manifest-path my_oracle/Cargo.toml",
//!             'funny_hash', (x,)
//!         )
//!     }
//! }
//!
//! #[executable]
//! fn main() {
//!     for i in 10000..10009_u64 {
//!         let x = my_oracle::funny_hash(i);
//!         println!("Funny hash of {} is: {:?}", i, x);
//!     }
//! }
//! ```

#![warn(missing_docs)]

pub use self::builder::Oracle;
pub use self::handler::Handler;
pub use starknet_core;

mod builder;
mod handler;
mod io;
mod jsonrpc;
mod server;
