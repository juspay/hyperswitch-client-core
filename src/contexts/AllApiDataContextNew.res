let allApiDataContext = React.createContext((
  (None: option<ClientResponseType.clientResponse>),
  (None: option<array<SessionsType.sessions>>),
  (None: option<SdkConfigTypes.sdkConfigValue>),
))

module Provider = {
  let make = React.Context.provider(allApiDataContext)
}
@react.component
let make = (~children, ~clientData, ~sessionTokenData, ~sdkConfigData) => {
  <Provider value=(clientData, sessionTokenData, sdkConfigData)> children </Provider>
}
