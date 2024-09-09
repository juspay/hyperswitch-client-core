@module("./ShadowHookImpl")
external useGetShadowStyle: (
  ~shadowIntensity: float,
  ~shadowColor: ReactNative.Color.t=?,
  unit,
) => ReactNative.Style.t = "useGetShadowStyle"
