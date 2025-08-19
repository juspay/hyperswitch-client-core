// Feature flag for turbo modules
@val @scope("global") external turboModuleProxy: Nullable.t<'a> = "__turboModuleProxy"

let isTurboModuleEnabled = () => {
  turboModuleProxy != null
}

let sendMessageToNative = str => {
  if isTurboModuleEnabled() {
    TurboModulesHyper.sendMessageToNative(str)
  } else {
    NativeModulesHyper.sendMessageToNative(str)
  }
}

let useExitPaymentsheet = () => {
  if isTurboModuleEnabled() {
    TurboModulesHyper.useExitPaymentsheet()
  } else {
    NativeModulesHyper.useExitPaymentsheet()->Obj.magic
  }
}

let useExitCard = () =>
  if isTurboModuleEnabled() {
    TurboModulesHyper.useExitCard()
  } else {
    NativeModulesHyper.useExitCard()
  }

let useExitWidget = () =>
  if isTurboModuleEnabled() {
    TurboModulesHyper.useExitWidget
  } else {
    NativeModulesHyper.useExitWidget
  }

let launchApplePay = (requestObj: string, callback, startCallback, presentCallback) =>
  if isTurboModuleEnabled() {
    TurboModulesHyper.launchApplePay(requestObj, callback, startCallback, presentCallback)
  } else {
    NativeModulesHyper.launchApplePay(requestObj, callback, startCallback, presentCallback)
  }

let launchGPay = (requestObj: string, callback) =>
  if isTurboModuleEnabled() {
    TurboModulesHyper.launchGPay(requestObj, callback)
  } else {
    NativeModulesHyper.launchGPay(requestObj, callback)
  }

let launchWidgetPaymentSheet = (requestObj: string, callback) =>
  if isTurboModuleEnabled() {
    TurboModulesHyper.launchWidgetPaymentSheet(requestObj, callback)
  } else {
    NativeModulesHyper.launchWidgetPaymentSheet(requestObj, callback)
  }

let updateWidgetHeight = if isTurboModuleEnabled() {
  TurboModulesHyper.updateWidgetHeight
} else {
  NativeModulesHyper.updateWidgetHeight
}

// Export the hyperModule object
let hyperModule = if isTurboModuleEnabled() {
  TurboModulesHyper.hyperTurboModule
} else {
  NativeModulesHyper.hyperModule
}

// Export stringifiedResStatus function
let stringifiedResStatus = if isTurboModuleEnabled() {
  TurboModulesHyper.stringifiedResStatus
} else {
  NativeModulesHyper.stringifiedResStatus
}
