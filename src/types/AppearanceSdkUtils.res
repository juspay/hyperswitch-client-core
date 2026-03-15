open AppearanceTypes
open Utils

type sdkPropsDefaults = SuperpositionSdkProps.t

let defaultAppearance: appearance = {
  locale: None,
  colors: switch WebKit.platform {
  | #android =>
    Some(
      DefaultColors({
        light: None,
        dark: None,
      }),
    )
  | #ios =>
    Some(
      Colors({
        primary: None,
        background: None,
        componentBackground: None,
        componentBorder: None,
        componentDivider: None,
        componentText: None,
        primaryText: None,
        secondaryText: None,
        placeholderText: None,
        icon: None,
        error: None,
        loaderBackground: None,
        loaderForeground: None,
      }),
    )
  | _ => None
  },
  shapes: Some({
    borderRadius: None,
    borderWidth: None,
    shadow: None,
  }),
  font: Some({
    family: None,
    scale: None,
    headingTextSizeAdjust: None,
    subHeadingTextSizeAdjust: None,
    placeholderTextSizeAdjust: None,
    buttonTextSizeAdjust: None,
    errorTextSizeAdjust: None,
    linkTextSizeAdjust: None,
    modalTextSizeAdjust: None,
    cardTextSizeAdjust: None,
  }),
  primaryButton: Some({
    shapes: Some({
      borderRadius: None,
      borderWidth: None,
      shadow: None,
    }),
    primaryButtonColor: switch WebKit.platform {
    | #android =>
      Some(
        PrimaryButtonDefault({
          light: Some({
            background: None,
            text: None,
            border: None,
          }),
          dark: Some({
            background: None,
            text: None,
            border: None,
          }),
        }),
      )
    | #ios =>
      Some(
        PrimaryButtonColor(
          Some({
            background: None,
            text: None,
            border: None,
          }),
        ),
      )
    | _ => None
    },
  }),
  googlePay: {
    buttonType: PLAIN,
    buttonStyle: None,
  },
  applePay: {
    buttonType: #plain,
    buttonStyle: None,
  },
  theme: Default,
  layout: Tab,
}

let retOptionalNonEmptyStr = x => {
  switch retOptionalStr(x) {
  | Some("") => None
  | val => val
  }
}

let coalesceOption = (primary, fallback) =>
  switch primary {
  | Some(_) => primary
  | None => fallback
  }

let layoutStringToType = layout =>
  switch layout {
  | "tab" | "tabs" | "Tab" | "Tabs" => Some(Tab)
  | "accordion" | "Accordion" => Some(Accordion)
  | "spacedAccordion" | "SpacedAccordion" | "spaced_accordion" => Some(SpacedAccordion)
  | _ => None
  }

let themeStringToType = theme => {
  let normalized = theme->String.trim->String.toLowerCase
  if normalized->String.startsWith("default") {
    Some(Default)
  } else if normalized == "light" {
    Some(Light)
  } else if normalized == "dark" {
    Some(Dark)
  } else if normalized == "minimal" {
    Some(Minimal)
  } else if (
    normalized == "flatminimal" || normalized == "flat_minimal" || normalized == "flat minimal"
  ) {
    Some(FlatMinimal)
  } else {
    None
  }
}

let googlePayButtonTypeStringToType = buttonType => {
  switch buttonType->String.trim->String.toUpperCase {
  | "BUY" => Some(BUY)
  | "BOOK" => Some(BOOK)
  | "CHECKOUT" => Some(CHECKOUT)
  | "DONATE" => Some(DONATE)
  | "ORDER" => Some(ORDER)
  | "PAY" => Some(PAY)
  | "SUBSCRIBE" => Some(SUBSCRIBE)
  | "PLAIN" => Some(PLAIN)
  | _ => None
  }
}

