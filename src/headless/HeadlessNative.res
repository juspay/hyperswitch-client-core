open ReactNative

type headlessModule = {
  initialisePaymentSession: (JSON.t => unit) => unit,
  getPaymentSession: (JSON.t, JSON.t, JSON.t, JSON.t => unit) => unit,
  exitHeadless: string => unit,
}

let getFunctionFromModule = (dict: Dict.t<'a>, key: string, default: 'b): 'b => {
  switch dict->Dict.get(key) {
  | Some(fn) => Obj.magic(fn)
  | None => default
  }
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

  {
    initialisePaymentSession: getFunctionFromModule(
      hyperSwitchHeadlessDict,
      "initialisePaymentSession",
      _ => (),
    ),
    getPaymentSession: getFunctionFromModule(hyperSwitchHeadlessDict, "getPaymentSession", (
      _,
      _,
      _,
      _,
    ) => ()),
    exitHeadless: getFunctionFromModule(hyperSwitchHeadlessDict, "exitHeadless", _ => ()),
  }
}
