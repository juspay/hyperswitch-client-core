@val @scope("global") external turboModuleProxy: Nullable.t<'a> = "__turboModuleProxy"
@val @scope("global") external nativeFabricUIManager: Nullable.t<'a> = "nativeFabricUIManager"
let isTurboModuleEnabled = () => {
  let hasTurboModule = switch turboModuleProxy {
  | Value(_) => true
  | Null | Undefined => false
  }
  hasTurboModule
}

let isFabricEnabled = () => {
  let hasFabricUIManager = switch nativeFabricUIManager {
  | Value(_) => true
  | Null | Undefined => false
  }
  hasFabricUIManager
}
