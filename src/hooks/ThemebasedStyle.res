open ReactNative
open Style

type statusColorConfig = {
  textColor: ReactNative.Color.t,
  backgroundColor: ReactNative.Color.t,
}

type componentConfig = {
  background: ReactNative.Color.t,
  borderColor: ReactNative.Color.t,
  dividerColor: ReactNative.Color.t,
  color: ReactNative.Color.t,
}
type statusColor = {
  green: statusColorConfig,
  orange: statusColorConfig,
  red: statusColorConfig,
  blue: statusColorConfig,
}

type maxTextSize = {
  maxHeadingTextSize: float,
  maxSubHeadingTextSize: float,
  maxPlaceholderTextSize: float,
  maxButtonTextSize: float,
  maxErrorTextSize: float,
  maxLinkTextSize: float,
  maxModalTextSize: float,
  maxCardTextSize: float,
}

let getStrProp = (~overRideProp, ~defaultProp) => {
  let x = switch overRideProp {
  | Some(val) => val
  | None => defaultProp
  }
  x
}
let getStyleProp = (~override, ~fn, ~default) => {
  let x = switch override {
  | Some(val) => fn(val)
  | None => default
  }
  x
}

let maxTextSize = {
  maxHeadingTextSize: 10.,
  maxSubHeadingTextSize: 10.,
  maxPlaceholderTextSize: 5.,
  maxButtonTextSize: 15.,
  maxErrorTextSize: 15.,
  maxLinkTextSize: 7.,
  maxModalTextSize: 6.,
  maxCardTextSize: 7.,
}

let status_color = {
  green: {textColor: "#36AF47", backgroundColor: "rgba(54, 175, 71, 0.12)"},
  orange: {textColor: "#CA8601", backgroundColor: "rgba(202, 134, 1, 0.12)"},
  red: {textColor: "#EF6969", backgroundColor: "rgba(239, 105, 105, 0.12)"},
  blue: {textColor: "#0099FF", backgroundColor: "rgba(0, 153, 255, 0.12)"},
}
let styles = {
  StyleSheet.create({
    "light_bgColor": s({backgroundColor: "#ffffff"}),
    "dark_bgColor": s({backgroundColor: "#2e2e2e"}),
    "flatMinimal_bgColor": s({backgroundColor: "rgba(107, 114, 128, 1)"}),
    "minimal_bgColor": s({backgroundColor: "#ffffff"}),
    "light_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.2)}),
    "dark_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.2)}),
    "flatMinimal_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.2)}),
    "minimal_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.2)}),
    "light_textPrimary": s({color: "#0570de"}),
    "dark_textPrimary": s({color: "#FFFFFF"}),
    "flatMinimal_textPrimary": s({color: "#e0e0e0"}),
    "minimal_textPrimary": s({color: "black"}),
    "light_textSecondary": s({color: "#767676"}),
    "dark_textSecondary": s({color: "#F6F8F9"}),
    "flatMinimal_textSeconadry": s({color: "#F6F8FA"}),
    "minimal_textSeconadry": s({color: "blue"}),
    "light_textSecondary_Bold": s({color: "#000000"}),
    "dark_textSecondaryBold": s({color: "#F6F8F9"}),
    "flatMinimal_textSeconadryBold": s({color: "#F6F8FA"}),
    "minimal_textSeconadryBold": s({color: "blue"}),
    "light_textInputBg": s({backgroundColor: "#ffffff"}),
    "dark_textInputBg": s({backgroundColor: "#444444"}),
    "flatMinimal_textInputBg": s({backgroundColor: "black"}),
    "minimal_textInputBg": s({backgroundColor: "white"}),
    "light_boxColor": s({backgroundColor: "#FFFFFF"}),
    "dark_boxColor": s({backgroundColor: "#191A1A"}),
    "flatMinimal_boxColor": s({backgroundColor: "#191A1A"}),
    "minimal_boxColor": s({backgroundColor: "#191A1A"}),
    "light_boxBorderColor": s({borderColor: "#e4e4e5"}),
    "dark_boxBorderColor": s({borderColor: "#79787d"}),
    "flatMinimal_boxBorderColor": s({borderColor: "#3541ff"}),
    "minimal_boxBorderColor": s({borderColor: "#e4e4e5"}),
  })
}

