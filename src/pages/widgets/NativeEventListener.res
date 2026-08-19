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

let setupPaymentConfirmListener = (
  ~onConfirm: (string, string) => unit, // clientSecret, publishableKey
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
let setupWidgetEventListener = (~onWidgetEvent: widgetResponse => unit) => {
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
