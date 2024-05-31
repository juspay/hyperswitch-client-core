open ReactNative
open Style
@react.component
let make = (
  ~isAllValuesValid,
  ~handlePress,
  //  ~buttomFlex,
  ~hasSomeFields=true,
  ~paymentMethod,
  ~paymentExperience=?,
  ~displayText="Pay Now",
  (),
) => {
  let (buttomFlex, _) = React.useState(_ => Animated.Value.create(1.))
  let localeObject = GetLocale.useGetLocalObj()

  let animateFlex = (~flexval, ~value, ~endCallback=() => (), ()) => {
    Animated.timing(
      flexval,
      Animated.Value.Timing.config(
        ~toValue={value->Animated.Value.Timing.fromRawValue},
        ~isInteraction=true,
        ~useNativeDriver=false,
        ~delay=0.,
        (),
      ),
    )->Animated.start(~endCallback=_ => {endCallback()}, ())
  }

  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let {
    payNowButtonColor,
    // payNowButtonTextColor,
    payNowButtonBorderColor,
    buttonBorderRadius,
    buttonBorderWidth,
  } = ThemebasedStyle.useThemeBasedStyle()
  let logger = LoggerHook.useLoggerHook()

  React.useEffect2(() => {
    if isAllValuesValid && hasSomeFields {
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_DATA_FILLED,
        ~paymentMethod,
        ~paymentExperience?,
        (),
      )
    }
    None
  }, (isAllValuesValid, hasSomeFields))

  React.useEffect1(() => {
    if loading == PaymentSuccess {
      animateFlex(
        ~flexval=buttomFlex,
        ~value=0.01,
        // ~endCallback=() => {
        //   ()
        // },
        (),
      )
    }
    None
  }, [loading])

  <View style={viewStyle(~alignItems=#center, ())}>
    <Space height=10. />
    <CustomButton
      borderWidth=buttonBorderWidth
      borderRadius=buttonBorderRadius
      borderColor=payNowButtonBorderColor
      buttonState={switch loading {
      | ProcessingPayments => LoadingButton
      | PaymentSuccess => Completed
      | _ => isAllValuesValid ? Normal : Disabled
      }}
      // rightIcon=CustomIcon(
      //   loading == PaymentSuccess
      //     ? <Animated.View
      //         style={viewStyle(
      //           ~backgroundColor="#32CD32",
      //           ~flex=1.,
      //           ~alignItems=#center,
      //           ~justifyContent=#center,
      //           ~flexDirection=#row,
      //           ~height=100.->pct,
      //           (),
      //         )}>
      //         <Animated.View
      //           style={viewStyle(
      //             ~flex={buttomFlex->Animated.StyleProp.float},
      //             ~height=100.->dp,
      //             (),
      //           )}
      //         />
      //         <Icon name="completepayment" width=40. height=20. />
      //       </Animated.View>
      //     : <Icon name="lock" width=40. height=16. fill=payNowButtonTextColor />,
      // )
      loadingText="Processing..."
      linearGradientColorTuple=Some(isAllValuesValid ? payNowButtonColor : ("#CCCCCC", "#CCCCCC"))
      // leftIcon=CustomIcon(
      //   loading == PaymentSuccess ? <> </> : <View style={viewStyle(~width=40.->dp, ())} />,
      // )
      text={
        // loading == PaymentSuccess? "" :
        displayText == "Pay Now" ? localeObject.payNowButton : displayText
      }
      name="Pay"
      onPress={ev => {
        if !(isAllValuesValid && hasSomeFields) {
          logger(
            ~logType=INFO,
            ~value="",
            ~category=USER_EVENT,
            ~eventName=PAYMENT_DATA_FILLED,
            ~paymentMethod,
            ~paymentExperience?,
            (),
          )
        }
        logger(
          ~logType=INFO,
          ~value="",
          ~category=USER_EVENT,
          ~eventName=PAYMENT_ATTEMPT,
          ~paymentMethod,
          ~paymentExperience?,
          (),
        )
        handlePress(ev)
      }}
    />
    <HyperSwitchBranding />
  </View>
}
