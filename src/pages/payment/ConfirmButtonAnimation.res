open ReactNative
open Style
@react.component
let make = (~handlePress, ~displayText="Pay Now", ()) => {
  let localeObject = GetLocale.useGetLocalObj()

  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let {
    payNowButtonColor,
    payNowButtonBorderColor,
    buttonBorderRadius,
    buttonBorderWidth,
  } = ThemebasedStyle.useThemeBasedStyle()
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
        SdkLogger.logUser(~event=PaymentSubmitted({source: PayButton}))
        handlePress()
      }}
    />
  </View>
}
