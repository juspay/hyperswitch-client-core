// Native calls the payment method management surfaces make, all to their own
// host's module (HyperModule.PaymentMethodManagementNative).

let useNotifyValidationFailure = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  () =>
    HyperModule.PaymentMethodManagementNative.notifyWidgetPaymentResult(
      nativeProp.rootTag,
      PaymentConfirmTypes.formValidationError->HyperModule.resStatusPayload,
    )
}

let setupWidgetActionListener = (~onWidgetAction: NativeModulesType.widgetActionData => unit) =>
  HyperModule.PaymentMethodManagementNative.subscribeTriggerWidgetAction(dict =>
    switch dict->NativeModulesType.widgetActionDataMapper {
    | Some(actionData) => onWidgetAction(actionData)
    | None => ()
    }
  )
