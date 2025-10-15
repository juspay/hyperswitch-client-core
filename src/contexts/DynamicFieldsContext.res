type sheetType = ButtonSheet | DynamicFieldsSheet

type dynamicFieldsData = {
  sheetType: sheetType,
  setSheetType: sheetType => unit,
  getRequiredFieldsForTabs: (
    AccountPaymentMethodType.paymentMethodType,
    Dict.t<JSON.t>,
    bool,
  ) => (
    array<SuperpositionTypes.fieldConfig>,
    RescriptCore.Dict.t<Core__JSON.t>,
    bool,
    array<string>,
    bool,
  ),
  getRequiredFieldsForButton: (
    AccountPaymentMethodType.paymentMethodType,
    RescriptCore.Dict.t<Core__JSON.t>,
    option<SdkTypes.addressDetails>,
    option<SdkTypes.addressDetails>,
    bool,
  ) => (bool, RescriptCore.Dict.t<Core__JSON.t>),
  country: string,
  setCountry: string => unit,
  walletData: (
    array<SuperpositionTypes.fieldConfig>,
    Dict.t<JSON.t>,
    Dict.t<JSON.t>,
    bool,
    array<string>,
    PaymentMethodType.paymentMethod,
    string,
    string,
    SdkTypes.paymentMethodTypeWallet,
    array<AccountPaymentMethodType.paymentExperience>,
  ),
  isNicknameSelected: bool,
  setIsNicknameSelected: bool => unit,
  nickname: option<string>,
  setNickname: option<string> => unit,
  isNicknameValid: bool,
  setIsNicknameValid: bool => unit,
}

let dynamicFieldsContext = React.createContext({
  sheetType: ButtonSheet,
  setSheetType: _ => (),
  getRequiredFieldsForTabs: (_, _, _) => ([], Dict.make(), false, [], false),
  getRequiredFieldsForButton: (_, _, _, _, _) => (true, Dict.make()),
  country: "",
  setCountry: _ => (),
  walletData: ([], Dict.make(), Dict.make(), false, [], OTHERS, "", "", NONE, []),
  isNicknameSelected: false,
  setIsNicknameSelected: _ => (),
  nickname: None,
  setNickname: _ => (),
  isNicknameValid: false,
  setIsNicknameValid: _ => (),
})

