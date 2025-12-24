type walletDataRecord = {
  missingRequiredFields: array<SuperpositionTypes.fieldConfig>,
  initialValues: Dict.t<JSON.t>,
  walletDict: Dict.t<JSON.t>,
  isCardPayment: bool,
  enabledCardSchemes: array<string>,
  paymentMethodData: AccountPaymentMethodType.payment_method_type,
  billingAddress: option<SdkTypes.addressDetails>,
  shippingAddress: option<SdkTypes.addressDetails>,
  useIntentData: bool,
}

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
    string,
  ),
  getRequiredFieldsForButton: (
    AccountPaymentMethodType.payment_method_type,
    RescriptCore.Dict.t<Core__JSON.t>,
    option<SdkTypes.addressDetails>,
    option<SdkTypes.addressDetails>,
    bool,
    option<RescriptCore.Dict.t<RescriptCore.JSON.t>>,
  ) => (bool, RescriptCore.Dict.t<Core__JSON.t>, string),
  country: string,
  setCountry: option<string> => unit,
  setInitialValueCountry: string => unit,
  walletData: walletDataRecord,
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
  getRequiredFieldsForTabs: (_, _, _) => ([], Dict.make(), false, [], false, ""),
  getRequiredFieldsForButton: (_, _, _, _, _, _) => (true, Dict.make(), ""),
  country: SdkTypes.defaultCountry,
  setCountry: _ => (),
  setInitialValueCountry: _ => (),
  walletData: {
    missingRequiredFields: [],
    initialValues: Dict.make(),
    walletDict: Dict.make(),
    isCardPayment: false,
    enabledCardSchemes: [],
    paymentMethodData: {
      payment_method: OTHERS,
      payment_method_str: "",
      payment_method_type: "",
      payment_method_type_wallet: NONE,
      card_networks: [],
      bank_names: [],
      payment_experience: [],
      required_fields: Dict.make(),
    },
    billingAddress: None,
    shippingAddress: None,
    useIntentData: false,
  },
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

  let (country, setCountry) = React.useState(_ => None)
  let (initialValueCountry, setInitialValueCountry) = React.useState(_ =>
    nativeProp.hyperParams.country
  )

  let setCountry = React.useCallback1(country => {
    setCountry(_ => country)
  }, [setCountry])

  let setInitialValueCountry = React.useCallback1(country => {
    setInitialValueCountry(_ => country)
  }, [setInitialValueCountry])

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

    let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
      paymentMethodData.required_fields,
    )

    let defaultCountry = switch requiredFieldsFromPML->Dict.get(
      "payment_method_data.billing.address.country",
    ) {
    | Some("") | None => nativeProp.hyperParams.country
    | Some(country) => country
    }

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      payment_method: paymentMethodData.payment_method_str,
      payment_method_type: paymentMethodData.payment_method_type,
      mandate_type: accountPaymentMethodData
      ->Option.map(data => data.payment_type === NORMAL ? "non_mandate" : "mandate")
      ->Option.getOr("non_mandate"),
      collect_billing_details_from_wallet_connector: "required",
      collect_shipping_details_from_wallet_connector: "required",
      country: switch country {
      | Some(val) => val
      | None => defaultCountry
      },
    }

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

    // Validate CountrySelect fields against their allowed options
    missingRequiredFields->Array.forEach(field => {
      switch field.fieldType {
      | CountrySelect => {
          let currentCountry =
            initialValues
            ->Dict.get(field.outputPath)
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr(country->Option.getOr(nativeProp.hyperParams.country))

          let validatedCountry =
            field.options->Array.includes(currentCountry)
              ? currentCountry
              : field.options->Array.get(0)->Option.getOr(SdkTypes.defaultCountry)

          initialValues->Dict.set(field.outputPath, JSON.Encode.string(validatedCountry))
        }
      | _ => ()
      }
    })

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
      defaultCountry,
    )
  }

  let (walletData, setWalletData) = React.useState(_ => {
    missingRequiredFields: [],
    initialValues: Dict.make(),
    walletDict: Dict.make(),
    isCardPayment: false,
    enabledCardSchemes: [],
    paymentMethodData: {
      payment_method: OTHERS,
      payment_method_str: "",
      payment_method_type: "",
      payment_method_type_wallet: NONE,
      card_networks: [],
      bank_names: [],
      payment_experience: [],
      required_fields: Dict.make(),
    },
    billingAddress: None,
    shippingAddress: None,
    useIntentData: false,
  })

  let setWalletData = React.useCallback1(
    (
      ~missingRequiredFields,
      ~initialValues,
      ~walletDict,
      ~isCardPayment,
      ~enabledCardSchemes,
      ~paymentMethodData,
      ~billingAddress,
      ~shippingAddress,
      ~useIntentData,
    ) => {
      setWalletData(_ => {
        missingRequiredFields,
        initialValues,
        walletDict,
        isCardPayment,
        enabledCardSchemes,
        paymentMethodData,
        billingAddress,
        shippingAddress,
        useIntentData,
      })
    },
    [setWalletData],
  )

  let getRequiredFieldsForButton = (
    paymentMethodData: AccountPaymentMethodType.payment_method_type,
    walletDict,
    billingAddress,
    shippingAddress,
    useIntentData,
    formData,
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
        requiredFieldsFromWallet->Dict.set(
          "payment_method_data.billing.address.country",
          country->Option.getOr(nativeProp.hyperParams.country),
        )
      | _ => ()
      }
      requiredFieldsFromWallet
    } else {
      let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
        paymentMethodData.required_fields,
      )
      switch requiredFieldsFromPML->Dict.get("payment_method_data.billing.address.country") {
      | Some("") | None =>
        requiredFieldsFromPML->Dict.set(
          "payment_method_data.billing.address.country",
          country->Option.getOr(nativeProp.hyperParams.country),
        )
      | _ => ()
      }
      requiredFieldsFromPML
    }

    let defaultCountry = switch requiredFieldsFromSource->Dict.get(
      "payment_method_data.billing.address.country",
    ) {
    | Some("") | None => nativeProp.hyperParams.country
    | Some(country) => country
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
      country: switch country {
      | Some(val) => val
      | None => defaultCountry
      },
    }

    let (_requiredFields, missingRequiredFields, initialValues) = getSuperpositionFinalFields(
      eligibleConnectors,
      configParams,
      requiredFieldsFromSource,
    )

    let isFieldsMissing = missingRequiredFields->Array.length > 0

    if isFieldsMissing {
      setWalletData(
        ~missingRequiredFields,
        ~initialValues=switch formData {
        | Some(data) =>
          Utils.pruneUnusedFieldsFromDict(
            data,
            "",
            _requiredFields->Array.map(field => field.outputPath),
          )
        | None => initialValues
        },
        ~walletDict,
        ~isCardPayment=paymentMethodData.payment_method === CARD,
        ~enabledCardSchemes=PaymentUtils.getCardNetworks(paymentMethodData.card_networks->Some),
        ~paymentMethodData,
        ~billingAddress,
        ~shippingAddress,
        ~useIntentData,
      )
      setSheetType(DynamicFieldsSheet)
    }

    (isFieldsMissing, initialValues, defaultCountry)
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
      country: country->Option.getOr(initialValueCountry),
      setCountry,
      setInitialValueCountry,
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
