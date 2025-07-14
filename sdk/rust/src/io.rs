use crate::jsonrpc;
use anyhow::Context;
use std::io;
use std::io::{BufRead, Write};

pub struct Io {
    stdin: io::BufReader<io::StdinLock<'static>>,
    stdout: io::StdoutLock<'static>,
}

impl Io {
    pub fn lock() -> Self {
        Self {
            stdin: io::BufReader::new(io::stdin().lock()),
            stdout: io::stdout().lock(),
        }
    }

    pub fn send(&mut self, message: impl Into<jsonrpc::Message>) {
        let message = message.into();
        return inner(self, &message);

        // Minimize monomorphisation effects.
        fn inner(this: &mut Io, message: &jsonrpc::Message) {
            // Serialise the message to string as a whole to avoid emitting unterminated messages.
            let line =
                serde_json::to_string(&message).expect("failed to serialize message from oracle");

            eprintln!("send: {line}");
            writeln!(this.stdout, "{line}").expect("failed to write message to oracle stdout");
            this.stdout.flush().expect("failed to flush oracle stdout");
        }
    }

    pub fn recv(&mut self) -> Option<anyhow::Result<jsonrpc::Message>> {
        let mut buf = String::new();
        match self.stdin.read_line(&mut buf) {
            Ok(0) => None,
            Ok(_n) => {
                eprintln!("recv: {buf}");
                Some(
                    serde_json::from_str(buf.trim()).context("failed to parse message from oracle"),
                )
            }
            Err(err) => Some(Err(err).context("failed to read bytes from oracle")),
        }
    }
}
