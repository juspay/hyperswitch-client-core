type appObj = SdkTypes.appearance
type themeType = Light(appObj) | Dark(appObj)

let defaultValue: themeType = Light(SdkTypes.defaultAppearance)
let defaultSetter = (_: themeType) => ()
let themeContext = React.createContext((defaultValue, defaultSetter))

module Provider = {
  let make = React.Context.provider(themeContext)
}

@react.component
let make = (~children, ~appearance: SdkTypes.appearance) => {
  let isDarkMode = LightDarkTheme.useIsDarkMode()
  let (theme, setTheme) = React.useState(_ =>
    switch appearance.theme {
    | Default => isDarkMode ? Dark(appearance) : Light(appearance)
    | Dark => Dark(appearance)
    | _ => Light(appearance)
    }
  )
  let setTheme = React.useCallback1(val => {
    setTheme(_ => val)
  }, [setTheme])

  let value = React.useMemo2(() => {
    (theme, setTheme)
  }, (theme, setTheme))

  <Provider value> children </Provider>
}
