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

let generatePaymentMethodData = (
  ~prop: PaymentMethodListType.payment_method_types_card,
  ~cardData: CardDataContext.cardData,
  ~cardHolderName: option<'a>,
  ~nickname: option<'a>,
) => {
  let (month, year) = Validation.getExpiryDates(cardData.expireDate)

  [
    (
      prop.payment_method,
      [
        ("card_number", cardData.cardNumber->Validation.clearSpaces->JSON.Encode.string),
        ("card_exp_month", month->JSON.Encode.string),
        ("card_exp_year", year->JSON.Encode.string),
        (
          "card_holder_name",
          switch cardHolderName {
          | Some(cardHolderName) => cardHolderName->JSON.Encode.string
          | None => JSON.Encode.null
          },
        ),
        (
          "nick_name",
          switch nickname {
          | Some(nick) => nick->JSON.Encode.string
          | None => JSON.Encode.null
          },
        ),
        ("card_cvc", cardData.cvv->JSON.Encode.string),
        (
          "card_network",
          switch cardData.selectedCoBadgedCardBrand {
          | Some(selectedCoBadgedCardBrand) => selectedCoBadgedCardBrand->JSON.Encode.string
          | None =>
            switch cardData.cardBrand {
            | "" => JSON.Encode.null
            | cardBrand => cardBrand->JSON.Encode.string
            }
          },
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object,
    ),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
  ->Some
}

let generateCardConfirmBody = (
  ~nativeProp: SdkTypes.nativeProp,
  ~prop: PaymentMethodListType.payment_method_types_card,
  ~payment_method_data=?,
  ~allApiData: AllApiDataContext.allApiData,
  ~isNicknameSelected=false,
  ~payment_token=?,
  ~isSaveCardCheckboxVisible=?,
  ~isGuestCustomer,
  (),
): PaymentMethodListType.redirectType => {
  let isMandate = allApiData.additionalPMLData.mandateType->checkIfMandate
  {
    client_secret: nativeProp.clientSecret,
    return_url: ?Utils.getReturnUrl(
      ~appId=nativeProp.hyperParams.appId,
      ~appURL=allApiData.additionalPMLData.redirect_url,
    ),
    payment_method: prop.payment_method,
    payment_method_type: ?Some(prop.payment_method_type),
    connector: ?switch prop.card_networks {
    | Some(cardNetwork) =>
      cardNetwork
      ->Array.get(0)
      ->Option.mapOr(None, card_network => card_network.eligible_connectors->Some)
    | None => None
    },
    ?payment_method_data,
    ?payment_token,
    billing: ?nativeProp.configuration.defaultBillingDetails,
    shipping: ?nativeProp.configuration.shippingDetails,
    // setup_future_usage: ?switch (allApiData.mandateType != NORMAL, isNicknameSelected) {
    // | (true, _) => Some("off_session")
    // | (false, true) => Some("on_session")
    // | (false, false) => None
    // },
    // setup_future_usage: {
    //   isNicknameSelected || isMandate->Option.getOr(false)
    //     ? "off_session"
    //     : "on_session"
    // },
    payment_type: ?allApiData.additionalPMLData.paymentType,
    // mandate_data: ?(
    //   (isNicknameSelected && isMandate->Option.getOr(false)) ||
    //   isMandate->Option.getOr(false) &&
    //   !isNicknameSelected &&
    //   !(isSaveCardCheckboxVisible->Option.getOr(false)) ||
    //   (allApiData.mandateType == NORMAL && isNicknameSelected)
    //     ? Some({
    //         customer_acceptance: {
    //           acceptance_type: "online",
    //           accepted_at: Date.now()->Date.fromTime->Date.toISOString,
    //           online: {
    //             ip_address: ?nativeProp.hyperParams.ip,
    //             user_agent: ?nativeProp.hyperParams.userAgent,
    //           },
    //         },
    //       })
    //     : None
    // ),
    // moved customer_acceptance outside mandate_data
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
