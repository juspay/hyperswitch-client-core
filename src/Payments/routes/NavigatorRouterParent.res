open ReactNative
open Style

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  <View style={s({flex: 1.})}>
    {WebKit.platform === #android && nativeProp.sdkState === PaymentSheet
      ? <StatusBar translucent=true backgroundColor="transparent" />
      : React.null}
    // PMM states are unreachable in this bundle: the PMM flow ships in its own
    // bundle (`hyperPMM` component) since the JS bundle split. NavigationRouter
    // already renders React.null for those states, so no branch is needed here.
    <NavigationRouter />
  </View>
}
