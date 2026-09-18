open SdkTypes

let useNotifyValidationFailure = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  () => {
    switch nativeProp.sdkState {
    | PaymentSheet
    | ButtonSheet
    | TabSheet
    | WidgetPaymentSheet
    | WidgetButtonSheet
    | WidgetTabSheet
    | HostedCheckout
    | CardWidget
    | ExpressCheckoutWidget
    | PaymentMethodsManagement
    | WidgetPaymentMethodsManagement =>
      HyperModule.notifyWidgetPaymentResult(
        nativeProp.rootTag,
        PaymentConfirmTypes.formValidationError->HyperModule.resStatusPayload,
      )
    | _ => ()
    }
  }
}

let useWidgetActions = (~confirmButtonData: GlobalConfirmButton.confirmButtonData) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let attempt = nativeProp.widgetConfirm->Option.map(c => c.attempt)->Option.getOr(-1)
  React.useEffect1(() => {
    if attempt >= 0 {
      switch nativeProp.sdkState {
      | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet => confirmButtonData.handlePress()
      | _ => ()
      }
    }
    None
  }, [attempt])
}
