let checkIfMandate = (paymentType: PaymentMethodType.mandateType) => {
  paymentType == NEW_MANDATE || paymentType == SETUP_MANDATE
}

let buildVaultCard = (data: option<JSON.t>): option<JSON.t> => {
  let body =
    data
    ->Option.flatMap(JSON.Decode.object)
    ->Option.flatMap(obj =>
      switch obj->Dict.get("tokens") {
      | Some(_) as tokens => tokens
      | None => obj->Dict.get("raw")
      }
    )
  let card =
    body
    ->Option.flatMap(JSON.Decode.object)
    ->Option.map(obj =>
      switch obj->Dict.get("vault_card")->Option.flatMap(JSON.Decode.object) {
      | Some(inner) => inner
      | None => obj
      }
    )

  card->Option.flatMap(card => {
    let getStr = key => card->Dict.get(key)->Option.flatMap(JSON.Decode.string)
    let cardNumber = getStr("card_number")

    let (expMonth, expYear) = switch (getStr("card_exp_month"), getStr("card_exp_year")) {
    | (Some(_), Some(_)) as split => split
    | _ =>
      switch getStr("expiration_date") {
      | Some(exp) if exp->String.includes("/") =>
        let parts = exp->String.split("/")->Array.map(String.trim)
        (parts->Array.get(0), parts->Array.get(1))
      | Some(exp) if exp->String.length >= 4 =>
        (Some(exp->String.slice(~start=0, ~end=2)), Some(exp->String.sliceToEnd(~start=2)))
      | _ => (None, None)
      }
    }

    let lastFour = switch getStr("last_four") {
    | Some(_) as v => v
    | None => cardNumber->Option.map(cn => cn->String.sliceToEnd(~start=cn->String.length - 4))
    }
    let binNumber = switch getStr("bin_number") {
    | Some(_) as v => v
    | None =>
      cardNumber->Option.flatMap(cn =>
        cn->String.length >= 6 ? Some(cn->String.slice(~start=0, ~end=6)) : None
      )
    }

    let out = Dict.make()
    let setStr = (key, valOpt) =>
      valOpt->Option.forEach(v => out->Dict.set(key, JSON.Encode.string(v)))
    setStr("card_number", cardNumber)
    setStr("card_exp_month", expMonth)
    setStr("card_exp_year", expYear)
    setStr("card_cvc", getStr("card_cvc"))
    setStr("last_four", lastFour)
    setStr("bin_number", binNumber)

    out->Dict.toArray->Array.length > 0 ? Some(out->JSON.Encode.object) : None
  })
}

let buildVaultPmd = (data: option<JSON.t>): option<Dict.t<JSON.t>> =>
  buildVaultCard(data)->Option.map(vaultCard =>
    [
      ("payment_method_data", [("vault_card", vaultCard)]->Dict.fromArray->JSON.Encode.object),
    ]->Dict.fromArray
  )

let buildVaultCvc = (data: option<JSON.t>): option<string> =>
  data
  ->Option.flatMap(JSON.Decode.object)
  ->Option.flatMap(obj =>
    switch obj->Dict.get("tokens") {
    | Some(_) as tokens => tokens
    | None => obj->Dict.get("raw")
    }
  )
  ->Option.flatMap(JSON.Decode.object)
  ->Option.flatMap(obj => obj->Dict.get("card_cvc"))
  ->Option.flatMap(JSON.Decode.string)

// Builds the saved-card `payment_method_data` merging optional billing with the
// tokenized CVC. VGS-tokenized CVC goes under `vault_card_token.card_cvc`.
let buildSavedPmd = (~billing, ~vaultCvcToken: option<string>): option<JSON.t> => {
  let arr = []
  billing->Option.forEach(address =>
    arr->Array.push(("billing", address->Utils.getJsonObjectFromRecord))
  )
  vaultCvcToken->Option.forEach(token =>
    arr->Array.push((
      "vault_card_token",
      [("card_cvc", token->JSON.Encode.string)]->Dict.fromArray->JSON.Encode.object,
    ))
  )
  arr->Array.length > 0 ? Some(arr->Dict.fromArray->JSON.Encode.object) : None
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

let shouldShowSavedPaymentMethods = (~sdkConfigData, ~sessionTokenData) =>
  SdkConfigTypes.getVaultingAction(sdkConfigData) !== Tokenize ||
  sessionTokenData->Option.flatMap((d: SessionsType.sessionData) => d.vaultDetails)->Option.isSome

let generateCardConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~payment_method_str: string,
  ~payment_method_type: string,
  ~payment_method_data=?,
  ~payment_type: PaymentMethodType.mandateType,
  ~payment_type_str=?,
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
    client_secret: ?switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
    | Some(_) => None
    | None => Some(nativeProp.paymentSessionConfig.clientSecret)
    },
    return_url: ?Utils.getReturnUrl(~appId=nativeProp.sdkParams.appId, ~appURL),
    payment_method: payment_method_str,
    payment_method_type,
    ?payment_method_data,
    ?payment_token,
    ?email,
    payment_type: ?payment_type_str,
    customer_acceptance: ?(
      payment_token->Option.isNone &&
      (nativeProp.configuration.alwaysSendCustomerAcceptance ||
      isNicknameSelected && isMandate ||
      isMandate && !isNicknameSelected && !(isSaveCardCheckboxVisible->Option.getOr(false)) ||
      payment_type === NORMAL && isNicknameSelected ||
      payment_type === SETUP_MANDATE) &&
      !isGuestCustomer
        ? Some({
            {
              acceptance_type: "online",
              accepted_at: Date.now()->Date.fromTime->Date.toISOString,
              online: {
                user_agent: Utils.resolveUserAgent(~userAgent=nativeProp.sdkParams.userAgent),
              },
            }
          })
        : None
    ),
    browser_info: {
      user_agent: Utils.resolveUserAgent(~userAgent=nativeProp.sdkParams.userAgent),
      accept_header: "text\/html,application\/xhtml+xml,application\/xml;q=0.9,image\/webp,image\/apng,*\/*;q=0.8",
      language: LocaleDataType.localeTypeToString(nativeProp.configuration.locale),
      color_depth: 32,
      screen_height: ?screen_height->Option.map(Int.fromFloat),
      screen_width: ?screen_width->Option.map(Int.fromFloat),
      time_zone: Date.make()->Date.getTimezoneOffset,
      java_enabled: true,
      java_script_enabled: true,
      device_model: ?nativeProp.sdkParams.device_model,
      os_type: ?nativeProp.sdkParams.os_type,
      os_version: ?nativeProp.sdkParams.os_version,
    },
  }
}

