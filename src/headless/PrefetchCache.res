// Runtime-local cache shared by every headless invocation using the same JS engine.
// This is deliberately module state rather than React state: headless tasks use different
// component roots, while the module instance survives until the bridge/runtime is destroyed.
// Native separately keeps the copy required to launch visible UI. This cache avoids sending the
// large payload back across the bridge when the runtime that performed prefetch is still alive.

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
// entry containing its two refreshed responses; the mounted UI retains its existing sdk_config.
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
