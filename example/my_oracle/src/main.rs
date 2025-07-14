use anyhow::ensure;
use cairo_oracle_server::Oracle;
use std::process::ExitCode;

fn main() -> ExitCode {
    Oracle::new()
        .provide("funny_hash", |value: u64| {
            ensure!(value % 2 == 0, "Value must be even");
            Ok(value * value)
        })
        .run()
}
