/*
 * Single React root for every vault surface registered under "hs-vault".
 *
 * Each native field widget mounts its own RN surface with
 *   { type: fieldTypeName, config: { fieldName?, isRequired, sdkAuthorization?, environment?,
 *                                    configuration?: { appearance?, options? } } }
 * (see BaseVaultFieldView.kt / HyperswitchTextField.swift). This entry
 * decodes that, routes by `type` to the matching field widget from
 * react-native-hyperswitch-vault, and registers the surface's state with
 * VaultRegistry so cross-surface aggregation and the hsVaultTokenise broadcast
 * can find it.
 */

open VaultFieldTypes

/*
 * Appearance arrives as an opaque JSON dict from native and is passed through
 * unchanged. The provider's VaultFormOptions.appearance reader is the public
 * wire format already; this cast is the type boundary.
 */
external jsonToAppearance: JSON.t => VaultFormOptions.appearance = "%identity"

/*
 * Decoders for the scannable enums sent over the wire by BaseVaultFieldView /
 * HyperswitchTextField under `configuration.options`.
 */
let labelBehaviorOfString = (raw: option<string>): option<CardFieldOptions.labelBehavior> =>
  switch raw {
  | Some("none") => Some(#none)
  | Some("static") => Some(#static)
  | Some("floating") => Some(#floating)
  | _ => None
  }

let errorDisplayOfString = (raw: option<string>): option<CardFieldOptions.errorDisplay> =>
  switch raw {
  | Some("none") => Some(#none)
  | Some("inline") => Some(#inline)
  | _ => None
  }

let cvcIconOfString = (raw: option<string>): option<CardFieldOptions.cvcIconDisplay> =>
  switch raw {
  | Some("none") => Some(#none)
  | Some("default") => Some(#default)
  | _ => None
  }

/* Native BrandIconMode {auto, static, hidden} -> JS brandIconMode
 * {[#standard | #animated | #hidden | #hideGeneric]}. auto maps to animated
 * (the JS default), static maps to standard, hidden survives. */
let brandIconModeOfString = (raw: option<string>): option<CardFieldOptions.brandIconMode> =>
  switch raw {
  | Some("auto") => Some(#animated)
  | Some("static") => Some(#standard)
  | Some("hidden") => Some(#hidden)
  | _ => None
  }

/*
 * configuration.options arrives as an opaque JSON dict — keys per
 * VaultFieldOptions.toBundle / VaultFieldOptions(dict:). Each value type is
 * already narrowed by the wrapper that consumes it.
 */
let optionString = (json: option<JSON.t>, key: string): option<string> =>
  json->Option.flatMap(
    j =>
      j
      ->JSON.Decode.object
      ->Option.flatMap(d => d->Dict.get(key))
      ->Option.flatMap(JSON.Decode.string),
  )

let optionBool = (json: option<JSON.t>, key: string): option<bool> =>
  json->Option.flatMap(
    j =>
      j
      ->JSON.Decode.object
      ->Option.flatMap(d => d->Dict.get(key))
      ->Option.flatMap(JSON.Decode.bool),
  )

let optionJson = (json: option<JSON.t>, key: string): option<JSON.t> =>
  json->Option.flatMap(j => j->JSON.Decode.object->Option.flatMap(d => d->Dict.get(key)))

external jsonToFieldStyles: JSON.t => CardFieldStyles.fieldStyles = "%identity"
external jsonToExpiryStyles: JSON.t => CardFieldStyles.expiryStyles = "%identity"

/*
 * Public state snapshot a widget emits through onStateChange — matches
 * VaultPublicState.cardNumberState / expiryState / cvcState / cardholderNameState.
 * All four variants share {status, valid, isEmpty, isFocused, error?}; brand
 * comes on the card-number one only. Identity cast to the registry shape is
 * safe because the intersection is structural.
 */
external cardNumberStateToSnapshot: VaultPublicState.cardNumberState => VaultRegistry.fieldSnapshot =
  "%identity"
external expiryStateToSnapshot: VaultPublicState.expiryState => VaultRegistry.fieldSnapshot =
  "%identity"
external cvcStateToSnapshot: VaultPublicState.cvcState => VaultRegistry.fieldSnapshot = "%identity"
external cardholderNameStateToSnapshot: VaultPublicState.cardholderNameState =>
  VaultRegistry.fieldSnapshot = "%identity"

@react.component
let make = (~props, ~rootTag) => {
  let {fieldType, config, rootTag} = VaultFieldTypes.decodeInitialProps(props, rootTag)
  {
    let environment = environmentFromString(config.environment)
    let appearance = config.configuration.appearance->Option.map(jsonToAppearance)

    let pushToRegistry = (~fieldType: fieldType, snapshot: VaultRegistry.fieldSnapshot): unit =>
      VaultRegistry.pushFieldState(~rootTag, ~fieldType, ~state=snapshot)

    /* Per the surface model, the host (one per provider) is what runs
     * tokenize/confirmPayment. We host it here directly — same hook the
     * off-the-shelf HyperswitchVaultFormProvider uses — so the CVC surface's
     * tokenise listener can read host.machinery.tokenize without needing a
     * ref onto a forwardRef component. */
    let host = VaultFormHost.useHost(
      ~session=None,
      ~environment,
      ~appearance,
      ~localisation=None,
      ~disabled=false,
      ~accessible=None,
      ~enabledCardSchemes=[],
      ~eligibility=None,
      ~vaultEndpoint=None,
      ~cardholderNameMode=#collect,
      ~onFormStateChange=None,
      ~unstyled=CardFieldOptions.defaultUnstyled,
    )

    /* The CVC surface claims the hsVaultTokenise broadcast. */
    React.useEffect0(() => {
      switch fieldType {
      | CVC =>
        VaultTokenise.subscribe(
          ~fallbackAuthorization=config.sdkAuthorization,
          ~fallbackEnvironment=config.environment,
          ~isCollectable=VaultRegistry.collectableState,
          ~collectCard=VaultRegistry.collectCard,
        )->Some
      | _ => None
      }
    })

    /*
     * Raw-value collector for the cross-surface tokenise. Registered as a
     * thunk over the widget controller's latest ref: the raw card value is
     * only materialized while VaultTokenise.runTokenise assembles the vault
     * confirm body, and never crosses the native bridge.
     */
    React.useEffect0(() => {
      let collect: option<VaultRegistry.rawCollector> = switch fieldType {
      | CardNumber =>
        Some(() => host.contextValue.controller.cardDetails().cardNumber->JSON.Encode.string)
      | Expiry =>
        Some(
          () => {
            let card = host.contextValue.controller.cardDetails()
            let d = Dict.make()
            d->Dict.set("month", card.expiryMonth->JSON.Encode.string)
            d->Dict.set("year", card.expiryYear->JSON.Encode.string)
            JSON.Encode.object(d)
          },
        )
      | CVC => Some(() => host.contextValue.controller.cardDetails().cvc->JSON.Encode.string)
      | CardHolder =>
        Some(() => host.contextValue.controller.cardholderName()->JSON.Encode.string)
      | Ssn
      | Info
      | VaultFieldTypes.Unknown(_) => None
      }
      switch collect {
      | Some(collect) =>
        VaultRegistry.registerCollector(~fieldType, ~collect)
        Some(() => VaultRegistry.dropCollector(~fieldType))
      | None => None
      }
    })

    /* Drop this surface's entries from the registry on unmount. */
    React.useEffect0(() => Some(() => VaultRegistry.dropSurface(~rootTag, ~fieldType)))

    /* Pull the merchant-customisable props straight out of
     * configuration.options (the strings the native side set under
     * VaultFieldOptions) and pass them through the Fields wrappers, which
     * expose named args to ReScript JSX. Anything not present stays None and
     * the widget falls back to its own default. */
    let options = config.configuration.options
    let placeholder = optionString(options, "placeholder")
    let label = optionString(options, "label")
    let labelBehavior = labelBehaviorOfString(optionString(options, "labelBehavior"))
    let errorDisplay = errorDisplayOfString(optionString(options, "errorDisplay"))
    let accessibilityLabel = optionString(options, "accessibilityLabel")
    let accessibilityHint = optionString(options, "accessibilityHint")
    let testID = optionString(options, "testID")
    let brandIconMode = brandIconModeOfString(optionString(options, "brandIconMode"))
    let cvcIcon = cvcIconOfString(optionString(options, "cvcIcon"))
    /* `options.unstyled` flips the field to a bare TextInput. `options.styles`
     * is the raw per-slot style bag (root/container/input/placeholder/label/
     * error/accessory) passed through unchanged — the widget fronts
     * `%identity` casts into the typed CardFieldStyles.view/textStyleProp. */
    let unstyledRaw = optionBool(options, "unstyled")
    let stylesJson = optionJson(options, "styles")
    let unstyled = unstyledRaw
    let fieldStyles = stylesJson->Option.map(jsonToFieldStyles)
    let expiryStyles = stylesJson->Option.map(jsonToExpiryStyles)

    /* One widget per surface; pick by fieldType, rendered through the
     * named-arg wrappers in Fields.res. */
    let child: React.element = switch fieldType {
    | CardNumber =>
      let onStateChange = (state: VaultPublicState.cardNumberState) =>
        pushToRegistry(~fieldType=CardNumber, cardNumberStateToSnapshot(state))
      <Fields.CardNumber
        placeholder=?placeholder
        label=?label
        labelBehavior=?labelBehavior
        errorDisplay=?errorDisplay
        accessibilityLabel=?accessibilityLabel
        accessibilityHint=?accessibilityHint
        testID=?testID
        brandIconMode=?brandIconMode
        unstyled=?unstyled
        styles=?fieldStyles
        onStateChange
      />
    | Expiry =>
      let onStateChange = (state: VaultPublicState.expiryState) =>
        pushToRegistry(~fieldType=Expiry, expiryStateToSnapshot(state))
      <Fields.Expiry
        placeholder=?placeholder
        label=?label
        labelBehavior=?labelBehavior
        errorDisplay=?errorDisplay
        accessibilityLabel=?accessibilityLabel
        accessibilityHint=?accessibilityHint
        testID=?testID
        unstyled=?unstyled
        styles=?expiryStyles
        onStateChange
      />
    | CVC =>
      let onStateChange = (state: VaultPublicState.cvcState) =>
        pushToRegistry(~fieldType=CVC, cvcStateToSnapshot(state))
      <Fields.CVC
        placeholder=?placeholder
        label=?label
        labelBehavior=?labelBehavior
        errorDisplay=?errorDisplay
        accessibilityLabel=?accessibilityLabel
        accessibilityHint=?accessibilityHint
        testID=?testID
        cvcIcon=?cvcIcon
        unstyled=?unstyled
        styles=?fieldStyles
        onStateChange
      />
    | CardHolder =>
      let onStateChange = (state: VaultPublicState.cardholderNameState) =>
        pushToRegistry(~fieldType=CardHolder, cardholderNameStateToSnapshot(state))
      <Fields.CardholderName
        placeholder=?placeholder
        label=?label
        labelBehavior=?labelBehavior
        errorDisplay=?errorDisplay
        accessibilityLabel=?accessibilityLabel
        accessibilityHint=?accessibilityHint
        testID=?testID
        unstyled=?unstyled
        styles=?fieldStyles
        onStateChange
      />
    | Ssn
    | Info
    | VaultFieldTypes.Unknown(_) =>
      /* Native sends ssnInput / infoInput for non-card fields; those don't
       * map onto a Vault widget — render nothing for this surface. */
      React.null
    }

    <VaultWidgetContext.ContextProvider value={Some(host.contextValue)}>
      {child}
    </VaultWidgetContext.ContextProvider>
  }
}

let app = make
