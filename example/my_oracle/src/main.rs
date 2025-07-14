use anyhow::ensure;
use cairo_oracle_server::Oracle;
use std::process::ExitCode;

fn main() -> ExitCode {
    Oracle::new()
        .provide("funny_hash", |value: u64| {
            ensure!(value % 2 == 0, "value must be even");
            Ok(value * value)
        })
        .provide("zip_mul", |a: Vec<u64>, b: Vec<u64>| {
            ensure!(a.len() == b.len(), "vectors must have the same length");
            let product: Vec<u64> = a.iter().zip(b.iter()).map(|(x, y)| x * y).collect();
            Ok(product)
        })
        .run()
}
