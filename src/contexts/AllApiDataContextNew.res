type contextValue = {
  clientData: ClientResponseType.clientResponse,
  sdkConfigData: SdkConfigTypes.sdkConfigValue,
  sessionTokenData: option<array<SessionsType.sessions>>,
}

let allApiDataContext: React.Context.t<option<contextValue>> = React.createContext(None)

module Provider = {
  let make = React.Context.provider(allApiDataContext)
}

@react.component
let make = (~children, ~allApiData: option<contextValue>) => {
  <Provider value=allApiData> children </Provider>
}

let useOptionalData = () => React.useContext(allApiDataContext)

let useData = () =>
  switch React.useContext(allApiDataContext) {
  | Some(data) => data
  | None =>
    Exn.raiseError(
      "AllApiDataContextNew.useData called while API data is still loading — render this component below a loading gate.",
    )
  }
