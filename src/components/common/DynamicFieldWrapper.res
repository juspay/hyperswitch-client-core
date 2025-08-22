@react.component
let make = (
  ~requiredFields: RequiredFieldsTypes.required_fields,
  ~setIsAllDynamicFieldValid,
  ~setDynamicFieldsJson,
  ~isSaveCardsFlow=false,
  ~savedCardsData: option<SdkTypes.savedDataType>,
  ~keyToTrigerButtonClickError,
  ~shouldRenderShippingFields=false,
  ~displayPreValueFields=false,
  ~paymentMethodType=?,
  ~fieldsOrder: array<DynamicFields.fieldType>=[Other, Billing, Shipping],
) => {
  let (_, setIsSuperpositionInitialized) = React.useState(() => false)
  let (componentWiseRequiredFields, setComponentWiseRequiredFields) = React.useState(() => None)

  let initSuperposition = async () => {
    let componentRequiredFields = await SuperpositionHelper.initSuperpositionAndGetRequiredFields()
    setComponentWiseRequiredFields(_ => componentRequiredFields)
    setIsSuperpositionInitialized(_ => true)
  }

  React.useEffect0(() => {
    initSuperposition()->ignore
    None
  })

  switch componentWiseRequiredFields {
  | Some(fields) if fields->Array.length > 0 =>
    <DynamicFieldsSuperposition componentWiseRequiredFields=fields />
  | None
  | _ =>
    <DynamicFields
      requiredFields
      setIsAllDynamicFieldValid
      setDynamicFieldsJson
      isSaveCardsFlow
      savedCardsData
      keyToTrigerButtonClickError
      shouldRenderShippingFields
      displayPreValueFields
      ?paymentMethodType
      fieldsOrder
    />
  }
}
