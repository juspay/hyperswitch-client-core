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
      cardDetailsLabel: Utils.getString(res, "cardDetailsLabel", defaultLocale.cardDetailsLabel),
      cardNumberLabel: Utils.getString(res, "cardNumberLabel", defaultLocale.cardNumberLabel),
      localeDirection: Utils.getString(res, "localeDirection", defaultLocale.localeDirection),
      inValidCardErrorText: Utils.getString(
        res,
        "inValidCardErrorText",
        defaultLocale.inValidCardErrorText,
      ),
      unsupportedCardErrorText: Utils.getString(
        res,
        "unsupportedCardErrorText",
        defaultLocale.unsupportedCardErrorText,
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
      cvcTextLabel: Utils.getString(res, "cvcTextLabel", defaultLocale.cvcTextLabel),
      emailLabel: Utils.getString(res, "emailLabel", defaultLocale.emailLabel),
      emailInvalidText: Utils.getString(res, "emailInvalidText", defaultLocale.emailInvalidText),
      emailEmptyText: Utils.getString(res, "emailEmptyText", defaultLocale.emailEmptyText),
      accountNumberText: Utils.getString(res, "accountNumberText", defaultLocale.accountNumberText),
      fullNameLabel: Utils.getString(res, "fullNameLabel", defaultLocale.fullNameLabel),
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
      becsDebitTerms: Utils.getString(res, "becsDebitTerms", defaultLocale.becsDebitTerms),
      cardTermsPart1: Utils.getString(res, "cardTermsPart1", defaultLocale.cardTermsPart1),
      cardTermsPart2: Utils.getString(res, "cardTermsPart2", defaultLocale.cardTermsPart2),
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
      billingNamePlaceholder: Utils.getString(
        res,
        "billingNamePlaceholder",
        defaultLocale.billingNamePlaceholder,
      ),
      cardHolderName: Utils.getString(res, "cardHolderName", defaultLocale.cardHolderName),
      nicknamePlaceholder: Utils.getString(
        res,
        "nicknamePlaceholder",
        defaultLocale.nicknamePlaceholder,
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
      invalidDigitsNickNameError: Utils.getString(
        res,
        "invalidDigitsNickNameError",
        defaultLocale.invalidDigitsNickNameError,
      ),
      lastNameRequiredText: Utils.getString(
        res,
        "lastNameRequiredText",
        defaultLocale.lastNameRequiredText,
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
        defaultLocale.deletePaymentMethod->Option.getOr("delete"),
      ),
      enterValidDigitsText: Utils.getString(
        res,
        "enterValidDigitsText",
        defaultLocale.enterValidDigitsText,
      ),
      digitsText: Utils.getString(res, "digitsText", defaultLocale.digitsText),
      enterValidIban: Utils.getString(res, "enterValidIban", defaultLocale.enterValidIban),
      selectCardBrand: Utils.getString(res, "selectCardBrand", defaultLocale.selectCardBrand),
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
      formFieldACHRoutingNumberLabel: Utils.getString(
        res,
        "formFieldACHRoutingNumberLabel",
        defaultLocale.formFieldACHRoutingNumberLabel,
      ),
      swiftCode: Utils.getString(res, "swiftCode", defaultLocale.swiftCode),
      doneText: Utils.getString(res, "doneText", defaultLocale.doneText),
      copyToClipboard: Utils.getString(res, "copyToClipboard", defaultLocale.copyToClipboard),
      currencyNetwork: Utils.getString(res, "currencyNetwork", defaultLocale.currencyNetwork),
      formFieldPhoneNumberLabel: Utils.getString(
        res,
        "formFieldPhoneNumberLabel",
        defaultLocale.formFieldPhoneNumberLabel,
      ),
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

//-
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
    apiFunction(~uri=endpoint, ~method_=Get, ~headers, ~dontUseDefaultHeader=true, ())
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
