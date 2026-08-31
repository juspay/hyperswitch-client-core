@react.component
let make = (
  ~loading,
  ~handlePress: unit => unit,
  ~paymentMethod: string,
  ~paymentExperience=?,
  ~customerPaymentExperience=?,
  ~errorText=None,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let allApiData = AllApiDataContextNew.useOptionalData()
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
          displayText={switch (nativeProp.configuration.primaryButtonLabel, allApiData) {
          | (Some(str), _) => str
          | (None, Some({clientData})) =>
            clientData.intent_data.payment_type !== NORMAL
              ? "Pay Now"
              : localeObject.payNowButton
          | (None, None) => localeObject.payNowButton
          }}
        />}
    <HyperSwitchBranding />
  </>
}
