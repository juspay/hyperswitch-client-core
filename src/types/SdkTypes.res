open Utils

type fontFamilyTypes = DefaultIOS | DefaultAndroid | CustomFont(string) | DefaultWeb

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

type customPickerType = {
  label: string,
  value: string,
  icon?: string,
}

type colors = {
  primary: option<string>,
  background: option<string>,
  componentBackground: option<string>,
  componentBorder: option<string>,
  componentDivider: option<string>,
  componentText: option<string>,
  primaryText: option<string>,
  secondaryText: option<string>,
  placeholderText: option<string>,
  icon: option<string>,
  error: option<string>,
  loaderBackground: option<string>,
  loaderForeground: option<string>,
  selectedComponentBackground: option<string>,
  selectedComponentBorder: option<string>,
  selectedComponentBorderWidth: option<float>,
  selectedComponentDivider: option<string>,
  selectedComponentText: option<string>,
}

type colorType = {light: option<colors>, dark: option<colors>}

// IOS Specific
type offsetType = {
  x: option<float>,
  y: option<float>,
}
type shadowConfig = {
  color: option<string>,
  opacity: option<float>,
  blurRadius: option<float>,
  offset: option<offsetType>,
  intensity: option<float>,
}

type shapes = {
  borderRadius: option<float>,
  borderWidth: option<float>,
  shadow: option<shadowConfig>, // IOS Specific
}

type font = {
  family: option<fontFamilyTypes>,
  scale: option<float>,
  headingTextSizeAdjust: option<float>,
  subHeadingTextSizeAdjust: option<float>,
  placeholderTextSizeAdjust: option<float>,
  buttonTextSizeAdjust: option<float>,
  errorTextSizeAdjust: option<float>,
  linkTextSizeAdjust: option<float>,
  modalTextSizeAdjust: option<float>,
  cardTextSizeAdjust: option<float>,
}

type primaryButtonColor = {
  background: option<string>,
  text: option<string>,
  border: option<string>,
}
type primaryButtonColorType = {light: option<primaryButtonColor>, dark: option<primaryButtonColor>}

type primaryButton = {
  shapes: option<shapes>,
  primaryButtonColor: option<primaryButtonColorType>,
  height: option<float>,
}

type themeType =
  Default | Light | Dark | Minimal | FlatMinimal | Brutal | Glass | Skeu | Clay | Charcoal | Soft

type logoColors = {
  backgroundColor: ReactNative.Color.t,
  selected?: ReactNative.Color.t,
  unselected?: ReactNative.Color.t,
}
type logoThemeBasedColors = {light: option<logoColors>, dark: option<logoColors>}

type checkedIconColors = {
  color?: ReactNative.Color.t,
  stroke?: ReactNative.Color.t,
}
type checkedIconThemeBasedColors = {
  light: option<checkedIconColors>,
  dark: option<checkedIconColors>,
}
type checkedIconConfig = {
  colors: option<checkedIconThemeBasedColors>,
  size?: float,
  bottom?: float,
  right?: float,
}

type logoConfig = {
  borderRadius: option<float>,
  colors: option<logoThemeBasedColors>,
  checkedIconForSelection: option<checkedIconConfig>,
}

type appearance = {
  theme: themeType,
  colors: option<colorType>,
  shapes: option<shapes>,
  font: option<font>,
  primaryButton: option<primaryButton>,
  logo: option<logoConfig>,
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
  cardNumber: option<string>,
  expiryDate: option<string>,
  cvv: option<string>,
}

type googlePayButtonType = BUY | BOOK | CHECKOUT | DONATE | ORDER | PAY | SUBSCRIBE | PLAIN
type googlePayThemeBaseStyle = {light: ReactNative.Appearance.t, dark: ReactNative.Appearance.t}
type googlePayConfiguration = {
  visibility: LayoutTypes.visibility,
  buttonType: googlePayButtonType,
  buttonStyle: option<googlePayThemeBaseStyle>,
}

