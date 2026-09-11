open SdkTypes

let isPrefetch = props =>
  props
  ->Utils.getDictFromJson
  ->Dict.get("type")
  ->Option.flatMap(JSON.Decode.string)
  ->Option.getOr("") == "prefetch"

module SavedPaymentMethods = {
  module Runner = {
    @react.component
    let make = () => {
      let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
      let key = SessionDataHook.useSessionCredentialsKey()
      let fetchers = SessionDataHook.useSessionFetchers()

      // A confirm must reach the intent the session currently has: after updateIntent
      // switches the credentials, the flow runs again under them and registers a fresh
      // confirm callback with native.
      UpdateIntentHook.useUpdateIntentListener()->ignore

      React.useEffect1(() => {
        // Same cache as the prefetch surface: a session that prefetched answers this
        // without a second round trip, and two headless calls share one.
        let entry = SessionStore.getOrStart(~key, ~fetchers)
        SessionStore.retain(~key)

        let headlessModule = HeadlessCommon.makeHeadlessModule()
        let reRegisterCallback = ref(() => ())

        let getCvc = (response: JSON.t) =>
          switch response->Utils.getDictFromJson->Dict.get("cvc") {
          | Some(cvc) => cvc
          | None => JSON.Encode.null
          }

        HeadlessCommon.runHeadlessFlow(
          headlessModule,
          reRegisterCallback,
          nativeProp,
          ~getCvc,
          ~prefetched=entry,
        )
        Some(() => SessionStore.release(~key))
      }, [key])

      React.null
    }
  }

  @react.component
  let make = (~props, ~rootTag) => {
    let nativeProp = nativeJsonToRecord(props, rootTag)
    <NativePropContext nativeProp>
      <LoggerContext>
        <Runner />
      </LoggerContext>
    </NativePropContext>
  }
}

// A viewless task has no screen to fall back to. Report the crash the way the task
// would have reported a failure and render nothing. Native has no timer on either
// round trip, so the reply is what ends a pending call; native ignores it when
// nothing is pending.
module Fallback = {
  @react.component
  let make = (~rootTag, ~isPrefetch) => {
    React.useEffect0(() => {
      let crashed: HyperModule.exitResultPayload = {
        status: "failed",
        code: "headless_task_crashed",
        message: "The headless task crashed before it could respond.",
      }
      if isPrefetch {
        HyperModule.onUpdateIntentEvent(
          rootTag,
          UpdateIntentHook.updateIntentCompleteReturned,
          crashed,
        )
      } else {
        HeadlessCommon.makeHeadlessModule().exitHeadless(rootTag, crashed)
      }
      None
    })
    React.null
  }
}

// `rootTag` is the surface's own root tag, passed by AppRegistry; it is what the
// native side resolves replies against.
@react.component
let make = (~props, ~rootTag) => {
  let isPrefetch = isPrefetch(props)
  <ErrorBoundary
    rootTag
    level=FallBackScreen.Top
    renderFallback={(_error, _level, tag) => <Fallback rootTag=tag isPrefetch />}>
    {isPrefetch ? <PrefetchTask props rootTag /> : <SavedPaymentMethods props rootTag />}
  </ErrorBoundary>
}
