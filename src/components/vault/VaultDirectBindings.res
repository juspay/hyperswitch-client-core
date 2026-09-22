// Direct bindings for @juspay-tech/react-native-hyperswitch-vault.
// These cover the deprecation-free props of the vault SDK: appearance (theming),
// errorDisplay, labelBehavior, cardBrandIcon, ref-based tokenize.
//
// `tokenize(paymentMethodData?)` — the optional host paymentMethodData
// ({ nickName: ... }) is forwarded by the vault to the payment-method-session
// `confirm` call when the card is minted.

type viewStyleProp = ReactNative.Style.t
type textStyleProp = ReactNative.Style.t

type fieldStyles = {
  root?: viewStyleProp,
  container?: viewStyleProp,
  input?: textStyleProp,
  placeholder?: textStyleProp,
  label?: textStyleProp,
  error?: textStyleProp,
  accessory?: viewStyleProp,
}

type fieldHandleSubmit = {@as("focus") focus: unit => unit, blur: unit => unit, clear: unit => unit}
type fieldRef = React.ref<Nullable.t<fieldHandleSubmit>>
let focusField = (reference: fieldRef) =>
  reference.current->Nullable.toOption->Option.forEach(handle => handle.focus())

type rec vaultFormHandle = {tokenize: option<JSON.t> => promise<tokenizeResult>}
and tokenizeResult = {
  status: string,
  token?: string,
  error?: vaultError,
}
and vaultError = {
  code: string,
  message: string,
  @as("type") type_: string,
}

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

type vaultFormFields = {
  cardNumber: fieldChange,
  cardExpiry: fieldChange,
  cardCvc: fieldChange,
  cardholderName?: fieldChange,
}

// Matches the vault's NativeEventTypes: absent values arrive as `undefined`.
type cardDetails = {
  bin?: string,
  last4?: string,
  brand?: string,
  expiryMonth?: string,
  expiryYear?: string,
  formattedExpiry?: string,
  isCardNumberComplete: bool,
  isCvcComplete: bool,
  isExpiryComplete: bool,
  isCardNumberValid: bool,
  isExpiryValid: bool,
}

type cardFormEvent = {elementType: string}

type cardFormChange = {
  elementType: string,
  eventName: string,
  payload: cardDetails,
  fieldsReady: bool,
  complete: bool,
  valid: bool,
  submitting: bool,
  canSubmit: bool,
  fields: vaultFormFields,
}

type cardNumberOptions = {
  placeholder?: string,
  labelBehavior?: string,
  errorDisplay?: string,
  cardBrandIcon?: string,
  unstyled?: bool,
}

module CardForm = {
  @module("@juspay-tech/react-native-hyperswitch-vault") @react.component
  external make: (
    ~ref: React.ref<Nullable.t<vaultFormHandle>>=?,
    ~vaultDetails: JSON.t=?,
    ~environment: string=?,
    ~appearance: JSON.t=?,
    // PMM parity with the web SDK: the management save always stamps the
    // payment-method-session confirm with `customer_acceptance`.
    ~alwaysSendCustomerAcceptance: bool=?,
    ~children: React.element,
    ~onChange: cardFormChange => unit=?,
    ~onReady: cardFormEvent => unit=?,
  ) => React.element = "CardForm"
}

module CardNumberField = {
  @module("@juspay-tech/react-native-hyperswitch-vault") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~labelBehavior: string=?,
    ~errorDisplay: string=?,
    ~cardBrandIcon: string=?,
    ~unstyled: bool=?,
    ~testID: string=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
    ~onReady: fieldEvent => unit=?,
  ) => React.element = "CardNumberField"
}

module CardExpiryField = {
  @module("@juspay-tech/react-native-hyperswitch-vault") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~labelBehavior: string=?,
    ~errorDisplay: string=?,
    ~unstyled: bool=?,
    ~testID: string=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
    ~onReady: fieldEvent => unit=?,
  ) => React.element = "CardExpiryField"
}

module CardCVCField = {
  @module("@juspay-tech/react-native-hyperswitch-vault") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~labelBehavior: string=?,
    ~errorDisplay: string=?,
    ~unstyled: bool=?,
    ~testID: string=?,
    ~options: cardNumberOptions=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
    ~onReady: fieldEvent => unit=?,
  ) => React.element = "CardCVCField"
}

module CardholderNameField = {
  @module("@juspay-tech/react-native-hyperswitch-vault") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~labelBehavior: string=?,
    ~errorDisplay: string=?,
    ~unstyled: bool=?,
    ~testID: string=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
    ~onReady: fieldEvent => unit=?,
  ) => React.element = "CardholderNameField"
}
