let allApiDataContext = React.createContext((
  (None: option<CombinedPMLType.combinedPML>),
  (None: option<array<SessionsType.sessions>>),
  (None: option<SdkConfigTypes.sdkConfigValue>),
))

module Provider = {
  let make = React.Context.provider(allApiDataContext)
}
@react.component
let make = (~children, ~combinedPMLData, ~sessionTokenData, ~sdkConfigData) => {
  <Provider value=(combinedPMLData, sessionTokenData, sdkConfigData)> children </Provider>
}
