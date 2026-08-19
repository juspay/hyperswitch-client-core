module Native = {
  @module("./HyperHeadlessNative")
  external getPaymentSession: (int, JSON.t, JSON.t, array<JSON.t>, JSON.t => unit) => unit =
    "getPaymentSession"
  @module("./HyperHeadlessNative")
  external exitHeadless: (int, HyperModule.exitResultPayload) => unit = "exitHeadless"
}

let getPaymentSession = Native.getPaymentSession
let exitHeadless = Native.exitHeadless