type themeBasedStyleObj = {
  platform: string,
  bgColor: ReactNative.Style.t,
  paymentSheetOverlay: string,
  loadingBgColor: string,
  loadingFgColor: string,
  bgTransparentColor: ReactNative.Style.t,
  textPrimary: ReactNative.Style.t,
  textSecondary: ReactNative.Style.t,
  textSecondaryBold: ReactNative.Style.t,
  placeholderColor: string,
  textInputBg: ReactNative.Style.t,
  iconColor: string,
  lineBorderColor: string,
  linkColor: ReactNative.Color.t,
  disableBgColor: ReactNative.Color.t,
  filterHeaderColor: ReactNative.Color.t,
  filterOptionTextColor: array<ReactNative.Color.t>,
  tooltipTextColor: ReactNative.Color.t,
  tooltipBackgroundColor: ReactNative.Color.t,
  boxColor: ReactNative.Style.t,
  boxBorderColor: ReactNative.Style.t,
  dropDownSelectAll: array<array<ReactNative.Color.t>>,
  fadedColor: array<ReactNative.Color.t>,
  status_color: statusColor,
  detailViewToolTipText: string,
  summarisedViewSingleStatHeading: string,
  switchThumbColor: string,
  shimmerColor: array<string>, //[background color, highlight color]
  lastOffset: string,
  dangerColor: string,
  orderDisableButton: string,
  toastColorConfig: statusColorConfig, // [backrgroundcolor, textColor]
  primaryColor: ReactNative.Color.t,
  borderRadius: float,
  borderWidth: float,
  buttonBorderRadius: float,
  buttonBorderWidth: float,
  component: componentConfig,
  locale: LocaleDataType.localeTypes,
  fontFamily: SdkTypes.fontFamilyTypes,
  fontScale: float,
  headingTextSizeAdjust: float,
  subHeadingTextSizeAdjust: float,
  placeholderTextSizeAdjust: float,
  buttonTextSizeAdjust: float,
  errorTextSizeAdjust: float,
  linkTextSizeAdjust: float,
  modalTextSizeAdjust: float,
  cardTextSizeAdjust: float,
  paypalButonColor: ReactNative.Color.t,
  samsungPayButtonColor: ReactNative.Color.t,
  applePayButtonColor: SdkTypes.applePayButtonStyle,
  googlePayButtonColor: Appearance.t,
  payNowButtonColor: ReactNative.Color.t,
  payNowButtonTextColor: string,
  payNowButtonBorderColor: string,
  payNowButtonShadowColor: string,
  payNowButtonShadowIntensity: float,
  focusedTextInputBoderColor: string,
  errorTextInputColor: string,
  normalTextInputBoderColor: string,
  shadowColor: string,
  shadowIntensity: float,
  primaryButtonHeight: float,
  disclaimerBackgroundColor: string,
  disclaimerTextColor: string,
  instructionalTextColor: string,
  poweredByTextColor: string,
  detailsViewTextKeyColor: string,
  detailsViewTextValueColor: string,
  silverBorderColor: string,
  sheetContentPadding: float,
  errorMessageSpacing: float,
}

