open ReactNative
open PaymentMethodListType

@react.component
let make = (
  ~cardVal: PaymentMethodListType.payment_method_types_card,
  ~isScreenFocus,
  ~setConfirmButtonDataRef: React.element => unit,
) => {
  // Custom Hooks
  let localeObject = GetLocale.useGetLocalObj()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  // Custom context
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)

  let (isNicknameSelected, setIsNicknameSelected) = React.useState(_ => false)
  let (keyToTrigerButtonClickError, setKeyToTrigerButtonClickError) = React.useState(_ => 0)

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }
  let isSaveCardCheckboxVisible = nativeProp.configuration.displaySavedPaymentMethodsCheckbox

  // Fields Hooks
  let (cardData, _) = React.useContext(CardDataContext.cardDataContext)
  let (nickname, setNickname) = React.useState(_ => None)

  // Validity Hooks
  let (isAllCardValuesValid, setIsAllCardValuesValid) = React.useState(_ => false)
  let (isAllDynamicFieldValid, setIsAllDynamicFieldValid) = React.useState(_ => true)
  let requiredFields = cardVal.required_field->Array.filter(val => {
    switch val.field_type {
    | RequiredFieldsTypes.UnKnownField(_) => false
    | _ => true
    }
  })
  let (dynamicFieldsJson, setDynamicFieldsJson) = React.useState((_): array<(
    RescriptCoreFuture.Dict.key,
    JSON.t,
    option<string>,
  )> => [])
  let (error, setError) = React.useState(_ => None)

  let isConfirmButtonValid = isAllCardValuesValid && isAllDynamicFieldValid

  let initialiseNetcetera = NetceteraThreeDsHooks.useInitNetcetera()
  let (isInitialised, setIsInitialised) = React.useState(_ => false)

  React.useEffect1(() => {
    if (
      Platform.os == #android &&
      !isInitialised &&
      allApiData.additionalPMLData.requestExternalThreeDsAuthentication->Option.getOr(false) &&
      cardData.cardNumber->String.length > 0
    ) {
      setIsInitialised(_ => true)
      initialiseNetcetera(
        ~netceteraSDKApiKey=nativeProp.configuration.netceteraSDKApiKey->Option.getOr(""),
        ~sdkEnvironment=nativeProp.env,
      )
    }
    None
  }, [cardData.cardNumber])

  let processRequest = (prop: PaymentMethodListType.payment_method_types_card) => {
    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
      if !closeSDK {
        setLoading(FillingDetails)
        switch errorMessage.message {
        | Some(message) => setError(_ => Some(message))
        | None => ()
        }
      }
      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }
    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      switch paymentStatus {
      | PaymentSuccess => {
          setLoading(PaymentSuccess)
          setTimeout(() => {
            handleSuccessFailure(~apiResStatus=status, ())
          }, 300)->ignore
        }
      | _ => handleSuccessFailure(~apiResStatus=status, ())
      }
    }

    let payment_method_data = PaymentUtils.generatePaymentMethodData(
      ~prop,
      ~cardData,
      ~cardHolderName=None,
      ~nickname,
    )

    let body = PaymentUtils.generateCardConfirmBody(
      ~nativeProp,
      ~prop,
      ~payment_method_data=payment_method_data->Option.getOr(JSON.Encode.null),
      ~allApiData,
      ~isNicknameSelected,
      ~isSaveCardCheckboxVisible,
      ~isGuestCustomer=savedPaymentMethodsData.isGuestCustomer,
      (),
    )

    let paymentBodyWithDynamicFields = PaymentMethodListType.getPaymentBody(body, dynamicFieldsJson)
    fetchAndRedirect(
      ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=prop.payment_method_type,
      (),
    )
  }

  let handlePress = _ => {
    isConfirmButtonValid
      ? {
          setLoading(ProcessingPayments(None))
          processRequest(cardVal)
        }
      : setKeyToTrigerButtonClickError(prev => prev + 1)
  }

  React.useEffect6(() => {
    if isScreenFocus {
      setConfirmButtonDataRef(
        <ConfirmButton
          loading=false isAllValuesValid=true handlePress paymentMethod="CARD" errorText=error
        />,
      )
    }
    None
  }, (isConfirmButtonValid, isScreenFocus, error, isNicknameSelected, nickname, dynamicFieldsJson))
  <>
    <Space />
    <View>
      <TextWrapper text=localeObject.cardDetailsLabel textType={ModalText} />
      <Space height=8. />
      <CardElement setIsAllValid=setIsAllCardValuesValid reset=false keyToTrigerButtonClickError />
      {cardVal.required_field->Array.length != 0
        ? <>
            <DynamicFields
              setIsAllDynamicFieldValid
              setDynamicFieldsJson
              requiredFields
              isSaveCardsFlow={false}
              savedCardsData=None
              keyToTrigerButtonClickError
            />
            <Space height=8. />
          </>
        : React.null}
      {switch (
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        savedPaymentMethodsData.isGuestCustomer,
        allApiData.additionalPMLData.mandateType,
      ) {
      | (true, false, NEW_MANDATE | NORMAL) =>
        <>
          <Space height=8. />
          <ClickableTextElement
            disabled={false}
            initialIconName="checkboxClicked"
            updateIconName=Some("checkboxNotClicked")
            text=localeObject.saveCardDetails
            isSelected=isNicknameSelected
            setIsSelected=setIsNicknameSelected
            textType={ModalText}
            disableScreenSwitch=true
          />
        </>
      | _ => React.null
      }}
      {switch (
        savedPaymentMethodsData.isGuestCustomer,
        isNicknameSelected,
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        allApiData.additionalPMLData.mandateType,
      ) {
      | (false, _, true, NEW_MANDATE | NORMAL) =>
        <NickNameElement nickname setNickname isNicknameSelected />
      | (false, _, false, NEW_MANDATE) | (false, _, _, SETUP_MANDATE) =>
        <NickNameElement nickname setNickname isNicknameSelected=true />
      | _ => React.null
      }}
    </View>
  </>
}
