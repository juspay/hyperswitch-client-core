// @juspay-tech/react-native-hyperswitch-paypal, loaded with import() by PaypalModule.res.
// Evaluated in its own chunk; see OptionalPackage.res for why the require is guarded.
@val external require: string => unknown = "require"

let loaded: Nullable.t<unknown> = try {
  Nullable.make(require("@juspay-tech/react-native-hyperswitch-paypal"))
} catch {
| _ => Nullable.null
}
