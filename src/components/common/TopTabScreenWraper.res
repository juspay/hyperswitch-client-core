open ReactNative
open Style

@react.component
let make = (~children, ~setDynamicHeight, ~isScreenFocus) => {
  let (viewHeight, setViewHeight) = React.useState(_ => 0.)
  let updateTabHeight = (event: Event.layoutEvent) => {
    let {height} = event.nativeEvent.layout
    if (viewHeight -. height)->Math.abs > 10. {
      setViewHeight(_ => height)
    } else if height == 0. {
      setViewHeight(_ => 100.)
    }
  }

  React.useEffect3(() => {
    isScreenFocus ? setDynamicHeight(viewHeight) : ()
    None
  }, (viewHeight, setDynamicHeight, isScreenFocus))
  <View onLayout=updateTabHeight style={viewStyle(~width=100.->pct, ())}> children </View>
}
