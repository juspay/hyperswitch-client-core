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
