@react.component
let make = () => {
  let (bannerState, _, hideBanner) = BannerContext.useBanner()
  // let (isConnected, _) = NetworkStatusHook.useNetworkStatus()
  let isConnected = true
  let (shouldRender, setShouldRender) = React.useState(_ => false)

  React.useEffect2(() => {
    if bannerState.isVisible {
      setShouldRender(_ => true)
      None
    } else {
      let timeoutId = setTimeout(() => {
        setShouldRender(_ => false)
      }, 300)
      Some(() => clearTimeout(timeoutId))
    }
  }, (bannerState.isVisible, setShouldRender))

  shouldRender
    ? <FloatingBanner
        message=bannerState.message
        bannerType=bannerState.bannerType
        isVisible=bannerState.isVisible
        isConnected
        onDismiss={_ => hideBanner()}
      />
    : React.null
}
