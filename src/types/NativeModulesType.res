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
  exitWidgetPaymentsheet: (int,string, string, bool) => unit,
  updateWidgetHeight: int => unit,
  onWidgetStateChange: (string, string) => unit,
}

type useExitPaymentsheetReturnType = {
  exit: (PaymentConfirmTypes.error, bool) => unit,
  simplyExit: (PaymentConfirmTypes.error, int, bool) => unit,
}

type widgetActionType = 
  | GoBack({widgetId: string})
  | ConfirmPayment({widgetId : string})
  | UnknownEvent

let widgetActionEventObjectMapper = var=> {
  let actionType = Utils.getOptionString(var, "actionType")
  switch actionType {
  | Some("goBack") => GoBack({
      widgetId: Utils.getOptionString(var, "widgetId")->Option.getOr("")
    })
  | Some("confirmPayment") => ConfirmPayment({
      widgetId: Utils.getOptionString(var, "widgetId")->Option.getOr("")
    })
  | _ => UnknownEvent
}
}