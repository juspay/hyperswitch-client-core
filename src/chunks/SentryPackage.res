// @sentry/react-native, loaded with import() by Sentry.res (SentryImpl.native.res).
// Evaluated in its own chunk; see OptionalPackage.res for why the require is guarded.
@val external require: string => unknown = "require"

let loaded: Nullable.t<unknown> = try {
  Nullable.make(require("@sentry/react-native"))
} catch {
| _ => Nullable.null
}
