// let useIsDarkMode = () => {
//   let (theme, _) = React.useContext(ThemeContext.themeContext)
//   theme->Option.getOr(#dark) == #dark
// }
open ReactNative
let useIsDarkMode = () => {
  switch Appearance.useColorScheme()->Option.getOr(#light) {
  | #dark => true
  | #light => false
  }
}
