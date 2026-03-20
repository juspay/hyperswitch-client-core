open ReactNative
open Style
@react.component
let make = (
  ~handlePress,
  ~paymentMethod,
  ~paymentExperience=?,
  ~customerPaymentExperience=?,
  ~displayText="Pay Now",
  ~disabled=false,
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

  React.useEffect0(() => {
    logger(
      ~logType=INFO,
      ~value="",
      ~category=USER_EVENT,
      ~eventName=PAYMENT_DATA_FILLED,
      ~paymentMethod,
      ~paymentExperience?,
      (),
    )
    None
  })

  <View style={s({alignItems: #center})}>
    <Space height=10. />
    <CustomButton
      borderWidth=buttonBorderWidth
      borderRadius=buttonBorderRadius
      borderColor=payNowButtonBorderColor
      buttonState={switch (disabled, loading) {
      | (true, _) => Disabled
      | (false, ProcessingPayments | ProcessingPaymentsWithOverlay) => LoadingButton
      | (false, PaymentSuccess) => Completed
      | _ => Normal
      }}
      loadingText="Processing..."
      backgroundColor={payNowButtonColor}
      text={displayText == "Pay Now" ? localeObject.payNowButton : displayText}
      testID={TestUtils.payButtonTestId}
      onPress={ev => {
        logger(
          ~logType=INFO,
          ~value="",
          ~category=USER_EVENT,
          ~eventName=PAYMENT_ATTEMPT,
          ~paymentMethod,
          ~paymentExperience?,
          ~customerPaymentExperience?,
          (),
        )
        handlePress(ev)
      }}
    />
  </View>
}
