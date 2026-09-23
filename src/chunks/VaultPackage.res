// @juspay-tech/react-native-hyperswitch-vault, loaded with import() by VaultDirectBindings.res.
// Evaluated in its own chunk; see OptionalPackage.res for why the require is guarded.
@val external require: string => unknown = "require"

let loaded: Nullable.t<unknown> = try {
  Nullable.make(require("@juspay-tech/react-native-hyperswitch-vault"))
} catch {
| _ => Nullable.null
}
