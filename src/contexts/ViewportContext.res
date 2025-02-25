type viewPortContants = {
  windowHeight: float,
  windowWidth: float,
  screenHeight: float,
  screenWidth: float,
  navigationBarHeight: float,
  maxPaymentSheetHeight: float,
}

let defaultNavbarHeight = 25.
let windowHeight = ReactNative.Dimensions.get(#window).height
let windowWidth = ReactNative.Dimensions.get(#window).width
let screenHeight = ReactNative.Dimensions.get(#screen).height
let screenWidth = ReactNative.Dimensions.get(#screen).width
let statusBarHeight = ReactNative.StatusBar.currentHeight

let navigationBarHeight = if ReactNative.Platform.os !== #android {
  defaultNavbarHeight
} else {
  let navigationHeight = screenHeight -. windowHeight -. statusBarHeight
  Math.min(75., Math.max(0., navigationHeight) +. defaultNavbarHeight)
}

let maxPaymentSheetHeight = 95. // pct

let defaultVal: viewPortContants = {
  windowHeight,
  windowWidth,
  screenHeight,
  screenWidth,
  navigationBarHeight,
  maxPaymentSheetHeight,
}

let viewPortContext = React.createContext((defaultVal, (_: viewPortContants) => ()))

module Provider = {
  let make = React.Context.provider(viewPortContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => defaultVal)

  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
