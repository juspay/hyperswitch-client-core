open ReactNative
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

  let (paymentScreenType, _) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)

  <View>
    {errorText->Belt.Option.isSome ? <ErrorText text={errorText} /> : React.null}
    {loading
      ? <View>
          <CustomLoader />
          <Space />
          <HyperSwitchBranding />
        </View>
      : <ConfirmButtonAnimation
          isAllValuesValid
          handlePress
          paymentMethod
          ?hasSomeFields
          ?paymentExperience
          displayText={switch paymentScreenType {
          | WALLET_MISSING_FIELDS(_, _, _) => "Submit"
          | _ =>
            switch nativeProp.configuration.primaryButtonLabel {
            | Some(str) => str
            | None =>
              allApiData.additionalPMLData.mandateType != NORMAL
                ? "Pay Now"
                : localeObject.payNowButton
            }
          }}
        />}
  </View>
}
