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
    if shouldEmitEvent(~eventType=PaymentMethodInfoCard, ~subscribedEvents) {
      emitToNative(
        ~rootTag=nativeProp.rootTag,
        ~eventType=PaymentEventTypes.eventToString(PaymentMethodInfoCard),
        ~payload=cardInfoToJson(info),
      )
    }
  }

  let emitPaymentMethodStatus = (~event: paymentMethodStatusEvent) => {
    if shouldEmitEvent(~eventType=PaymentMethodStatus, ~subscribedEvents) {
      emitToNative(
        ~rootTag=nativeProp.rootTag,
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
        ~rootTag=nativeProp.rootTag,
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
        ~rootTag=nativeProp.rootTag,
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
        ~rootTag=nativeProp.rootTag,
        ~eventType=PaymentEventTypes.eventToString(CvcStatus),
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
