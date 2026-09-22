open Utils

type useExitPaymentsheetReturnType = {
  exit: (PaymentConfirmTypes.error, bool) => unit,
  simplyExit: (PaymentConfirmTypes.error, int, bool) => unit,
}

// Widget action types that can be triggered from native side
type widgetActionType = ConfirmPayment | ConfirmCvcPayment

let widgetActionTypeToString = actionType =>
  switch actionType {
  | ConfirmPayment => "CONFIRM_PAYMENT_ACTION"
  | ConfirmCvcPayment => "CONFIRM_CVC_PAYMENT"
  }

let widgetActionTypeFromString = (str: string): option<widgetActionType> =>
  switch str {
  | "CONFIRM_PAYMENT_ACTION" => Some(ConfirmPayment)
  | "CONFIRM_CVC_PAYMENT" => Some(ConfirmCvcPayment)
  | _ => None
  }

// Widget action data structure received from native
type widgetActionData = {
  actionType: widgetActionType,
  rootTag: int,
  sdkAuthorization: option<string>,
  paymentToken: option<string>,
  billing: option<JSON.t>,
}

let widgetActionDataMapper = (dict: Dict.t<JSON.t>): option<widgetActionData> => {
  let actionTypeStr = dict->getString("actionType", "")
  let rootTag = dict->getInt("rootTag", -1)
  let paymentToken = dict->getOptionString("paymentToken")
  let sdkAuthorization = dict->getOptionString("sdkAuthorization")
  let billing =
    dict
    ->getOptionString("billing")
    ->Option.flatMap(str =>
      try Some(str->JSON.parseExn) catch {
      | _ => None
      }
    )

  actionTypeStr
  ->widgetActionTypeFromString
  ->Option.map(actionType => {
    actionType,
    rootTag,
    sdkAuthorization,
    paymentToken,
    billing,
  })
}
