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

external importWrapper: string => promise<OptionalPackage.wrapper> = "import"

// Through a wrapper that makes a missing or failing package a rejected load
// instead of a fatal error (OptionalPackage.res).
let loadVault = (): promise<vaultModule> =>
  importWrapper("../../chunks/VaultPackage.bs.js")->OptionalPackage.unwrap(
    "@juspay-tech/react-native-hyperswitch-vault",
  )

// When the package is not in this build, each component renders [unavailable]
// instead: the form its children, a field a ghost mark. Shoppers never see a
// "package not installed" error.
let fromVault = (
  pick: vaultModule => React.component<'props>,
  ~unavailable: React.component<'props>,
): React.component<'props> => {
  let component = React.lazy_(() =>
    loadVault()
    ->Promise.thenResolve(pick)
    ->Promise.catch(_ => Promise.resolve(unavailable))
  )
  props => <React.Suspense fallback=React.null> {React.createElement(component, props)} </React.Suspense>
}

// True once the vault package is known to be missing from this build, so a
// screen can hide what only the vault's fields would explain (errors, hints).
let useUnavailable = () => {
  let (unavailable, setUnavailable) = React.useState(() => false)
  React.useEffect0(() => {
    loadVault()
    ->Promise.thenResolve(_ => ())
    ->Promise.catch(_ => {
      setUnavailable(_ => true)
      Promise.resolve()
    })
    ->ignore
    None
  })
  unavailable
}

// A field's ghost mark, in the field's own box.
let ghostField = (~styles: option<fieldStyles>, ~testID: option<string>) =>
  <ReactNative.View style=?{styles->Option.flatMap(styles => styles.container)}>
    <GhostMark
      height=12.
      width={ReactNative.Style.pct(60.)}
      radius=4.
      style={ReactNative.Style.s({alignSelf: #"flex-start"})}
      testID=?{testID->Option.map(id => id ++ "-unavailable")}
    />
  </ReactNative.View>

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
  let make = fromVault(pick, ~unavailable=props => props.children)
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
  let make = fromVault(pick, ~unavailable=props =>
    ghostField(~styles=props.styles, ~testID=props.testID)
  )
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
  let make = fromVault(pick, ~unavailable=props =>
    ghostField(~styles=props.styles, ~testID=props.testID)
  )
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
  let make = fromVault(pick, ~unavailable=props =>
    ghostField(~styles=props.styles, ~testID=props.testID)
  )
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
  let make = fromVault(pick, ~unavailable=props =>
    ghostField(~styles=props.styles, ~testID=props.testID)
  )
}
