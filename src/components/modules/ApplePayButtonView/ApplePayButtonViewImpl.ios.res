open ReactNative

// type props = {
//   buttonType?: SdkTypes.applePayButtonType,
//   buttonStyle?: SdkTypes.applePayButtonStyle,
//   cornerRadius?: float,
//   style?: Style.t,
// }

// let make: React.component<props> = NativeModules.requireNativeComponent("ApplePayView")

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
}
@val @scope("global") external turboModuleProxy: Nullable.t<'a> = "__turboModuleProxy"
@val @scope("global") external nativeFabricUIManager: Nullable.t<'a> = "nativeFabricUIManager"
@module("../HyperModules/spec/views/ApplePayButtonNativeComponent") @val
external applePayButton: React.component<props> = "default"

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

let make: React.component<props> = if isTurboModuleEnabled() {
  applePayButton
} else {
  NativeModules.requireNativeComponent("ApplePayView")
}
