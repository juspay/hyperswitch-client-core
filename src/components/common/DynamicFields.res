open ReactNative
open Style
open RequiredFieldsTypes

let updateDictImmutable = (dict, key, value) => {
  let newDict = Dict.fromArray(dict->Dict.toArray)
  newDict->Dict.set(key, value)
  newDict
}

let updateMultipleDictEntries = (dict, entries) => {
  let newDict = Dict.fromArray(dict->Dict.toArray)
  entries->Array.forEach(((key, value)) => {
    newDict->Dict.set(key, value)
  })
  newDict
}

let getFieldValueOptimized = (finalJsonDict, requiredField) => {
  switch requiredField {
  | StringField(x) | EmailField(x) =>
    finalJsonDict
    ->Dict.get(x)
    ->Option.map(((value, _)) => value->JSON.Decode.string->Option.getOr(""))
    ->Option.getOr("")
  | FullNameField(firstName, lastName) =>
    let firstNameValue = finalJsonDict->Dict.get(firstName)
    let lastNameValue = finalJsonDict->Dict.get(lastName)
    
    switch (firstNameValue, lastNameValue) {
    | (Some((firstVal, _)), Some((lastVal, _))) => {
        let first = firstVal->JSON.Decode.string->Option.getOr("")
        let last = lastVal->JSON.Decode.string->Option.getOr("")
        switch (first, last) {
        | ("", "") => ""
        | (f, "") => f
        | ("", l) => l
        | (f, l) => f ++ " " ++ l
        }
      }
    | (Some((firstVal, _)), None) => firstVal->JSON.Decode.string->Option.getOr("")
    | (None, Some((lastVal, _))) => lastVal->JSON.Decode.string->Option.getOr("")
    | _ => ""
    }
  | PhoneField(phoneCode, phoneNumber) =>
    let phoneCodeValue = finalJsonDict->Dict.get(phoneCode)->Option.flatMap(((value, _)) => value->JSON.Decode.string)
    let phoneNumberValue = finalJsonDict->Dict.get(phoneNumber)->Option.flatMap(((value, _)) => value->JSON.Decode.string)
    phoneCodeValue->Option.getOr("") ++ " " ++ phoneNumberValue->Option.getOr("")
  }
}

let processCountryData = (countryArr, contextCountryData) => {
  contextCountryData
  ->Array.filter((item: CountryStateDataHookTypes.country) => countryArr->Array.includes(item.isoAlpha2))
  ->Array.map((item: CountryStateDataHookTypes.country): CustomPicker.customPickerType => {
    {
      label: item.label != "" ? item.label ++ " - " ++ item.value : item.value,
      value: item.isoAlpha2,
      icon: Utils.getCountryFlags(item.isoAlpha2),
    }
  })
}

let processStateData = (states, country) => {
  states
  ->Utils.getStateNames(country)
  ->Array.map((item): CustomPicker.customPickerType => {
    {
      label: item.label != "" ? item.label ++ " - " ++ item.value : item.value,
      value: item.code,
    }
  })
}

