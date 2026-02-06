open ReactNative
open Style

@react.component
let make = () => {
  let {
    borderWidth,
    borderRadius,
    component,
    shadowIntensity,
    shadowColor,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

  <>
    <Space />
    <View
      style={array([
        getShadowStyle,
        s({
          paddingHorizontal: 24.->dp,
          paddingVertical: 5.->dp,
          borderRadius,
          borderWidth,
          borderColor: component.borderColor,
          backgroundColor: component.background,
        }),
      ])}
    >
      {["loading1", "loading2"]
      ->Array.mapWithIndex((key, i) => {
        <View
          key
          style={s({
            minHeight: 60.->dp,
            paddingVertical: 16.->dp,
            borderBottomWidth: {i < 1 ? 1.0 : 0.},
            borderBottomColor: component.borderColor,
            justifyContent: #center,
          })}
        >
          <View
            style={s({
              flexDirection: #row,
              flexWrap: #wrap,
              alignItems: #center,
              justifyContent: #"space-between",
            })}
          >
            <View style={s({flexDirection: #row, alignItems: #center, maxWidth: 60.->pct})}>
              <CustomLoader height="24" width="24" radius=Some(50.) />
              <Space />
              <View style={s({display: #flex, flexDirection: #column})}>
                <View style={s({display: #flex, flexDirection: #row, alignItems: #center})}>
                  <CustomLoader height="20" width="100" />
                </View>
                <Space height=8. />
                <View style={s({display: #flex, flexDirection: #row, alignItems: #center})}>
                  <CustomLoader height="16" width="24" />
                  <Space width=5. />
                  <CustomLoader height="16" width="60" />
                </View>
              </View>
            </View>
            <CustomLoader height="20" width="48" />
          </View>
        </View>
      })
      ->React.array}
    </View>
    <Space height=20. />
    <Space />
    <CustomLoader width="200" height="20" />
    <Space height=20. />
  </>
}
