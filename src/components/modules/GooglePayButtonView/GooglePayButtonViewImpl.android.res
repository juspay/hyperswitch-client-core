type props = {
  buttonType?: SdkTypes.googlePayButtonType,
  borderRadius?: float,
  buttonStyle?: ReactNative.Appearance.t,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
}

// let make: React.component<props> = ReactNative.NativeModules.requireNativeComponent(
//   "GooglePayButton",
// )
// Feature flag for turbo modules and new architecture
@val @scope("global") external turboModuleProxy: Nullable.t<'a> = "__turboModuleProxy"
@val @scope("global") external nativeFabricUIManager: Nullable.t<'a> = "nativeFabricUIManager"
@module("../HyperModules/spec/views/GooglePayButtonNativeComponent") @val
external googlePayButton: React.component<props> = "default"

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
  googlePayButton
} else {
  ReactNative.NativeModules.requireNativeComponent("GooglePayButton")
}
