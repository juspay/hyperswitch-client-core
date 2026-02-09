open CountryStateDataHookTypes

let decodeCountryArray: array<Js.Json.t> => array<country> = data => {
  data->Array.map(item => {
    switch item->Js.Json.decodeObject {
    | Some(res) => {
        country_code: Utils.getString(res, "country_code", ""),
        country_name: Utils.getString(res, "country_name", ""),
        country_flag: ?Utils.getOptionString(res, "country_flag"),
        phone_number_code: Utils.getString(res, "phone_number_code", ""),
        validation_regex: ?Utils.getOptionString(res, "validation_regex"),
        format_example: ?Utils.getOptionString(res, "format_example"),
        format_regex: ?Utils.getOptionString(res, "format_regex"),
        timeZones: Utils.getStrArray(res, "timeZones"),
      }
    | None => defaultTimeZone
    }
  })
}

let decodeStateJson: Js.Json.t => Dict.t<array<state>> = data => {
  data
  ->Utils.getDictFromJson
  ->Js.Dict.entries
  ->Array.map(item => {
    let (key, val) = item
    let newVal =
      val
      ->JSON.Decode.array
      ->Option.getOr([])
      ->Array.map(jsonItem => {
        let dictItem = jsonItem->Utils.getDictFromJson
        {
          label: Utils.getString(dictItem, "label", ""),
          value: Utils.getString(dictItem, "value", ""),
          code: Utils.getString(dictItem, "code", ""),
        }
      })
    (key, newVal)
  })
  ->Js.Dict.fromArray
}

