open ReactNative
open Style

@react.component
let make = (~children, ~setDynamicHeight, ~isScreenFocus) => {
  let (viewHeight, setViewHeight) = React.useState(_ => 100.)
  let timer = React.useRef(Js.Nullable.null)

  let updateTabHeight = (event: Event.layoutEvent) => {
    let {height} = event.nativeEvent.layout
    if height > 100. && (viewHeight -. height)->Math.abs > 10. {
      switch timer.current->Js.Nullable.toOption {
      | Some(timerId) => Js.Global.clearTimeout(timerId)
      | None => ()
      }
      let timerId = Js.Global.setTimeout(() => {
        setViewHeight(_ => height)

        LayoutAnimation.configureNext({
          duration: 10.,
          update: {
            duration: 10.,
            \"type": #easeInEaseOut,
          },
        })
      }, 300)
      timer.current = timerId->Js.Nullable.return
    }
  }

  React.useEffect3(() => {
    isScreenFocus ? setDynamicHeight(viewHeight) : ()
    None
  }, (viewHeight, setDynamicHeight, isScreenFocus))
  <View onLayout=updateTabHeight style={s({width: Dimensions.get(#window).width->dp})}>
    children
  </View>
}
