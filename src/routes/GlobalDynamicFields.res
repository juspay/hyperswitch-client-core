@react.component
let make = (~dynamicFieldsState: DynamicFieldsTypes.dynamicFieldsState) => {
  dynamicFieldsState.isVisible
    ? <DynamicFields
        requiredFields=dynamicFieldsState.requiredFields
        setIsAllDynamicFieldValid=dynamicFieldsState.setIsAllDynamicFieldValid
        setDynamicFieldsJson=dynamicFieldsState.setDynamicFieldsJson
        isSaveCardsFlow=dynamicFieldsState.isSaveCardsFlow
        savedCardsData=dynamicFieldsState.savedCardsData
        keyToTrigerButtonClickError=dynamicFieldsState.keyToTrigerButtonClickError
        shouldRenderShippingFields=dynamicFieldsState.shouldRenderShippingFields
        displayPreValueFields=dynamicFieldsState.displayPreValueFields
        paymentMethodType=?dynamicFieldsState.paymentMethodType
        fieldsOrder=dynamicFieldsState.fieldsOrder
      />
    : React.null
}
