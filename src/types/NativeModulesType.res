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
  let nativeObject = var
  let actionType = Utils.getOptionString(nativeObject, "actionType")
  switch actionType {
  | Some("goBack") => GoBack({
      widgetId: Utils.getOptionString(nativeObject, "widgetId")->Option.getOr("")
    })
  | Some("confirmPayment") => ConfirmPayment({
      widgetId: Utils.getOptionString(nativeObject, "widgetId")->Option.getOr("")
    })
  | _ => UnknownEvent
}
}