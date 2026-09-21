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

let holders: Dict.t<int> = Dict.make()

let invalidate = (~key) => table->Dict.delete(key)

let retain = (~key) => holders->Dict.set(key, holders->Dict.get(key)->Option.getOr(0) + 1)

let release = (~key) => {
  let remaining = holders->Dict.get(key)->Option.getOr(1) - 1
  if remaining <= 0 {
    holders->Dict.delete(key)
    invalidate(~key)
  } else {
    holders->Dict.set(key, remaining)
  }
}

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

let refresh = (~key, ~fetchers) => {
  invalidate(~key)
  getOrStart(~key, ~fetchers)
}

let peek = (~key) => table->Dict.get(key)

type sessionEvent =
  | IntentUpdating
  | IntentUpdateEnded
  | IntentSwitched(SdkTypes.paymentSessionConfig)

type listener = {sessionTag: int, handle: sessionEvent => unit}

let listeners: array<listener> = []

type sessionState = {switched: option<SdkTypes.paymentSessionConfig>, updating: bool}

let states: Dict.t<sessionState> = Dict.make()

let idle = {switched: None, updating: false}

let stateOf = (~sessionTag: int) => states->Dict.get(sessionTag->Int.toString)->Option.getOr(idle)

let forget = (~sessionTag: int) => states->Dict.delete(sessionTag->Int.toString)

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

let publish = (~sessionTag: int, event: sessionEvent) => {
  let current = stateOf(~sessionTag)
  states->Dict.set(
    sessionTag->Int.toString,
    switch event {
    | IntentUpdating => {...current, updating: true}
    | IntentUpdateEnded => {...current, updating: false}
    | IntentSwitched(config) => {switched: Some(config), updating: false}
    },
  )
  listeners
  ->Array.copy
  ->Array.forEach(listener =>
    if listener.sessionTag === sessionTag {
      listener.handle(event)
    }
  )
}
