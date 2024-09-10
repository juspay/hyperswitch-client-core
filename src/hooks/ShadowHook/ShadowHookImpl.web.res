let useGetShadowStyle = (~shadowIntensity, ~shadowColor="black", ()) => {
  let shadowOffsetHeight = shadowIntensity->Float.toString
  let shadowOpacity = 0.2->Float.toString
  let shadowOffsetWidth = 0.->Float.toString

  let processedColor = ReactNative.Color.processColor(shadowColor)->Int.fromString->Option.getOr(0)
  let r = processedColor->lsr(16)->land(255)->Int.toString
  let g = processedColor->lsr(8)->land(255)->Int.toString
  let b = processedColor->land(255)->Int.toString

  let a: JsxDOMStyle.t = {
    boxShadow: `${shadowOffsetWidth} ${shadowOffsetWidth} ${shadowOffsetHeight}px rgba(${r}, ${g}, ${b}, ${shadowOpacity})`,
  }
  a
}
