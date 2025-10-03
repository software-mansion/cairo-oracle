# Shell

This library provides an interface for executing shell commands from Cairo scripts using the
[`shell` oracle protocol](https://docs.swmansion.com/scarb/docs/extensions/oracles/shell.html).

```toml
[dependencies]
shell = "1.0.0"
```

_Language support: requires Cairo 2.13+_

## Usage

This package lets Cairo code spawn a command on the host machine and capture its standard output.
Each call is a one‑shot subprocess: no processes are kept alive between invocations.
The standard error is routed to executor's log stream.

The command line is parsed and executed by a minimal cross-platform shell, the same that
powers [deno tasks](https://docs.deno.com/runtime/reference/cli/task/#syntax).

Use it primarily in tests, prototypes, or local development scenarios where you need to call small utilities,
format data, or fetch information that would be cumbersome to embed in Cairo directly.

### Inspect exit code and standard output.

```cairo
#[executable]
fn main() {
	let (code, stdout) = shell::exec("echo hello").unwrap();
	assert_eq!(code, 0);
	assert_eq!(stdout, "hello\n");
}
```

### Fail on non‑zero exit

```cairo
#[executable]
fn main() {
	let os = shell::output("uname -s").unwrap();
	assert!(os.len() > 0);

	// Will return an oracle::Error because the command exits with code 1.
	let err = shell::output("false");
	assert!(err.is_err());
}
```
