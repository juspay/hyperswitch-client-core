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
      cardNickname: Utils.getString(res, "cardNickname", defaultLocale.cardNickname),
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

let useLocaleDataFetch = () => {
  let apiFunction = CommonHooks.fetchApi
  let logger = LoggerHook.useLoggerHook()

  (~locale: option<SdkTypes.localeTypes>=None, ~timeout=10000) => {
    let localeString = SdkTypes.localeTypeToString(locale)
    let localeStringEndPoint = `https://dev.hyperswitch.io/assets/v1/locales/${localeString}`

    logger(
      ~logType=INFO,
      ~value="initialize Locale Strings API",
      ~category=API,
      ~eventName=S3_API,
      (),
    )

    apiFunction(
      ~uri=localeStringEndPoint,
      ~method_=Get,
      ~headers=Dict.make(),
      ~dontUseDefaultHeader=true,
      (),
    )
    ->GZipUtils.extractJson
    ->PromiseHelper.withTimeout(timeout, Null)
    ->Promise.then(data => {
      if data != Null {
        Promise.resolve(Some(getLocaleStringsFromJson(data)))
      } else {
        Promise.reject(Exn.raiseError("API Failed"))
      }
    })
    ->Promise.catch(_ => {
      logger(
        ~logType=ERROR,
        ~value=`Locale Strings API failed - ${localeStringEndPoint}`,
        ~category=API,
        ~eventName=S3_API,
        (),
      )
      Promise.resolve(None)
    })
  }
}
