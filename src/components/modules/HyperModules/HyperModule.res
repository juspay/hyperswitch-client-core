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
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["sendMessageToNative"](str)
  } else {
    HyperNativeModules.sendMessageToNative(str)
  }
}

let useExitPaymentsheet = () => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["useExitPaymentsheet"]()
  } else {
    HyperNativeModules.useExitPaymentsheet()
  }
}

let useExitCard = () => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["useExitCard"]()
  } else {
    HyperNativeModules.useExitCard()
  }
}

let useExitWidget = () => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["useExitWidget"]()
  } else {
    HyperNativeModules.useExitWidget()
  }
}

let launchApplePay = (requestObj: string, callback) => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["launchApplePay"](requestObj, callback)
  } else {
    HyperNativeModules.launchApplePay(requestObj, callback)
  }
}

let launchGPay = (requestObj: string, callback) => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["launchGPay"](requestObj, callback)
  } else {
    HyperNativeModules.launchGPay(requestObj, callback)
  }
}

let launchWidgetPaymentSheet = (requestObj: string, callback) => {
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["launchWidgetPaymentSheet"](requestObj, callback)
  } else {
    HyperNativeModules.launchWidgetPaymentSheet(requestObj, callback)
  }
}

let updateWidgetHeight =
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["updateWidgetHeight"]
  } else {
    HyperNativeModules.updateWidgetHeight
  }


// Export the hyperModule object
let hyperModule =
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["hyperTurboModule"]
  } else {
    HyperNativeModules.hyperModule
  }


// Export stringifiedResStatus function
let stringifiedResStatus =
  if isTurboModuleEnabled() {
    let turboModule = %raw("require('./HyperTurboModules.bs.js')")
    turboModule["stringifiedResStatus"]
  } else {
    HyperNativeModules.stringifiedResStatus
  }

