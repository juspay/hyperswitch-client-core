open ReactNative
type screenType = Small | Medium | Large

let useDimension = () => {
  let (screenType, setScreenType) = React.useState(() => Small)

  let handleDimensionChange = _ => {
    let width = Dimensions.get(#window).width
    if width < 640. {
      setScreenType(_ => Small)
    } else if width > 640. && width < 786. {
      setScreenType(_ => Medium)
    } else if width > 768. {
      setScreenType(_ => Large)
    }
  }
  React.useEffect0(() => {
    let subscription = Dimensions.addEventListener(#change, handleDimensionChange)
    handleDimensionChange()
    Some(
      () => {
        subscription->EventSubscription.remove
      },
    )
  })
  (screenType, Dimensions.get(#window))
}
