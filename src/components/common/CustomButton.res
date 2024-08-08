open ReactNative
open Style

type buttonState = Normal | LoadingButton | Completed | Disabled
type buttonType = Primary
type buttonSize = Medium | Small

type iconType = CustomIcon(React.element) | NoIcon

external toSize: ReactNative.Animated.Interpolation.t => size = "%identity"

module Window = {
  @scope("window") @val
  external alert: string => unit = "alert"
}

@react.component
let make = (
  ~loadingText="Loading..",
  ~buttonState: buttonState=Normal,
  ~text=?,
  ~name as _=?,
  ~buttonType: buttonType=Primary,
  ~buttonSize: buttonSize=Medium,
  ~leftIcon: iconType=NoIcon,
  ~rightIcon: iconType=NoIcon,
  ~onPress=?,
  ~fullLength=true,
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
  } = ThemebasedStyle.useThemeBasedStyle()
  let shadowOffsetHeight = payNowButtonShadowIntensity
  let elevation = payNowButtonShadowIntensity
  let shadowRadius = payNowButtonShadowIntensity
  let shadowOpacity = 0.2
  let shadowOffsetWidth = 0.
  let styles = {
    StyleSheet.create({
      "lengthStyle": fullLength ? viewStyle(~width=100.->pct, ()) : viewStyle(~width=300.->dp, ()),
      "buttonSizeClass": {
        switch buttonSize {
        | Small => viewStyle(~height=40.->dp, ())
        | Medium => viewStyle(~height=45.->dp, ())
        }
      },
      "textColor": textStyle(~color=payNowButtonTextColor, ()),
      "buttonTextClass": switch buttonSize {
      | Small => textStyle(~fontSize=14., ~paddingHorizontal=6.->dp, ())
      | Medium => textStyle(~fontSize=17., ~paddingHorizontal=8.->dp, ())
      },
    })
  }
  // let iconSize = switch buttonSize {
  // | Small => 14.
  // | Medium => 16.
  // }

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

  // let iconColor = switch buttonState {
  // | Normal => "white"
  // | Loading => "#bbbbbb"
  // | Disabled => "#bbbbbb"
  // | Transparent => "#bbbbbb"
  // }

  let disabled = switch buttonState {
  | Normal => false
  | _ => true
  }
  // let isdisabledColor = switch buttonState {
  // | Disabled => true
  // | _ => false
  // }

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
      viewStyle(
        ~justifyContent=#center,
        ~alignItems=#center,
        ~elevation,
        ~shadowRadius,
        ~shadowOpacity,
        ~shadowOffset={
          offset(~width=shadowOffsetWidth, ~height=shadowOffsetHeight /. 2.)
        },
        ~shadowColor=payNowButtonShadowColor,
        //  ~shadowRadius=3.,
        ~margin=1.->dp,
        ~borderRadius,
        ~borderWidth,
        ~borderColor,
        ~overflow=#hidden,
        ~backgroundColor=bgColor1,
        (),
      ),
      styles["lengthStyle"],
      styles["buttonSizeClass"],
    ])}>
    {switch children {
    | Some(child) => child
    | _ =>
      <TouchableOpacity
        disabled
        style={array([
          viewStyle(
            ~width=100.->pct,
            ~height=100.->pct,
            ~flex=1.,
            ~flexDirection=#row,
            ~justifyContent=#center,
            ~alignItems=#center,
            ~borderRadius,
            ~overflow=#hidden,
            ~opacity=1., //{isdisabledColor ? 0.6 : 1.},
            (),
          ),
        ])}
        ?onPress>
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
      </TouchableOpacity>
    }}
  </View>
}