let generateSessionsTokenBody = (~clientSecret, ~paymentId, ~sdkAuthorization=?, ~wallet) => {
  let baseArr = [
    ("payment_id", paymentId->JSON.Encode.string),
    ("wallets", wallet->JSON.Encode.array),
  ]
  let bodyArr = switch sdkAuthorization->Utils.getNonEmptyOption {
  | Some(_) => baseArr
  | None => baseArr->Array.concat([("client_secret", clientSecret->JSON.Encode.string)])
  }
  bodyArr
  ->Dict.fromArray
  ->JSON.Encode.object
  ->JSON.stringify
}

let generateSavedCardConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~payment_method,
  ~payment_token,
  ~savedCardCvv,
  ~payment_type_str,
  ~screen_height=?,
  ~screen_width=?,
  ~billing=?,
  ~vaultCvcToken=?,
): PaymentConfirmTypes.redirectType => {
  client_secret: ?switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
  | Some(_) => None
  | None => Some(nativeProp.paymentSessionConfig.clientSecret)
  },
  payment_method,
  payment_token,
  card_cvc: ?(
    vaultCvcToken->Option.isSome
      ? None
      : savedCardCvv->Option.isSome
      ? Some(savedCardCvv->Option.getOr(""))
      : None
  ),
  return_url: ?Utils.getCustomReturnAppUrl(~appId=nativeProp.sdkParams.appId),
  payment_method_data: ?buildSavedPmd(~billing, ~vaultCvcToken),
  payment_type: ?payment_type_str,
  browser_info: {
    user_agent: Utils.resolveUserAgent(~userAgent=nativeProp.sdkParams.userAgent),
    accept_header: "text\/html,application\/xhtml+xml,application\/xml;q=0.9,image\/webp,image\/apng,*\/*;q=0.8",
    language: LocaleDataType.localeTypeToString(nativeProp.configuration.locale),
    color_depth: 32,
    screen_height: ?screen_height->Option.map(Int.fromFloat),
    screen_width: ?screen_width->Option.map(Int.fromFloat),
    time_zone: Date.make()->Date.getTimezoneOffset,
    java_enabled: true,
    java_script_enabled: true,
    device_model: ?nativeProp.sdkParams.device_model,
    os_type: ?nativeProp.sdkParams.os_type,
    os_version: ?nativeProp.sdkParams.os_version,
  },
}
let generateWalletConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~payment_token,
  ~payment_method_type,
  ~payment_type_str,
): PaymentConfirmTypes.redirectType => {
  client_secret: ?switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
  | Some(_) => None
  | None => Some(nativeProp.paymentSessionConfig.clientSecret)
  },
  payment_token,
  payment_method: "wallet",
  payment_method_type,
  payment_type: ?payment_type_str,
}

let generatePostSessionTokensBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~sessionObject: SessionsType.sessions,
  ~payment_type_str: option<string>=?,
  (),
): JSON.t => {
  let sdkData = [("token", JSON.Encode.string(""))]->Dict.fromArray->JSON.Encode.object

  let walletInner =
    [(paymentMethodData.payment_method_type ++ "_sdk", sdkData)]
    ->Dict.fromArray
    ->JSON.Encode.object

  let paymentMethodDataBody =
    [("wallet", walletInner)]
    ->Dict.fromArray
    ->JSON.Encode.object

  let connector = switch sessionObject.connector {
  | "" =>
    paymentMethodData.payment_experience
    ->Array.get(0)
    ->Option.map(_ => [paymentMethodData.payment_method_type])
    ->Option.getOr([paymentMethodData.payment_method_type])
  | c => [c]
  }

  [
    ("payment_id", nativeProp.paymentSessionConfig.paymentId->JSON.Encode.string),
    ("payment_method_type", JSON.Encode.string(paymentMethodData.payment_method_type)),
    ("payment_method", JSON.Encode.string(paymentMethodData.payment_method_str)),
    ("client_secret", JSON.Encode.string(nativeProp.paymentSessionConfig.clientSecret)),
    ("payment_experience", JSON.Encode.string("invoke_sdk_client")),
    ("connector", connector->Array.map(JSON.Encode.string)->JSON.Encode.array),
    ("payment_method_data", paymentMethodDataBody),
    ("payment_type", JSON.Encode.string(payment_type_str->Option.getOr("normal"))),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
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
