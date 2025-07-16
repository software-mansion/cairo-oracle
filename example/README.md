# Cairo Oracle Example

This example demonstrates how to use Cairo Oracles to interact with external Rust code from Cairo programs. The example showcases three different oracle functions that perform computations outside of the Cairo runtime.

## Running the Example

> [!IMPORTANT]
> Make sure you are using the Scarb version specified in the `.tool-versions` file.

```bash
scarb execute --experimental-oracles
```

```
   Compiling example v0.1.0 (/path/to/cairo-oracle/example/Scarb.toml)
    Finished `dev` profile target(s) in 1 second
   Executing example
Funny hash of 10000 is: Result::Ok([100000000])
Funny hash of 10001 is: Result::Err(oracle::Error(@"value must be even"))
Funny hash of 10002 is: Result::Ok([100040004])
Funny hash of 10003 is: Result::Err(oracle::Error(@"value must be even"))
Funny hash of 10004 is: Result::Ok([100080016])
Funny hash of 10005 is: Result::Err(oracle::Error(@"value must be even"))
Funny hash of 10006 is: Result::Ok([100120036])
Funny hash of 10007 is: Result::Err(oracle::Error(@"value must be even"))
Funny hash of 10008 is: Result::Ok([100160064])
Zip mul of [1, 2, 3, 4, 5] and [6, 7, 8, 9, 10] is: Result::Ok([5, 6, 14, 24, 36, 50])
State action with 42: Result::Ok([42])
State action with 7: Result::Ok([49])
State action with 12345: Result::Ok([12394])
Saving output to: target/execute/example/execution8
```

Oracle's stderr is piped to Scarb debug logs. To see it, run:

```bash
scarb -vvv execute --experimental-oracles
```
