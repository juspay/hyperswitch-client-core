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

type cvcConfirmRequest = {
  clientSecret: string,
  publishableKey: string,
  cardNetwork: string,
  requiresCvv: bool,
}

let parseCvcConfirmRequest = dict => {
  {
    clientSecret: Utils.getString(dict, "clientSecret", ""),
    publishableKey: Utils.getString(dict, "publishableKey", ""),
    cardNetwork: Utils.getString(dict, "cardNetwork", ""),
    requiresCvv: Utils.getBool(dict, "requiresCvv", true),
  }
}

let setupCvcWidgetListener = (~onCvcConfirmRequest: cvcConfirmRequest => unit) => {
  sendReadyMessage("cvc")
  setupNativeEventListener("confirmCVC", var => {
    let request = var->parseCvcConfirmRequest
    onCvcConfirmRequest(request)
  })
}
