open ReactNative
open Style
@react.component
let make = (
  ~isAllValuesValid,
  ~handlePress,
  ~hasSomeFields=true,
  ~paymentMethod,
  ~paymentExperience=?,
  ~displayText="Pay Now",
  (),
) => {
  let localeObject = GetLocale.useGetLocalObj()

  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let {
    payNowButtonColor,
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

  <View style={viewStyle(~alignItems=#center, ())}>
    <Space height=10. />
    <CustomButton
      borderWidth=buttonBorderWidth
      borderRadius=buttonBorderRadius
      borderColor=payNowButtonBorderColor
      buttonState={switch loading {
      | ProcessingPayments(_) => LoadingButton
      | PaymentSuccess => Completed
      | _ => isAllValuesValid ? Normal : Disabled
      }}
      loadingText="Processing..."
      linearGradientColorTuple=Some(isAllValuesValid ? payNowButtonColor : ("#CCCCCC", "#CCCCCC"))
      text={displayText == "Pay Now" ? localeObject.payNowButton : displayText}
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
