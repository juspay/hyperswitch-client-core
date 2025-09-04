open ReactNative
open Style
open SuperpositionTypes
open ReactFinalForm

// Creates React-compatible synthetic events for ReactFinalForm integration
let createSyntheticEvent = (_value: string): ReactEvent.Form.t => {
  %raw(`{target: {value: _value}}`)
}



let renderFieldByType = (field: fieldConfig, input: ReactFinalForm.fieldRenderPropsInput, meta: ReactFinalForm.fieldRenderPropsMeta) => {
  switch field.fieldType {
  | TextInput =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
    />
  | EmailInput =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
      keyboardType=#"email-address"
    />
  | PasswordInput =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
      secureTextEntry={true}
    />
  | PhoneInput =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
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
  ~setConfirmButtonDataRef: React.element => unit,
  ~isScreenFocus: bool,
  // New wallet processing parameters
  ~hasMissingFields: option<bool>=?,
  ~walletPaymentMethodData: option<JSON.t>=?,
  ~onFormValuesChange: option<(JSON.t) => unit>=?,
) => {
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  
  let (error, setError) = React.useState(_ => None)
  
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
        let billingDataFromForm = formValues->JSON.Decode.object->Option.flatMap(obj => 
          obj->Dict.get("billing")->Option.flatMap(JSON.Decode.object)
        )->Option.getOr(Dict.make())
        
        let addressData = billingDataFromForm->Dict.get("address")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
        
        let cardPaymentMethodData = PaymentUtils.generatePaymentMethodData(
          ~prop,
          ~cardData,
          ~cardHolderName=None,
          ~nickname=None,
        )
        
        let payment_method_data = switch cardPaymentMethodData {
        | Some(cardData) => {
            let cardDataObj = cardData->JSON.Decode.object->Option.getOr(Dict.make())
            
            if billingDataFromForm->Dict.toArray->Array.length > 0 {
              let billingDataForPMD = [
                ("address", [
                  ("first_name", addressData->Dict.get("first_name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->JSON.Encode.string),
                  ("last_name", addressData->Dict.get("last_name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->JSON.Encode.string),
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
          ~isNicknameSelected=false,
          ~isSaveCardCheckboxVisible=false,
          ~isGuestCustomer=true, 
          (),
        )

        
        let dynamicFieldsArray = formValues->JSON.Decode.object
        ->Option.mapOr([], obj => 
          obj->Dict.toArray
          ->Array.filter(((key, _)) => key !== "card" && key !== "billing")
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
      onSubmit={(_, _) => Promise.resolve(Nullable.null)}
      initialValues
      render={formRenderProps => {
        let handlePress = _ => {
          setLoading(ProcessingPayments(None))
          // Check if this is a wallet scenario with hasMissingFields=false (direct payment)
          switch (hasMissingFields, _walletData, _walletType) {
          | (Some(false), Some(_), Some(_)) => processWalletPayment()
          | _ => processRequest(formRenderProps.values)
          }
        }

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
        
        React.useEffect3(() => {
          if isScreenFocus {
            setConfirmButtonDataRef(
              <ConfirmButton
                loading=false 
                isAllValuesValid={true}
                handlePress
                paymentMethod="CARD" 
                errorText=error
              />
            )
          }
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
                <CardFieldsComponent fields={fields} createSyntheticEvent={createSyntheticEvent} />
              </View>
            | "billing" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                <Space height=15. />
                  <TextWrapper text="Billing Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    validate={(_, _) => Promise.resolve(Nullable.null)}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
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
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
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
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
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
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
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
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
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
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
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
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
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
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
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
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
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
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
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
