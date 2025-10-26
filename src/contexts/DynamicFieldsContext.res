type sheetType = ButtonSheet | DynamicFieldsSheet

type dynamicFieldsData = {
  formDataRef: option<React.ref<RescriptCore.Dict.t<JSON.t>>>,
  sheetType: sheetType,
  setSheetType: sheetType => unit,
  getRequiredFieldsForTabs: (
    AccountPaymentMethodType.payment_method_type,
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
    AccountPaymentMethodType.payment_method_type,
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
    SdkTypes.payment_method_type_wallet,
    array<AccountPaymentMethodType.payment_experience>,
  ),
  isNicknameSelected: bool,
  setIsNicknameSelected: bool => unit,
  nickname: option<string>,
  setNickname: option<string> => unit,
  isNicknameValid: bool,
  setIsNicknameValid: bool => unit,
}

let dynamicFieldsContext = React.createContext({
  formDataRef: None,
  sheetType: ButtonSheet,
  setSheetType: _ => (),
  getRequiredFieldsForTabs: (_, _, _) => ([], Dict.make(), false, [], false),
  getRequiredFieldsForButton: (_, _, _, _, _) => (true, Dict.make()),
  country: AddressUtils.defaultCountry,
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
  let formDataRef = Some(React.useRef(Dict.make()))
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
    paymentMethodData: AccountPaymentMethodType.payment_method_type,
    formData,
    isScreenFocus,
  ) => {
    let eligibleConnectors = switch paymentMethodData.payment_method {
    | CARD =>
      paymentMethodData.card_networks->AccountPaymentMethodType.getEligibleConnectorFromCardNetwork
    | _ =>
      paymentMethodData.payment_experience->AccountPaymentMethodType.getEligibleConnectorFromPaymentExperience
    }

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      payment_method: paymentMethodData.payment_method_str,
      payment_method_type: paymentMethodData.payment_method_type,
      mandate_type: accountPaymentMethodData
      ->Option.map(data => data.payment_type === NORMAL ? "non_mandate" : "mandate")
      ->Option.getOr("non_mandate"),
      collect_billing_details_from_wallet_connector: "required",
      collect_shipping_details_from_wallet_connector: "required",
      country,
    }

    let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
      paymentMethodData.required_fields,
    )

    switch requiredFieldsFromPML->Dict.get("payment_method_data.billing.address.country") {
    | None | Some("") =>
      requiredFieldsFromPML->Dict.set(
        "payment_method_data.billing.address.country",
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
      CommonUtils.mergeDict(
        switch formDataRef {
        | Some(ref) => CommonUtils.mergeDict(initialValues, ref.current)
        | None => initialValues
        },
        formData,
      ),
      paymentMethodData.payment_method === CARD,
      PaymentUtils.getCardNetworks(paymentMethodData.card_networks->Some),
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
    (NONE: SdkTypes.payment_method_type_wallet),
    [],
  ))

  let setWalletData = React.useCallback1(
    (
      requiredFields,
      initialValues,
      walletDict,
      isCardPayment,
      enabledCardSchemes,
      payment_method,
      payment_method_str,
      payment_method_type,
      payment_method_type_wallet,
      payment_experience,
    ) => {
      setWalletData(_ => (
        requiredFields,
        initialValues,
        walletDict,
        isCardPayment,
        enabledCardSchemes,
        payment_method,
        payment_method_str,
        payment_method_type,
        payment_method_type_wallet,
        payment_experience,
      ))
    },
    [setWalletData],
  )

  let getRequiredFieldsForButton = (
    paymentMethodData: AccountPaymentMethodType.payment_method_type,
    walletDict,
    billingAddress,
    shippingAddress,
    useIntentData,
  ) => {
    let eligibleConnectors = switch paymentMethodData.payment_method {
    | CARD =>
      paymentMethodData.card_networks
      ->Array.get(0)
      ->Option.mapOr([], network => network.eligible_connectors)
    | _ =>
      paymentMethodData.payment_experience
      ->Array.get(0)
      ->Option.mapOr([], experience => experience.eligible_connectors)
    }

    let requiredFieldsFromSource = if (
      accountPaymentMethodData
      ->Option.map(accountPaymentMethods =>
        accountPaymentMethods.collect_billing_details_from_wallets
      )
      ->Option.getOr(false) && !useIntentData
    ) {
      let requiredFieldsFromWallet = switch billingAddress {
      | Some(billingAddress) => AddressUtils.getFlatAddressDict(~billingAddress, ~shippingAddress)
      | None => SuperpositionHelper.extractFieldValuesFromPML(paymentMethodData.required_fields)
      }
      switch requiredFieldsFromWallet->Dict.get("payment_method_data.billing.address.country") {
      | Some("") | None =>
        requiredFieldsFromWallet->Dict.set("payment_method_data.billing.address.country", country)
      | _ => ()
      }
      requiredFieldsFromWallet
    } else {
      let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
        paymentMethodData.required_fields,
      )
      switch requiredFieldsFromPML->Dict.get("payment_method_data.billing.address.country") {
      | Some("") | None =>
        requiredFieldsFromPML->Dict.set("payment_method_data.billing.address.country", country)
      | _ => ()
      }
      requiredFieldsFromPML
    }

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      payment_method: paymentMethodData.payment_method_str,
      payment_method_type: paymentMethodData.payment_method_type,
      mandate_type: accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
      ->Option.getOr(NORMAL) === NORMAL
        ? "non_mandate"
        : "mandate",
      collect_billing_details_from_wallet_connector: "required",
      collect_shipping_details_from_wallet_connector: "required",
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
        paymentMethodData.payment_method === CARD,
        PaymentUtils.getCardNetworks(paymentMethodData.card_networks->Some),
        paymentMethodData.payment_method,
        paymentMethodData.payment_method_str,
        paymentMethodData.payment_method_type,
        paymentMethodData.payment_method_type_wallet,
        paymentMethodData.payment_experience,
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
      formDataRef,
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
