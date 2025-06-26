open ReactNative
open Style

@react.component
let make = (~children, ~setDynamicHeight, ~isScreenFocus) => {
  let (viewHeight, setViewHeight) = React.useState(_ => 100.)
  let updateTabHeight = (event: Event.layoutEvent) => {
    let {height} = event.nativeEvent.layout
    if height > 100. && (viewHeight -. height)->Math.abs > 10. {
      setViewHeight(_ => height)

      LayoutAnimation.configureNext({
        duration: 10.,
        update: {
          duration: 10.,
          \"type": #easeInEaseOut,
        },
      })
    }
  }

  React.useEffect3(() => {
    isScreenFocus ? setDynamicHeight(viewHeight) : ()
    None
  }, (viewHeight, setDynamicHeight, isScreenFocus))
  <View onLayout=updateTabHeight style={s({width: 100.->pct})}> children </View>
}
