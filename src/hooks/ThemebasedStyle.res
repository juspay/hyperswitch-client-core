open ReactNative
open Style

type resolvedCheckedIconConfig = {
  color: ReactNative.Color.t,
  stroke?: ReactNative.Color.t,
  size: float,
  bottom: float,
  right: float,
}

type resolvedLogoConfig = {
  borderRadius: float,
  colors: SdkTypes.logoColors,
  checkedIconForSelection?: resolvedCheckedIconConfig,
}

type statusColorConfig = {
  textColor: ReactNative.Color.t,
  backgroundColor: ReactNative.Color.t,
}

type selectedComponentConfig = {
  background: ReactNative.Color.t,
  borderColor: ReactNative.Color.t,
  borderWidth: float,
  dividerColor: ReactNative.Color.t,
  color: ReactNative.Color.t,
}

type componentConfig = {
  background: ReactNative.Color.t,
  borderColor: ReactNative.Color.t,
  dividerColor: ReactNative.Color.t,
  color: ReactNative.Color.t,
  selected: selectedComponentConfig,
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
    "flatMinimal_bgColor": s({backgroundColor: "#16181F"}),
    "minimal_bgColor": s({backgroundColor: "#F7F8FA"}),
    "light_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.2)}),
    "dark_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.2)}),
    "flatMinimal_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.2)}),
    "minimal_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.2)}),
    "light_textPrimary": s({color: "#0570de"}),
    "dark_textPrimary": s({color: "#FFFFFF"}),
    "flatMinimal_textPrimary": s({color: "#E8EAF0"}),
    "minimal_textPrimary": s({color: "#111827"}),
    "light_textSecondary": s({color: "#767676"}),
    "dark_textSecondary": s({color: "#F6F8F9"}),
    "flatMinimal_textSeconadry": s({color: "#8A90A0"}),
    "minimal_textSeconadry": s({color: "#6B7280"}),
    "light_textSecondary_Bold": s({color: "#000000"}),
    "dark_textSecondaryBold": s({color: "#F6F8F9"}),
    "flatMinimal_textSeconadryBold": s({color: "#B8BDC8"}),
    "minimal_textSeconadryBold": s({color: "#374151"}),
    "light_textInputBg": s({backgroundColor: "#ffffff"}),
    "dark_textInputBg": s({backgroundColor: "#444444"}),
    "flatMinimal_textInputBg": s({backgroundColor: "#12141C"}),
    "minimal_textInputBg": s({backgroundColor: "#FFFFFF"}),
    "light_boxColor": s({backgroundColor: "#FFFFFF"}),
    "dark_boxColor": s({backgroundColor: "#191A1A"}),
    "flatMinimal_boxColor": s({backgroundColor: "#1E2130"}),
    "minimal_boxColor": s({backgroundColor: "#FFFFFF"}),
    "light_boxBorderColor": s({borderColor: "#e4e4e5"}),
    "dark_boxBorderColor": s({borderColor: "#79787d"}),
    "flatMinimal_boxBorderColor": s({borderColor: "#2E3248"}),
    "minimal_boxBorderColor": s({borderColor: "#E4E6EA"}),
    "brutal_bgColor": s({backgroundColor: "#cbfdbb"}),
    "brutal_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.3)}),
    "brutal_textPrimary": s({color: "#000000"}),
    "brutal_textSecondary": s({color: "#333333"}),
    "brutal_textSecondaryBold": s({color: "#000000"}),
    "brutal_textInputBg": s({backgroundColor: "#FFFFFF"}),
    "brutal_boxColor": s({backgroundColor: "#f5fb1f"}),
    "brutal_boxBorderColor": s({borderColor: "#000000"}),
    "glass_bgColor": s({backgroundColor: "rgba(15,10,40,1)"}),
    "glass_bgTransparentColor": s({backgroundColor: Color.rgba(~r=15, ~g=10, ~b=40, ~a=0.85)}),
    "glass_textPrimary": s({color: "#F1F5F9"}),
    "glass_textSecondary": s({color: "#CBD5E1"}),
    "glass_textSecondaryBold": s({color: "#F1F5F9"}),
    "glass_textInputBg": s({backgroundColor: "rgba(255,255,255,0.08)"}),
    "glass_boxColor": s({backgroundColor: "rgba(255,255,255,0.12)"}),
    "glass_boxBorderColor": s({borderColor: "rgba(255,255,255,0.25)"}),
    "skeu_bgColor": s({backgroundColor: "#E8E0D0"}),
    "skeu_bgTransparentColor": s({backgroundColor: Color.rgba(~r=90, ~g=70, ~b=40, ~a=0.25)}),
    "skeu_textPrimary": s({color: "#1A1A1A"}),
    "skeu_textSecondary": s({color: "#5A4A3A"}),
    "skeu_textSecondaryBold": s({color: "#2C2C2C"}),
    "skeu_textInputBg": s({backgroundColor: "#FAFAF7"}),
    "skeu_boxColor": s({backgroundColor: "#FFFFFF"}),
    "skeu_boxBorderColor": s({borderColor: "#C9B99A"}),
    "clay_bgColor": s({backgroundColor: "#EEF0FF"}),
    "clay_bgTransparentColor": s({backgroundColor: Color.rgba(~r=108, ~g=99, ~b=255, ~a=0.12)}),
    "clay_textPrimary": s({color: "#1A1A2E"}),
    "clay_textSecondary": s({color: "#5A5A8A"}),
    "clay_textSecondaryBold": s({color: "#1A1A2E"}),
    "clay_textInputBg": s({backgroundColor: "#F8F8FF"}),
    "clay_boxColor": s({
      backgroundColor: "#FFFFFF",
    }),
    "clay_boxBorderColor": s({borderColor: "#D4D0FF"}),
    "charcoal_bgColor": s({backgroundColor: "#F2F2F2"}),
    "charcoal_bgTransparentColor": s({backgroundColor: Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.15)}),
    "charcoal_textPrimary": s({color: "#1A1A1A"}),
    "charcoal_textSecondary": s({color: "#888888"}),
    "charcoal_textSecondaryBold": s({color: "#1A1A1A"}),
    "charcoal_textInputBg": s({backgroundColor: "#E8E8E8"}),
    "charcoal_boxColor": s({backgroundColor: "#EAEAEA"}),
    "charcoal_boxBorderColor": s({borderColor: "#E0E0E0"}),
    "soft_bgColor": s({backgroundColor: "#E4EBF5"}),
    "soft_bgTransparentColor": s({backgroundColor: Color.rgba(~r=52, ~g=71, ~b=103, ~a=0.15)}),
    "soft_textPrimary": s({color: "#31394D"}),
    "soft_textSecondary": s({color: "#6B7280"}),
    "soft_textSecondaryBold": s({color: "#31394D"}),
    "soft_textInputBg": s({backgroundColor: "#E4EBF5"}),
    "soft_boxColor": s({backgroundColor: "#E4EBF5"}),
    "soft_boxBorderColor": s({borderColor: "transparent"}),
    "soft_textInputBgStyle": s({backgroundColor: "#E4EBF5"}),
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
  payNowButtonShadowConfig: SdkTypes.shadowConfig,
  focusedTextInputBoderColor: string,
  errorTextInputColor: string,
  normalTextInputBoderColor: string,
  shadowConfig: SdkTypes.shadowConfig,
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
  logoConfig: option<resolvedLogoConfig>,
}

