open ReactNative
open Style
open SuperpositionTypes
open ReactFinalForm

// Creates React-compatible synthetic events for ReactFinalForm integration
let createSyntheticEvent = (_value: string): ReactEvent.Form.t => {
  %raw(`{target: {value: _value}}`)
}

let splitFullName = (fullName: string): (string, string) => {
  let trimmedName = fullName->String.trim
  if trimmedName === "" {
    ("", "")
  } else {
    let nameParts = trimmedName->String.split(" ")->Array.filter(part => part !== "")
    switch nameParts->Array.length {
    | 0 => ("", "")
    | 1 => (nameParts->Array.get(0)->Option.getOr(""), "")
    | _ => {
        let firstName = nameParts->Array.get(0)->Option.getOr("")
        let lastName = nameParts->Array.slice(~start=1, ~end=nameParts->Array.length)->Array.join(" ")
        (firstName, lastName)
      }
    }
  }
}

let validateField = (
  ~fieldType: SuperpositionTypes.fieldType,
  ~fieldName: string,
  ~value: string,
  ~meta: ReactFinalForm.fieldRenderPropsMeta,
  ~localeObject: LocaleDataType.localeStrings,
  ~forceValidation: bool=false,
): (bool, option<string>) => {
  // Don't show errors for fields that are currently active (focused)
  // This provides better UX after submit validation
  if meta.active {
    (true, None)
  } else {
    let shouldValidate = forceValidation || (meta.touched && !meta.active)
    
    if !shouldValidate {
      (true, None)
    } else {
      switch fieldType {
      | TextInput => {
          if value->String.trim === "" {
            (false, Some(localeObject.mandatoryFieldText))
          } else {
            if fieldName->String.endsWith("full_name") {
              let (firstName, lastName) = splitFullName(value)
              if firstName === "" {
                (false, Some(localeObject.cardHolderNameRequiredText))
              } else if lastName === "" {
                (false, Some(localeObject.lastNameRequiredText))
              } else if firstName->Validation.containsDigit || lastName->Validation.containsDigit {
                (false, Some(localeObject.invalidDigitsCardHolderNameError))
              } else {
                (true, None)
              }
            } else {
              (true, None)
            }
          }
        }
      | EmailInput => {
          if value->String.trim === "" {
            (false, Some(localeObject.emailEmptyText))
          } else {
            switch value->EmailValidation.isEmailValid {
            | Some(false) => (false, Some(localeObject.emailInvalidText))
            | Some(true) => (true, None)
            | None => (false, Some(localeObject.emailEmptyText))
            }
          }
        }
      | PasswordInput | PhoneInput => {
          if value->String.trim === "" {
            (false, Some(localeObject.mandatoryFieldText))
          } else {
            (true, None)
          }
        }
      | _ => (true, None) 
      }
    }
  }
}



let renderFieldByType = (field: fieldConfig, input: ReactFinalForm.fieldRenderPropsInput, meta: ReactFinalForm.fieldRenderPropsMeta) => {
  switch field.fieldType {
  | TextInput =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      onFocusRFF={input.onFocus}
      onBlurRFF={input.onBlur}
      placeholder={field.displayName}
      isValid={meta.valid}
    />
  | EmailInput =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      onFocusRFF={input.onFocus}
      onBlurRFF={input.onBlur}
      placeholder={field.displayName}
      isValid={meta.valid}
      keyboardType=#"email-address"
    />
  | PasswordInput =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      onFocusRFF={input.onFocus}
      onBlurRFF={input.onBlur}
      placeholder={field.displayName}
      isValid={meta.valid}
      secureTextEntry={true}
    />
  | PhoneInput =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      onFocusRFF={input.onFocus}
      onBlurRFF={input.onBlur}
      placeholder={field.displayName}
      isValid={meta.valid}
      keyboardType=#"phone-pad"
    />
  | CountrySelect =>
    <CustomPicker
      value={Some(input.value->JSON.Decode.string->Option.getOr(""))}
      setValue={_ => ()}
      onChange={input.onChange}
      items={field.options->Array.map(option => {
        CustomPicker.label: option,
        value: option,
        icon: Utils.getCountryFlags(option),
      })}
      placeholderText={field.displayName}
      isValid={meta.valid}
    />
  | CountryCodeSelect | DropdownSelect | CurrencySelect =>
    <CustomPicker
      value={Some(input.value->JSON.Decode.string->Option.getOr(""))}
      setValue={_ => ()}
      onChange={input.onChange}
      items={field.options->Array.map(option => {
        CustomPicker.label: option,
        value: option,
        icon: Utils.getCountryFlags(option),
      })}
      placeholderText={field.displayName}
      isValid={meta.valid}
    />
  | MonthSelect =>
    // For now, use text input for month selection - can be enhanced later with CustomPicker
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
      keyboardType=#"numeric"
    />
  | YearSelect =>
    // For now, use text input for year selection - can be enhanced later with CustomPicker
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
      keyboardType=#"numeric"
    />
  | DatePicker =>
    // For now, use text input for date picker - can be enhanced later
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
    />
  // | _ =>
  //   <CustomInput
  //     state={input.value->JSON.Decode.string->Option.getOr("")}
  //     setState={_ => ()}
  //     onChange={input.onChange}
  //     placeholder={field.displayName}
  //     isValid={meta.valid}
  //   />
  }
}

