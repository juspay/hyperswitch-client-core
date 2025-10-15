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
  ~payment_method_str: string,
  ~payment_method_type: string,
  ~payment_method_data=?,
  ~payment_type: PaymentMethodType.mandateType,
  ~appURL: option<string>=?,
  ~isNicknameSelected=false,
  ~payment_token=?,
  ~isSaveCardCheckboxVisible=?,
  ~isGuestCustomer,
  ~email=?,
  ~screen_height=?,
  ~screen_width=?,
  (),
): PaymentConfirmTypes.redirectType => {
  let isMandate = payment_type !== NORMAL
  {
    client_secret: nativeProp.clientSecret,
    return_url: ?Utils.getReturnUrl(~appId=nativeProp.hyperParams.appId, ~appURL),
    payment_method: payment_method_str,
    payment_method_type,
    ?payment_method_data,
    ?payment_token,
    ?email,
    // payment_type: payment_type_str,
    customer_acceptance: ?(
      payment_token->Option.isNone &&
      ((isNicknameSelected && isMandate) ||
      isMandate && !isNicknameSelected && !(isSaveCardCheckboxVisible->Option.getOr(false)) ||
      payment_type === NORMAL && isNicknameSelected ||
      payment_type === SETUP_MANDATE) &&
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
  ~appURL: option<string>=?,
  ~screen_height=?,
  ~screen_width=?,
  ~billing=?,
): PaymentConfirmTypes.redirectType => {
  client_secret: nativeProp.clientSecret,
  payment_method: "card",
  payment_token,
  card_cvc: ?(savedCardCvv->Option.isSome ? Some(savedCardCvv->Option.getOr("")) : None),
  return_url: ?Utils.getReturnUrl(~appId=nativeProp.hyperParams.appId, ~appURL),
  payment_method_data: ?billing->Option.map(address =>
    [("billing", address->Utils.getJsonObjectFromRecord)]
    ->Dict.fromArray
    ->JSON.Encode.object
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
let generateWalletConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~payment_token,
  ~payment_method_type,
): PaymentConfirmTypes.redirectType => {
  client_secret: nativeProp.clientSecret,
  payment_token,
  payment_method: "wallet",
  payment_method_type,
}

let generateClickToPayConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~checkoutResult: JSON.t,
  ~provider: string,
  ~email: string,
): string => {
  open Utils

  let dict = checkoutResult->getDictFromJson

  let ctpServiceDetails = switch provider->String.toLowerCase {
  | "mastercard" => {
      let headers = dict->getJsonObjectFromDict("headers")->getDictFromJson
      let merchantTransactionId = headers->getString("merchant-transaction-id", "")
      let xSrcFlowId = headers->getString("x-src-cx-flow-id", "")
      let checkoutResponseData =
        dict->getJsonObjectFromDict("checkoutResponseData")->getDictFromJson
      let correlationId = checkoutResponseData->getString("srcCorrelationId", "")

      [
        ("merchant_transaction_id", merchantTransactionId->JSON.Encode.string),
        ("correlation_id", correlationId->JSON.Encode.string),
        ("x_src_flow_id", xSrcFlowId->JSON.Encode.string),
        ("provider", "mastercard"->JSON.Encode.string),
      ]->Dict.fromArray
    }
  | "visa" => {
      let encryptedPayload = dict->getString("checkoutResponse", "")

      [
        ("encrypted_payload", encryptedPayload->JSON.Encode.string),
        ("provider", "visa"->JSON.Encode.string),
      ]->Dict.fromArray
    }
  | _ => Dict.make()
  }
  let paymentMethod = dict->getString("payment_method", "card")
  let paymentMethodType = dict->getString("payment_method_type", "debit")
  let confirmBody = [
    ("client_secret", nativeProp.clientSecret->JSON.Encode.string),
    ("payment_method", paymentMethod->JSON.Encode.string),
    ("payment_method_type", paymentMethodType->JSON.Encode.string),
    ("ctp_service_details", ctpServiceDetails->JSON.Encode.object),
  ]
  Console.log2("[ClickToPay] Confirm body before email:", confirmBody)
  let confirmBodyWithEmail = if provider->String.toLowerCase === "visa" {
    Array.concat(confirmBody, [("email", email->JSON.Encode.string)])
  } else {
    confirmBody
  }

  confirmBodyWithEmail->Dict.fromArray->JSON.Encode.object->JSON.stringify
}

let getActionType = (nextActionObj: option<PaymentConfirmTypes.nextAction>) => {
  let actionType = nextActionObj->Option.getOr({type_: "", redirectToUrl: ""})
  actionType.type_
}

let getCardNetworks = cardNetworks => {
  switch cardNetworks {
  | Some(cardNetworks) =>
    cardNetworks->Array.map((item: AccountPaymentMethodType.card_networks) => item.card_network)
  | None => []
  }
}
