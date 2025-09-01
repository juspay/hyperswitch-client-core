let getValueFromPMLData = (outputPath: string, pmlRequiredFields: RequiredFieldsTypes.required_fields) => {
  let foundField = pmlRequiredFields->Array.find(pmlField => {
    let pmlFieldPath = pmlField.required_field->RequiredFieldsTypes.getRequiredFieldName
    pmlFieldPath === outputPath
  })
  
  switch foundField {
  | Some(field) => field.value
  | None => ""
  }
}


let mergeSuperpositionWithPMLValues = (
  superpositionFields: array<(string, array<SuperpositionHelper.fieldConfig>)>,
  allPMLRequiredFields: array<RequiredFieldsTypes.required_fields>,
) => {
  let flattenedPMLFields = allPMLRequiredFields->Array.flat
  
  superpositionFields->Array.map(((componentName, fields)) => {
    let mergedFields = fields->Array.map(superpositionField => {
      let pmlValue = getValueFromPMLData(superpositionField.outputPath, flattenedPMLFields)
      
      {
        ...superpositionField,
        defaultValue: pmlValue,
      }
    })
    
    (componentName, mergedFields)
  })
}

let hasAnyEmptyField = (fields: array<SuperpositionHelper.fieldConfig>) => {
  fields->Array.some(field => field.defaultValue === "")
}

let filterSuperpositionFields = (
  componentWiseFields: array<(string, array<SuperpositionHelper.fieldConfig>)>,
) => {
  componentWiseFields->Array.filter(((componentName, fields)) => {
    switch componentName {
    | "billing" | "shipping" => {
        let hasEmpty = hasAnyEmptyField(fields)
        hasEmpty
      }
    | _ => {
        hasAnyEmptyField(fields)
      }
    }
  })
}

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
  ~setIsAllCardValid=?,
  ~cardNetworks=?,
  ~setConfirmButtonDataRef=?,
  ~isScreenFocus=true,
) => {
  let (_, setIsSuperpositionInitialized) = React.useState(() => false)
  let (componentWiseRequiredFields, setComponentWiseRequiredFields) = React.useState(() => None)
  
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)

  let initSuperposition = async () => {
    let componentRequiredFields = await SuperpositionHelper.initSuperpositionAndGetRequiredFields()
    
    switch componentRequiredFields {
    | Some(fields) => {
        let allPMLRequiredFields = allApiData.paymentList->Array.map(paymentMethod => {
          switch paymentMethod {
          | PaymentMethodListType.CARD(cardData) => cardData.required_field
          | PaymentMethodListType.BANK_REDIRECT(bankData) => bankData.required_field
          | PaymentMethodListType.WALLET(walletData) => walletData.required_field
          | PaymentMethodListType.PAY_LATER(payLaterData) => payLaterData.required_field
          | PaymentMethodListType.BANK_TRANSFER(bankTransferData) => bankTransferData.required_field
          | PaymentMethodListType.CRYPTO(cryptoData) => cryptoData.required_field
          | PaymentMethodListType.BANK_DEBIT(bankDebitData) => bankDebitData.required_field
          | PaymentMethodListType.OPEN_BANKING(openBankingData) => openBankingData.required_field
          }
        })
        
        let mergedFields = mergeSuperpositionWithPMLValues(fields, allPMLRequiredFields)
        
        let filteredFields = filterSuperpositionFields(mergedFields)
        
        setComponentWiseRequiredFields(_ => Some(filteredFields))
      }
    | None => {
        setComponentWiseRequiredFields(_ => None)
      }
    }
    
    setIsSuperpositionInitialized(_ => true)
  }

  React.useEffect0(() => {
    initSuperposition()->ignore
    None
  })

  switch componentWiseRequiredFields {
  | Some(fields) if fields->Array.length > 0 =>
    <DynamicFieldsSuperposition 
      componentWiseRequiredFields=fields 
      setConfirmButtonDataRef={setConfirmButtonDataRef->Option.getOr(_ => ())}
      isScreenFocus
    />
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
      ?setIsAllCardValid
      ?cardNetworks
    />
  }
}
