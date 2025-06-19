@react.component
let make = (~requiredFields, ~paymentMethod, ~paymentExperience) => {
  let (isAllDynamicFieldValid, setIsAllDynamicFieldValid) = React.useState(_ => false)

  let (dynamicFieldsJson, setDynamicFieldsJson) = React.useState((_): dict<(
    JSON.t,
    option<string>,
  )> => Dict.make())

  let (keyToTrigerButtonClickError, setKeyToTrigerButtonClickError) = React.useState(_ => 0)

  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])

  let handlePress = _ => {
    if isAllDynamicFieldValid {
      setLoading(ProcessingPayments(None))
      setKeyToTrigerButtonClickError(prev => prev + 1)
    } else {
      setKeyToTrigerButtonClickError(prev => prev + 1)
    }
  }

  let (error, _setError) = React.useState(_ => None)

  React.useEffect(() => {
    setConfirmButtonDataRef(
      <ConfirmButton
        loading=false
        isAllValuesValid=true
        handlePress
        hasSomeFields=false
        paymentMethod
        ?paymentExperience
        errorText=error
      />,
    )

    None
  }, (isAllDynamicFieldValid, paymentMethod, paymentExperience, error))

  <React.Fragment>
    <DynamicFields
      requiredFields
      setIsAllDynamicFieldValid
      setDynamicFieldsJson
      keyToTrigerButtonClickError
      savedCardsData=None
    />
    <Space height=15. />
    <GlobalConfirmButton confirmButtonDataRef />
    <Space height=15. />
  </React.Fragment>
}