let darkRecord = {
  primaryButtonHeight: 45.,
  platform: "android",
  paymentSheetOverlay: "#00000025",
  bgColor: styles["dark_bgColor"],
  loadingBgColor: "#3e3e3e90",
  loadingFgColor: "#2e2e2e",
  bgTransparentColor: styles["dark_bgTransparentColor"],
  textPrimary: styles["dark_textPrimary"],
  textSecondary: styles["dark_textSecondary"],
  textSecondaryBold: styles["dark_textSecondaryBold"],
  placeholderColor: "#F6F8F940",
  textInputBg: styles["dark_textInputBg"],
  iconColor: "rgba(246, 248, 249, 0.25)",
  lineBorderColor: "#2C2D2F",
  linkColor: "#00B0FF",
  disableBgColor: "#202124",
  filterHeaderColor: "rgba(246, 248, 249, 0.75)",
  filterOptionTextColor: ["rgba(246, 248, 249, 0.8)", "#F6F8F9"],
  tooltipTextColor: "#191A1A75",
  tooltipBackgroundColor: "#F7F8FA",
  boxColor: styles["dark_boxColor"],
  boxBorderColor: styles["dark_boxBorderColor"],
  dropDownSelectAll: [["#202124", "#202124", "#202124"], ["#202124", "#202124", "#202124"]],
  fadedColor: ["rgba(0, 0, 0, 0.75)", "rgba(0, 0, 0,1)"],
  status_color,
  detailViewToolTipText: "rgba(25, 26, 26, 0.75)",
  summarisedViewSingleStatHeading: "#F6F8F9",
  switchThumbColor: "#f4f3f4",
  shimmerColor: ["#191A1A", "#232424"],
  lastOffset: "#1B1B1D",
  dangerColor: "#EF6969",
  orderDisableButton: "#F6F8F9",
  toastColorConfig: {
    backgroundColor: "#343434",
    textColor: "#FFFFFF",
  },
  primaryColor: "#0057c7",
  borderRadius: 7.0,
  borderWidth: 1.,
  buttonBorderRadius: 8.0,
  buttonBorderWidth: 0.0,
  component: {
    background: Color.rgb(~r=57, ~g=57, ~b=57),
    borderColor: "#e6e6e650",
    dividerColor: "#e6e6e6",
    color: "#ffffff",
  },
  locale: En,
  fontFamily: switch WebKit.platform {
  | #ios | #iosWebView => DefaultIOS
  | #android | #androidWebView => DefaultAndroid
  | #web | #next => DefaultWeb
  },
  fontScale: 1.,
  headingTextSizeAdjust: 0.,
  subHeadingTextSizeAdjust: 0.,
  placeholderTextSizeAdjust: 0.,
  buttonTextSizeAdjust: 0.,
  errorTextSizeAdjust: 0.,
  linkTextSizeAdjust: 0.,
  modalTextSizeAdjust: 0.,
  cardTextSizeAdjust: 0.,
  paypalButonColor: "#ffffff",
  samsungPayButtonColor: "#000000",
  payNowButtonTextColor: "#fff",
  applePayButtonColor: #white,
  googlePayButtonColor: #light,
  payNowButtonColor: "#0057c7",
  payNowButtonBorderColor: "#e6e6e650",
  payNowButtonShadowColor: "black",
  payNowButtonShadowIntensity: 2.,
  focusedTextInputBoderColor: "#0057c7",
  errorTextInputColor: "rgba(0, 153, 255, 1)",
  normalTextInputBoderColor: "rgba(204, 210, 226, 0.75)",
  shadowColor: "black",
  shadowIntensity: 2.,
  disclaimerBackgroundColor: "#FDF3E0",
  disclaimerTextColor: "#D57F0C",
  instructionalTextColor: "#999999",
  poweredByTextColor: "#111111",
  detailsViewTextKeyColor: "#999999",
  detailsViewTextValueColor: "#333333",
  silverBorderColor: "#CCCCCC",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
}
let lightRecord = {
  primaryButtonHeight: 45.,
  platform: "android",
  paymentSheetOverlay: "#00000070",
  bgColor: styles["light_bgColor"],
  loadingBgColor: "rgb(220,220,220)",
  loadingFgColor: "rgb(250,250,250)",
  bgTransparentColor: styles["light_bgTransparentColor"],
  textPrimary: styles["light_textPrimary"],
  textSecondary: styles["light_textSecondary"],
  textSecondaryBold: styles["light_textSecondary_Bold"],
  placeholderColor: "#00000070",
  textInputBg: styles["light_textInputBg"],
  iconColor: "rgba(53, 64, 82, 0.25)",
  lineBorderColor: "#CCD2E250",
  linkColor: "#006DF9",
  disableBgColor: "#ECECEC",
  filterHeaderColor: "#666666",
  filterOptionTextColor: ["#354052", "rgba(53, 64, 82, 0.8)"],
  tooltipTextColor: "#F6F8F975",
  tooltipBackgroundColor: "#191A1A",
  boxColor: styles["light_boxColor"],
  boxBorderColor: styles["light_boxBorderColor"],
  dropDownSelectAll: [["#E7EAF1", "#E7EAF1", "#E7EAF1"], ["#F1F5FA", "#FDFEFF", "#F1F5FA"]],
  fadedColor: ["#CCCFD450", "rgba(53, 64, 82, 0.5)"],
  status_color,
  detailViewToolTipText: "rgba(246, 248, 249, 0.75)",
  summarisedViewSingleStatHeading: "#354052",
  switchThumbColor: "white",
  shimmerColor: ["#EAEBEE", "#FFFFFF"],
  lastOffset: "#FFFFFF",
  dangerColor: "#FF3434",
  orderDisableButton: "#354052",
  toastColorConfig: {
    backgroundColor: "#2C2D2F",
    textColor: "#F5F7FC",
  },
  primaryColor: "#006DF9",
  borderRadius: 7.0,
  borderWidth: 1.,
  buttonBorderRadius: 8.0,
  buttonBorderWidth: 0.0,
  component: {
    background: "#FFFFFF",
    borderColor: "rgb(226,226,228)",
    dividerColor: "#e6e6e6",
    color: "#000000",
  },
  locale: En,
  fontFamily: switch WebKit.platform {
  | #ios | #iosWebView => DefaultIOS
  | #android | #androidWebView => DefaultAndroid
  | #web | #next => DefaultWeb
  },
  fontScale: 1.,
  headingTextSizeAdjust: 0.,
  subHeadingTextSizeAdjust: 0.,
  placeholderTextSizeAdjust: 0.,
  buttonTextSizeAdjust: 0.,
  errorTextSizeAdjust: 0.,
  linkTextSizeAdjust: 0.,
  modalTextSizeAdjust: 0.,
  cardTextSizeAdjust: 0.,
  paypalButonColor: "#F6C657",
  applePayButtonColor: #black,
  samsungPayButtonColor: "#000000",
  googlePayButtonColor: #dark,
  payNowButtonColor: "#006DF9",
  payNowButtonTextColor: "#FFFFFF",
  payNowButtonBorderColor: "#ffffff",
  payNowButtonShadowColor: "black",
  payNowButtonShadowIntensity: 2.,
  focusedTextInputBoderColor: "#006DF9",
  errorTextInputColor: "rgba(0, 153, 255, 1)",
  normalTextInputBoderColor: "rgba(204, 210, 226, 0.75)",
  shadowColor: "black",
  shadowIntensity: 2.,
  disclaimerBackgroundColor: "#FDF3E0",
  disclaimerTextColor: "#D57F0C",
  instructionalTextColor: "#999999",
  poweredByTextColor: "#111111",
  detailsViewTextKeyColor: "#999999",
  detailsViewTextValueColor: "#333333",
  silverBorderColor: "#CCCCCC",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
}

