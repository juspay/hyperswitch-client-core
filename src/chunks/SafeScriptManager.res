// Stands in for Re.Pack's InitializeScriptManager (rspack.config.mjs replaces it):
// the same ScriptManager.init(), which the bundle runs before the entry. Without
// Re.Pack's native ScriptManager module in the app, init() throws and the entry
// would never start; here the SDK starts anyway and only the chunks loaded on
// demand (Sentry, PayPal, vault, ...) are unavailable.
@module("@callstack/repack/client") @scope("ScriptManager")
external init: unit => unit = "init"

let () = try {
  init()
} catch {
| _ =>
  Console.warn(
    "[Hyperswitch] Re.Pack's ScriptManager native module is missing: optional features are unavailable.",
  )
}
