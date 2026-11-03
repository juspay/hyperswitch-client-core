include PaymentEventData

let emitToNative = (~rootTag: int, ~eventType: string, ~payload: JSON.t) => {
  HyperModule.emitPaymentEvent(rootTag, eventType, payload)
}

type emitterFunctions = {
  emitCardInfo: (~info: cardInfo) => unit,
  emitPaymentMethodStatus: (~event: paymentMethodStatusEvent) => unit,
  emitFormStatus: (~event: formStatusEvent) => unit,
  emitPaymentMethodInfoAddress: (~info: paymentMethodInfoAddress) => unit,
  emitCvcStatus: (~event: cvcStatusEvent) => unit,
  emitCustomMessageElementClicked: (~event: PaymentMessageTypes.elementClickedEvent) => unit,
}

let usePaymentEventEmitter = (): emitterFunctions => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let subscribedEvents = nativeProp.configuration.subscribedEvents

  let emitCardInfo = (~info: cardInfo) => {
    if shouldEmitEvent(~eventType=CardDetailsChange, ~subscribedEvents) {
      emitToNative(
        ~rootTag=nativeProp.rootTag,
        ~eventType=PaymentEventTypes.eventToString(CardDetailsChange),
        ~payload=cardInfoToJson(info),
      )
    }
  }

  let emitPaymentMethodStatus = (~event: paymentMethodStatusEvent) => {
    if shouldEmitEvent(~eventType=PaymentMethodChange, ~subscribedEvents) {
      emitToNative(
        ~rootTag=nativeProp.rootTag,
        ~eventType=PaymentEventTypes.eventToString(PaymentMethodChange),
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
    if shouldEmitEvent(~eventType=FormStatusChange, ~subscribedEvents) {
      emitToNative(
        ~rootTag=nativeProp.rootTag,
        ~eventType=PaymentEventTypes.eventToString(FormStatusChange),
        ~payload=formStatusEventToJson(
          ~status=event.status->PaymentEventTypes.formStatusValueFromString,
        ),
      )
    }
  }

  let emitPaymentMethodInfoAddress = (~info: paymentMethodInfoAddress) => {
    if shouldEmitEvent(~eventType=BillingDetailsChange, ~subscribedEvents) {
      emitToNative(
        ~rootTag=nativeProp.rootTag,
        ~eventType=PaymentEventTypes.eventToString(BillingDetailsChange),
        ~payload=paymentMethodInfoAddressToJson(
          ~country=info.country,
          ~state=info.state,
          ~postalCode=info.postalCode,
        ),
      )
    }
  }

  let emitCvcStatus = (~event: cvcStatusEvent) => {
    if shouldEmitEvent(~eventType=CvcStatusChange, ~subscribedEvents) {
      emitToNative(
        ~rootTag=nativeProp.rootTag,
        ~eventType=PaymentEventTypes.eventToString(CvcStatusChange),
        ~payload=cvcStatusEventToJson(event),
      )
    }
  }

  let emitCustomMessageElementClicked = (~event: PaymentMessageTypes.elementClickedEvent) => {
    if shouldEmitEvent(~eventType=CustomMessageElementClicked, ~subscribedEvents) {
      let payload =
        [
          ("key", event.key->JSON.Encode.string),
          ("type", event.\"type"->JSON.Encode.string),
          ("paymentMethod", event.paymentMethod->JSON.Encode.string),
          ("paymentMethodType", event.paymentMethodType->JSON.Encode.string),
        ]->Dict.fromArray
      emitToNative(
        ~rootTag=nativeProp.rootTag,
        ~eventType=PaymentEventTypes.eventToString(CustomMessageElementClicked),
        ~payload=payload->JSON.Encode.object,
      )
    }
  }

  {
    emitCardInfo,
    emitPaymentMethodStatus,
    emitFormStatus,
    emitPaymentMethodInfoAddress,
    emitCvcStatus,
    emitCustomMessageElementClicked,
  }
}
