open ReactNative
open PaymentMethodListType
open Style
@react.component
let make = (
  ~cardVal: PaymentMethodListType.payment_method_types_card,
  ~isScreenFocus,
  ~setConfirmButtonDataRef: React.element => unit,
) => {
  //  let {component, borderWidth, borderRadius} = ThemebasedStyle.useThemeBasedStyle()

  // Custom Hooks
  let localeObject = GetLocale.useGetLocalObj()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  // Custom context
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)

  let (isNicknameSelected, setIsNicknameSelected) = React.useState(_ => false)
  let (savedPaymentMethodsData, _) = React.useContext(
    SavedPaymentMethodContext.savedPaymentMethodContext,
  )
  let savedPaymentMethodsData = switch savedPaymentMethodsData {
  | Some(data) => data

  | _ => SavedPaymentMethodContext.dafaultsavePMObj
  }
  let isSaveCardCheckboxVisible = nativeProp.configuration.displaySavedPaymentMethodsCheckbox

  // Fields Hooks
  let (cardData, _) = React.useContext(CardDataContext.cardDataContext)
  // let {cardNumber, expireDate, cvv} = cardData
  //let (_country, setCountry) = React.useState(_ => "")
  //let (_zip, setZip) = React.useState(_ => "")
  let (nickname, setNickname) = React.useState(_ => None)
  //  let (cardHolderName, setCardHolderName) = React.useState(_ => None)

  // Validity Hooks
  let (isAllCardVlauesValid, setIsAllCardVlauesValid) = React.useState(_ => false)
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
  // let (isAllBillingValuesValid, setIsAllBillingValuesValid) = React.useState(_ => false)
  let (error, setError) = React.useState(_ => None)

  let isConfirmButtonValid = isAllCardVlauesValid && isAllDynamicFieldValid

  // let updateBilllingValues = (~country, ~zip, ~isAllValid) => {
  //   setCountry(_ => country)
  //   setZip(_ => zip)
  //   setIsAllBillingValuesValid(_ => isAllValid)
  //   ()
  // }
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
    // let (month, year) = Validation.getExpiryDates(expireDate)

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
    setLoading(ProcessingPayments)
    processRequest(cardVal)
  }

  React.useEffect6(() => {
    if isScreenFocus {
      setConfirmButtonDataRef(
        <ConfirmButton
          loading=false
          isAllValuesValid=isConfirmButtonValid
          handlePress
          paymentMethod="CARD"
          errorText=error
        />,
      )
    }
    None
  }, (isConfirmButtonValid, isScreenFocus, error, isNicknameSelected, nickname, dynamicFieldsJson))
  <View style={viewStyle(~marginHorizontal=18.->dp, ())}>
    <Space />
    <View>
      <TextWrapper text=localeObject.cardDetailsLabel textType={ModalText} />
      <Space height=8. />
      <CardElement setIsAllValid=setIsAllCardVlauesValid reset=false />
      // <Space height=24. />
      // <TextWrapper text=localeObject.cardHolderName textType={SubheadingBold} />
      // <Space height=8. />
      // <CustomInput
      //   state={cardHolderName->Option.getOr("")}
      //   setState={str => setCardHolderName(_ => str == "" ? None : Some(str))}
      //   placeholder=localeObject.cardHolderName
      //   keyboardType=#default
      //   isValid=true
      //   onFocus={_ => ()}
      //   onBlur={_ => ()}
      //   textColor=component.color
      //   borderBottomLeftRadius=borderRadius
      //   borderBottomRightRadius=borderRadius
      //   borderTopLeftRadius=borderRadius
      //   borderTopRightRadius=borderRadius
      //   borderTopWidth=borderWidth
      //   borderBottomWidth=borderWidth
      //   borderLeftWidth=borderWidth
      //   borderRightWidth=borderWidth
      // />
      {cardVal.required_field->Array.length != 0
        ? <>
            <DynamicFields
              setIsAllDynamicFieldValid
              setDynamicFieldsJson
              requiredFields
              isSaveCardsFlow={false}
              savedCardsData=None
            />
            <Space height=8. />
          </>
        : React.null}
      {switch (
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        savedPaymentMethodsData.isGuestCustomer,
        allApiData.mandateType,
      ) {
      | (true, false, NEW_MANDATE | NORMAL) =>
        // switch customer.id {
        // | Some(_) =>
        <>
          <Space height=8. />
          <ClickableTextElement
            disabled={false}
            initialIconName="checkboxClicked"
            updateIconName=Some("checkboxNotClicked")
            text=localeObject.saveCardDetails
            isSelected=isNicknameSelected
            setIsSelected=setIsNicknameSelected
            textType={TextWrapper.ModalTextBold}
            disableScreenSwitch=true
          />
        </>
      // | None => React.null
      // }
      | _ => React.null
      }}
      {switch (
        savedPaymentMethodsData.isGuestCustomer,
        isNicknameSelected,
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        allApiData.mandateType,
      ) {
      | (false, _, true, NEW_MANDATE | NORMAL) =>
        <NickNameElement nickname setNickname isNicknameSelected />
      | (false, _, false, NEW_MANDATE) | (false, _, _, SETUP_MANDATE) =>
        <NickNameElement nickname setNickname isNicknameSelected=true />
      | _ => React.null
      }}
      // <Space />
      // <TextWrapper text=localeObject.countryOrRegion textType=Subheading />
      // <Space height=5. />
      // <BillingElement updateBilllingValues={updateBilllingValues} />
      // {cardVal.required_field->Array.length != 0
      //   ? <DynamicFields
      //       setIsAllDynamicFieldValid
      //       requiredFields={cardVal.required_field->Array.filter(val => {
      //         switch val.field_type {
      //         | RequiredFieldsTypes.UnKnownField(_) => false
      //         | _ => true
      //         }
      //       })}
      //     />
      //   : React.null}
    </View>
  </View>
}
