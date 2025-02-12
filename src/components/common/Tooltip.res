open ReactNative
open Style

@react.component
let make = (~children, ~onClickOutside=_ => (), ~backgroundColor=?, ~top, ~right) => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let {shadowColor, shadowIntensity} = ThemebasedStyle.useThemeBasedStyle()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

  <Portal>
    <CustomTouchableOpacity
      onPress={event => onClickOutside(event)} style={viewStyle(~flex=1., ())}>
      <SafeAreaView />
      <View
        style={array([
          viewStyle(
            ~position=#absolute,
            ~top=top->dp,
            ~right=right->dp,
            ~margin=10.->dp,
            ~paddingHorizontal=20.->dp,
            ~paddingVertical=10.->dp,
            ~maxHeight=180.->dp,
            ~backgroundColor={
              switch backgroundColor {
              | Some(color) => color
              | None => component.background
              }
            },
            ~borderRadius=8.,
            (),
          ),
          shadowStyle,
        ])}>
        {children}
      </View>
    </CustomTouchableOpacity>
  </Portal>
}
