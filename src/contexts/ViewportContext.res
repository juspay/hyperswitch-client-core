type viewPortContants = {
  windowHeight: float,
  windowWidth: float,
  screenHeight: float,
  screenWidth: float,
  navigationBarHeight: float,
  maxPaymentSheetHeight: float,
}

let defaultNavbarHeight =
  ReactNative.Platform.os === #ios || WebKit.platform === #iosWebView ? 0. : 20.
let windowHeight = ReactNative.Dimensions.get(#window).height
let windowWidth = ReactNative.Dimensions.get(#window).width
let screenHeight = ReactNative.Dimensions.get(#screen).height
let screenWidth = ReactNative.Dimensions.get(#screen).width
let statusBarHeight = ReactNative.StatusBar.currentHeight

let maxPaymentSheetHeight = 95. // pct

let defaultVal: viewPortContants = {
  windowHeight,
  windowWidth,
  screenHeight,
  screenWidth,
  navigationBarHeight: defaultNavbarHeight,
  maxPaymentSheetHeight,
}

let viewPortContext = React.createContext((defaultVal, (_: viewPortContants) => ()))

module Provider = {
  let make = React.Context.provider(viewPortContext)
}
@react.component
let make = (~children, ~bottomInset) => {
  let (state, setState) = React.useState(_ => {
    ...defaultVal,
    navigationBarHeight: (
      WebKit.platform === #androidWebView ? 0. : bottomInset->Option.getOr(20.)
    ) +.
    defaultNavbarHeight,
  })

  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
