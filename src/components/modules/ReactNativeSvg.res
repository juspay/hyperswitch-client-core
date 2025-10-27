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

module SvgCss = {
  @module("react-native-svg/css") @react.component
  external make: (
    ~xml: string,
    ~width: float,
    ~height: float,
    ~fill: string,
    ~onError: unit => unit,
    ~onLoad: unit => unit=?,
  ) => React.element = "SvgCss"
}

let error = `<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 115.19 123.38" style="enable-background:new 0 0 115.19 123.38" xml:space="preserve"><style type="text/css">.st0{fill-rule:evenodd;clip-rule:evenodd;stroke:#000000;stroke-width:0.5;stroke-miterlimit:2.6131;}</style><g><path d="M93.13,79.5c12.05,0,21.82,9.77,21.82,21.82c0,12.05-9.77,21.82-21.82,21.82c-12.05,0-21.82-9.77-21.82-21.82 C71.31,89.27,81.08,79.5,93.13,79.5L93.13,79.5z M8.08,0.25h95.28c2.17,0,4.11,0.89,5.53,2.3c1.42,1.42,2.3,3.39,2.3,5.53v70.01 c-2.46-1.91-5.24-3.44-8.25-4.48V9.98c0-0.43-0.16-0.79-0.46-1.05c-0.26-0.26-0.66-0.46-1.05-0.46H9.94 c-0.43,0-0.79,0.16-1.05,0.46C8.63,9.19,8.43,9.58,8.43,9.98v70.02h0.03l31.97-30.61c1.28-1.18,3.29-1.05,4.44,0.23 c0.03,0.03,0.03,0.07,0.07,0.07l26.88,31.8c-4.73,5.18-7.62,12.08-7.62,19.65c0,3.29,0.55,6.45,1.55,9.4H8.08 c-2.17,0-4.11-0.89-5.53-2.3s-2.3-3.39-2.3-5.53V8.08c0-2.17,0.89-4.11,2.3-5.53S5.94,0.25,8.08,0.25L8.08,0.25z M73.98,79.35 l3.71-22.79c0.3-1.71,1.91-2.9,3.62-2.6c0.66,0.1,1.25,0.43,1.71,0.86l17.1,17.97c-2.18-0.52-4.44-0.79-6.78-0.79 C85.91,71.99,79.13,74.77,73.98,79.35L73.98,79.35z M81.98,18.19c3.13,0,5.99,1.28,8.03,3.32c2.07,2.07,3.32,4.9,3.32,8.03 c0,3.13-1.28,5.99-3.32,8.03c-2.07,2.07-4.9,3.32-8.03,3.32c-3.13,0-5.99-1.28-8.03-3.32c-2.07-2.07-3.32-4.9-3.32-8.03 c0-3.13,1.28-5.99,3.32-8.03C76.02,19.44,78.86,18.19,81.98,18.19L81.98,18.19z M85.82,88.05l19.96,21.6 c1.58-2.39,2.5-5.25,2.5-8.33c0-8.36-6.78-15.14-15.14-15.14C90.48,86.17,87.99,86.85,85.82,88.05L85.82,88.05z M100.44,114.58 l-19.96-21.6c-1.58,2.39-2.5,5.25-2.5,8.33c0,8.36,6.78,15.14,15.14,15.14C95.78,116.46,98.27,115.78,100.44,114.58L100.44,114.58z"/></g></svg>`
let svgUriCache: Dict.t<string> = Dict.make()

module SvgUri = {
  // @module("react-native-svg/css") @react.component
  // external make: (
  //   ~uri: string,
  //   ~width: float,
  //   ~height: float,
  //   ~fill: string,
  //   ~onError: unit => unit,
  //   ~onLoad: unit => unit,
  // ) => React.element = "SvgCssUri"

  @react.component
  let make = (
    ~uri: string,
    ~width: float,
    ~height: float,
    ~fill: string,
    ~onError: unit => unit,
    ~onLoad: option<unit => unit>=?,
    ~loadingComponent=React.null,
  ) => {
    let (xml, setXml) = React.useState(_ => None)

    React.useEffect1(() => {
      switch svgUriCache->Dict.get(uri) {
      | Some(xml) => setXml(_ => Some(xml))
      | None =>
        Fetch.fetch(uri)
        ->Promise.then(Fetch.Response.text)
        ->Promise.then(text => {
          if text === "" || text->String.trim->String.sliceToEnd(~start=-6) !== "</svg>" {
            svgUriCache->Dict.set(uri, error)
            onError()
          } else {
            svgUriCache->Dict.set(uri, text)
            setXml(_ => Some(text))
          }
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          svgUriCache->Dict.set(uri, error)
          onError()
          Promise.resolve()
        })
        ->ignore
      }
      None
    }, [uri])

    switch xml {
    | Some(xml) => <SvgCss onError ?onLoad xml width height fill />
    | None => loadingComponent
    }
  }
}
