open ReactNative

let animateFlex = (~flexval, ~value, ~endCallback=_ => (), ()) => {
  Animated.timing(
    flexval,
    {
      toValue: {value->Animated.Value.Timing.fromRawValue},
      isInteraction: true,
      useNativeDriver: false,
      delay: 0.,
    },
  )->Animated.start(~endCallback)
}
