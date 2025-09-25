let checkIfMandate = (paymentType: PaymentMethodListType.mandateType) => {
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
  (mandateType == PaymentMethodListType.NEW_MANDATE || mandateType == NORMAL) &&
  displaySavedPaymentMethods
}

let generateCardConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~prop: PaymentMethodListType.payment_method_type,
  ~payment_method_data=?,
  ~allApiData: AllApiDataContext.allApiData,
  ~isNicknameSelected=false,
  ~payment_token=?,
  ~isSaveCardCheckboxVisible=?,
  ~isGuestCustomer,
  ~email=?,
  ~screen_height=?,
  ~screen_width=?,
  (),
): PaymentMethodListType.redirectType => {
  let isMandate = allApiData.additionalPMLData.mandateType->checkIfMandate
  {
    client_secret: nativeProp.clientSecret,
    return_url: ?Utils.getReturnUrl(
      ~appId=nativeProp.hyperParams.appId,
      ~appURL=allApiData.additionalPMLData.redirect_url,
    ),
    payment_method: prop.payment_method_str,
    payment_method_type: ?Some(prop.payment_method_type),
    ?payment_method_data,
    ?payment_token,
    ?email,
    customer_acceptance: ?(
      payment_token->Option.isNone &&
      ((isNicknameSelected && isMandate) ||
      isMandate && !isNicknameSelected && !(isSaveCardCheckboxVisible->Option.getOr(false)) ||
      allApiData.additionalPMLData.mandateType == NORMAL && isNicknameSelected ||
      allApiData.additionalPMLData.mandateType == SETUP_MANDATE) &&
      !isGuestCustomer
        ? Some({
            {
              acceptance_type: "online",
              accepted_at: Date.now()->Date.fromTime->Date.toISOString,
              online: {
                user_agent: ?nativeProp.hyperParams.userAgent,
              },
            }
          })
        : None
    ),
    browser_info: {
      user_agent: ?nativeProp.hyperParams.userAgent,
      accept_header: "text\/html,application\/xhtml+xml,application\/xml;q=0.9,image\/webp,image\/apng,*\/*;q=0.8",
      language: SdkTypes.localeTypeToString(nativeProp.configuration.appearance.locale),
      color_depth: 32,
      screen_height: ?screen_height->Option.map(Int.fromFloat),
      screen_width: ?screen_width->Option.map(Int.fromFloat),
      time_zone: Date.make()->Date.getTimezoneOffset,
      java_enabled: true,
      java_script_enabled: true,
      device_model: ?nativeProp.hyperParams.device_model,
      os_type: ?nativeProp.hyperParams.os_type,
      os_version: ?nativeProp.hyperParams.os_version,
    },
  }
}

let checkIsCVCRequired = (pmObject: SdkTypes.savedDataType) =>
  switch pmObject {
  | SAVEDLISTCARD(obj) => obj.requiresCVV
  | _ => false
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
    ("client_secret", clientSecret->JSON.Encode.string),
    ("wallets", wallet->JSON.Encode.array),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
  ->JSON.stringify
}

let generateSavedCardConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~payment_token,
  ~savedCardCvv,
): PaymentMethodListType.redirectType => {
  client_secret: nativeProp.clientSecret,
  payment_method: "card",
  payment_token,
  card_cvc: ?(savedCardCvv->Option.isSome ? Some(savedCardCvv->Option.getOr("")) : None),
}
let generateWalletConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~payment_token,
  ~payment_method_type,
): PaymentMethodListType.redirectType => {
  client_secret: nativeProp.clientSecret,
  payment_token,
  payment_method: "wallet",
  payment_method_type,
}

let getActionType = (nextActionObj: option<PaymentConfirmTypes.nextAction>) => {
  let actionType = nextActionObj->Option.getOr({type_: "", redirectToUrl: ""})
  actionType.type_
}

let getCardNetworks = cardNetworks => {
  switch cardNetworks {
  | Some(cardNetworks) =>
    cardNetworks->Array.map((item: PaymentMethodListType.card_networks) => item.card_network)
  | None => []
  }
}