let applePayButtonTypeStringToType = buttonType => {
  let normalized = buttonType->String.trim->String.toLowerCase
  let normalized = if normalized->String.startsWith("#") {
    normalized->String.substringToEnd(~start=1)
  } else {
    normalized
  }
  switch normalized {
  | "buy" => Some(#buy)
  | "setup" | "set_up" | "set-up" => Some(#setUp)
  | "instore" | "in_store" | "in-store" => Some(#inStore)
  | "donate" => Some(#donate)
  | "checkout" => Some(#checkout)
  | "book" => Some(#book)
  | "subscribe" => Some(#subscribe)
  | "plain" => Some(#plain)
  | _ => None
  }
}

let applePayButtonStyleStringToType = buttonStyle => {
  switch buttonStyle->String.trim->String.toLowerCase {
  | "white" => Some(#white)
  | "whiteoutline" | "white_outline" | "white-outline" => Some(#whiteOutline)
  | "black" => Some(#black)
  | _ => None
  }
}

let getLocaleFromSdkProps = (defaults: sdkPropsDefaults): option<LocaleDataType.localeTypes> =>
  switch SuperpositionSdkProps.getString(defaults, SuperpositionSdkProps.localeKey) {
  | Some(localeStr) =>
    switch LocaleDataType.localeStringToType(localeStr) {
    | Some(locale) => Some(locale)
    | None => Some(En)
    }
  | None => Some(En)
  }

let getLayoutFromSdkProps = (defaults: sdkPropsDefaults): layoutType =>
  SuperpositionSdkProps.getString(defaults, SuperpositionSdkProps.layoutKey)
  ->Option.flatMap(layoutStringToType)
  ->Option.getOr(Tab)

let getThemeFromSdkProps = (defaults: sdkPropsDefaults): option<themeType> =>
  SuperpositionSdkProps.getNonEmptyString(defaults, SuperpositionSdkProps.themeKey)->Option.flatMap(
    themeStringToType,
  )

let getGooglePayButtonTypeFromSdkProps = (defaults: sdkPropsDefaults): option<
  googlePayButtonType,
> =>
  SuperpositionSdkProps.getNonEmptyString(
    defaults,
    SuperpositionSdkProps.googlePayButtonTypeKey,
  )->Option.flatMap(googlePayButtonTypeStringToType)

let getApplePayButtonTypeFromSdkProps = (defaults: sdkPropsDefaults): option<applePayButtonType> =>
  SuperpositionSdkProps.getNonEmptyString(
    defaults,
    SuperpositionSdkProps.applePayButtonTypeKey,
  )->Option.flatMap(applePayButtonTypeStringToType)

let getApplePayButtonStyleFromSdkProps = (defaults: sdkPropsDefaults): option<
  applePayThemeBaseStyle,
> =>
  SuperpositionSdkProps.getNonEmptyString(defaults, SuperpositionSdkProps.applePayButtonStyleKey)
  ->Option.flatMap(applePayButtonStyleStringToType)
  ->Option.map(style => ({light: style, dark: style}: applePayThemeBaseStyle))

let getAppearanceLocale = (
  appearanceDict: Dict.t<JSON.t>,
  keys: NativeSdkPropsKeys.keys,
  defaults: sdkPropsDefaults,
) =>
  switch retOptionalNonEmptyStr(getProp(keys.locale, appearanceDict)) {
  | Some(localeStr) =>
    switch LocaleDataType.localeStringToType(localeStr) {
    | Some(locale) => Some(locale)
    | None => getLocaleFromSdkProps(defaults)
    }
  | None => getLocaleFromSdkProps(defaults)
  }

let getAppearanceLayout = (appearanceDict: Dict.t<JSON.t>, defaults: sdkPropsDefaults) =>
  switch getOptionString(appearanceDict, "layout")->Option.flatMap(layoutStringToType) {
  | Some(layout) => layout
  | None => getLayoutFromSdkProps(defaults)
  }

let getAppearanceTheme = (appearanceDict: Dict.t<JSON.t>, defaults: sdkPropsDefaults) =>
  switch getOptionString(appearanceDict, "theme")->Option.flatMap(themeStringToType) {
  | Some(theme) => theme
  | None => getThemeFromSdkProps(defaults)->Option.getOr(Default)
  }

let getGooglePayButtonType = (googlePayDict: Dict.t<JSON.t>, defaults: sdkPropsDefaults) =>
  switch getOptionString(googlePayDict, "buttonType")->Option.flatMap(
    googlePayButtonTypeStringToType,
  ) {
  | Some(buttonType) => buttonType
  | None => getGooglePayButtonTypeFromSdkProps(defaults)->Option.getOr(PLAIN)
  }

let getApplePayButtonType = (applePayDict: Dict.t<JSON.t>, defaults: sdkPropsDefaults) =>
  switch getOptionString(applePayDict, "buttonType")->Option.flatMap(
    applePayButtonTypeStringToType,
  ) {
  | Some(buttonType) => buttonType
  | None => getApplePayButtonTypeFromSdkProps(defaults)->Option.getOr(#plain)
  }

let emptyColors = {
  primary: None,
  background: None,
  componentBackground: None,
  componentBorder: None,
  componentDivider: None,
  componentText: None,
  primaryText: None,
  secondaryText: None,
  placeholderText: None,
  icon: None,
  error: None,
  loaderBackground: None,
  loaderForeground: None,
}

let hasAnyColorValue = (colorSet: colors) =>
  colorSet.primary->Option.isSome ||
  colorSet.background->Option.isSome ||
  colorSet.componentBackground->Option.isSome ||
  colorSet.componentBorder->Option.isSome ||
  colorSet.componentDivider->Option.isSome ||
  colorSet.componentText->Option.isSome ||
  colorSet.primaryText->Option.isSome ||
  colorSet.secondaryText->Option.isSome ||
  colorSet.placeholderText->Option.isSome ||
  colorSet.icon->Option.isSome ||
  colorSet.error->Option.isSome ||
  colorSet.loaderBackground->Option.isSome ||
  colorSet.loaderForeground->Option.isSome

let mergeColors = (base: colors, sdk: colors): colors => {
  primary: coalesceOption(base.primary, sdk.primary),
  background: coalesceOption(base.background, sdk.background),
  componentBackground: coalesceOption(base.componentBackground, sdk.componentBackground),
  componentBorder: coalesceOption(base.componentBorder, sdk.componentBorder),
  componentDivider: coalesceOption(base.componentDivider, sdk.componentDivider),
  componentText: coalesceOption(base.componentText, sdk.componentText),
  primaryText: coalesceOption(base.primaryText, sdk.primaryText),
  secondaryText: coalesceOption(base.secondaryText, sdk.secondaryText),
  placeholderText: coalesceOption(base.placeholderText, sdk.placeholderText),
  icon: coalesceOption(base.icon, sdk.icon),
  error: coalesceOption(base.error, sdk.error),
  loaderBackground: coalesceOption(base.loaderBackground, sdk.loaderBackground),
  loaderForeground: coalesceOption(base.loaderForeground, sdk.loaderForeground),
}

let getColorsFromSdkProps = (defaults: sdkPropsDefaults): option<colors> => {
  let sdkColors = {
    primary: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsPrimaryKey,
    ),
    background: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsBackgroundKey,
    ),
    componentBackground: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsComponentBackgroundKey,
    ),
    componentBorder: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsComponentBorderKey,
    ),
    componentDivider: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsComponentDividerKey,
    ),
    componentText: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsComponentTextKey,
    ),
    primaryText: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsPrimaryTextKey,
    ),
    secondaryText: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsSecondaryTextKey,
    ),
    placeholderText: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsPlaceholderTextKey,
    ),
    icon: SuperpositionSdkProps.getNonEmptyString(defaults, SuperpositionSdkProps.colorsIconKey),
    error: SuperpositionSdkProps.getNonEmptyString(defaults, SuperpositionSdkProps.colorsErrorKey),
    loaderBackground: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsLoaderBackgroundKey,
    ),
    loaderForeground: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.colorsLoaderForegroundKey,
    ),
  }
  hasAnyColorValue(sdkColors) ? Some(sdkColors) : None
}

let mergeColorTypeWithSdkProps = (colorType, defaults: sdkPropsDefaults) =>
  switch getColorsFromSdkProps(defaults) {
  | None => colorType
  | Some(sdkColors) =>
    switch colorType {
    | Some(Colors(baseColors)) => Some(Colors(mergeColors(baseColors, sdkColors)))
    | Some(DefaultColors({light, dark})) =>
      Some(
        DefaultColors({
          light: Some(mergeColors(light->Option.getOr(emptyColors), sdkColors)),
          dark: Some(mergeColors(dark->Option.getOr(emptyColors), sdkColors)),
        }),
      )
    | None => Some(Colors(sdkColors))
    }
  }

let emptyShapes = {
  borderRadius: None,
  borderWidth: None,
  shadow: None,
}

let hasAnyShapeValue = (shapeSet: shapes) =>
  shapeSet.borderRadius->Option.isSome ||
  shapeSet.borderWidth->Option.isSome ||
  shapeSet.shadow->Option.isSome

let getShapesFromSdkProps = (defaults: sdkPropsDefaults): option<shapes> => {
  let sdkShapes = {
    borderRadius: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.shapesBorderRadiusKey,
    ),
    borderWidth: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.shapesBorderWidthKey,
    ),
    shadow: None,
  }
  hasAnyShapeValue(sdkShapes) ? Some(sdkShapes) : None
}

