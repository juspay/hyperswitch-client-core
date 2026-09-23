// @juspay-tech/react-native-hyperswitch-scancard, loaded with import() by ScanCardModule.res.
// Evaluated in its own chunk; see OptionalPackage.res for why the require is guarded.
@val external require: string => unknown = "require"

let loaded: Nullable.t<unknown> = try {
  Nullable.make(require("@juspay-tech/react-native-hyperswitch-scancard"))
} catch {
| _ => Nullable.null
}
