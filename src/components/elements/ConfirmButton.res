@react.component
let make = (
  ~loading,
  ~handlePress: ReactNative.Event.pressEvent => unit,
  ~paymentMethod: string,
  ~paymentExperience=?,
  ~customerPaymentExperience=?,
  ~errorText=None,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let localeObject = GetLocale.useGetLocalObj()

  <>
    {errorText->Option.isSome ? <ErrorText text={errorText} /> : React.null}
    {loading
      ? <CustomLoader />
      : <ConfirmButtonAnimation
          handlePress
          paymentMethod
          ?paymentExperience
          ?customerPaymentExperience
          displayText={switch nativeProp.configuration.primaryButtonLabel {
          | Some(str) => str
          | None =>
            accountPaymentMethodData
            ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
            ->Option.getOr(NORMAL) !== NORMAL
              ? "Pay Now"
              : localeObject.payNowButton
          }}
        />}
    <HyperSwitchBranding />
  </>
}