let defaultResolvedLogoConfig: resolvedLogoConfig = {
  borderRadius: 50.,
  colors: {
    backgroundColor: "#2e2e2e",
    unselected: "white",
  },
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
    selected: {
      background: Color.rgb(~r=57, ~g=57, ~b=57),
      borderColor: "#0057c7",
      borderWidth: 2.0,
      dividerColor: "#e6e6e6",
      color: "#ffffff",
    },
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
  payNowButtonShadowConfig: {
    color: Some("black"),
    opacity: Some(0.2),
    blurRadius: None,
    offset: None,
    intensity: Some(2.),
  },
  focusedTextInputBoderColor: "#0057c7",
  errorTextInputColor: "rgba(0, 153, 255, 1)",
  normalTextInputBoderColor: "rgba(204, 210, 226, 0.75)",
  shadowConfig: {
    color: Some("black"),
    opacity: Some(0.2),
    blurRadius: None,
    offset: None,
    intensity: Some(2.),
  },
  disclaimerBackgroundColor: "#FDF3E0",
  disclaimerTextColor: "#D57F0C",
  instructionalTextColor: "#999999",
  poweredByTextColor: "#111111",
  detailsViewTextKeyColor: "#999999",
  detailsViewTextValueColor: "#333333",
  silverBorderColor: "#CCCCCC",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  logoConfig: None,
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
    selected: {
      background: "#FFFFFF",
      borderColor: "#006DF9",
      borderWidth: 2.0,
      dividerColor: "#e6e6e6",
      color: "#006DF9",
    },
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
  payNowButtonShadowConfig: {
    color: Some("black"),
    opacity: Some(0.2),
    blurRadius: None,
    offset: None,
    intensity: Some(2.),
  },
  focusedTextInputBoderColor: "#006DF9",
  errorTextInputColor: "rgba(0, 153, 255, 1)",
  normalTextInputBoderColor: "rgba(204, 210, 226, 0.75)",
  shadowConfig: {
    color: Some("black"),
    opacity: Some(0.2),
    blurRadius: None,
    offset: None,
    intensity: Some(2.),
  },
  disclaimerBackgroundColor: "#FDF3E0",
  disclaimerTextColor: "#D57F0C",
  instructionalTextColor: "#999999",
  poweredByTextColor: "#111111",
  detailsViewTextKeyColor: "#999999",
  detailsViewTextValueColor: "#333333",
  silverBorderColor: "#CCCCCC",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  logoConfig: None,
}

