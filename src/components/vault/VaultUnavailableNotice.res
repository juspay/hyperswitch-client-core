open ReactNative
open Style

@react.component
let make = (~message: string) => {
  let {dangerColor, gap} = ThemebasedStyle.useThemeBasedStyle()

  <View style={s({marginBottom: gap->dp})}>
    <TextWrapper text=message textType={ModalText} overrideStyle=Some(s({color: dangerColor})) />
  </View>
}
