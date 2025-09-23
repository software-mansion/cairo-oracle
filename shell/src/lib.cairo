pub type ExitCode = i32;
pub type Stdout = ByteArray;

pub type Result<T> = oracle::Result<T>;

pub fn exec(command: ByteArray) -> Result<(ExitCode, Stdout)> {
    oracle::invoke("shell:", 'exec', command)
}

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
