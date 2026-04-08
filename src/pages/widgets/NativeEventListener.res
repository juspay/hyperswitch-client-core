open ReactNative

let setupNativeEventListener = (eventName, handler) => {
  let nativeEventEmitter = NativeEventEmitter.make(
    Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule"),
  )

  let eventSubscription = NativeEventEmitter.addListener(nativeEventEmitter, eventName, handler)

  () => {
    eventSubscription->EventSubscription.remove
  }
}

let sendReadyMessage = paymentMethodType => {
  HyperModule.sendMessageToNative(
    `{"isReady": "true", "paymentMethodType": "${paymentMethodType}"}`,
  )
}

// Hook to send ready event when widget is mounted and ready
let useSendReadyEvent = (~paymentMethodType: string) => {
  React.useEffect0(() => {
    sendReadyMessage(paymentMethodType)
    None
  })
}

let setupPaymentConfirmListener = (
  ~onConfirm: (string, string) => unit, // clientSecret, publishableKey
  ~paymentMethodType: string="card",
) => {
  setupNativeEventListener("confirm", var => {
    let responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
    onConfirm(responseFromJava.clientSecret, responseFromJava.publishableKey)
  })
}

type widgetResponse = {
  clientSecret: string,
  publishableKey: string,
  confirm: bool,
  paymentMethodType: string,
}
let setupWidgetEventListener = (
  ~onWidgetEvent: widgetResponse => unit,
  ~walletType: SdkTypes.payment_method_type_wallet,
) => {
  setupNativeEventListener("widget", var => {
    let responseFromJava = {
      let mapped = var->PaymentConfirmTypes.itemToObjMapperJava
      {
        clientSecret: mapped.clientSecret,
        publishableKey: mapped.publishableKey,
        confirm: mapped.confirm,
        paymentMethodType: mapped.paymentMethodType,
      }
    }
    onWidgetEvent(responseFromJava)
  })
}

let setupExpressCheckoutListener = (
  ~onExpressCheckoutConfirm: PaymentConfirmTypes.responseFromJava => unit,
) => {
  setupNativeEventListener("confirmEC", var => {
    let responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
    onExpressCheckoutConfirm(responseFromJava)
  })
}

let setupWidgetActionListener = (~onWidgetAction: NativeModulesType.widgetActionData => unit) => {
  setupNativeEventListener("triggerWidgetAction", var => {
    switch var->JSON.Decode.object {
    | Some(dict) =>
      switch dict->NativeModulesType.widgetActionDataMapper {
      | Some(actionData) => onWidgetAction(actionData)
      | None => ()
      }
    | None => ()
    }
  })
}
