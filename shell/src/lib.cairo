//! This package lets Cairo code spawn a command on the host machine and capture its standard
//! output. It uses the [`shell` oracle
//! protocol](https://docs.swmansion.com/scarb/docs/extensions/oracles/shell.html). Each call is a
//! one‑shot subprocess: no processes are kept alive between invocations. The standard error is
//! routed to executor's log stream.
//!
//! The command line is parsed and executed by a minimal cross-platform shell, the same that
//! powers [deno tasks](https://docs.deno.com/runtime/reference/cli/task/#syntax).
//!
//! Use it primarily in tests, prototypes, or local development scenarios where you need to call
//! small utilities, format data, or fetch information that would be cumbersome to embed in Cairo
//! directly.

/// Exit status returned by a shell command.
pub type ExitCode = i32;

/// Captured standard output (`stdout`) of a shell command.
pub type Stdout = ByteArray;

/// Result type re‑export for convenience.
pub type Result<T> = oracle::Result<T>;

/// Executes a shell command and returns its exit code and standard output.
///
/// Prefer using [`output`] if you only care about successful commands and want an error otherwise.
///
/// ```cairo
/// let (code, out) = shell::exec("echo Cairo").unwrap();
/// assert_eq!(code, 0);
/// assert_eq!(out, "Cairo\n");
/// ```
pub fn exec(command: ByteArray) -> Result<(ExitCode, Stdout)> {
    oracle::invoke("shell:", "exec", command)
}

/// Runs a shell command and returns its `stdout` on success.
///
/// If the underlying command exits with a non‑zero status, an error is returned which message
/// includes the exit code.
///
/// ```cairo
/// let uname = shell::output("uname -s").unwrap();
/// assert!(uname.len() > 0);
///
/// let result = shell::output("false");
/// assert!(result.is_err());
/// ```
pub fn output(command: ByteArray) -> Result<Stdout> {
    match exec(command)? {
        (0, stdout) => Ok(stdout),
        (
            exit_code, _,
        ) => Err(
            oracle::ErrorTrait::custom(format!("command failed with exit code: {}", exit_code)),
        ),
    }
}

#[cfg(test)]
mod tests {
    fn unwrap<T>(result: Result<T, oracle::Error>) -> T {
        match result {
            Result::Ok(value) => value,
            Result::Err(err) => panic!("{:?}", err),
        }
    }

    #[test]
    fn exec_success() {
        let (exit_code, stdout) = unwrap(super::exec("echo hello"));
        assert_eq!(exit_code, 0);
        assert_eq!(stdout, "hello\n");
    }

    #[test]
    fn exec_failure() {
        let (exit_code, stdout) = unwrap(super::exec("false"));
        assert_eq!(exit_code, 1);
        assert_eq!(stdout, "");
    }

    #[test]
    fn exec_nonexistent_command() {
        let (exit_code, stdout) = unwrap(super::exec("nonexistent_command_123"));
        assert_eq!(exit_code, 127);
        assert_eq!(stdout, "");
    }

    #[test]
    fn output_success() {
        let stdout = unwrap(super::output("echo hello"));
        assert_eq!(stdout, "hello\n");
    }

    #[test]
    #[should_panic(expected: "oracle::Error(@\"command failed with exit code: 1\")")]
    fn output_failure() {
        unwrap(super::output("false"));
    }

    #[test]
    #[should_panic(expected: "oracle::Error(@\"command failed with exit code: 127\")")]
    fn output_nonexistent_command() {
        unwrap(super::output("nonexistent_command_123"));
    }
}
