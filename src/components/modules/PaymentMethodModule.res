module Native = {
  @module("./PaymentMethodModuleNative")
  external subscribeTokenise: (Dict.t<JSON.t> => unit) => (unit => unit) = "subscribeTokenise"

  @module("./PaymentMethodModuleNative")
  external returnTokenResult: (int, JSON.t) => unit = "returnTokenResult"
}

let subscribeTokenise = Native.subscribeTokenise
let returnTokenResult = Native.returnTokenResult
