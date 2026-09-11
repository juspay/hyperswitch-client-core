type entry = {
  client: promise<JSON.t>,
  sessions: promise<JSON.t>,
  sdkConfig: promise<JSON.t>,
}

type fetchers = {
  fetchClient: unit => promise<JSON.t>,
  fetchSessions: unit => promise<JSON.t>,
  fetchSdkConfig: unit => promise<JSON.t>,
}

let table: Dict.t<entry> = Dict.make()

// How many mounted surfaces hold each entry. Keyed like the table, so two
// surfaces of one session, or two sessions with identical credentials, share
// one count and one set of requests.
let holders: Dict.t<int> = Dict.make()

// Drops the cached responses only. The surfaces holding the key stay mounted and
// keep their count: the next `getOrStart` under that key refetches for them, and
// their own `release` still has to bring the count down.
let invalidate = (~key) => table->Dict.delete(key)

let retain = (~key) => holders->Dict.set(key, holders->Dict.get(key)->Option.getOr(0) + 1)

// Drops the entry once nothing holds it, so a finished session's responses do
// not outlive it in a shared JS realm.
let release = (~key) => {
  let remaining = holders->Dict.get(key)->Option.getOr(1) - 1
  if remaining <= 0 {
    holders->Dict.delete(key)
    invalidate(~key)
  } else {
    holders->Dict.set(key, remaining)
  }
}

// A failed response drops the entry it belongs to, so the next `getOrStart` retries.
// Only that entry: a late failure must not evict a newer entry that `refresh` has
// since started under the same key.
let evictOnError = (p, ~key, ~isCurrent) =>
  p
  ->Promise.then(json => {
    if (json == JSON.Encode.null || json->ErrorUtils.isError) && isCurrent() {
      invalidate(~key)
    }
    Promise.resolve(json)
  })
  ->Promise.catch(_ => {
    if isCurrent() {
      invalidate(~key)
    }
    Promise.resolve(JSON.Encode.null)
  })

let getOrStart = (~key, ~fetchers: fetchers): entry =>
  switch table->Dict.get(key) {
  | Some(entry) => entry
  | None =>
    let started = ref(None)
    let isCurrent = () =>
      switch (table->Dict.get(key), started.contents) {
      | (Some(current), Some(mine)) => current === mine
      | _ => false
      }
    let entry = {
      client: fetchers.fetchClient()->evictOnError(~key, ~isCurrent),
      sessions: fetchers.fetchSessions()->evictOnError(~key, ~isCurrent),
      sdkConfig: fetchers.fetchSdkConfig()->evictOnError(~key, ~isCurrent),
    }
    started := Some(entry)
    table->Dict.set(key, entry)
    entry
  }

// Starts fresh requests under [key] whatever is cached there: the intent behind the
// credentials changed, so cached responses are stale even when the key is not.
let refresh = (~key, ~fetchers) => {
  invalidate(~key)
  getOrStart(~key, ~fetchers)
}

type sessionEvent =
  | IntentUpdating
  | IntentUpdateEnded
  | IntentSwitched(SdkTypes.paymentSessionConfig)

// Events are published under the session that raised them and reach only the
// listeners subscribed under that tag. A surface without a session tag has no
// session to follow, so it does not subscribe at all.
type listener = {sessionTag: int, handle: sessionEvent => unit}

let listeners: array<listener> = []

let subscribe = (~sessionTag: int, handle: sessionEvent => unit) => {
  let listener = {sessionTag, handle}
  listeners->Array.push(listener)
  () => {
    let index = listeners->Array.indexOf(listener)
    if index >= 0 {
      listeners->Array.splice(~start=index, ~remove=1, ~insert=[])
    }
  }
}

let publish = (~sessionTag: int, event: sessionEvent) =>
  listeners
  ->Array.copy
  ->Array.forEach(listener =>
    if listener.sessionTag === sessionTag {
      listener.handle(event)
    }
  )
