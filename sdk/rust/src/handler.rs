use anyhow::{Result, ensure};
use starknet_core::codec::{Decode, Encode};
use starknet_core::types::Felt;
use std::collections::HashMap;

pub(crate) type HandlerMap<'a> = HashMap<String, BoxedUntypedHandler<'a>>;
pub(crate) type BoxedUntypedHandler<'a> = Box<dyn (FnMut(Vec<Felt>) -> Result<Vec<Felt>>) + 'a>;

pub(crate) fn box_handler<'a, T>(mut handler: impl Handler<T> + 'a) -> BoxedUntypedHandler<'a> {
    Box::new(move |calldata| handler.invoke_untyped(calldata))
}

// NOTE: The T parameter allows us to overcome a lack of specialisation in Rust.
//   This trick has been stolen from Axum, the clue is using tuples here:
//   https://docs.rs/axum/latest/src/axum/handler/mod.rs.html#193

pub trait Handler<T> {
    fn invoke_untyped(&mut self, calldata: Vec<Felt>) -> Result<Vec<Felt>>;
}

macro_rules! impl_handler {
    ($($var:ident: $param:ident),*) => {
        impl<F, $($param,)* R> Handler<(($($param,)*),)> for F
        where
            F: FnMut($($param),*) -> Result<R>,
            $($param: for<'a> Decode<'a>,)*
            R: Encode,
        {
            fn invoke_untyped(&mut self, calldata: Vec<Felt>) -> Result<Vec<Felt>> {
                let mut calldata = calldata.iter();

                $(
                    let $var = $param::decode_iter(&mut calldata)?;
                )*

                ensure!(calldata.next().is_none(), "unexpected parameters");

                let value = self($($var,)*)?;

                let mut encoded = vec![];
                value.encode(&mut encoded)?;
                Ok(encoded)
            }
        }
    };
}

// Generate implementations for up to 12 parameters.
impl_handler!();
impl_handler!(a0: A0);
impl_handler!(a0: A0, a1: A1);
impl_handler!(a0: A0, a1: A1, a2: A2);
impl_handler!(a0: A0, a1: A1, a2: A2, a3: A3);
impl_handler!(a0: A0, a1: A1, a2: A2, a3: A3, a4: A4);
impl_handler!(a0: A0, a1: A1, a2: A2, a3: A3, a4: A4, a5: A5);
impl_handler!(a0: A0, a1: A1, a2: A2, a3: A3, a4: A4, a5: A5, a6: A6);
impl_handler!(a0: A0, a1: A1, a2: A2, a3: A3, a4: A4, a5: A5, a6: A6, a7: A7);
impl_handler!(a0: A0, a1: A1, a2: A2, a3: A3, a4: A4, a5: A5, a6: A6, a7: A7, a8: A8);
impl_handler!(a0: A0, a1: A1, a2: A2, a3: A3, a4: A4, a5: A5, a6: A6, a7: A7, a8: A8, a9: A9);
impl_handler!(a0: A0, a1: A1, a2: A2, a3: A3, a4: A4, a5: A5, a6: A6, a7: A7, a8: A8, a9: A9, a10: A10);
impl_handler!(a0: A0, a1: A1, a2: A2, a3: A3, a4: A4, a5: A5, a6: A6, a7: A7, a8: A8, a9: A9, a10: A10, a11: A11);
