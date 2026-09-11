open SdkTypes

module Runner = {
  @react.component
  let make = () => {
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let key = SessionDataHook.useSessionCredentialsKey()
    let fetchers = SessionDataHook.useSessionFetchers()

    let prefetchTag = nativeProp.rootTag
    // The prefetch surface is the session's identity: the other surfaces of the
    // session carry its tag and only react to events published under it.
    let sessionTag = nativeProp.sdkParams.sessionTag->Option.getOr(prefetchTag)

    // Native drives updateIntent through this surface's props rather than events, so the
    // surface only ever sees its own session. `init` shows the overlay on the session's
    // other surfaces. `complete` arrives with the new credentials already in
    // `paymentSessionConfig` and always refetches: the intent behind the credentials
    // changed even when the credentials themselves did not, so whatever is cached under
    // this key is stale. The session's other surfaces switch once the data is warm.
    let (attempt, phase) = switch nativeProp.updateIntent {
    | Some({attempt, phase}) => (attempt, Some(phase))
    | None => (-1, None)
    }

    // Native has no timer on this round trip: it waits for exactly one reply per
    // `complete`, and only a native event that rules the reply out (session closed or
    // re-initialised) ends the attempt otherwise. So the reply must always go out, and
    // a subscriber that throws on the session event must not swallow it.
    let broadcast = event =>
      try SessionStore.publish(~sessionTag, event) catch {
      | _ => ()
      }
    let reply = payload =>
      HyperModule.onUpdateIntentEvent(
        prefetchTag,
        UpdateIntentHook.updateIntentCompleteReturned,
        payload,
      )

    // Every phase transition supersedes the work of the previous one: a `complete` whose
    // requests are still in flight when a `cancel` or a newer attempt arrives must not
    // reply or switch the session's surfaces for it. Unmounting supersedes everything.
    let generation = React.useRef(0)
    // An overlay was raised by `init` and nothing has lowered it yet.
    let updating = React.useRef(false)
    let endUpdate = () =>
      if updating.current {
        updating.current = false
        broadcast(IntentUpdateEnded)
      }

    // Declared before the holder effect so that, when `complete` changes the key, the
    // fresh requests are started here and the holder effect below finds them.
    React.useEffect2(() => {
      generation.current = generation.current + 1
      let mine = generation.current
      switch phase {
      | Some(UpdateIntentInit) =>
        updating.current = true
        broadcast(IntentUpdating)
      | Some(UpdateIntentCancelled) => endUpdate()
      | Some(UpdateIntentComplete) =>
        let entry = SessionStore.refresh(~key, ~fetchers)
        let prefetchFailed: HyperModule.exitResultPayload = {
          status: "failed",
          code: "prefetch_failed",
          message: "Could not load data for the updated payment intent",
        }
        let switched = nativeProp.paymentSessionConfig
        Promise.all3((entry.client, entry.sessions, entry.sdkConfig))
        ->Promise.thenResolve(((clientResp, _sessionsResp, configResp)) => {
          let failed = json => json == JSON.Encode.null || json->ErrorUtils.isError
          failed(clientResp) || failed(configResp)
            ? (SessionStore.IntentUpdateEnded, prefetchFailed)
            : (SessionStore.IntentSwitched(switched), {status: "success"})
        })
        ->Promise.catch(_ => Promise.resolve((SessionStore.IntentUpdateEnded, prefetchFailed)))
        ->Promise.thenResolve(((event, result)) => {
          if generation.current === mine {
            updating.current = false
            broadcast(event)
            reply(result)
          }
        })
        ->ignore
      | None => ()
      }
      None
    }, (attempt, phase))

    // Stopped by native (the session closed or was released) while an update was in
    // flight: the session's other surfaces still need their overlay lowered, and native
    // has already ended the attempt, so nothing is replied.
    React.useEffect0(() => Some(
      () => {
        generation.current = generation.current + 1
        endUpdate()
      },
    ))

    // Holds the entry for as long as this surface runs under these credentials, starting
    // the requests on first mount. The last holder to release evicts the entry, so the
    // count must only ever change here and in the other surfaces' matching effects.
    React.useEffect1(() => {
      SessionStore.getOrStart(~key, ~fetchers)->ignore
      SessionStore.retain(~key)
      Some(() => SessionStore.release(~key))
    }, [key])

    React.null
  }
}

// `rootTag` is the surface's own root tag from AppRegistry: unique per surface on the
// shared host, and the address native resolves this session's updateIntent replies by.
@react.component
let make = (~props, ~rootTag) => {
  let nativeProp = SdkTypes.nativeJsonToRecord(props, rootTag)

  <NativePropContext nativeProp>
    <LoggerContext>
      <Runner />
    </LoggerContext>
  </NativePropContext>
}
