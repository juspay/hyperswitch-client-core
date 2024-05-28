open ReactNative
open Style

type textType =
  | HeadingBold
  | Heading
  | Subheading
  | SubheadingBold
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
  | CardText

@react.component
let make = (~text=?, ~textType: textType, ~children: option<React.element>=?) => {
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
      textStyle(~fontSize=17. +. headingTextSizeAdjust, ~letterSpacing=0.3, ())
    ])
  | HeadingBold =>
    array([
      textSecondaryBold,
      textStyle(~fontSize=17. +. headingTextSizeAdjust, ~fontWeight=FontWeight._500, ~letterSpacing=0.3, ()),
    ])
  | Subheading => array([textSecondaryBold, textStyle(~fontSize=15. +. subHeadingTextSizeAdjust, ())])
  | SubheadingBold =>
    array([textSecondaryBold, textStyle(~fontSize=15. +. subHeadingTextSizeAdjust, ~fontWeight=FontWeight._500, ())])
  | ModalText => array([textStyle(~fontSize=14. +. modalTextSizeAdjust, ~letterSpacing=0.5, ()), textSecondary])
  | ModalTextBold => array([textStyle(~fontSize=14. +. modalTextSizeAdjust, ~fontWeight=FontWeight._500, ()), textSecondary])
  | PlaceholderText => 
    array([
      textStyle(~fontStyle=#normal, ~fontSize=12. +. placeholderTextSizeAdjust, ~marginBottom=2.5->pct, ()),
      textPrimary,
    ])
  | PlaceholderTextBold => 
    array([
      textStyle(~fontStyle=#normal, ~fontSize=12. +. placeholderTextSizeAdjust, ~fontWeight=FontWeight._500, ~marginBottom=2.5->pct, ()),
      textPrimary,
    ])
  | ErrorText => array([textStyle(~color={errorTextInputColor}, ~fontFamily, ~fontSize=12. +. errorTextSizeAdjust, ())])
  | ErrorTextBold => array([textStyle(~color={errorTextInputColor}, ~fontFamily, ~fontSize=12. +. errorTextSizeAdjust, ~fontWeight=FontWeight._500, ())])
  | ButtonText => 
    array([
      textStyle(~color=payNowButtonTextColor, ~fontSize=17. +. buttonTextSizeAdjust, ()),
    ])
  | ButtonTextBold => array([textStyle(~color=payNowButtonTextColor, ~fontSize=17. +. buttonTextSizeAdjust, ~fontWeight=FontWeight._400, ())])
  | LinkText => array([textStyle(~fontSize=14. +. linkTextSizeAdjust, ()), textPrimary])
  | LinkTextBold => array([textStyle(~fontSize=14. +. linkTextSizeAdjust, ~fontWeight=FontWeight._500, ()), textPrimary])
  | CardText =>
    array([textStyle(~fontSize=15. +. cardTextSizeAdjust, ~fontWeight=FontWeight._400, ~color=component.color, ())])
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
  <Text style={array([textStyle(~fontFamily, ()), renderStyle])}>
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
