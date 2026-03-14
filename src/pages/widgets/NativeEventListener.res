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
  params: Js.Json.t,
}

// Parse JSON string to event objects
let parseGoBackEvent = (jsonString: string): option<goBackEvent> => {
  try {
    let parsed = Js.Json.parseExn(jsonString)
    let dict = parsed->Js.Json.decodeObject
    switch dict {
    | Some(d) =>
      let widgetId = d->Dict.get("widgetId")->Option.flatMap(Js.Json.decodeString)->Option.getOr("")
      let action = d->Dict.get("action")->Option.flatMap(Js.Json.decodeString)->Option.getOr("")
      Some({widgetId, action})
    | None => None
    }
  } catch {
  | _ => None
  }
}

let parseConfirmPaymentEvent = (jsonString: string): option<confirmPaymentEvent> => {
  try {
    let parsed = Js.Json.parseExn(jsonString)
    let dict = parsed->Js.Json.decodeObject
    switch dict {
    | Some(d) =>
      let widgetId = d->Dict.get("widgetId")->Option.flatMap(Js.Json.decodeString)->Option.getOr("")
      let params = d->Dict.get("params")->Option.getOr(Js.Json.null)
      Some({widgetId, params})
    | None => None
    }
  } catch {
  | _ => None
  }
}

// Setup listeners for widget actions with widgetId filtering
let setupWidgetGoBackListener = (
  ~currentWidgetId: string,
  ~onGoBack: unit => unit,
) => {
  setupNativeEventListener("WidgetGoBack", var => {
    let eventJson = var->Js.Json.decodeString->Option.getOr("")
    switch parseGoBackEvent(eventJson) {
    | Some(event) =>
      // Only handle event if widgetId matches
      if event.widgetId === currentWidgetId {
        onGoBack()
      }
    | None => ()
    }
  })
}

let setupWidgetConfirmPaymentListener = (
  ~currentWidgetId: string,
  ~onConfirmPayment: Js.Json.t => unit,
) => {
  setupNativeEventListener("WidgetConfirmPayment", var => {
    let eventJson = var->Js.Json.decodeString->Option.getOr("")
    switch parseConfirmPaymentEvent(eventJson) {
    | Some(event) =>
      // Only handle event if widgetId matches
      if event.widgetId === currentWidgetId {
        onConfirmPayment(event.params)
      }
    | None => ()
    }
  })
}