module OptimizedRenderField = {
  @react.component
  let make = React.memo((
    ~required_fields_type: RequiredFieldsTypes.required_fields_type,
    ~setFinalJsonDict,
    ~finalJsonDict,
    ~isSaveCardsFlow,
    ~statesAndCountry: CountryStateDataContext.data,
    ~keyToTrigerButtonClickError,
    ~paymentMethodType: option<RequiredFieldsTypes.payment_method_types_in_bank_debit>,
    ~countryCodes,
  ) => {
    let localeObject = GetLocale.useGetLocalObj()
    let {component, dangerColor, borderWidth, borderRadius} = ThemebasedStyle.useThemeBasedStyle()

    let value = getFieldValueOptimized(finalJsonDict, required_fields_type.required_field)
    let initialValue = value === "" ? None : Some(value)
    
    let (val, setVal) = React.useState(_ => initialValue)
    let (errorMessage, setErrorMessage) = React.useState(_ => None)
    let (isFocus, setIsFocus) = React.useState(_ => false)

    let placeholder = RequiredFieldsTypes.useGetPlaceholder(
      ~field_type=required_fields_type.field_type,
      ~display_name=required_fields_type.display_name,
      ~required_field=required_fields_type.required_field,
    )()

    let isValid = React.useMemo1(() => errorMessage->Option.isNone, [errorMessage])
    let isValidForFocus = React.useMemo2(() => isFocus || isValid, (isFocus, isValid))

    let countryItems = React.useMemo2(() => {
      switch required_fields_type.field_type {
      | AddressCountry(countryArr) =>
        switch statesAndCountry {
        | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
          let countries = switch countryArr {
          | UseContextData => res.countries->Array.map(item => item.isoAlpha2)
          | UseBackEndData(data) => data
          }
          processCountryData(countries, res.countries)
        | _ => []
        }
      | _ => []
      }
    }, (required_fields_type.field_type, statesAndCountry))

    let stateItems = React.useMemo2(() => {
      switch required_fields_type.field_type {
      | AddressState =>
        switch statesAndCountry {
        | FetchData(statesAndCountryVal) | Localdata(statesAndCountryVal) =>
          let country = switch required_fields_type.required_field {
          | StringField(x) => 
            finalJsonDict
            ->Dict.get(getKey(x, "country"))
            ->Option.map(((value, _)) => value->JSON.Decode.string->Option.getOr(""))
            ->Option.getOr("")
          | _ => ""
          }
          processStateData(statesAndCountryVal.states, country)
        | _ => []
        }
      | _ => []
      }
    }, (required_fields_type.field_type, finalJsonDict))

    let isLoading = React.useMemo1(() => {
      switch statesAndCountry {
      | Loading => true
      | _ => false
      }
    }, [statesAndCountry])

    let validateAndUpdate = React.useCallback1((newValue) => {
      let requiredFieldPath = RequiredFieldsTypes.getRequiredFieldPath(
        ~isSaveCardsFlow,
        ~requiredField=required_fields_type,
      )
      
      switch requiredFieldPath {
      | StringField(stringFieldPath) | EmailField(stringFieldPath) =>
        let validationErrMsg = RequiredFieldsTypes.checkIsValid(
          ~text=newValue,
          ~field_type=required_fields_type.field_type,
          ~localeObject,
          ~display_name=required_fields_type.display_name,
          ~paymentMethodType,
        )
        let isCountryField = switch required_fields_type.field_type {
        | AddressCountry(_) => true
        | _ => false
        }

        setErrorMessage(_ => validationErrMsg)
        setFinalJsonDict(prev => {
          let newData = updateDictImmutable(prev, stringFieldPath, (newValue->JSON.Encode.string, validationErrMsg))
          if isCountryField {
            let stateKey = getKey(stringFieldPath, "state")
            switch prev->Dict.get(stateKey) {
            | Some(_) => updateDictImmutable(newData, stateKey, (JSON.Encode.null, Some("required")))
            | None => newData
            }
          } else {
            newData
          }
        })
        
      | FullNameField(firstNameFieldPath, lastNameFieldPath) =>
        let arr = newValue->String.split(" ")
        let firstNameVal = arr->Array.get(0)->Option.getOr("")
        let lastNameVal = arr->Array.filterWithIndex((_, index) => index !== 0)->Array.join(" ")
        let isBillingFields = required_fields_type.field_type === BillingName || required_fields_type.field_type === ShippingName
        
        let (firstNameVal, firstNameErrorMessage) =
          firstNameVal === ""
            ? (JSON.Encode.null, isBillingFields ? Some(localeObject.mandatoryFieldText) : Some(localeObject.cardHolderNameRequiredText))
            : (JSON.Encode.string(firstNameVal), firstNameVal->Validation.containsDigit ? Some(localeObject.invalidDigitsCardHolderNameError) : None)
            
        let (lastNameVal, lastNameErrorMessage) =
          lastNameVal === ""
            ? (JSON.Encode.null, Some(localeObject.lastNameRequiredText))
            : (JSON.Encode.string(lastNameVal), lastNameVal->Validation.containsDigit ? Some(localeObject.invalidDigitsCardHolderNameError) : None)

        setErrorMessage(_ =>
          switch firstNameErrorMessage {
          | Some(_) => firstNameErrorMessage
          | None => lastNameErrorMessage
          }
        )

        setFinalJsonDict(prev => {
          updateMultipleDictEntries(prev, [
            (firstNameFieldPath, (firstNameVal, firstNameErrorMessage)),
            (lastNameFieldPath, (lastNameVal, lastNameErrorMessage))
          ])
        })

      | PhoneField(phoneCodePath, phoneNumberPath) =>
        let phoneCodeVal = newValue->RequiredFieldsTypes.getFirstValue->JSON.Encode.string
        let phoneNumberVal = newValue->RequiredFieldsTypes.getLastValue

        let errorMessage = RequiredFieldsTypes.checkIsValid(
          ~text=phoneNumberVal,
          ~field_type=required_fields_type.field_type,
          ~localeObject,
          ~display_name=required_fields_type.display_name,
          ~paymentMethodType,
        )
        setErrorMessage(_ => errorMessage)
        setFinalJsonDict(prev => {
          updateMultipleDictEntries(prev, [
            (phoneCodePath, (phoneCodeVal, None)),
            (phoneNumberPath, (phoneNumberVal->JSON.Encode.string, errorMessage))
          ])
        })
      }
    }, [setFinalJsonDict])

    let onChange = React.useCallback1((text) => {
      let processedText = RequiredFieldsTypes.allowOnlyDigits(
        ~text=Some(text),
        ~fieldType=required_fields_type.field_type,
        ~prev=val,
        ~paymentMethodType,
      )
      setVal(_ => processedText)
    }, [setVal])

    let onChangeCountry = React.useCallback1((func) => {
      setVal(func)
    }, [setVal])

    let onChangePhone = React.useCallback1((text) => {
      setVal(prev => Some(
        prev->Option.getOr("")->RequiredFieldsTypes.getFirstValue ++
        " " ++
        RequiredFieldsTypes.allowOnlyDigits(
          ~text=Some(text),
          ~fieldType=required_fields_type.field_type,
          ~prev,
          ~paymentMethodType,
        )->Option.getOr(""),
      ))
    }, [setVal])

    let onChangePhoneCode = React.useCallback1((value) => {
      setVal(prev => Some(
        value(prev)->Option.getOr("") ++
        " " ++
        prev->Option.getOr("")->RequiredFieldsTypes.getLastValue,
      ))
    }, [setVal])

    let onFocus = React.useCallback0(() => {
      setIsFocus(_ => true)
    })

    let onBlur = React.useCallback0(() => {
      setIsFocus(_ => false)
    })

    React.useEffect1(() => {
      switch val {
      | Some(text) => validateAndUpdate(text)
      | None => ()
      }
      None
    }, [val])

    React.useEffect2(() => {
      if !isFocus {
        setVal(_ => initialValue)
      }
      None
    }, (initialValue, isFocus))

    React.useEffect1(() => {
      keyToTrigerButtonClickError != 0
        ? setVal(prev => prev->Option.isNone ? Some("") : prev)
        : ()
      None
    }, [keyToTrigerButtonClickError])

    <>
      {switch required_fields_type.required_field {
      | StringField(_) | EmailField(_) | FullNameField(_, _) =>
        switch required_fields_type.field_type {
        | AddressCountry(_) =>
          <CustomPicker
            value=val
            setValue=onChangeCountry
            isCountryStateFields=true
            borderBottomLeftRadius=borderRadius
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            items=countryItems
            placeholderText=placeholder
            isValid
            isLoading
          />
        | AddressState =>
          <CustomPicker
            value=val
            isCountryStateFields=true
            setValue=onChangeCountry
            borderBottomLeftRadius=borderRadius
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            items=stateItems
            placeholderText=placeholder
            isValid
            isLoading
          />
        | _ =>
          <CustomInput
            state={val->Option.getOr("")}
            setState=onChange
            placeholder
            keyboardType={RequiredFieldsTypes.getKeyboardType(~field_type=required_fields_type.field_type)}
            enableCrossIcon=false
            isValid=isValidForFocus
            onFocus={_ => onFocus()}
            onBlur={_ => onBlur()}
            textColor={isFocus || isValid ? component.color : dangerColor}
            borderTopLeftRadius=borderRadius
            borderTopRightRadius=borderRadius
            borderBottomWidth=borderWidth
            borderLeftWidth=borderWidth
            borderRightWidth=borderWidth
            borderTopWidth=borderWidth
          />
        }
      | PhoneField(_, _) =>
        <View
          style={s({
            display: #flex,
            flexDirection: #row,
            justifyContent: #"space-between",
            gap: 8.->dp,
          })}>
          <CustomPicker
            value={Some(val->Option.getOr("")->RequiredFieldsTypes.getFirstValue)}
            setValue=onChangePhoneCode
            borderBottomLeftRadius=borderRadius
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            items=countryCodes
            placeholderText="Code"
            isValid
            isLoading
            showValue=true
            style={s({flex: 1.})}
            isCountryStateFields=true
          />
          <CustomInput
            state={val->Option.getOr("")->RequiredFieldsTypes.getLastValue}
            setState=onChangePhone
            placeholder
            keyboardType={RequiredFieldsTypes.getKeyboardType(~field_type=required_fields_type.field_type)}
            enableCrossIcon=false
            isValid=isValidForFocus
            onFocus={_ => onFocus()}
            onBlur={_ => onBlur()}
            textColor={isFocus || isValid ? component.color : dangerColor}
            borderTopLeftRadius=borderRadius
            borderTopRightRadius=borderRadius
            borderBottomWidth=borderWidth
            borderLeftWidth=borderWidth
            borderRightWidth=borderWidth
            borderTopWidth=borderWidth
            style={s({flex: 3.})}
          />
        </View>
      }}
      {if isFocus {
        React.null
      } else {
        <ErrorText text=errorMessage />
      }}
    </>
  })
}

