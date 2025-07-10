//! This package is the front gate to the concept of **oracles** in Cairo programs. Oracles allow
//! Cairo code to invoke external, untrusted, performant logic during program execution, enabling
//! integration with the outside world in a controlled and auditable manner.
//!
//! ## Feature status
//!
//! As of the date when this package version has been released, oracle support in Scarb is
//! **experimental**. It must be enabled with `scarb execute --experimental-oracles` or by setting
//! the `SCARB_EXPERIMENTAL_ORACLES=1` environment variable. The API and protocol may change in
//! future releases.
//!
//! ## What is an oracle?
//!
//! An oracle is an external process (could be a binary or a script or web service) that exposes
//! custom logic or data to a Cairo program. Oracles can perform computations, access files, or
//! provide any service not natively available in Cairo. They are executed as separate processes and
//! communicate with the Cairo executor using a defined protocol. By their mere nature, oracle
//! execution is not included in the execution trace and thus the proof.
//!
//! ## How are oracles executed?
//!
//! The exact details on how oracles are executed are up to the execution runtime. Consult your
//! execution runtime documentation for details and possibilities.
//!
//! ## Never trust your oracle!
//!
//! If you care about generating execution proofs of your programs, then do not forget to **never
//! trust your oracle**. Oracle execution is not part of the execution trace and thus is a potential
//! vector for third-party actors to attack your program. Always validate the results returned by
//! oracles, and never assume that they are correct without verification.

use core::fmt;
use core::result::Result as CoreResult;

/// Invokes an external oracle process and returns its result.
///
/// Avoid calling this function directly in user code. Instead, write oracle interface modules,
/// which group all single oracle features together.
///
/// To use an oracle, call `invoke` with:
/// 1. `connection_url`: A string describing how to connect to the oracle. The execution runtime
///    handles oracle process management transparently under the hood. Consult your runtime
///    documentation for details what protocols and options are supported. For stdio-based oracles,
///    this is typically a path to an executable (e.g., `"stdio:./my_oracle"`).
/// 2. `selector`: The name or identifier of the method to invoke on the oracle (as short string).
///    It acts as a function name or command within the oracle process.
/// 3. `calldata`: The arguments to pass to the oracle method, as a serializable Cairo type. To pass
///    multiple arguments, use a tuple or struct that implements `Serde`.
///
/// The function returns a `Result<R, oracle::Error>`, where `R` is the expected return type, or an
/// error if the invocation fails or the oracle returns an error.
///
/// ```cairo
/// mod math_oracle {
///     pub type Result<T> = oracle::Result<T>;
///
///     pub fn pow(x: u64, n: u32) -> Result<u128> {
///         oracle::invoke("stdio:./my_math_oracle.py", 'pow', (x, n))
///     }
///
///     pub fn sqrt(x: u64) -> Result<u64> {
///         oracle::invoke("stdio:./my_math_oracle.py", 'sqrt', x)
///     }
/// }
///
/// mod fs_oracle {
///     pub type Result<T> = oracle::Result<T>;
///
///     pub fn fs_read(path: ByteArray) -> Result<ByteArray> {
///         oracle::invoke("builtin:fs", 'read', path)
///     }
///
///     pub fn fs_exists(path: ByteArray) -> Result<bool> {
///         oracle::invoke("builtin:fs", 'exists', path)
///     }
/// }
/// ```
pub fn invoke<T, +Destruct<T>, +Drop<T>, +Serde<T>, R, +Serde<R>>(
    connection_url: ByteArray, selector: felt252, calldata: T,
) -> Result<R> {
    let mut input: Array<felt252> = array![];
    connection_url.serialize(ref input);
    selector.serialize(ref input);
    calldata.serialize(ref input);

    let mut output = cheatcode::<'oracle_invoke'>(input.span());

    // `unwrap_or_else` requires +Drop<R>, which we do not ask for:
    // https://github.com/software-mansion/cairo-lint/issues/387
    #[allow(manual_unwrap_or)]
    match Serde::<Result<R>>::deserialize(ref output) {
        Option::Some(result) => result,
        Option::None => Err(deserialization_error()),
    }
}

/// `Result<T, oracle::Error>`
pub type Result<T> = CoreResult<T, Error>;

/// An error type that can be raised when invoking oracles.
///
/// The internal structure of this type is opaque, but it can be displayed and (de)serialized.
#[derive(Drop, Clone, PartialEq, Serde)]
pub struct Error {
    message: ByteArray,
}

fn deserialization_error() -> Error {
    Error { message: "failed to deserialize oracle response" }
}

impl DisplayError of fmt::Display<Error> {
    fn fmt(self: @Error, ref f: fmt::Formatter) -> CoreResult<(), fmt::Error> {
        fmt::Display::fmt(self.message, ref f)
    }
}

impl DebugError of fmt::Debug<Error> {
    fn fmt(self: @Error, ref f: fmt::Formatter) -> CoreResult<(), fmt::Error> {
        write!(f, "oracle::Error({:?})", self.message)
    }
}

/// Private, parallel declaration of `starknet::testing::cheatcode`.
///
/// We roll out our own so that oracles are not dependent on the `starknet` package.
extern fn cheatcode<const selector: felt252>(
    input: Span<felt252>,
) -> Span<felt252> implicits() nopanic;
