// Typed externals into the HyperHeadless TurboModule access layer
// (HyperHeadlessNative.ts). Everything no-ops when the native module is
// absent, so these are always safe to call.
//
// This file lives next to HyperHeadlessNative.ts on purpose: the `@module`
// path stays a sibling reference, and consumers (HeadlessCommon.res) reach it
// by ReScript module name, which the compiler resolves rather than the bundler.
module Native = {
  @module("./HyperHeadlessNative")
  external getPaymentSession: (int, JSON.t, JSON.t, array<JSON.t>, JSON.t => unit) => unit =
    "getPaymentSession"
  @module("./HyperHeadlessNative")
  external exitHeadless: (int, string) => unit = "exitHeadless"
}

let getPaymentSession = Native.getPaymentSession
let exitHeadless = Native.exitHeadless
