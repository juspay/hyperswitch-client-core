open Utils
include AppearanceTypes
open AppearanceSdkUtils

type payment_method_type_wallet = GOOGLE_PAY | APPLE_PAY | PAYPAL | SAMSUNG_PAY | NONE

let defaultCountry = "US"

let walletNameMapper = str => {
  switch str {
  | "google_pay" => "Google Pay"
  | "apple_pay" => "Apple Pay"
  | "paypal" => "Paypal"
  | "samsung_pay" => "Samsung Pay"
  | _ => ""
  }
}

let walletNameToTypeMapper = str => {
  switch str {
  | "Google Pay" => GOOGLE_PAY
  | "Apple Pay" => APPLE_PAY
  | "Paypal" => PAYPAL
  | "Samsung Pay" => SAMSUNG_PAY
  | _ => NONE
  }
}

type savedCard = {
  cardScheme?: string,
  // walletType?: string,
  name?: string,
  cardHolderName?: string,
  cardNumber?: string,
  expiry_date?: string,
  payment_token?: string,
  paymentMethodId?: string,
  mandate_id?: string,
  nick_name?: string,
  isDefaultPaymentMethod?: bool,
  requiresCVV: bool,
  created?: string,
  lastUsedAt?: string,
}

type savedWallet = {
  payment_method_type?: string,
  walletType?: string,
  payment_token?: string,
  paymentMethodId?: string,
  isDefaultPaymentMethod?: bool,
  created?: string,
  lastUsedAt?: string,
}

// type savedDataType =
//   | SAVEDLISTCARD(savedCard)
//   | SAVEDLISTWALLET(savedWallet)
//   | NONE

type customPickerType = {
  label: string,
  value: string,
  icon?: string,
}

type address = {
  first_name?: string,
  last_name?: string,
  city?: string,
  country?: string,
  line1?: string,
  line2?: string,
  line3?: string,
  zip?: string,
  state?: string,
}

type phone = {
  number?: string,
  country_code?: string,
}

type addressDetails = {
  address: option<address>,
  email: option<string>,
  phone: option<phone>,
}

type customerConfiguration = {
  id: option<string>,
  ephemeralKeySecret: option<string>,
}

type placeholder = {
  cardNumber: string,
  expiryDate: string,
  cvv: string,
}

type configurationType = {
  allowsDelayedPaymentMethods: bool,
  appearance: appearance,
  shippingDetails: option<addressDetails>,
  primaryButtonLabel: option<string>,
  paymentSheetHeaderText: option<string>,
  savedPaymentScreenHeaderText: option<string>,
  merchantDisplayName: string,
  defaultBillingDetails: option<addressDetails>,
  primaryButtonColor: option<string>,
  allowsPaymentMethodsRequiringShippingAddress: bool,
  displaySavedPaymentMethodsCheckbox: bool,
  displaySavedPaymentMethods: bool,
  placeholder: placeholder,
  defaultView: bool,
  netceteraSDKApiKey: option<string>,
  displayDefaultSavedPaymentIcon: bool,
  enablePartialLoading: bool,
  displayMergedSavedMethods: bool,
  disableBranding: bool,
}

type sdkState =
  | PaymentSheet
  | ButtonSheet
  | TabSheet
  | WidgetPaymentSheet
  | WidgetButtonSheet
  | WidgetTabSheet
  | HostedCheckout
  | CardWidget
  | CustomWidget(payment_method_type_wallet)
  | ExpressCheckoutWidget
  | PaymentMethodsManagement
  | Headless
  | NoView

let widgetToStrMapper = str => {
  switch str {
  | GOOGLE_PAY => "GOOGLE_PAY"
  | PAYPAL => "PAYPAL"
  | _ => ""
  }
}

let walletTypeToStrMapper = walletType => {
  switch walletType {
  | GOOGLE_PAY => "google_pay"
  | APPLE_PAY => "apple_pay"
  | PAYPAL => "paypal"
  | SAMSUNG_PAY => "samsung_pay"
  | _ => ""
  }
}