let minimal = {
  primaryButtonHeight: 48.,
  platform: "android",
  paymentSheetOverlay: "#00000030",
  bgColor: styles["minimal_bgColor"],
  loadingBgColor: "#E8EAED",
  loadingFgColor: "#0570DE",
  bgTransparentColor: styles["minimal_bgTransparentColor"],
  textPrimary: styles["minimal_textPrimary"],
  textSecondary: styles["minimal_textSeconadry"],
  textSecondaryBold: styles["minimal_textSeconadryBold"],
  placeholderColor: "#9CA3AF",
  textInputBg: styles["minimal_textInputBg"],
  iconColor: "rgba(17,24,39,0.35)",
  lineBorderColor: "#E4E6EA",
  linkColor: "#0570DE",
  disableBgColor: "#F3F4F6",
  filterHeaderColor: "#374151",
  filterOptionTextColor: ["#111827", "rgba(55,65,81,0.8)"],
  tooltipTextColor: "#FFFFFF",
  tooltipBackgroundColor: "#111827",
  boxColor: styles["minimal_boxColor"],
  boxBorderColor: styles["minimal_boxBorderColor"],
  dropDownSelectAll: [["#EFF6FF", "#EFF6FF", "#EFF6FF"], ["#F9FAFB", "#FFFFFF", "#F9FAFB"]],
  fadedColor: ["#E5E7EB", "rgba(55,65,81,0.5)"],
  status_color,
  detailViewToolTipText: "#FFFFFF",
  summarisedViewSingleStatHeading: "#111827",
  switchThumbColor: "#FFFFFF",
  shimmerColor: ["#E5E7EB", "#F9FAFB"],
  lastOffset: "#F7F8FA",
  dangerColor: "#DC2626",
  orderDisableButton: "#6B7280",
  toastColorConfig: {
    backgroundColor: "#111827",
    textColor: "#F9FAFB",
  },
  primaryColor: "#0570DE",
  borderRadius: 8.0,
  borderWidth: 0.5,
  buttonBorderRadius: 8.0,
  buttonBorderWidth: 0.0,
  component: {
    background: "#FFFFFF",
    borderColor: "#E4E6EA",
    dividerColor: "#F3F4F6",
    color: "#111827",
    selected: {
      background: "#EFF6FF",
      borderColor: "#0570DE",
      borderWidth: 1.5,
      dividerColor: "#DBEAFE",
      color: "#0570DE",
    },
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
  samsungPayButtonColor: "#111827",
  applePayButtonColor: #black,
  googlePayButtonColor: #dark,
  payNowButtonColor: "#0570DE",
  payNowButtonTextColor: "#FFFFFF",
  payNowButtonBorderColor: "#0460C8",
  payNowButtonShadowConfig: {
    color: Some("rgba(5,112,222,0.3)"),
    opacity: Some(0.8),
    blurRadius: Some(8.),
    offset: Some({x: Some(0.), y: Some(3.)}),
    intensity: Some(4.),
  },
  focusedTextInputBoderColor: "#0570DE",
  errorTextInputColor: "#DC2626",
  normalTextInputBoderColor: "#D1D5DB",
  shadowConfig: {
    color: Some("rgba(0,0,0,0.08)"),
    opacity: Some(0.08),
    blurRadius: Some(8.),
    offset: Some({x: Some(0.), y: Some(2.)}),
    intensity: Some(4.),
  },
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  disclaimerBackgroundColor: "#FFFBEB",
  disclaimerTextColor: "#92400E",
  instructionalTextColor: "#9CA3AF",
  poweredByTextColor: "#6B7280",
  detailsViewTextKeyColor: "#9CA3AF",
  detailsViewTextValueColor: "#111827",
  silverBorderColor: "#D1D5DB",
  logoConfig: None,
}

let flatMinimal = {
  primaryButtonHeight: 48.,
  platform: "android",
  paymentSheetOverlay: "#00000050",
  bgColor: styles["flatMinimal_bgColor"],
  loadingBgColor: "#1E2130",
  loadingFgColor: "#3541FF",
  bgTransparentColor: styles["flatMinimal_bgTransparentColor"],
  textPrimary: styles["flatMinimal_textPrimary"],
  textSecondary: styles["flatMinimal_textSeconadry"],
  textSecondaryBold: styles["flatMinimal_textSeconadryBold"],
  placeholderColor: "rgba(232,234,240,0.35)",
  textInputBg: styles["flatMinimal_textInputBg"],
  iconColor: "rgba(232,234,240,0.35)",
  lineBorderColor: "#2E3248",
  linkColor: "#6470FF",
  disableBgColor: "#1E2130",
  filterHeaderColor: "#B8BDC8",
  filterOptionTextColor: ["#E8EAF0", "rgba(232,234,240,0.7)"],
  tooltipTextColor: "#FFFFFF",
  tooltipBackgroundColor: "#3541FF",
  boxColor: styles["flatMinimal_boxColor"],
  boxBorderColor: styles["flatMinimal_boxBorderColor"],
  dropDownSelectAll: [["#1A2040", "#1A2040", "#1A2040"], ["#1E2130", "#1E2130", "#1E2130"]],
  fadedColor: ["rgba(46,50,72,0.6)", "rgba(232,234,240,0.3)"],
  status_color,
  detailViewToolTipText: "#FFFFFF",
  summarisedViewSingleStatHeading: "#E8EAF0",
  switchThumbColor: "#3541FF",
  shimmerColor: ["#1E2130", "#252840"],
  lastOffset: "#16181F",
  dangerColor: "#FF5252",
  orderDisableButton: "#4A4D6A",
  toastColorConfig: {
    backgroundColor: "#1E2130",
    textColor: "#E8EAF0",
  },
  primaryColor: "#3541FF",
  borderRadius: 6.0,
  borderWidth: 0.0,
  buttonBorderRadius: 6.0,
  buttonBorderWidth: 0.0,
  component: {
    background: "#1E2130",
    borderColor: "#2E3248",
    dividerColor: "#252840",
    color: "#E8EAF0",
    selected: {
      background: "#1A2040",
      borderColor: "#3541FF",
      borderWidth: 1.5,
      dividerColor: "#2A3060",
      color: "#E8EAF0",
    },
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
  applePayButtonColor: #white,
  googlePayButtonColor: #dark,
  samsungPayButtonColor: "#3541FF",
  payNowButtonColor: "#3541FF",
  payNowButtonTextColor: "#FFFFFF",
  payNowButtonBorderColor: "#5A63FF",
  payNowButtonShadowConfig: {
    color: Some("rgba(53,65,255,0.2)"),
    opacity: Some(0.2),
    blurRadius: Some(12.),
    offset: Some({x: Some(0.), y: Some(4.)}),
    intensity: Some(6.),
  },
  focusedTextInputBoderColor: "#3541FF",
  errorTextInputColor: "#FF5252",
  normalTextInputBoderColor: "#2E3248",
  shadowConfig: {
    color: Some("rgba(0,0,0,0.0)"),
    opacity: Some(0.0),
    blurRadius: Some(0.),
    offset: Some({x: Some(0.), y: Some(0.)}),
    intensity: Some(0.),
  },
  disclaimerBackgroundColor: "#1A2040",
  disclaimerTextColor: "#8A90A0",
  instructionalTextColor: "#6A7080",
  poweredByTextColor: "#6A7080",
  detailsViewTextKeyColor: "#8A90A0",
  detailsViewTextValueColor: "#E8EAF0",
  silverBorderColor: "#2E3248",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  logoConfig: None,
}

let brutalRecord = {
  primaryButtonHeight: 48.,
  platform: "android",
  paymentSheetOverlay: "#00000040",
  bgColor: styles["brutal_bgColor"],
  loadingBgColor: "#B8FF9F",
  loadingFgColor: "#FFE500",
  bgTransparentColor: styles["brutal_bgTransparentColor"],
  textPrimary: styles["brutal_textPrimary"],
  textSecondary: styles["brutal_textSecondary"],
  textSecondaryBold: styles["brutal_textSecondaryBold"],
  placeholderColor: "#55555590",
  textInputBg: styles["brutal_textInputBg"],
  iconColor: "rgba(0, 0, 0, 0.4)",
  lineBorderColor: "#00000030",
  linkColor: "#807dfa",
  disableBgColor: "#D0F0C0",
  filterHeaderColor: "#000000",
  filterOptionTextColor: ["#000000", "rgba(0,0,0,0.7)"],
  tooltipTextColor: "#000000",
  tooltipBackgroundColor: "#FFE500",
  boxColor: styles["brutal_boxColor"],
  boxBorderColor: styles["brutal_boxBorderColor"],
  dropDownSelectAll: [["#FFE500", "#FFE500", "#FFE500"], ["#B8FF9F", "#B8FF9F", "#B8FF9F"]],
  fadedColor: ["rgba(0,0,0,0.1)", "rgba(0,0,0,0.3)"],
  status_color,
  detailViewToolTipText: "#000000",
  summarisedViewSingleStatHeading: "#000000",
  switchThumbColor: "#FFE500",
  shimmerColor: ["#9dfc7c", "#B8FF9F"],
  lastOffset: "#B8FF9F",
  dangerColor: "#f76363",
  orderDisableButton: "#333333",
  toastColorConfig: {
    backgroundColor: "#000000",
    textColor: "#FFE500",
  },
  primaryColor: "#000000",
  borderRadius: 8.0,
  borderWidth: 2.5,
  buttonBorderRadius: 8.0,
  buttonBorderWidth: 2.5,
  component: {
    background: "#FFFFFF",
    borderColor: "#000000",
    dividerColor: "#00000020",
    color: "#000000",
    selected: {
      background: "#FFE500",
      borderColor: "#000000",
      borderWidth: 2.5,
      dividerColor: "#000000",
      color: "#000000",
    },
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
  googlePayButtonColor: #light,
  samsungPayButtonColor: "#000000",
  payNowButtonColor: "#FFE500",
  payNowButtonTextColor: "#000000",
  payNowButtonBorderColor: "#000000",
  payNowButtonShadowConfig: {
    color: Some("#000000"),
    opacity: Some(1.0),
    blurRadius: Some(0.),
    offset: Some({x: Some(2.), y: Some(2.)}),
    intensity: Some(2.),
  },
  focusedTextInputBoderColor: "#000000",
  errorTextInputColor: "#f76363",
  normalTextInputBoderColor: "#000000",
  shadowConfig: {
    color: Some("#000000"),
    opacity: Some(1.0),
    blurRadius: Some(0.),
    offset: Some({x: Some(2.), y: Some(2.)}),
    intensity: Some(2.),
  },
  disclaimerBackgroundColor: "#FFE500",
  disclaimerTextColor: "#000000",
  instructionalTextColor: "#555555",
  poweredByTextColor: "#000000",
  detailsViewTextKeyColor: "#555555",
  detailsViewTextValueColor: "#000000",
  silverBorderColor: "#000000",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  logoConfig: None,
}

let glassRecord = {
  primaryButtonHeight: 48.,
  platform: "android",
  paymentSheetOverlay: "rgba(0,0,0,0.6)",
  bgColor: styles["glass_bgColor"],
  loadingBgColor: "rgba(255,255,255,0.12)",
  loadingFgColor: "#A78BFA",
  bgTransparentColor: styles["glass_bgTransparentColor"],
  textPrimary: styles["glass_textPrimary"],
  textSecondary: styles["glass_textSecondary"],
  textSecondaryBold: styles["glass_textSecondaryBold"],
  placeholderColor: "rgba(241,245,249,0.4)",
  textInputBg: styles["glass_textInputBg"],
  iconColor: "rgba(241,245,249,0.6)",
  lineBorderColor: "rgba(255,255,255,0.15)",
  linkColor: "#A78BFA",
  disableBgColor: "rgba(255,255,255,0.06)",
  filterHeaderColor: "#F1F5F9",
  filterOptionTextColor: ["#F1F5F9", "rgba(241,245,249,0.7)"],
  tooltipTextColor: "#F1F5F9",
  tooltipBackgroundColor: "rgba(99,102,241,0.85)",
  boxColor: styles["glass_boxColor"],
  boxBorderColor: styles["glass_boxBorderColor"],
  dropDownSelectAll: [
    ["rgba(167,139,250,0.3)", "rgba(167,139,250,0.3)", "rgba(167,139,250,0.3)"],
    ["rgba(255,255,255,0.12)", "rgba(255,255,255,0.12)", "rgba(255,255,255,0.12)"],
  ],
  fadedColor: ["rgba(255,255,255,0.08)", "rgba(255,255,255,0.2)"],
  status_color,
  detailViewToolTipText: "#F1F5F9",
  summarisedViewSingleStatHeading: "#F1F5F9",
  switchThumbColor: "#A78BFA",
  shimmerColor: ["rgba(255,255,255,0.06)", "rgba(255,255,255,0.15)"],
  lastOffset: "rgba(15,10,40,1)",
  dangerColor: "#f87171",
  orderDisableButton: "rgba(255,255,255,0.3)",
  toastColorConfig: {
    backgroundColor: "rgba(255,255,255,0.15)",
    textColor: "#F1F5F9",
  },
  primaryColor: "#A78BFA",
  borderRadius: 16.0,
  borderWidth: 1.0,
  buttonBorderRadius: 16.0,
  buttonBorderWidth: 1.0,
  component: {
    background: "rgba(255,255,255,0.12)",
    borderColor: "rgba(255,255,255,0.25)",
    dividerColor: "rgba(255,255,255,0.1)",
    color: "#F1F5F9",
    selected: {
      background: "rgba(255,255,255,0.22)",
      borderColor: "#A78BFA",
      borderWidth: 1.0,
      dividerColor: "rgba(167,139,250,0.4)",
      color: "#F1F5F9",
    },
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
  samsungPayButtonColor: "#6366F1",
  payNowButtonColor: "#6366F1",
  payNowButtonTextColor: "#FFFFFF",
  payNowButtonBorderColor: "rgba(255,255,255,0.3)",
  payNowButtonShadowConfig: {
    color: Some("rgba(99,102,241,0.5)"),
    opacity: Some(0.8),
    blurRadius: Some(20.),
    offset: Some({x: Some(0.), y: Some(4.)}),
    intensity: Some(8.),
  },
  focusedTextInputBoderColor: "#A78BFA",
  errorTextInputColor: "#f87171",
  normalTextInputBoderColor: "rgba(255,255,255,0.25)",
  shadowConfig: {
    color: Some("rgba(0,0,0,0.4)"),
    opacity: Some(0.4),
    blurRadius: Some(12.),
    offset: Some({x: Some(0.), y: Some(4.)}),
    intensity: Some(4.),
  },
  disclaimerBackgroundColor: "rgba(255,255,255,0.1)",
  disclaimerTextColor: "#CBD5E1",
  instructionalTextColor: "#94A3B8",
  poweredByTextColor: "#94A3B8",
  detailsViewTextKeyColor: "#94A3B8",
  detailsViewTextValueColor: "#F1F5F9",
  silverBorderColor: "rgba(255,255,255,0.2)",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  logoConfig: None,
}

let skeuRecord = {
  primaryButtonHeight: 48.,
  platform: "android",
  paymentSheetOverlay: "rgba(60,40,20,0.45)",
  bgColor: styles["skeu_bgColor"],
  loadingBgColor: "#D4B896",
  loadingFgColor: "#8B6914",
  bgTransparentColor: styles["skeu_bgTransparentColor"],
  textPrimary: styles["skeu_textPrimary"],
  textSecondary: styles["skeu_textSecondary"],
  textSecondaryBold: styles["skeu_textSecondaryBold"],
  placeholderColor: "#B0A090",
  textInputBg: styles["skeu_textInputBg"],
  iconColor: "rgba(90,74,58,0.6)",
  lineBorderColor: "#DDD0BC",
  linkColor: "#2C5F9E",
  disableBgColor: "#EDE5D8",
  filterHeaderColor: "#1A1A1A",
  filterOptionTextColor: ["#1A1A1A", "#5A4A3A"],
  tooltipTextColor: "#FAFAF7",
  tooltipBackgroundColor: "#5A3A10",
  boxColor: styles["skeu_boxColor"],
  boxBorderColor: styles["skeu_boxBorderColor"],
  dropDownSelectAll: [
    [["#FFF3DC", "#FFF3DC", "#FFF3DC"]],
    [["#FFFFFF", "#FFFFFF", "#FFFFFF"]],
  ]->Array.flat,
  fadedColor: ["rgba(90,74,58,0.08)", "rgba(90,74,58,0.2)"],
  status_color,
  detailViewToolTipText: "#1A1A1A",
  summarisedViewSingleStatHeading: "#1A1A1A",
  switchThumbColor: "#C6881A",
  shimmerColor: ["#EDE5D8", "#F5F0E8"],
  lastOffset: "#E8E0D0",
  dangerColor: "#C0392B",
  orderDisableButton: "#A09080",
  toastColorConfig: {
    backgroundColor: "#3B2A14",
    textColor: "#F5F0E8",
  },
  primaryColor: "#2C5F9E",
  borderRadius: 10.0,
  borderWidth: 1.5,
  buttonBorderRadius: 10.0,
  buttonBorderWidth: 1.5,
  component: {
    background: "#FFFFFF",
    borderColor: "#C9B99A",
    dividerColor: "#E5D9C8",
    color: "#1A1A1A",
    selected: {
      background: "#FFF3DC",
      borderColor: "#C6881A",
      borderWidth: 1.5,
      dividerColor: "#E8C97A",
      color: "#5A3A10",
    },
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
  googlePayButtonColor: #light,
  samsungPayButtonColor: "#3B2A14",
  payNowButtonColor: "#C6881A",
  payNowButtonTextColor: "#FFFFFF",
  payNowButtonBorderColor: "#8B6914",
  payNowButtonShadowConfig: {
    color: Some("rgba(139,105,20,0.45)"),
    opacity: Some(0.9),
    blurRadius: Some(8.),
    offset: Some({x: Some(0.), y: Some(4.)}),
    intensity: Some(8.),
  },
  focusedTextInputBoderColor: "#C6881A",
  errorTextInputColor: "#C0392B",
  normalTextInputBoderColor: "#C9B99A",
  shadowConfig: {
    color: Some("rgba(0,0,0,0.28)"),
    opacity: Some(0.28),
    blurRadius: Some(10.),
    offset: Some({x: Some(0.), y: Some(4.)}),
    intensity: Some(10.),
  },
  disclaimerBackgroundColor: "#FFF3DC",
  disclaimerTextColor: "#5A3A10",
  instructionalTextColor: "#7A6A58",
  poweredByTextColor: "#8B7A6A",
  detailsViewTextKeyColor: "#7A6A58",
  detailsViewTextValueColor: "#1A1A1A",
  silverBorderColor: "#C9B99A",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  logoConfig: None,
}

let clayRecord = {
  primaryButtonHeight: 52.,
  platform: "android",
  paymentSheetOverlay: "rgba(30,20,80,0.35)",
  bgColor: styles["clay_bgColor"],
  loadingBgColor: "#D4D0FF",
  loadingFgColor: "#6C63FF",
  bgTransparentColor: styles["clay_bgTransparentColor"],
  textPrimary: styles["clay_textPrimary"],
  textSecondary: styles["clay_textSecondary"],
  textSecondaryBold: styles["clay_textSecondaryBold"],
  placeholderColor: "#A0A0C8",
  textInputBg: styles["clay_textInputBg"],
  iconColor: "rgba(108,99,255,0.5)",
  lineBorderColor: "#D4D0FF",
  linkColor: "#6C63FF",
  disableBgColor: "#F0EFFF",
  filterHeaderColor: "#1A1A2E",
  filterOptionTextColor: ["#1A1A2E", "#5A5A8A"],
  tooltipTextColor: "#FFFFFF",
  tooltipBackgroundColor: "#6C63FF",
  boxColor: styles["clay_boxColor"],
  boxBorderColor: styles["clay_boxBorderColor"],
  dropDownSelectAll: [
    [["#EBE9FF", "#EBE9FF", "#EBE9FF"]],
    [["#FFFFFF", "#FFFFFF", "#FFFFFF"]],
  ]->Array.flat,
  fadedColor: ["rgba(108,99,255,0.06)", "rgba(108,99,255,0.18)"],
  status_color,
  detailViewToolTipText: "#1A1A2E",
  summarisedViewSingleStatHeading: "#1A1A2E",
  switchThumbColor: "#6C63FF",
  shimmerColor: ["#E8E7FF", "#F0EFFF"],
  lastOffset: "#EEF0FF",
  dangerColor: "#FF6B6B",
  orderDisableButton: "#B0AEDD",
  toastColorConfig: {
    backgroundColor: "#1A1A2E",
    textColor: "#EEF0FF",
  },
  primaryColor: "#6C63FF",
  borderRadius: 28.0,
  borderWidth: 1.0,
  buttonBorderRadius: 28.0,
  buttonBorderWidth: 1.0,
  component: {
    background: "#FFFFFF",
    borderColor: "#D4D0FF",
    dividerColor: "#E8E7FF",
    color: "#1A1A2E",
    selected: {
      background: "#EBE9FF",
      borderColor: "#6C63FF",
      borderWidth: 1.5,
      dividerColor: "#C4C0FF",
      color: "#4A40CC",
    },
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
  googlePayButtonColor: #light,
  samsungPayButtonColor: "#4A40CC",
  payNowButtonColor: "#6C63FF",
  payNowButtonTextColor: "#FFFFFF",
  payNowButtonBorderColor: "#5A50E0",
  payNowButtonShadowConfig: {
    color: Some("rgba(108,99,255,0.2)"),
    opacity: Some(0.2),
    blurRadius: Some(16.),
    offset: Some({x: Some(0.), y: Some(8.)}),
    intensity: Some(12.),
  },
  focusedTextInputBoderColor: "#6C63FF",
  errorTextInputColor: "#FF6B6B",
  normalTextInputBoderColor: "#D4D0FF",
  shadowConfig: {
    color: Some("rgba(108,99,255,0.2)"),
    opacity: Some(0.2),
    blurRadius: Some(16.),
    offset: Some({x: Some(0.), y: Some(8.)}),
    intensity: Some(12.),
  },
  disclaimerBackgroundColor: "#EBE9FF",
  disclaimerTextColor: "#4A40CC",
  instructionalTextColor: "#7A7AAA",
  poweredByTextColor: "#9090B8",
  detailsViewTextKeyColor: "#7A7AAA",
  detailsViewTextValueColor: "#1A1A2E",
  silverBorderColor: "#D4D0FF",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  logoConfig: None,
}

let charcoalRecord = {
  primaryButtonHeight: 48.,
  platform: "android",
  paymentSheetOverlay: "rgba(0,0,0,0.2)",
  bgColor: styles["charcoal_bgColor"],
  loadingBgColor: "#E8E8E8",
  loadingFgColor: "#1A1A1A",
  bgTransparentColor: styles["charcoal_bgTransparentColor"],
  textPrimary: styles["charcoal_textPrimary"],
  textSecondary: styles["charcoal_textSecondary"],
  textSecondaryBold: styles["charcoal_textSecondaryBold"],
  placeholderColor: "#AAAAAA",
  textInputBg: styles["charcoal_textInputBg"],
  iconColor: "rgba(26,26,26,0.35)",
  lineBorderColor: "#D8D8D8",
  linkColor: "#1A1A1A",
  disableBgColor: "#E4E4E4",
  filterHeaderColor: "#555555",
  filterOptionTextColor: ["#1A1A1A", "rgba(26,26,26,0.7)"],
  tooltipTextColor: "#F2F2F2",
  tooltipBackgroundColor: "#1A1A1A",
  boxColor: styles["charcoal_boxColor"],
  boxBorderColor: styles["charcoal_boxBorderColor"],
  dropDownSelectAll: [["#E0E0E0", "#E0E0E0", "#E0E0E0"], ["#EAEAEA", "#EAEAEA", "#EAEAEA"]],
  fadedColor: ["rgba(0,0,0,0.06)", "rgba(0,0,0,0.15)"],
  status_color,
  detailViewToolTipText: "#F2F2F2",
  summarisedViewSingleStatHeading: "#1A1A1A",
  switchThumbColor: "#FFFFFF",
  shimmerColor: ["#E4E4E4", "#EFEFEF"],
  lastOffset: "#F2F2F2",
  dangerColor: "#D32F2F",
  orderDisableButton: "#999999",
  toastColorConfig: {
    backgroundColor: "#1A1A1A",
    textColor: "#F2F2F2",
  },
  primaryColor: "#A1A1A1",
  borderRadius: 12.0,
  borderWidth: 0.0,
  buttonBorderRadius: 12.0,
  buttonBorderWidth: 0.0,
  component: {
    background: "#EAEAEA",
    borderColor: "#E0E0E0",
    dividerColor: "#E4E4E4",
    color: "#1A1A1A",
    selected: {
      background: "#000000",
      borderColor: "#000000",
      borderWidth: 0.0,
      dividerColor: "#333333",
      color: "#FFFFFF",
    },
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
  googlePayButtonColor: #light,
  samsungPayButtonColor: "#1A1A1A",
  payNowButtonColor: "#2A2A2A",
  payNowButtonTextColor: "#FFFFFF",
  payNowButtonBorderColor: "#1A1A1A",
  payNowButtonShadowConfig: {
    color: Some("rgba(0,0,0,0)"),
    opacity: Some(0.),
    blurRadius: Some(0.),
    offset: Some({x: Some(0.), y: Some(0.)}),
    intensity: Some(0.),
  },
  focusedTextInputBoderColor: "#1A1A1A",
  errorTextInputColor: "#D32F2F",
  normalTextInputBoderColor: "#E0E0E0",
  shadowConfig: {
    color: Some("rgba(0,0,0,0.5)"),
    opacity: Some(0.5),
    blurRadius: Some(6.),
    offset: Some({x: Some(0.), y: Some(2.)}),
    intensity: Some(3.),
  },
  disclaimerBackgroundColor: "#E8E8E8",
  disclaimerTextColor: "#555555",
  instructionalTextColor: "#888888",
  poweredByTextColor: "#888888",
  detailsViewTextKeyColor: "#888888",
  detailsViewTextValueColor: "#1A1A1A",
  silverBorderColor: "#D8D8D8",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  logoConfig: None,
}

let softRecord = {
  primaryButtonHeight: 48.,
  platform: "android",
  paymentSheetOverlay: "rgba(49,57,77,0.25)",
  bgColor: styles["soft_bgColor"],
  loadingBgColor: "#CDD5E0",
  loadingFgColor: "#4A90E2",
  bgTransparentColor: styles["soft_bgTransparentColor"],
  textPrimary: styles["soft_textPrimary"],
  textSecondary: styles["soft_textSecondary"],
  textSecondaryBold: styles["soft_textSecondaryBold"],
  placeholderColor: "#9BA5B5",
  textInputBg: styles["soft_textInputBgStyle"],
  iconColor: "rgba(107,114,128,0.5)",
  lineBorderColor: "rgba(163,177,198,0.4)",
  linkColor: "#4A90E2",
  disableBgColor: "#D8E0EC",
  filterHeaderColor: "#6B7280",
  filterOptionTextColor: ["#31394D", "rgba(49,57,77,0.7)"],
  tooltipTextColor: "#FFFFFF",
  tooltipBackgroundColor: "#31394D",
  boxColor: styles["soft_boxColor"],
  boxBorderColor: styles["soft_boxBorderColor"],
  dropDownSelectAll: [["#D8E0EC", "#D8E0EC", "#D8E0EC"], ["#E4EBF5", "#E4EBF5", "#E4EBF5"]],
  fadedColor: ["rgba(163,177,198,0.3)", "rgba(163,177,198,0.6)"],
  status_color,
  detailViewToolTipText: "#FFFFFF",
  summarisedViewSingleStatHeading: "#31394D",
  switchThumbColor: "#FFFFFF",
  shimmerColor: ["#D0D8E8", "#E4EBF5"],
  lastOffset: "#E4EBF5",
  dangerColor: "#E74C3C",
  orderDisableButton: "#A0AABB",
  toastColorConfig: {
    backgroundColor: "#31394D",
    textColor: "#FFFFFF",
  },
  primaryColor: "#4A90E2",
  borderRadius: 15.0,
  borderWidth: 0.0,
  buttonBorderRadius: 15.0,
  buttonBorderWidth: 0.0,
  component: {
    background: "#E4EBF5",
    borderColor: "transparent",
    dividerColor: "rgba(163,177,198,0.4)",
    color: "#31394D",
    selected: {
      background: "#E4EBF5",
      borderColor: "#4A90E2",
      borderWidth: 2.0,
      dividerColor: "rgba(74,144,226,0.3)",
      color: "#4A90E2",
    },
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
  googlePayButtonColor: #light,
  samsungPayButtonColor: "#31394D",
  payNowButtonColor: "#4A90E2",
  payNowButtonTextColor: "#FFFFFF",
  payNowButtonBorderColor: "#3A7BD5",
  payNowButtonShadowConfig: {
    color: Some("rgba(163,177,198,0.6)"),
    opacity: Some(0.4),
    blurRadius: Some(16.),
    offset: Some({x: Some(0.), y: Some(6.)}),
    intensity: Some(8.),
  },
  focusedTextInputBoderColor: "#4A90E2",
  errorTextInputColor: "#E74C3C",
  normalTextInputBoderColor: "transparent",
  shadowConfig: {
    color: Some("rgba(163,177,198,0.6)"),
    opacity: Some(0.6),
    blurRadius: Some(12.),
    offset: Some({x: Some(6.), y: Some(6.)}),
    intensity: Some(6.),
  },
  disclaimerBackgroundColor: "#D8E0EC",
  disclaimerTextColor: "#4A6080",
  instructionalTextColor: "#8090A8",
  poweredByTextColor: "#8090A8",
  detailsViewTextKeyColor: "#8090A8",
  detailsViewTextValueColor: "#31394D",
  silverBorderColor: "rgba(163,177,198,0.5)",
  sheetContentPadding: 20.,
  errorMessageSpacing: 4.,
  logoConfig: None,
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
  walletButtons: SdkTypes.walletButtonsConfiguration,
  locale: option<LocaleDataType.localeTypes>,
  isDarkMode: bool,
) => {
  let appearanceColor: option<SdkTypes.colors> = switch appearance.colors {
  | Some({light, dark}) => isDarkMode ? dark : light
  | None => None
  }
  let btnColor: option<SdkTypes.primaryButtonColor> = switch appearance.primaryButton {
  | Some(btn) =>
    switch btn.primaryButtonColor {
    | Some({light, dark}) => isDarkMode ? dark : light
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

  let gpayOverrideStyle = switch walletButtons.googlePay.buttonStyle {
  | Some(val) => isDarkMode ? val.dark : val.light
  | None => themeObj.googlePayButtonColor
  }

  let applePayOverrideStyle = switch walletButtons.applePay.buttonStyle {
  | Some(val) => isDarkMode ? val.dark : val.light
  | None => themeObj.applePayButtonColor
  }

  let paypalOverrideStyle = switch walletButtons.payPal.buttonStyle {
  | Some(val) => isDarkMode ? val.dark : val.light
  | None => isDarkMode ? WHITE : GOLD
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
      selected: {
        background: getStrProp(
          ~overRideProp=switch appearanceColor {
          | Some(obj) => obj.selectedComponentBackground
          | _ => None
          },
          ~defaultProp=themeObj.component.selected.background,
        ),
        borderColor: getStrProp(
          ~overRideProp=switch appearanceColor {
          | Some(obj) => obj.selectedComponentBorder
          | _ => None
          },
          ~defaultProp=themeObj.component.selected.borderColor,
        ),
        borderWidth: getStrProp(
          ~overRideProp=switch appearanceColor {
          | Some(obj) => obj.selectedComponentBorderWidth
          | _ => None
          },
          ~defaultProp=themeObj.component.selected.borderWidth,
        ),
        dividerColor: getStrProp(
          ~overRideProp=switch appearanceColor {
          | Some(obj) => obj.selectedComponentDivider
          | _ => None
          },
          ~defaultProp=themeObj.component.selected.dividerColor,
        ),
        color: getStrProp(
          ~overRideProp=switch appearanceColor {
          | Some(obj) => obj.selectedComponentText
          | _ => None
          },
          ~defaultProp=themeObj.component.selected.color,
        ),
      },
    },
    locale: switch locale {
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
    paypalButonColor: switch paypalOverrideStyle {
    | BLUE => "blue"
    | WHITE => "white"
    | BLACK => "black"
    | SILVER => "silver"
    | GOLD => "gold"
    },
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
    payNowButtonShadowConfig: {
      color: switch btnShape {
      | Some(obj) =>
        switch obj.shadow {
        | Some(s) => s.color
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.payNowButtonShadowConfig.color),
      opacity: switch btnShape {
      | Some(obj) =>
        switch obj.shadow {
        | Some(s) => s.opacity
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.payNowButtonShadowConfig.opacity),
      blurRadius: switch btnShape {
      | Some(obj) =>
        switch obj.shadow {
        | Some(s) => s.blurRadius
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.payNowButtonShadowConfig.blurRadius),
      offset: switch btnShape {
      | Some(obj) =>
        switch obj.shadow {
        | Some(s) => s.offset
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.payNowButtonShadowConfig.offset),
      intensity: switch btnShape {
      | Some(obj) =>
        switch obj.shadow {
        | Some(s) => s.intensity
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.payNowButtonShadowConfig.intensity),
    },
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
    shadowConfig: {
      color: switch appearance.shapes {
      | Some(shapeObj) =>
        switch shapeObj.shadow {
        | Some(s) => s.color
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.shadowConfig.color),
      opacity: switch appearance.shapes {
      | Some(shapeObj) =>
        switch shapeObj.shadow {
        | Some(s) => s.opacity
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.shadowConfig.opacity),
      blurRadius: switch appearance.shapes {
      | Some(shapeObj) =>
        switch shapeObj.shadow {
        | Some(s) => s.blurRadius
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.shadowConfig.blurRadius),
      offset: switch appearance.shapes {
      | Some(shapeObj) =>
        switch shapeObj.shadow {
        | Some(s) => s.offset
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.shadowConfig.offset),
      intensity: switch appearance.shapes {
      | Some(shapeObj) =>
        switch shapeObj.shadow {
        | Some(s) => s.intensity
        | None => None
        }
      | None => None
      }->Option.orElse(themeObj.shadowConfig.intensity),
    },
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
    logoConfig: appearance.logo->Option.map(logoConfig => {
      let colors =
        logoConfig.colors
        ->Option.flatMap(c => isDarkMode ? c.dark : c.light)
        ->Option.getOr(defaultResolvedLogoConfig.colors)
      let checkedIconForSelection = logoConfig.checkedIconForSelection->Option.map(iconConfig => {
        let iconColors = iconConfig.colors->Option.flatMap(c => isDarkMode ? c.dark : c.light)
        {
          color: iconColors->Option.flatMap(c => c.color)->Option.getOr("green"),
          stroke: ?iconColors->Option.flatMap(c => c.stroke),
          size: iconConfig.size->Option.getOr(18.),
          bottom: iconConfig.bottom->Option.getOr(-2.),
          right: iconConfig.right->Option.getOr(-2.),
        }
      })
      {
        borderRadius: logoConfig.borderRadius->Option.getOr(defaultResolvedLogoConfig.borderRadius),
        colors,
        ?checkedIconForSelection,
      }
    }),
  }
}

//for preDefine light and dark styles
let useThemeBasedStyle = () => {
  let (themeType, _) = React.useContext(ThemeContext.themeContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let themerecord = switch nativeProp.configuration.appearance.theme {
  | FlatMinimal => Some(flatMinimal)
  | Brutal => Some(brutalRecord)
  | Glass => Some(glassRecord)
  | Skeu => Some(skeuRecord)
  | Clay => Some(clayRecord)
  | Charcoal => Some(charcoalRecord)
  | Soft => Some(softRecord)
  | Minimal => Some(minimal)
  | Light => Some(lightRecord)
  | Dark => Some(darkRecord)
  | Default => None
  }
  let themerecordOverridedWithAppObj = switch themeType {
  | Light(appearance) =>
    itemToObj(
      themerecord->Option.getOr(lightRecord),
      appearance,
      nativeProp.configuration.walletButtons,
      nativeProp.configuration.locale,
      false,
    )
  | Dark(appearance) =>
    itemToObj(
      themerecord->Option.getOr(darkRecord),
      appearance,
      nativeProp.configuration.walletButtons,
      nativeProp.configuration.locale,
      true,
    )
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
