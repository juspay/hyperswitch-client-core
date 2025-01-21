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
    switch nativeProp.customLogUrl {
    | Some(url) => url
    | None =>
      switch nativeProp.env {
      | PROD => "https://api.hyperswitch.io/logs/sdk"
      | _ => "https://sandbox.hyperswitch.io/logs/sdk"
      }
    }
  }
}
