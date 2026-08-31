type insets = ReactNativeSafeArea.insets = {
  top: float,
  right: float,
  bottom: float,
  left: float,
}

let zeroInsets: insets = {top: 0., right: 0., bottom: 0., left: 0.}

let isNativePlatform = WebKit.platform === #ios || WebKit.platform === #android

// Web and the webviews have no live safe area, so the sheets keep the fixed gaps that
// used to be folded into every inset. On native the insets are the real ones, and
// anything added on top of them double-pads.
let topGap = isNativePlatform ? 0. : 50.
let bottomGap = switch WebKit.platform {
| #ios | #android | #iosWebView => 0.
| _ => 20.
}

let hasInset = (insets: insets) =>
  insets.top > 0. || insets.bottom > 0. || insets.left > 0. || insets.right > 0.

let insetsFromSdkParams = (nativeProp: SdkTypes.nativeProp): insets =>
  switch nativeProp.sdkParams.insets {
  | None => zeroInsets
  | Some(hostInsets) =>
    let bottom = hostInsets.bottom->Option.getOr(0.)
    {
      top: hostInsets.top->Option.getOr(0.),
      bottom: WebKit.platform === #androidWebView ? bottom /. 2. : bottom,
      left: isNativePlatform ? hostInsets.left->Option.getOr(0.) : 0.,
      right: isNativePlatform ? hostInsets.right->Option.getOr(0.) : 0.,
    }
  }

let safeAreaContext = React.createContext(zeroInsets)

module Provider = {
  let make = React.Context.provider(safeAreaContext)
}

module NativeInsets = {
  @react.component
  let make = (~fallback: insets, ~children) => {
    let measured = ReactNativeSafeArea.useSafeAreaInsets()

    <Provider value={hasInset(measured) ? measured : fallback}> children </Provider>
  }
}

@react.component
let make = (~children) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let hostInsets = React.useMemo1(() => insetsFromSdkParams(nativeProp), [nativeProp])

  isNativePlatform
    ? <ReactNativeSafeArea.SafeAreaProvider initialMetrics=ReactNativeSafeArea.initialWindowMetrics>
        <NativeInsets fallback=hostInsets> children </NativeInsets>
      </ReactNativeSafeArea.SafeAreaProvider>
    : <Provider value=hostInsets> children </Provider>
}

let useSafeAreaInsets = () => React.useContext(safeAreaContext)
