// TurboModule interface definition using external bindings
@module("./spec/modules") @val external sendMessageToNativeTurbo: string => unit = "sendMessageToNative"
@module("./spec/modules")
external launchApplePayTurbo: (string, JSON.t => unit) => unit = "launchApplePay"
@module("./spec/modules") external launchGPayTurbo: (string, JSON.t => unit) => unit = "launchGPay"
@module("./spec/modules")
external exitPaymentsheetTurbo: (int, string, bool) => unit = "exitPaymentsheet"
@module("./spec/modules")
external exitPaymentMethodManagementTurbo: (int, string, bool) => unit =
  "exitPaymentMethodManagement"
@module("./spec/modules") external exitWidgetTurbo: (string, string) => unit = "exitWidget"
@module("./spec/modules") external exitCardFormTurbo: string => unit = "exitCardForm"
@module("./spec/modules")
external launchWidgetPaymentSheetTurbo: (string, JSON.t => unit) => unit =
  "launchWidgetPaymentSheet"
@module("./spec/modules") external onAddPaymentMethodTurbo: string => unit = "onAddPaymentMethod"
@module("./spec/modules")
external exitWidgetPaymentsheetTurbo: (int, string, bool) => unit = "exitWidgetPaymentsheet"
@module("./spec/modules") external updateWidgetHeightTurbo: int => unit = "updateWidgetHeight"

// TurboModule interface as a record
let turboModules = {
  "sendMessageToNative": sendMessageToNativeTurbo,
  "launchApplePay": launchApplePayTurbo,
  "launchGPay": launchGPayTurbo,
  "exitPaymentsheet": exitPaymentsheetTurbo,
  "exitPaymentMethodManagement": exitPaymentMethodManagementTurbo,
  "exitWidget": exitWidgetTurbo,
  "exitCardForm": exitCardFormTurbo,
  "launchWidgetPaymentSheet": launchWidgetPaymentSheetTurbo,
  "onAddPaymentMethod": onAddPaymentMethodTurbo,
  "exitWidgetPaymentsheet": exitWidgetPaymentsheetTurbo,
  "updateWidgetHeight": updateWidgetHeightTurbo,
}
