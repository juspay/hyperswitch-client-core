open ReactNative
open Style

@react.component
let make = () => {
  let mediaView = WindowDimension.useMediaView()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity=16., ~shadowColor="#0000000f", ())

  let isDesktop = mediaView === Desktop

  <ScrollView
    keyboardShouldPersistTaps={#handled}
    showsVerticalScrollIndicator=false
    contentContainerStyle={array([s({flexGrow: 1., alignItems: #center})])}>
    {isDesktop
      ? <View
          style={array([
            s({
              position: #absolute,
              width: 50.->pct,
              height: 100.->pct,
              top: 0.->dp,
              right: 0.->dp,
            }),
            shadowStyle,
          ])}
        />
      : React.null}
    <View
      style={array([
        s({
          flex: 1.,
          flexDirection: isDesktop ? #row : #column,
          width: isDesktop ? auto : 100.->pct,
          gap: {isDesktop ? 100. : 10.}->dp,
        }),
      ])}>
      <View style={s({zIndex: 999})}>
        <CheckoutView isDesktop />
      </View>
      <View style={s({maxWidth: 380.->dp})}>
        <ParentPaymentSheet />
      </View>
    </View>
  </ScrollView>
}
