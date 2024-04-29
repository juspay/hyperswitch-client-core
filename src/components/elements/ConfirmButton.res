open ReactNative
open Style

@react.component
let make = (
  ~loading: bool,
  ~isAllValuesValid: bool,
  ~handlePress: ReactNative.Event.pressEvent => unit,
  ~hasSomeFields=?,
  ~paymentMethod: string,
  ~paymentExperience=?,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let localeObject = GetLocale.useGetLocalObj()

  <View style={viewStyle(~marginHorizontal=18.->dp, ())}>
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
          | None => allApiData.mandateType != NORMAL ? "Pay Now" : localeObject.payNowButton
          }}
        />}
  </View>
}
