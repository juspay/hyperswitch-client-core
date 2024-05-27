open Utils

type localeTypes =
  | En
  | He
  | Fr
  | En_GB
  | Ar
  | Ja
  | De
  | Fr_BE
  | Es
  | Ca
  | Pt
  | It
  | Pl
  | Nl
  | NI_BE
  | Sv
  | Ru
  | Lt
  | Cs
  | Sk
  | Ls
  | Cy
  | El
  | Et
  | Fi
  | Nb
  | Bs
  | Da
  | Ms
  | Tr_CY

type fontFamilyTypes = DefaultIOS | DefaultAndroid | CustomFont(string) | DefaultWeb

type payment_method_type_wallet = GOOGLE_PAY | APPLE_PAY | PAYPAL | NONE | KLARNA
let walletNameMapper = str => {
  switch str {
  | "google_pay" => "Google Pay"
  | "apple_pay" => "Apple Pay"
  | "paypal" => "Paypal"
  | _ => ""
  }
}

let walletNameToTypeMapper = str => {
  switch str {
  | "Google Pay" => GOOGLE_PAY
  | "Apple Pay" => APPLE_PAY
  | "Paypal" => PAYPAL
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
  mandate_id?: string,
  nick_name?: string,
  isDefaultPaymentMethod?: bool,
  requiresCVV: bool,
}

type savedWallet = {
  payment_method_type?: string,
  walletType?: string,
  payment_token?: string,
  isDefaultPaymentMethod?: bool,
}

type savedDataType =
  | SAVEDLISTCARD(savedCard)
  | SAVEDLISTWALLET(savedWallet)
  | NONE

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
}

type defaultColors = {light: option<colors>, dark: option<colors>}
type colorType =
  | Colors(colors)
  | DefaultColors(defaultColors)

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
  headingTextSizeAdjust:option<float>,
  subHeadingTextSizeAdjust:option<float>,
  placeholderTextSizeAdjust:option<float>,
  buttonTextSizeAdjust:option<float>,
  errorTextSizeAdjust:option<float>,
  linkTextSizeAdjust:option<float>,
  modalTextSizeAdjust:option<float>,
  cardTextSizeAdjust:option<float>,
}

type primaryButtonColor = {
  background: option<string>,
  text: option<string>,
  border: option<string>,
}
type primaryButtonColorType =
  | PrimaryButtonColor(option<primaryButtonColor>)
  | PrimaryButtonDefault({light: option<primaryButtonColor>, dark: option<primaryButtonColor>})

type primaryButton = {
  shapes: option<shapes>,
  primaryButtonColor: option<primaryButtonColorType>,
}

type appearance = {
  locale: option<localeTypes>,
  colors: option<colorType>,
  shapes: option<shapes>,
  font: option<font>,
  primaryButton: option<primaryButton>,
}

type address = {
  first_name: option<string>,
  last_name: option<string>,
  city: option<string>,
  country: option<string>,
  line1: option<string>,
  line2: option<string>,
  zip: option<string>,
  state: option<string>,
}

type phone = {
  number: option<string>,
  country_code: option<string>,
}

type addressDetails = {
  address: option<address>,
  email: option<string>,
  name: option<string>,
  phone: option<phone>,
}

type customerConfiguration = {
  id: option<string>,
  ephemeralKeySecret: option<string>,
}
type googlePayConfiguration = {
  environment: string,
  countryCode: string,
  currencyCode: option<string>,
}

type placeholder = {
  cardNumber: string,
  expiryDate: string,
  cvv: string,
}

type configurationType = {
  allowsDelayedPaymentMethods: bool,
  appearance: option<appearance>,
  shippingDetails: option<addressDetails>,
  primaryButtonLabel: option<string>,
  paymentSheetHeaderText: option<string>,
  savedPaymentScreenHeaderText: option<string>,
  // customer: option<customerConfiguration>,
  merchantDisplayName: string,
  defaultBillingDetails: option<addressDetails>,
  primaryButtonColor: option<string>,
  allowsPaymentMethodsRequiringShippingAddress: bool,
  displaySavedPaymentMethodsCheckbox: bool,
  displaySavedPaymentMethods: bool,
  placeholder: placeholder,
  // themes: string,

  // Android Specific
  googlePay: option<googlePayConfiguration>,

  // IOS specific
}

type sdkState =
  | PaymentSheet
  | HostedCheckout
  | CardWidget
  | CustomWidget(payment_method_type_wallet)
  | ExpressCheckoutWidget
  | WidgetPaymentSheet
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
  | _ => ""
  }
}

