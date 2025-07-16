mod my_oracle {
    #[derive(Debug, Drop, Serde)]
    struct NumberAnalysis {
        both_are_odd: bool,
        mul: u128,
    }

    pub fn funny_hash(x: u64) -> oracle::Result<u64> {
        oracle::invoke(
            "stdio:cargo -q run --manifest-path my_oracle/Cargo.toml", 'funny_hash', (x,),
        )
    }

    pub fn zip_mul(a: Span<u64>, b: Span<u64>) -> oracle::Result<Span<NumberAnalysis>> {
        oracle::invoke("stdio:cargo -q run --manifest-path my_oracle/Cargo.toml", 'zip_mul', (a, b))
    }

    pub fn state_action(action: u64) -> oracle::Result<u64> {
        oracle::invoke(
            "stdio:cargo -q run --manifest-path my_oracle/Cargo.toml", 'state_action', (action,),
        )
    }
}

#[executable]
fn main() {
    for i in 10000..10009_u64 {
        let x = my_oracle::funny_hash(i);
        println!("Funny hash of {} is: {:?}", i, x);
    }

    let a = array![1, 2, 3, 4, 5, 6].span();
    let b = array![6, 6, 7, 7, 8, 8].span();
    let c = my_oracle::zip_mul(a, b);
    println!("Zip mul of {:?} and {:?} is: {:?}", a, b, c);

    let s1 = my_oracle::state_action(42);
    println!("State action with 42: {:?}", s1);

    let s2 = my_oracle::state_action(7);
    println!("State action with 7: {:?}", s2);

    let s3 = my_oracle::state_action(12345);
    println!("State action with 12345: {:?}", s3);
}