let sdkStateToStrMapper = sdkState => {
  switch sdkState {
  | PaymentSheet => "PAYMENT_SHEET"
  | TabSheet => "TAB_SHEET"
  | ButtonSheet => "BUTTON_SHEET"
  | WidgetPaymentSheet => "WIDGET_PAYMENT_SHEET"
  | WidgetTabSheet => "WIDGET_TAB_SHEET"
  | WidgetButtonSheet => "WIDGET_BUTTON_SHEET"
  | HostedCheckout => "HOSTED_CHECKOUT"
  | CardWidget => "CARD_FORM"
  | CustomWidget(str) => str->widgetToStrMapper
  | ExpressCheckoutWidget => "EXPRESS_CHECKOUT_WIDGET"
  | PaymentMethodsManagement => "PAYMENT_METHODS_MANAGEMENT"
  | Headless => "HEADLESS"
  | NoView => "NO_VIEW"
  }
}

type hyperParams = {
  confirm: bool,
  appId?: string,
  country: string,
  disableBranding: bool,
  enableSuperpositionSdkProps: bool,
  userAgent: option<string>,
  launchTime?: float,
  sdkVersion: string,
  device_model: option<string>,
  os_type: option<string>,
  os_version: option<string>,
  deviceBrand: option<string>,
  bottomInset: option<float>,
  topInset: option<float>,
  leftInset: option<float>,
  rightInset: option<float>,
  superpositionConfigRaw: option<JSON.t>,
}

type nativeProp = {
  publishableKey: string,
  clientSecret: string,
  paymentMethodId: string,
  ephemeralKey: option<string>,
  customBackendUrl: option<string>,
  customLogUrl: option<string>,
  sessionId: string,
  from: string,
  configuration: configurationType,
  env: GlobalVars.envType,
  sdkState: sdkState,
  rootTag: int,
  hyperParams: hyperParams,
  customParams: Dict.t<JSON.t>,
  subscribedEvents: array<string>,
  widgetId: string,
}

type sdkPropsDefaults = SuperpositionSdkProps.t

let defaultAppearance = AppearanceSdkUtils.defaultAppearance

let getColorFromDict = (colorDict, keys: NativeSdkPropsKeys.keys) => {
  primary: retOptionalNonEmptyStr(getProp(keys.primary, colorDict)),
  background: retOptionalNonEmptyStr(getProp(keys.background, colorDict)),
  componentBackground: retOptionalNonEmptyStr(getProp(keys.componentBackground, colorDict)),
  componentBorder: retOptionalNonEmptyStr(getProp(keys.componentBorder, colorDict)),
  componentDivider: retOptionalNonEmptyStr(getProp(keys.componentDivider, colorDict)),
  componentText: retOptionalNonEmptyStr(getProp(keys.componentText, colorDict)),
  primaryText: retOptionalNonEmptyStr(getProp(keys.primaryText, colorDict)),
  secondaryText: retOptionalNonEmptyStr(getProp(keys.secondaryText, colorDict)),
  placeholderText: retOptionalNonEmptyStr(getProp(keys.placeholderText, colorDict)),
  icon: retOptionalNonEmptyStr(getProp(keys.icon, colorDict)),
  error: retOptionalNonEmptyStr(getProp(keys.error, colorDict)),
  loaderBackground: retOptionalNonEmptyStr(getProp(keys.loadingBgColor, colorDict)),
  loaderForeground: retOptionalNonEmptyStr(getProp(keys.loadingFgColor, colorDict)),
}

let getPrimaryButtonColorFromDict = (primaryButtonColorDict, keys: NativeSdkPropsKeys.keys) => {
  {
    background: retOptionalNonEmptyStr(
      getProp(keys.primaryButton_background, primaryButtonColorDict),
    ),
    text: retOptionalNonEmptyStr(getProp(keys.primaryButton_text, primaryButtonColorDict)),
    border: retOptionalNonEmptyStr(getProp(keys.primaryButton_border, primaryButtonColorDict)),
  }
}

