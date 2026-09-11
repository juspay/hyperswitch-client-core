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
    | PaymentMethodsManagement =>
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

  // Native confirms through this widget's props: each call bumps `attempt`, and React
  // delivers it here whether the widget was already mounted or mounts afterwards, so no
  // confirm is ever lost to timing. The button handler of the render that saw the new
  // attempt is the one that runs, so it always sees the current form.
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
