type walletDataRecord = {
  missingRequiredFields: array<SuperpositionTypes.fieldConfig>,
  initialValues: Dict.t<JSON.t>,
  walletDict: Dict.t<JSON.t>,
  isCardPayment: bool,
  enabledCardSchemes: array<string>,
  paymentMethodData: ClientResponseType.paymentMethodEnabled,
  billingAddress: option<SdkTypes.addressDetails>,
  shippingAddress: option<SdkTypes.addressDetails>,
  useIntentData: bool,
}

type sheetType = ButtonSheet | DynamicFieldsSheet

type eligibilityStatus = Denied | Allowed | Pending

type dynamicFieldsData = {
  formDataRef: option<React.ref<RescriptCore.Dict.t<JSON.t>>>,
  sheetType: sheetType,
  setSheetType: sheetType => unit,
  getRequiredFieldsForTabs: (
    ClientResponseType.paymentMethodEnabled,
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
    ClientResponseType.paymentMethodEnabled,
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
  eligibilityStatus: eligibilityStatus,
  setEligibilityStatus: (eligibilityStatus => eligibilityStatus) => unit,
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
      payment_experience: [],
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
  eligibilityStatus: Allowed,
  setEligibilityStatus: _ => (),
})

module Provider = {
  let make = React.Context.provider(dynamicFieldsContext)
}

let buildIntentData = (flatByWritePath: Dict.t<string>): JSON.t => {
  let prefix = "payment_method_data."
  let byReadPath = Dict.make()
  flatByWritePath
  ->Dict.toArray
  ->Array.forEach(((writePath, value)) =>
    byReadPath->Dict.set(
      writePath->String.startsWith(prefix)
        ? writePath->String.sliceToEnd(~start=prefix->String.length)
        : writePath,
      value,
    )
  )
  byReadPath->SuperpositionHelper.convertFlatDictToNestedObject->JSON.Encode.object
}

let intentBillingCountry = (intentData: JSON.t) =>
  CommonUtils.getStringAtPath(intentData->Utils.getDictFromJson, "billing.address.country")

let withCountry = (intentData: JSON.t, country: string): JSON.t => {
  let root = intentData->Utils.getDictFromJson->Dict.copy
  let billing =
    root->Dict.get("billing")->Option.mapOr(Dict.make(), Utils.getDictFromJson)->Dict.copy
  let address =
    billing->Dict.get("address")->Option.mapOr(Dict.make(), Utils.getDictFromJson)->Dict.copy
  address->Dict.set("country", country->JSON.Encode.string)
  billing->Dict.set("address", address->JSON.Encode.object)
  root->Dict.set("billing", billing->JSON.Encode.object)
  root->JSON.Encode.object
}

let prepareIntentData = (intentData: JSON.t, fallbackCountry: string) =>
  switch intentData->intentBillingCountry {
  | Some(country) if country !== "" => (intentData, country)
  | _ => (intentData->withCountry(fallbackCountry), fallbackCountry)
  }

