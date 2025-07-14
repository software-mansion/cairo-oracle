use crate::handler::{Handler, HandlerMap, box_handler};
use crate::server::Server;
use std::mem;
use std::process::ExitCode;

pub struct Oracle<'a> {
    handler_map: HandlerMap<'a>,
}

impl<'a> Oracle<'a> {
    pub fn new() -> Self {
        Self {
            handler_map: Default::default(),
        }
    }

    pub fn provide<T>(&mut self, selector: &str, handler: impl Handler<T> + 'a) -> &mut Self {
        self.handler_map
            .insert(selector.into(), box_handler(handler));
        self
    }

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
