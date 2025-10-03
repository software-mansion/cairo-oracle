//! This library provides the core functionality for interacting with **oracles** in Cairo.
//! Oracles are external, untrusted processes that can be called from Cairo code to fetch data or
//! perform computations not possible within the VM, like accessing web APIs or local files.
//!
//! ## Feature status
//!
//! This is an experimental feature. The API and behaviour may change in future versions of Scarb.
//! Oracles are currently available with the `--experimental-oracles` flag passed to the executor.
//!
//! ## What is an oracle?
//!
//! An oracle is an external process (like a script, binary, or web service) that exposes custom
//! logic or data to a Cairo program at runtime. You use it to perform tasks the Cairo VM cannot,
//! such as accessing real-world data or executing complex, non-provable computations.
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
//! While the specific protocols are runtime-dependent, here are the common schemes:
//! - [`shell`](https://docs.swmansion.com/scarb/docs/extensions/oracles/shell.html) — one‑shot
//!   shell command execution returning stdout.
//!   - check out the [`shell` package](https://scarbs.xyz/packages/shell) for ready to use Cairo
//!     library that wraps this protocol.
//! - [`wasm`](https://docs.swmansion.com/scarb/docs/extensions/oracles/wasm.html) — run
//!   WebAssembly components.
//!
//! Always consult your specific runtime's documentation for a complete list of supported protocols
//! and available built-in oracles.
//!
//! ## Never trust your oracle!
//!
//! This is the most important security principle in this library. Because oracle execution is not
//! proven, you must operate under the assumption that an oracle can be malicious or compromised. An
//! attacker can intercept or control the oracle to return arbitrary, invalid, or harmful data.
//!
//! Your Cairo code is the only line of defense. It is your responsibility to validate and verify
//! any data returned by an oracle before it is used in any state-changing logic.
//!
//! **Always treat oracle responses as untrusted input.** For example, if your program expects a
//! sorted list of values, it must immediately verify that the list is indeed sorted. Failure to do
//! so creates a critical security vulnerability.

use core::fmt;
use core::result::Result as CoreResult;
use starknet::testing::cheatcode;

/// Invokes an external oracle process and returns its result.
///
/// Avoid calling this function directly in user code. Instead, write oracle interface modules,
/// which group all single oracle features together.
///
/// To use an oracle, call `invoke` with:
/// 1. `connection_string`: A string describing how to connect to the oracle. The execution runtime
///    handles oracle process management transparently under the hood. Consult your runtime
///    documentation for details what protocols and options are supported. For wasm-based oracles,
///    this is a path to a WASM binary that must be an
///    [asset](https://docs.swmansion.com/scarb/docs/reference/manifest.html#assets).
/// 2. `selector`: The name or identifier of the method to invoke on the oracle (as a `ByteArray`).
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
///         oracle::invoke("wasm:math_oracle.wasm", "pow", (x, n))
///     }
///
///     pub fn sqrt(x: u64) -> Result<u64> {
///         oracle::invoke("wasm:math_oracle.wasm", "sqrt", x)
///     }
/// }
/// ```
pub fn invoke<T, +Destruct<T>, +Drop<T>, +Serde<T>, R, +Serde<R>>(
    connection_string: ByteArray, selector: ByteArray, calldata: T,
) -> Result<R> {
    let mut input: Array<felt252> = array![];
    connection_string.serialize(ref input);
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

#[generate_trait]
pub impl ErrorImpl of ErrorTrait {
    /// Creates a new `oracle::Error` with a custom message.
    ///
    /// This is useful for oracle-wrapping libraries that need extra error checking in Cairo code.
    fn custom(message: ByteArray) -> Error {
        Error { message }
    }
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_result_error_serde() {
        let mut serialized: Array<felt252> = array![];
        let original_error: Result<()> = Result::Err(Error { message: "abcdef" });
        original_error.serialize(ref serialized);
        assert_eq!(serialized, array![1, 0, 107075202213222, 6]);

        let mut span = serialized.span();
        let deserialized = Serde::<Result<()>>::deserialize(ref span).unwrap();
        assert_eq!(deserialized, original_error);
    }
}
