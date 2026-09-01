/*
 * ReScript-friendly JSX wrappers over the four vault field widgets.
 *
 * The widgets in react-native-hyperswitch-vault are `React.forwardRef`s
 * whose props are an anonymous positional record — convenient from TSX
 * (`<CardNumberField placeholder="Card number" />`) but awkward from ReScript
 * JSX, where labels need to be declared named args.
 *
 * These four wrappers expose the same surface as named args, all optional,
 * and forward onto the underlying record via React.createElement. The widgets'
 * `make` is a forwardRef OBJECT (not a function), even though
 * Jsx.component<'props> type-checks as callable — a direct `make({...})` call
 * compiles but crashes at runtime ("make is not a function").
 *
 * Styling/behaviour props the native side can set under `configuration.options`
 * (placeholder, label, labelBehavior, errorDisplay, accessibilityLabel/Hint,
 * testID, unstyled, plus brandIconMode / cvcIcon where applicable) map
 * one-for-one onto the named args here.
 */

module CardNumber = {
  @react.component
  let make = (
    ~placeholder: option<string>=?,
    ~label: option<string>=?,
    ~labelBehavior: option<CardFieldOptions.labelBehavior>=?,
    ~errorDisplay: option<CardFieldOptions.errorDisplay>=?,
    ~accessibilityLabel: option<string>=?,
    ~accessibilityHint: option<string>=?,
    ~testID: option<string>=?,
    ~brandIconMode: option<CardFieldOptions.brandIconMode>=?,
    ~unstyled: option<bool>=?,
    ~styles: option<CardFieldStyles.fieldStyles>=?,
    ~onStateChange: option<VaultPublicState.cardNumberState => unit>=?,
  ) =>
    React.createElement(
      CardNumberWidget.make,
      {
        "children": None,
        "styles": styles,
        "placeholder": placeholder,
        "label": label,
        "labelBehavior": labelBehavior,
        "errorDisplay": errorDisplay,
        "accessibilityLabel": accessibilityLabel,
        "accessibilityHint": accessibilityHint,
        "testID": testID,
        "brandIconMode": brandIconMode,
        "onStateChange": onStateChange,
        "unstyled": unstyled,
      },
    )
}

module Expiry = {
  @react.component
  let make = (
    ~placeholder: option<string>=?,
    ~label: option<string>=?,
    ~labelBehavior: option<CardFieldOptions.labelBehavior>=?,
    ~errorDisplay: option<CardFieldOptions.errorDisplay>=?,
    ~accessibilityLabel: option<string>=?,
    ~accessibilityHint: option<string>=?,
    ~testID: option<string>=?,
    ~unstyled: option<bool>=?,
    ~styles: option<CardFieldStyles.expiryStyles>=?,
    ~onStateChange: option<VaultPublicState.expiryState => unit>=?,
  ) =>
    React.createElement(
      CardExpiryWidget.make,
      {
        "children": None,
        "styles": styles,
        "placeholder": placeholder,
        "label": label,
        "labelBehavior": labelBehavior,
        "errorDisplay": errorDisplay,
        "accessibilityLabel": accessibilityLabel,
        "accessibilityHint": accessibilityHint,
        "testID": testID,
        "onStateChange": onStateChange,
        "unstyled": unstyled,
      },
    )
}

module CVC = {
  @react.component
  let make = (
    ~placeholder: option<string>=?,
    ~label: option<string>=?,
    ~labelBehavior: option<CardFieldOptions.labelBehavior>=?,
    ~errorDisplay: option<CardFieldOptions.errorDisplay>=?,
    ~accessibilityLabel: option<string>=?,
    ~accessibilityHint: option<string>=?,
    ~testID: option<string>=?,
    ~unstyled: option<bool>=?,
    ~cvcIcon: option<CardFieldOptions.cvcIconDisplay>=?,
    ~styles: option<CardFieldStyles.fieldStyles>=?,
    ~onStateChange: option<VaultPublicState.cvcState => unit>=?,
  ) =>
    React.createElement(
      CardCVCWidget.make,
      {
        "children": None,
        "styles": styles,
        "placeholder": placeholder,
        "label": label,
        "labelBehavior": labelBehavior,
        "errorDisplay": errorDisplay,
        "accessibilityLabel": accessibilityLabel,
        "accessibilityHint": accessibilityHint,
        "testID": testID,
        "onStateChange": onStateChange,
        "cvcIcon": cvcIcon,
        "unstyled": unstyled,
      },
    )
}

module CardholderName = {
  @react.component
  let make = (
    ~placeholder: option<string>=?,
    ~label: option<string>=?,
    ~labelBehavior: option<CardFieldOptions.labelBehavior>=?,
    ~errorDisplay: option<CardFieldOptions.errorDisplay>=?,
    ~accessibilityLabel: option<string>=?,
    ~accessibilityHint: option<string>=?,
    ~testID: option<string>=?,
    ~unstyled: option<bool>=?,
    ~styles: option<CardFieldStyles.fieldStyles>=?,
    ~onStateChange: option<VaultPublicState.cardholderNameState => unit>=?,
  ) =>
    React.createElement(
      CardholderNameWidget.make,
      {
        "children": None,
        "styles": styles,
        "placeholder": placeholder,
        "label": label,
        "labelBehavior": labelBehavior,
        "errorDisplay": errorDisplay,
        "accessibilityLabel": accessibilityLabel,
        "accessibilityHint": accessibilityHint,
        "testID": testID,
        "onStateChange": onStateChange,
        "unstyled": unstyled,
      },
    )
}
