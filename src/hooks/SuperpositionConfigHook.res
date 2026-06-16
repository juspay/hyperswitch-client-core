let useGetSuperpositionRawConfigs = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let logger = LoggerHook.useLoggerHook()
  let logOutcome = outcome =>
    logger(
      ~logType=INFO,
      ~value=outcome,
      ~category=USER_EVENT,
      ~eventName=LoggerTypes.CONFIG_CALL,
      (),
    )

  let decodedProfileId = switch nativeProp.paymentSessionConfig.sdkAuthorization {
  | Some(auth) => Utils.getSdkAuthorizationData(auth).profileId
  | None => None
  }
  let profileId = switch decodedProfileId {
  | Some(_) => decodedProfileId
  | None => nativeProp.hyperswitchConfig.profileId
  }

  let fetchConfig = profileId->Option.map(_ => {
    () => {
      let uri = `${baseUrl}/v1/sdk/configs/web/sdk_config.json`

      let clientSecret = {
        let fromConfig = nativeProp.paymentSessionConfig.clientSecret
        if fromConfig->String.length > 0 {
          fromConfig
        } else {
          let fromAuth = switch nativeProp.paymentSessionConfig.sdkAuthorization {
          | Some(auth) => Utils.getSdkAuthorizationData(auth).clientSecret->Option.getOr("")
          | None => ""
          }
          if fromAuth->String.length == 0 {
            logOutcome("missing-client-secret")
          }
          fromAuth
        }
      }

      let headers = Utils.getHeader(
        ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
        ~appId=nativeProp.sdkParams.appId,
        (),
      )
      if clientSecret->String.length > 0 {
        headers->Dict.set("client-secret", clientSecret)
      }

      APIUtils.fetchApiWrapper(
        ~uri,
        ~method=#GET,
        ~headers,
        ~eventName=LoggerTypes.CONFIG_CALL,
        ~apiLogWrapper,
      )
    }
  })

  let refetchKey =
    `${profileId->Option.getOr("no-profile")}|${baseUrl}|${nativeProp.hyperswitchConfig.publishableKey}`

  SuperpositionConfigLoader.useSuperpositionRawConfigs(~fetchConfig, ~refetchKey, ~logOutcome)
}
