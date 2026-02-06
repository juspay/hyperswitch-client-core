open ReactNative
open Style

@react.component
let make = (~children) => {
  let sheetFlex = AnimatedValue.useAnimatedValue(0.)
  React.useEffect0(() => {
    Animated.timing(
      sheetFlex,
      {
        toValue: {1.->Animated.Value.Timing.fromRawValue},
        isInteraction: true,
        useNativeDriver: false,
      },
    )->Animated.start
    None
  })

  <View
    style={s({
      flex: 1.,
      alignContent: #center,
      backgroundColor: "transparent",
      justifyContent: #center,
    })}
  >
    <Animated.View style={s({maxHeight: 100.->pct})}>
      <CustomView.WidgetWrapper> {children} </CustomView.WidgetWrapper>
    </Animated.View>
    <LoadingOverlay />
  </View>
}
