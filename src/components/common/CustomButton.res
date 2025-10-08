open ReactNative
open Style

type buttonState = Normal | LoadingButton | Completed | Disabled
type buttonType = Primary

type iconType = CustomIcon(React.element) | NoIcon

@react.component
let make = (
  ~loadingText="Loading..",
  ~buttonState: buttonState=Normal,
  ~text=?,
  ~buttonType: buttonType=Primary,
  ~leftIcon: iconType=NoIcon,
  ~rightIcon: iconType=NoIcon,
  ~onPress,
  ~backgroundColor=?,
  ~borderWidth=0.,
  ~borderRadius=0.,
  ~borderColor="#ffffff",
  ~children=None,
  ~testID=?,
) => {
  let fillAnimation = AnimatedValue.useAnimatedValue(0.)
  let {
    payNowButtonColor,
    payNowButtonTextColor,
    payNowButtonShadowColor,
    payNowButtonShadowIntensity,
    component,
    primaryButtonHeight,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(
    ~shadowIntensity=payNowButtonShadowIntensity,
    ~shadowColor=payNowButtonShadowColor,
    (),
  )

  let _buttonColor = switch buttonState {
  | Normal => ("#0048a0", "#0570de")
  | LoadingButton => ("#0048a0", "#0570de")
  | Completed => ("#0048a0", "#0570de")
  | Disabled => ("#808080", "#808080")
  }

  let disabled = switch buttonState {
  | Normal => false
  | _ => true
  }

  let loaderIconColor = switch buttonType {
  | Primary => Some(payNowButtonTextColor)
  }

  let fillStyle = s({
    position: #absolute,
    top: 0.->dp,
    bottom: 0.->dp,
    right: 0.->dp,
    opacity: 0.4,
    backgroundColor: {component.background},
  })
  let widthStyle = s({
    width: Animated.Interpolation.interpolate(
      fillAnimation,
      {
        inputRange: [0.0, 1.0],
        outputRange: ["95%", "0%"]->Animated.Interpolation.fromStringArray,
      },
    )->Animated.StyleProp.size,
  })

  let fillButton = () => {
    Animated.timing(
      fillAnimation,
      {
        toValue: 1.0->Animated.Value.Timing.fromRawValue,
        duration: 1800.0,
        useNativeDriver: false,
      },
    )->Animated.start
  }

  <CustomPressable
    disabled
    testID={testID->Option.getOr("")}
    style={array([
      s({
        height: primaryButtonHeight->dp,
        width: 100.->pct,
        borderRadius,
        borderWidth,
        borderColor,
        backgroundColor: ?(
          children->Option.isNone ? Some(backgroundColor->Option.getOr(payNowButtonColor)) : None
        ),
        overflow: #hidden,
      }),
    ])}
    onPress={ev => {
      Keyboard.dismiss()
      onPress(ev)
    }}>
    <View
      style={array([
        getShadowStyle,
        s({
          width: 100.->pct,
          height: 100.->pct,
          flexDirection: #row,
        }),
      ])}
      pointerEvents={Platform.os === #web ? #auto : #none}>
      {switch children {
      | Some(child) => child
      | _ =>
        <>
          <UIUtils.RenderIf condition={buttonState == LoadingButton}>
            {
              fillButton()
              <Animated.View style={array([fillStyle, widthStyle])} />
            }
          </UIUtils.RenderIf>
          {switch text {
          | Some(textStr) if textStr !== "" =>
            <View
              style={s({
                flex: 1.,
                flexDirection: #row,
                alignItems: #center,
                justifyContent: #center,
                gap: 12.->dp,
              })}>
              {switch leftIcon {
              | CustomIcon(element) => element
              | NoIcon => React.null
              }}
              <TextWrapper
                text={switch buttonState {
                | LoadingButton => loadingText
                | Completed => "Complete"
                | _ => textStr
                }}
                // textType=CardText
                textType={ButtonTextBold}
              />
              {switch rightIcon {
              | CustomIcon(element) => element
              | NoIcon => React.null
              }}
            </View>
          | _ =>
            <View
              style={s({
                flex: 1.,
                flexDirection: #row,
                alignItems: #center,
                justifyContent: #center,
                gap: 12.->dp,
              })}>
              {switch leftIcon {
              | CustomIcon(element) => element
              | NoIcon => React.null
              }}
              {switch rightIcon {
              | CustomIcon(element) => element
              | NoIcon => React.null
              }}
            </View>
          }}
          <UIUtils.RenderIf condition={buttonState == LoadingButton || buttonState == Completed}>
            <Loadericon iconColor=?loaderIconColor />
          </UIUtils.RenderIf>
        </>
      }}
    </View>
  </CustomPressable>
}
