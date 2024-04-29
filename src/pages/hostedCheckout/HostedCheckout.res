open ReactNative
open Style

@react.component
let make = () => {
  let {bgColor} = ThemebasedStyle.useThemeBasedStyle()
  let useMediaView = WindowDimension.useMediaView()
  let isMobileView = WindowDimension.useIsMobileView()
  let parentViewStyle = switch useMediaView() {
  | Mobile => viewStyle()
  | _ => viewStyle(~flexDirection=#row, ())
  }
  let sdkViewStyle = switch useMediaView() {
  | Mobile => viewStyle()
  | _ =>
    viewStyle(
      ~flex=1.,
      ~alignItems=#center,
      ~justifyContent=#center,
      ~shadowOffset=offset(~width=-7.5, ~height=0.),
      ~shadowRadius=20.,
      ~shadowColor="rgba(1,1,1,0.027)",
      (),
    )
  }

  let checkoutViewStyle = switch useMediaView() {
  | Mobile => viewStyle()
  | _ =>
    viewStyle(
      ~flex=1.,
      ~marginHorizontal=80.->dp,
      ~alignItems=#center,
      ~justifyContent=#"space-around",
      ~paddingVertical=30.->dp,
      (),
    )
  }

  <View style={array([viewStyle(~flex=1., ()), bgColor])}>
    <ScrollView
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={viewStyle(~flexGrow=1., ~paddingBottom=40.->dp, ())}>
      <View style={array([parentViewStyle, viewStyle(~flex=1., ~marginHorizontal=15.->dp, ())])}>
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
