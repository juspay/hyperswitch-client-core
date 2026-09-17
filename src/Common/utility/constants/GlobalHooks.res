open EnvTypes

let backendPath = "/api"
let logsPath = "/api/logs/sdk"
let nonProdLogsPath = "/logs/sdk"
let assetsPath = "/assets/v2"

let getUrlFromNativeProp = (~urlType, ~customEndpoints: SdkTypes.customEndpointsConfig) => {
  switch urlType {
  | #backend =>
    customEndpoints.overrideEndpoints
    ->Option.map(endpoints => endpoints.customBackendEndpoint)
    ->Option.getOr(customEndpoints.commonEndpoint->Option.map(endpoint => endpoint ++ backendPath))
  | #logs =>
    customEndpoints.overrideEndpoints
    ->Option.map(endpoints => endpoints.customLoggingEndpoint)
    ->Option.getOr(customEndpoints.commonEndpoint->Option.map(endpoint => endpoint ++ logsPath))
  | #assets =>
    customEndpoints.overrideEndpoints
    ->Option.map(endpoints => endpoints.customAssetEndpoint)
    ->Option.getOr(customEndpoints.commonEndpoint->Option.map(endpoint => endpoint ++ assetsPath))
  }
}

let getDefaultBaseUrl = (~urlType, ~environment: GlobalVars.envType) => {
  switch urlType {
  | #assets =>
    switch environment {
    | PROD => process.env["PROD_ASSETS_END_POINT"] ++ assetsPath
    | SANDBOX => process.env["SANDBOX_ASSETS_END_POINT"] ++ assetsPath
    | INTEG => process.env["INTEG_ASSETS_END_POINT"] ++ assetsPath
    }
  | #logs =>
    switch environment {
    | PROD => process.env["HYPERSWITCH_PRODUCTION_URL"] ++ logsPath
    | SANDBOX => process.env["HYPERSWITCH_SANDBOX_URL"] ++ nonProdLogsPath
    | INTEG => process.env["HYPERSWITCH_INTEG_URL"] ++ nonProdLogsPath
    }
  | #backend =>
    switch environment {
    | PROD => process.env["HYPERSWITCH_PRODUCTION_URL"] ++ backendPath
    | SANDBOX => process.env["HYPERSWITCH_SANDBOX_URL"]
    | INTEG => process.env["HYPERSWITCH_INTEG_URL"]
    }
  }
}

let getUrl = (~customEndpoints, ~urlType, ~environment) => {
  switch switch customEndpoints {
  | Some(customEndpoints) => getUrlFromNativeProp(~customEndpoints, ~urlType)
  | None => None
  } {
  | Some(endpoint) => endpoint
  | None => getDefaultBaseUrl(~urlType, ~environment)
  }
}

let useGetBaseUrl = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  () =>
    getUrl(
      ~customEndpoints=nativeProp.hyperswitchConfig.customEndpoints,
      ~urlType=#backend,
      ~environment=nativeProp.hyperswitchConfig.environment,
    )
}

let useGetAssetUrlWithVersion = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  () =>
    getUrl(
      ~customEndpoints=nativeProp.hyperswitchConfig.customEndpoints,
      ~urlType=#assets,
      ~environment=nativeProp.hyperswitchConfig.environment,
    )
}

let getLoggingUrl = (~customEndpoints, ~environment) => {
  switch (
    getUrlFromNativeProp(~urlType=#backend, ~customEndpoints),
    getUrlFromNativeProp(~urlType=#logs, ~customEndpoints),
  ) {
  | (Some(_), None) => None
  | (_, Some(url)) => Some(url)
  | (None, None) => Some(getDefaultBaseUrl(~urlType=#logs, ~environment))
  }
}

let useGetLoggingUrl = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  () =>
    getLoggingUrl(
      ~customEndpoints=nativeProp.hyperswitchConfig.customEndpoints->Option.getOr(
        SdkTypes.defaultCustomEndpointsConfig,
      ),
      ~environment=nativeProp.hyperswitchConfig.environment,
    )
}
