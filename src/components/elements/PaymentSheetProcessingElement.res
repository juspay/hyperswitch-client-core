open ReactNative
open Style

@react.component
let make = () => {
  let {primaryColor} = ThemebasedStyle.useThemeBasedStyle()
  let spinnerColor =
    ThemebasedStyle.useAppearanceColors()
    ->Option.flatMap(colors => colors.loaderForeground)
    ->Utils.getNonEmptyOption
    ->Option.getOr(primaryColor)

  <View
    style={s({
      alignItems: #center,
      justifyContent: #center,
      height: 100.->pct,
      width: 100.->pct,
    })}>
    <ActivityIndicator animating=true size=Large color=spinnerColor />
  </View>
}
