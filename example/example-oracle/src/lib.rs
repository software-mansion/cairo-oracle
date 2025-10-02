use std::sync::atomic::{AtomicU64, Ordering};

wit_bindgen::generate!();

struct Oracle;

impl Guest for Oracle {
    fn funny_hash(value: u64) -> Result<u64, String> {
        if value.is_multiple_of(2) {
            Ok(value * value)
        } else {
            Err("value must be even".into())
        }
    }

    fn zip_mul(a: Vec<u64>, b: Vec<u64>) -> Vec<u64> {
        assert!(a.len() == b.len(), "vectors must have the same length");
        a.into_iter().zip(b).map(|(x, y)| x * y).collect()
    }

    fn state_action(action: u64) -> u64 {
        static ACCUMULATOR: AtomicU64 = AtomicU64::new(0);
        ACCUMULATOR.fetch_add(action, Ordering::Relaxed) + action
    }
}

export!(Oracle);