let getPrimaryButtonShapesFromSdkProps = (defaults: sdkPropsDefaults): option<shapes> => {
  let sdkShapes = {
    borderRadius: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.primaryButtonBorderRadiusKey,
    ),
    borderWidth: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.primaryButtonBorderWidthKey,
    ),
    shadow: None,
  }
  hasAnyShapeValue(sdkShapes) ? Some(sdkShapes) : None
}

let mergeShapes = (base: shapes, sdk: shapes): shapes => {
  borderRadius: coalesceOption(base.borderRadius, sdk.borderRadius),
  borderWidth: coalesceOption(base.borderWidth, sdk.borderWidth),
  shadow: coalesceOption(base.shadow, sdk.shadow),
}

let mergeShapesOption = (shapeOpt, sdkShapeOpt) =>
  switch (shapeOpt, sdkShapeOpt) {
  | (Some(baseShape), Some(sdkShape)) => Some(mergeShapes(baseShape, sdkShape))
  | (None, Some(sdkShape)) => Some(sdkShape)
  | (shapeOpt, None) => shapeOpt
  }

let emptyFont = {
  family: None,
  scale: None,
  headingTextSizeAdjust: None,
  subHeadingTextSizeAdjust: None,
  placeholderTextSizeAdjust: None,
  buttonTextSizeAdjust: None,
  errorTextSizeAdjust: None,
  linkTextSizeAdjust: None,
  modalTextSizeAdjust: None,
  cardTextSizeAdjust: None,
}

