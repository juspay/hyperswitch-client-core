/**
Checks if native modules for sdk have been imported as optional dependency
*/
let isAvailable =
  Dict.get(ReactNative.NativeModules.nativeModules, "RNLinksdk")
  ->Option.flatMap(JSON.Decode.object)
  ->Option.isSome