let decodeJsonTocountryStateData: JSON.t => countryStateData = jsonData => {
  switch jsonData->Js.Json.decodeObject {
  | Some(res) => {
      let countryArr =
        res
        ->Js.Dict.get("country")
        ->Option.getOr([]->Js.Json.Array)
        ->Js.Json.decodeArray
        ->Option.getOr([])

      let statesDict =
        res
        ->Js.Dict.get("states")
        ->Option.getOr(Js.Json.Object(Js.Dict.empty()))
      {
        countries: decodeCountryArray(countryArr),
        states: decodeStateJson(statesDict),
      }
    }
  | None => {
      countries: [],
      states: Js.Dict.empty(),
    }
  }
}
open LocaleDataType
let getLocaleStrings: Js.Json.t => localeStrings = data => {
  switch data->Js.Json.decodeObject {
  | Some(res) => {
      locale: Utils.getString(res, "locale", defaultLocale.locale),
      localeDirection: Utils.getString(res, "localeDirection", defaultLocale.localeDirection),
      cardNumberLabel: Utils.getString(res, "cardNumberLabel", defaultLocale.cardNumberLabel),
      cardDetailsLabel: Utils.getString(res, "cardDetailsLabel", defaultLocale.cardDetailsLabel),
      inValidCardErrorText: Utils.getString(
        res,
        "inValidCardErrorText",
        defaultLocale.inValidCardErrorText,
      ),
      inCompleteCVCErrorText: Utils.getString(
        res,
        "inCompleteCVCErrorText",
        defaultLocale.inCompleteCVCErrorText,
      ),
      inValidCVCErrorText: Utils.getString(
        res,
        "inValidCVCErrorText",
        defaultLocale.inValidCVCErrorText,
      ),
      inCompleteExpiryErrorText: Utils.getString(
        res,
        "inCompleteExpiryErrorText",
        defaultLocale.inCompleteExpiryErrorText,
      ),
      inValidExpiryErrorText: Utils.getString(
        res,
        "inValidExpiryErrorText",
        defaultLocale.inValidExpiryErrorText,
      ),
      pastExpiryErrorText: Utils.getString(
        res,
        "pastExpiryErrorText",
        defaultLocale.pastExpiryErrorText,
      ),
      poweredBy: Utils.getString(res, "poweredBy", defaultLocale.poweredBy),
      validThruText: Utils.getString(res, "validThruText", defaultLocale.validThruText),
      sortCodeText: Utils.getString(res, "sortCodeText", defaultLocale.sortCodeText),
      accountNumberText: Utils.getString(res, "accountNumberText", defaultLocale.accountNumberText),
      cvcTextLabel: Utils.getString(res, "cvcTextLabel", defaultLocale.cvcTextLabel),
      emailLabel: Utils.getString(res, "emailLabel", defaultLocale.emailLabel),
      emailInvalidText: Utils.getString(res, "emailInvalidText", defaultLocale.emailInvalidText),
      emailEmptyText: Utils.getString(res, "emailEmptyText", defaultLocale.emailEmptyText),
      line1Label: Utils.getString(res, "line1Label", defaultLocale.line1Label),
      line1Placeholder: Utils.getString(res, "line1Placeholder", defaultLocale.line1Placeholder),
      line1EmptyText: Utils.getString(res, "line1EmptyText", defaultLocale.line1EmptyText),
      line2Label: Utils.getString(res, "line2Label", defaultLocale.line2Label),
      line2Placeholder: Utils.getString(res, "line2Placeholder", defaultLocale.line2Placeholder),
      cityLabel: Utils.getString(res, "cityLabel", defaultLocale.cityLabel),
      cityEmptyText: Utils.getString(res, "cityEmptyText", defaultLocale.cityEmptyText),
      postalCodeLabel: Utils.getString(res, "postalCodeLabel", defaultLocale.postalCodeLabel),
      postalCodeEmptyText: Utils.getString(
        res,
        "postalCodeEmptyText",
        defaultLocale.postalCodeEmptyText,
      ),
      stateLabel: Utils.getString(res, "stateLabel", defaultLocale.stateLabel),
      fullNameLabel: Utils.getString(res, "fullNameLabel", defaultLocale.fullNameLabel),
      fullNamePlaceholder: Utils.getString(
        res,
        "fullNamePlaceholder",
        defaultLocale.fullNamePlaceholder,
      ),
      countryLabel: Utils.getString(res, "countryLabel", defaultLocale.countryLabel),
      currencyLabel: Utils.getString(res, "currencyLabel", defaultLocale.currencyLabel),
      bankLabel: Utils.getString(res, "bankLabel", defaultLocale.bankLabel),
      redirectText: Utils.getString(res, "redirectText", defaultLocale.redirectText),
      bankDetailsText: Utils.getString(res, "bankDetailsText", defaultLocale.bankDetailsText),
      orPayUsing: Utils.getString(res, "orPayUsing", defaultLocale.orPayUsing),
      addNewCard: Utils.getString(res, "addNewCard", defaultLocale.addNewCard),
      useExisitingSavedCards: Utils.getString(
        res,
        "useExisitingSavedCards",
        defaultLocale.useExisitingSavedCards,
      ),
      saveCardDetails: Utils.getString(res, "saveCardDetails", defaultLocale.saveCardDetails),
      addBankAccount: Utils.getString(res, "addBankAccount", defaultLocale.addBankAccount),
      payNowButton: Utils.getString(res, "payNowButton", defaultLocale.payNowButton),
      cardNumberEmptyText: Utils.getString(
        res,
        "cardNumberEmptyText",
        defaultLocale.cardNumberEmptyText,
      ),
      cardExpiryDateEmptyText: Utils.getString(
        res,
        "cardExpiryDateEmptyText",
        defaultLocale.cardExpiryDateEmptyText,
      ),
      cvcNumberEmptyText: Utils.getString(
        res,
        "cvcNumberEmptyText",
        defaultLocale.cvcNumberEmptyText,
      ),
      enterFieldsText: Utils.getString(res, "enterFieldsText", defaultLocale.enterFieldsText),
      enterValidDetailsText: Utils.getString(
        res,
        "enterValidDetailsText",
        defaultLocale.enterValidDetailsText,
      ),
      card: Utils.getString(res, "card", defaultLocale.card),
      billingNameLabel: Utils.getString(res, "billingNameLabel", defaultLocale.billingNameLabel),
      cardHolderName: Utils.getString(res, "cardHolderName", defaultLocale.cardHolderName),
      cardNickname: Utils.getString(res, "cardNickname", defaultLocale.cardNickname),
      billingNamePlaceholder: Utils.getString(
        res,
        "billingNamePlaceholder",
        defaultLocale.billingNamePlaceholder,
      ),
      firstName: Utils.getString(res, "firstName", defaultLocale.firstName),
      lastName: Utils.getString(res, "lastName", defaultLocale.lastName),
      billingDetails: Utils.getString(res, "billingDetails", defaultLocale.billingDetails),
      requiredText: Utils.getString(res, "requiredText", defaultLocale.requiredText),
      cardHolderNameRequiredText: Utils.getString(
        res,
        "cardHolderNameRequiredText",
        defaultLocale.cardHolderNameRequiredText,
      ),
      invalidDigitsCardHolderNameError: Utils.getString(
        res,
        "invalidDigitsCardHolderNameError",
        defaultLocale.invalidDigitsCardHolderNameError,
      ),
      lastNameRequiredText: Utils.getString(
        res,
        "lastNameRequiredText",
        defaultLocale.lastNameRequiredText,
      ),
      nickNameLengthExceedError: Utils.getString(
        res,
        "nickNameLengthExceedError",
        defaultLocale.nickNameLengthExceedError,
      ),
      invalidDigitsNickNameError: Utils.getString(
        res,
        "invalidDigitsNickNameError",
        defaultLocale.invalidDigitsNickNameError,
      ),
      cardExpiresText: Utils.getString(res, "cardExpiresText", defaultLocale.cardExpiresText),
      addPaymentMethodLabel: Utils.getString(
        res,
        "addPaymentMethodLabel",
        defaultLocale.addPaymentMethodLabel,
      ),
      walletDisclaimer: Utils.getString(res, "walletDisclaimer", defaultLocale.walletDisclaimer),
      deletePaymentMethod: Utils.getString(
        res,
        "deletePaymentMethod",
        defaultLocale.deletePaymentMethod,
      ),
      enterValidCardNumberErrorText: Utils.getString(
        res,
        "enterValidCardNumberErrorText",
        defaultLocale.enterValidCardNumberErrorText,
      ),
      line2EmptyText: Utils.getString(res, "line2EmptyText", defaultLocale.line2EmptyText),
      postalCodeInvalidText: Utils.getString(
        res,
        "postalCodeInvalidText",
        defaultLocale.postalCodeInvalidText,
      ),
      stateEmptyText: Utils.getString(res, "stateEmptyText", defaultLocale.stateEmptyText),
      ibanEmptyText: Utils.getString(res, "ibanEmptyText", defaultLocale.ibanEmptyText),
      selectPaymentMethodText: Utils.getString(
        res,
        "selectPaymentMethodText",
        defaultLocale.selectPaymentMethodText,
      ),
      achBankDebitTermsPart1: Utils.getString(
        res,
        "achBankDebitTermsPart1",
        defaultLocale.achBankDebitTermsPart1,
      ),
      achBankDebitTermsPart2: Utils.getString(
        res,
        "achBankDebitTermsPart2",
        defaultLocale.achBankDebitTermsPart2,
      ),
      sepaDebitTermsPart1: Utils.getString(
        res,
        "sepaDebitTermsPart1",
        defaultLocale.sepaDebitTermsPart1,
      ),
      sepaDebitTermsPart2: Utils.getString(
        res,
        "sepaDebitTermsPart2",
        defaultLocale.sepaDebitTermsPart2,
      ),
      sepaDebitTermsPart3: Utils.getString(
        res,
        "sepaDebitTermsPart3",
        defaultLocale.sepaDebitTermsPart3,
      ),
      becsDebitTerms: Utils.getString(res, "becsDebitTerms", defaultLocale.becsDebitTerms),
      surchargeMsgAmountPart1: Utils.getString(
        res,
        "surchargeMsgAmountPart1",
        defaultLocale.surchargeMsgAmountPart1,
      ),
      surchargeMsgAmountPart2: Utils.getString(
        res,
        "surchargeMsgAmountPart2",
        defaultLocale.surchargeMsgAmountPart2,
      ),
      surchargeMsgAmountForCardPart1: Utils.getString(
        res,
        "surchargeMsgAmountForCardPart1",
        defaultLocale.surchargeMsgAmountForCardPart1,
      ),
      surchargeMsgAmountForCardPart2: Utils.getString(
        res,
        "surchargeMsgAmountForCardPart2",
        defaultLocale.surchargeMsgAmountForCardPart2,
      ),
      surchargeMsgAmountForOneClickWallets: Utils.getString(
        res,
        "surchargeMsgAmountForOneClickWallets",
        defaultLocale.surchargeMsgAmountForOneClickWallets,
      ),
      on: Utils.getString(res, "on", defaultLocale.on),
      \"and": Utils.getString(res, "and", defaultLocale.\"and"),
      nameEmptyText: Utils.getString(res, "nameEmptyText", defaultLocale.nameEmptyText),
      completeNameEmptyText: Utils.getString(
        res,
        "completeNameEmptyText",
        defaultLocale.completeNameEmptyText,
      ),
      billingDetailsText: Utils.getString(
        res,
        "billingDetailsText",
        defaultLocale.billingDetailsText,
      ),
      socialSecurityNumberLabel: Utils.getString(
        res,
        "socialSecurityNumberLabel",
        defaultLocale.socialSecurityNumberLabel,
      ),
      saveWalletDetails: Utils.getString(res, "saveWalletDetails", defaultLocale.saveWalletDetails),
      morePaymentMethods: Utils.getString(
        res,
        "morePaymentMethods",
        defaultLocale.morePaymentMethods,
      ),
      useExistingPaymentMethods: Utils.getString(
        res,
        "useExistingPaymentMethods",
        defaultLocale.useExistingPaymentMethods,
      ),
      nicknamePlaceholder: Utils.getString(
        res,
        "nicknamePlaceholder",
        defaultLocale.nicknamePlaceholder,
      ),
      cardExpiredText: Utils.getString(res, "cardExpiredText", defaultLocale.cardExpiredText),
      cardHeader: Utils.getString(res, "cardHeader", defaultLocale.cardHeader),
      cardBrandConfiguredErrorText: Utils.getString(
        res,
        "cardBrandConfiguredErrorText",
        defaultLocale.cardBrandConfiguredErrorText,
      ),
      currencyNetwork: Utils.getString(res, "currencyNetwork", defaultLocale.currencyNetwork),
      expiryPlaceholder: Utils.getString(res, "expiryPlaceholder", defaultLocale.expiryPlaceholder),
      dateOfBirth: Utils.getString(res, "dateOfBirth", defaultLocale.dateOfBirth),
      vpaIdLabel: Utils.getString(res, "vpaIdLabel", defaultLocale.vpaIdLabel),
      vpaIdEmptyText: Utils.getString(res, "vpaIdEmptyText", defaultLocale.vpaIdEmptyText),
      vpaIdInvalidText: Utils.getString(res, "vpaIdInvalidText", defaultLocale.vpaIdInvalidText),
      dateofBirthRequiredText: Utils.getString(
        res,
        "dateofBirthRequiredText",
        defaultLocale.dateofBirthRequiredText,
      ),
      dateOfBirthInvalidText: Utils.getString(
        res,
        "dateOfBirthInvalidText",
        defaultLocale.dateOfBirthInvalidText,
      ),
      dateOfBirthPlaceholderText: Utils.getString(
        res,
        "dateOfBirthPlaceholderText",
        defaultLocale.dateOfBirthPlaceholderText,
      ),
      formFundsInfoText: Utils.getString(res, "formFundsInfoText", defaultLocale.formFundsInfoText),
      formFundsCreditInfoTextPart1: Utils.getString(
        res,
        "formFundsCreditInfoTextPart1",
        defaultLocale.formFundsCreditInfoTextPart1,
      ),
      formFundsCreditInfoTextPart2: Utils.getString(
        res,
        "formFundsCreditInfoTextPart2",
        defaultLocale.formFundsCreditInfoTextPart2,
      ),
      formEditText: Utils.getString(res, "formEditText", defaultLocale.formEditText),
      formSaveText: Utils.getString(res, "formSaveText", defaultLocale.formSaveText),
      formSubmitText: Utils.getString(res, "formSubmitText", defaultLocale.formSubmitText),
      formSubmittingText: Utils.getString(
        res,
        "formSubmittingText",
        defaultLocale.formSubmittingText,
      ),
      formSubheaderBillingDetailsText: Utils.getString(
        res,
        "formSubheaderBillingDetailsText",
        defaultLocale.formSubheaderBillingDetailsText,
      ),
      formSubheaderCardText: Utils.getString(
        res,
        "formSubheaderCardText",
        defaultLocale.formSubheaderCardText,
      ),
      formSubheaderAccountTextPart1: Utils.getString(
        res,
        "formSubheaderAccountTextPart1",
        defaultLocale.formSubheaderAccountTextPart1,
      ),
      formSubheaderAccountTextPart2: Utils.getString(
        res,
        "formSubheaderAccountTextPart2",
        defaultLocale.formSubheaderAccountTextPart2,
      ),
      formHeaderReviewText: Utils.getString(
        res,
        "formHeaderReviewText",
        defaultLocale.formHeaderReviewText,
      ),
      formHeaderReviewTabLayoutTextPart1: Utils.getString(
        res,
        "formHeaderReviewTabLayoutTextPart1",
        defaultLocale.formHeaderReviewTabLayoutTextPart1,
      ),
      formHeaderReviewTabLayoutTextPart2: Utils.getString(
        res,
        "formHeaderReviewTabLayoutTextPart2",
        defaultLocale.formHeaderReviewTabLayoutTextPart2,
      ),
      formHeaderBankTextPart1: Utils.getString(
        res,
        "formHeaderBankTextPart1",
        defaultLocale.formHeaderBankTextPart1,
      ),
      formHeaderBankTextPart2: Utils.getString(
        res,
        "formHeaderBankTextPart2",
        defaultLocale.formHeaderBankTextPart2,
      ),
      formHeaderWalletTextPart1: Utils.getString(
        res,
        "formHeaderWalletTextPart1",
        defaultLocale.formHeaderWalletTextPart1,
      ),
      formHeaderWalletTextPart2: Utils.getString(
        res,
        "formHeaderWalletTextPart2",
        defaultLocale.formHeaderWalletTextPart2,
      ),
      formHeaderEnterCardText: Utils.getString(
        res,
        "formHeaderEnterCardText",
        defaultLocale.formHeaderEnterCardText,
      ),
      formHeaderSelectBankText: Utils.getString(
        res,
        "formHeaderSelectBankText",
        defaultLocale.formHeaderSelectBankText,
      ),
      formHeaderSelectWalletText: Utils.getString(
        res,
        "formHeaderSelectWalletText",
        defaultLocale.formHeaderSelectWalletText,
      ),
      formHeaderSelectAccountText: Utils.getString(
        res,
        "formHeaderSelectAccountText",
        defaultLocale.formHeaderSelectAccountText,
      ),
      formFieldACHRoutingNumberLabel: Utils.getString(
        res,
        "formFieldACHRoutingNumberLabel",
        defaultLocale.formFieldACHRoutingNumberLabel,
      ),
      formFieldSepaIbanLabel: Utils.getString(
        res,
        "formFieldSepaIbanLabel",
        defaultLocale.formFieldSepaIbanLabel,
      ),
      formFieldSepaBicLabel: Utils.getString(
        res,
        "formFieldSepaBicLabel",
        defaultLocale.formFieldSepaBicLabel,
      ),
      formFieldPixIdLabel: Utils.getString(
        res,
        "formFieldPixIdLabel",
        defaultLocale.formFieldPixIdLabel,
      ),
      formFieldBankAccountNumberLabel: Utils.getString(
        res,
        "formFieldBankAccountNumberLabel",
        defaultLocale.formFieldBankAccountNumberLabel,
      ),
      formFieldPhoneNumberLabel: Utils.getString(
        res,
        "formFieldPhoneNumberLabel",
        defaultLocale.formFieldPhoneNumberLabel,
      ),
      formFieldCountryCodeLabel: Utils.getString(
        res,
        "formFieldCountryCodeLabel",
        defaultLocale.formFieldCountryCodeLabel,
      ),
      formFieldBankNameLabel: Utils.getString(
        res,
        "formFieldBankNameLabel",
        defaultLocale.formFieldBankNameLabel,
      ),
      formFieldBankCityLabel: Utils.getString(
        res,
        "formFieldBankCityLabel",
        defaultLocale.formFieldBankCityLabel,
      ),
      formFieldCardHoldernamePlaceholder: Utils.getString(
        res,
        "formFieldCardHoldernamePlaceholder",
        defaultLocale.formFieldCardHoldernamePlaceholder,
      ),
      formFieldBankNamePlaceholder: Utils.getString(
        res,
        "formFieldBankNamePlaceholder",
        defaultLocale.formFieldBankNamePlaceholder,
      ),
      formFieldBankCityPlaceholder: Utils.getString(
        res,
        "formFieldBankCityPlaceholder",
        defaultLocale.formFieldBankCityPlaceholder,
      ),
      formFieldEmailPlaceholder: Utils.getString(
        res,
        "formFieldEmailPlaceholder",
        defaultLocale.formFieldEmailPlaceholder,
      ),
      formFieldPhoneNumberPlaceholder: Utils.getString(
        res,
        "formFieldPhoneNumberPlaceholder",
        defaultLocale.formFieldPhoneNumberPlaceholder,
      ),
      formFieldInvalidRoutingNumber: Utils.getString(
        res,
        "formFieldInvalidRoutingNumber",
        defaultLocale.formFieldInvalidRoutingNumber,
      ),
      infoCardRefId: Utils.getString(res, "infoCardRefId", defaultLocale.infoCardRefId),
      infoCardErrCode: Utils.getString(res, "infoCardErrCode", defaultLocale.infoCardErrCode),
      infoCardErrMsg: Utils.getString(res, "infoCardErrMsg", defaultLocale.infoCardErrMsg),
      infoCardErrReason: Utils.getString(res, "infoCardErrReason", defaultLocale.infoCardErrReason),
      linkRedirectionTextPart1: Utils.getString(
        res,
        "linkRedirectionTextPart1",
        defaultLocale.linkRedirectionTextPart1,
      ),
      linkRedirectionTextPart2: Utils.getString(
        res,
        "linkRedirectionTextPart2",
        defaultLocale.linkRedirectionTextPart2,
      ),
      linkExpiryInfoPart1: Utils.getString(
        res,
        "linkExpiryInfoPart1",
        defaultLocale.linkExpiryInfoPart1,
      ),
      linkExpiryInfoPart2: Utils.getString(
        res,
        "linkExpiryInfoPart2",
        defaultLocale.linkExpiryInfoPart2,
      ),
      payoutFromTextPart1: Utils.getString(
        res,
        "payoutFromTextPart1",
        defaultLocale.payoutFromTextPart1,
      ),
      payoutFromTextPart2: Utils.getString(
        res,
        "payoutFromTextPart2",
        defaultLocale.payoutFromTextPart2,
      ),
      payoutStatusFailedMessage: Utils.getString(
        res,
        "payoutStatusFailedMessage",
        defaultLocale.payoutStatusFailedMessage,
      ),
      payoutStatusPendingMessage: Utils.getString(
        res,
        "payoutStatusPendingMessage",
        defaultLocale.payoutStatusPendingMessage,
      ),
      payoutStatusSuccessMessage: Utils.getString(
        res,
        "payoutStatusSuccessMessage",
        defaultLocale.payoutStatusSuccessMessage,
      ),
      payoutStatusFailedText: Utils.getString(
        res,
        "payoutStatusFailedText",
        defaultLocale.payoutStatusFailedText,
      ),
      payoutStatusPendingText: Utils.getString(
        res,
        "payoutStatusPendingText",
        defaultLocale.payoutStatusPendingText,
      ),
      payoutStatusSuccessText: Utils.getString(
        res,
        "payoutStatusSuccessText",
        defaultLocale.payoutStatusSuccessText,
      ),
      pixCNPJInvalidText: Utils.getString(
        res,
        "pixCNPJInvalidText",
        defaultLocale.pixCNPJInvalidText,
      ),
      pixCNPJEmptyText: Utils.getString(res, "pixCNPJEmptyText", defaultLocale.pixCNPJEmptyText),
      pixCNPJLabel: Utils.getString(res, "pixCNPJLabel", defaultLocale.pixCNPJLabel),
      pixCNPJPlaceholder: Utils.getString(
        res,
        "pixCNPJPlaceholder",
        defaultLocale.pixCNPJPlaceholder,
      ),
      pixCPFInvalidText: Utils.getString(res, "pixCPFInvalidText", defaultLocale.pixCPFInvalidText),
      pixCPFEmptyText: Utils.getString(res, "pixCPFEmptyText", defaultLocale.pixCPFEmptyText),
      pixCPFLabel: Utils.getString(res, "pixCPFLabel", defaultLocale.pixCPFLabel),
      pixCPFPlaceholder: Utils.getString(res, "pixCPFPlaceholder", defaultLocale.pixCPFPlaceholder),
      pixKeyEmptyText: Utils.getString(res, "pixKeyEmptyText", defaultLocale.pixKeyEmptyText),
      pixKeyPlaceholder: Utils.getString(res, "pixKeyPlaceholder", defaultLocale.pixKeyPlaceholder),
      pixKeyLabel: Utils.getString(res, "pixKeyLabel", defaultLocale.pixKeyLabel),
      invalidCardHolderNameError: Utils.getString(
        res,
        "invalidCardHolderNameError",
        defaultLocale.invalidCardHolderNameError,
      ),
      invalidNickNameError: Utils.getString(
        res,
        "invalidNickNameError",
        defaultLocale.invalidNickNameError,
      ),
      cardTermsPart1: Utils.getString(res, "cardTermsPart1", defaultLocale.cardTermsPart1),
      cardTermsPart2: Utils.getString(res, "cardTermsPart2", defaultLocale.cardTermsPart2),
      useExisitingSavedCardsWeb: Utils.getString(
        res,
        "useExisitingSavedCardsWeb",
        defaultLocale.useExisitingSavedCardsWeb,
      ),
      unsupportedCardErrorText: Utils.getString(
        res,
        "unsupportedCardErrorText",
        defaultLocale.unsupportedCardErrorText,
      ),
      selectCardBrand: Utils.getString(res, "selectCardBrand", defaultLocale.selectCardBrand),
      enterValidDigitsText: Utils.getString(
        res,
        "enterValidDigitsText",
        defaultLocale.enterValidDigitsText,
      ),
      digitsText: Utils.getString(res, "digitsText", defaultLocale.digitsText),
      enterValidIban: Utils.getString(res, "enterValidIban", defaultLocale.enterValidIban),
      mandatoryFieldText: Utils.getString(
        res,
        "mandatoryFieldText",
        defaultLocale.mandatoryFieldText,
      ),
      disclaimerTextAchTransfer: Utils.getString(
        res,
        "disclaimerTextAchTransfer",
        defaultLocale.disclaimerTextAchTransfer,
      ),
      instructionalTextOfAchTransfer: Utils.getString(
        res,
        "instructionalTextOfAchTransfer",
        defaultLocale.instructionalTextOfAchTransfer,
      ),
      accountDetailsText: Utils.getString(
        res,
        "accountDetailsText",
        defaultLocale.accountDetailsText,
      ),
      achBankTransferText: Utils.getString(
        res,
        "achBankTransferText",
        defaultLocale.achBankTransferText,
      ),
      bankName: Utils.getString(res, "bankName", defaultLocale.bankName),
      swiftCode: Utils.getString(res, "swiftCode", defaultLocale.swiftCode),
      doneText: Utils.getString(res, "doneText", defaultLocale.doneText),
      copyToClipboard: Utils.getString(res, "copyToClipboard", defaultLocale.copyToClipboard),
    }
  | None => defaultLocale
  }
}

