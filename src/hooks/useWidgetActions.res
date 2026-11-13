open SdkTypes

let useNotifyWidgetResult = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  (error: PaymentConfirmTypes.error) => {
    switch nativeProp.sdkState {
    | PaymentSheet
    | ButtonSheet
    | TabSheet
    | WidgetPaymentSheet
    | WidgetButtonSheet
    | WidgetTabSheet
    | HostedCheckout
    | CardWidget
    | ExpressCheckoutWidget =>
      HyperModule.notifyWidgetPaymentResult(nativeProp.rootTag, error->HyperModule.resStatusPayload)
    | _ => ()
    }
  }
}

let useNotifyValidationFailure = () => {
  let notify = useNotifyWidgetResult()
  () => notify(PaymentConfirmTypes.formValidationError)
}

let useNotifyNotReady = () => {
  let notify = useNotifyWidgetResult()
  () => notify(PaymentConfirmTypes.widgetNotReadyError)
}

let useWidgetActions = (~confirmButtonData: GlobalConfirmButton.confirmButtonData) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let notifyNotReady = useNotifyNotReady()

  let attempt = nativeProp.widgetConfirm->Option.map(c => c.attempt)->Option.getOr(-1)
  let credentialsKey = PaymentUtils.getSessionCredentialsKey(nativeProp)
  let handled = React.useRef(-1)
  // An attempt can be held back for a render; it is still one confirm from native.
  let logged = React.useRef(-1)
  // The attempt that was held back for a render, and the state that brings that render about.
  let held = React.useRef(-1)
  let (heldRender, setHeldRender) = React.useState(_ => 0)
  React.useEffect4(() => {
    if attempt >= 0 && handled.current !== attempt {
      switch nativeProp.sdkState {
      | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet =>
        if logged.current !== attempt {
          logged.current = attempt
          SdkLogger.logUser(
            ~event=PaymentSubmitted({source: MerchantApi}),
            ~details=[("attempt", attempt->JSON.Encode.int)],
            ~paymentMethod=?confirmButtonData.payment_method_type->LoggerPaymentMethod.ofTypeName,
          )
        }
        switch confirmButtonData.credentialsKey {
        | Some(key) if key === credentialsKey =>
          handled.current = attempt
          confirmButtonData.handlePress()
        | Some(_) if held.current !== attempt =>
          held.current = attempt
          setHeldRender(render => render + 1)
        | Some(_) | None =>
          handled.current = attempt
          notifyNotReady()
        }
      | _ => handled.current = attempt
      }
    }
    None
  }, (attempt, credentialsKey, confirmButtonData, heldRender))
}
