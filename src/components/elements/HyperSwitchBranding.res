open ReactNative
open Style
@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  <UIUtils.RenderIf condition={!nativeProp.hyperParams.disableBranding}>
    <Space />
    <View style={viewStyle(~alignItems=#center, ())}>
      <View
        style={viewStyle(
          ~flexDirection=#row,
          ~display={#flex},
          ~alignItems=#center,
          ~justifyContent=#center,
          (),
        )}>
        <TextWrapper textType={Heading}>
          {"powered by "->React.string}
        </TextWrapper>
        <TextWrapper textType={HeadingBold}>
          {"Hyperswitch"->React.string}
        </TextWrapper>
      </View>
      // <Icon
      //   name={switch themeType {
      //   | Light(_) => "hyperswitch"
      //   | Dark(_) => "hyperswitchdark"
      //   }}
      //   width=180.
      //   height=20.
      // />
      <Space height=10. />
    </View>
  </UIUtils.RenderIf>
}
