include PaymentEventData

let emitToNative = (~widgetId: string, ~eventType: string, ~payload: JSON.t) => {
  HyperModule.emitPaymentEvent(widgetId, eventType, payload)
}

type emitterFunctions = {
  emitCardInfo: (~info: cardInfo) => unit,
  emitPaymentMethodStatus: (~event: paymentMethodStatusEvent) => unit,
  emitFormStatus: (~event: formStatusEvent) => unit,
  emitPaymentMethodInfoAddress: (~info: paymentMethodInfoAddress) => unit,
  emitCvcStatus: (~event: cvcStatusEvent) => unit,
}

let usePaymentEventEmitter = (): emitterFunctions => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let subscribedEvents = nativeProp.subscribedEvents

  let emitCardInfo = (~info: cardInfo) => {
    if shouldEmitEvent(~eventType=PaymentMethodInfoCard, ~subscribedEvents) {
      emitToNative(
        ~widgetId=nativeProp.widgetId,
        ~eventType=PaymentEventTypes.eventToString(PaymentMethodInfoCard),
        ~payload=cardInfoToJson(info),
      )
    }
  }

  let emitPaymentMethodStatus = (~event: paymentMethodStatusEvent) => {
    if shouldEmitEvent(~eventType=PaymentMethodStatus, ~subscribedEvents) {
      emitToNative(
        ~widgetId=nativeProp.widgetId,
        ~eventType=PaymentEventTypes.eventToString(PaymentMethodStatus),
        ~payload=paymentMethodStatusEventToJson(
          ~paymentMethod=event.paymentMethod,
          ~paymentMethodType=event.paymentMethodType,
          ~isSavedPaymentMethod=event.isSavedPaymentMethod,
          ~isOneClickWallet=event.isOneClickWallet,
        ),
      )
    }
  }

  let emitFormStatus = (~event: formStatusEvent) => {
    if shouldEmitEvent(~eventType=FormStatus, ~subscribedEvents) {
      emitToNative(
        ~widgetId=nativeProp.widgetId,
        ~eventType=PaymentEventTypes.eventToString(FormStatus),
        ~payload=formStatusEventToJson(
          ~status=event.status->PaymentEventTypes.formStatusValueFromString,
        ),
      )
    }
  }

  let emitPaymentMethodInfoAddress = (~info: paymentMethodInfoAddress) => {
    if shouldEmitEvent(~eventType=PaymentMethodInfoBillingAddress, ~subscribedEvents) {
      emitToNative(
        ~widgetId=nativeProp.widgetId,
        ~eventType=PaymentEventTypes.eventToString(PaymentMethodInfoBillingAddress),
        ~payload=paymentMethodInfoAddressToJson(
          ~country=info.country,
          ~state=info.state,
          ~postalCode=info.postalCode,
        ),
      )
    }
  }

  let emitCvcStatus = (~event: cvcStatusEvent) => {
    if shouldEmitEvent(~eventType=CvcStatus, ~subscribedEvents) {
      emitToNative(
        ~widgetId=nativeProp.widgetId,
        ~eventType=PaymentEventTypes.eventToString(CvcStatus),
        ~payload=cvcStatusEventToJson(event),
      )
    }
  }

  {
    emitCardInfo,
    emitPaymentMethodStatus,
    emitFormStatus,
    emitPaymentMethodInfoAddress,
    emitCvcStatus,
  }
}
