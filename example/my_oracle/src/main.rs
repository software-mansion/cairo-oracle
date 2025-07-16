use anyhow::{Result, ensure};
use cairo_oracle_server::Oracle;
use starknet_core::codec::Encode;
use std::process::ExitCode;

#[derive(Encode)]
struct NumberAnalysis {
    both_are_odd: bool,
    mul: u64,
}

fn main() -> ExitCode {
    let mut accumulator = 0;

    Oracle::new()
        .provide("funny_hash", |value: u64| {
            ensure!(value % 2 == 0, "value must be even");
            Ok(value * value)
        })
        .provide(
            "zip_mul",
            |a: Vec<u64>, b: Vec<u64>| -> Result<Vec<NumberAnalysis>> {
                ensure!(a.len() == b.len(), "vectors must have the same length");
                Ok(a.into_iter()
                    .zip(b.into_iter())
                    .map(|(x, y)| NumberAnalysis {
                        both_are_odd: x % 2 == 1 && y % 2 == 1,
                        mul: (x as u64) * (y as u64),
                    })
                    .collect())
            },
        )
        .provide("state_action", move |action: u64| {
            accumulator += action;
            Ok(accumulator)
        })
        .run()
}
