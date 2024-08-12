open ReactNative
open Style
let useGetShadowStyle = (~shadowIntensity, ~shadowColor="black", ()) => {
  let shadowOffsetHeight = shadowIntensity
  let elevation = shadowIntensity
  let shadowRadius = shadowIntensity
  let shadowOpacity = 0.2
  let shadowOffsetWidth = 0.
  viewStyle(
    ~elevation,
    ~shadowRadius,
    ~shadowOpacity,
    ~shadowOffset={
      offset(~width=shadowOffsetWidth, ~height=shadowOffsetHeight /. 2.)
    },
    ~shadowColor,
    (),
  )
}