let getAppearanceObj = (
  appearanceDict: Dict.t<JSON.t>,
  keys: NativeSdkPropsKeys.keys,
  from: string,
  sdkPropsDefaults: sdkPropsDefaults,
) => {
  let fontDict = getObj(appearanceDict, keys.font, Dict.make())
  let primaryButtonDict = getObj(appearanceDict, keys.primaryButton, Dict.make())
  let primaryButtonShapesDict = switch keys.primaryButton_shapes {
  | "" => primaryButtonDict
  | _ => getObj(primaryButtonDict, keys.primaryButton_shapes, Dict.make())
  }

  let googlePayDict = getObj(appearanceDict, "googlePay", Dict.make())
  let googlePayButtonStyle = getOptionalObj(googlePayDict, "buttonStyle")

  let applePayDict = getObj(appearanceDict, "applePay", Dict.make())
  let applePayButtonStyle = getOptionalObj(applePayDict, "buttonStyle")

  applyAppearanceSdkProps(
    {
      locale: getAppearanceLocale(appearanceDict, keys, sdkPropsDefaults),
      colors: from == "rn" || from == "flutter"
        ? {
            let colors = getObj(appearanceDict, keys.colors, Dict.make())

            let colorsLightDict = colors->Dict.get(keys.light)->Option.flatMap(JSON.Decode.object)

            let colorsDarkDict = colors->Dict.get(keys.dark)->Option.flatMap(JSON.Decode.object)

            Some(
              colorsLightDict === None && colorsDarkDict === None
                ? Colors(getColorFromDict(colors, keys))
                : DefaultColors({
                    light: Some(getColorFromDict(colorsLightDict->Option.getOr(Dict.make()), keys)),
                    dark: Some(getColorFromDict(colorsDarkDict->Option.getOr(Dict.make()), keys)),
                  }),
            )
          }
        : switch keys.colors {
          | "" =>
            let colorsLightDict = getObj(appearanceDict, keys.light, Dict.make())
            let colorsDarkDict = getObj(appearanceDict, keys.dark, Dict.make())
            Some(
              DefaultColors({
                light: Some(getColorFromDict(colorsLightDict, keys)),
                dark: Some(getColorFromDict(colorsDarkDict, keys)),
              }),
            )
          | _ =>
            let colors = getObj(appearanceDict, keys.colors, Dict.make())
            Some(Colors(getColorFromDict(colors, keys)))
          },
      shapes: {
        let shapesDict = getObj(appearanceDict, keys.shapes, Dict.make())
        let shadowDict = getObj(
          keys.shapes == "" ? appearanceDict : shapesDict,
          keys.shadow,
          Dict.make(),
        )
        let offsetDict = getObj(shadowDict, keys.shadow_offset, Dict.make())
        Some({
          borderRadius: retOptionalFloat(getProp(keys.borderRadius, shapesDict)),
          borderWidth: retOptionalFloat(getProp(keys.borderWidth, shapesDict)),
          shadow: Some({
            color: retOptionalStr(getProp(keys.shadow_color, shadowDict)),
            opacity: retOptionalFloat(getProp(keys.shadow_opacity, shadowDict)),
            blurRadius: retOptionalFloat(getProp(keys.shadow_blurRadius, shadowDict)),
            offset: Some({
              x: retOptionalFloat(getProp(keys.x, offsetDict)),
              y: retOptionalFloat(getProp(keys.y, offsetDict)),
            }),
            intensity: retOptionalFloat(getProp(keys.shadow_intensity, shadowDict)),
          }),
        })
      },
      font: Some({
        family: switch switch ReactNative.Platform.os {
        | #ios | #android => retOptionalNonEmptyStr(getProp(keys.family, fontDict))
        | _ => retOptionalNonEmptyStr(getProp("family", fontDict))
        } {
        | Some(str) => Some(CustomFont(str))
        | None => None
        },
        scale: retOptionalFloat(getProp(keys.scale, fontDict)),
        headingTextSizeAdjust: retOptionalFloat(getProp(keys.headingTextSizeAdjust, fontDict)),
        subHeadingTextSizeAdjust: retOptionalFloat(
          getProp(keys.subHeadingTextSizeAdjust, fontDict),
        ),
        placeholderTextSizeAdjust: retOptionalFloat(
          getProp(keys.placeholderTextSizeAdjust, fontDict),
        ),
        buttonTextSizeAdjust: retOptionalFloat(getProp(keys.buttonTextSizeAdjust, fontDict)),
        errorTextSizeAdjust: retOptionalFloat(getProp(keys.errorTextSizeAdjust, fontDict)),
        linkTextSizeAdjust: retOptionalFloat(getProp(keys.linkTextSizeAdjust, fontDict)),
        modalTextSizeAdjust: retOptionalFloat(getProp(keys.modalTextSizeAdjust, fontDict)),
        cardTextSizeAdjust: retOptionalFloat(getProp(keys.cardTextSizeAdjust, fontDict)),
      }),
      primaryButton: Some({
        shapes: Some({
          borderRadius: retOptionalFloat(
            getProp(keys.primaryButton_borderRadius, primaryButtonShapesDict),
          ),
          borderWidth: retOptionalFloat(
            getProp(keys.primaryButton_borderWidth, primaryButtonShapesDict),
          ),
          shadow: {
            let primaryButtonShadowDict = getObj(
              keys.primaryButton_shapes == "" ? appearanceDict : primaryButtonShapesDict,
              keys.primaryButton_shadow,
              Dict.make(),
            )
            let primaryButtonOffsetDict = getObj(
              primaryButtonShadowDict,
              keys.primaryButton_offset,
              Dict.make(),
            )
            Some({
              color: retOptionalStr(getProp(keys.primaryButton_color, primaryButtonShadowDict)),
              opacity: retOptionalFloat(
                getProp(keys.primaryButton_opacity, primaryButtonShadowDict),
              ),
              blurRadius: retOptionalFloat(
                getProp(keys.primaryButton_blurRadius, primaryButtonShadowDict),
              ),
              offset: Some({
                x: retOptionalFloat(getProp(keys.x, primaryButtonOffsetDict)),
                y: retOptionalFloat(getProp(keys.y, primaryButtonOffsetDict)),
              }),
              intensity: retOptionalFloat(
                getProp(keys.primaryButton_intensity, primaryButtonShadowDict),
              ),
            })
          },
        }),
        primaryButtonColor: from == "rn" || from == "flutter"
          ? {
              let primaryButtonColors = getObj(
                primaryButtonDict,
                keys.primaryButton_color,
                Dict.make(),
              )

              let primaryButtonColorsLightDict =
                primaryButtonColors
                ->Dict.get(keys.primaryButton_light)
                ->Option.flatMap(JSON.Decode.object)

              let primaryButtonColorsDarkDict =
                primaryButtonColors
                ->Dict.get(keys.primaryButton_dark)
                ->Option.flatMap(JSON.Decode.object)

              Some(
                primaryButtonColorsLightDict === None && primaryButtonColorsDarkDict === None
                  ? PrimaryButtonColor(
                      Some(getPrimaryButtonColorFromDict(primaryButtonColors, keys)),
                    )
                  : PrimaryButtonDefault({
                      light: Some(
                        getPrimaryButtonColorFromDict(
                          primaryButtonColorsLightDict->Option.getOr(Dict.make()),
                          keys,
                        ),
                      ),
                      dark: Some(
                        getPrimaryButtonColorFromDict(
                          primaryButtonColorsDarkDict->Option.getOr(Dict.make()),
                          keys,
                        ),
                      ),
                    }),
              )
            }
          : switch keys.primaryButton_color {
            | "" =>
              Some(PrimaryButtonColor(Some(getPrimaryButtonColorFromDict(primaryButtonDict, keys))))
            | _ =>
              let primaryButtonColorLightDict = getObj(
                primaryButtonDict,
                keys.primaryButton_light,
                Dict.make(),
              )

              let primaryButtonColorDarkDict = getObj(
                primaryButtonDict,
                keys.primaryButton_dark,
                Dict.make(),
              )

              Some(
                PrimaryButtonDefault({
                  light: Some(getPrimaryButtonColorFromDict(primaryButtonColorLightDict, keys)),
                  dark: Some(getPrimaryButtonColorFromDict(primaryButtonColorDarkDict, keys)),
                }),
              )
            },
      }),
      googlePay: {
        buttonType: getGooglePayButtonType(googlePayDict, sdkPropsDefaults),
        buttonStyle: googlePayButtonStyle->Option.map(googlePayButtonStyle => {
          let style: googlePayThemeBaseStyle = {
            light: switch getString(googlePayButtonStyle, "light", "") {
            | "light" => #light
            | "dark" => #dark
            | _ => #dark
            },
            dark: switch getString(googlePayButtonStyle, "dark", "") {
            | "light" => #light
            | "dark" => #dark
            | _ => #light
            },
          }
          style
        }),
      },
      applePay: {
        buttonType: getApplePayButtonType(applePayDict, sdkPropsDefaults),
        buttonStyle: coalesceOption(
          applePayButtonStyle->Option.map(applePayButtonStyle => {
            let style: applePayThemeBaseStyle = {
              light: switch getString(applePayButtonStyle, "light", "") {
              | "white" => #white
              | "whiteOutline" => #whiteOutline
              | "black" => #black
              | _ => #black
              },
              dark: switch getString(applePayButtonStyle, "dark", "") {
              | "white" => #white
              | "whiteOutline" => #whiteOutline
              | "black" => #black
              | _ => #white
              },
            }
            style
          }),
          getApplePayButtonStyleFromSdkProps(sdkPropsDefaults),
        ),
      },
      theme: getAppearanceTheme(appearanceDict, sdkPropsDefaults),
      layout: getAppearanceLayout(appearanceDict, sdkPropsDefaults),
    },
    sdkPropsDefaults,
  )
}

