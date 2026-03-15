type fontFamilyTypes = DefaultIOS | DefaultAndroid | CustomFont(string) | DefaultWeb

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
type primaryButtonColorType =
  | PrimaryButtonColor(option<primaryButtonColor>)
  | PrimaryButtonDefault({light: option<primaryButtonColor>, dark: option<primaryButtonColor>})

type primaryButton = {
  shapes: option<shapes>,
  primaryButtonColor: option<primaryButtonColorType>,
}

type googlePayButtonType = BUY | BOOK | CHECKOUT | DONATE | ORDER | PAY | SUBSCRIBE | PLAIN

type googlePayThemeBaseStyle = {
  light: ReactNative.Appearance.t,
  dark: ReactNative.Appearance.t,
}

type googlePayConfiguration = {
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

type applePayThemeBaseStyle = {
  light: applePayButtonStyle,
  dark: applePayButtonStyle,
}

type applePayConfiguration = {
  buttonType: applePayButtonType,
  buttonStyle: option<applePayThemeBaseStyle>,
}

type themeType = Default | Light | Dark | Minimal | FlatMinimal
type layoutType = Tab | Accordion | SpacedAccordion

type appearance = {
  locale: option<LocaleDataType.localeTypes>,
  colors: option<colorType>,
  shapes: option<shapes>,
  font: option<font>,
  primaryButton: option<primaryButton>,
  googlePay: googlePayConfiguration,
  applePay: applePayConfiguration,
  theme: themeType,
  layout: layoutType,
}
