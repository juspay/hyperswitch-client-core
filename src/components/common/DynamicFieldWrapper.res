let getValueFromPMLData = (
  outputPath: string, 
  allPaymentMethods: array<PaymentMethodListType.payment_method>,
  selectedPaymentMethod: option<string>,
  ~isCardPayment: bool=false
) => {
  let targetPaymentMethodFields = switch selectedPaymentMethod {
  | Some(paymentMethodName) => {
      let matchingPaymentMethod = allPaymentMethods->Array.find(paymentMethod => {
        let pmType = switch paymentMethod {
        | PaymentMethodListType.CARD(_) => "card"
        | PaymentMethodListType.PAY_LATER(prop) => prop.payment_method_type
        | PaymentMethodListType.BANK_REDIRECT(prop) => prop.payment_method_type
        | PaymentMethodListType.WALLET(prop) => prop.payment_method_type
        | PaymentMethodListType.BANK_TRANSFER(prop) => prop.payment_method_type
        | PaymentMethodListType.CRYPTO(prop) => prop.payment_method_type
        | PaymentMethodListType.BANK_DEBIT(prop) => prop.payment_method_type
        | PaymentMethodListType.OPEN_BANKING(prop) => prop.payment_method_type
        }
        pmType === paymentMethodName
      })
      
      switch matchingPaymentMethod {
      | Some(PaymentMethodListType.CARD(cardData)) => cardData.required_field
      | Some(PaymentMethodListType.PAY_LATER(payLaterData)) => payLaterData.required_field
      | Some(PaymentMethodListType.BANK_REDIRECT(bankData)) => bankData.required_field
      | Some(PaymentMethodListType.WALLET(walletData)) => walletData.required_field
      | Some(PaymentMethodListType.BANK_TRANSFER(bankTransferData)) => bankTransferData.required_field
      | Some(PaymentMethodListType.CRYPTO(cryptoData)) => cryptoData.required_field
      | Some(PaymentMethodListType.BANK_DEBIT(bankDebitData)) => bankDebitData.required_field
      | Some(PaymentMethodListType.OPEN_BANKING(openBankingData)) => openBankingData.required_field
      | None => []
      }
    }
  | None => {
      allPaymentMethods->Array.map(paymentMethod => {
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
      })->Array.flat
    }
  }
  
  let filteredFields = if isCardPayment {
    targetPaymentMethodFields->Array.filter(pmlField => {
      let fieldName = pmlField.required_field->RequiredFieldsTypes.getRequiredFieldName
      !(fieldName->String.includes("wallet.")) && 
      !(fieldName->String.includes("bank_")) && 
      !(fieldName->String.includes("crypto.")) &&
      !(fieldName->String.includes("upi."))
    })
  } else {
    targetPaymentMethodFields
  }
  
  let foundField = filteredFields->Array.find(pmlField => {
    let pmlFieldPath = pmlField.required_field->RequiredFieldsTypes.getRequiredFieldName
    pmlFieldPath->String.includes(outputPath)
  })
  
  switch foundField {
  | Some(field) => field.value
  | None => ""
  }
}


let mergeSuperpositionWithPMLValues = (
  superpositionFields: array<(string, array<SuperpositionTypes.fieldConfig>)>,
  allPaymentMethods: array<PaymentMethodListType.payment_method>,
  selectedPaymentMethod: option<string>,
) => {
  superpositionFields->Array.map(((componentName, fields)) => {
    let mergedFields = fields->Array.map(superpositionField => {
      if superpositionField.name->String.endsWith(".full_name") && superpositionField.mergedFields->Array.length > 0 {
        if superpositionField.defaultValue !== "" {
          superpositionField
        } else {
          let mergedValues = superpositionField.mergedFields
            ->Array.map(originalField => {
              getValueFromPMLData(originalField.outputPath, allPaymentMethods, selectedPaymentMethod, ~isCardPayment=true)
            })
            ->Array.filter(value => value !== "")
            ->Array.join(" ")
          
          {
            ...superpositionField,
            defaultValue: mergedValues,
          }
        }
      } else {
        let pmlValue = getValueFromPMLData(superpositionField.outputPath, allPaymentMethods, selectedPaymentMethod)
        
        {
          ...superpositionField,
          defaultValue: pmlValue,
        }
      }
    })
    
    (componentName, mergedFields)
  })
}

let hasAnyEmptyField = (fields: array<SuperpositionTypes.fieldConfig>) => {
  fields->Array.some(field => field.defaultValue === "")
}