let getPrimaryColor = (colors, ~theme=Default) =>
  switch colors {
  | Colors(c) => c.primary
  | DefaultColors(df) =>
    switch theme {
    | Dark => df.dark->Option.flatMap(d => d.primary)
    | _ => df.light->Option.flatMap(l => l.primary)
    }
  }

let parseConfigurationDict = (configObj, from, sdkPropsDefaults) => {
  let shippingDetailsDict =
    configObj->Dict.get("shippingDetails")->Option.flatMap(JSON.Decode.object)
  let billingDetailsDict = getObj(configObj, "defaultBillingDetails", Dict.make())

  let _customerDict = configObj->Dict.get("customer")->Option.flatMap(JSON.Decode.object)
  let addressDict = getOptionalObj(billingDetailsDict, "address")
  let billingName =
    getOptionString(billingDetailsDict, "name")
    ->Option.getOr("default")
    ->String.split(" ")

  let appearanceDict = configObj->Dict.get("appearance")->Option.flatMap(JSON.Decode.object)
  let appearance = {
    from == "rn" || from == "flutter" || WebKit.platform === #web
      ? switch appearanceDict {
        | Some(appObj) =>
          getAppearanceObj(appObj, NativeSdkPropsKeys.rnKeys, from, sdkPropsDefaults)
        | None => getDefaultAppearanceWithSdkProps(sdkPropsDefaults)
        }
      : switch appearanceDict {
        | Some(appObj) =>
          switch WebKit.platform {
          | #ios | #iosWebView =>
            getAppearanceObj(appObj, NativeSdkPropsKeys.iosKeys, from, sdkPropsDefaults)
          | #android | #androidWebView =>
            getAppearanceObj(appObj, NativeSdkPropsKeys.androidKeys, from, sdkPropsDefaults)
          | _ => getDefaultAppearanceWithSdkProps(sdkPropsDefaults)
          }
        | None => getDefaultAppearanceWithSdkProps(sdkPropsDefaults)
        }
  }
  let placeholderDict =
    configObj
    ->Dict.get("placeholder")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.getOr(Dict.make())

  let configuration = {
    allowsDelayedPaymentMethods: SuperpositionSdkProps.getBoolWithFallback(
      configObj,
      "allowsDelayedPaymentMethods",
      sdkPropsDefaults,
      SuperpositionSdkProps.allowsDelayedPaymentMethodsKey,
      false,
    ),
    appearance,
    shippingDetails: switch shippingDetailsDict {
    | Some(shippingObj) =>
      let addressObj = getOptionalObj(shippingObj, "address")
      let (first_name, last_name) = getOptionString(shippingObj, "name")->splitName
      addressObj->Option.map(addressObj => {
        address: Some({
          first_name,
          last_name,
          city: ?getOptionString(addressObj, "city"),
          country: ?getOptionString(addressObj, "country"),
          line1: ?getOptionString(addressObj, "line1"),
          line2: ?getOptionString(addressObj, "line2"),
          zip: ?getOptionString(addressObj, "postalCode"),
          state: ?getOptionString(addressObj, "state"),
        }),
        phone: Some({
          number: ?getOptionString(shippingObj, "phoneNumber"),
        }),
        //isCheckboxSelected: getOptionBool(shippingObj, "isCheckboxSelected"),
        email: None, //getOptionString(shippingObj, "email"),
        //name: None, getOptionString(shippingObj, "name"),
      })
    | None => None
    },
    primaryButtonLabel: SuperpositionSdkProps.getOptionStringWithFallback(
      configObj,
      "primaryButtonLabel",
      sdkPropsDefaults,
      SuperpositionSdkProps.primaryButtonLabelKey,
    ),
    paymentSheetHeaderText: SuperpositionSdkProps.getOptionStringWithFallback(
      configObj,
      "paymentSheetHeaderLabel",
      sdkPropsDefaults,
      SuperpositionSdkProps.paymentSheetHeaderTextKey,
    ),
    savedPaymentScreenHeaderText: getOptionString(configObj, "savedPaymentSheetHeaderLabel"),
    displayDefaultSavedPaymentIcon: SuperpositionSdkProps.getBoolWithFallback(
      configObj,
      "displayDefaultSavedPaymentIcon",
      sdkPropsDefaults,
      SuperpositionSdkProps.displayDefaultSavedPaymentIconKey,
      true,
    ),
    enablePartialLoading: SuperpositionSdkProps.getBoolWithFallback(
      configObj,
      "enablePartialLoading",
      sdkPropsDefaults,
      SuperpositionSdkProps.enablePartialLoadingKey,
      false,
    ),
    // customer: switch customerDict {
    // | Some(obj) =>
    //   Some({
    //     id: getOptionString(obj, "id"),
    //     ephemeralKeySecret: getOptionString(obj, "ephemeralKeySecret"),
    //   })
    // | _ => None
    // },
    merchantDisplayName: SuperpositionSdkProps.getStringWithFallback(
      configObj,
      "merchantDisplayName",
      sdkPropsDefaults,
      SuperpositionSdkProps.merchantDisplayNameKey,
      "",
    ),
    defaultBillingDetails: addressDict->Option.map(addressDict => {
      address: Some({
        first_name: ?(
          billingName->Array.get(0) === Some("default") ? None : billingName->Array.get(0)
        ),
        last_name: ?(billingName->Array.length > 1 ? billingName[1] : None),
        city: ?getOptionString(addressDict, "city"),
        country: ?getOptionString(addressDict, "country"),
        line1: ?getOptionString(addressDict, "line1"),
        line2: ?getOptionString(addressDict, "line2"),
        zip: ?getOptionString(addressDict, "postalCode"),
        state: ?getOptionString(addressDict, "state"),
      }),
      phone: Some({
        number: ?getOptionString(billingDetailsDict, "phoneNumber"),
      }),
      email: None, //getOptionString(billingDetailsDict, "email"),
      //name: None, getOptionString(billingDetailsDict, "name"),
    }),
    primaryButtonColor: getOptionString(configObj, "primaryButtonColor"),
    allowsPaymentMethodsRequiringShippingAddress: SuperpositionSdkProps.getBoolWithFallback(
      configObj,
      "allowsPaymentMethodsRequiringShippingAddress",
      sdkPropsDefaults,
      SuperpositionSdkProps.allowsPaymentMethodsRequiringShippingAddressKey,
      false,
    ),
    displaySavedPaymentMethodsCheckbox: SuperpositionSdkProps.getBoolWithFallback(
      configObj,
      "displaySavedPaymentMethodsCheckbox",
      sdkPropsDefaults,
      SuperpositionSdkProps.displaySavedPaymentMethodsCheckboxKey,
      true,
    ),
    displaySavedPaymentMethods: SuperpositionSdkProps.getBoolWithFallback(
      configObj,
      "displaySavedPaymentMethods",
      sdkPropsDefaults,
      SuperpositionSdkProps.displaySavedPaymentMethodsKey,
      true,
    ),
    defaultView: SuperpositionSdkProps.getBoolWithFallback(
      configObj,
      "defaultView",
      sdkPropsDefaults,
      SuperpositionSdkProps.defaultViewKey,
      false,
    ),
    netceteraSDKApiKey: getOptionString(configObj, "netceteraSDKApiKey"),
    placeholder: {
      cardNumber: SuperpositionSdkProps.getStringWithFallback(
        placeholderDict,
        "cardNumber",
        sdkPropsDefaults,
        SuperpositionSdkProps.placeholderCardNumberKey,
        "1234 1234 1234 1234",
      ),
      expiryDate: SuperpositionSdkProps.getStringWithFallback(
        placeholderDict,
        "expiryDate",
        sdkPropsDefaults,
        SuperpositionSdkProps.placeholderExpiryDateKey,
        "MM / YY",
      ),
      cvv: SuperpositionSdkProps.getStringWithFallback(
        placeholderDict,
        "cvv",
        sdkPropsDefaults,
        SuperpositionSdkProps.placeholderCvvKey,
        "CVC",
      ),
    },
    displayMergedSavedMethods: SuperpositionSdkProps.getBoolWithFallback(
      configObj,
      "displayMergedSavedMethods",
      sdkPropsDefaults,
      SuperpositionSdkProps.displayMergedSavedMethodsKey,
      false,
    ),
    disableBranding: SuperpositionSdkProps.getBoolWithFallback(
      configObj,
      "disableBranding",
      sdkPropsDefaults,
      SuperpositionSdkProps.disableBrandingKey,
      false,
    ),
  }
  configuration
}

