open ReactNative
open Style
@react.component
let make = (
  ~handlePress,
  ~paymentMethod,
  ~displayText="Pay Now",
  // Off for buttons that only submit fields (for example the address sheet), not a payment.
  ~logSubmit=true,
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
  let loggedPaymentMethod = paymentMethod->LoggerPaymentMethod.ofTypeName

  <View style={s({alignItems: #center})}>
    <Space height=10. />
    <CustomButton
      borderWidth=buttonBorderWidth
      borderRadius=buttonBorderRadius
      borderColor=payNowButtonBorderColor
      buttonState={switch loading {
      | ProcessingPayments | ProcessingPaymentsWithOverlay => LoadingButton
      | PaymentSuccess => Completed
      | _ => Normal
      }}
      loadingText={localeObject.processingText}
      backgroundColor={payNowButtonColor}
      text={displayText == "Pay Now" ? localeObject.payNowButton : displayText}
      testID={TestUtils.payButtonTestId}
      onPress={_ => {
        if logSubmit {
          SdkLogger.logUser(
            ~event=PaymentSubmitted({source: PayButton}),
            ~paymentMethod=?loggedPaymentMethod,
          )
        }
        handlePress()
      }}
    />
  </View>
}
