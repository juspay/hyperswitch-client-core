open ReactNative
open ReactNative.Style

@react.component
let make = () => {
  let {borderRadius} = ThemebasedStyle.useThemeBasedStyle()

  <View style={s({gap: 12.->dp})}>
    <View style={s({alignItems: #center})}>
      <CustomLoader height="32" width="150" radius={Some(borderRadius)} />
    </View>
    <View style={s({gap: 8.->dp})}>
      <CustomLoader height="50" width="100%" radius={Some(borderRadius)} />
      <CustomLoader height="50" width="100%" radius={Some(borderRadius)} />
      <CustomLoader height="50" width="100%" radius={Some(borderRadius)} />
    </View>
    <CustomLoader height="48" width="100%" radius={Some(borderRadius)} />
    <CustomLoader height="24" width="80%" radius={Some(borderRadius)} />
  </View>
}
