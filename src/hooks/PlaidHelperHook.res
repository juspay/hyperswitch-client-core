open PaymentConfirmTypes
open LoadingContext

let usePlaidProps = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let getOpenProps = (
    retrievePayment: (Types.retrieve, string, string, ~isForceSync: bool=?) => promise<JSON.t>,
    responseCallback: (~paymentStatus: sdkPaymentState, ~status: error) => unit,
    errorCallback: (~errorMessage: error, ~closeSDK: bool, unit) => unit,
  ) => {
    PlaidTypes.onSuccess: success => {
      retrievePayment(
        Types.Payment,
        nativeProp.clientSecret,
        nativeProp.publishableKey,
        ~isForceSync=true,
      )
      ->Promise.then(res => {
        if res == JSON.Encode.null {
          errorCallback(~errorMessage=defaultConfirmError, ~closeSDK=true, ())
        } else {
          let status =
            res
            ->Utils.getDictFromJson
            ->Dict.get("status")
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr("")

          switch status {
          | "succeeded"
          | "requires_customer_action"
          | "processing" =>
            responseCallback(
              ~paymentStatus=PaymentSuccess,
              ~status={
                status: success.metadata.status->Option.getOr(""),
                message: success.metadata.metadataJson->Option.getOr("success message"),
                code: "",
                type_: "",
              },
            )
          | "requires_capture"
          | "requires_confirmation"
          | "cancelled"
          | "requires_merchant_action" =>
            ()
            responseCallback(
              ~paymentStatus=ProcessingPayments,
              ~status={status, message: "", code: "", type_: ""},
            )
          | _ =>
            errorCallback(
              ~errorMessage={
                status,
                message: "Payment is processing. Try again later!",
                type_: "sync_payment_failed",
                code: "",
              },
              ~closeSDK={true},
              (),
            )
          }
        }
        Promise.resolve()
      })
      ->ignore
    },
    onExit: linkExit => {
      Plaid.dismissLink()
      let error: error = {
        message: switch linkExit.error {
        | Some(err) => err.errorMessage
        | None => "unknown error"
        },
      }
      errorCallback(~errorMessage=error, ~closeSDK={true}, ())
    },
  }

  getOpenProps
}
