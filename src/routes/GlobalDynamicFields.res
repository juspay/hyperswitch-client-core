@react.component
let make = (~dynamicFieldsDataRef: DynamicFieldsTypes.dynamicFieldsDataRef) => {
  dynamicFieldsDataRef.isVisible
    ? <DynamicFields
        requiredFields=dynamicFieldsDataRef.requiredFields
        setIsAllDynamicFieldValid=dynamicFieldsDataRef.setIsAllDynamicFieldValid
        setDynamicFieldsJson=dynamicFieldsDataRef.setDynamicFieldsJson
        isSaveCardsFlow=dynamicFieldsDataRef.isSaveCardsFlow
        savedCardsData=dynamicFieldsDataRef.savedCardsData
        keyToTrigerButtonClickError=dynamicFieldsDataRef.keyToTrigerButtonClickError
        displayPreValueFields=dynamicFieldsDataRef.displayPreValueFields
        paymentMethodType=?dynamicFieldsDataRef.paymentMethodType
      />
    : React.null
}
