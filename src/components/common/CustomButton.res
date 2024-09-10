open ReactNative
open Style

type buttonState = Normal | LoadingButton | Completed | Disabled
type buttonType = Primary

type iconType = CustomIcon(React.element) | NoIcon

external toSize: ReactNative.Animated.Interpolation.t => size = "%identity"

@react.component
let make = (
  ~loadingText="Loading..",
  ~buttonState: buttonState=Normal,
  ~text=?,
  ~name as _=?,
  ~buttonType: buttonType=Primary,
  ~leftIcon: iconType=NoIcon,
  ~rightIcon: iconType=NoIcon,
  ~onPress=?,
  ~linearGradientColorTuple=None,
  ~borderWidth=0.,
  ~borderRadius=0.,
  ~borderColor="#ffffff",
  ~children=None,
) => {
  let fillAnimation = React.useRef(Animated.Value.create(0.)).current
  let {
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

  let backColor = switch linearGradientColorTuple {
  | Some(tuple) => tuple
  | None =>
    switch buttonState {
    | Normal => ("#0048a0", "#0570de")
    | LoadingButton => ("#0048a0", "#0570de")
    | Completed => ("#0048a0", "#0570de")
    | Disabled => ("#808080", "#808080")
    }
  }

  let disabled = switch buttonState {
  | Normal => false
  | _ => true
  }

  let loaderIconColor = switch buttonType {
  | Primary => Some(payNowButtonTextColor)
  }
  let (bgColor1, _) = backColor

  let fillStyle = viewStyle(
    ~position=#absolute,
    ~top=0.->dp,
    ~bottom=0.->dp,
    ~right=0.->dp,
    ~opacity=0.4,
    ~backgroundColor={component.background},
    (),
  )
  let widthStyle = viewStyle(
    ~width=Animated.Interpolation.interpolate(
      fillAnimation,
      {
        inputRange: [0.0, 1.0],
        outputRange: ["95%", "0%"]->Animated.Interpolation.fromStringArray,
      },
    )->toSize,
    (),
  )

  let fillButton = () => {
    Animated.timing(
      fillAnimation,
      {
        toValue: 1.0->Animated.Value.Timing.fromRawValue,
        duration: 1800.0,
        useNativeDriver: false,
      },
    )->Animated.start()
  }

  <View
    style={array([
      getShadowStyle,
      viewStyle(
        ~height=primaryButtonHeight->dp,
        ~width=100.->pct,
        ~justifyContent=#center,
        ~alignItems=#center,
        ~borderRadius,
        ~borderWidth,
        ~borderColor,
        ~backgroundColor=bgColor1,
        (),
      ),
    ])}>
    <CustomTouchableOpacity
      disabled
      style={array([
        viewStyle(
          ~height=100.->pct,
          ~width=100.->pct,
          ~borderRadius,
          ~flex=1.,
          ~flexDirection=#row,
          ~justifyContent=#center,
          ~alignItems=#center,
          (),
        ),
      ])}
      ?onPress>
      {switch children {
      | Some(child) => child
      | _ =>
        <>
          {switch leftIcon {
          | CustomIcon(element) => element
          | NoIcon => React.null
          }}
          {if buttonState == LoadingButton {
            fillButton()
            <Animated.View style={array([fillStyle, widthStyle])} />
          } else {
            React.null
          }}
          {switch text {
          | Some(textStr) if textStr !== "" =>
            <View style={viewStyle(~flex=1., ~alignItems=#center, ~justifyContent=#center, ())}>
              <TextWrapper
                text={switch buttonState {
                | LoadingButton => loadingText
                | Completed => "Complete"
                | _ => textStr
                }}
                // textType=CardText
                textType={ButtonTextBold}
              />
            </View>
          | _ => React.null
          }}
          {if buttonState == LoadingButton || buttonState == Completed {
            <Loadericon iconColor=?loaderIconColor />
          } else {
            switch rightIcon {
            | CustomIcon(element) => element
            | NoIcon => React.null
            }
          }}
        </>
      }}
    </CustomTouchableOpacity>
  </View>
}
