use crate::handler::HandlerMap;
use crate::io::Io;
use crate::jsonrpc::*;
use anyhow::ensure;
use serde::Deserialize;
use starknet_core::types::Felt;
use std::io;
use std::process::ExitCode;

#[derive(Deserialize)]
struct InvokeParams {
    selector: String,
    calldata: Vec<Felt>,
}

pub struct Server<'a> {
    handler_map: HandlerMap<'a>,
    io: Io,
    mf: MessageFactory,
}

impl<'a> Server<'a> {
    pub fn main(handler_map: HandlerMap<'a>) -> ExitCode {
        let mut server = Server {
            handler_map,
            io: Io::lock(),
            mf: MessageFactory::default(),
        };
        server.run()
    }

    fn run(&mut self) -> ExitCode {
        let result = self.initialize().and_then(|()| self.giant_loop());

        match result {
            Ok(()) => ExitCode::SUCCESS,
            Err(err) => {
                eprintln!("{err:?}");
                ExitCode::FAILURE
            }
        }
    }

    fn initialize(&mut self) -> anyhow::Result<()> {
        let ready_request = self.mf.request("ready", serde_json::Value::Null);
        let ready_request_id = ready_request.id.clone();
        self.io.send(ready_request);

        let Some(message) = self.io.recv().transpose()? else {
            // Client has terminated the connection after we send a `ready` request.
            // Nothing has happened yet for us, so we cleanly terminate.
            return Ok(());
        };

        let response = message.expect_response()?;

        ensure!(
            response.id == ready_request_id,
            "unexpected `ready` response id, expected: {expected:?}, got: {actual:?}",
            expected = ready_request_id,
            actual = response.id
        );

        // We silently ignore any response parameters in case future spec allows passing some.

        Ok(())
    }

    fn giant_loop(&mut self) -> anyhow::Result<()> {
        loop {
            match self.io.recv() {
                None => {
                    eprintln!("warn: client disconnected without sending `shutdown` notification");
                    return Ok(());
                }

                Some(Err(err)) => {
                    if err.is::<io::Error>() {
                        return Err(err);
                    } else {
                        eprintln!("warn: {err:?}");
                    }
                }

                Some(Ok(Message::Notification(notification)))
                    if notification.method == "shutdown" =>
                {
                    return Ok(());
                }

                Some(Ok(Message::Notification(_))) => {
                    // Unknown notification, ignore it.
                }

                Some(Ok(Message::Response(_))) => {
                    // Unexpected response, ignore it.
                }

                Some(Ok(Message::Request(request))) if request.method == "invoke" => {
                    let InvokeParams { selector, calldata } =
                        match serde_json::from_value::<InvokeParams>(request.params) {
                            Ok(params) => params,
                            Err(err) => {
                                self.io.send(self.mf.error(
                                    request.id,
                                    ResponseError {
                                        code: INVALID_PARAMS_CODE,
                                        message: format!("{err:?}"),
                                        data: None,
                                    },
                                ));
                                continue;
                            }
                        };

                    let Some(handler) = self.handler_map.get_mut(&selector) else {
                        let provides = self
                            .handler_map
                            .keys()
                            .map(|selector| format!("{selector:?}"))
                            .collect::<Vec<_>>()
                            .join(", ");

                        self.io.send(self.mf.error(
                            request.id,
                            ResponseError {
                                code: INVALID_PARAMS_CODE,
                                message: format!("unknown selector: {selector:?}, this oracle provides: {provides}"),
                                data: None,
                            },
                        ));
                        continue;
                    };

                    match handler(calldata) {
                        Ok(result) => {
                            self.io.send(self.mf.result(request.id, result));
                        }
                        Err(err) => {
                            self.io.send(self.mf.error(
                                request.id,
                                ResponseError {
                                    code: INTERNAL_ERROR_CODE,
                                    message: format!("{err:?}"),
                                    data: None,
                                },
                            ));
                        }
                    }
                }

                Some(Ok(Message::Request(Request { id, method, .. }))) => {
                    self.io.send(self.mf.error(
                        id,
                        ResponseError {
                            code: METHOD_NOT_FOUND_CODE,
                            message: format!("unknown request method: {method:?}"),
                            data: None,
                        },
                    ));
                }
            }
        }
    }
}
