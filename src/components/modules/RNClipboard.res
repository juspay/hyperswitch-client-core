type clipboard = {
  getString: unit => Js.Promise.t<string>,
  setString: string => unit,
}

@val external require: string => {"default": clipboard} = "require"

let (getString, setString) = switch try {
  require("@react-native-clipboard/clipboard")->Some
} catch {
| _ => None
} {
| Some(mod) => (mod["default"].getString, mod["default"].setString)
| None => (ReactNative.Clipboard.getString, ReactNative.Clipboard.setString)
}