let getLocaleStringsFromJson: Js.Json.t => localeStrings = jsonData => {
  switch jsonData->Js.Json.decodeObject {
  | Some(res) => getLocaleStrings(res->Utils.getJsonObjectFromRecord)
  | None => defaultLocale
  }
}

let useFetchDataFromS3WithGZipDecoding = () => {
  let apiFunction = APIUtils.fetchApi
  let logger = LoggerHook.useLoggerHook()
  let baseUrl = GlobalHooks.useGetAssetUrlWithVersion()()

  (~s3Path: string, ~decodeJsonToRecord, ~cache=false) => {
    let endpoint = if cache {
      `${baseUrl}${s3Path}`
    } else {
      let timestamp = Js.Date.now()->Float.toString
      `${baseUrl}${s3Path}?v=${timestamp}`
    }
    logger(
      ~logType=INFO,
      ~value=`S3 API called - ${endpoint}`,
      ~category=API,
      ~eventName=S3_API,
      (),
    )
    let headers = Dict.make()
    headers->Dict.set("Accept-Encoding", "br, gzip")
    apiFunction(~uri=endpoint, ~method_=#GET, ~headers, ~dontUseDefaultHeader=true)
    ->Promise.then(resp => resp->Fetch.Response.json)
    ->Promise.then(data => {
      let countryStaterecord = decodeJsonToRecord(data)
      Promise.resolve(Some(countryStaterecord))
    })
    ->Promise.catch(_ => {
      logger(
        ~logType=ERROR,
        ~value=`S3 API failed - ${endpoint}`,
        ~category=API,
        ~eventName=S3_API,
        (),
      )
      Promise.resolve(None)
    })
  }
}
