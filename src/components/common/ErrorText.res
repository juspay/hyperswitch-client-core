open ReactNative
open Style

@react.component
let make = (~text) => {
  let {errorTextInputColor} = ThemebasedStyle.useThemeBasedStyle()
  let fontFamily = FontFamily.useCustomFontFamily()

  switch text {
  | "" => React.null
  | val =>
    <>
      <Space height=4. />
      <Text style={textStyle(~color={errorTextInputColor}, ~fontFamily, ~fontSize=12., ())}>
        {val->React.string}
      </Text>
      <Space />
    </>
  }
}
