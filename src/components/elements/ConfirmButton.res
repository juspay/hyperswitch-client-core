@react.component
let make = (
  ~loading: bool,
  ~isAllValuesValid: bool,
  ~handlePress: ReactNative.Event.pressEvent => unit,
  ~hasSomeFields=?,
  ~paymentMethod: string,
  ~paymentExperience=?,
  ~errorText=None,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let localeObject = GetLocale.useGetLocalObj()

  <>
    {errorText->Belt.Option.isSome ? <ErrorText text={errorText} /> : React.null}
    {loading
      ? <>
          <CustomLoader />
          <Space />
          <HyperSwitchBranding />
        </>
      : <ConfirmButtonAnimation
          isAllValuesValid
          handlePress
          paymentMethod
          ?hasSomeFields
          ?paymentExperience
          displayText={switch nativeProp.configuration.primaryButtonLabel {
          | Some(str) => str
          | None =>
            allApiData.additionalPMLData.mandateType != NORMAL
              ? "Pay Now"
              : localeObject.payNowButton
          }}
        />}
  </>
}
