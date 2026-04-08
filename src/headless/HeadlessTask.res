// HeadlessTask.res
// Headless JS task that runs in a separate JS context (when CvcWidget is NOT active).
// Delegates all logic to HeadlessCommon, providing a response-based CVC getter.

open SdkTypes

@react.component
let make = (~props) => {
  let headlessModule = HeadlessCommon.makeHeadlessModule()
  let reRegisterCallback = ref(() => ())
  let nativeProp = nativeJsonToRecord(props, 0)

  // In HeadlessTask, CVC comes from the native callback response (response["cvc"])
  let getCvc = (response: JSON.t) => {
    switch response->Utils.getDictFromJson->Dict.get("cvc") {
    | Some(cvc) => cvc
    | None => JSON.Encode.null
    }
  }

  HeadlessCommon.runHeadlessFlow(
    headlessModule,
    reRegisterCallback,
    nativeProp,
    ~getCvc,
  )

  React.null
}
