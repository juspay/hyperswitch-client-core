open ReactNative
open Style

@react.component
let make = (
  ~elementType: string,
  ~height: float,
  ~placeholder: string,
  ~label: string,
  ~active: bool,
  ~empty: bool,
  ~valid: bool,
  ~iconRight: option<React.element>=?,
  ~useProviderIcon: bool=false,
  ~reference: VaultBindings.fieldRef,
  ~onFocus,
  ~onBlur,
  ~onChange=?,
  ~onReady=?,
  ~options: option<VaultBindings.fieldOptions>=?,
  ~testID: string="",
) => {
  let {
    component,
    dangerColor,
    placeholderColor,
    placeholderTextSizeAdjust,
    fontScale,
  } = ThemebasedStyle.useThemeBasedStyle()
  let fontFamily = FontFamily.useCustomFontFamily()
  let animatedValue = AnimatedValue.useAnimatedValue(0.)
  let lifted = active || !empty
  React.useEffect1(() => {
    Animated.timing(
      animatedValue,
      {
        toValue: (lifted ? 1. : 0.)->Animated.Value.Timing.fromRawValue,
        duration: 200.,
        useNativeDriver: false,
      },
    )->Animated.start
    None
  }, [lifted])
  let inputHeight = height *. 0.7
  let styles: VaultBindings.fieldStyles = {
    container: s({height: inputHeight->dp, width: 100.->pct}),
    input: useProviderIcon
      ? s({
          height: inputHeight->dp,
          width: 100.->pct,
          paddingVertical: 0.->dp,
          color: valid ? component.color : dangerColor,
          fontFamily,
          fontSize: (16. +. placeholderTextSizeAdjust) *. fontScale,
        })
      : s({
          height: inputHeight->dp,
          width: 100.->pct,
          padding: 0.->dp,
          color: valid ? component.color : dangerColor,
          fontFamily,
          fontSize: (16. +. placeholderTextSizeAdjust) *. fontScale,
        }),
  }
  let unstyled = !useProviderIcon
  <>
    <View style={s({flex: 1., height: 100.->pct, justifyContent: #"flex-end"})}>
      <Animated.View
        pointerEvents=#none
        style={s({
          position: #absolute,
          top: 0.->dp,
          height: animatedValue
          ->Animated.Interpolation.interpolate({
            inputRange: [0., 1.],
            outputRange: [
              "100%",
              `${((height +. 10.) /. 1.4)->Float.toString}%`,
            ]->Animated.Interpolation.fromStringArray,
          })
          ->Animated.StyleProp.size,
          justifyContent: #center,
        })}>
        <Animated.Text
          numberOfLines=1
          style={s({
            fontFamily,
            fontWeight: lifted ? #500 : #normal,
            color: placeholderColor,
            fontSize: animatedValue
            ->Animated.Interpolation.interpolate({
              inputRange: [0., 1.],
              outputRange: [
                (16. +. placeholderTextSizeAdjust) *. fontScale,
                11. +. placeholderTextSizeAdjust,
              ]->Animated.Interpolation.fromFloatArray,
            })
            ->Animated.StyleProp.float,
          })}>
          {React.string(lifted ? label : placeholder)}
        </Animated.Text>
      </Animated.View>
      {switch elementType {
      | "cardNumber" =>
        <VaultBindings.CardNumberField
          ref=reference unstyled styles placeholder="" testID onFocus onBlur ?onChange ?onReady
        />
      | "cardExpiry" =>
        <VaultBindings.CardExpiryField
          ref=reference unstyled styles placeholder="" testID onFocus onBlur ?onChange ?onReady
        />
      | _ =>
        <VaultBindings.CardCVCField
          ref=reference
          unstyled
          styles
          placeholder=""
          testID
          onFocus
          onBlur
          ?onChange
          ?onReady
          ?options
        />
      }}
    </View>
    {switch useProviderIcon ? None : iconRight {
    | Some(icon) => <View pointerEvents=#none> icon </View>
    | None => React.null
    }}
  </>
}
