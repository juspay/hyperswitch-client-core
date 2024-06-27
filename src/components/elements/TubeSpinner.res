open ReactNative
open Style

external toString: 'a => string = "%identity"

module Svg = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~uri: string=?,
    ~width: float=?,
    ~viewBox: string=?,
    ~height: float=?,
    ~fill: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
    ~children: React.element=?,
  ) => React.element = "Svg"
}

module Defs = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~uri: string=?,
    ~width: string=?,
    ~viewBox: string=?,
    ~height: string=?,
    ~fill: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
    ~children: React.element=?,
  ) => React.element = "Defs"
}

module RadialGradient = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~id: string=?,
    ~cx: string=?,
    ~cy: string=?,
    ~fx: string=?,
    ~fy: string=?,
    ~uri: string=?,
    ~gradientTransform: string=?,
    ~width: float=?,
    ~height: float=?,
    ~fill: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
    ~children: React.element=?,
  ) => React.element = "RadialGradient"
}

module Stop = {
  @module("react-native-svg/src") @react.component
  external make: (~offset: string, ~stopColor: string, ~stopOpacity: string=?) => React.element =
    "Stop"
}

module Circle = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~uri: string=?,
    ~cx: string=?,
    ~cy: string=?,
    ~r: string=?,
    ~fill: string=?,
    ~opacity: string=?,
    ~stroke: string=?,
    ~strokeWidth: string=?,
    ~strokeLinecap: string=?,
    ~strokeDasharray: string=?,
    ~strokeDashoffset: string=?,
    ~transformOrigin: string=?,
    ~origin: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
  ) => React.element = "Circle"
}

module AnimateTransform = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~attributeName: string=?,
    ~\"type": string=?,
    ~from: string=?,
    ~to: string=?,
    ~dur: string=?,
    ~repeatCount: string=?,
    ~values: string=?,
    ~keyTimes: string=?,
    ~keySplines: string=?,
    ~uri: string=?,
    ~width: float=?,
    ~height: float=?,
    ~fill: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
  ) => React.element = "AnimateTransform"
}

@react.component
let make = (~loaderColor=?, ~size=?) => {
  let {primaryColor, iconColor} = ThemebasedStyle.useThemeBasedStyle()
  let iconColor = switch loaderColor {
  | Some(color) => color
  | None => iconColor
  }

  let size = switch size {
  | Some(size) => size
  | None => 180.
  }

  // let iconColor = "#2347FF"
  let rotateSpin = React.useRef(Animated.Value.create(0.)).current

  let angleSpinValue = Animated.Interpolation.interpolate(
    rotateSpin,
    {
      inputRange: [0., 1.],
      outputRange: ["0deg", "360deg"]->Animated.Interpolation.fromStringArray,
    },
  )

  React.useEffect1(() => {
    Animated.loop(
      Animated.timing(
        rotateSpin,
        Animated.Value.Timing.config(
          ~toValue=-1.->Animated.Value.Timing.fromRawValue,
          ~isInteraction=true,
          ~useNativeDriver=false,
          ~delay=0.,
          ~duration=800.,
          ~easing=Easing.linear,
          (),
        ),
      ),
    )->Animated.start()
    None
  }, [rotateSpin])
  <View>
    <Animated.View
      style={viewStyle(~transform=[rotate(~rotate=angleSpinValue->Animated.StyleProp.angle)], ())}>
      <Svg width=size height=size viewBox="0 0 200 200">
        <Defs>
          <RadialGradient
            id="a12" cx="0.66" fx="0.66" cy="0.3125" fy="0.3125" gradientTransform="scale(1.5)">
            <Stop offset="0" stopColor={iconColor} />
            <Stop offset="0.3" stopColor={iconColor} stopOpacity="0.9" />
            <Stop offset="0.6" stopColor={iconColor} stopOpacity="0.6" />
            <Stop offset="0.8" stopColor={iconColor} stopOpacity="0.3" />
            <Stop offset="1" stopColor={iconColor} stopOpacity="0" />
          </RadialGradient>
        </Defs>
        <Circle
          cx="100"
          cy="100"
          r="70"
          fill="none"
          stroke="url(#a12)"
          strokeWidth="15"
          strokeLinecap="round"
          strokeDasharray="200 1000"
          strokeDashoffset="0"
          origin="100, 100"
        />
        <Circle
          cx="100"
          cy="100"
          r="70"
          fill="none"
          opacity="0.2"
          stroke={iconColor}
          strokeWidth="15"
          strokeLinecap="round"
        />
      </Svg>
    </Animated.View>
  </View>
}
