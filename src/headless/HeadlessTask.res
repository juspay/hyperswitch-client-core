open SdkTypes

let isPrefetch = props =>
  props
  ->Utils.getDictFromJson
  ->Dict.get("type")
  ->Option.flatMap(JSON.Decode.string)
  ->Option.getOr("") == "prefetch"

module SavedPaymentMethods = {
  @react.component
  let make = (~props) => {
    React.useEffect0(() => {
      let headlessModule = HeadlessCommon.makeHeadlessModule()
      let reRegisterCallback = ref(() => ())
      let nativeProp = nativeJsonToRecord(props, 0)


      let getCvc = (response: JSON.t) =>
        switch response->Utils.getDictFromJson->Dict.get("cvc") {
        | Some(cvc) => cvc
        | None => JSON.Encode.null
        }

      HeadlessCommon.runHeadlessFlow(headlessModule, reRegisterCallback, nativeProp, ~getCvc)
      None
    })

    React.null
  }
}

@react.component
let make = (~props) => isPrefetch(props) ? <PrefetchTask props /> : <SavedPaymentMethods props />
