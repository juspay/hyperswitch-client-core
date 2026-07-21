open SdkTypes

let useNotifyValidationFailure = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  (~message = None) => {
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
    let updatedError = switch message {
    | Some(msg) =>
      {
        ...PaymentConfirmTypes.formValidationError,
        message: msg,
      }
    | None => PaymentConfirmTypes.formValidationError
    }
      HyperModule.hyperModule.notifyWidgetPaymentResult(
        nativeProp.rootTag,
        updatedError
        ->HyperModule.stringifiedResStatus,
      )
    | _ => ()
    }
  }
}

let useWidgetActions = (~confirmButtonData: GlobalConfirmButton.confirmButtonData) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  React.useEffect2(() => {
    // Only setup widget action listener for widget states
    let shouldSetupListener = switch nativeProp.sdkState {
    | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet => true
    | _ => false
    }

    if shouldSetupListener {
      let unsubscribe = NativeEventListener.setupWidgetActionListener(~onWidgetAction=(
        actionData: NativeModulesType.widgetActionData,
      ) => {
        switch actionData.actionType {
        | ConfirmPayment =>
          if actionData.rootTag === nativeProp.rootTag {
            confirmButtonData.handlePress()
          }
        | ConfirmCvcPayment => () // Handled by CvcWidget.res directly
        }
      })

      Some(unsubscribe)
    } else {
      None
    }
  }, (nativeProp.sdkState, confirmButtonData))
}
