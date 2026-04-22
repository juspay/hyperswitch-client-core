open ReactNative
open Style

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  <View style={s({flex: 1.})}>
    {WebKit.platform === #android && nativeProp.sdkState === PaymentSheet
      ? <StatusBar translucent=true backgroundColor="transparent" />
      : React.null}
    {switch nativeProp.sdkState {
    | PaymentMethodsManagement => <PMMangementNavigatorRouter />
    | _ => <NavigationRouter />
    }}
  </View>
}
