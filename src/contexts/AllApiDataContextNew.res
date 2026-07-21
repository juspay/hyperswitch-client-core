let allApiDataContext = React.createContext((
  (None: option<ClientListType.clientList>),
  (None: option<array<SessionsType.sessions>>),
  (None: option<SdkConfigTypes.sdkConfigValue>),
))

module Provider = {
  let make = React.Context.provider(allApiDataContext)
}
@react.component
let make = (~children, ~clientListData, ~sessionTokenData, ~sdkConfigData) => {
  <Provider value=(clientListData, sessionTokenData, sdkConfigData)> children </Provider>
}
