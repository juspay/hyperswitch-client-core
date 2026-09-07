let useSessionFetchers = (): SessionStore.fetchers => {
  let fetchClientData = AllPaymentHooks.useFetchClientData()
  let sessionToken = AllPaymentHooks.useSessionTokenHook()
  let sdkConfig = AllPaymentHooks.useSdkConfigHook()

  {
    fetchClient: () => fetchClientData(),
    fetchSessions: () => sessionToken(),
    fetchSdkConfig: () => sdkConfig(),
  }
}

let useSessionCredentialsKey = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  PaymentUtils.getSessionCredentialsKey(nativeProp)
}
