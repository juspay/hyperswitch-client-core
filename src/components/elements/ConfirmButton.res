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
  let (clientData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
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
            clientData
            ->Option.map(data => data.intent_data.payment_type)
            ->Option.getOr(NORMAL) !== NORMAL
              ? "Pay Now"
              : localeObject.payNowButton
          }}
        />}
    <HyperSwitchBranding />
  </>
}
