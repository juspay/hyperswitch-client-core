open ReactNative
open Style

type textType =
  | HeadingBold
  | Heading
  | Subheading
  | SubheadingBold
  | ModalTextLight
  | ModalText
  | ModalTextBold
  | PlaceholderText
  | PlaceholderTextBold
  | ErrorText
  | ErrorTextBold
  | ButtonText
  | ButtonTextBold
  | LinkText
  | LinkTextBold
  | CardTextBold
  | CardText

@react.component
let make = (
  ~text=?,
  ~textType: textType,
  ~children: option<React.element>=?,
  ~overrideStyle=None,
  ~ellipsizeMode: ReactNative.Text.ellipsizeMode=#tail,
  ~numberOfLines: int=0,
) => {
  let {
    textPrimary,
    textSecondary,
    textSecondaryBold,
    component,
    headingTextSizeAdjust,
    subHeadingTextSizeAdjust,
    placeholderTextSizeAdjust,
    buttonTextSizeAdjust,
    errorTextSizeAdjust,
    linkTextSizeAdjust,
    modalTextSizeAdjust,
    cardTextSizeAdjust,
    payNowButtonTextColor,
    errorTextInputColor,
  } = ThemebasedStyle.useThemeBasedStyle()
  let fontFamily = FontFamily.useCustomFontFamily()

  let renderStyle = switch textType {
  | Heading =>
    array([
      textSecondaryBold,
      textStyle(~fontSize=17. +. headingTextSizeAdjust, ~letterSpacing=0.3, ()),
    ])
  | HeadingBold =>
    array([
      textSecondaryBold,
      textStyle(~fontSize=17. +. headingTextSizeAdjust, ~fontWeight=#600, ~letterSpacing=0.3, ()),
    ])
  | Subheading =>
    array([textSecondaryBold, textStyle(~fontSize=15. +. subHeadingTextSizeAdjust, ())])
  | SubheadingBold =>
    array([
      textSecondary,
      textStyle(~fontSize=15. +. subHeadingTextSizeAdjust, ~fontWeight=#500, ()),
    ])
  | ModalTextLight =>
    array([textStyle(~fontSize=14. +. modalTextSizeAdjust, ~fontWeight=#500, ()), textSecondary])
  | ModalText => array([textStyle(~fontSize=14. +. modalTextSizeAdjust, ()), textSecondaryBold])
  | ModalTextBold =>
    array([
      textStyle(~fontSize=14. +. modalTextSizeAdjust, ~fontWeight=#500, ()),
      textSecondaryBold,
    ])
  | PlaceholderText =>
    array([
      textStyle(
        ~fontStyle=#normal,
        ~fontSize=12. +. placeholderTextSizeAdjust,
        ~marginBottom=2.5->pct,
        (),
      ),
      textPrimary,
    ])
  | PlaceholderTextBold =>
    array([
      textStyle(
        ~fontStyle=#normal,
        ~fontSize=12. +. placeholderTextSizeAdjust,
        ~fontWeight=#500,
        ~marginBottom=2.5->pct,
        (),
      ),
      textPrimary,
    ])
  | ErrorText =>
    array([
      textStyle(
        ~color={errorTextInputColor},
        ~fontFamily,
        ~fontSize=12. +. errorTextSizeAdjust,
        (),
      ),
    ])
  | ErrorTextBold =>
    array([
      textStyle(
        ~color={errorTextInputColor},
        ~fontFamily,
        ~fontSize=12. +. errorTextSizeAdjust,
        ~fontWeight=#500,
        (),
      ),
    ])
  | ButtonText =>
    array([textStyle(~color=payNowButtonTextColor, ~fontSize=17. +. buttonTextSizeAdjust, ())])
  | ButtonTextBold =>
    array([
      textStyle(
        ~color=payNowButtonTextColor,
        ~fontSize=17. +. buttonTextSizeAdjust,
        ~fontWeight=#600,
        (),
      ),
    ])
  | LinkText => array([textStyle(~fontSize=14. +. linkTextSizeAdjust, ()), textPrimary])
  | LinkTextBold =>
    array([textStyle(~fontSize=14. +. linkTextSizeAdjust, ~fontWeight=#500, ()), textPrimary])
  | CardTextBold =>
    array([
      textStyle(~fontSize=14. +. cardTextSizeAdjust, ~fontWeight=#600, ~color=component.color, ()),
    ])
  | CardText =>
    array([
      textStyle(~fontSize=12. +. cardTextSizeAdjust, ~fontWeight=#400, ~color=component.color, ()),
    ])
  }
  // let textTypeString = switch textType {
  // | HeadingBold => "SmallHeadingBold"
  // | Subheading => "Subheading"
  // | SubheadingBold => "SubheadingBold"
  // | ModalText => "ModalText"
  // | ModalTextBold => "ModalTextBold"
  // | CustomCssText(_) => "CustomCssText"
  // | CardText => "CardText"
  // | TextActive => "TextActive"
  // }
  let overrideStyle = switch overrideStyle {
  | Some(val) => val
  | None => viewStyle()
  }
  <Text
    style={array([textStyle(~fontFamily, ()), renderStyle, overrideStyle])}
    ellipsizeMode
    numberOfLines>
    {switch text {
    | Some(text) => React.string(text)
    | None => React.null
    }}
    {switch children {
    | Some(children) => children
    | None => React.null
    }}
  </Text>
}
