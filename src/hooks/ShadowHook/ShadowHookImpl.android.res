let useGetShadowStyle = (~shadowIntensity, ()) => {
  ReactNative.Style.viewStyle(~elevation=shadowIntensity, ())
}
