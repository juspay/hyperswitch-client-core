// Runtime-local cache shared by every root mounted on this JS engine (bareroot and headless
// alike — both platforms run one VM). This is deliberately module state rather than React
// state: roots unmount and remount, while the module instance survives until the runtime is
// destroyed. This cache is the SOLE owner of prefetched data; native keeps no copy and only
// receives a completion signal. Native clears entries here on terminal payment states and on
// a failed re-validation of the same authorization (a stale entry must never survive its own
// failed refresh). A prefetch that lands after its native timeout simply repopulates a fresh
// entry for its key; consumers only read at mount/update boundaries, so this is safe.

let maxEntries = 8
let cache: Dict.t<JSON.t> = Dict.make()

let key = (sdkAuthorization: string) => sdkAuthorization === "" ? None : Some(sdkAuthorization)

let removeOldestIfFull = cache => {
  if cache->Dict.keysToArray->Array.length >= maxEntries {
    cache
    ->Dict.keysToArray
    ->Array.get(0)
    ->Option.forEach(oldestKey => cache->Dict.delete(oldestKey))
  }
}

// Each entry contains only data fetched with this exact authorization. updateIntent writes a new
// entry containing its three refreshed responses (client data, session tokens, sdk_config).
let set = (~sdkAuthorization: string, data: JSON.t): JSON.t => {
  switch key(sdkAuthorization) {
  | Some(cacheKey) =>
    if cache->Dict.get(cacheKey)->Option.isNone {
      removeOldestIfFull(cache)
    }
    cache->Dict.set(cacheKey, data)
  | None => ()
  }
  data
}

let get = (~sdkAuthorization: string): option<JSON.t> =>
  key(sdkAuthorization)->Option.flatMap(cacheKey => cache->Dict.get(cacheKey))

let remove = (~sdkAuthorization: string) =>
  key(sdkAuthorization)->Option.forEach(cacheKey => cache->Dict.delete(cacheKey))

let cleanupEmitter = ReactNative.NativeEventEmitter.make(
  Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule"),
)
let cleanupSubscription = ReactNative.NativeEventEmitter.addListener(
  cleanupEmitter,
  "clearPrefetchCache",
  payload => {
    let sdkAuthorization =
      payload
      ->Utils.getDictFromJson
      ->Utils.getString("sdkAuthorization", "")
    remove(~sdkAuthorization)
  },
)
