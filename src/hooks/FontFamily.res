let convertFontToGoogleFontURL = fontName => {
  let normalizedFontName =
    fontName
    ->String.splitByRegExp("/[_\s]+/"->RegExp.fromString)
    ->Array.map(word =>
      switch word {
      | Some(word) =>
        word->String.charAt(0)->String.toUpperCase ++
          word->String.slice(~start=1, ~end=word->String.length)->String.toLowerCase
      | None => ""
      }
    )
    ->Array.join("+")

  Window.useLink(`https://fonts.googleapis.com/css2?family=${normalizedFontName}`)->ignore
  normalizedFontName
}

let useCustomFontFamily = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  switch ThemebasedStyle.itemToObj(
    ThemebasedStyle.lightRecord,
    nativeProp.configuration.appearance,
    false,
  ).fontFamily {
  | CustomFont(font) =>
    if ReactNative.Platform.os === #web {
      convertFontToGoogleFontURL(font)
    } else {
      font
    }
  | DefaultAndroid => "Roboto"
  | DefaultIOS => "System"
  | DefaultWeb => "Inter,-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica Neue,Ubuntu,sans-serif"
  }
}
