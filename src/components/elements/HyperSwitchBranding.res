open ReactNative
open Style
@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (themeType, _) = React.useContext(ThemeContext.themeContext)

  <UIUtils.RenderIf condition={!nativeProp.hyperParams.disableBranding}>
    <Space />
    <View style={s({alignItems: #center})}>
      <Icon
        name={switch themeType {
        | Light(_) => "hyperswitch"
        | Dark(_) => "hyperswitchdark"
        }}
        width=180.
        height=20.
      />
    </View>
  </UIUtils.RenderIf>
}
