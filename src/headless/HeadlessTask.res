/* Headless entry point rendered as a temporary task/root on the existing React Native runtime.
   Delegates all logic to HeadlessCommon, providing a response-based CVC getter. */

open SdkTypes

type headlessMode = Prefetch | UpdateIntent | SavedPaymentMethods

let headlessModeFromString = mode =>
  switch mode {
  | "prefetch" => Some(Prefetch)
  | "updateIntent" => Some(UpdateIntent)
  | "savedPM" => Some(SavedPaymentMethods)
  | _ => None
  }

let handleRequest = (headlessModule, props) => {
  let nativeProp = nativeJsonToRecord(props, 0)
  let headlessType = props->Utils.getDictFromJson->Utils.getString("headlessType", "")

  switch headlessModeFromString(headlessType) {
  | Some(Prefetch)
  | Some(UpdateIntent) =>
    HeadlessCommon.fetchAndCachePrefetchData(headlessModule, nativeProp)
  | Some(SavedPaymentMethods) =>
    // In HeadlessTask, CVC comes from the native callback response (response["cvc"])
    let getCvc = (response: JSON.t) => {
      switch response->Utils.getDictFromJson->Dict.get("cvc") {
      | Some(cvc) => cvc
      | None => JSON.Encode.null
      }
    }
    let prefetchedApiData = HeadlessCommon.resolveHeadlessPrefetch(
      nativeProp.paymentSessionConfig.sdkAuthorization,
    )
    HeadlessCommon.runHeadlessFlow(
      headlessModule,
      nativeProp,
      ~prefetchedApiData,
      ~getCvc,
    )
  | None =>
    /* Fail loudly. Falling through to the saved-method flow would register a native
       callback and wait forever; native times out its own request instead. */
    Console.error(`[Hyperswitch] unknown headlessType "${headlessType}"`)
    Promise.resolve()
  }
}

/* One subscription per JS runtime, installed by whichever task runs first and kept for the
   runtime's life: a cold-start fallback task must not install a second subscriber and handle
   every event twice. Native never asks JS to tear it down — there is no shutdown event, the
   task ends natively on re-init, and one subscriber per runtime holds by construction. */
let subscription: ref<option<unit => unit>> = ref(None)

/* This promise intentionally never resolves. Android awaits nothing: after the first
   startTask the task stays alive and every later request arrives through the headlessRequest
   event, until native finishTask ends it on the next session's init — an unresolved task
   promise is inert (AppRegistry only forwards settlement to notifyTaskFinished). iOS invokes
   the component below and releases its temporary root when native receives completePrefetch —
   iOS never emits headlessRequest, so the subscription is inert there. */
let run = (~props) =>
  Promise.make((_, _) => {
    let headlessModule = HeadlessCommon.makeHeadlessModule()

    /* Installed before the first request is handled: an updateIntent emitted right after
       completePrefetch must not fall on the floor. */
    if subscription.contents->Option.isNone {
      subscription :=
        Some(
          HyperModule.Events.subscribeHeadlessRequest(payload =>
            handleRequest(headlessModule, payload->JSON.Encode.object)->ignore
          ),
        )
    }

    handleRequest(headlessModule, props)->ignore
  })

@react.component
let make = (~props) => {
  React.useEffect0(() => {
    run(~props)->ignore
    None
  })
  React.null
}