@react.component
let make = (~children) => {
  let formDataRef = Some(React.useRef(Dict.make()))
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (clientData, _, sdkConfigData) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let superpositionConfig = sdkConfigData->Option.getOr(SdkConfigTypes.defaultSdkConfigValue)
  let profile = superpositionConfig.account_config->Option.flatMap(ac => ac.profile)
  let collectBillingDetailsFromWalletConnector = SdkConfigParser.getCollectBillingDetailsFromWalletConnector(
    profile,
  )
  let collectShippingDetailsFromWalletConnector = SdkConfigParser.getCollectShippingDetailsFromWalletConnector(
    profile,
  )
  let getSuperpositionFinalFields = ConfigurationService.useConfigurationService(
    ~rawConfigs=superpositionConfig.raw_configs,
  )

  let (profile_id, processor_merchant_id, organization_id) = SdkConfigParser.getProfileContext(
    superpositionConfig.context_used,
  )

  let (sheetType, setSheetType) = React.useState(_ => ButtonSheet)
  let setSheetType = React.useCallback1(val => {
    setSheetType(_ => val)
  }, [setSheetType])

  let (country, setCountry) = React.useState(_ => None)
  let (initialValueCountry, setInitialValueCountry) = React.useState(_ =>
    nativeProp.sdkParams.country
  )

  let setCountry = React.useCallback1(country => {
    setCountry(_ => country)
  }, [setCountry])

  let setInitialValueCountry = React.useCallback1(country => {
    setInitialValueCountry(_ => country)
  }, [setInitialValueCountry])

  let getRequiredFieldsForTabs = (
    paymentMethodData: ClientResponseType.paymentMethodEnabled,
    formData,
    isScreenFocus,
  ) => {
    let eligibleConnectors =
      SdkConfigParser.getEligibleConnectorsFromPaymentMethods(
        superpositionConfig.payment_methods,
        paymentMethodData.payment_method_str,
        paymentMethodData.payment_method_type,
      )->Array.map(JSON.Encode.string)

    let rawIntentData =
      clientData
      ->Option.map(data => data.intent_data.raw_intent_data)
      ->Option.getOr(Dict.make()->JSON.Encode.object)

    let (intentData, defaultCountry) = prepareIntentData(
      rawIntentData,
      nativeProp.sdkParams.country,
    )

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      payment_method: paymentMethodData.payment_method_str,
      payment_method_type: paymentMethodData.payment_method_type,
      mandate_type: clientData
      ->Option.map(data => data.intent_data.payment_type === NORMAL ? "non_mandate" : "mandate")
      ->Option.getOr("non_mandate"),
      always_collect_billing_details_from_wallet_connector: collectBillingDetailsFromWalletConnector,
      always_collect_shipping_details_from_wallet_connector: collectShippingDetailsFromWalletConnector,
      country: switch country {
      | Some(val) => val
      | None => defaultCountry
      },
      platform: WebKit.platformGroup,
      profile_id: ?profile_id,
      processor_merchant_id: ?processor_merchant_id,
      organization_id: ?organization_id,
    }

    let (_requiredFields, missingRequiredFields, initialValues) = getSuperpositionFinalFields(
      eligibleConnectors,
      configParams,
      intentData,
    )

    missingRequiredFields->Array.forEach(field => {
      let isCountryDropdown = field.fieldRenderType === Country
      if isCountryDropdown {
        let currentCountry =
          initialValues
          ->Dict.get(field.confirmRequestWritePath)
          ->Option.flatMap(JSON.Decode.string)
          ->Option.getOr(country->Option.getOr(nativeProp.sdkParams.country))

        let validatedCountry =
          field.dropdownOptions->Option.getOr([])->Array.includes(currentCountry)
            ? currentCountry
            : field.dropdownOptions
              ->Option.getOr([])
              ->Array.get(0)
              ->Option.getOr(SdkTypes.defaultCountry)

        initialValues->Dict.set(field.confirmRequestWritePath, JSON.Encode.string(validatedCountry))
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
      payment_experience: [],
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
    paymentMethodData: ClientResponseType.paymentMethodEnabled,
    walletDict,
    billingAddress,
    shippingAddress,
    useIntentData,
    formData,
  ) => {
    let eligibleConnectors =
      SdkConfigParser.getEligibleConnectorsFromPaymentMethods(
        superpositionConfig.payment_methods,
        paymentMethodData.payment_method_str,
        paymentMethodData.payment_method_type,
      )->Array.map(JSON.Encode.string)

    let rawIntentData = if (
      SdkConfigParser.getCollectBillingDetailsFromWalletConnector(
        superpositionConfig.account_config->Option.flatMap(ac => ac.profile),
      ) && !useIntentData
    ) {
      switch billingAddress {
      | Some(billingAddress) =>
        AddressUtils.getFlatAddressDict(~billingAddress, ~shippingAddress)->buildIntentData
      | None => Dict.make()->JSON.Encode.object
      }
    } else {
      clientData
      ->Option.map(data => data.intent_data.raw_intent_data)
      ->Option.getOr(Dict.make()->JSON.Encode.object)
    }

    let (intentData, defaultCountry) = prepareIntentData(
      rawIntentData,
      country->Option.getOr(nativeProp.sdkParams.country),
    )

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      payment_method: paymentMethodData.payment_method_str,
      payment_method_type: paymentMethodData.payment_method_type,
      mandate_type: clientData
      ->Option.map(data => data.intent_data.payment_type)
      ->Option.getOr(NORMAL) === NORMAL
        ? "non_mandate"
        : "mandate",
      always_collect_billing_details_from_wallet_connector: collectBillingDetailsFromWalletConnector,
      always_collect_shipping_details_from_wallet_connector: collectShippingDetailsFromWalletConnector,
      country: switch country {
      | Some(val) => val
      | None => defaultCountry
      },
      platform: WebKit.platformGroup,
      profile_id: ?profile_id,
      processor_merchant_id: ?processor_merchant_id,
      organization_id: ?organization_id,
    }

    let (_requiredFields, missingRequiredFields, initialValues) = getSuperpositionFinalFields(
      eligibleConnectors,
      configParams,
      intentData,
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
            _requiredFields->Array.map(field => field.confirmRequestWritePath),
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

  let (eligibilityStatus, setEligibilityStatus) = React.useState(_ => Allowed)

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
      eligibilityStatus,
      setEligibilityStatus,
    }>
    children
  </Provider>
}
