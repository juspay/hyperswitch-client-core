open ReactNative
open Style

type textType =
  | HeadingBold
  | Subheading
  | SubheadingBold
  | ModalText
  | ModalTextBold
  | CardText
  | TextActive
  | CustomCssText(ReactNative.Style.t)

@react.component
let make = (~text=?, ~textType: textType, ~children: option<React.element>=?) => {
  let {
    textPrimary,
    textSecondary,
    textSecondaryBold,
    component,
  } = ThemebasedStyle.useThemeBasedStyle()
  let fontFamily = FontFamily.useCustomFontFamily()

  let renderStyle = switch textType {
  | HeadingBold =>
    array([
      textSecondaryBold,
      textStyle(~fontSize=17., ~fontWeight=FontWeight._500, ~letterSpacing=0.3, ()),
    ])
  | Subheading => array([textSecondaryBold, textStyle(~fontSize=15., ())])
  | SubheadingBold =>
    array([textSecondaryBold, textStyle(~fontSize=15., ~fontWeight=FontWeight._500, ())])
  | CardText =>
    array([textStyle(~fontSize=15., ~fontWeight=FontWeight._400, ~color=component.color, ())])
  | ModalText => array([textStyle(~fontSize=14., ~letterSpacing=0.5, ()), textSecondary])
  | ModalTextBold => array([textStyle(~fontSize=14., ()), textSecondary])
  | CustomCssText(styling) => array([styling])
  | TextActive => array([textStyle(~fontSize=14., ~fontWeight=FontWeight._500, ()), textPrimary])
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