module Provider = {
  let make = React.Context.provider(dynamicFieldsContext)
}
@react.component
let make = (~children) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let getSuperpositionFinalFields = ConfigurationService.useConfigurationService()

  let (sheetType, setSheetType) = React.useState(_ => ButtonSheet)
  let setSheetType = React.useCallback1(val => {
    setSheetType(_ => val)
  }, [setSheetType])

  let (country, setCountry) = React.useState(_ => nativeProp.hyperParams.country)
  let setCountry = React.useCallback1(country => {
    setCountry(_ => country)
  }, [setCountry])

  let getRequiredFieldsForTabs = (
    paymentMethodData: AccountPaymentMethodType.paymentMethodType,
    formData,
    isScreenFocus,
  ) => {
    let eligibleConnectors = switch paymentMethodData.paymentMethod {
    | CARD =>
      paymentMethodData.cardNetworks->AccountPaymentMethodType.getEligibleConnectorFromCardNetwork
    | _ =>
      paymentMethodData.paymentExperience->AccountPaymentMethodType.getEligibleConnectorFromPaymentExperience
    }

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      paymentMethod: paymentMethodData.paymentMethodStr,
      paymentMethodType: paymentMethodData.paymentMethodType,
      mandateType: accountPaymentMethodData
      ->Option.map(data => data.paymentType === NORMAL ? "non_mandate" : "mandate")
      ->Option.getOr("non_mandate"),
      collectBillingDetailsFromWalletConnector: "required",
      collectShippingDetailsFromWalletConnector: "required",
      country,
    }

    let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
      paymentMethodData.requiredFields,
    )

    switch requiredFieldsFromPML->Dict.get("paymentMethodData.billing.address.country") {
    | None | Some("") =>
      requiredFieldsFromPML->Dict.set(
        "paymentMethodData.billing.address.country",
        nativeProp.hyperParams.country,
      )
    | _ => ()
    }

    let (_requiredFields, missingRequiredFields, initialValues) = getSuperpositionFinalFields(
      eligibleConnectors,
      configParams,
      requiredFieldsFromPML,
    )

    (
      missingRequiredFields,
      CommonUtils.mergeDict(initialValues, formData),
      paymentMethodData.paymentMethod === CARD,
      PaymentUtils.getCardNetworks(paymentMethodData.cardNetworks->Some),
      isScreenFocus,
    )
  }

  let (walletData, setWalletData) = React.useState(_ => (
    [],
    Dict.make(),
    Dict.make(),
    false,
    [],
    (OTHERS: PaymentMethodType.paymentMethod),
    "",
    "",
    (NONE: SdkTypes.paymentMethodTypeWallet),
    [],
  ))

  let setWalletData = React.useCallback1(
    (
      requiredFields,
      initialValues,
      walletDict,
      isCardPayment,
      enabledCardSchemes,
      paymentMethod,
      paymentMethodStr,
      paymentMethodType,
      paymentMethodTypeWallet,
      paymentExperience,
    ) => {
      setWalletData(_ => (
        requiredFields,
        initialValues,
        walletDict,
        isCardPayment,
        enabledCardSchemes,
        paymentMethod,
        paymentMethodStr,
        paymentMethodType,
        paymentMethodTypeWallet,
        paymentExperience,
      ))
    },
    [setWalletData],
  )

  let getRequiredFieldsForButton = (
    paymentMethodData: AccountPaymentMethodType.paymentMethodType,
    walletDict,
    billingAddress,
    shippingAddress,
    useIntentData,
  ) => {
    let eligibleConnectors = switch paymentMethodData.paymentMethod {
    | CARD =>
      paymentMethodData.cardNetworks
      ->Array.get(0)
      ->Option.mapOr([], network => network.eligibleConnectors)
    | _ =>
      paymentMethodData.paymentExperience
      ->Array.get(0)
      ->Option.mapOr([], experience => experience.eligibleConnectors)
    }

    let requiredFieldsFromSource = if (
      accountPaymentMethodData
      ->Option.map(accountPaymentMethods =>
        accountPaymentMethods.collectBillingDetailsFromWallets
      )
      ->Option.getOr(false) && !useIntentData
    ) {
      let requiredFieldsFromWallet = switch billingAddress {
      | Some(billingAddress) => AddressUtils.getFlatAddressDict(~billingAddress, ~shippingAddress)
      | None => SuperpositionHelper.extractFieldValuesFromPML(paymentMethodData.requiredFields)
      }
      switch requiredFieldsFromWallet->Dict.get("paymentMethodData.billing.address.country") {
      | Some("") | None =>
        requiredFieldsFromWallet->Dict.set("paymentMethodData.billing.address.country", country)
      | _ => ()
      }
      requiredFieldsFromWallet
    } else {
      let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
        paymentMethodData.requiredFields,
      )
      switch requiredFieldsFromPML->Dict.get("paymentMethodData.billing.address.country") {
      | Some("") | None =>
        requiredFieldsFromPML->Dict.set("paymentMethodData.billing.address.country", country)
      | _ => ()
      }
      requiredFieldsFromPML
    }

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      paymentMethod: paymentMethodData.paymentMethodStr,
      paymentMethodType: paymentMethodData.paymentMethodType,
      mandateType: accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.paymentType)
      ->Option.getOr(NORMAL) === NORMAL
        ? "non_mandate"
        : "mandate",
      collectBillingDetailsFromWalletConnector: "required",
      collectShippingDetailsFromWalletConnector: "required",
      country,
    }

    let (_requiredFields, missingRequiredFields, initialValues) = getSuperpositionFinalFields(
      eligibleConnectors,
      configParams,
      requiredFieldsFromSource,
    )

    let isFieldsMissing = missingRequiredFields->Array.length > 0

    if isFieldsMissing {
      setWalletData(
        missingRequiredFields,
        initialValues,
        walletDict,
        paymentMethodData.paymentMethod === CARD,
        PaymentUtils.getCardNetworks(paymentMethodData.cardNetworks->Some),
        paymentMethodData.paymentMethod,
        paymentMethodData.paymentMethodStr,
        paymentMethodData.paymentMethodType,
        paymentMethodData.paymentMethodTypeWallet,
        paymentMethodData.paymentExperience,
      )
      setSheetType(DynamicFieldsSheet)
    }

    (isFieldsMissing, initialValues)
  }

  let (isNicknameSelected, setIsNicknameSelected) = React.useState(_ => false)
  let setIsNicknameSelected = React.useCallback1(val => {
    setIsNicknameSelected(_ => val)
  }, [setIsNicknameSelected])

  let (nickname, setNickname) = React.useState(_ => None)
  let setNickname = React.useCallback1(val => {
    setNickname(_ => val)
  }, [setNickname])

  let (isNicknameValid, setIsNicknameValid) = React.useState(_ => true)
  let setIsNicknameValid = React.useCallback1(val => {
    setIsNicknameValid(_ => val)
  }, [setIsNicknameValid])

  React.useEffect(() => {
    if isNicknameSelected == false {
      setNickname(None)
      setIsNicknameValid(true)
    }
    None
  }, [isNicknameSelected])

  <Provider
    value={
      sheetType,
      setSheetType,
      getRequiredFieldsForTabs,
      getRequiredFieldsForButton,
      country,
      setCountry,
      walletData,
      isNicknameSelected,
      setIsNicknameSelected,
      nickname,
      setNickname,
      isNicknameValid,
      setIsNicknameValid,
    }>
    children
  </Provider>
}
