let useGetShadowStyle = (~shadowConfig: SdkTypes.shadowConfig, ()) => {
  let intensity = shadowConfig.intensity->Option.getOr(2.)
  ReactNative.Style.s({
    shadowColor: shadowConfig.color->Option.getOr("black"),
    shadowOpacity: shadowConfig.opacity->Option.getOr(0.2),
    shadowRadius: shadowConfig.blurRadius->Option.getOr(intensity),
    shadowOffset: {
      width: shadowConfig.offset->Option.flatMap(o => o.x)->Option.getOr(intensity /. 2.),
      height: shadowConfig.offset->Option.flatMap(o => o.y)->Option.getOr(intensity /. 2.),
    },
  })
}
