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

  hasFabricUIManager || hasTurboModule
}

@module("react-native/Libraries/Utilities/codegenNativeComponent")
external codegenNativeComponent: string => React.component<'props> = "default"