let minimal = {
  primaryButtonHeight: 45.,
  platform: "android",
  paymentSheetOverlay: "#00000025",
  bgColor: styles["light_bgColor"],
  loadingBgColor: "rgb(244,244,244)",
  loadingFgColor: "rgb(250,250,250)",
  bgTransparentColor: styles["light_bgTransparentColor"],
  textPrimary: styles["light_textPrimary"],
  textSecondary: styles["light_textSecondary"],
  textSecondaryBold: styles["light_textSecondary_Bold"],
  placeholderColor: "#00000070",
  textInputBg: styles["light_textInputBg"],
  iconColor: "rgba(53, 64, 82, 0.25)",
  lineBorderColor: "#CCD2E250",
  linkColor: "#006DF9",
  disableBgColor: "#ECECEC",
  filterHeaderColor: "#666666",
  filterOptionTextColor: ["#354052", "rgba(53, 64, 82, 0.8)"],
  tooltipTextColor: "#F6F8F975",
  tooltipBackgroundColor: "#191A1A",
  boxColor: styles["light_boxColor"],
  boxBorderColor: styles["light_boxBorderColor"],
  dropDownSelectAll: [["#E7EAF1", "#E7EAF1", "#E7EAF1"], ["#F1F5FA", "#FDFEFF", "#F1F5FA"]],
  fadedColor: ["#CCCFD450", "rgba(53, 64, 82, 0.5)"],
  status_color,
  detailViewToolTipText: "rgba(246, 248, 249, 0.75)",
  summarisedViewSingleStatHeading: "#354052",
  switchThumbColor: "white",
  shimmerColor: ["#EAEBEE", "#FFFFFF"],
  lastOffset: "#FFFFFF",
  dangerColor: "#FF3434",
  orderDisableButton: "#354052",
  toastColorConfig: {
    backgroundColor: "#2C2D2F",
    textColor: "#F5F7FC",
  },
  primaryColor: "#0570de",
  borderRadius: 7.0,
  borderWidth: 0.5,
  buttonBorderRadius: 8.0,
  buttonBorderWidth: 0.5,
  component: {
    background: "#ffffff",
    borderColor: "#e6e6e6",
    dividerColor: "#e6e6e6",
    color: "#000000",
  },
  locale: En,
  fontFamily: switch WebKit.platform {
  | #ios | #iosWebView => DefaultIOS
  | #android | #androidWebView => DefaultAndroid
  | #web | #next => DefaultWeb
  },
  fontScale: 1.,
  headingTextSizeAdjust: 0.,
  subHeadingTextSizeAdjust: 0.,
  placeholderTextSizeAdjust: 0.,
  buttonTextSizeAdjust: 0.,
  errorTextSizeAdjust: 0.,
  linkTextSizeAdjust: 0.,
  modalTextSizeAdjust: 0.,
  cardTextSizeAdjust: 0.,
  paypalButonColor: "#ffc439",
  samsungPayButtonColor: "#000000",
  applePayButtonColor: #black,
  googlePayButtonColor: #dark,
  payNowButtonColor: "#0570de",
  payNowButtonTextColor: "#FFFFFF",
  payNowButtonBorderColor: "#ffffff",
  payNowButtonShadowColor: "black",
  payNowButtonShadowIntensity: 3.,
  focusedTextInputBoderColor: "rgba(0, 153, 255, 1)",
  errorTextInputColor: "rgba(0, 153, 255, 1)",
  normalTextInputBoderColor: "rgba(204, 210, 226, 0.75)",
  shadowColor: "black",
  shadowIntensity: 3.,
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  disclaimerBackgroundColor: "#FDF3E0",
  disclaimerTextColor: "#D57F0C",
  instructionalTextColor: "#999999",
  poweredByTextColor: "#111111",
  detailsViewTextKeyColor: "#999999",
  detailsViewTextValueColor: "#333333",
  silverBorderColor: "#CCCCCC",
}

