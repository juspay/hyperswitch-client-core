open ReactNative
open Style

switch UIManager.setLayoutAnimationEnabledExperimental {
| None => ()
| Some(setEnabled) => setEnabled(true)
}

@react.component
let make = () => {
  let {bgColor, borderRadius} = ThemebasedStyle.useThemeBasedStyle()
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let (nativeProps, _) = React.useContext(NativePropContext.nativePropContext)

  switch loading {
  | ProcessingPayments | ProcessingPaymentsWithOverlay =>
    <Portal>
      <View
        style={array([
          s({
            flex: 1.,
            opacity: loading === ProcessingPaymentsWithOverlay ? 0.90 : 1.0,
            borderRadius,
          }),
          loading === ProcessingPaymentsWithOverlay ? bgColor : s({backgroundColor: "transparent"}),
        ])}
      >
        {switch nativeProps.sdkState {
        | CardWidget | CustomWidget(_) =>
          <View style={s({flex: 1., alignItems: #center, justifyContent: #center})}>
            // <HyperLoaderAnimation shapeSize=20. />
            <CustomLoader />
          </View>

        | ExpressCheckoutWidget =>
          <View
            style={s({
              flex: 1.,
              alignItems: #center,
              justifyContent: #center,
              marginHorizontal: 5.->dp,
            })}
          >
            <CustomLoader height="100%" />
          </View>
        | _ =>
          <>
            // <Animated.View
            //   style={s({
            //     backgroundColor: "#FFB000",
            //     marginVertical: 2.->dp,
            //     borderRadius: 10.,
            //     width: {20.->pct},
            //     height: 2.->dp,
            //     transform=Animated.ValueXY.getTranslateTransform(sliderPosition),
            //   })}
            // />
            <View style={s({flex: 1., justifyContent: #center, alignItems: #center})}>
              // <HyperLoaderAnimation />
              {loading === ProcessingPaymentsWithOverlay
                ? <PaymentSheetProcessingElement />
                : React.null}
            </View>
          </>
        }}
      </View>
    </Portal>

  | PaymentSuccess =>
    switch nativeProps.sdkState {
    | PaymentSheet =>
      <Portal>
        //<SuccessScreen />
        <View style={array([s({flex: 1., opacity: 0.}), bgColor])}>
          <View style={s({flex: 1., justifyContent: #center, alignItems: #center})}>
            // <HyperLoaderAnimation />
          </View>
        </View>
      </Portal>
    | _ => React.null
    }
  | _ => React.null
  }
}
