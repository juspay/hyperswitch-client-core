let useBackHandler = (~loading: LoadingContext.sdkPaymentState, ~sdkState: SdkTypes.sdk_state) => {
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()

  React.useEffect2(() => {
    let backHandler = ReactNative.BackHandler.addEventListener(#hardwareBackPress, () => {
      switch loading {
      | ProcessingPayments | ProcessingPaymentsWithOverlay => ()
      | _ =>
        // Handle back press for both regular payment sheets and widgets
        let shouldHandleBack = [SdkTypes.PaymentSheet, SdkTypes.HostedCheckout]->Array.includes(sdkState) ||
          [SdkTypes.WidgetPaymentSheet, SdkTypes.WidgetTabSheet, SdkTypes.WidgetButtonSheet]->Array.includes(sdkState)
        
        if shouldHandleBack {
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
