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
    errorMessageSpacing,
    fontScale,
  } = ThemebasedStyle.useThemeBasedStyle()
  let fontFamily = FontFamily.useCustomFontFamily()

  let renderStyle = switch textType {
  | Heading =>
    array([
      textSecondaryBold,
      s({fontSize: (17. +. headingTextSizeAdjust) *. fontScale, letterSpacing: 0.3}),
    ])
  | HeadingBold =>
    array([
      textSecondaryBold,
      s({
        fontSize: (17. +. headingTextSizeAdjust) *. fontScale,
        fontWeight: #600,
        letterSpacing: 0.3,
      }),
    ])
  | Subheading =>
    array([textSecondaryBold, s({fontSize: (15. +. subHeadingTextSizeAdjust) *. fontScale})])
  | SubheadingBold =>
    array([
      textSecondary,
      s({fontSize: (15. +. subHeadingTextSizeAdjust) *. fontScale, fontWeight: #500}),
    ])
  | ModalTextLight =>
    array([
      s({fontSize: (14. +. modalTextSizeAdjust) *. fontScale, fontWeight: #500}),
      textSecondary,
    ])
  | ModalText =>
    array([s({fontSize: (14. +. modalTextSizeAdjust) *. fontScale}), textSecondaryBold])
  | ModalTextBold =>
    array([
      s({fontSize: (14. +. modalTextSizeAdjust) *. fontScale, fontWeight: #500}),
      textSecondaryBold,
    ])
  | PlaceholderText =>
    array([
      s({
        fontStyle: #normal,
        fontSize: (12. +. placeholderTextSizeAdjust) *. fontScale,
        marginBottom: 2.5->pct,
      }),
      textPrimary,
    ])
  | PlaceholderTextBold =>
    array([
      s({
        fontStyle: #normal,
        fontSize: (12. +. placeholderTextSizeAdjust) *. fontScale,
        fontWeight: #500,
        marginBottom: 2.5->pct,
      }),
      textPrimary,
    ])
  | ErrorText =>
    array([
      s({
        color: errorTextInputColor,
        fontFamily,
        fontSize: (12. +. errorTextSizeAdjust) *. fontScale,
        marginTop: errorMessageSpacing->dp,
      }),
    ])
  | ErrorTextBold =>
    array([
      s({
        color: errorTextInputColor,
        fontFamily,
        fontSize: (12. +. errorTextSizeAdjust) *. fontScale,
        fontWeight: #500,
      }),
    ])
  | ButtonText =>
    array([s({color: payNowButtonTextColor, fontSize: (17. +. buttonTextSizeAdjust) *. fontScale})])
  | ButtonTextBold =>
    array([
      s({
        color: payNowButtonTextColor,
        fontSize: (17. +. buttonTextSizeAdjust) *. fontScale,
        fontWeight: #600,
      }),
    ])
  | LinkText => array([s({fontSize: (14. +. linkTextSizeAdjust) *. fontScale}), textPrimary])
  | LinkTextBold =>
    array([s({fontSize: (16. +. linkTextSizeAdjust) *. fontScale, fontWeight: #600}), textPrimary])
  | CardTextBold =>
    array([
      s({
        fontSize: (14. +. cardTextSizeAdjust) *. fontScale,
        fontWeight: #600,
        color: component.color,
      }),
    ])
  | CardText =>
    array([
      s({
        fontSize: (12. +. cardTextSizeAdjust) *. fontScale,
        fontWeight: #400,
        color: component.color,
      }),
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
  | None => empty
  }
  <Text
    style={array([s({fontFamily: fontFamily}), renderStyle, overrideStyle])}
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
