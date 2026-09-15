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

      UpdateIntentHook.useUpdateIntentListener()->ignore

      React.useEffect1(() => {

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
