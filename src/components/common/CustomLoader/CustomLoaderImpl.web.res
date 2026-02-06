module ContentLoaderWeb = {
  @module("react-content-loader") @react.component
  external make: (
    ~speed: float,
    ~width: string,
    ~height: string,
    ~viewBox: string=?,
    ~backgroundColor: string=?,
    ~foregroundColor: string=?,
    ~style: ReactNative.Style.t=?,
    ~children: React.element,
  ) => React.element = "default"
}

module ContentLoader = {
  @react.component
  let make = (
    ~speed,
    ~width,
    ~height,
    ~viewBox=?,
    ~backgroundColor="red",
    ~foregroundColor="black",
    ~style=?,
    ~children=React.null,
  ) => {
    <ContentLoaderWeb speed width height ?viewBox backgroundColor foregroundColor ?style>
      {children}
    </ContentLoaderWeb>
  }
}

@react.component
let make = (~height="45", ~width="100%", ~speed=2., ~radius=None, ~style) => {
  let {borderRadius, loadingBgColor, loadingFgColor} = ThemebasedStyle.useThemeBasedStyle()
  let br = switch radius {
  | Some(var) => var
  | None => borderRadius
  }
  <ContentLoader
    width
    height
    speed
    // viewBox
    ?style
    backgroundColor=loadingBgColor
    foregroundColor=loadingFgColor
  >
    <rect x="0" y="0" rx={br->Float.toString} ry={br->Float.toString} width height />
  </ContentLoader>
}
