open ReactNative
open Style
open ReactNativeSvg

@react.component
let make = (~loaderColor=?, ~size=?) => {
  let {iconColor} = ThemebasedStyle.useThemeBasedStyle()
  let iconColor = switch loaderColor {
  | Some(color) => color
  | None => iconColor
  }

  let size = switch size {
  | Some(size) => size
  | None => 180.
  }

  let rotateSpin = AnimatedValue.useAnimatedValue(0.)

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
        {
          toValue: -1.->Animated.Value.Timing.fromRawValue,
          isInteraction: true,
          useNativeDriver: false,
          delay: 0.,
          duration: 800.,
          easing: Easing.linear,
        },
      ),
    )->Animated.start
    None
  }, [rotateSpin])
  <View>
    <Animated.View
      style={s({transform: [rotate(~rotate=angleSpinValue->Animated.StyleProp.angle)]})}
    >
      <Svg width=size height=size viewBox="0 0 200 200">
        <Defs>
          <RadialGradient
            id="a12" cx="0.66" fx="0.66" cy="0.3125" fy="0.3125" gradientTransform="scale(1.5)"
          >
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
