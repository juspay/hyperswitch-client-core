open EnvTypes
let useGetBaseUrl = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  () => {
    switch nativeProp.baseConfiguration.customEndpoint {
    | CustomEndpoint(endpoint) =>
      switch endpoint {
      | Some(url) => url
      | None =>
        switch nativeProp.env {
        | PROD => EnvTypes.process.env["HYPERSWITCH_PRODUCTION_URL"]
        | SANDBOX => EnvTypes.process.env["HYPERSWITCH_SANDBOX_URL"]
        | INTEG => EnvTypes.process.env["HYPERSWITCH_INTEG_URL"]
        }
      }
    | OverrideEndpoints(endpoints) =>
      switch endpoints.backendEndpoint {
      | Some(url) => url
      | None =>
        switch nativeProp.env {
        | PROD => EnvTypes.process.env["HYPERSWITCH_PRODUCTION_URL"]
        | SANDBOX => EnvTypes.process.env["HYPERSWITCH_SANDBOX_URL"]
        | INTEG => EnvTypes.process.env["HYPERSWITCH_INTEG_URL"]
        }
      }
    }
  }
}
let useGetS3AssetsVersion = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  () => {
    switch nativeProp.env {
    | PROD
    | SANDBOX
    | INTEG => "/assets/v2"
    }
  }
}

let useGetAssetUrlWithVersion = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let appendVersion = useGetS3AssetsVersion()()
  () => {
    switch nativeProp.env {
    | PROD => process.env["PROD_ASSETS_END_POINT"]
    | SANDBOX => process.env["SANDBOX_ASSETS_END_POINT"]
    | INTEG => process.env["INTEG_ASSETS_END_POINT"]
    } ++
    appendVersion
  }
}

let useGetLoggingUrl = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  () => {
    switch nativeProp.baseConfiguration.customEndpoint {
    | CustomEndpoint(url) => url
    | OverrideEndpoints(endpoints) =>
      Some(
        endpoints.loggingEndpoint->Option.getOr(
          switch nativeProp.env {
          | PROD => EnvTypes.process.env["HYPERSWITCH_PRODUCTION_URL"]
          | SANDBOX => EnvTypes.process.env["HYPERSWITCH_SANDBOX_URL"]
          | INTEG => EnvTypes.process.env["HYPERSWITCH_INTEG_URL"]
          } ++
          process.env["HYPERSWITCH_LOGS_PATH"],
        ),
      )
    }
  }
}