let filterSuperpositionFields = (
  componentWiseFields: array<(string, array<SuperpositionTypes.fieldConfig>)>,
) => {
  componentWiseFields->Array.filter(((componentName, fields)) => {
    switch componentName {
    | "billing" | "shipping" => {
        // For billing and shipping, always include the component if it has fields
        // We need to process both complete and incomplete PML data
        fields->Array.length > 0
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
  // ~setConfirmButtonDataRef=?,
  ~isScreenFocus=true,
  ~walletData: option<PaymentScreenContext.walletData>=?,
  ~walletType: option<PaymentMethodListType.payment_method_types_wallet>=?,
  ~onNoMissingFields: option<(unit) => unit>=?,
  ~onFormValuesChange: option<(JSON.t) => unit>=?,
  ~onMissingFieldsStateChange: option<(bool) => unit>=?,
  ~isNicknameSelected=false,
  ~nickname: option<string>=?,
  ~isSaveCardCheckboxVisible=false,
  ~isGuestCustomer=true,
) => {
  let paymentMethodContext = React.useContext(PaymentMethodSelectionContext.paymentMethodSelectionContext)
  let selectedPaymentMethod = paymentMethodContext.selectedPaymentMethod
  let externalSuperpositionFields = paymentMethodContext.externalSuperpositionFields
  let (_, setIsSuperpositionInitialized) = React.useState(() => false)
  let (componentWiseRequiredFields, setComponentWiseRequiredFields) = React.useState(() => None)
  let (hasMissingFields, setHasMissingFields) = React.useState(() => None)
  let (walletPaymentMethodData, setWalletPaymentMethodData) = React.useState(() => None)
  
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  
  // Default no-op function for onNoMissingFields callback
  let onNoMissingFields = switch onNoMissingFields {
  | Some(fn) => fn
  | None => () => ()
  }
  
  // Form values change callback
  let onFormValuesChangeCallback = onFormValuesChange
  
  // Missing fields state change callback
  let onMissingFieldsStateChangeCallback = onMissingFieldsStateChange

  let initSuperposition = async () => {
    // Create context for superposition evaluation
  let contextWithConnectorArray: SuperpositionTypes.connectorArrayContext = {
  eligibleConnectors: ["Stripe", "Adyen", "Cybersource", "Airwallex"],
  payment_method: "Card",
  payment_method_type: Some("debit"),
  country: Some("US"),
  mandate_type: Some("non_mandate"),
  collect_shipping_details_from_wallet_connector: None,  // Add missing field
  collect_billing_details_from_wallet_connector: None,   // Add missing field
}
    
    let componentRequiredFields = await SuperpositionHelper.initSuperpositionAndGetRequiredFields(~contextWithConnectorArray)
    switch componentRequiredFields {
    | Some(fields) => {
        let fieldsWithMergedNames = fields->Array.map(((componentName, componentFields)) => {
          let mergedFields = SuperpositionHelper.mergeFields(
            componentFields,
            ["first_name", "last_name"],
            "full_name",
            "Full Name",
            ~parent=""
          )
          (componentName, mergedFields)
        })
        
        // Check if this is a wallet missing fields scenario
        switch (walletData, walletType) {
        | (Some(walletDataValue), Some(_)) => {
            // Extract shipping and billing addresses from wallet data
            let (shippingAddress, billingAddress, email) = switch walletDataValue {
            | GooglePayData(gPayData) => {
                let billingFromGPay = switch gPayData.paymentMethodData.info {
                | Some(info) => info.billing_address
                | None => None
                }
                (gPayData.shippingDetails, billingFromGPay, gPayData.email)
              }
            | ApplePayData(aPayData) => (aPayData.shippingAddress, aPayData.billingContact, aPayData.email)
            | SamsungPayData(_, billingAddr, shippingAddr) => (shippingAddr, billingAddr, billingAddr->Option.flatMap(addr => addr.email))
            }
            
            // Filter to only billing fields since user mentioned we only need billing details
            let billingOnlyFields = fieldsWithMergedNames->Array.filter(((componentName, _)) => {
              componentName === "billing"
            })
            
            // For wallet missing fields, get the missing fields with wallet data pre-filled
            let (hasMissingFieldsValue, missingFields, paymentMethodData) = WalletType.getMissingFieldsAndPaymentMethodDataSuperposition(
              billingOnlyFields,
              ~shippingAddress,
              ~billingAddress,
              ~email,
              ~collectBillingDetailsFromWallets=true,
            )
            setComponentWiseRequiredFields(_ => Some(missingFields))
            setHasMissingFields(_ => Some(hasMissingFieldsValue))
            setWalletPaymentMethodData(_ => Some(paymentMethodData->JSON.Encode.object))
            
            // Notify parent of missing fields state change
            switch onMissingFieldsStateChangeCallback {
            | Some(callback) => callback(hasMissingFieldsValue)
            | None => ()
            }
            
            // If no fields are missing, call the callback to process payment directly
            if !hasMissingFieldsValue {
              onNoMissingFields()
            }
          }
        | _ => {
            // Regular flow - merge with PML values
            let mergedFields = mergeSuperpositionWithPMLValues(fieldsWithMergedNames, allApiData.paymentList, selectedPaymentMethod)
            
            let filteredFields = filterSuperpositionFields(mergedFields)
            
            let hasMissingFieldsValue = {
              let billingFields = filteredFields->Array.find(((componentName, _)) => componentName === "billing")
              switch billingFields {
              | Some(("billing", fields)) => 
                  fields->Array.some(field => field.defaultValue === "" && field.required)
              | Some((_, _)) => false 
              | None => false 
              }
            }
            
            setComponentWiseRequiredFields(_ => Some(filteredFields))
            setHasMissingFields(_ => Some(hasMissingFieldsValue))
            
            switch onMissingFieldsStateChangeCallback {
            | Some(callback) => callback(hasMissingFieldsValue)
            | None => ()
            }
          }
        }
      }
    | None => {
        setComponentWiseRequiredFields(_ => None)
      }
    }
    
    setIsSuperpositionInitialized(_ => true)
  }

  React.useEffect1(() => {
    switch externalSuperpositionFields {
    | Some(fields) => {
        let fieldsWithMergedNames = fields->Array.map(((componentName, componentFields)) => {
          let mergedFields = SuperpositionHelper.mergeFields(
            componentFields,
            ["first_name", "last_name"],
            "full_name",
            "Full Name",
            ~parent=""
          )
          (componentName, mergedFields)
        })
        
        let mergedFields = mergeSuperpositionWithPMLValues(fieldsWithMergedNames, allApiData.paymentList, selectedPaymentMethod)
        let filteredFields = filterSuperpositionFields(mergedFields)
        
        let hasMissingFieldsValue = {
          let billingFields = filteredFields->Array.find(((componentName, _)) => componentName === "billing")
          switch billingFields {
          | Some(("billing", fields)) => 
              fields->Array.some(field => field.defaultValue === "" && field.required)
          | Some((_, _)) => false 
          | None => false
          }
        }
        
        setComponentWiseRequiredFields(_ => Some(filteredFields))
        setHasMissingFields(_ => Some(hasMissingFieldsValue))
        
        switch onMissingFieldsStateChangeCallback {
        | Some(callback) => callback(hasMissingFieldsValue)
        | None => ()
        }
      }
    | None => {
        switch selectedPaymentMethod {
        | Some("card") | None => {
            initSuperposition()->ignore
          }
        | Some(_) => {
            setComponentWiseRequiredFields(_ => None)
          }
        }
      }
    }
    None
  }, [externalSuperpositionFields])

  React.useEffect0(() => {
    switch (externalSuperpositionFields, selectedPaymentMethod) {
    | (None, None) | (None, Some("card")) => {
        initSuperposition()->ignore
      }
    | _ => () 
    }
    None
  })

  let fieldsToRender = switch (selectedPaymentMethod, externalSuperpositionFields, componentWiseRequiredFields) {
  | (Some(_), Some(fields), _) when fields->Array.length > 0 => Some(fields)
  | (_, _, Some(fields)) when fields->Array.length > 0 => Some(fields)
  | _ => None
  }

  let shouldRenderDefaultCard = switch (selectedPaymentMethod, setIsAllCardValid, fieldsToRender) {
  | (Some("card"), Some(_), None) | (None, Some(_), None) => true 
  | _ => false
  }

  switch fieldsToRender {
  | Some(fields) =>
    <DynamicFieldsSuperposition 
      componentWiseRequiredFields=fields 
      // setConfirmButtonDataRef={setConfirmButtonDataRef->Option.getOr(_ => ())}
      isScreenFocus
      _walletData=?walletData
      _walletType=?walletType
      ?hasMissingFields
      ?walletPaymentMethodData
      onFormValuesChange=?onFormValuesChangeCallback
      keyToTrigerButtonClickError
      isNicknameSelected
      nickname={nickname->Option.getOr("")}
      isSaveCardCheckboxVisible
      isGuestCustomer
    />
  | None when shouldRenderDefaultCard || selectedPaymentMethod->Option.isNone =>
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
  | None =>
    React.null
  }
}
