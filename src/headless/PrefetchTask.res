open SdkTypes

module Runner = {
  @react.component
  let make = () => {
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let key = SessionDataHook.useSessionCredentialsKey()
    let fetchers = SessionDataHook.useSessionFetchers()

    let prefetchTag = nativeProp.rootTag
    let sessionTag = nativeProp.sdkParams.sessionTag->Option.getOr(prefetchTag)
    let (attempt, phase) = switch nativeProp.updateIntent {
    | Some({attempt, phase}) => (attempt, Some(phase))
    | None => (-1, None)
    }

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

    let generation = React.useRef(0)
    let updating = React.useRef(false)
    let endUpdate = () =>
      if updating.current {
        updating.current = false
        broadcast(IntentUpdateEnded)
      }

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

    React.useEffect0(() => Some(
      () => {
        generation.current = generation.current + 1
        endUpdate()
      },
    ))

    React.useEffect1(() => {
      SessionStore.getOrStart(~key, ~fetchers)->ignore
      SessionStore.retain(~key)
      Some(() => SessionStore.release(~key))
    }, [key])

    React.null
  }
}

@react.component
let make = (~props, ~rootTag) => {
  let nativeProp = SdkTypes.nativeJsonToRecord(props, rootTag)

  <NativePropContext nativeProp>
    <LoggerContext>
      <Runner />
    </LoggerContext>
  </NativePropContext>
}