let flatMinimal = {
  primaryButtonHeight: 45.,
  platform: "android",
  paymentSheetOverlay: "#00000025",
  bgColor: styles["flatMinimal_bgColor"],
  loadingBgColor: "rgb(244,244,244)",
  loadingFgColor: "rgb(250,250,250)",
  bgTransparentColor: styles["light_bgTransparentColor"],
  textPrimary: styles["flatMinimal_textPrimary"],
  textSecondary: styles["flatMinimal_textSeconadry"],
  textSecondaryBold: styles["flatMinimal_textSeconadryBold"],
  placeholderColor: "#00000070",
  textInputBg: styles["light_textInputBg"],
  iconColor: "rgba(53, 64, 82, 0.25)",
  lineBorderColor: "#CCD2E250",
  linkColor: "#006DF9",
  disableBgColor: "#ECECEC",
  filterHeaderColor: "#666666",
  filterOptionTextColor: ["#354052", "rgba(53, 64, 82, 0.8)"],
  tooltipTextColor: "#F6F8F975",
  tooltipBackgroundColor: "#191A1A",
  boxColor: styles["light_boxColor"],
  boxBorderColor: styles["light_boxBorderColor"],
  dropDownSelectAll: [["#E7EAF1", "#E7EAF1", "#E7EAF1"], ["#F1F5FA", "#FDFEFF", "#F1F5FA"]],
  fadedColor: ["#CCCFD450", "rgba(53, 64, 82, 0.5)"],
  status_color,
  detailViewToolTipText: "rgba(246, 248, 249, 0.75)",
  summarisedViewSingleStatHeading: "#354052",
  switchThumbColor: "white",
  shimmerColor: ["#EAEBEE", "#FFFFFF"],
  lastOffset: "#FFFFFF",
  dangerColor: "#fd1717",
  orderDisableButton: "#354052",
  toastColorConfig: {
    backgroundColor: "#2C2D2F",
    textColor: "#F5F7FC",
  },
  primaryColor: "#3541ff",
  borderRadius: 7.0,
  borderWidth: 0.5,
  buttonBorderRadius: 8.0,
  buttonBorderWidth: 0.5,
  component: {
    background: "#ffffff",
    borderColor: "#566186",
    dividerColor: "#e6e6e6",
    color: "#30313d",
  },
  locale: En,
  fontFamily: switch WebKit.platform {
  | #ios | #iosWebView => DefaultIOS
  | #android | #androidWebView => DefaultAndroid
  | #web | #next => DefaultWeb
  },
  fontScale: 1.,
  headingTextSizeAdjust: 0.,
  subHeadingTextSizeAdjust: 0.,
  placeholderTextSizeAdjust: 0.,
  buttonTextSizeAdjust: 0.,
  errorTextSizeAdjust: 0.,
  linkTextSizeAdjust: 0.,
  modalTextSizeAdjust: 0.,
  cardTextSizeAdjust: 0.,
  paypalButonColor: "#ffc439",
  applePayButtonColor: #black,
  googlePayButtonColor: #dark,
  samsungPayButtonColor: "#000000",
  payNowButtonColor: "#0570de",
  payNowButtonTextColor: "#000000",
  payNowButtonBorderColor: "#000000",
  payNowButtonShadowColor: "black",
  payNowButtonShadowIntensity: 3.,
  focusedTextInputBoderColor: "rgba(0, 153, 255, 1)",
  errorTextInputColor: "rgba(0, 153, 255, 1)",
  normalTextInputBoderColor: "rgba(204, 210, 226, 0.75)",
  shadowColor: "black",
  shadowIntensity: 3.,
  disclaimerBackgroundColor: "#FDF3E0",
  disclaimerTextColor: "#D57F0C",
  instructionalTextColor: "#999999",
  poweredByTextColor: "#111111",
  detailsViewTextKeyColor: "#999999",
  detailsViewTextValueColor: "#333333",
  silverBorderColor: "#CCCCCC",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
}

