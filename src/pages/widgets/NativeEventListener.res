let setupNativeEventListener = (eventName, handler) => {
  switch eventName {
  | "confirm" => HyperModule.Events.subscribeConfirm(handler)
  | "widget" => HyperModule.Events.subscribeWidget(handler)
  | "confirmEC" => HyperModule.Events.subscribeConfirmEC(handler)
  | _ => () => ()
  }
}

let setupPaymentConfirmListener = (~onConfirm: (string, string) => unit) => {
  // clientSecret, publishableKey

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

// Deprecated: express checkout is no longer a supported surface. Kept only so
// the existing ExpressCheckoutWidget page still compiles.
let setupExpressCheckoutListener = (
  ~onExpressCheckoutConfirm: PaymentConfirmTypes.responseFromJava => unit,
) => {
  setupNativeEventListener("confirmEC", var => {
    let responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
    onExpressCheckoutConfirm(responseFromJava)
  })
}
