type appObj = SdkTypes.appearance
type themeType = Light(appObj) | Dark(appObj)

let defaultValue: themeType = Light(SdkTypes.defaultAppearance)
let defaultSetter = (_: themeType) => ()
let themeContext = React.createContext((defaultValue, defaultSetter))

module Provider = {
  let make = React.Context.provider(themeContext)
}

@react.component
let make = (~children) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let isDarkMode = LightDarkTheme.useIsDarkMode()
  let (theme, setTheme) = React.useState(_ =>
    isDarkMode
      ? Dark(nativeProp.configuration.appearance)
      : Light(nativeProp.configuration.appearance)
  )
  let setTheme = React.useCallback1(val => {
    setTheme(_ => val)
  }, [setTheme])

  let value = React.useMemo2(() => {
    (theme, setTheme)
  }, (theme, setTheme))

  <Provider value> children </Provider>
}
