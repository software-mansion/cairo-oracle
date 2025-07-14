mod my_oracle {
    pub fn funny_hash(input: u64) -> oracle::Result<Span<u64>> {
        oracle::invoke(
            "stdio:cargo run --manifest-path my_oracle/Cargo.toml", 'funny_hash', (input,),
        )
    }

    pub fn zip_mul(a: Span<u64>, b: Span<u64>) -> oracle::Result<Span<u64>> {
        oracle::invoke(
            "stdio:cargo run --manifest-path my_oracle/Cargo.toml", 'zip_mul', (a, b),
        )
    }
}

#[executable]
fn main() {
    for i in 10000..10009_u64 {
        let x = my_oracle::funny_hash(i);
        println!("Funny hash of {} is: {:?}", i, x);
    }

    let a = array![1, 2, 3, 4, 5].span();
    let b = array![6, 7, 8, 9, 10].span();
    let c = my_oracle::zip_mul(a, b);
    println!("Zip mul of {:?} and {:?} is: {:?}", a, b, c);
}
