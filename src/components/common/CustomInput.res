open ReactNative
open Style

external toSize: Animated.Interpolation.t => size = "%identity"
external toFloat: Animated.Interpolation.t => float = "%identity"
external toString: Animated.Interpolation.t => string = "%identity"

type iconType =
  | NoIcon
  | CustomIcon(React.element)

@react.component
let make = (
  ~state,
  ~setState,
  ~placeholder="Enter the text here",
  ~placeholderTextColor=None,
  ~width=100.->pct,
  ~height: float=46.,
  ~secureTextEntry=false,
  ~keyboardType=#default,
  ~iconLeft: iconType=NoIcon,
  ~iconRight: iconType=NoIcon,
  ~multiline: bool=false,
  ~heading="",
  ~mandatory=false,
  ~reference=None,
  ~autoFocus=false,
  ~clearTextOnFocus=false,
  ~maxLength=None,
  ~onKeyPress=?,
  ~enableCrossIcon=true,
  ~textAlign=None,
  ~onPressIconRight=?,
  ~isValid=true,
  ~showEyeIconaftersecureTextEntry=false,
  ~borderTopWidth=1.,
  ~borderBottomWidth=1.,
  ~borderLeftWidth=1.,
  ~borderRightWidth=1.,
  ~borderTopLeftRadius=7.,
  ~borderTopRightRadius=7.,
  ~borderBottomLeftRadius=7.,
  ~borderBottomRightRadius=7.,
  ~onFocus=() => (),
  ~onBlur=() => (),
  ~textColor="black",
  ~editable=true,
  ~pointerEvents=#auto,
  ~fontSize=16.,
  ~enableShadow=true,
  ~animate=true,
  ~animateLabel=?,
) => {
  let {
    placeholderColor,
    bgColor,
    primaryColor,
    errorTextInputColor,
    normalTextInputBoderColor,
    component,
    shadowColor,
    shadowIntensity,
    placeholderTextSizeAdjust,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

  let (showPass, setShowPass) = React.useState(_ => secureTextEntry)
  let (isFocused, setIsFocused) = React.useState(_ => false)
  let logger = LoggerHook.useLoggerHook()
  let fontFamily = FontFamily.useCustomFontFamily()

  // let focusedTextInputBoderColor = "rgba(0, 153, 255, 1)"
  // let errorTextInputColor = "rgba(218, 14, 15, 1)"
  // let normalTextInputBoderColor = "rgba(204, 210, 226, 0.75)"
  // let _ = state != "" && secureTextEntry == false && enableCrossIcon
  let shadowStyle = enableShadow ? getShadowStyle : viewStyle()

  let animatedValue = React.useRef(Animated.Value.create(state != "" ? 1. : 0.)).current

  React.useEffect2(() => {
    Animated.timing(
      animatedValue,
      {
        toValue: if (isFocused || state != "") && animate {
          1.->Animated.Value.Timing.fromRawValue
        } else {
          0.->Animated.Value.Timing.fromRawValue
        },
        duration: 200.,
        useNativeDriver: false,
      },
    )->Animated.start()

    None
  }, (isFocused, state))

  <View style={viewStyle(~width=100.->pct, ())}>
    {heading != ""
      ? <TextWrapper textType={PlaceholderText}>
          {React.string(heading)}
          {mandatory
            ? <TextWrapper textType={ErrorText}> {" *"->React.string} </TextWrapper>
            : React.null}
        </TextWrapper>
      : React.null}
    <View
      style={array([
        bgColor,
        viewStyle(
          ~backgroundColor=component.background,
          ~borderTopWidth,
          ~borderBottomWidth,
          ~borderLeftWidth,
          ~borderRightWidth,
          ~borderTopLeftRadius,
          ~borderTopRightRadius,
          ~borderBottomLeftRadius,
          ~borderBottomRightRadius,
          ~height=height->dp,
          ~flexDirection=#row,
          ~borderColor=isValid
            ? isFocused ? primaryColor : normalTextInputBoderColor
            : errorTextInputColor,
          ~width,
          ~paddingHorizontal=13.->dp,
          ~alignItems=#center,
          ~justifyContent=#center,
          (),
        ),
        shadowStyle,
        // bgColor,
      ])}>
      {switch iconLeft {
      | CustomIcon(element) => <View style={viewStyle(~paddingRight=10.->dp, ())}> element </View>
      | NoIcon => React.null
      }}
      <View
        style={viewStyle(
          ~flex=1.,
          ~position=#relative,
          ~height=100.->pct,
          ~justifyContent={
            animate ? #"flex-end" : #center
          },
          (),
        )}>
        {animate
          ? <Animated.View
              pointerEvents=#none
              style={viewStyle(
                ~top=0.->dp,
                ~position=#absolute,
                ~height=animatedValue
                ->Animated.Interpolation.interpolate({
                  inputRange: [0., 1.],
                  outputRange: ["100%", "40%"]->Animated.Interpolation.fromStringArray,
                })
                ->toSize,
                ~justifyContent=#center,
                (),
              )}>
              <Animated.Text
                style={array([
                  textStyle(
                    ~fontFamily,
                    ~fontWeight=if isFocused || state != "" {
                      #500
                    } else {
                      #normal
                    },
                    ~fontSize=animatedValue
                    ->Animated.Interpolation.interpolate({
                      inputRange: [0., 1.],
                      outputRange: [
                        fontSize +. placeholderTextSizeAdjust,
                        fontSize +. placeholderTextSizeAdjust -. 5.,
                      ]->Animated.Interpolation.fromFloatArray,
                    })
                    ->toFloat,
                    ~color=placeholderTextColor->Option.getOr(placeholderColor),
                    (),
                  ),
                ])}>
                {React.string({
                  if isFocused || state != "" {
                    animateLabel->Option.getOr(placeholder) ++ (mandatory ? "*" : "")
                  } else {
                    placeholder
                  }
                })}
              </Animated.Text>
            </Animated.View>
          : React.null}
        <TextInput
          ref=?reference
          style={array([
            textStyle(
              ~fontStyle=#normal,
              ~color=textColor,
              ~fontFamily,
              ~fontSize={fontSize +. placeholderTextSizeAdjust},
              ~textAlign?,
              (),
            ),
            viewStyle(~padding=0.->dp, ~height=(height -. 10.)->dp, ~width=100.->pct, ()),
          ])}
          secureTextEntry=showPass
          autoCapitalize=#none
          multiline
          autoCorrect={false}
          clearTextOnFocus
          ?maxLength
          placeholder=?{animate ? None : Some(placeholder)}
          placeholderTextColor={placeholderTextColor->Option.getOr(placeholderColor)}
          value={state}
          ?onKeyPress
          onChangeText={text => {
            logger(
              ~logType=INFO,
              ~value=text,
              ~category=USER_EVENT,
              ~eventName=INPUT_FIELD_CHANGED,
              (),
            )
            setState(text)
          }}
          keyboardType
          autoFocus
          autoComplete={#off}
          textContentType={#oneTimeCode}
          onFocus={_ => {
            setIsFocused(_ => true)
            onFocus()
            logger(~logType=INFO, ~value=placeholder, ~category=USER_EVENT, ~eventName=FOCUS, ())
          }}
          onBlur={_ => {
            // TODO: remove invalid input (string with only space) eg: "      "
            state->String.trim == "" ? setState("") : ()
            onBlur()
            setIsFocused(_ => false)
            logger(~logType=INFO, ~value=placeholder, ~category=USER_EVENT, ~eventName=BLUR, ())
          }}
          editable
          pointerEvents
        />
      </View>
      <CustomTouchableOpacity activeOpacity=1. onPress=?onPressIconRight>
        {switch iconRight {
        | NoIcon => React.null
        | CustomIcon(element) =>
          <View style={viewStyle(~flexDirection=#row, ~alignContent=#"space-around", ())}>
            element
          </View>
        }}
      </CustomTouchableOpacity>
      {secureTextEntry && showEyeIconaftersecureTextEntry
        ? {
            <CustomTouchableOpacity
              style={viewStyle(~height=100.->pct, ~justifyContent=#center, ~paddingLeft=5.->dp, ())}
              onPress={_ => {setShowPass(prev => !prev)}}>
              <TextWrapper textType={PlaceholderText}> {"eye"->React.string} </TextWrapper>
            </CustomTouchableOpacity>
          }
        : React.null}
    </View>
  </View>
}
