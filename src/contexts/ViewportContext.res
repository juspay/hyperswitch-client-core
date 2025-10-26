type viewPortContants = {
  windowHeight: float,
  windowWidth: float,
  screenHeight: float,
  screenWidth: float,
  bottomInset: float,
  topInset: float,
}

let windowHeight = ReactNative.Dimensions.get(#window).height
let windowWidth = ReactNative.Dimensions.get(#window).width
let screenHeight = ReactNative.Dimensions.get(#screen).height
let screenWidth = ReactNative.Dimensions.get(#screen).width
let statusBarHeight = ReactNative.StatusBar.currentHeight

let minTopInset = 50.

let minBottomInset = WebKit.platform === #ios || WebKit.platform === #iosWebView ? 0. : 20.

let defaultVal: viewPortContants = {
  windowHeight,
  windowWidth,
  screenHeight,
  screenWidth,
  bottomInset: minBottomInset,
  topInset: minTopInset,
}

let viewPortContext = React.createContext((defaultVal, (_: viewPortContants) => ()))

module Provider = {
  let make = React.Context.provider(viewPortContext)
}
@react.component
let make = (~children, ~topInset, ~bottomInset) => {
  let (state, setState) = React.useState(_ => {
    ...defaultVal,
    bottomInset: WebKit.platform === #androidWebView
      ? bottomInset->Option.getOr(0.) /. 2. +. minBottomInset
      : bottomInset->Option.getOr(0.) +. minBottomInset,
    topInset: WebKit.platform === #androidWebView
      ? topInset->Option.getOr(0.) +. minTopInset
      : topInset->Option.getOr(0.) +. minTopInset,
  })

  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
