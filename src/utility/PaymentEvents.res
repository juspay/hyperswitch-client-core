include PaymentEventData

let emitToNative = (~rootTag: int, ~eventType: string, ~payload: JSON.t) => {
  HyperModule.emitPaymentEvent(rootTag, eventType, payload)
}

// Lifecycle events (ready/focus/blur) need no subscription; they live in ElementEventsContext.
let emitIfSubscribed = (nativeProp: SdkTypes.nativeProp, eventType, buildPayload) =>
  if shouldEmitEvent(~eventType, ~subscribedEvents=nativeProp.configuration.subscribedEvents) {
    emitToNative(
      ~rootTag=nativeProp.rootTag,
      ~eventType=PaymentEventTypes.eventToString(eventType),
      ~payload=buildPayload(),
    )
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
  {
    emitCardInfo: (~info) =>
      emitIfSubscribed(nativeProp, CardDetailsChange, () => cardInfoToJson(info)),
    emitPaymentMethodStatus: (~event) =>
      emitIfSubscribed(nativeProp, PaymentMethodChange, () =>
        paymentMethodStatusEventToJson(
          ~paymentMethod=event.paymentMethod,
          ~paymentMethodType=event.paymentMethodType,
          ~isSavedPaymentMethod=event.isSavedPaymentMethod,
          ~isOneClickWallet=event.isOneClickWallet,
        )
      ),
    emitFormStatus: (~event) =>
      emitIfSubscribed(nativeProp, FormStatusChange, () =>
        formStatusEventToJson(~status=event.status->PaymentEventTypes.formStatusValueFromString)
      ),
    emitPaymentMethodInfoAddress: (~info) =>
      emitIfSubscribed(nativeProp, BillingDetailsChange, () =>
        paymentMethodInfoAddressToJson(
          ~country=info.country,
          ~state=info.state,
          ~postalCode=info.postalCode,
        )
      ),
    emitCvcStatus: (~event) =>
      emitIfSubscribed(nativeProp, CvcStatusChange, () => cvcStatusEventToJson(event)),
  }
}
