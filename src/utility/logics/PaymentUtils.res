let checkIfMandate = (paymentType: PaymentMethodType.mandateType) => {
  paymentType == NEW_MANDATE || paymentType == SETUP_MANDATE
}

let showUseExisitingSavedCardsBtn = (
  ~isGuestCustomer,
  ~pmList,
  ~mandateType,
  ~displaySavedPaymentMethods,
) => {
  !isGuestCustomer &&
  pmList->Option.getOr([])->Array.length > 0 &&
  (mandateType == PaymentMethodType.NEW_MANDATE || mandateType == NORMAL) &&
  displaySavedPaymentMethods
}

let generateCardConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~paymentMethodStr: string,
  ~paymentMethodType: string,
  ~paymentMethodData=?,
  ~paymentType: PaymentMethodType.mandateType,
  ~appURL: option<string>=?,
  ~isNicknameSelected=false,
  ~paymentToken=?,
  ~isSaveCardCheckboxVisible=?,
  ~isGuestCustomer,
  ~email=?,
  ~screenHeight=?,
  ~screenWidth=?,
  (),
): PaymentConfirmTypes.redirectType => {
  let isMandate = paymentType !== NORMAL
  {
    clientSecret: nativeProp.clientSecret,
    returnUrl: ?Utils.getReturnUrl(~appId=nativeProp.hyperParams.appId, ~appURL),
    paymentMethod: paymentMethodStr,
    paymentMethodType,
    ?paymentMethodData,
    ?paymentToken,
    ?email,
    // paymentType: paymentTypeStr,
    customerAcceptance: ?(
      paymentToken->Option.isNone &&
      ((isNicknameSelected && isMandate) ||
      isMandate && !isNicknameSelected && !(isSaveCardCheckboxVisible->Option.getOr(false)) ||
      paymentType === NORMAL && isNicknameSelected ||
      paymentType === SETUP_MANDATE) &&
      !isGuestCustomer
        ? Some({
            {
              acceptanceType: "online",
              acceptedAt: Date.now()->Date.fromTime->Date.toISOString,
              online: {
                userAgent: ?nativeProp.hyperParams.userAgent,
              },
            }
          })
        : None
    ),
    browserInfo: {
      userAgent: ?nativeProp.hyperParams.userAgent,
      acceptHeader: "text\/html,application\/xhtml+xml,application\/xml;q=0.9,image\/webp,image\/apng,*\/*;q=0.8",
      language: SdkTypes.localeTypeToString(nativeProp.configuration.appearance.locale),
      colorDepth: 32,
      screenHeight: ?screenHeight->Option.map(Int.fromFloat),
      screenWidth: ?screenWidth->Option.map(Int.fromFloat),
      timeZone: Date.make()->Date.getTimezoneOffset,
      javaEnabled: true,
      javaScriptEnabled: true,
      deviceModel: ?nativeProp.hyperParams.deviceModel,
      osType: ?nativeProp.hyperParams.osType,
      osVersion: ?nativeProp.hyperParams.osVersion,
    },
  }
}

let generateSessionsTokenBody = (~clientSecret, ~wallet) => {
  [
    (
      "payment_id",
      String.split(clientSecret, "_secret_")
      ->Array.get(0)
      ->Option.getOr("")
      ->JSON.Encode.string,
    ),
    ("clientSecret", clientSecret->JSON.Encode.string),
    ("wallets", wallet->JSON.Encode.array),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
  ->JSON.stringify
}

let generateSavedCardConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~paymentToken,
  ~savedCardCvv,
  ~appURL: option<string>=?,
  ~screenHeight=?,
  ~screenWidth=?,
  ~billing=?,
): PaymentConfirmTypes.redirectType => {
  clientSecret: nativeProp.clientSecret,
  paymentMethod: "card",
  paymentToken,
  cardCvc: ?(savedCardCvv->Option.isSome ? Some(savedCardCvv->Option.getOr("")) : None),
  returnUrl: ?Utils.getReturnUrl(~appId=nativeProp.hyperParams.appId, ~appURL),
  paymentMethodData: ?billing->Option.map(address =>
    [("billing", address->Utils.getJsonObjectFromRecord)]
    ->Dict.fromArray
    ->JSON.Encode.object
  ),
  browserInfo: {
    userAgent: ?nativeProp.hyperParams.userAgent,
    acceptHeader: "text\/html,application\/xhtml+xml,application\/xml;q=0.9,image\/webp,image\/apng,*\/*;q=0.8",
    language: SdkTypes.localeTypeToString(nativeProp.configuration.appearance.locale),
    colorDepth: 32,
    screenHeight: ?screenHeight->Option.map(Int.fromFloat),
    screenWidth: ?screenWidth->Option.map(Int.fromFloat),
    timeZone: Date.make()->Date.getTimezoneOffset,
    javaEnabled: true,
    javaScriptEnabled: true,
    deviceModel: ?nativeProp.hyperParams.deviceModel,
    osType: ?nativeProp.hyperParams.osType,
    osVersion: ?nativeProp.hyperParams.osVersion,
  },
}
let generateWalletConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~paymentToken,
  ~paymentMethodType,
): PaymentConfirmTypes.redirectType => {
  clientSecret: nativeProp.clientSecret,
  paymentToken,
  paymentMethod: "wallet",
  paymentMethodType,
}

let getActionType = (nextActionObj: option<PaymentConfirmTypes.nextAction>) => {
  let actionType = nextActionObj->Option.getOr({type_: "", redirectToUrl: ""})
  actionType.type_
}

let getCardNetworks = cardNetworks => {
  switch cardNetworks {
  | Some(cardNetworks) =>
    cardNetworks->Array.map((item: AccountPaymentMethodType.cardNetworks) => item.cardNetwork)
  | None => []
  }
}
