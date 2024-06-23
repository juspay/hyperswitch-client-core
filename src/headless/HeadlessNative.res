open ReactNative

type strFun = string => unit
external jsonToStrFun: JSON.t => strFun = "%identity"

type jsonWithCallback = (JSON.t => unit) => unit
external jsonWithCallback: JSON.t => jsonWithCallback = "%identity"

type jsonFunWithCallback = (JSON.t, JSON.t => unit) => unit
external jsonToStrFunWithCallback: JSON.t => jsonFunWithCallback = "%identity"

type jsonFun2WithCallback = (JSON.t, JSON.t, JSON.t => unit) => unit
external jsonToStrFun2WithCallback: JSON.t => jsonFun2WithCallback = "%identity"

type jsonFun3WithCallback = (JSON.t, JSON.t, JSON.t, JSON.t => unit) => unit
external jsonToStrFun3WithCallback: JSON.t => jsonFun3WithCallback = "%identity"

type headlessModule = {
  initialisePaymentSession: (RescriptCore.JSON.t => unit) => unit,
  getPaymentSession: (
    RescriptCore.JSON.t,
    RescriptCore.JSON.t,
    RescriptCore.JSON.t,
    RescriptCore.JSON.t => unit,
  ) => unit,
  exitHeadless: string => unit,
}

@react.component
let dummy = () => {
  React.null
}

let initialise = headless => {
  AppRegistry.registerComponent("dummy", _ => dummy)
  AppRegistry.registerHeadlessTask("dummy", () => {
    _data => {
      Promise.resolve()
    }
  })

  let hyperSwitchHeadlessDict =
    Dict.get(ReactNative.NativeModules.nativeModules, headless)
    ->Option.flatMap(JSON.Decode.object)
    ->Option.getOr(Dict.make())

  let initialisePaymentSession = getNativePropCallback =>
    switch hyperSwitchHeadlessDict->Dict.get("initialisePaymentSession") {
    | Some(initialisePaymentSession) =>
      jsonWithCallback(initialisePaymentSession)(getNativePropCallback)
    | None => ()
    }

  let getPaymentSession = (
    defaultPaymentMethod,
    lastUsedPaymentMethod,
    savedPaymentMethodList,
    confirmCallBack,
  ) =>
    switch hyperSwitchHeadlessDict->Dict.get("getPaymentSession") {
    | Some(getPaymentSession) =>
      jsonToStrFun3WithCallback(getPaymentSession)(
        defaultPaymentMethod,
        lastUsedPaymentMethod,
        savedPaymentMethodList,
        confirmCallBack,
      )
    | None => ()
    }

  let exitHeadless = response =>
    switch hyperSwitchHeadlessDict->Dict.get("exitHeadless") {
    | Some(exitHeadless) => jsonToStrFun(exitHeadless)(response)
    | None => ()
    }

  {
    initialisePaymentSession,
    getPaymentSession,
    exitHeadless,
  }
}
