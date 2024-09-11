let useGetShadowStyle = (~shadowIntensity, ~shadowColor="black", ()) => {
  let shadowOffsetHeight = shadowIntensity
  let shadowRadius = shadowIntensity
  let shadowOpacity = 0.2
  let shadowOffsetWidth = 0.
  ReactNative.Style.viewStyle(
    ~shadowRadius,
    ~shadowOpacity,
    ~shadowOffset={
      ReactNative.Style.offset(~width=shadowOffsetWidth, ~height=shadowOffsetHeight /. 2.)
    },
    ~shadowColor,
    (),
  )
}
