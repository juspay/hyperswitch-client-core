open SdkTypes

let useWidgetActions = (
  ~confirmButtonData: GlobalConfirmButton.confirmButtonData,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  React.useEffect2(() => {
    // Only setup widget action listener for widget states
    let shouldSetupListener = switch nativeProp.sdkState {
    | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet => true
    | _ => false
    }

    if shouldSetupListener {
      let unsubscribe = NativeEventListener.setupWidgetActionListener(
        ~onWidgetAction=(actionData: NativeModulesType.widgetActionData) => {
            switch actionData.actionType {
            | ConfirmPayment =>
              // Trigger the confirm button press
              confirmButtonData.handlePress(Obj.magic(()))
            }
        },
      )

      Some(unsubscribe)
    } else {
      None
    }
  }, (nativeProp.sdkState, confirmButtonData))
}
