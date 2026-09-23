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

// The vault package is a chunk of its own (hyperswitch.vault.chunk.bundle), loaded
// when a card form first renders, never at startup. Each component below keeps
// the vault component's props and renders it once the chunk is in, inside a
// Suspense boundary of its own so a field loading never hides the form.
type vaultModule

external importVault: string => promise<vaultModule> = "import"

// The literal specifier lets the bundler resolve and split the package.
let loadVault = () => importVault("@juspay-tech/react-native-hyperswitch-vault")

let fromVault = (pick: vaultModule => React.component<'props>): React.component<'props> => {
  let component = React.lazy_(() => loadVault()->Promise.thenResolve(pick))
  props => <React.Suspense fallback=React.null> {React.createElement(component, props)} </React.Suspense>
}

module CardForm = {
  type props = {
    ref?: React.ref<Nullable.t<vaultFormHandle>>,
    vaultDetails?: JSON.t,
    environment?: string,
    appearance?: JSON.t,
    // PMM parity with the web SDK: the management save always stamps the
    // payment-method-session confirm with `customer_acceptance`.
    alwaysSendCustomerAcceptance?: bool,
    children: React.element,
    onChange?: cardFormChange => unit,
    onReady?: cardFormEvent => unit,
  }
  @get external pick: vaultModule => React.component<props> = "CardForm"
  let make = fromVault(pick)
}

module CardNumberField = {
  type props = {
    ref?: fieldRef,
    styles?: fieldStyles,
    placeholder?: string,
    labelBehavior?: string,
    errorDisplay?: string,
    cardBrandIcon?: string,
    unstyled?: bool,
    testID?: string,
    onChange?: fieldChange => unit,
    onFocus?: fieldEvent => unit,
    onBlur?: fieldEvent => unit,
    onReady?: fieldEvent => unit,
  }
  @get external pick: vaultModule => React.component<props> = "CardNumberField"
  let make = fromVault(pick)
}

module CardExpiryField = {
  type props = {
    ref?: fieldRef,
    styles?: fieldStyles,
    placeholder?: string,
    labelBehavior?: string,
    errorDisplay?: string,
    unstyled?: bool,
    testID?: string,
    onChange?: fieldChange => unit,
    onFocus?: fieldEvent => unit,
    onBlur?: fieldEvent => unit,
    onReady?: fieldEvent => unit,
  }
  @get external pick: vaultModule => React.component<props> = "CardExpiryField"
  let make = fromVault(pick)
}

module CardCVCField = {
  type props = {
    ref?: fieldRef,
    styles?: fieldStyles,
    placeholder?: string,
    labelBehavior?: string,
    errorDisplay?: string,
    unstyled?: bool,
    testID?: string,
    options?: cardNumberOptions,
    onChange?: fieldChange => unit,
    onFocus?: fieldEvent => unit,
    onBlur?: fieldEvent => unit,
    onReady?: fieldEvent => unit,
  }
  @get external pick: vaultModule => React.component<props> = "CardCVCField"
  let make = fromVault(pick)
}

module CardholderNameField = {
  type props = {
    ref?: fieldRef,
    styles?: fieldStyles,
    placeholder?: string,
    labelBehavior?: string,
    errorDisplay?: string,
    unstyled?: bool,
    testID?: string,
    onChange?: fieldChange => unit,
    onFocus?: fieldEvent => unit,
    onBlur?: fieldEvent => unit,
    onReady?: fieldEvent => unit,
  }
  @get external pick: vaultModule => React.component<props> = "CardholderNameField"
  let make = fromVault(pick)
}
