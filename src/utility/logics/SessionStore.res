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

let invalidate = (~key) => table->Dict.delete(key)

let evictOnError = (p, ~key) =>
  p
  ->Promise.then(json => {
    if json == JSON.Encode.null || json->ErrorUtils.isError {
      invalidate(~key)
    }
    Promise.resolve(json)
  })
  ->Promise.catch(_ => {
    invalidate(~key)
    Promise.resolve(JSON.Encode.null)
  })

let getOrStart = (~key, ~fetchers: fetchers): entry =>
  switch table->Dict.get(key) {
  | Some(entry) => entry
  | None =>
    let entry = {
      client: fetchers.fetchClient()->evictOnError(~key),
      sessions: fetchers.fetchSessions()->evictOnError(~key),
      sdkConfig: fetchers.fetchSdkConfig()->evictOnError(~key),
    }
    table->Dict.set(key, entry)
    entry
  }

type sessionEvent =
  | IntentUpdating
  | IntentUpdateEnded
  | IntentSwitched(SdkTypes.paymentSessionConfig)

let listeners: array<sessionEvent => unit> = []

let subscribe = (listener: sessionEvent => unit) => {
  listeners->Array.push(listener)
  () => {
    let index = listeners->Array.indexOf(listener)
    if index >= 0 {
      listeners->Array.splice(~start=index, ~remove=1, ~insert=[])
    }
  }
}

let publish = (event: sessionEvent) => listeners->Array.copy->Array.forEach(l => l(event))
