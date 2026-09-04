/* Headless entry point rendered as a temporary task/root on the existing React Native runtime.
   Delegates all logic to HeadlessCommon, providing a response-based CVC getter. */

open SdkTypes

type headlessMode = Prefetch | UpdateIntent | SavedPaymentMethods | Shutdown

let headlessModeFromString = mode =>
  switch mode {
  | "prefetch" => Some(Prefetch)
  | "updateIntent" => Some(UpdateIntent)
  | "savedPM" => Some(SavedPaymentMethods)
  | "shutdown" => Some(Shutdown)
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
  | None
  | Some(Shutdown) =>
    /* Fail loudly. Falling through to the saved-method flow would register a native
       callback and wait forever; native times out its own request instead. */
    Console.error(`[Hyperswitch] unknown headlessType "${headlessType}"`)
    Promise.resolve()
  }
}

/* One subscription per JS runtime, not per task: a cold-start fallback task must not install a
   second subscriber and handle every event twice. The resolver ref belongs to whichever task is
   currently live, so a shutdown event always ends the right one. */
let subscription: ref<option<unit => unit>> = ref(None)
let resolveTask: ref<option<unit => unit>> = ref(None)

/* Android awaits this promise to finish its HeadlessJsTask: after the first startTask the task
   stays alive and every later request arrives through the headlessRequest event, until native
   shuts it down on the next session's init. iOS invokes the component below and releases its
   temporary root when native receives completePrefetch — iOS never emits headlessRequest, so
   the subscription is inert there. */
let run = (~props) =>
  Promise.make((resolve, _) => {
    let headlessModule = HeadlessCommon.makeHeadlessModule()
    resolveTask := Some(() => resolve())

    /* Installed before the first request is handled: an updateIntent emitted right after
       completePrefetch must not fall on the floor. */
    if subscription.contents->Option.isNone {
      subscription :=
        Some(
          HyperModule.Events.subscribeHeadlessRequest(payload => {
            let headlessType =
              payload
              ->Dict.get("headlessType")
              ->Option.flatMap(JSON.Decode.string)
              ->Option.getOr("")
            switch headlessModeFromString(headlessType) {
            | Some(Shutdown) =>
              subscription.contents->Option.forEach(unsubscribe => unsubscribe())
              subscription := None
              resolveTask.contents->Option.forEach(finish => finish())
              resolveTask := None
            | _ => handleRequest(headlessModule, payload->JSON.Encode.object)->ignore
            }
          }),
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
