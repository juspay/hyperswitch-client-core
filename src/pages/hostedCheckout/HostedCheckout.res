open ReactNative
open Style

@react.component
let make = () => {
  let {bgColor} = ThemebasedStyle.useThemeBasedStyle()
  let useMediaView = WindowDimension.useMediaView()
  let isMobileView = WindowDimension.useIsMobileView()
  let parentViewStyle = switch useMediaView() {
  | Mobile => empty
  | _ => s({flexDirection: #row})
  }
  let sdkViewStyle = switch useMediaView() {
  | Mobile => empty
  | _ =>
    s({
      flex: 1.,
      alignItems: #center,
      justifyContent: #center,
      shadowOffset: {width: -7.5, height: 0.},
      shadowRadius: 20.,
      shadowColor: "rgba(1,1,1,0.027)",
      padding: 32.->dp,
    })
  }

  let checkoutViewStyle = switch useMediaView() {
  | Mobile => empty
  | _ =>
    s({
      flex: 1.,
      marginHorizontal: 80.->dp,
      alignItems: #center,
      justifyContent: #"space-around",
      paddingVertical: 30.->dp,
    })
  }

  <View style={array([s({flex: 1.}), bgColor])}>
    <ScrollView
      keyboardShouldPersistTaps={#handled}
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={s({flexGrow: 1., paddingBottom: 40.->dp})}>
      <View style={array([parentViewStyle, s({flex: 1., marginHorizontal: 15.->dp})])}>
        <View style={checkoutViewStyle}>
          <CheckoutView />
          {isMobileView ? React.null : <CheckoutView.TermsView />}
        </View>
        <View style={array([bgColor, sdkViewStyle])}>
          <HostedCheckoutSdk />
        </View>
      </View>
    </ScrollView>
  </View>
}