let hasAnyFontValue = (fontSet: font) =>
  fontSet.family->Option.isSome ||
  fontSet.scale->Option.isSome ||
  fontSet.headingTextSizeAdjust->Option.isSome ||
  fontSet.subHeadingTextSizeAdjust->Option.isSome ||
  fontSet.placeholderTextSizeAdjust->Option.isSome ||
  fontSet.buttonTextSizeAdjust->Option.isSome ||
  fontSet.errorTextSizeAdjust->Option.isSome ||
  fontSet.linkTextSizeAdjust->Option.isSome ||
  fontSet.modalTextSizeAdjust->Option.isSome ||
  fontSet.cardTextSizeAdjust->Option.isSome

let getFontFromSdkProps = (defaults: sdkPropsDefaults): option<font> => {
  let sdkFont = {
    family: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.fontFamilyKey,
    )->Option.map(fontFamily => CustomFont(fontFamily)),
    scale: SuperpositionSdkProps.getFloat(defaults, SuperpositionSdkProps.fontScaleKey),
    headingTextSizeAdjust: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.fontHeadingTextSizeAdjustKey,
    ),
    subHeadingTextSizeAdjust: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.fontSubHeadingTextSizeAdjustKey,
    ),
    placeholderTextSizeAdjust: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.fontPlaceholderTextSizeAdjustKey,
    ),
    buttonTextSizeAdjust: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.fontButtonTextSizeAdjustKey,
    ),
    errorTextSizeAdjust: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.fontErrorTextSizeAdjustKey,
    ),
    linkTextSizeAdjust: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.fontLinkTextSizeAdjustKey,
    ),
    modalTextSizeAdjust: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.fontModalTextSizeAdjustKey,
    ),
    cardTextSizeAdjust: SuperpositionSdkProps.getFloat(
      defaults,
      SuperpositionSdkProps.fontCardTextSizeAdjustKey,
    ),
  }
  hasAnyFontValue(sdkFont) ? Some(sdkFont) : None
}

