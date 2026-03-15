type t = Dict.t<JSON.t>

let sdkPropsPrefix = "SdkProps."

let allowsDelayedPaymentMethodsKey = "allows_delayed_payment_methods"
let allowsPaymentMethodsRequiringShippingAddressKey = "allows_payment_methods_requiring_shipping_address"
let applePayButtonStyleKey = "apple_pay_button_style"
let applePayButtonTypeKey = "apple_pay_button_type"
let colorsBackgroundKey = "colors_background"
let colorsComponentBackgroundKey = "colors_component_background"
let colorsComponentBorderKey = "colors_component_border"
let colorsComponentDividerKey = "colors_component_divider"
let colorsComponentTextKey = "colors_component_text"
let colorsErrorKey = "colors_error"
let colorsIconKey = "colors_icon"
let colorsLoaderBackgroundKey = "colors_loader_background"
let colorsLoaderForegroundKey = "colors_loader_foreground"
let colorsPlaceholderTextKey = "colors_placeholder_text"
let colorsPrimaryKey = "colors_primary"
let colorsPrimaryTextKey = "colors_primary_text"
let colorsSecondaryTextKey = "colors_secondary_text"
let disableBrandingKey = "disable_branding"
let displayDefaultSavedPaymentIconKey = "display_default_saved_payment_icon"
let displayMergedSavedMethodsKey = "display_merged_saved_methods"
let enablePartialLoadingKey = "enable_partial_loading"
let displaySavedPaymentMethodsKey = "display_saved_payment_methods"
let displaySavedPaymentMethodsCheckboxKey = "display_saved_payment_methods_checkbox"
let defaultViewKey = "default_view"
let fontButtonTextSizeAdjustKey = "font_button_text_size_adjust"
let fontCardTextSizeAdjustKey = "font_card_text_size_adjust"
let fontErrorTextSizeAdjustKey = "font_error_text_size_adjust"
let fontFamilyKey = "font_family"
let fontHeadingTextSizeAdjustKey = "font_heading_text_size_adjust"
let fontLinkTextSizeAdjustKey = "font_link_text_size_adjust"
let fontModalTextSizeAdjustKey = "font_modal_text_size_adjust"
let fontPlaceholderTextSizeAdjustKey = "font_placeholder_text_size_adjust"
let fontScaleKey = "font_scale"
let fontSubHeadingTextSizeAdjustKey = "font_sub_heading_text_size_adjust"
let googlePayButtonTypeKey = "google_pay_button_type"
let merchantDisplayNameKey = "merchant_display_name"
let paymentSheetHeaderTextKey = "payment_sheet_header_text"
let placeholderCardNumberKey = "placeholder_card_number"
let placeholderCvvKey = "placeholder_cvv"
let placeholderExpiryDateKey = "placeholder_expiry_date"
let primaryButtonBackgroundKey = "primary_button_background"
let primaryButtonBorderKey = "primary_button_border"
let primaryButtonBorderRadiusKey = "primary_button_border_radius"
let primaryButtonBorderWidthKey = "primary_button_border_width"
let primaryButtonLabelKey = "primary_button_label"
let primaryButtonTextKey = "primary_button_text"
let shapesBorderRadiusKey = "shapes_border_radius"
let shapesBorderWidthKey = "shapes_border_width"
let layoutKey = "layout"
let localeKey = "locale"
let themeKey = "theme"

let empty: t = Dict.make()

let parseConfigRaw = (value: JSON.t): option<JSON.t> => {
  switch value->JSON.Decode.object {
  | Some(_) => Some(value)
  | None =>
    switch value->JSON.Decode.string {
    | Some(configStr) =>
      try {
        Some(configStr->JSON.parseExn)
      } catch {
      | _ => None
      }
    | None => None
    }
  }
}

let getNativeConfig = hyperParams =>
  hyperParams->Dict.get("superpositionConfigRaw")->Option.flatMap(parseConfigRaw)

let fromConfig = (config: JSON.t): t => {
  switch config->JSON.Decode.object {
  | Some(configDict) =>
    switch configDict->Dict.get("resolved_configs")->Option.flatMap(JSON.Decode.object) {
    | Some(resolvedConfigs) =>
      resolvedConfigs
      ->Dict.toArray
      ->Array.filterMap(((key, value)) =>
        if key->String.startsWith(sdkPropsPrefix) {
          Some((key->String.substringToEnd(~start=String.length(sdkPropsPrefix)), value))
        } else {
          None
        }
      )
      ->Dict.fromArray
    | None => empty
    }
  | None => empty
  }
}

let parse = config => {
  switch config {
  | Some(validConfig) => fromConfig(validConfig)
  | None => empty
  }
}

let getBool = (defaults: t, key: string, fallback: bool): bool =>
  defaults->Dict.get(key)->Option.flatMap(JSON.Decode.bool)->Option.getOr(fallback)

let getString = (defaults: t, key: string): option<string> =>
  defaults->Dict.get(key)->Option.flatMap(JSON.Decode.string)

let getNonEmptyString = (defaults: t, key: string): option<string> =>
  switch getString(defaults, key) {
  | Some("") => None
  | val => val
  }

let getFloat = (defaults: t, key: string): option<float> =>
  defaults->Dict.get(key)->Option.flatMap(JSON.Decode.float)

let getBoolWithFallback = (dict, nativeKey, defaults, sdkPropKey, fallback) =>
  Utils.getBool(dict, nativeKey, getBool(defaults, sdkPropKey, fallback))

let getStringWithFallback = (dict, nativeKey, defaults, sdkPropKey, fallback) =>
  Utils.getString(dict, nativeKey, getString(defaults, sdkPropKey)->Option.getOr(fallback))

let getOptionStringWithFallback = (dict, nativeKey, defaults, sdkPropKey) =>
  switch Utils.getOptionString(dict, nativeKey) {
  | Some(value) => Some(value)
  | None => getString(defaults, sdkPropKey)
  }
