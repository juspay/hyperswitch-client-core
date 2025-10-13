let useNetworkStatus = () => {
  let (isConnected, setIsConnected) = React.useState(_ => true)
  let (_, showBanner, hideBanner) = BannerContext.useBanner()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  let showConnected = React.useRef(false)

  let checkConnectivity = async () => {
    try {
      let response = await Fetch.fetchWithInit(
        `${baseUrl}/health`,
        Fetch.RequestInit.make(
          ~method_=Get,
          ~mode=CORS,
          ~cache=NoCache,
          ~headers=Fetch.HeadersInit.make({"Cache-Control": "no-cache"}),
          (),
        ),
      )

      let statusCode = response->Fetch.Response.status->string_of_int
      let connected = statusCode->String.charAt(0) === "2"
      setIsConnected(_ => connected)

      if !connected {
        showConnected.current = true
        showBanner(~message="No internet connection", ~bannerType=#error)
      } else {
        if showConnected.current {
          showBanner(~message="Back Online", ~bannerType=#success)
          showConnected.current = false
        } else {
          hideBanner()
        }
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