let nativeJsonToRecord = (jsonFromNative, rootTag) => {
  let dictfromNative = jsonFromNative->JSON.Decode.object->Option.getOr(Dict.make())
  let configurationDict = getObj(dictfromNative, "configuration", Dict.make())
  let from = getOptionString(dictfromNative, "from")->Option.getOr("native")

  let publishableKey = getString(dictfromNative, "publishableKey", "")
  let customBackendUrl = switch getOptionString(dictfromNative, "customBackendUrl") {
  | Some("") => None
  | val => val
  }
  let customLogUrl = switch getOptionString(dictfromNative, "customLogUrl") {
  | Some("") => None
  | val => val
  }

  let hyperParamsDict = getObj(dictfromNative, "hyperParams", Dict.make())
  let nativeSuperpositionConfig = SuperpositionSdkProps.getNativeConfig(hyperParamsDict)
  let enableSuperpositionSdkProps = getBool(hyperParamsDict, "enableSuperpositionSdkProps", true)
  let sdkPropsDefaults = enableSuperpositionSdkProps
    ? SuperpositionSdkProps.parse(nativeSuperpositionConfig)
    : SuperpositionSdkProps.empty
  let configuration = parseConfigurationDict(configurationDict, from, sdkPropsDefaults)
  let resolvedHyperParams = {
    appId: ?getOptionString(hyperParamsDict, "appId"),
    country: switch getOptionString(hyperParamsDict, "country") {
    | Some("") | None => defaultCountry
    | Some(country) => country
    },
    disableBranding: getBool(
      hyperParamsDict,
      "disableBranding",
      SuperpositionSdkProps.getBool(
        sdkPropsDefaults,
        SuperpositionSdkProps.disableBrandingKey,
        false,
      ),
    ),
    enableSuperpositionSdkProps,
    userAgent: getOptionString(hyperParamsDict, "user-agent"),
    confirm: getBool(hyperParamsDict, "confirm", false),
    launchTime: ?getOptionFloat(hyperParamsDict, "launchTime"),
    sdkVersion: getString(hyperParamsDict, "sdkVersion", ""),
    device_model: getOptionString(hyperParamsDict, "device_model"),
    os_type: getOptionString(hyperParamsDict, "os_type"),
    os_version: getOptionString(hyperParamsDict, "os_version"),
    deviceBrand: getOptionString(hyperParamsDict, "deviceBrand"),
    bottomInset: getOptionFloat(hyperParamsDict, "bottomInset"),
    topInset: getOptionFloat(hyperParamsDict, "topInset"),
    leftInset: getOptionFloat(hyperParamsDict, "leftInset"),
    rightInset: getOptionFloat(hyperParamsDict, "rightInset"),
    superpositionConfigRaw: nativeSuperpositionConfig,
  }

  {
    from,
    env: GlobalVars.checkEnv(publishableKey),
    rootTag,
    publishableKey,
    clientSecret: getString(dictfromNative, "clientSecret", ""),
    paymentMethodId: String.split(getString(dictfromNative, "clientSecret", ""), "_secret_")
    ->Array.get(0)
    ->Option.getOr(""),
    ephemeralKey: getOptionString(dictfromNative, "ephemeralKey"),
    customBackendUrl,
    customLogUrl,
    sessionId: getString(dictfromNative, "sessionId", ""),
    widgetId: getString(dictfromNative, "widgetId", ""),
    sdkState: switch getString(dictfromNative, "type", "") {
    | "payment" => PaymentSheet
    | "tabSheet" => TabSheet
    | "buttonSheet" => ButtonSheet
    | "widgetPaymentSheet" => WidgetPaymentSheet
    | "widgetTabSheet" => WidgetTabSheet
    | "widgetButtonSheet" => WidgetButtonSheet
    | "hostedCheckout" => HostedCheckout
    | "google_pay" => CustomWidget(GOOGLE_PAY)
    | "paypal" => CustomWidget(PAYPAL)
    | "card" => CardWidget
    | "paymentMethodsManagement" => PaymentMethodsManagement
    | "expressCheckout" => ExpressCheckoutWidget
    | "headless" => Headless
    | _ => NoView
    },
    configuration,
    hyperParams: resolvedHyperParams,
    customParams: getObj(dictfromNative, "customParams", Dict.make()),
    subscribedEvents: switch dictfromNative->Dict.get("subscribedEvents") {
    | Some(json) =>
      json
      ->JSON.Decode.array
      ->Option.getOr([])
      ->Array.map(event => event->JSON.Decode.string->Option.getOr(""))
    | None => []
    },
  }
}
