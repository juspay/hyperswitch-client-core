let setupNativeEventListener = (eventName, handler) => {
  // Single transport: the codegen typed EventEmitters on the HyperModule
  // TurboModule (new-arch native). No RCTDeviceEventEmitter channel and no
  // fallback subscription — the native side delivers all bundle events
  // through these emitters.
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
    let mapped = var->PaymentConfirmTypes.itemToObjMapperJava
    onWidgetEvent({
      clientSecret: mapped.clientSecret,
      publishableKey: mapped.publishableKey,
      confirm: mapped.confirm,
      paymentMethodType: mapped.paymentMethodType,
    })
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
