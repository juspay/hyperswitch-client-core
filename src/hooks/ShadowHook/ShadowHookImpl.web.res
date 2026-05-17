let useGetShadowStyle = (~shadowConfig: SdkTypes.shadowConfig, ()) => {
  let intensity = shadowConfig.intensity->Option.getOr(2.)
  let color = shadowConfig.color->Option.getOr("black")
  let opacity = shadowConfig.opacity->Option.getOr(0.2)
  let blurRadius = shadowConfig.blurRadius->Option.getOr(intensity)->Float.toString
  let offsetX =
    shadowConfig.offset->Option.flatMap(o => o.x)->Option.getOr(intensity)->Float.toString
  let offsetY =
    shadowConfig.offset->Option.flatMap(o => o.y)->Option.getOr(intensity)->Float.toString

  let processedColor = ReactNative.Color.processColor(color)->Int.fromString->Option.getOr(0)
  let r = processedColor->lsr(16)->land(255)->Int.toString
  let g = processedColor->lsr(8)->land(255)->Int.toString
  let b = processedColor->land(255)->Int.toString

  let a: JsxDOMStyle.t = {
    boxShadow: `${offsetX}px ${offsetY}px ${blurRadius}px rgba(${r}, ${g}, ${b}, ${opacity->Float.toString})`,
  }
  a
}
