/*
 * Decoder for the initialProperties shape the native vault surfaces send.
 * Parsed the same way the main SDK parses its native props (see
 * SdkTypes.nativeJsonToRecord): the whole prop object is a flat JSON dict read
 * with the tolerant Utils getters, and `rootTag` arrives as a separate
 * AppRegistry prop rather than a key inside the JSON.
 *
 * Mirrors:
 *   android .../widget/BaseVaultFieldView.kt      (buildInitialProps)
 *   ios hyperswitchVaultSDK/UIElements/HyperswitchTextField.swift (initialProperties)
 *
 *     { type,
 *       config: { fieldName?, isRequired,
 *                 sessionConfig?: { sdkAuthorization?, environment? },
 *                 configuration?: { appearance?, options? } } }
 */

/*
 * NOTE — deliberately self-contained: this module must NOT `open Utils` or
 * any other client-core unit. The vault-package units this module is
 * imported alongside (in HsVaultEntry) compile shared-code/sdk-utils under a
 * different absolute path than this repo does, and the toolchain embeds the
 * source path in the .cmi digest — referencing both graphs in one module
 * fails the OCaml consistency check ("inconsistent assumptions over
 * interface CountryStateDataHookTypes"). The four tiny JSON getters below
 * stand in for the Utils helpers.
 */

let optString = (d: Dict.t<JSON.t>, key: string): option<string> =>
  d->Dict.get(key)->Option.flatMap(JSON.Decode.string)

let getString = (d: Dict.t<JSON.t>, key: string, default: string): string =>
  d->optString(key)->Option.getOr(default)

let getBool = (d: Dict.t<JSON.t>, key: string, default: bool): bool =>
  d->Dict.get(key)->Option.flatMap(JSON.Decode.bool)->Option.getOr(default)

let getObj = (d: Dict.t<JSON.t>, key: string, default: Dict.t<JSON.t>): Dict.t<JSON.t> =>
  d->Dict.get(key)->Option.flatMap(JSON.Decode.object)->Option.getOr(default)

type fieldType =
  | CardNumber
  | Expiry
  | CVC
  | CardHolder
  | Ssn
  | Info
  | Unknown(string)

let fieldTypeFromString = (raw: string): fieldType =>
  switch raw {
  | "cardNumberInput" => CardNumber
  | "expDateInput" => Expiry
  | "cvcInput" => CVC
  | "cardHolderInput" => CardHolder
  | "ssnInput" => Ssn
  | "infoInput" => Info
  | other => Unknown(other)
  }

/* Field-type string the native side keys aggregated states on
 * (see android FieldType.rawValue / ios VaultFieldState.fieldType). */
let fieldTypeRawValue = (t: fieldType): string =>
  switch t {
  | CardNumber => "card_number"
  | Expiry => "exp_date"
  | CVC => "cvc"
  | CardHolder => "card_holder"
  | Ssn => "ssn"
  | Info => "info"
  | Unknown(raw) => raw
  }

type appearanceDict = JSON.t
type optionsDict = JSON.t

type configurationDict = {
  appearance: option<appearanceDict>,
  options: option<optionsDict>,
}

type surfaceConfig = {
  fieldName: option<string>,
  isRequired: bool,
  environment: option<string>,
  sdkAuthorization: option<string>,
  configuration: configurationDict,
}

type surfaceProps = {
  fieldType: fieldType,
  config: surfaceConfig,
  /* Surface id assigned by React Native; passed in as the separate
   * AppRegistry `rootTag` prop, same as App.res -> nativeJsonToRecord. */
  rootTag: int,
}

let decodeInitialProps = (jsonFromNative: JSON.t, rootTag: int): surfaceProps => {
  let d = jsonFromNative->JSON.Decode.object->Option.getOr(Dict.make())
  let config = getObj(d, "config", Dict.make())
  let configuration = getObj(config, "configuration", Dict.make())
  /* Both native sides nest the library-owned session creds under
   * config.sessionConfig (set by HyperswitchCollect.bindView /
   * configuration.collector), NOT flat on config. */
  let sessionConfig = getObj(config, "sessionConfig", Dict.make())

  {
    fieldType: getString(d, "type", "")->fieldTypeFromString,
    config: {
      fieldName: optString(config, "fieldName"),
      isRequired: getBool(config, "isRequired", true),
      environment: optString(sessionConfig, "environment"),
      sdkAuthorization: optString(sessionConfig, "sdkAuthorization"),
      configuration: {
        appearance: configuration->Dict.get("appearance"),
        options: configuration->Dict.get("options"),
      },
    },
    rootTag,
  }
}

/* Helpers for the initialProps shape when handed in as a JS object. */
external initialPropsToJson: 'a => JSON.t = "%identity"

/*
 * Environment string -> the shared vault environment variant.
 *
 * Native sends HyperswitchEnvironment.jsEnvName / rawValue
 * ("production" | "integration" | "sandbox", defaulting to sandbox on
 * iOS). Shared by HsVaultEntry (host appearance) and VaultTokenise
 * (base-url resolution); lives here because it is wire decoding.
 */
let environmentFromString = (raw: option<string>): [#production | #sandbox | #integration] =>
  switch raw {
  | Some("production") => #production
  | Some("integration") => #integration
  | Some("sandbox") => #sandbox
  | _ => #sandbox
  }
