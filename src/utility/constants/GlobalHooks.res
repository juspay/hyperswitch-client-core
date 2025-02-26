let useGetBaseUrl = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  () => {
    switch nativeProp.customBackendUrl {
    | Some(url) => url
    | None =>
      switch nativeProp.env {
      | PROD => "https://api.hyperswitch.io"
      | SANDBOX => "https://sandbox.hyperswitch.io"
      | INTEG => "https://integ-api.hyperswitch.io"
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
    | INTEG => "/assets/v1"
    }
  }
}

let useGetAssetUrlWithVersion = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let appendVersion = useGetS3AssetsVersion()()
  () => {
    switch nativeProp.env {
    | PROD => "https://checkout.hyperswitch.io"
    | SANDBOX => "https://beta.hyperswitch.io"
    | INTEG => "https://dev.hyperswitch.io"
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
      switch nativeProp.env {
      | PROD => Some("https://api.hyperswitch.io/logs/sdk")
      | _ => Some("https://sandbox.hyperswitch.io/logs/sdk")
      }
    }
  }
}
