open SdkTypes

let useNotifyValidationFailure = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  () => {
    switch nativeProp.sdkState {
    | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet =>
      HyperModule.hyperModule.notifyWidgetPaymentResult(
        nativeProp.rootTag,
        PaymentConfirmTypes.formValidationError->HyperModule.stringifiedResStatus,
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
        }
      })

      Some(unsubscribe)
    } else {
      None
    }
  }, (nativeProp.sdkState, confirmButtonData))
}
