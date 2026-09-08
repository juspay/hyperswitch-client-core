type fieldStyles = {
  container?: ReactNative.Style.t,
  input?: ReactNative.Style.t,
}

type fieldHandle = {focus: unit => unit, blur: unit => unit, clear: unit => unit}
type fieldRef = React.ref<Nullable.t<fieldHandle>>
let focusField = (reference: fieldRef) => reference.current->Nullable.toOption->Option.forEach(handle => handle.focus())

type fieldEvent = {elementType: string}

type fieldChange = {
  elementType: string,
  empty: bool,
  complete: bool,
  valid: bool,
  brand?: string,
  error?: string,
  touched: bool,
}

type savedCardData = {cardNetwork?: string}
type savedCardPaymentMethodData = {card?: savedCardData}

type savedCard = {
  paymentMethodToken?: string,
  paymentMethodData?: savedCardPaymentMethodData,
}

type fieldOptions = {savedCard?: savedCard}

type cardFormEvent = {elementType: string}

type cardDetails = {
  bin: Nullable.t<string>,
  last4: Nullable.t<string>,
  brand: Nullable.t<string>,
  expiryMonth: Nullable.t<string>,
  expiryYear: Nullable.t<string>,
  formattedExpiry: Nullable.t<string>,
  isCardNumberComplete: bool,
  isCvcComplete: bool,
  isExpiryComplete: bool,
  isCardNumberValid: bool,
  isExpiryValid: bool,
}

type cardFormChange = {
  elementType: string,
  eventName: string,
  payload: cardDetails,
  complete: bool,
  valid: bool,
  fields: Dict.t<fieldChange>,
}

type tokenizeError = {
  code: string,
  message: string,
  @as("type") type_: string,
}

type tokenizeData = {tokens?: Dict.t<JSON.t>}

type tokenizeResult = {
  status: string,
  vaultType?: string,
  data?: tokenizeData,
  error?: tokenizeError,
}

module CardForm = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~id: string=?,
    ~vaultDetails: JSON.t=?,
    ~onReady: cardFormEvent => unit=?,
    ~onChange: cardFormChange => unit=?,
    ~onError: JSON.t => unit=?,
    ~children: React.element,
  ) => React.element = "CardForm"
}

module CardNumberField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~unstyled: bool=?,
    ~onReady: fieldEvent => unit=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~testID: string=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
  ) => React.element = "CardNumberField"
}

module CardExpiryField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~unstyled: bool=?,
    ~onReady: fieldEvent => unit=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~testID: string=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
  ) => React.element = "CardExpiryField"
}

module CardCVCField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~unstyled: bool=?,
    ~onReady: fieldEvent => unit=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~testID: string=?,
    ~options: fieldOptions=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
  ) => React.element = "CardCVCField"
}

type hyperswitchPaymentMethods

@module("@juspay-tech/react-native-hyperswitch-payment-methods")
external hyperswitchPaymentMethods: hyperswitchPaymentMethods = "HyperswitchPaymentMethods"

@send
external tokenize: (hyperswitchPaymentMethods, string) => promise<tokenizeResult> = "tokenize"

let tokenizeForm = (formId: string): promise<tokenizeResult> =>
  hyperswitchPaymentMethods->tokenize(formId)
