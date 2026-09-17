type refusal =
  | UnreadableVaultingAction
  | VaultUnavailable

type strategy =
  | Pending
  | DirectCard
  | VaultCard(VaultDetailsType.vaultDetails)
  | Refused(refusal)

type formState = {
  isValid: bool,
  showErrors: bool,
}

let defaultFormState = {isValid: false, showErrors: false}

type cardStrategyData = {
  strategy: strategy,
  getFormState: string => formState,
  setFormValid: (string, bool) => unit,
  setShowErrors: (string, bool) => unit,
}

let cardStrategyContext = React.createContext({
  strategy: Pending,
  getFormState: _ => defaultFormState,
  setFormValid: (_, _) => (),
  setShowErrors: (_, _) => (),
})

module Provider = {
  let make = React.Context.provider(cardStrategyContext)
}

@react.component
let make = (~children, ~strategy: strategy) => {
  let (formStates, setFormStates) = React.useState(() => Dict.make())

  let getFormState = React.useCallback1(
    formId => formStates->Dict.get(formId)->Option.getOr(defaultFormState),
    [formStates],
  )

  let update = React.useCallback1((formId, f) => {
    setFormStates(prev => {
      let current = prev->Dict.get(formId)->Option.getOr(defaultFormState)
      let next = f(current)
      if next.isValid === current.isValid && next.showErrors === current.showErrors {
        prev
      } else {
        let copy = prev->Dict.copy
        copy->Dict.set(formId, next)
        copy
      }
    })
  }, [setFormStates])

  let setFormValid = React.useCallback1(
    (formId, isValid) => update(formId, s => {...s, isValid}),
    [update],
  )

  let setShowErrors = React.useCallback1(
    (formId, showErrors) => update(formId, s => {...s, showErrors}),
    [update],
  )

  <Provider value={strategy, getFormState, setFormValid, setShowErrors}> children </Provider>
}
