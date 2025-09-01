open ReactNative
open Style

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
  ~onFocusRFF: option<ReactEvent.Focus.t => unit>=?,
  ~onBlurRFF: option<ReactEvent.Focus.t => unit>=?,
  ~textColor="black",
  ~editable=true,
  ~pointerEvents=#auto,
  ~fontSize=16.,
  ~enableShadow=true,
  ~animate=true,
  ~animateLabel=?,
  ~name="",
  ~style=?,
  ~onChange=?,
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
  let shadowStyle = enableShadow ? getShadowStyle : empty

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
    )->Animated.start

    None
  }, (isFocused, state))

  <View style={style->Option.getOr(s({width: 100.->pct}))}>
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
        s({
          backgroundColor: component.background,
          borderTopWidth,
          borderBottomWidth,
          borderLeftWidth,
          borderRightWidth,
          borderTopLeftRadius,
          borderTopRightRadius,
          borderBottomLeftRadius,
          borderBottomRightRadius,
          height: height->dp,
          flexDirection: #row,
          borderColor: isValid
            ? isFocused ? primaryColor : normalTextInputBoderColor
            : errorTextInputColor,
          width,
          paddingHorizontal: 13.->dp,
          alignItems: #center,
          justifyContent: #center,
        }),
        shadowStyle,
        // bgColor,
      ])}>
      {switch iconLeft {
      | CustomIcon(element) => <View style={s({paddingRight: 10.->dp})}> element </View>
      | NoIcon => React.null
      }}
      <View
        style={s({
          flex: 1.,
          position: #relative,
          height: 100.->pct,
          justifyContent: animate ? #"flex-end" : #center,
        })}>
        {animate
          ? <Animated.View
              pointerEvents=#none
              style={s({
                top: 0.->dp,
                position: #absolute,
                height: animatedValue
                ->Animated.Interpolation.interpolate({
                  inputRange: [0., 1.],
                  outputRange: ["100%", "40%"]->Animated.Interpolation.fromStringArray,
                })
                ->Animated.StyleProp.size,
                justifyContent: #center,
              })}>
              <Animated.Text
                style={array([
                  s({
                    fontFamily,
                    fontWeight: isFocused || state != "" ? #500 : #normal,
                    fontSize: animatedValue
                    ->Animated.Interpolation.interpolate({
                      inputRange: [0., 1.],
                      outputRange: [
                        fontSize +. placeholderTextSizeAdjust,
                        fontSize +. placeholderTextSizeAdjust -. 5.,
                      ]->Animated.Interpolation.fromFloatArray,
                    })
                    ->Animated.StyleProp.float,
                    color: placeholderTextColor->Option.getOr(placeholderColor),
                  }),
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
          ref=?{switch reference {
          | Some(ref) => ref->ReactNative.Ref.value->Some
          | None => None
          }}
          style={array([
            s({
              fontStyle: #normal,
              color: textColor,
              fontFamily,
              fontSize: fontSize +. placeholderTextSizeAdjust,
              ?textAlign,
            }),
            s({padding: 0.->dp, height: (height -. 10.)->dp, width: 100.->pct}),
          ])}
          testID=name
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
            setState(text)
            switch onChange {
            | Some(onChangeFn) => {
                let syntheticEvent = %raw(`{target: {value: text}}`)
                onChangeFn(syntheticEvent)
              }
            | None => ()
            }
          }}
          keyboardType
          autoFocus
          autoComplete={#off}
          textContentType={#oneTimeCode}
          onFocus={event => {
            setIsFocused(_ => true)
            onFocus()
            switch onFocusRFF {
            | Some(rffCallback) => {
                let syntheticEvent: ReactEvent.Focus.t = event->Obj.magic
                rffCallback(syntheticEvent)
              }
            | None => ()
            }
            logger(~logType=INFO, ~value=placeholder, ~category=USER_EVENT, ~eventName=FOCUS, ())
          }}
          onBlur={event => {
            state->String.trim == "" ? setState("") : ()
            onBlur()
            setIsFocused(_ => false)
            switch onBlurRFF {
            | Some(rffCallback) => {
                let syntheticEvent: ReactEvent.Focus.t = event->Obj.magic
                rffCallback(syntheticEvent)
              }
            | None => ()
            }
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
          <View style={s({flexDirection: #row, alignContent: #"space-around"})}> element </View>
        }}
      </CustomTouchableOpacity>
      {secureTextEntry && showEyeIconaftersecureTextEntry
        ? {
            <CustomTouchableOpacity
              style={s({height: 100.->pct, justifyContent: #center, paddingLeft: 5.->dp})}
              onPress={_ => {setShowPass(prev => !prev)}}>
              <TextWrapper textType={PlaceholderText}> {"eye"->React.string} </TextWrapper>
            </CustomTouchableOpacity>
          }
        : React.null}
    </View>
  </View>
}
