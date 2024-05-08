open ReactNative
open Style

@react.component
let make = (~text=None) => {
  let {errorTextInputColor} = ThemebasedStyle.useThemeBasedStyle()
  let fontFamily = FontFamily.useCustomFontFamily()

  switch text {
  | None => React.null
  | Some(val) => val == ""
      ? React.null
      : <>
          <Text style={textStyle(~color={errorTextInputColor}, ~fontFamily, ~fontSize=12., ())}>
            {val->React.string}
          </Text>
        </>
  }
}
