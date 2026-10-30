open EnvTypes

let backendPath = "/api"
let logsPath = "/api/logs/sdk"
let assetsPath = "/assets/v2"

let warnedEndpoints = Set.make()

// Custom endpoints must use https. Plain http is only accepted with
// sandbox/integ keys so local servers keep working; never in production.
let isAllowedEndpoint = (~environment: GlobalVars.envType, endpoint) => {
  let allowed = switch environment {
  | PROD => %re("/^https:\/\/[^\/\s?#]+/i")->RegExp.test(endpoint)
  | SANDBOX | INTEG => %re("/^https?:\/\/[^\/\s?#]+/i")->RegExp.test(endpoint)
  }
  if !allowed && !(warnedEndpoints->Set.has(endpoint)) {
    warnedEndpoints->Set.add(endpoint)
    Console.warn(
      `Hyperswitch: ignoring custom endpoint "${endpoint}". Use an https:// URL (http:// is only allowed with sandbox keys).`,
    )
  }
  allowed
}

let getUrlFromNativeProp = (
  ~urlType,
  ~customEndpoints: SdkTypes.customEndpointsConfig,
  ~environment,
) => {
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
  }->Option.filter(endpoint => isAllowedEndpoint(~environment, endpoint))
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
    | SANDBOX => process.env["HYPERSWITCH_SANDBOX_URL"] ++ logsPath
    | INTEG => process.env["HYPERSWITCH_INTEG_URL"] ++ logsPath
    }
  | #backend =>
    switch environment {
    | PROD => process.env["HYPERSWITCH_PRODUCTION_URL"] ++ backendPath
    | SANDBOX => process.env["HYPERSWITCH_SANDBOX_URL"] ++ backendPath
    | INTEG => process.env["HYPERSWITCH_INTEG_URL"] ++ backendPath
    }
  }
}

let getUrl = (~customEndpoints, ~urlType, ~environment) => {
  switch switch customEndpoints {
  | Some(customEndpoints) => getUrlFromNativeProp(~customEndpoints, ~urlType, ~environment)
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
    getUrlFromNativeProp(~urlType=#backend, ~customEndpoints, ~environment),
    getUrlFromNativeProp(~urlType=#logs, ~customEndpoints, ~environment),
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
