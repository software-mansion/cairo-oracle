mod my_oracle {
    pub fn funny_hash(input: u64) -> oracle::Result<Span<u64>> {
        oracle::invoke(
            "stdio:cargo run --manifest-path my_oracle/Cargo.toml", 'funny_hash', (input,),
        )
    }
}

#[executable]
fn main() {
    for i in 10000..10009_u64 {
        let x = my_oracle::funny_hash(i);
        print!("Funny hash of {} is: {:?}\n", i, x);
    }
}