let some = (~override, ~fn, ~default) => {
  switch override {
  | Some(val) => fn(val)
  | None => default
  }
}
let itemToObj = (
  themeObj: themeBasedStyleObj,
  appearance: SdkTypes.appearance,
  isDarkMode: bool,
) => {
  let appearanceColor: option<SdkTypes.colors> = switch appearance.colors {
  | Some(Colors(obj)) => Some(obj)
  | Some(DefaultColors({light, dark})) => isDarkMode ? dark : light
  | None => None
  }
  let btnColor: option<SdkTypes.primaryButtonColor> = switch appearance.primaryButton {
  | Some(btn) =>
    switch btn.primaryButtonColor {
    | Some(PrimaryButtonColor(btn_color)) => btn_color
    | Some(PrimaryButtonDefault({light, dark})) => isDarkMode ? dark : light
    | None => None
    }
  | None => None
  }

  let btnShape: option<SdkTypes.shapes> = switch appearance.primaryButton {
  | Some(btn) =>
    switch btn.shapes {
    | Some(obj) => Some(obj)
    | None => None
    }
  | None => None
  }

  let gpayOverrideStyle = switch appearance.googlePay.buttonStyle {
  | Some(val) => isDarkMode ? val.dark : val.light
  | None => themeObj.googlePayButtonColor
  }

  let applePayOverrideStyle = switch appearance.applePay.buttonStyle {
  | Some(val) => isDarkMode ? val.dark : val.light
  | None => themeObj.applePayButtonColor
  }
  {
    primaryButtonHeight: themeObj.primaryButtonHeight,
    platform: themeObj.platform,
    bgColor: getStyleProp(
      ~override=switch appearanceColor {
      | Some(obj) => obj.background
      | _ => None
      },
      ~fn=val => s({backgroundColor: val}),
      ~default=themeObj.bgColor,
    ),
    loadingBgColor: getStrProp(
      ~overRideProp=switch appearanceColor {
      | Some(obj) => obj.loaderBackground
      | _ => None
      },
      ~defaultProp=themeObj.loadingBgColor,
    ),
    loadingFgColor: getStrProp(
      ~overRideProp=switch appearanceColor {
      | Some(obj) => obj.loaderBackground
      | _ => None
      },
      ~defaultProp=themeObj.loadingFgColor,
    ),
    bgTransparentColor: styles["light_bgTransparentColor"],
    textPrimary: getStyleProp(
      ~override=switch appearanceColor {
      | Some(obj) => obj.primaryText
      | _ => None
      },
      ~fn=val => s({color: val}),
      ~default=themeObj.textPrimary,
    ),
    textSecondary: getStyleProp(
      ~override=switch appearanceColor {
      | Some(obj) => obj.secondaryText
      | _ => None
      },
      ~fn=val => s({color: val}),
      ~default=themeObj.textSecondary,
    ),
    textSecondaryBold: getStyleProp(
      ~override=switch appearanceColor {
      | Some(obj) => obj.secondaryText
      | _ => None
      },
      ~fn=val => s({color: val}),
      ~default=themeObj.textSecondaryBold,
    ),
    placeholderColor: getStrProp(
      ~overRideProp=switch appearanceColor {
      | Some(obj) => obj.placeholderText
      | _ => None
      },
      ~defaultProp=themeObj.placeholderColor,
    ),
    textInputBg: themeObj.textInputBg,
    iconColor: getStrProp(
      ~overRideProp=switch appearanceColor {
      | Some(obj) => obj.icon
      | _ => None
      },
      ~defaultProp=themeObj.iconColor,
    ),
    lineBorderColor: themeObj.lineBorderColor,
    linkColor: themeObj.linkColor,
    disableBgColor: themeObj.disableBgColor,
    filterHeaderColor: themeObj.filterHeaderColor,
    filterOptionTextColor: themeObj.filterOptionTextColor,
    tooltipTextColor: themeObj.tooltipTextColor,
    tooltipBackgroundColor: themeObj.tooltipBackgroundColor,
    boxColor: themeObj.boxBorderColor,
    boxBorderColor: themeObj.boxBorderColor,
    dropDownSelectAll: themeObj.dropDownSelectAll,
    fadedColor: themeObj.fadedColor,
    status_color,
    detailViewToolTipText: themeObj.detailViewToolTipText,
    summarisedViewSingleStatHeading: themeObj.summarisedViewSingleStatHeading,
    switchThumbColor: themeObj.switchThumbColor,
    shimmerColor: themeObj.shimmerColor,
    lastOffset: themeObj.lastOffset,
    dangerColor: getStrProp(
      ~overRideProp=switch appearanceColor {
      | Some(obj) => obj.error
      | _ => None
      },
      ~defaultProp=themeObj.dangerColor,
    ),
    orderDisableButton: themeObj.orderDisableButton,
    toastColorConfig: {
      backgroundColor: themeObj.toastColorConfig.backgroundColor,
      textColor: themeObj.toastColorConfig.textColor,
    },
    primaryColor: getStrProp(
      ~overRideProp=switch appearanceColor {
      | Some(obj) => obj.primary
      | _ => None
      },
      ~defaultProp=themeObj.primaryColor,
    ),
    borderRadius: getStrProp(
      ~overRideProp=switch appearance.shapes {
      | Some(shapeObj) => shapeObj.borderRadius
      | None => None
      },
      ~defaultProp=themeObj.borderRadius,
    ),
    borderWidth: getStrProp(
      ~overRideProp=switch appearance.shapes {
      | Some(obj) => obj.borderWidth
      | None => None
      },
      ~defaultProp=themeObj.borderWidth,
    ),
    buttonBorderRadius: getStrProp(
      ~overRideProp=switch btnShape {
      | Some(obj) => obj.borderRadius
      | None => Some(themeObj.buttonBorderRadius)
      },
      ~defaultProp=themeObj.buttonBorderRadius,
    ),
    buttonBorderWidth: getStrProp(
      ~overRideProp=switch btnShape {
      | Some(obj) => obj.borderWidth
      | None => Some(themeObj.buttonBorderWidth)
      },
      ~defaultProp=themeObj.buttonBorderWidth,
    ),
    component: {
      background: getStrProp(
        ~overRideProp=switch appearanceColor {
        | Some(obj) => obj.componentBackground
        | _ => None
        },
        ~defaultProp=themeObj.component.background,
      ),
      borderColor: getStrProp(
        ~overRideProp=switch appearanceColor {
        | Some(obj) => obj.componentBorder
        | _ => None
        },
        ~defaultProp=themeObj.component.borderColor,
      ),
      dividerColor: getStrProp(
        ~overRideProp=switch appearanceColor {
        | Some(obj) => obj.componentDivider
        | _ => None
        },
        ~defaultProp=themeObj.component.dividerColor,
      ),
      color: getStrProp(
        ~overRideProp=switch appearanceColor {
        | Some(obj) => obj.componentText
        | _ => None
        },
        ~defaultProp=themeObj.component.color,
      ),
    },
    locale: switch appearance.locale {
    | Some(obj) => obj
    | _ => En
    },
    fontFamily: switch appearance.font {
    | Some(obj) =>
      switch obj.family {
      | Some(family) => family
      | None => themeObj.fontFamily
      }
    | None => themeObj.fontFamily
    },
    fontScale: switch appearance.font {
    | Some(obj) =>
      switch obj.scale {
      | Some(scale) => scale
      | None => 1.
      }
    | None => themeObj.fontScale
    },
    headingTextSizeAdjust: switch appearance.font {
    | Some(obj) =>
      switch obj.headingTextSizeAdjust {
      | Some(size) => size >= maxTextSize.maxHeadingTextSize ? maxTextSize.maxHeadingTextSize : size
      | None => themeObj.headingTextSizeAdjust
      }
    | None => themeObj.headingTextSizeAdjust
    },
    subHeadingTextSizeAdjust: switch appearance.font {
    | Some(obj) =>
      switch obj.subHeadingTextSizeAdjust {
      | Some(size) =>
        size >= maxTextSize.maxSubHeadingTextSize ? maxTextSize.maxSubHeadingTextSize : size
      | None => themeObj.subHeadingTextSizeAdjust
      }
    | None => themeObj.subHeadingTextSizeAdjust
    },
    placeholderTextSizeAdjust: switch appearance.font {
    | Some(obj) =>
      switch obj.placeholderTextSizeAdjust {
      | Some(size) =>
        size >= maxTextSize.maxPlaceholderTextSize ? maxTextSize.maxPlaceholderTextSize : size
      | None => themeObj.placeholderTextSizeAdjust
      }
    | None => themeObj.placeholderTextSizeAdjust
    },
    buttonTextSizeAdjust: switch appearance.font {
    | Some(obj) =>
      switch obj.buttonTextSizeAdjust {
      | Some(size) => size >= maxTextSize.maxButtonTextSize ? maxTextSize.maxButtonTextSize : size
      | None => themeObj.buttonTextSizeAdjust
      }
    | None => themeObj.buttonTextSizeAdjust
    },
    errorTextSizeAdjust: switch appearance.font {
    | Some(obj) =>
      switch obj.errorTextSizeAdjust {
      | Some(size) => size >= maxTextSize.maxErrorTextSize ? maxTextSize.maxErrorTextSize : size
      | None => themeObj.errorTextSizeAdjust
      }
    | None => themeObj.errorTextSizeAdjust
    },
    linkTextSizeAdjust: switch appearance.font {
    | Some(obj) =>
      switch obj.linkTextSizeAdjust {
      | Some(size) => size >= maxTextSize.maxLinkTextSize ? maxTextSize.maxLinkTextSize : size
      | None => themeObj.linkTextSizeAdjust
      }
    | None => themeObj.linkTextSizeAdjust
    },
    modalTextSizeAdjust: switch appearance.font {
    | Some(obj) =>
      switch obj.modalTextSizeAdjust {
      | Some(size) => size >= maxTextSize.maxModalTextSize ? maxTextSize.maxModalTextSize : size
      | None => themeObj.modalTextSizeAdjust
      }
    | None => themeObj.modalTextSizeAdjust
    },
    cardTextSizeAdjust: switch appearance.font {
    | Some(obj) =>
      switch obj.cardTextSizeAdjust {
      | Some(size) => size >= maxTextSize.maxCardTextSize ? maxTextSize.maxCardTextSize : size
      | None => themeObj.cardTextSizeAdjust
      }
    | None => themeObj.cardTextSizeAdjust
    },
    paypalButonColor: themeObj.paypalButonColor,
    samsungPayButtonColor: themeObj.samsungPayButtonColor,
    applePayButtonColor: applePayOverrideStyle,
    googlePayButtonColor: gpayOverrideStyle,
    payNowButtonColor: getStrProp(
      ~overRideProp=switch btnColor {
      | Some(obj) =>
        switch obj.background {
        | Some(str) => Some(str)
        | None =>
          switch appearanceColor {
          | Some(appObj) =>
            switch appObj.primary {
            | Some(str) => Some(str)
            | None => None
            }
          | None => None
          }
        }
      | None => None
      },
      ~defaultProp=themeObj.payNowButtonColor,
    ),
    payNowButtonTextColor: getStrProp(
      ~overRideProp=switch btnColor {
      | Some(obj) => obj.text
      | None => None
      },
      ~defaultProp=themeObj.payNowButtonTextColor,
    ),
    payNowButtonBorderColor: getStrProp(
      ~overRideProp=switch btnColor {
      | Some(obj) => obj.border
      | None => None
      },
      ~defaultProp=themeObj.payNowButtonBorderColor,
    ),
    payNowButtonShadowColor: getStrProp(
      ~overRideProp=switch btnShape {
      | Some(obj) =>
        switch obj.shadow {
        | Some(shadowObj) => shadowObj.color
        | None => None
        }
      | None => None
      },
      ~defaultProp=themeObj.payNowButtonShadowColor,
    ),
    payNowButtonShadowIntensity: getStrProp(
      ~overRideProp=switch btnShape {
      | Some(obj) =>
        switch obj.shadow {
        | Some(shadowObj) => shadowObj.intensity
        | None => None
        }
      | None => None
      },
      ~defaultProp=themeObj.payNowButtonShadowIntensity,
    ),
    focusedTextInputBoderColor: getStrProp(
      ~overRideProp=switch appearanceColor {
      | Some(obj) => obj.componentBorder
      | _ => None
      },
      ~defaultProp=themeObj.focusedTextInputBoderColor,
    ),
    errorTextInputColor: getStrProp(
      ~overRideProp=switch appearanceColor {
      | Some(obj) => obj.error
      | _ => None
      },
      ~defaultProp=themeObj.dangerColor,
    ),
    normalTextInputBoderColor: getStrProp(
      ~overRideProp=switch appearanceColor {
      | Some(obj) => obj.componentBorder
      | _ => None
      },
      ~defaultProp=themeObj.component.borderColor,
    ),
    shadowColor: getStrProp(
      ~overRideProp=switch appearance.shapes {
      | Some(shapeObj) =>
        switch shapeObj.shadow {
        | Some(shadowObj) => shadowObj.color
        | None => None
        }
      | None => None
      },
      ~defaultProp=themeObj.shadowColor,
    ),
    shadowIntensity: getStrProp(
      ~overRideProp=switch appearance.shapes {
      | Some(shapeObj) =>
        switch shapeObj.shadow {
        | Some(shadowObj) => shadowObj.intensity
        | None => None
        }
      | None => None
      },
      ~defaultProp=themeObj.shadowIntensity,
    ),
    paymentSheetOverlay: themeObj.paymentSheetOverlay,
    disclaimerBackgroundColor: themeObj.disclaimerBackgroundColor,
    disclaimerTextColor: themeObj.disclaimerTextColor,
    instructionalTextColor: themeObj.instructionalTextColor,
    poweredByTextColor: themeObj.poweredByTextColor,
    detailsViewTextKeyColor: themeObj.detailsViewTextKeyColor,
    detailsViewTextValueColor: themeObj.detailsViewTextValueColor,
    silverBorderColor: themeObj.silverBorderColor,
    sheetContentPadding: themeObj.sheetContentPadding,
    errorMessageSpacing: themeObj.errorMessageSpacing,
  }
}

//for preDefine light and dark styles
let useThemeBasedStyle = () => {
  let (themeType, _) = React.useContext(ThemeContext.themeContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let themerecord = switch nativeProp.configuration.appearance.theme {
  | FlatMinimal => Some(flatMinimal)
  | Minimal => Some(minimal)
  | Light => Some(lightRecord)
  | Dark => Some(darkRecord)
  | Default => None
  }
  let themerecordOverridedWithAppObj = switch themeType {
  | Light(appearance) => itemToObj(themerecord->Option.getOr(lightRecord), appearance, false)
  | Dark(appearance) => itemToObj(themerecord->Option.getOr(darkRecord), appearance, true)
  }
  themerecordOverridedWithAppObj
}
//for custom light and dark styles
// let useCustomThemeBasedStyle = (~lightStyle, ~darkStyle, ~defaultStyle=?, ()) => {
//   let isDarkMode = LightDarkTheme.useIsDarkMode()
//   let x = isDarkMode ? darkStyle : lightStyle

//   switch defaultStyle {
//   | Some(style) => array([style, x])
//   | None => x
//   }
// }
