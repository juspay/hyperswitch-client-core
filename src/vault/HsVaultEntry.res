/*
 * Single React root for every vault surface registered under "hs-vault".
 *
 * Each native field widget mounts its own RN surface with
 *   { type: fieldTypeName, config: { fieldName?, isRequired, sdkAuthorization?, environment?,
 *                                    configuration?: { appearance?, options? } } }
 * (see BaseVaultFieldView.kt / HyperswitchTextField.swift). This entry
 * decodes that, routes by `type` to the matching field widget from
 * react-native-hyperswitch-vault, and hands the surface's rootTag down as a
 * prop. Emission + raw-value storage live in the widgets' own package
 * (HyperNativeVault.useNativeFeatures → globalThis.HyperVaultStore) — this
 * entry ONLY claims the tokenise broadcast.
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
 * Registry emission is NOT here: each widget's HyperNativeVault.useNativeFeatures
 * hook mirrors its own redacted wire state (validation flags + ≤6-digit bin)
 * into globalThis.HyperVaultStore and pushes it over the TurboModule, keyed by
 * the rootTag this entry hands down as a prop. Raw values stay in JS; only the
 * redacted wire states cross the bridge.
 */
@react.component
let make = (~props, ~rootTag) => {
  let {fieldType, config, rootTag} = VaultFieldTypes.decodeInitialProps(props, rootTag)
  {
    let environment = environmentFromString(config.environment)
    let appearance = config.configuration.appearance->Option.map(jsonToAppearance)

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

    /*
     * The CVC surface claims the hsVaultTokenise broadcast. Gate + collect
     * read HyperVaultStore — client-core's single global registry. The
     * widgets keep its raw values current; the tokenise flow re-reads THEM,
     * never component state.
     */
    React.useEffect0(() => {
      switch fieldType {
      | CVC =>
        VaultTokenise.subscribe(
          ~fallbackAuthorization=config.sdkAuthorization,
          ~fallbackEnvironment=config.environment,
          ~isCollectable=HyperVaultStore.collectableState,
          ~collectCard=HyperVaultStore.collectCard,
        )->Some
      | _ => None
      }
    })

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
        rootTag
      />
    | Expiry =>
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
        rootTag
      />
    | CVC =>
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
        rootTag
      />
    | CardHolder =>
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
        rootTag
      />
    | Ssn
    | Info
    | VaultFieldTypes.Unknown(_) =>
      /* Native sends ssn / info for non-card fields; those don't
       * map onto a Vault widget — render nothing for this surface. */
      React.null
    }

    <VaultWidgetContext.ContextProvider value={Some(host.contextValue)}>
      {child}
    </VaultWidgetContext.ContextProvider>
  }
}

let app = make
