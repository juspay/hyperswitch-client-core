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

/* Android awaits this promise to finish its HeadlessJsTask. iOS invokes the component below and
   releases its temporary root when native receives completePrefetch. */
let run = (~props) => {
  let headlessModule = HeadlessCommon.makeHeadlessModule()
  let reRegisterCallback = ref(() => ())
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
      reRegisterCallback,
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

@react.component
let make = (~props) => {
  React.useEffect0(() => {
    run(~props)->ignore
    None
  })
  React.null
}
