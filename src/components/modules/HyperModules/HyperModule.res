// Feature flag for turbo modules and new architecture
@val @scope("global") external turboModuleProxy: Nullable.t<'a> = "__turboModuleProxy"
@val @scope("global") external nativeFabricUIManager: Nullable.t<'a> = "nativeFabricUIManager"

let isTurboModuleEnabled = () => {
  let hasFabricUIManager = switch nativeFabricUIManager {
  | Value(_) => true
  | Null | Undefined => false
  }

  let hasTurboModule = switch turboModuleProxy {
  | Value(_) => true
  | Null | Undefined => false
  }

  // Return true if either Fabric or TurboModules are available
  hasFabricUIManager || hasTurboModule
}

let sendMessageToNative = str => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["sendMessageToNative"](str)
  } else {
    NativeModulesHyper.sendMessageToNative(str)
  }
}

let useExitPaymentsheet = () => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["useExitPaymentsheet"]()
  } else {
    NativeModulesHyper.useExitPaymentsheet()
  }
}

let useExitCard = () => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["useExitCard"]()
  } else {
    NativeModulesHyper.useExitCard()
  }
}

let useExitWidget = () => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["useExitWidget"]
  } else {
    NativeModulesHyper.useExitWidget
  }
}

let launchApplePay = (requestObj: string, callback) => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["launchApplePay"](requestObj, callback)
  } else {
    NativeModulesHyper.launchApplePay(requestObj, callback)
  }
}

let launchGPay = (requestObj: string, callback) => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["launchGPay"](requestObj, callback)
  } else {
    NativeModulesHyper.launchGPay(requestObj, callback)
  }
}

let launchWidgetPaymentSheet = (requestObj: string, callback) => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["launchWidgetPaymentSheet"](requestObj, callback)
  } else {
    NativeModulesHyper.launchWidgetPaymentSheet(requestObj, callback)
  }
}

let updateWidgetHeight =
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["updateWidgetHeight"]
  } else {
    NativeModulesHyper.updateWidgetHeight
  }


// Export the hyperModule object
let hyperModule =
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["hyperTurboModule"]
  } else {
    NativeModulesHyper.hyperModule
  }


// Export stringifiedResStatus function
let stringifiedResStatus =
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./TurboModulesHyper.bs.js')")
    turboModule["stringifiedResStatus"]
  } else {
    NativeModulesHyper.stringifiedResStatus
  }

