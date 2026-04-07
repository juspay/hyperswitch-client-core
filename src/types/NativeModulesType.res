type hyperModule = {
  sendMessageToNative: string => unit,
  launchApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  startApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  presentApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  launchGPay: (string, Dict.t<JSON.t> => unit) => unit,
  exitPaymentsheet: (int, string, bool) => unit,
  exitPaymentMethodManagement: (int, string, bool) => unit,
  exitWidget: (string, string) => unit,
  exitCardForm: string => unit,
  launchWidgetPaymentSheet: (string, Dict.t<JSON.t> => unit) => unit,
  onAddPaymentMethod: string => unit,
  exitWidgetPaymentsheet: (int, string, string, bool) => unit,
  updateWidgetHeight: int => unit,
  emitPaymentEvent: (string, string, JSON.t) => unit,
}

type useExitPaymentsheetReturnType = {
  exit: (PaymentConfirmTypes.error, bool) => unit,
  simplyExit: (PaymentConfirmTypes.error, int, bool) => unit,
}
open Utils

// Widget action types that can be triggered from native side
type widgetActionType = ConfirmPayment

let widgetActionTypeToString = actionType =>
  switch actionType {
  | ConfirmPayment => "CONFIRM_PAYMENT_ACTION"
  }

let widgetActionTypeFromString = (str: string): option<widgetActionType> =>
  switch str {
  | "CONFIRM_PAYMENT_ACTION" => Some(ConfirmPayment)
  | _ => None
  }

// Widget action data structure received from native
type widgetActionData = {
  actionType: widgetActionType,
  rootTag: int,
}

let widgetActionDataMapper = (dict: Dict.t<JSON.t>): option<widgetActionData> => {
  let actionTypeStr = dict->getString("actionType", "")
  let rootTag = dict->getInt("rootTag", -1)

  actionTypeStr
  ->widgetActionTypeFromString
  ->Option.map(actionType => {
    actionType,
    rootTag,
  })
}
