/* Runtime-local cache shared by every root mounted on this JS engine (bareroot and headless
   alike — both platforms run one VM). This is deliberately module state rather than React
   state: roots unmount and remount, while the module instance survives until the runtime is
   destroyed. This cache is the SOLE owner of prefetched data; native keeps no copy and only
   receives a completion signal. Native clears entries here on terminal payment states and on
   a failed re-validation of the same authorization (a stale entry must never survive its own
   failed refresh). A prefetch that lands after its native timeout simply repopulates a fresh
   entry for its key; consumers only read at mount/update boundaries, so this is safe.

   Entries also expire: a cancelled initPaymentSession can leave behind an authorization that
   is never reused, so entries older than ttlMinutes are swept on every write (set/remove),
   and a read of an expired entry evicts it and reports a miss — consumers re-fetch rather
   than serve server-expired session data after a long idle window.
   Timestamps live in a parallel map so entry payloads stay untouched. */

let maxEntries = 5

// Hardcoded for now; will be driven dynamically (from config/server) later.
let ttlMinutes = 30.
let ttlMillis = ttlMinutes *. 60. *. 1000.

let cache: Dict.t<JSON.t> = Dict.make()
let insertedAt: Dict.t<float> = Dict.make()

let key = (sdkAuthorization: string) => sdkAuthorization === "" ? None : Some(sdkAuthorization)

let drop = cacheKey => {
  cache->Dict.delete(cacheKey)
  insertedAt->Dict.delete(cacheKey)
}

let timestamp = k => insertedAt->Dict.get(k)->Option.getOr(0.)

let expireStaleEntries = () => {
  let now = Date.now()
  cache->Dict.keysToArray->Array.forEach(k =>
    if now -. k->timestamp > ttlMillis {
      drop(k)
    }
  )
}

/* Hermes has no Array.prototype.toSorted; a reduce finds the oldest key without it. */
let removeOldestIfFull = () =>
  if cache->Dict.keysToArray->Array.length >= maxEntries {
    cache
    ->Dict.keysToArray
    ->Array.reduce(None, (oldest, k) =>
      switch oldest {
      | Some(o) if o->timestamp <= k->timestamp => oldest
      | _ => Some(k)
      }
    )
    ->Option.forEach(drop)
  }

/* Each entry contains only data fetched with this exact authorization. updateIntent writes a new
   entry containing its three refreshed responses (client data, session tokens, sdk_config). */
let set = (~sdkAuthorization: string, data: JSON.t): JSON.t => {
  switch key(sdkAuthorization) {
  | Some(cacheKey) =>
    expireStaleEntries()
    if cache->Dict.get(cacheKey)->Option.isNone {
      removeOldestIfFull()
    }
    cache->Dict.set(cacheKey, data)
    insertedAt->Dict.set(cacheKey, Date.now())
  | None => ()
  }
  data
}

let get = (~sdkAuthorization: string): option<JSON.t> =>
  switch key(sdkAuthorization) {
  | Some(cacheKey) =>
    if Date.now() -. cacheKey->timestamp > ttlMillis {
      drop(cacheKey)
      None
    } else {
      cache->Dict.get(cacheKey)
    }
  | None => None
  }

let remove = (~sdkAuthorization: string) => {
  expireStaleEntries()
  key(sdkAuthorization)->Option.forEach(drop)
}

/* Bridgeless-safe: native emits this event through the codegen channel
   (HyperTurboModule emitClearPrefetchCache), so the subscription must go through
   the generated attach — the legacy NativeEventEmitter never arms it. */
let cleanupSubscription = HyperModule.Events.subscribeClearPrefetchCache(payload =>
  remove(
    ~sdkAuthorization=payload
    ->Dict.get("sdkAuthorization")
    ->Option.flatMap(JSON.Decode.string)
    ->Option.getOr(""),
  )
)
