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
  ~height: float=44.,
  ~secureTextEntry=false,
  ~keyboardType=#default,
  ~iconLeft: iconType=NoIcon,
  ~iconRight: iconType=NoIcon,
  ~multiline: bool=false,
  ~heading="",
  ~mandatory=false,
  ~textContentType=#username,
  ~reference=None,
  ~autoFocus=false,
  ~clearTextOnFocus=false,
  ~maxLength=None,
  ~onKeyPress=?,
  ~enableCrossIcon=true,
  ~textAlign=None,
  ~onPressIconRight=?,
  ~isValid=true,
  ~showEyeIconaftersecureTextEntry=true,
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
) => {
  let {
    textPrimary,
    placeholderColor,
    bgColor,
    focusedTextInputBoderColor,
    errorTextInputColor,
    normalTextInputBoderColor,
    component,
    shadowColor,
    shadowIntensity,
  } = ThemebasedStyle.useThemeBasedStyle()
  let shadowOffsetHeight = shadowIntensity
  let elevation = shadowIntensity
  let shadowRadius = shadowIntensity
  let shadowOpacity = 0.2
  let shadowOffsetWidth = 0.
  let (showPass, setShowPass) = React.useState(_ => secureTextEntry)
  let (isFocused, setIsFocused) = React.useState(_ => false)
  let logger = LoggerHook.useLoggerHook()
  let fontFamily = FontFamily.useCustomFontFamily()

  // let focusedTextInputBoderColor = "rgba(0, 153, 255, 1)"
  // let errorTextInputColor = "rgba(218, 14, 15, 1)"
  // let normalTextInputBoderColor = "rgba(204, 210, 226, 0.75)"
  let _ = state != "" && secureTextEntry == false && enableCrossIcon
  let shadwoStyle = enableShadow
    ? viewStyle(
        ~elevation,
        ~shadowRadius,
        ~shadowOpacity,
        ~shadowOffset={
          offset(~width=shadowOffsetWidth, ~height=shadowOffsetHeight)
        },
        ~shadowColor,
        (),
      )
    : viewStyle()
  <View style={viewStyle(~width=100.->pct, ())}>
    {heading != ""
      ? <TextWrapper
          //          fontFamily=IBMPlexSans_Medium
          textType=CustomCssText(
            array([
              textStyle(~fontStyle=#normal, ~fontSize=12., ~marginBottom=2.5->pct, ()),
              textPrimary,
            ]),
          )>
          {React.string(heading)}
          {mandatory
            ? <TextWrapper
                //   fontFamily=IBMPlexSans_Regular
                textType=CustomCssText(
                  textStyle(
                    //  ~fontFamily=FontFamily.getFontFamily(IBMPlexSans_Regular),
                    ~color={"red"},
                    (),
                  ),
                )>
                {" *"->React.string}
              </TextWrapper>
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
            ? isFocused ? focusedTextInputBoderColor : normalTextInputBoderColor
            : errorTextInputColor,
          ~width,
          ~paddingHorizontal=13.->dp,
          ~alignItems=#center,
          ~justifyContent=#center,
          (),
        ),
        shadwoStyle,
        // bgColor,
      ])}>
      {switch iconLeft {
      | CustomIcon(element) => <View style={viewStyle(~paddingRight=10.->dp, ())}> element </View>
      | NoIcon => React.null
      }}
      <TextInput
        ref=?reference
        style={array([
          textStyle(
            ~flex=1.,
            ~fontStyle=#normal,
            ~color=textColor,
            ~fontFamily,
            //    ~fontFamily=FontFamily.getFontFamily(IBMPlexSans_Medium),
            ~fontSize,
            //  ~lineHeight=1.5,
            ~textAlign?,
            (),
          ),
          viewStyle(~height=100.->pct, ~width=100.->pct, ()),
        ])}
        secureTextEntry=showPass
        autoCapitalize=#none
        multiline
        autoCorrect={false}
        clearTextOnFocus
        ?maxLength
        placeholder
        placeholderTextColor={placeholderTextColor->Option.getOr(placeholderColor)}
        value={state}
        ?onKeyPress
        onChangeText={text => {
          logger(
            ~logType=INFO,
            ~value=placeholder,
            ~category=USER_EVENT,
            ~eventName=INPUT_FIELD_CHANGED,
            (),
          )
          setState(text)
        }}
        keyboardType
        autoFocus
        textContentType
        onFocus={_ => {
          setIsFocused(_ => true)
          onFocus()
          logger(~logType=INFO, ~value=placeholder, ~category=USER_EVENT, ~eventName=FOCUS, ())
        }}
        onBlur={_ => {
          onBlur()
          setIsFocused(_ => false)
          logger(~logType=INFO, ~value=placeholder, ~category=USER_EVENT, ~eventName=BLUR, ())
        }}
        editable
        pointerEvents
      />
      <TouchableOpacity activeOpacity=1. onPress=?onPressIconRight>
        {switch iconRight {
        | NoIcon => React.null
        | CustomIcon(element) =>
          <View style={viewStyle(~flexDirection=#row, ~alignContent=#"space-around", ())}>
            element
          </View>
        }}
      </TouchableOpacity>
      {secureTextEntry && showEyeIconaftersecureTextEntry
        ? {
            <TouchableOpacity
              style={viewStyle(~height=100.->pct, ~justifyContent=#center, ~paddingLeft=5.->dp, ())}
              onPress={_ => {setShowPass(prev => !prev)}}>
              <Text> {"eye"->React.string} </Text>
            </TouchableOpacity>
          }
        : React.null}
    </View>
  </View>
}
