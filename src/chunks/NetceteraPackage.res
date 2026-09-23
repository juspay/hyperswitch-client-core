// @juspay-tech/react-native-hyperswitch-netcetera-3ds, loaded with import() by Netcetera3dsModule.res.
// Evaluated in its own chunk; see OptionalPackage.res for why the require is guarded.
@val external require: string => unknown = "require"

let loaded: Nullable.t<unknown> = try {
  Nullable.make(require("@juspay-tech/react-native-hyperswitch-netcetera-3ds"))
} catch {
| _ => Nullable.null
}
