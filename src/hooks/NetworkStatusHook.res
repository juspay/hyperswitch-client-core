let useNetworkStatus = () => {
  let (isConnected, setIsConnected) = React.useState(_ => true)
  let (_, showBanner, hideBanner) = BannerContext.useBanner()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  let showConnected = React.useRef(false)

  let checkConnectivity = async () => {
    try {
      let headers = Dict.make()
      headers->Dict.set("Cache-Control", "no-cache")
      
      let response = await APIUtils.fetchApi(
        ~uri=`${baseUrl}/health`,
        ~method_=#GET,
        ~headers,
        ~mode=#cors,
        ~dontUseDefaultHeader=true
      )

      let statusCode = response->Fetch.Response.status->string_of_int
      let connected = statusCode->String.charAt(0) === "2"
      setIsConnected(_ => connected)

      if !connected {
        showConnected.current = true
        showBanner(~message="No internet connection", ~bannerType=#error)
      } else if showConnected.current {
        showBanner(~message="Back Online", ~bannerType=#success)
        showConnected.current = false
      } else {
        hideBanner()
      }
    } catch {
    | _ =>
      showConnected.current = true
      setIsConnected(_ => false)
      showBanner(~message="No internet connection", ~bannerType=#error)
    }
  }

  React.useEffect0(() => {
    let intervalId = setInterval(() => {
      checkConnectivity()->ignore
    }, 10000)
    checkConnectivity()->ignore
    Some(() => clearInterval(intervalId))
  })

  (isConnected, checkConnectivity)
}
