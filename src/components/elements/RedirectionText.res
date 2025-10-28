open ReactNative
open Style

@react.component
let make = () => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()

  <View style={s({flexDirection: #row, alignItems: #center, paddingHorizontal: 2.->dp})}>
    <Icon name="redirection" width=40. height=35. fill=component.color />
    <Space width=10. />
    <View style={s({flex: 1.})}>
      <TextWrapper text=localeObject.redirectText textType=ModalText />
    </View>
  </View>
}
