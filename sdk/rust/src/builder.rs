use crate::handler::{Handler, HandlerMap, box_handler};
use crate::server::Server;
use std::mem;
use std::process::ExitCode;

/// Builder for configuring and running the Oracle server.
///
/// Allows registering handlers for selectors and starting the server.
pub struct Oracle<'a> {
    handler_map: HandlerMap<'a>,
}

impl<'a> Oracle<'a> {
    /// Creates a new oracle instance ready for handler registration.
    pub fn new() -> Self {
        Self {
            handler_map: Default::default(),
        }
    }

    /// Registers a handler for a given selector.
    pub fn provide<T>(&mut self, selector: &str, handler: impl Handler<T> + 'a) -> &mut Self {
        self.handler_map
            .insert(selector.into(), box_handler(handler));
        self
    }

    /// Starts the oracle server with the registered handlers.
    ///
    /// Takes an exclusive lock on stdin and stdout for the duration of the server.
    /// Returns the [`ExitCode`] that should be used to exit the process.
    #[must_use = "the returned exit code must be used to exit the process"]
    pub fn run(&mut self) -> ExitCode {
        let handler_map = mem::take(&mut self.handler_map);
        Server::main(handler_map)
    }
}

impl Default for Oracle<'_> {
    fn default() -> Self {
        Self::new()
    }
}
