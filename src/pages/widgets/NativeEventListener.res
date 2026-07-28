// Native -> JS events arrive through the HyperModule TurboModule's typed
// event emitters, surfaced as subscribe* functions on HyperModuleNative and
// bound in HyperModule.res. Each subscribe function returns an unsubscribe
// thunk (no-op when the native module is absent, e.g. on web).
//
// Subscribing also tells native that this event now has a JS listener, which
// is what releases any events native queued before the subscribing React tree
// mounted — so the unsubscribe thunk MUST be returned to React from every
// effect that calls these, or native will go on queueing.
let setupNativeEventListener = (eventName, handler) => {
  switch eventName {
  | "confirm" => HyperModule.Events.subscribeConfirm(handler)
  | "widget" => HyperModule.Events.subscribeWidget(handler)
  | "confirmEC" => HyperModule.Events.subscribeConfirmEC(handler)
  | "triggerWidgetAction" => HyperModule.Events.subscribeTriggerWidgetAction(handler)
  | "updateIntentInit" => HyperModule.Events.subscribeUpdateIntentInit(handler)
  | "updateIntentComplete" => HyperModule.Events.subscribeUpdateIntentComplete(handler)
  | _ => () => ()
  }
}

// Signals that a payment method's UI is mounted and ready. Drives
// WidgetLauncher.onPaymentReadyCallback on Android and is a no-op on iOS.
// It is NOT an event-delivery handshake: events are fire-and-forget on both
// platforms, so this is sent after listeners attach purely for ordering.
let sendReadyMessage = paymentMethodType => {
  HyperModule.sendMessageToNative(
    `{"isReady": "true", "paymentMethodType": "${paymentMethodType}"}`,
  )
}

let setupPaymentConfirmListener = (
  ~onConfirm: (string, string) => unit, // clientSecret, publishableKey
  ~paymentMethodType: string="card",
) => {
  let unsubscribe = setupNativeEventListener("confirm", var => {
    let responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
    onConfirm(responseFromJava.clientSecret, responseFromJava.publishableKey)
  })
  sendReadyMessage(paymentMethodType)
  unsubscribe
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

  let unsubscribe = setupNativeEventListener("widget", var => {
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
  sendReadyMessage(formattedType)
  unsubscribe
}

// Deprecated: express checkout is no longer a supported surface. Kept only so
// the existing ExpressCheckoutWidget page still compiles.
let setupExpressCheckoutListener = (
  ~onExpressCheckoutConfirm: PaymentConfirmTypes.responseFromJava => unit,
) => {
  let unsubscribe = setupNativeEventListener("confirmEC", var => {
    let responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
    onExpressCheckoutConfirm(responseFromJava)
  })
  sendReadyMessage("expressCheckout")
  unsubscribe
}

let setupWidgetActionListener = (~onWidgetAction: NativeModulesType.widgetActionData => unit) => {
  setupNativeEventListener("triggerWidgetAction", dict => {
    switch dict->NativeModulesType.widgetActionDataMapper {
    | Some(actionData) => onWidgetAction(actionData)
    | None => ()
    }
  })
}

let setupUpdateIntentInitListener = (
  ~onUpdateIntentInit: NativeModulesType.updateIntentData => unit,
) => {
  setupNativeEventListener("updateIntentInit", dict => {
    switch NativeModulesType.updateIntentDataMapper("updateIntentInit", dict) {
    | Some(intentData) => onUpdateIntentInit(intentData)
    | None => ()
    }
  })
}

let setupUpdateIntentCompleteListener = (
  ~onUpdateIntentComplete: NativeModulesType.updateIntentData => unit,
) => {
  setupNativeEventListener("updateIntentComplete", dict => {
    switch NativeModulesType.updateIntentDataMapper("updateIntentComplete", dict) {
    | Some(intentData) => onUpdateIntentComplete(intentData)
    | None => ()
    }
  })
}
