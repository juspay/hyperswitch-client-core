open EnvTypes
let useGetBaseUrl = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  () => {
    switch nativeProp.customBackendUrl {
    | Some(url) => url
    | None =>
      switch nativeProp.env {
      | PROD => process.env["HYPERSWITCH_PRODUCTION_URL"]
      | SANDBOX => process.env["HYPERSWITCH_SANDBOX_URL"]
      | INTEG => process.env["HYPERSWITCH_INTEG_URL"]
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
    switch (nativeProp.customBackendUrl, nativeProp.customLogUrl) {
    | (Some(_), None) => None
    | (_, Some(url)) => Some(url)
    | (None, None) =>
      Some(
        switch nativeProp.env {
        | PROD => process.env["HYPERSWITCH_PRODUCTION_URL"]
        | _ => process.env["HYPERSWITCH_SANDBOX_URL"]
        } ++
        process.env["HYPERSWITCH_LOGS_PATH"],
      )
    }
  }
}
