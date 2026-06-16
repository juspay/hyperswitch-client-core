let superpositionConfigContext = React.createContext((
  SdkConfigTypes.defaultSdkConfigValue: SdkConfigTypes.sdkConfigValue
))

module Provider = {
  let make = React.Context.provider(superpositionConfigContext)
}

@react.component
let make = (~children) => {
  let configResult = SuperpositionConfigHook.useGetSuperpositionRawConfigs()
  <Provider value=configResult> children </Provider>
}