let mergeFont = (base: font, sdk: font): font => {
  family: coalesceOption(base.family, sdk.family),
  scale: coalesceOption(base.scale, sdk.scale),
  headingTextSizeAdjust: coalesceOption(base.headingTextSizeAdjust, sdk.headingTextSizeAdjust),
  subHeadingTextSizeAdjust: coalesceOption(
    base.subHeadingTextSizeAdjust,
    sdk.subHeadingTextSizeAdjust,
  ),
  placeholderTextSizeAdjust: coalesceOption(
    base.placeholderTextSizeAdjust,
    sdk.placeholderTextSizeAdjust,
  ),
  buttonTextSizeAdjust: coalesceOption(base.buttonTextSizeAdjust, sdk.buttonTextSizeAdjust),
  errorTextSizeAdjust: coalesceOption(base.errorTextSizeAdjust, sdk.errorTextSizeAdjust),
  linkTextSizeAdjust: coalesceOption(base.linkTextSizeAdjust, sdk.linkTextSizeAdjust),
  modalTextSizeAdjust: coalesceOption(base.modalTextSizeAdjust, sdk.modalTextSizeAdjust),
  cardTextSizeAdjust: coalesceOption(base.cardTextSizeAdjust, sdk.cardTextSizeAdjust),
}

let mergeFontOption = (fontOpt, sdkFontOpt) =>
  switch (fontOpt, sdkFontOpt) {
  | (Some(baseFont), Some(sdkFont)) => Some(mergeFont(baseFont, sdkFont))
  | (None, Some(sdkFont)) => Some(sdkFont)
  | (fontOpt, None) => fontOpt
  }

let emptyPrimaryButtonColor = {
  background: None,
  text: None,
  border: None,
}

let hasAnyPrimaryButtonColorValue = (colorSet: primaryButtonColor) =>
  colorSet.background->Option.isSome ||
  colorSet.text->Option.isSome ||
  colorSet.border->Option.isSome

let getPrimaryButtonColorFromSdkProps = (defaults: sdkPropsDefaults): option<
  primaryButtonColor,
> => {
  let sdkColors = {
    background: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.primaryButtonBackgroundKey,
    ),
    text: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.primaryButtonTextKey,
    ),
    border: SuperpositionSdkProps.getNonEmptyString(
      defaults,
      SuperpositionSdkProps.primaryButtonBorderKey,
    ),
  }
  hasAnyPrimaryButtonColorValue(sdkColors) ? Some(sdkColors) : None
}

