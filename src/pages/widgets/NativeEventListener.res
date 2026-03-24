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

let setupPaymentConfirmListener = (
  ~onConfirm: (string, string) => unit, // clientSecret, publishableKey
  ~paymentMethodType: string="card",
) => {
  sendReadyMessage(paymentMethodType)

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
  let formattedType = walletType->SdkTypes.widgetToStrMapper->String.toLowerCase
  sendReadyMessage(formattedType)

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
  sendReadyMessage("expressCheckout")
  setupNativeEventListener("confirmEC", var => {
    let responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
    onExpressCheckoutConfirm(responseFromJava)
  })
}

// Widget action event types
type goBackEvent = {
  widgetId: string,
  action: string,
}

type confirmPaymentEvent = {
  widgetId: string,
  action: string
}
type actionType = GoBack | ConfirmPayment

let setupWidgetActionListener = (~currentWidgetId: string, ~actionType=GoBack,  ~handler: () => unit) => {
  setupNativeEventListener("triggerWidgetAction", var => {
    let eventData = var->NativeModulesType.widgetActionEventObjectMapper
    switch (eventData, actionType) {
    | (GoBack({widgetId}), GoBack) => 
      if widgetId === currentWidgetId { handler() } else { () }
    | (ConfirmPayment({widgetId}), ConfirmPayment) => if widgetId === currentWidgetId { handler() } else { () }
    | _ => ()
    }
  })
}