let useGetShadowStyle = (~shadowIntensity, ~shadowColor="black", ()) => {
  let shadowOffsetHeight = shadowIntensity->Float.toString
  let shadowOpacity = 0.2->Float.toString
  let shadowOffsetWidth = 0.->Float.toString

  let processedColor = ReactNative.Color.processColor(shadowColor)->Int.fromString->Option.getOr(0)
  let r = processedColor->Int.Bitwise.lsr(16)->Int.Bitwise.land(255)->Int.toString
  let g = processedColor->Int.Bitwise.lsr(8)->Int.Bitwise.land(255)->Int.toString
  let b = processedColor->Int.Bitwise.land(255)->Int.toString

  let a: JsxDOMStyle.t = {
    boxShadow: `${shadowOffsetWidth} ${shadowOffsetWidth} ${shadowOffsetHeight}px rgba(${r}, ${g}, ${b}, ${shadowOpacity})`,
  }
  a
}
