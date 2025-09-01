open ReactNative
open Style

@react.component
let make = () => {
  let localeObject = GetLocale.useGetLocalObj()

  <View style={s({flexDirection: #row})}>
    // <Icon name="redirection" width=40. height=35. fill=component.color />
    // <Space width=5. />
    <View>
      <TextWrapper text=localeObject.redirectText textType=ModalText overrideStyle=Some(Style.s({fontWeight: #400})) />
    </View>
  </View>
}