let mergePrimaryButtonColor = (
  base: primaryButtonColor,
  sdk: primaryButtonColor,
): primaryButtonColor => {
  background: coalesceOption(base.background, sdk.background),
  text: coalesceOption(base.text, sdk.text),
  border: coalesceOption(base.border, sdk.border),
}

let mergePrimaryButtonColorTypeWithSdkProps = (colorType, defaults: sdkPropsDefaults): option<
  primaryButtonColorType,
> =>
  switch getPrimaryButtonColorFromSdkProps(defaults) {
  | None => colorType
  | Some(sdkColors) =>
    switch colorType {
    | Some(PrimaryButtonColor(baseColors)) =>
      Some(
        PrimaryButtonColor(
          Some(
            mergePrimaryButtonColor(baseColors->Option.getOr(emptyPrimaryButtonColor), sdkColors),
          ),
        ),
      )
    | Some(PrimaryButtonDefault({light, dark})) =>
      Some(
        PrimaryButtonDefault({
          light: Some(
            mergePrimaryButtonColor(light->Option.getOr(emptyPrimaryButtonColor), sdkColors),
          ),
          dark: Some(
            mergePrimaryButtonColor(dark->Option.getOr(emptyPrimaryButtonColor), sdkColors),
          ),
        }),
      )
    | None => Some(PrimaryButtonColor(Some(sdkColors)))
    }
  }

let mergePrimaryButtonWithSdkProps = (
  buttonOpt: option<primaryButton>,
  defaults: sdkPropsDefaults,
): option<primaryButton> =>
  switch buttonOpt {
  | Some(button) =>
    Some({
      shapes: mergeShapesOption(button.shapes, getPrimaryButtonShapesFromSdkProps(defaults)),
      primaryButtonColor: mergePrimaryButtonColorTypeWithSdkProps(
        button.primaryButtonColor,
        defaults,
      ),
    })
  | None =>
    switch (
      getPrimaryButtonShapesFromSdkProps(defaults),
      mergePrimaryButtonColorTypeWithSdkProps(None, defaults),
    ) {
    | (None, None) => None
    | (shapes, colors) =>
      Some({
        shapes,
        primaryButtonColor: colors,
      })
    }
  }

let applyAppearanceSdkProps = (appearance: appearance, defaults: sdkPropsDefaults): appearance => {
  ...appearance,
  colors: mergeColorTypeWithSdkProps(appearance.colors, defaults),
  shapes: mergeShapesOption(appearance.shapes, getShapesFromSdkProps(defaults)),
  font: mergeFontOption(appearance.font, getFontFromSdkProps(defaults)),
  primaryButton: mergePrimaryButtonWithSdkProps(appearance.primaryButton, defaults),
  applePay: {
    ...appearance.applePay,
    buttonStyle: coalesceOption(
      appearance.applePay.buttonStyle,
      getApplePayButtonStyleFromSdkProps(defaults),
    ),
  },
}

let getDefaultAppearanceWithSdkProps = (defaults: sdkPropsDefaults): appearance => {
  applyAppearanceSdkProps(
    {
      ...defaultAppearance,
      locale: getLocaleFromSdkProps(defaults),
      googlePay: {
        ...defaultAppearance.googlePay,
        buttonType: getGooglePayButtonTypeFromSdkProps(defaults)->Option.getOr(
          defaultAppearance.googlePay.buttonType,
        ),
      },
      applePay: {
        buttonType: getApplePayButtonTypeFromSdkProps(defaults)->Option.getOr(
          defaultAppearance.applePay.buttonType,
        ),
        buttonStyle: getApplePayButtonStyleFromSdkProps(defaults),
      },
      theme: getThemeFromSdkProps(defaults)->Option.getOr(defaultAppearance.theme),
      layout: getLayoutFromSdkProps(defaults),
    },
    defaults,
  )
}
