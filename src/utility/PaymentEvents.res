include PaymentEventData

let emitToNative = (~widgetId: string, ~eventType: string, ~payload: JSON.t) => {
  HyperModule.emitPaymentEvent(widgetId, eventType, payload)
}

type emitterFunctions = {
  emitCardInfo: (~info: cardInfo) => unit,
  emitPaymentMethodStatus: (~event: paymentMethodStatusEvent) => unit,
  emitFormStatus: (~event: formStatusEvent) => unit,
  emitPaymentMethodInfoAddress: (~info: paymentMethodInfoAddress) => unit,
}

let usePaymentEventEmitter = (): emitterFunctions => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let subscribedEvents = nativeProp.subscribedEvents

  let emitCardInfo = (~info: cardInfo) => {
    if shouldEmitEvent(~eventType=PaymentMethodInfoCard, ~subscribedEvents) {
      emitToNative(
        ~widgetId=nativeProp.widgetId->Option.getOr(""),
        ~eventType=PaymentEventTypes.toString(PaymentMethodInfoCard),
        ~payload=cardInfoToJson(info),
      )
    }
  }

  let emitPaymentMethodStatus = (~event: paymentMethodStatusEvent) => {
    if shouldEmitEvent(~eventType=PaymentMethodStatus, ~subscribedEvents) {
      emitToNative(
        ~widgetId=nativeProp.widgetId->Option.getOr(""),
        ~eventType=PaymentEventTypes.toString(PaymentMethodStatus),
        ~payload=paymentMethodStatusEventToJson(event),
      )
    }
  }

  let emitFormStatus = (~event: formStatusEvent) => {
    if shouldEmitEvent(~eventType=FormStatus, ~subscribedEvents) {
      emitToNative(
        ~widgetId=nativeProp.widgetId->Option.getOr(""),
        ~eventType=PaymentEventTypes.toString(FormStatus),
        ~payload=formStatusEventToJson(event),
      )
    }
  }

  let emitPaymentMethodInfoAddress = (~info: paymentMethodInfoAddress) => {
    if shouldEmitEvent(~eventType=PaymentMethodInfoAddress, ~subscribedEvents) {
      emitToNative(
        ~widgetId=nativeProp.widgetId->Option.getOr(""),
        ~eventType=PaymentEventTypes.toString(PaymentMethodInfoAddress),
        ~payload=paymentMethodInfoAddressToJson(info),
      )
    }
  }

  {emitCardInfo, emitPaymentMethodStatus, emitFormStatus, emitPaymentMethodInfoAddress}
}