let sdkStateToStrMapper = sdkState => {
  switch sdkState {
  | PaymentSheet => "PAYMENT_SHEET"
  | HostedCheckout => "HOSTED_CHECKOUT"
  | CardWidget => "CARD_FORM"
  | CustomWidget(str) => str->widgetToStrMapper
  | ExpressCheckoutWidget => "EXPRESS_CHECKOUT_WIDGET"
  | WidgetPaymentSheet => "WIDGET_PAYMENT"
  | Headless => "HEADLESS"
  | NoView => "NO_VIEW"
  }
}

type hyperParams = {
  confirm: bool,
  appId?: string,
  country: string,
  disableBranding: bool,
  ip: option<string>,
  userAgent: option<string>,
  defaultView: bool,
  launchTime?: float,
}

type nativeProp = {
  publishableKey: string,
  clientSecret: string,
  customBackendUrl: option<string>,
  customLogUrl: option<string>,
  sessionId: string,
  from: string,
  configuration: configurationType,
  themes: string,
  env: GlobalVars.envType,
  sdkState: sdkState,
  rootTag: int,
  hyperParams: hyperParams,
  customParams: Dict.t<JSON.t>,
}
let deafultAppearance: appearance = {
  locale: None,
  colors: switch ReactNative.Platform.os {
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
    primaryButtonColor: switch ReactNative.Platform.os {
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
}

let getColorFromDict = (colorDict, keys: NativeSdkPropsKeys.keys) => {
  let x = {
    primary: retOptionalStr(getProp(keys.primary, colorDict)),
    background: retOptionalStr(getProp(keys.background, colorDict)),
    componentBackground: retOptionalStr(getProp(keys.componentBackground, colorDict)),
    componentBorder: retOptionalStr(getProp(keys.componentBorder, colorDict)),
    componentDivider: retOptionalStr(getProp(keys.componentDivider, colorDict)),
    componentText: retOptionalStr(getProp(keys.componentText, colorDict)),
    primaryText: retOptionalStr(getProp(keys.primaryText, colorDict)),
    secondaryText: retOptionalStr(getProp(keys.secondaryText, colorDict)),
    placeholderText: retOptionalStr(getProp(keys.placeholderText, colorDict)),
    icon: retOptionalStr(getProp(keys.icon, colorDict)),
    error: retOptionalStr(getProp(keys.error, colorDict)),
  }

  x
}

let getPrimaryButtonColorFromDict = (primaryButtonColorDict, keys: NativeSdkPropsKeys.keys) => {
  let x = {
    background: retOptionalStr(getProp(keys.primaryButton_background, primaryButtonColorDict)),
    text: retOptionalStr(getProp(keys.primaryButton_text, primaryButtonColorDict)),
    border: retOptionalStr(getProp(keys.primaryButton_border, primaryButtonColorDict)),
  }

  x
}

let getAppearanceObj = (
  appearanceDict: Dict.t<JSON.t>,
  keys: NativeSdkPropsKeys.keys,
  from: string,
) => {
  let fontDict = getObj(appearanceDict, keys.font, Dict.make())
  let primaryButtonDict = getObj(appearanceDict, keys.primaryButton, Dict.make())
  let primaryButtonShapesDict = getObj(primaryButtonDict, keys.primaryButton_shapes, Dict.make())

  {
    locale: switch retOptionalStr(getProp(keys.locale, appearanceDict)) {
    | Some(str) =>
      switch str {
      | "he" => Some(He)
      | "fr" => Some(Fr)
      | "en-GB" => Some(En_GB)
      | "ar" => Some(Ar)
      | "ja" => Some(Ja)
      | "de" => Some(De)
      | "fr-BE" => Some(Fr_BE)
      | "es" => Some(Es)
      | "ca" => Some(Ca)
      | "pt" => Some(Pt)
      | "it" => Some(It)
      | "pl" => Some(Pl)
      | "nl" => Some(Nl)
      | "nI-BE" => Some(NI_BE)
      | "sv" => Some(Sv)
      | "ru" => Some(Ru)
      | "lt" => Some(Lt)
      | "cs" => Some(Cs)
      | "sk" => Some(Sk)
      | "ls" => Some(Ls)
      | "cy" => Some(Cy)
      | "el" => Some(El)
      | "et" => Some(Et)
      | "fi" => Some(Fi)
      | "nb" => Some(Nb)
      | "bs" => Some(Bs)
      | "da" => Some(Da)
      | "ms" => Some(Ms)
      | "tr-CY" => Some(Tr_CY)
      | _ => Some(En)
      }
    | _ => Some(En)
    },
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
      family: switch retOptionalStr(getProp(keys.family, fontDict)) {
      | Some(str) => Some(CustomFont(str))
      | None =>
        switch ReactNative.Platform.os {
        | #ios => DefaultIOS
        | #web => DefaultWeb
        | _ => DefaultAndroid
        }->Some
      },
      scale: retOptionalFloat(getProp(keys.scale, fontDict)),
      headingTextSizeAdjust: retOptionalFloat(getProp(keys.headingTextSizeAdjust,fontDict)),
      subHeadingTextSizeAdjust: retOptionalFloat(getProp(keys.subHeadingTextSizeAdjust,fontDict)),
      placeholderTextSizeAdjust: retOptionalFloat(getProp(keys.placeholderTextSizeAdjust,fontDict)),
      buttonTextSizeAdjust: retOptionalFloat(getProp(keys.buttonTextSizeAdjust,fontDict)),
      errorTextSizeAdjust: retOptionalFloat(getProp(keys.errorTextSizeAdjust,fontDict)),
      linkTextSizeAdjust: retOptionalFloat(getProp(keys.linkTextSizeAdjust,fontDict)),
      modalTextSizeAdjust: retOptionalFloat(getProp(keys.modalTextSizeAdjust,fontDict)),
      cardTextSizeAdjust: retOptionalFloat(getProp(keys.cardTextSizeAdjust,fontDict)),
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
            opacity: retOptionalFloat(getProp(keys.primaryButton_opacity, primaryButtonShadowDict)),
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
                ? PrimaryButtonColor(Some(getPrimaryButtonColorFromDict(primaryButtonColors, keys)))
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
  }
}

let parseConfigurationDict = (configObj, from) => {
  let shippingDetailsDict =
    configObj->Dict.get("shippingDetails")->Option.flatMap(JSON.Decode.object)
  let billingDetailsDict = getObj(configObj, "defaultBillingDetails", Dict.make())

  let _customerDict = configObj->Dict.get("customer")->Option.flatMap(JSON.Decode.object)
  let googlePayDict = configObj->Dict.get("googlePay")->Option.flatMap(JSON.Decode.object)
  let addressDict = getObj(billingDetailsDict, "address", Dict.make())
  let billingName =
    getOptionString(billingDetailsDict, "name")
    ->Option.getOr("default")
    ->String.split(" ")

  let appearanceDict = configObj->Dict.get("appearance")->Option.flatMap(JSON.Decode.object)
  let appearanceObj: option<appearance> = {
    Some(
      from == "rn" || from == "flutter"
        ? switch appearanceDict {
          | Some(appObj) => getAppearanceObj(appObj, NativeSdkPropsKeys.rnKeys, from)
          | None => deafultAppearance
          }
        : switch appearanceDict {
          | Some(appObj) =>
            switch ReactNative.Platform.os {
            | #ios
            | #web =>
              //For Ios
              getAppearanceObj(appObj, NativeSdkPropsKeys.iosKeys, from)
            | #android =>
              // For Android
              getAppearanceObj(appObj, NativeSdkPropsKeys.androidKeys, from)

            | _ => deafultAppearance
            }
          | None => deafultAppearance
          },
    )
  }
  let placeholderDict =
    configObj
    ->Dict.get("placeholder")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.getOr(Dict.make())

  let configuration = {
    allowsDelayedPaymentMethods: getBool(configObj, "allowsDelayedPaymentMethods", false),
    appearance: appearanceObj,
    shippingDetails: switch shippingDetailsDict {
    | Some(shippingObj) =>
      let addressObj = getObj(shippingObj, "address", Dict.make())
      let shippingName =
        getOptionString(shippingObj, "name")
        ->Option.getOr("default")
        ->String.split(" ")
      addressObj == Dict.make()
        ? None
        : Some({
            address: Some({
              first_name: shippingName[0] == Some("default") ? None : shippingName[0],
              last_name: shippingName->Array.length > 1 ? shippingName[1] : None,
              city: getOptionString(addressObj, "city"),
              country: getOptionString(addressObj, "country"),
              line1: getOptionString(addressObj, "line1"),
              line2: getOptionString(addressObj, "line2"),
              zip: getOptionString(addressObj, "postalCode"),
              state: getOptionString(addressObj, "state"),
            }),
            phone: Some({number: getOptionString(shippingObj, "phoneNumber"), country_code: None}),
            //isCheckboxSelected: getOptionBool(shippingObj, "isCheckboxSelected"),
            email: None, //getOptionString(shippingObj, "email"),
            name: None, //getOptionString(shippingObj, "name"),
          })
    | None => None
    },
    primaryButtonLabel: getOptionString(configObj, "primaryButtonLabel"),
    paymentSheetHeaderText: getOptionString(configObj, "paymentSheetHeaderLabel"),
    savedPaymentScreenHeaderText: getOptionString(configObj, "savedPaymentScreenHeaderLabel"),
    // customer: switch customerDict {
    // | Some(obj) =>
    //   Some({
    //     id: getOptionString(obj, "id"),
    //     ephemeralKeySecret: getOptionString(obj, "ephemeralKeySecret"),
    //   })
    // | _ => None
    // },
    merchantDisplayName: getString(configObj, "merchantDisplayName", ""),
    defaultBillingDetails: addressDict == Dict.make()
      ? None
      : Some({
          address: Some({
            first_name: billingName[0] === Some("default") ? None : billingName[0],
            last_name: billingName->Array.length > 1 ? billingName[1] : None,
            city: getOptionString(addressDict, "city"),
            country: getOptionString(addressDict, "country"),
            line1: getOptionString(addressDict, "line1"),
            line2: getOptionString(addressDict, "line2"),
            zip: getOptionString(addressDict, "postalCode"),
            state: getOptionString(addressDict, "state"),
          }),
          phone: Some({
            number: getOptionString(billingDetailsDict, "phoneNumber"),
            country_code: None,
          }),
          email: None, //getOptionString(billingDetailsDict, "email"),
          name: None, // getOptionString(billingDetailsDict, "name"),
        }),
    primaryButtonColor: getOptionString(configObj, "primaryButtonColor"),
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
    displaySavedPaymentMethods: getBool(configObj, "displaySavedPaymentMethods", true),
    // themes: ,
    googlePay: switch googlePayDict {
    | Some(obj) =>
      if from === "rn" || from == "flutter" {
        Some({
          environment: getBool(obj, "testEnv", false) ? "TEST" : "PRODUCTION", // test or production string value will be all capital for gpay
          countryCode: getString(obj, "merchantCountryCode", ""),
          currencyCode: getOptionString(obj, "currencyCode"),
        })
      } else {
        Some({
          environment: getString(obj, "environment", "TEST")->String.toUpperCase, // test or production string value will be all capital for gpay
          countryCode: getString(obj, "countryCode", ""),
          currencyCode: getOptionString(obj, "currencyCode"),
        })
      }
    | _ => None
    },
    placeholder: {
      cardNumber: getString(placeholderDict, "cardNumber", "1234 1234 1234 1234"),
      expiryDate: getString(placeholderDict, "expiryDate", "MM / YY"),
      cvv: getString(placeholderDict, "cvv", "CVV"),
    },
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

  let hyperParams = getObj(dictfromNative, "hyperParams", Dict.make())

  {
    from,
    env: GlobalVars.checkEnv(publishableKey),
    rootTag,
    publishableKey,
    clientSecret: getString(dictfromNative, "clientSecret", ""),
    customBackendUrl,
    customLogUrl,
    sessionId: "",
    sdkState: switch getString(dictfromNative, "type", "") {
    | "payment" => PaymentSheet
    | "hostedCheckout" => HostedCheckout
    | "google_pay" => CustomWidget(GOOGLE_PAY)
    | "paypal" => CustomWidget(PAYPAL)
    | "card" => CardWidget
    | "widgetPayment" => WidgetPaymentSheet
    | "expressCheckout" => ExpressCheckoutWidget
    | "headless" => Headless
    | _ => NoView
    },
    configuration: parseConfigurationDict(configurationDict, from),
    themes: getString(dictfromNative, "themes", ""),
    hyperParams: {
      appId: ?getOptionString(hyperParams, "appId"),
      country: getString(hyperParams, "country", ""),
      disableBranding: getBool(hyperParams, "disableBranding", true),
      ip: getOptionString(hyperParams, "ip"),
      userAgent: getOptionString(hyperParams, "user-agent"),
      defaultView: getBool(hyperParams, "defaultView", false),
      confirm: getBool(hyperParams, "confirm", false),
      launchTime: ?getOptionFloat(hyperParams, "launchTime"),
    },
    customParams: getObj(dictfromNative, "customParams", Dict.make()),
  }
}
