let useUpiPolling = () => {
  let retrievePayment = AllPaymentHooks.useRetrieveHook()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  (~responseCallback, ~errorCallback) => {
    let rec shortPollUpiStatus = (
      ~pollConfig: PaymentConfirmTypes.waitScreenPollConfig,
      ~pollCount,
      ~displayToTimestamp: float,
    ) => {
      let now = Date.now()
      let endTime = displayToTimestamp /. 1_000_000.

      if now >= endTime {
        errorCallback(
          ~errorMessage={
            PaymentConfirmTypes.status: "failed",
            message: "Payment timeout - maximum time exceeded",
            code: "",
            type_: "",
          },
          ~closeSDK=true,
          (),
        )
      } else if pollCount >= pollConfig.frequency {
        errorCallback(
          ~errorMessage={
            PaymentConfirmTypes.status: "failed",
            message: "Payment timeout",
            code: "",
            type_: "",
          },
          ~closeSDK=true,
          (),
        )
      } else {
        setLoading(FillingDetails)

        retrievePayment(Payment, nativeProp.clientSecret, nativeProp.publishableKey)
        ->Promise.then(response => {
          let status = response->Utils.getDictFromJson->Utils.getString("status", "")

          switch status {
          | "succeeded" =>
            responseCallback(
              ~paymentStatus=LoadingContext.PaymentSuccess,
              ~status={
                PaymentConfirmTypes.status: "succeeded",
                message: "",
                code: "",
                type_: "",
              },
            )
            Promise.resolve()
          | "failed" =>
            errorCallback(
              ~errorMessage={
                PaymentConfirmTypes.status: "failed",
                message: "",
                code: "",
                type_: "",
              },
              ~closeSDK=true,
              (),
            )
            Promise.resolve()
          | _ =>
            Promise.make((_resolve, _reject) => {
              setTimeout(
                () => {
                  shortPollUpiStatus(~pollConfig, ~pollCount=pollCount + 1, ~displayToTimestamp)
                },
                pollConfig.delay_in_secs * 1000,
              )->ignore
            })
          }
        })
        ->Promise.catch(_err => {
          Promise.make((_resolve, _reject) => {
            setTimeout(
              () => {
                shortPollUpiStatus(~pollConfig, ~pollCount=pollCount + 1, ~displayToTimestamp)
              },
              pollConfig.delay_in_secs * 1000,
            )->ignore
          })
        })
        ->ignore
      }
    }

    shortPollUpiStatus
  }
}
