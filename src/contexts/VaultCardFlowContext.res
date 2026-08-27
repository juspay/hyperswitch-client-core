let vaultCardFlowContext = React.createContext((
  None: option<(VaultActivation.activation, React.ref<Nullable.t<VaultCardForm.vaultFormHandle>>)>
))

module Provider = {
  let make = React.Context.provider(vaultCardFlowContext)
}
