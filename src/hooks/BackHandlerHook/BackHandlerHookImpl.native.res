let useBackHandler = (~loading: LoadingContext.sdkPaymentState, ~sdkState: SdkTypes.sdkState) => {
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()

  React.useEffect2(() => {
    let backHandler = ReactNative.BackHandler.addEventListener(#hardwareBackPress, () => {
      switch loading {
      | ProcessingPayments | ProcessingPaymentsWithOverlay => ()
      | _ =>
        if [SdkTypes.PaymentSheet, SdkTypes.HostedCheckout]->Array.includes(sdkState) {
          handleSuccessFailure(
            ~apiResStatus=PaymentConfirmTypes.defaultCancelError,
            ~closeSDK=true,
            ~reset=false,
            (),
          )
        }
      }
      true
    })

    Some(() => backHandler["remove"]())
  }, (loading, sdkState))
}
