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

  {
    switch loading {
    | ProcessingPayments(val) =>
      <View
        style={array([
          viewStyle(
            ~width=100.->pct,
            ~height=100.->pct,
            ~position=#absolute,
            ~opacity=val->Option.isSome ? 0.90 : 1.0,
            ~borderRadius,
            (),
          ),
          val->Option.isSome ? bgColor : viewStyle(~backgroundColor="transparent", ()),
        ])}>
        {switch nativeProps.sdkState {
        | CardWidget | CustomWidget(_) =>
          <View style={viewStyle(~flex=1., ~alignItems=#center, ~justifyContent=#center, ())}>
            // <HyperLoaderAnimation shapeSize=20. />
          </View>
        | _ =>
          <>
            // <Animated.View
            //   style={viewStyle(
            //     ~backgroundColor="#FFB000",
            //     ~marginVertical=2.->dp,
            //     ~borderRadius=10.,
            //     ~width={20.->pct},
            //     ~height=2.->dp,
            //     ~transform=Animated.ValueXY.getTranslateTransform(sliderPosition),
            //     (),
            //   )}
            // />
            <View style={viewStyle(~flex=1., ~justifyContent=#center, ~alignItems=#center, ())}>
              // <HyperLoaderAnimation />
              {switch val {
              | Some(val) => val.showOverlay ? <PaymentSheetProcessingElement /> : React.null
              | None => React.null
              }}
            </View>
          </>
        }}
      </View>

    | PaymentSuccess =>
      switch nativeProps.sdkState {
      | PaymentSheet =>
        //<SuccessScreen />
        <View
          style={array([
            viewStyle(~width=100.->pct, ~height=100.->pct, ~position=#absolute, ~opacity=0., ()),
            bgColor,
          ])}>
          <View style={viewStyle(~flex=1., ~justifyContent=#center, ~alignItems=#center, ())}>
            // <HyperLoaderAnimation />
          </View>
        </View>
      | _ => React.null
      }
    | _ => React.null
    }
  }
}
