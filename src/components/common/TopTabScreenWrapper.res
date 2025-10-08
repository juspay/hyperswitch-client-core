open ReactNative
open Style

@react.component
let make = (~children, ~setDynamicHeight, ~isScreenFocus, ~width=None) => {
  let (viewHeight, setViewHeight) = React.useState(_ => 70.)
  let updateTabHeight = (event: Event.layoutEvent) => {
    let {height} = event.nativeEvent.layout
    if height > 70. && (viewHeight -. height)->Math.abs > 10. {
      setViewHeight(_ => height)
    }
  }

  React.useEffect3(() => {
    if isScreenFocus {
      setDynamicHeight(viewHeight)
    }
    None
  }, (viewHeight, setDynamicHeight, isScreenFocus))
  <View
    onLayout=updateTabHeight
    style={s({width: width->Option.getOr(Dimensions.get(#window).width->dp)})}>
    children
  </View>
}
