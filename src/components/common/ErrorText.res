@react.component
let make = (~text=None) => {
  let {errorTextInputColor} = ThemebasedStyle.useThemeBasedStyle()
  let fontFamily = FontFamily.useCustomFontFamily()

  switch text {
  | None => React.null
  | Some(val) =>
    val == ""
      ? React.null
      : <>
          <TextWrapper textType={ErrorText}> {val->React.string} </TextWrapper>
        </>
  }
}
