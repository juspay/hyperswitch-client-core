// Typed externals over HyperVaultRelayNative.ts: the CardWidget's line to the hosted
// payment-methods form. Opening no-ops, and tokenizing rejects, when the host lacks the module.
@module("./HyperVaultRelayNative")
external isAvailable: unit => bool = "isAvailable"
@module("./HyperVaultRelayNative")
external openVaultForm: (int, string) => unit = "openVaultForm"
@module("./HyperVaultRelayNative")
external tokenizeVaultForm: (int, string) => promise<string> = "tokenizeVaultForm"
