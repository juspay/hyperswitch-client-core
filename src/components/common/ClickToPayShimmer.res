open ReactNative
open ReactNative.Style

@react.component
let make = () => {
  let {borderRadius} = ThemebasedStyle.useThemeBasedStyle()

  <View style={s({gap: 12.->dp})}>
    <View style={s({gap: 8.->dp})}>
      <CustomLoader height="50" width="100%" radius={Some(borderRadius)} />
      <CustomLoader height="50" width="100%" radius={Some(borderRadius)} />
      <CustomLoader height="50" width="100%" radius={Some(borderRadius)} />
    </View>
  </View>
}