module OptimizedFields = {
  @react.component
  let make = React.memo((
    ~fields: array<RequiredFieldsTypes.required_fields_type>,
    ~finalJsonDict,
    ~setFinalJsonDict,
    ~isSaveCardsFlow,
    ~statesAndCountry: CountryStateDataContext.data,
    ~keyToTrigerButtonClickError,
    ~paymentMethodType,
    ~countryCodes,
  ) => {
    let renderedFields = React.useMemo1(() => {
      fields
      ->Array.mapWithIndex((item, index) =>
        <React.Fragment key={index->Int.toString}>
          {index == 0 ? React.null : <Space height=18. />}
          <OptimizedRenderField
            required_fields_type=item
            key={index->Int.toString}
            isSaveCardsFlow
            statesAndCountry
            finalJsonDict
            setFinalJsonDict
            keyToTrigerButtonClickError
            paymentMethodType
            countryCodes
          />
        </React.Fragment>
      )
      ->React.array
    }, [fields])

    renderedFields
  })
}

type fieldType = Other | Billing | Shipping

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
  ~fieldsOrder: array<fieldType>=[Other, Billing, Shipping],
) => {
  let clientTimeZone = Intl.DateTimeFormat.resolvedOptions(Intl.DateTimeFormat.make()).timeZone
  let (statesAndCountry, _) = React.useContext(CountryStateDataContext.countryStateDataContext)

  let clientCountry = React.useMemo1(() => {
    Utils.getClientCountry(
      switch statesAndCountry {
      | FetchData(data) | Localdata(data) => data.countries
      | _ => []
      },
      clientTimeZone,
    )
  }, [statesAndCountry])

  let initialKeysValDict = React.useMemo7(() => {
    switch statesAndCountry {
    | FetchData(statesAndCountryData) | Localdata(statesAndCountryData) =>
      requiredFields
      ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
      ->RequiredFieldsTypes.filterRequiredFieldsForShipping(shouldRenderShippingFields)
      ->RequiredFieldsTypes.getKeysValArray(
        isSaveCardsFlow,
        clientCountry.isoAlpha2,
        statesAndCountryData.countries->Array.map(item => {item.isoAlpha2}),
        statesAndCountryData.phoneCountryCodes,
      )
    | _ =>
      requiredFields
      ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
      ->RequiredFieldsTypes.filterRequiredFieldsForShipping(shouldRenderShippingFields)
      ->RequiredFieldsTypes.getKeysValArray(isSaveCardsFlow, clientCountry.isoAlpha2, [], [])
    }
  }, (
    requiredFields,
    isSaveCardsFlow,
    savedCardsData,
    clientCountry.isoAlpha2,
    shouldRenderShippingFields,
    statesAndCountry,
    displayPreValueFields,
  ))

  let filteredFields = React.useMemo6(() => {
    let fields = displayPreValueFields
      ? requiredFields
      : requiredFields->RequiredFieldsTypes.filterDynamicFieldsFromRendering(initialKeysValDict)
    
    fields
    ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
    ->RequiredFieldsTypes.filterRequiredFieldsForShipping(shouldRenderShippingFields)
  }, (
    requiredFields,
    isSaveCardsFlow,
    savedCardsData,
    shouldRenderShippingFields,
    displayPreValueFields,
    initialKeysValDict,
  ))

  let fields = React.useMemo2(() => {
    let getOrderValue = field => {
      let path = field.required_field->RequiredFieldsTypes.getRequiredFieldName->String.split(".")
      let x = if path->Array.includes("billing") {
        Billing
      } else if path->Array.includes("shipping") {
        Shipping
      } else {
        Other
      }
      fieldsOrder->Array.indexOf(x)
    }

    filteredFields->Array.sort((a, b) => {
      let aPath = getOrderValue(a)
      let bPath = getOrderValue(b)
      float(aPath - bPath)
    })
    filteredFields
  }, (filteredFields, fieldsOrder))

  let mappedCountryCodes = React.useMemo1(() => {
    switch statesAndCountry {
    | FetchData(statesAndCountry) | Localdata(statesAndCountry) =>
      statesAndCountry.phoneCountryCodes->Array.map((countryCode): CustomPicker.customPickerType => {
        label: countryCode.country_name ++ " " ++ countryCode.phone_number_code,
        value: countryCode.phone_number_code,
        icon: Utils.getCountryFlags(countryCode.country_code),
      })
    | Loading => []
    }
  }, [statesAndCountry])

  let (finalJsonDict, setFinalJsonDict) = React.useState(_ => initialKeysValDict)

  React.useEffect1(() => {
    let isAllValid =
      finalJsonDict
      ->Dict.toArray
      ->Array.reduce(true, (isValid, (_, (_, errorMessage))) => {
        isValid && errorMessage->Option.isNone
      })

    setIsAllDynamicFieldValid(_ => isAllValid)
    setDynamicFieldsJson(_ => finalJsonDict)
    None
  }, [finalJsonDict])

  React.useEffect2(() => {
    switch statesAndCountry {
    | FetchData(_) | Localdata(_) =>
      requiredFields
      ->Array.find(required => {
        switch required.field_type {
        | AddressCountry(_) => true
        | _ => false
        }
      })
      ->Option.forEach(required => {
        switch required.required_field {
        | StringField(path) =>
          setFinalJsonDict(prev => {
            switch prev->Dict.get(path) {
            | Some((key, _)) if key->JSON.Decode.string->Option.getOr("") != "" => prev
            | _ => updateDictImmutable(prev, path, (clientCountry.isoAlpha2->JSON.Encode.string, None))
            }
          })
        | _ => ()
        }
      })
    | _ => ()
    }
    None
  }, (statesAndCountry, clientCountry.isoAlpha2))

  <View style=empty>
    {fields->Array.length > 0
      ? <>
          <Space height=24. />
          <OptimizedFields
            fields
            countryCodes=mappedCountryCodes
            finalJsonDict
            setFinalJsonDict
            isSaveCardsFlow
            statesAndCountry
            paymentMethodType
            keyToTrigerButtonClickError
          />
        </>
      : React.null}
  </View>
}
