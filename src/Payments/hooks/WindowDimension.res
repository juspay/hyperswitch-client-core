type mediaView = Mobile | Tablet | Desktop

let useMediaView = () => {
  let {width} = ReactNative.Dimensions.useWindowDimensions()

  if width < 441.0 {
    Mobile
  } else if width < 830.0 {
    Tablet
  } else {
    Desktop
  }
}
