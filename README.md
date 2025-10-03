# Cairo Oracles

_Oracles_ are external, untrusted processes that can be called from Cairo code to fetch data or perform computations not
possible within the VM, like accessing web APIs or local files.

> [!WARNING]
> Oracle support in Scarb is **experimental**. It must be enabled with `scarb execute --experimental-oracles` or by
> setting the `SCARB_EXPERIMENTAL_ORACLES=1` environment variable. Both the API and protocol are experimental and may
> change in future releases.

This monorepo is home for various packages helping to use external oracles in Cairo programs.

- [`oracle`](./oracle) - The main Cairo library which provides type-safe interfaces for interacting with external
  oracles in Cairo applications.
- [`shell`](./shell) - Wraps the `shell` oracle protocol in an idiomatic Cairo API.
- [`example`](./example) - Example project showcasing oracle use.
