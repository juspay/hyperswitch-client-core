module Svg = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~uri: string=?,
    ~width: float=?,
    ~viewBox: string=?,
    ~height: float=?,
    ~fill: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
    ~children: React.element=?,
  ) => React.element = "Svg"
}

module Defs = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~uri: string=?,
    ~width: string=?,
    ~viewBox: string=?,
    ~height: string=?,
    ~fill: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
    ~children: React.element=?,
  ) => React.element = "Defs"
}

module RadialGradient = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~id: string=?,
    ~cx: string=?,
    ~cy: string=?,
    ~fx: string=?,
    ~fy: string=?,
    ~uri: string=?,
    ~gradientTransform: string=?,
    ~width: float=?,
    ~height: float=?,
    ~fill: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
    ~children: React.element=?,
  ) => React.element = "RadialGradient"
}

module Stop = {
  @module("react-native-svg/src") @react.component
  external make: (~offset: string, ~stopColor: string, ~stopOpacity: string=?) => React.element =
    "Stop"
}

module Circle = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~uri: string=?,
    ~cx: string=?,
    ~cy: string=?,
    ~r: string=?,
    ~fill: string=?,
    ~opacity: string=?,
    ~stroke: string=?,
    ~strokeWidth: string=?,
    ~strokeLinecap: string=?,
    ~strokeDasharray: string=?,
    ~strokeDashoffset: string=?,
    ~transformOrigin: string=?,
    ~origin: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
  ) => React.element = "Circle"
}

module AnimateTransform = {
  @module("react-native-svg/src") @react.component
  external make: (
    ~attributeName: string=?,
    ~\"type": string=?,
    ~from: string=?,
    ~to: string=?,
    ~dur: string=?,
    ~repeatCount: string=?,
    ~values: string=?,
    ~keyTimes: string=?,
    ~keySplines: string=?,
    ~uri: string=?,
    ~width: float=?,
    ~height: float=?,
    ~fill: string=?,
    ~onError: unit => unit=?,
    ~onLoad: unit => unit=?,
  ) => React.element = "AnimateTransform"
}

module SvgUri = {
  @module("react-native-svg/css") @react.component
  external make: (
    ~uri: string,
    ~width: float,
    ~height: float,
    ~fill: string,
    ~onError: unit => unit,
    ~onLoad: unit => unit,
  ) => React.element = "SvgCssUri"
}

module SvgCss = {
  @module("react-native-svg/css") @react.component
  external make: (
    ~xml: string,
    ~width: float,
    ~height: float,
    ~fill: string,
    ~onError: unit => unit,
    ~onLoad: unit => unit,
  ) => React.element = "SvgCss"
}
