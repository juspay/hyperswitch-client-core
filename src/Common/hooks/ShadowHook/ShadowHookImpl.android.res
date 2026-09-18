let useGetShadowStyle = (~shadowConfig: SdkTypes.shadowConfig, ()) => {
  ReactNative.Style.s({elevation: shadowConfig.intensity->Option.getOr(0.)})
}
