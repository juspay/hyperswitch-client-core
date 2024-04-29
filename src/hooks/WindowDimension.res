type useWindowDimensions = {height: float, width: float, scale: float}
@module("react-native")
external useWindowDimensions: unit => useWindowDimensions = "useWindowDimensions"

type mediaView = Mobile | Tablet | Desktop

let useMediaView = () => {
  let {width} = useWindowDimensions()
  () => {
    if width < 441.0 {
      Mobile
    } else if width < 830.0 {
      Tablet
    } else {
      Desktop
    }
  }
}

let useIsMobileView = () => {
  useMediaView()() == Mobile
}
