let convertFontToGoogleFontURL = fontName => {
  let normalizedFontName =
    fontName
    ->String.splitByRegExp(%re("/[_\s]+/"))
    ->Array.map(word =>
      switch word {
      | Some(word) =>
        word->String.charAt(0)->String.toUpperCase ++
          word->String.sliceToEnd(~start=1)->String.toLowerCase
      | None => ""
      }
    )

  Window.useLink(
    `https://fonts.googleapis.com/css2?family=${normalizedFontName->Array.join("+")}`,
  )->ignore
  normalizedFontName->Array.join(" ")
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
  | DefaultWeb => `-apple-system,BlinkMacSystemFont,"Segoe UI","Roboto","Helvetica Neue","Ubuntu",sans-serif`
  }
}
