open ReactNative
open Style

@react.component
let make = () => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()

  <View style={viewStyle(~flexDirection=#row, ())}>
    <Icon name="redirection" width=40. height=35. fill=component.color />
    <Space width=10. />
    <View style={viewStyle(~width=90.->pct, ())}>
      <TextWrapper text=localeObject.redirectText textType=ModalText />
    </View>
  </View>
}
