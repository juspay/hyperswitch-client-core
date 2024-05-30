let useCustomFontFamily = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  switch ThemebasedStyle.itemToObj(
    ThemebasedStyle.lightRecord,
    nativeProp.configuration.appearance,
    false,
  ).fontFamily {
  | CustomFont(font) => font
  | DefaultAndroid => "Roboto"
  | DefaultIOS => "System"
  | DefaultWeb => "Inter,-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica Neue,Ubuntu,sans-serif"
  }
}
