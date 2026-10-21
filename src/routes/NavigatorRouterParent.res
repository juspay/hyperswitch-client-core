open ReactNative
open Style

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  <View style={s({flex: 1.})} onStartShouldSetResponderCapture={_ => {SdkFunnelLogger.interaction("touch"); false}}>
    {WebKit.platform === #android && nativeProp.sdkState === PaymentSheet
      ? <StatusBar translucent=true backgroundColor="transparent" />
      : React.null}
    <NavigationRouter />
  </View>
}