type applePayButtonType = [
  | #buy
  | #setUp
  | #inStore
  | #donate
  | #checkout
  | #book
  | #subscribe
  | #plain
]
type applePayButtonStyle = [#white | #whiteOutline | #black]
type applePayThemeBaseStyle = {light: applePayButtonStyle, dark: applePayButtonStyle}
type applePayConfiguration = {
  visibility: LayoutTypes.visibility,
  buttonType: applePayButtonType,
  buttonStyle: option<applePayThemeBaseStyle>,
}

type payPalButtonType = PAYPAL | CHECKOUT | BUY_NOW | PAY
type payPalButtonStyle = GOLD | BLUE | WHITE | BLACK | SILVER
type payPalThemeBaseStyle = {light: payPalButtonStyle, dark: payPalButtonStyle}
type payPalConfiguration = {
  visibility: LayoutTypes.visibility,
  buttonType: payPalButtonType,
  buttonStyle: option<payPalThemeBaseStyle>,
}

type walletButtonsConfiguration = {
  googlePay: googlePayConfiguration,
  applePay: applePayConfiguration,
  payPal: payPalConfiguration,
}

type displayMode = [#default_sdk_message | #custom_message | #hidden]
type customMessage = {value: option<string>, displayMode: displayMode}
type paymentMethodConfig = {paymentMethod: string, message: customMessage}

type configurationType = {
  appearance: appearance,
  merchantDisplayName: string,
  allowsDelayedPaymentMethods: bool,
  allowsPaymentMethodsRequiringShippingAddress: bool,
  displaySavedPaymentMethodsCheckbox: bool,
  hideCardNicknameField: bool,
  displaySavedPaymentMethods: bool,
  displayDefaultSavedPaymentIcon: bool,
  displayPayButton: bool,
  stickyPayButton: bool,
  disableBranding: bool,
  preloadCardElement: bool,
  primaryButtonLabel: option<string>,
  paymentSheetHeaderLabel: option<string>,
  savedPaymentSheetHeaderLabel: option<string>,
  netceteraSDKApiKey: option<string>,
  locale: option<LocaleDataType.localeTypes>,
  subscribedEvents: array<PaymentEventTypes.events>,
  customer: option<customerConfiguration>,
  placeholder: placeholder,
  billingDetails: option<addressDetails>,
  shippingDetails: option<addressDetails>,
  walletButtons: walletButtonsConfiguration,
  redirectionInfo: LayoutTypes.visibility,
  alwaysSendCustomerAcceptance: bool,
  paymentMethodsConfig: array<paymentMethodConfig>,
  opensCardScannerAutomatically: bool,
  paymentMethodOrder: array<string>,
  paymentMethodLayout: LayoutTypes.layout,
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
  | CvcWidget
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
  | CvcWidget => "CVC_WIDGET"
  | PaymentMethodsManagement => "PAYMENT_METHODS_MANAGEMENT"
  | Headless => "HEADLESS"
  | NoView => "NO_VIEW"
  }
}

type overrideEndpoints = {
  customBackendEndpoint: option<string>,
  customLoggingEndpoint: option<string>,
  customAssetEndpoint: option<string>,
}

type customEndpointsConfig = {
  overrideEndpoints: option<overrideEndpoints>,
  commonEndpoint: option<string>,
}

let defaultCustomEndpointsConfig: customEndpointsConfig = {
  overrideEndpoints: None,
  commonEndpoint: None,
}

type hyperswitchConfig = {
  publishableKey: string,
  profileId: option<string>,
  environment: GlobalVars.envType,
  customEndpoints: option<customEndpointsConfig>,
}

type paymentSessionConfig = {
  clientSecret: string,
  sdkAuthorization: option<string>,
  paymentId: string,
}

type insets = {
  bottom: option<float>,
  top: option<float>,
  left: option<float>,
  right: option<float>,
}

type sdkParams = {
  sessionId: string,
  sdkVersion: string,
  confirm: bool,
  appId: option<string>,
  country: string,
  userAgent: option<string>,
  launchTime: option<float>,
  device_model: option<string>,
  os_type: option<string>,
  os_version: option<string>,
  deviceBrand: option<string>,
  insets: option<insets>,
}

type nativeProp = {
  rootTag: int,
  sdkState: sdkState,
  hyperswitchConfig: hyperswitchConfig,
  paymentSessionConfig: paymentSessionConfig,
  sdkParams: sdkParams,
  configuration: configurationType,
}

let defaultAppearance: appearance = {
  theme: Default,
  colors: Some({
    light: None,
    dark: None,
  }),
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
    primaryButtonColor: Some({
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
    height: None,
  }),
  logo: None,
}

let parseColorDict = (d: Dict.t<JSON.t>): colors => {
  primary: getOptionString(d, "primary"),
  background: getOptionString(d, "background"),
  componentBackground: getOptionString(d, "componentBackground"),
  componentBorder: getOptionString(d, "componentBorder"),
  componentDivider: getOptionString(d, "componentDivider"),
  componentText: getOptionString(d, "componentText"),
  primaryText: getOptionString(d, "primaryText"),
  secondaryText: getOptionString(d, "secondaryText"),
  placeholderText: getOptionString(d, "placeholderText"),
  icon: getOptionString(d, "icon"),
  error: getOptionString(d, "error"),
  loaderBackground: getOptionString(d, "loaderBackground"),
  loaderForeground: getOptionString(d, "loaderForeground"),
  selectedComponentBackground: getOptionString(d, "selectedComponentBackground"),
  selectedComponentBorder: getOptionString(d, "selectedComponentBorder"),
  selectedComponentBorderWidth: getOptionFloat(d, "selectedComponentBorderWidth"),
  selectedComponentDivider: getOptionString(d, "selectedComponentDivider"),
  selectedComponentText: getOptionString(d, "selectedComponentText"),
}

let parseShadowDict = (d: Dict.t<JSON.t>): shadowConfig => {
  let offsetDict = getOptionalObj(d, "offset")->Option.getOr(Dict.make())
  {
    color: getOptionString(d, "color"),
    opacity: getOptionFloat(d, "opacity"),
    blurRadius: getOptionFloat(d, "blurRadius"),
    offset: Some({
      x: getOptionFloat(offsetDict, "x"),
      y: getOptionFloat(offsetDict, "y"),
    }),
    intensity: getOptionFloat(d, "intensity"),
  }
}

let parseShapesDict = (d: Dict.t<JSON.t>): shapes => {
  borderRadius: getOptionFloat(d, "borderRadius"),
  borderWidth: getOptionFloat(d, "borderWidth"),
  shadow: getOptionalObj(d, "shadow")->Option.map(parseShadowDict),
}

let parsePrimaryButtonColorDict = (d: Dict.t<JSON.t>): primaryButtonColor => {
  background: getOptionString(d, "background"),
  text: getOptionString(d, "text"),
  border: getOptionString(d, "border"),
}

let parseAppearance = (d: Dict.t<JSON.t>): appearance => {
  let colorsDict = getOptionalObj(d, "colors")->Option.getOr(Dict.make())
  let lightDict = getOptionalObj(colorsDict, "light")
  let darkDict = getOptionalObj(colorsDict, "dark")

  let fontDict = getOptionalObj(d, "font")->Option.getOr(Dict.make())
  let shapesDict = getOptionalObj(d, "shapes")->Option.getOr(Dict.make())
  let primaryButtonDict = getOptionalObj(d, "primaryButton")->Option.getOr(Dict.make())
  let primaryButtonShapesDict =
    getOptionalObj(primaryButtonDict, "shapes")->Option.getOr(Dict.make())
  let primaryButtonColorsDict =
    getOptionalObj(primaryButtonDict, "colors")->Option.getOr(Dict.make())
  let pbLightDict = getOptionalObj(primaryButtonColorsDict, "light")
  let pbDarkDict = getOptionalObj(primaryButtonColorsDict, "dark")

  {
    theme: switch getString(d, "theme", "") {
    | "Light" => Light
    | "Dark" => Dark
    | "Minimal" => Minimal
    | "FlatMinimal" => FlatMinimal
    | "Brutal" => Brutal
    | "Glass" => Glass
    | "Skeu" => Skeu
    | "Clay" => Clay
    | "Charcoal" => Charcoal
    | "Soft" => Soft
    | _ => Default
    },
    colors: Some({
      light: Some(parseColorDict(lightDict->Option.getOr(Dict.make()))),
      dark: Some(parseColorDict(darkDict->Option.getOr(Dict.make()))),
    }),
    shapes: Some(parseShapesDict(shapesDict)),
    font: Some({
      family: switch getOptionString(fontDict, "family") {
      | Some(str) => Some(CustomFont(str))
      | None =>
        Some(
          switch ReactNative.Platform.os {
          | #ios => DefaultIOS
          | #android => DefaultAndroid
          | _ => DefaultWeb
          },
        )
      },
      scale: getOptionFloat(fontDict, "scale"),
      headingTextSizeAdjust: getOptionFloat(fontDict, "headingTextSizeAdjust"),
      subHeadingTextSizeAdjust: getOptionFloat(fontDict, "subHeadingTextSizeAdjust"),
      placeholderTextSizeAdjust: getOptionFloat(fontDict, "placeholderTextSizeAdjust"),
      buttonTextSizeAdjust: getOptionFloat(fontDict, "buttonTextSizeAdjust"),
      errorTextSizeAdjust: getOptionFloat(fontDict, "errorTextSizeAdjust"),
      linkTextSizeAdjust: getOptionFloat(fontDict, "linkTextSizeAdjust"),
      modalTextSizeAdjust: getOptionFloat(fontDict, "modalTextSizeAdjust"),
      cardTextSizeAdjust: getOptionFloat(fontDict, "cardTextSizeAdjust"),
    }),
    primaryButton: Some({
      shapes: Some(parseShapesDict(primaryButtonShapesDict)),
      primaryButtonColor: Some({
        light: Some(parsePrimaryButtonColorDict(pbLightDict->Option.getOr(Dict.make()))),
        dark: Some(parsePrimaryButtonColorDict(pbDarkDict->Option.getOr(Dict.make()))),
      }),
      height: getOptionFloat(primaryButtonDict, "height"),
    }),
    logo: getOptionalObj(d, "logo")->Option.map(logoDict => {
      borderRadius: getOptionFloat(logoDict, "borderRadius"),
      colors: getOptionalObj(logoDict, "colors")->Option.map((colorsDict): logoThemeBasedColors => {
        light: getOptionalObj(colorsDict, "light")->Option.map(
          (l): logoColors => {
            backgroundColor: getString(l, "backgroundColor", "transparent"),
            selected: ?getOptionString(l, "selected"),
            unselected: ?getOptionString(l, "unselected"),
          },
        ),
        dark: getOptionalObj(colorsDict, "dark")->Option.map(
          (l): logoColors => {
            backgroundColor: getString(l, "backgroundColor", "transparent"),
            selected: ?getOptionString(l, "selected"),
            unselected: ?getOptionString(l, "unselected"),
          },
        ),
      }),
      checkedIconForSelection: getOptionalObj(
        logoDict,
        "checkedIconForSelection",
      )->Option.map(iconDict => {
        colors: getOptionalObj(iconDict, "colors")->Option.map(
          (colorsDict): checkedIconThemeBasedColors => {
            light: getOptionalObj(colorsDict, "light")->Option.map(
              (l): checkedIconColors => {
                color: ?getOptionString(l, "color"),
                stroke: ?getOptionString(l, "stroke"),
              },
            ),
            dark: getOptionalObj(colorsDict, "dark")->Option.map(
              (l): checkedIconColors => {
                color: ?getOptionString(l, "color"),
                stroke: ?getOptionString(l, "stroke"),
              },
            ),
          },
        ),
        size: ?getOptionFloat(iconDict, "size"),
        bottom: ?getOptionFloat(iconDict, "bottom"),
        right: ?getOptionFloat(iconDict, "right"),
      }),
    }),
  }
}

let getPrimaryColor = (colors: colorType, ~theme=Default) =>
  switch theme {
  | Dark => colors.dark->Option.flatMap(d => d.primary)
  | _ => colors.light->Option.flatMap(l => l.primary)
  }

let parseAddressDict = d => {
  first_name: ?getOptionString(d, "first_name"),
  last_name: ?getOptionString(d, "last_name"),
  city: ?getOptionString(d, "city"),
  country: ?getOptionString(d, "country"),
  line1: ?getOptionString(d, "line1"),
  line2: ?getOptionString(d, "line2"),
  zip: ?getOptionString(d, "postalCode"),
  state: ?getOptionString(d, "state"),
}

let parsePhoneDict = d => {
  number: ?getOptionString(d, "number"),
  country_code: ?getOptionString(d, "code"),
}

let parseAddressDetails = (d: Dict.t<JSON.t>): option<addressDetails> => {
  let address = getOptionalObj(d, "address")->Option.map(parseAddressDict)
  let phone = getOptionalObj(d, "phone")->Option.map(parsePhoneDict)
  let email = getOptionString(d, "email")
  address === None && phone === None && email === None ? None : Some({address, phone, email})
}

let parseConfigurationDict = (configObj: Dict.t<JSON.t>, displayPayButton) => {
  let appearance =
    configObj
    ->Dict.get("appearance")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.mapOr(defaultAppearance, parseAppearance)

  let placeholderDict =
    configObj
    ->Dict.get("placeholder")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.getOr(Dict.make())

  let walletButtonsDict = getObj(configObj, "walletButtonsConfiguration", Dict.make())
  let googlePayDict = getObj(walletButtonsDict, "googlePay", Dict.make())
  let applePayDict = getObj(walletButtonsDict, "applePay", Dict.make())
  let payPalDict = getObj(walletButtonsDict, "payPal", Dict.make())

  {
    appearance,
    merchantDisplayName: getString(configObj, "merchantDisplayName", ""),
    allowsDelayedPaymentMethods: getBool(configObj, "allowsDelayedPaymentMethods", false),
    allowsPaymentMethodsRequiringShippingAddress: getBool(
      configObj,
      "allowsPaymentMethodsRequiringShippingAddress",
      false,
    ),
    displaySavedPaymentMethodsCheckbox: getBool(
      configObj,
      "displaySavedPaymentMethodsCheckbox",
      true,
    ),
    hideCardNicknameField: getBool(configObj, "hideCardNicknameField", false),
    displaySavedPaymentMethods: getBool(configObj, "displaySavedPaymentMethods", true),
    displayDefaultSavedPaymentIcon: getBool(configObj, "displayDefaultSavedPaymentIcon", true),
    displayPayButton: getBool(configObj, "displayPayButton", displayPayButton),
    stickyPayButton: getBool(configObj, "stickyPayButton", false),
    disableBranding: getBool(configObj, "disableBranding", false),
    preloadCardElement: getBool(configObj, "preloadCardElement", false),
    primaryButtonLabel: getOptionString(configObj, "primaryButtonLabel"),
    paymentSheetHeaderLabel: getOptionString(configObj, "paymentSheetHeaderLabel"),
    savedPaymentSheetHeaderLabel: getOptionString(configObj, "savedPaymentSheetHeaderLabel"),
    netceteraSDKApiKey: getOptionString(configObj, "netceteraSDKApiKey"),
    locale: switch getOptionString(configObj, "locale") {
    | Some(str) => LocaleDataType.localeStringToType(str)
    | None => Some(En)
    },
    subscribedEvents: configObj
    ->Dict.get("subscribedEvents")
    ->Option.flatMap(JSON.Decode.array)
    ->Option.getOr([])
    ->Array.map(e => e->JSON.Decode.string->Option.getOr("")->PaymentEventTypes.eventFromString),
    customer: configObj
    ->Dict.get("customer")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.map(d => {
      id: getOptionString(d, "id"),
      ephemeralKeySecret: getOptionString(d, "ephemeralKeySecret"),
    }),
    placeholder: {
      cardNumber: getOptionString(placeholderDict, "cardNumber"),
      expiryDate: getOptionString(placeholderDict, "expiryDate"),
      cvv: getOptionString(placeholderDict, "cvv"),
    },
    billingDetails: configObj
    ->Dict.get("billingDetails")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.flatMap(parseAddressDetails),
    shippingDetails: configObj
    ->Dict.get("shippingDetails")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.flatMap(parseAddressDetails),
    walletButtons: {
      googlePay: {
        visibility: switch getString(googlePayDict, "visibility", "") {
        | "hidden" => Hidden
        | _ => Shown
        },
        buttonType: switch getString(googlePayDict, "buttonType", "") {
        | "BUY" => BUY
        | "BOOK" => BOOK
        | "CHECKOUT" => CHECKOUT
        | "DONATE" => DONATE
        | "ORDER" => ORDER
        | "PAY" => PAY
        | "SUBSCRIBE" => SUBSCRIBE
        | _ => PLAIN
        },
        buttonStyle: getOptionalObj(googlePayDict, "buttonStyle")->Option.map((
          s
        ): googlePayThemeBaseStyle => {
          light: switch getString(s, "light", "") {
          | "light" => #light
          | _ => #dark
          },
          dark: switch getString(s, "dark", "") {
          | "dark" => #dark
          | _ => #light
          },
        }),
      },
      applePay: {
        visibility: switch getString(applePayDict, "visibility", "") {
        | "hidden" => Hidden
        | _ => Shown
        },
        buttonType: switch getString(applePayDict, "buttonType", "") {
        | "buy" => #buy
        | "setUp" => #setUp
        | "inStore" => #inStore
        | "donate" => #donate
        | "checkout" => #checkout
        | "book" => #book
        | "subscribe" => #subscribe
        | _ => #plain
        },
        buttonStyle: getOptionalObj(applePayDict, "buttonStyle")->Option.map((
          s
        ): applePayThemeBaseStyle => {
          light: switch getString(s, "light", "") {
          | "white" => #white
          | "whiteOutline" => #whiteOutline
          | _ => #black
          },
          dark: switch getString(s, "dark", "") {
          | "black" => #black
          | "whiteOutline" => #whiteOutline
          | _ => #white
          },
        }),
      },
      payPal: {
        visibility: switch getString(payPalDict, "visibility", "") {
        | "hidden" => Hidden
        | _ => Shown
        },
        buttonType: switch getString(payPalDict, "buttonType", "") {
        | "checkout" => CHECKOUT
        | "buynow" => BUY_NOW
        | "pay" => PAY
        | _ => PAYPAL
        },
        buttonStyle: getOptionalObj(payPalDict, "buttonStyle")->Option.map(s => {
          let payPalThemeBaseStyle: payPalThemeBaseStyle = {
            light: switch getString(s, "light", "") {
            | "blue" => BLUE
            | "white" => WHITE
            | "black" => BLACK
            | "silver" => SILVER
            | _ => GOLD
            },
            dark: switch getString(s, "dark", "") {
            | "gold" => GOLD
            | "white" => WHITE
            | "black" => BLACK
            | "silver" => SILVER
            | _ => WHITE
            },
          }
          payPalThemeBaseStyle
        }),
      },
    },
    redirectionInfo: switch getString(configObj, "redirectionInfo", "shown") {
    | "shown" => Shown
    | _ => Hidden
    },
    alwaysSendCustomerAcceptance: getBool(configObj, "alwaysSendCustomerAcceptance", false),
    paymentMethodsConfig: configObj
    ->Dict.get("paymentMethodsConfig")
    ->Option.flatMap(JSON.Decode.array)
    ->Option.getOr([])
    ->Array.filterMap(item =>
      item
      ->JSON.Decode.object
      ->Option.map(obj => {
        paymentMethod: getString(obj, "paymentMethod", ""),
        message: switch getOptionString(obj, "message") {
        | Some(str) => {value: Some(str), displayMode: #custom_message}
        | None => {value: None, displayMode: #default_sdk_message}
        },
      })
    ),
    opensCardScannerAutomatically: getBool(configObj, "opensCardScannerAutomatically", false),
    paymentMethodOrder: configObj
    ->Dict.get("paymentMethodOrder")
    ->Option.flatMap(JSON.Decode.array)
    ->Option.getOr([])
    ->Array.filterMap(JSON.Decode.string)
    ->Array.toReversed,
    paymentMethodLayout: LayoutTypes.parseLayout(configObj),
  }
}

let parseSdkState = str =>
  switch str {
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
  | "cvcWidget" => CvcWidget
  | "headless" => Headless
  | _ => NoView
  }

let parseEndpointsConfig = (d: Dict.t<JSON.t>): option<customEndpointsConfig> => {
  let overrideEndpointsObj = getOptionalObj(d, "overrideEndpoints")
  let overrideEndpoints = overrideEndpointsObj->Option.map(obj => {
    customBackendEndpoint: getOptionString(obj, "customBackendEndpoint"),
    customLoggingEndpoint: getOptionString(obj, "customLoggingEndpoint"),
    customAssetEndpoint: getOptionString(obj, "customAssetEndpoint"),
  })

  let commonEndpoint = getOptionString(d, "commonEndpoint")

  switch (commonEndpoint, overrideEndpoints) {
  | (Some(endpoint), None) => Some({overrideEndpoints: None, commonEndpoint: Some(endpoint)})
  | (None, Some(endpoints)) => Some({overrideEndpoints: Some(endpoints), commonEndpoint: None})
  | (Some(endpoint), Some(endpoints)) =>
    Some({overrideEndpoints: Some(endpoints), commonEndpoint: Some(endpoint)})
  | _ => None
  }
}

let nativeJsonToRecord = (jsonFromNative, rootTag) => {
  let d = jsonFromNative->JSON.Decode.object->Option.getOr(Dict.make())

  let hc = getObj(d, "hyperswitchConfig", Dict.make())
  let ps = getObj(d, "paymentSessionConfig", Dict.make())
  let sp = getObj(d, "sdkParams", Dict.make())

  let clientSecret = getString(ps, "clientSecret", "")
  let sdkAuthorization = switch getOptionString(ps, "sdkAuthorization") {
  | Some("") | None => None
  | v => v
  }
  let paymentId = switch sdkAuthorization {
  | Some(auth) =>
    Utils.getSdkAuthorizationData(auth).paymentId->Option.getOr(
      clientSecret->String.split("_secret_")->Array.get(0)->Option.getOr(""),
    )
  | None => clientSecret->String.split("_secret_")->Array.get(0)->Option.getOr("")
  }

  {
    rootTag,
    sdkState: getString(d, "type", "")->parseSdkState,
    hyperswitchConfig: {
      publishableKey: getString(hc, "publishableKey", ""),
      profileId: getOptionString(hc, "profileId"),
      environment: GlobalVars.checkEnv(getString(hc, "publishableKey", "")),
      customEndpoints: parseEndpointsConfig(getObj(hc, "customEndpoints", Dict.make())),
    },
    paymentSessionConfig: {
      clientSecret,
      sdkAuthorization,
      paymentId,
    },
    sdkParams: {
      sessionId: getString(sp, "sessionId", ""),
      sdkVersion: getString(sp, "sdkVersion", ""),
      confirm: getBool(sp, "confirm", false),
      appId: getOptionString(sp, "appId"),
      country: switch getOptionString(sp, "country") {
      | Some("") | None => defaultCountry
      | Some(c) => c
      },
      userAgent: getOptionString(sp, "user-agent"),
      launchTime: getOptionFloat(sp, "launchTime"),
      device_model: getOptionString(sp, "device_model"),
      os_type: getOptionString(sp, "os_type"),
      os_version: getOptionString(sp, "os_version"),
      deviceBrand: getOptionString(sp, "deviceBrand"),
      insets: Some({
        bottom: getOptionFloat(sp, "bottomInset"),
        top: getOptionFloat(sp, "topInset"),
        left: getOptionFloat(sp, "leftInset"),
        right: getOptionFloat(sp, "rightInset"),
      }),
    },
    configuration: parseConfigurationDict(
      getObj(d, "configuration", Dict.make()),
      getString(d, "type", "")->parseSdkState === PaymentSheet,
    ),
  }
}