@react.component
let make = (
  ~componentWiseRequiredFields: array<(string, array<fieldConfig>)>,
  ~_walletData: option<PaymentScreenContext.walletData>=?,
  ~_walletType: option<PaymentMethodListType.payment_method_types_wallet>=?,
  // ~setConfirmButtonDataRef: React.element => unit,
  ~isScreenFocus: bool,
  // New wallet processing parameters
  ~hasMissingFields: option<bool>=?,
  ~walletPaymentMethodData: option<JSON.t>=?,
  ~onFormValuesChange: option<(JSON.t) => unit>=?,
  ~keyToTrigerButtonClickError: int,
  ~isNicknameSelected=false,
  ~nickname: option<string>=?,
  ~isSaveCardCheckboxVisible=false,
  ~isGuestCustomer=true,
) => {
  
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let localeObject = GetLocale.useGetLocalObj()
  
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  
  let (error, setError) = React.useState(_ => None)
  let (lastActiveField, setLastActiveField) = React.useState(_ => None)
  let (submitAttempted, setSubmitAttempted) = React.useState(_ => false)
  let (forceRender, setForceRender) = React.useState(_ => 0)
  
  let handleSetLastActiveField = (fieldName: string) => {
    setLastActiveField(_ => Some(fieldName))
  }
  
  // Watch for keyToTrigerButtonClickError changes and trigger form submission
  React.useEffect1(() => {
    if keyToTrigerButtonClickError > 0 {
      setSubmitAttempted(_ => true)
      setForceRender(prev => prev + 1)
    }
    None
  }, [keyToTrigerButtonClickError])
  
  // Function to validate all fields for submit validation
  let validateAllFields = (formValues: JSON.t) => {
    let validationErrors = []
    let allFieldsValid = ref(true)
    
    componentWiseRequiredFields->Array.forEach(((_, fields)) => {
      fields->Array.forEach(field => {
        let fieldValue = formValues
          ->JSON.Decode.object
          ->Option.flatMap(obj => {
            let pathParts = field.name->String.split(".")
            let rec getValue = (currentObj: Dict.t<JSON.t>, parts: array<string>, index: int) => {
              switch parts->Array.get(index) {
              | Some(key) => {
                  switch currentObj->Dict.get(key) {
                  | Some(value) => {
                      if index === parts->Array.length - 1 {
                        value->JSON.Decode.string
                      } else {
                        value->JSON.Decode.object->Option.flatMap(nestedObj => 
                          getValue(nestedObj, parts, index + 1)
                        )
                      }
                    }
                  | None => None
                  }
                }
              | None => None
              }
            }
            getValue(obj, pathParts, 0)
          })
          ->Option.getOr("")
        
        // Create a mock meta object for validation
        let mockMeta: ReactFinalForm.fieldRenderPropsMeta = {
          active: false,
          data: false,
          dirty: true,
          dirtySinceLastSubmit: false,
          error: Nullable.null,
          initial: false,
          invalid: false,
          modified: false,
          modifiedSinceLastSubmit: false,
          pristine: false,
          submitError: Nullable.null,
          submitFailed: false,
          submitSucceeded: false,
          submitting: false,
          touched: true,
          valid: true,
          validating: false,
          visited: false,
          value: fieldValue->JSON.Encode.string,
        }
        
        let (isValid, errorMessage) = validateField(
          ~fieldType=field.fieldType,
          ~fieldName=field.name,
          ~value=fieldValue,
          ~meta=mockMeta,
          ~localeObject,
          ~forceValidation=true,
        )
        
        if !isValid {
          allFieldsValid := false
          switch errorMessage {
          | Some(msg) => validationErrors->Array.push((field.name, msg))->ignore
          | None => ()
          }
        }
      })
    })
    
    (allFieldsValid.contents, validationErrors)
  }
  
  // Wallet processing function - handles direct payment when hasMissingFields=false
  let processWalletPayment = () => {
    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
      if !closeSDK {
        setLoading(FillingDetails)
        switch errorMessage.message {
        | Some(message) => setError(_ => Some(message))
        | None => ()
        }
      }
      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }
    
    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      switch paymentStatus {
      | PaymentSuccess => {
          setLoading(PaymentSuccess)
          setTimeout(() => {
            handleSuccessFailure(~apiResStatus=status, ())
          }, 300)->ignore
        }
      | _ => handleSuccessFailure(~apiResStatus=status, ())
      }
    }

    switch (walletPaymentMethodData, _walletType, _walletData) {
    | (Some(_), Some(walletType), Some(walletData)) => {
        // Find the wallet payment method from allApiData
        let walletPaymentMethod = allApiData.paymentList->Array.find(paymentMethod => {
          switch paymentMethod {
          | PaymentMethodListType.WALLET(prop) => prop.payment_method_type_wallet === walletType.payment_method_type_wallet
          | _ => false
          }
        })
        
        switch walletPaymentMethod {
        | Some(PaymentMethodListType.WALLET(prop)) => {
            // Extract token based on wallet type
            let token = switch walletData {
            | GooglePayData(gpayData) => 
              gpayData.paymentMethodData.tokenization_data
              ->Option.map(tokenData => tokenData.token)
              ->Option.getOr("")
            | ApplePayData(applePayData) => 
              applePayData.paymentData->JSON.stringify
            | SamsungPayData(_, _, _) => ""
            }
            
            let body = PaymentUtils.generateWalletConfirmBody(
              ~nativeProp,
              ~payment_token=token,
              ~payment_method_type=prop.payment_method_type,
            )
            
            fetchAndRedirect(
              ~body=body->JSON.stringifyAny->Option.getOr(""),
              ~publishableKey=nativeProp.publishableKey,
              ~clientSecret=nativeProp.clientSecret,
              ~errorCallback,
              ~responseCallback,
              ~paymentMethod=prop.payment_method_type,
              ~isCardPayment=false,
              (),
            )
          }
        | _ => {
            errorCallback(~errorMessage={PaymentConfirmTypes.message: "Wallet payment method not available"}, ~closeSDK=false, ())
          }
        }
      }
    | _ => {
        errorCallback(~errorMessage={PaymentConfirmTypes.message: "Wallet data not available"}, ~closeSDK=false, ())
      }
    }
  }
  
  let processRequest = (formValues: JSON.t) => {
    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
      if !closeSDK {
        setLoading(FillingDetails)
        switch errorMessage.message {
        | Some(message) => setError(_ => Some(message))
        | None => ()
        }
      }
      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }
    
    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      switch paymentStatus {
      | PaymentSuccess => {
          setLoading(PaymentSuccess)
          setTimeout(() => {
            handleSuccessFailure(~apiResStatus=status, ())
          }, 300)->ignore
        }
      | _ => handleSuccessFailure(~apiResStatus=status, ())
      }
    }

    // Convert react-final-form values to cardData format expected by existing utilities
    let cardDataFromForm = formValues->JSON.Decode.object->Option.flatMap(obj => 
      obj->Dict.get("card")->Option.flatMap(JSON.Decode.object)
    )->Option.getOr(Dict.make())
    
    let cardNumber = cardDataFromForm->Dict.get("card_number")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
    let expiry = cardDataFromForm->Dict.get("card_exp_month")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
    let cvv = cardDataFromForm->Dict.get("card_cvc")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
    
    let cardBrand = Validation.getCardBrand(cardNumber)
    let cardData: CardDataContext.cardData = {
      cardNumber: cardNumber,
      expireDate: expiry,
      cvv: cvv,
      zip: "", 
      isCardNumberValid: None,
      isCardBrandSupported: None,
      isExpireDataValid: None,
      isCvvValid: None,
      isZipValid: None,
      cardBrand: cardBrand,
      selectedCoBadgedCardBrand: None,
    }
    
    let cardPaymentMethod = allApiData.paymentList->Array.find(paymentMethod => {
      switch paymentMethod {
      | PaymentMethodListType.CARD(_) => true
      | _ => false
      }
    })
    
    switch cardPaymentMethod {
    | Some(PaymentMethodListType.CARD(prop)) => {
        
        let billingDataForPayment = switch hasMissingFields {
        | Some(true) => {
            let billingDataFromForm = formValues->JSON.Decode.object->Option.flatMap(obj => 
              obj->Dict.get("billing")->Option.flatMap(JSON.Decode.object)
            )->Option.getOr(Dict.make())
            billingDataFromForm
          }
        | Some(false) => {
            let pmlBillingData = {
              switch formValues->JSON.Decode.object {
              | Some(formObj) => {
                  switch formObj->Dict.get("billing") {
                  | Some(billingObj) => 
                      billingObj->JSON.Decode.object->Option.getOr(Dict.make())
                  | None => 
                      Dict.make()
                  }
                }
              | None => 
                  Dict.make()
              }
            }
            pmlBillingData
          }
        | None => {
            let billingDataFromForm = formValues->JSON.Decode.object->Option.flatMap(obj => 
              obj->Dict.get("billing")->Option.flatMap(JSON.Decode.object)
            )->Option.getOr(Dict.make())
            billingDataFromForm
          }
        }
        
        let addressData = billingDataForPayment->Dict.get("address")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
        
        let cardPaymentMethodData = PaymentUtils.generatePaymentMethodData(
          ~prop,
          ~cardData,
          ~cardHolderName=None,
          ~nickname=isNicknameSelected ? nickname : None,
        )
        
        let payment_method_data = switch cardPaymentMethodData {
        | Some(cardData) => {
            let cardDataObj = cardData->JSON.Decode.object->Option.getOr(Dict.make())
            
            if billingDataForPayment->Dict.toArray->Array.length > 0 {
              let (firstName, lastName) = {
                let directFirstName = addressData->Dict.get("first_name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
                let directLastName = addressData->Dict.get("last_name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
                let fullName = addressData->Dict.get("full_name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
                
                if directFirstName !== "" || directLastName !== "" {
                  (directFirstName, directLastName)
                } else if fullName !== "" {
                  splitFullName(fullName)
                } else {
                  ("", "")
                }
              }
              
              let billingDataForPMD = [
                ("email", billingDataForPayment->Dict.get("email")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->JSON.Encode.string),
                ("address", [
                  ("first_name", firstName->JSON.Encode.string),
                  ("last_name", lastName->JSON.Encode.string),
                  ("city", addressData->Dict.get("city")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->JSON.Encode.string),
                  ("country", addressData->Dict.get("country")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->JSON.Encode.string),
                  ("line1", addressData->Dict.get("line1")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->JSON.Encode.string),
                  ("zip", addressData->Dict.get("zip")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->JSON.Encode.string),
                ]->Dict.fromArray->JSON.Encode.object)
              ]->Dict.fromArray->JSON.Encode.object
              
              cardDataObj->Dict.set("billing", billingDataForPMD)
              Some(cardDataObj->JSON.Encode.object)
            } else {
              Some(cardData)
            }
          }
        | None => None
        }

        let body = PaymentUtils.generateCardConfirmBody(
          ~nativeProp,
          ~prop,
          ~payment_method_data=payment_method_data->Option.getOr(JSON.Encode.null),
          ~allApiData,
          ~isNicknameSelected,
          ~isSaveCardCheckboxVisible,
          ~isGuestCustomer,
          (),
        )

        
        // When hasMissingFields=false, exclude billing data to avoid duplication
        // since billing data is already included in payment_method_data
let dynamicFieldsArray = formValues->JSON.Decode.object
->Option.mapOr([], obj => 
  obj->Dict.toArray
  ->Array.filter(((key, _)) => {
    key !== "card" && 
    (hasMissingFields === Some(true) || key !== "billing") // Exclude billing when hasMissingFields=false
  })
  ->Array.map(((key, value)) => (key, value, None))
)
        
        let paymentBodyWithDynamicFields = PaymentMethodListType.getPaymentBody(
          body,
          dynamicFieldsArray,
        )
        
        fetchAndRedirect(
          ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
          ~publishableKey=nativeProp.publishableKey,
          ~clientSecret=nativeProp.clientSecret,
          ~errorCallback,
          ~responseCallback,
          ~paymentMethod=prop.payment_method_type,
          ~isCardPayment=true,
          (),
        )
      }
    | _ => {
        errorCallback(~errorMessage={PaymentConfirmTypes.message: "Card payment method not available"}, ~closeSDK=false, ())
      }
    }
  }

  let setNestedValue = (obj: Dict.t<JSON.t>, path: string, value: JSON.t) => {
    let pathParts = path->String.split(".")
    let rec setNested = (currentObj: Dict.t<JSON.t>, parts: array<string>, index: int) => {
      switch parts->Array.get(index) {
      | Some(key) => {
          if index === parts->Array.length - 1 {
            currentObj->Dict.set(key, value)
          } else {
            let nested = switch currentObj->Dict.get(key) {
            | Some(existingObj) => existingObj->JSON.Decode.object->Option.getOr(Dict.make())
            | None => {
                let newDict = Dict.make()
                currentObj->Dict.set(key, newDict->JSON.Encode.object)
                newDict
              }
            }
            setNested(nested, parts, index + 1)
            currentObj->Dict.set(key, nested->JSON.Encode.object)
          }
        }
      | None => ()
      }
    }
    setNested(obj, pathParts, 0)
  }

  let createInitialValues = (componentWiseFields: array<(string, array<fieldConfig>)>) => {
    let initialValues = Dict.make()
    
    componentWiseFields->Array.forEach(((_, fields)) => {
      fields->Array.forEach(field => {
        if field.defaultValue !== "" {
          setNestedValue(initialValues, field.name, field.defaultValue->JSON.Encode.string)
        }
      })
    })
    
    initialValues->JSON.Encode.object
  }
  
  let initialValues = React.useMemo1(() => {
    createInitialValues(componentWiseRequiredFields)
  }, [componentWiseRequiredFields])

  <View style={Style.empty}>
    <ReactFinalForm.Form
      onSubmit={(formValues, _) => {
        let (allValid, _validationErrors) = validateAllFields(formValues)
        
        if !allValid {
          setSubmitAttempted(_ => true)
          setForceRender(prev => prev + 1)
          Promise.resolve(Nullable.null)
        } else {
          setLoading(ProcessingPayments(None))
          switch (hasMissingFields, _walletData, _walletType) {
          | (Some(false), Some(_), Some(_)) => processWalletPayment()
          | _ => processRequest(formValues)
          }
          Promise.resolve(Nullable.null)
        }
      }}
      initialValues
      render={formRenderProps => {
        // Store form submit function in a ref so we can call it from useEffect
        let formSubmitRef = React.useRef(formRenderProps.handleSubmit)
        formSubmitRef.current = formRenderProps.handleSubmit
        
        // Trigger form submission when keyToTrigerButtonClickError changes
        React.useEffect1(() => {
          if keyToTrigerButtonClickError > 0 {
            let syntheticEvent = createSyntheticEvent("")
            formSubmitRef.current(syntheticEvent)
          }
          None
        }, [keyToTrigerButtonClickError])
        // let handlePress = (_: ReactNative.Event.pressEvent) => {
        //   // Create a synthetic form event and trigger form submission
        //   let syntheticEvent = createSyntheticEvent("")
        //   formRenderProps.handleSubmit(syntheticEvent)
        // }

        // Notify parent of form values changes (using useMemo to avoid infinite loops)
        let formValuesJson = React.useMemo1(() => {
          formRenderProps.values->JSON.stringifyAny
        }, [formRenderProps.values])
        
        React.useEffect2(() => {
          switch onFormValuesChange {
          | Some(callback) => callback(formRenderProps.values)
          | None => ()
          }
          None
        }, (formValuesJson, onFormValuesChange))
        
        // Don't set up button when used within Card.res - Card.res handles the button
        // DynamicFieldsSuperposition only sets up button for standalone usage
        React.useEffect3(() => {
        //   // Only set up button if we're not being used within Card.res
        //   // Card.res will handle button setup and trigger form submission via keyToTrigerButtonClickError
        //   //  if isScreenFocus {
        //   //   Console.log("DynamicFieldsSuperposition: Setting confirm button with handlePress function")
        //   //   Console.log2("DynamicFieldsSuperposition: Form values:", formRenderProps.values)
        //   //   setConfirmButtonDataRef(
        //   //     <ConfirmButton
        //   //       loading=false 
        //   //       isAllValuesValid={true}
        //   //       handlePress
        //   //       paymentMethod="CARD" 
        //   //       errorText=error
        //   //     />
        //   //   )
        //   // }
          None
        }, (formRenderProps.values, isScreenFocus, error))

        <View>
          {error->Option.isSome ? <ErrorText text={error} /> : React.null}
          {componentWiseRequiredFields
          ->Array.mapWithIndex((componentWithField, index) => {
            let (componentName, fields) = componentWithField
            switch componentName {
            | "card" =>
              <View key={index->Int.toString}>
                <CardFieldsComponent fields={fields} createSyntheticEvent={createSyntheticEvent} lastActiveRef=?{lastActiveField} setLastActiveRef=?{Some(handleSetLastActiveField)} submitAttempted={submitAttempted} />
              </View>
            | "billing" =>
              // Only render billing fields if there are missing fields (hasMissingFields = true)
              // When hasMissingFields = false, PML data is complete and no fields should be rendered
              switch hasMissingFields {
              | Some(true) =>
                  <View key={index->Int.toString}>
                    <View style={Style.s({marginBottom: 12.->Style.dp})}>
                    <Space height=15. />
                      <TextWrapper text="Billing Details" textType=ModalText />
                    </View>
                    {fields
                    // Filter out email fields from billing section UI rendering, but keep them in form data
                    ->Array.filter(field => field.fieldType !== SuperpositionTypes.EmailInput)
                    ->Array.mapWithIndex((field, fieldIndex) => {
                      <ReactFinalForm.Field 
                        name={field.name} 
                        key={fieldIndex->Int.toString}
                        render={({input, meta}) => {
                          // Use unified validation function - include forceRender to trigger re-render
                          let _ = forceRender
                          let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                          let (isValid, errorMessage) = validateField(
                            ~fieldType=field.fieldType,
                            ~fieldName=field.name,
                            ~value=fieldValue,
                            ~meta,
                            ~localeObject,
                            ~forceValidation=submitAttempted,
                          )
                          
                          <View style={Style.s({marginVertical: 8.->Style.dp})}>
                            <Space height=5. />
                            {renderFieldByType(field, input, {
                              ...meta,
                              valid: isValid,
                            })}
                            {errorMessage->Option.isSome ? 
                              <ErrorText text={errorMessage} /> : React.null}
                          </View>
                        }}
                      />
                    })
                    ->React.array}
                  </View>
              | Some(false) | None =>
                  // When hasMissingFields = false or None, don't render billing fields
                  // PML data is complete and will be used directly
                  React.null
              }
            | "shipping" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Shipping Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) => {
                      let _ = forceRender
                      let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                      let (isValid, errorMessage) = validateField(
                        ~fieldType=field.fieldType,
                        ~fieldName=field.name,
                        ~value=fieldValue,
                        ~meta,
                        ~localeObject,
                        ~forceValidation=submitAttempted,
                      )
                      
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, {
                          ...meta,
                          valid: isValid,
                        })}
                        {errorMessage->Option.isSome ? 
                          <ErrorText text={errorMessage} /> : React.null}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | "bank" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Bank Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) => {
                      let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                      let (isValid, errorMessage) = validateField(
                        ~fieldType=field.fieldType,
                        ~fieldName=field.name,
                        ~value=fieldValue,
                        ~meta,
                        ~localeObject,
                        ~forceValidation=submitAttempted,
                      )
                      
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, {
                          ...meta,
                          valid: isValid,
                        })}
                        {errorMessage->Option.isSome ? 
                          <ErrorText text={errorMessage} /> : React.null}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | "wallet" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Wallet Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) => {
                      let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                      let (isValid, errorMessage) = validateField(
                        ~fieldType=field.fieldType,
                        ~fieldName=field.name,
                        ~value=fieldValue,
                        ~meta,
                        ~localeObject,
                        ~forceValidation=submitAttempted,
                      )
                      
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, {
                          ...meta,
                          valid: isValid,
                        })}
                        {errorMessage->Option.isSome ? 
                          <ErrorText text={errorMessage} /> : React.null}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | "crypto" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Crypto Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) => {
                      let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                      let (isValid, errorMessage) = validateField(
                        ~fieldType=field.fieldType,
                        ~fieldName=field.name,
                        ~value=fieldValue,
                        ~meta,
                        ~localeObject,
                        ~forceValidation=submitAttempted,
                      )
                      
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, {
                          ...meta,
                          valid: isValid,
                        })}
                        {errorMessage->Option.isSome ? 
                          <ErrorText text={errorMessage} /> : React.null}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | "upi" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="UPI Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) => {
                      let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                      let (isValid, errorMessage) = validateField(
                        ~fieldType=field.fieldType,
                        ~fieldName=field.name,
                        ~value=fieldValue,
                        ~meta,
                        ~localeObject,
                        ~forceValidation=submitAttempted,
                      )
                      
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, {
                          ...meta,
                          valid: isValid,
                        })}
                        {errorMessage->Option.isSome ? 
                          <ErrorText text={errorMessage} /> : React.null}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | "voucher" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Voucher Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) => {
                      let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                      let (isValid, errorMessage) = validateField(
                        ~fieldType=field.fieldType,
                        ~fieldName=field.name,
                        ~value=fieldValue,
                        ~meta,
                        ~localeObject,
                        ~forceValidation=submitAttempted,
                      )
                      
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, {
                          ...meta,
                          valid: isValid,
                        })}
                        {errorMessage->Option.isSome ? 
                          <ErrorText text={errorMessage} /> : React.null}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | "gift_card" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Gift Card Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) => {
                      let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                      let (isValid, errorMessage) = validateField(
                        ~fieldType=field.fieldType,
                        ~fieldName=field.name,
                        ~value=fieldValue,
                        ~meta,
                        ~localeObject,
                        ~forceValidation=submitAttempted,
                      )
                      
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, {
                          ...meta,
                          valid: isValid,
                        })}
                        {errorMessage->Option.isSome ? 
                          <ErrorText text={errorMessage} /> : React.null}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | "mobile_payment" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Mobile Payment Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) => {
                      let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                      let (isValid, errorMessage) = validateField(
                        ~fieldType=field.fieldType,
                        ~fieldName=field.name,
                        ~value=fieldValue,
                        ~meta,
                        ~localeObject,
                        ~forceValidation=submitAttempted,
                      )
                      
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, {
                          ...meta,
                          valid: isValid,
                        })}
                        {errorMessage->Option.isSome ? 
                          <ErrorText text={errorMessage} /> : React.null}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | "other" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Other Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) => {
                      let fieldValue = input.value->JSON.Decode.string->Option.getOr("")
                      let (isValid, errorMessage) = validateField(
                        ~fieldType=field.fieldType,
                        ~fieldName=field.name,
                        ~value=fieldValue,
                        ~meta,
                        ~localeObject,
                        ~forceValidation=submitAttempted,
                      )
                      
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, {
                          ...meta,
                          valid: isValid,
                        })}
                        {errorMessage->Option.isSome ? 
                          <ErrorText text={errorMessage} /> : React.null}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | _ =>
              <View key={index->Int.toString}>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <View key={fieldIndex->Int.toString} style={Style.s({marginVertical: 4.->Style.dp})}>
                    <TextWrapper text={field.displayName} textType=ModalText />
                  </View>
                })
                ->React.array}
              </View>
            }
          })
          ->React.array}
        </View>
      }}
    />
  </View>
}
