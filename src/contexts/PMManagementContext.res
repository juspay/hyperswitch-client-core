type pmManagementScreen = LIST_SCREEN | ADD_PM_SCREEN
let dafaultVal = LIST_SCREEN

let pmManagementScreenTypeContext = React.createContext((dafaultVal, (_: pmManagementScreen) => ()))

module Provider = {
  let make = React.Context.provider(pmManagementScreenTypeContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => dafaultVal)

  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
