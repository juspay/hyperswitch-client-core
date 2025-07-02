open ReactNative
open Style
open RequiredFieldsTypes

type fieldProps = {
  required_fields_type: RequiredFieldsTypes.required_fields_type,
  finalJsonDict: Dict.t<(JSON.t, option<string>)>,
  setFinalJsonDict: (Dict.t<(JSON.t, option<string>)> => Dict.t<(JSON.t, option<string>)>) => unit,
  isSaveCardsFlow: bool,
  statesAndCountry: CountryStateDataContext.data,
  keyToTrigerButtonClickError: int,
  paymentMethodType: option<RequiredFieldsTypes.payment_method_types_in_bank_debit>,
  countryCodes: array<CustomPicker.customPickerType>,
}

type styleProps = {
  borderRadius: float,
  borderWidth: float,
  component: ThemebasedStyle.themeBasedStyleObj,
  dangerColor: string,
}

let updateDictImmutable = (dict, key, value) => {
  let newDict = Dict.copy(dict)
  newDict->Dict.set(key, value)
  newDict
}

let updateMultipleDictEntries = (dict, entries) => {
  let newDict = Dict.copy(dict)
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

type fieldState = {
  value: option<string>,
  errorMessage: option<string>,
  isFocus: bool,
}

type fieldAction = 
  | SetValue(option<string>)
  | SetError(option<string>)
  | SetFocus(bool)
  | Reset(option<string>)

let fieldReducer = (state : fieldState, action) => {
  switch action {
  | SetValue(value) => {...state, value: value}
  | SetError(error) => {...state, errorMessage: error}
  | SetFocus(focus) => {...state, isFocus: focus}
  | Reset(initialValue) => {value: initialValue, errorMessage: None, isFocus: false}
  }
}

module FieldValidator = {
  let validateStringField = (value, fieldType, localeObject, displayName, paymentMethodType) => {
    RequiredFieldsTypes.checkIsValid(
      ~text=value,
      ~field_type=fieldType,
      ~localeObject,
      ~display_name=displayName,
      ~paymentMethodType,
    )
  }

  let validateFullName = (firstName, lastName, localeObject : LocaleDataType.localeStrings, isBillingFields) => {
    let firstNameError = firstName === ""
      ? (JSON.Encode.null, isBillingFields ? Some(localeObject.mandatoryFieldText) : Some(localeObject.cardHolderNameRequiredText))
      : (JSON.Encode.string(firstName), firstName->Validation.containsDigit ? Some(localeObject.invalidDigitsCardHolderNameError) : None)
    
    let lastNameError = lastName === ""
      ? (JSON.Encode.null, Some(localeObject.lastNameRequiredText))
      : (JSON.Encode.string(lastName), lastName->Validation.containsDigit ? Some(localeObject.invalidDigitsCardHolderNameError) : None)
    
    (firstNameError, lastNameError)
  }

  let validatePhoneField = (phoneNumber, fieldType, localeObject, displayName, paymentMethodType) => {
    RequiredFieldsTypes.checkIsValid(
      ~text=phoneNumber,
      ~field_type=fieldType,
      ~localeObject,
      ~display_name=displayName,
      ~paymentMethodType,
    )
  }
}

module CountryField = {
  @react.component
  let make = (~value, ~setValue, ~items, ~placeholder, ~isValid, ~isLoading, ~borderRadius, ~borderWidth) => {
    <CustomPicker
      value
      setValue
      isCountryStateFields=true
      borderBottomLeftRadius=borderRadius
      borderBottomRightRadius=borderRadius
      borderBottomWidth=borderWidth
      items
      placeholderText=placeholder
      isValid
      isLoading
    />
  }
}

module StateField = {
  @react.component  
  let make = (~value, ~setValue, ~items, ~placeholder, ~isValid, ~isLoading, ~borderRadius, ~borderWidth) => {
    <CustomPicker
      value
      isCountryStateFields=true
      setValue
      borderBottomLeftRadius=borderRadius
      borderBottomRightRadius=borderRadius
      borderBottomWidth=borderWidth
      items
      placeholderText=placeholder
      isValid
      isLoading
    />
  }
}

module PhoneField = {
  @react.component
  let make = (~value, ~onChangePhoneCode, ~onChangePhone, ~countryCodes, ~placeholder, ~isValid, ~isLoading, ~borderRadius, ~borderWidth, ~isValidForFocus, ~onFocus, ~onBlur, ~component : ThemebasedStyle.componentConfig , ~dangerColor, ~fieldType) => {
    <View
      style={s({
        display: #flex,
        flexDirection: #row,
        justifyContent: #"space-between",
        gap: 8.->dp,
      })}>
      <CustomPicker
        value={Some(value->Option.getOr("")->RequiredFieldsTypes.getFirstValue)}
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
        state={value->Option.getOr("")->RequiredFieldsTypes.getLastValue}
        setState=onChangePhone
        placeholder
        keyboardType={RequiredFieldsTypes.getKeyboardType(~field_type=fieldType)}
        enableCrossIcon=false
        isValid=isValidForFocus
        onFocus={_ => onFocus()}
        onBlur={_ => onBlur()}
        textColor={isValidForFocus ? component.color : dangerColor}
        borderTopLeftRadius=borderRadius
        borderTopRightRadius=borderRadius
        borderBottomWidth=borderWidth
        borderLeftWidth=borderWidth
        borderRightWidth=borderWidth
        borderTopWidth=borderWidth
        style={s({flex: 3.})}
      />
    </View>
  }
}

module TextInputField = {
  @react.component
  let make = (~value, ~onChange, ~placeholder, ~fieldType, ~isValidForFocus, ~onFocus, ~onBlur, ~component : ThemebasedStyle.componentConfig, ~dangerColor, ~borderRadius, ~borderWidth) => {
    <CustomInput
      state={value->Option.getOr("")}
      setState=onChange
      placeholder
      keyboardType={RequiredFieldsTypes.getKeyboardType(~field_type=fieldType)}
      enableCrossIcon=false
      isValid=isValidForFocus
      onFocus={_ => onFocus()}
      onBlur={_ => onBlur()}
      textColor={isValidForFocus ? component.color : dangerColor}
      borderTopLeftRadius=borderRadius
      borderTopRightRadius=borderRadius
      borderBottomWidth=borderWidth
      borderLeftWidth=borderWidth
      borderRightWidth=borderWidth
      borderTopWidth=borderWidth
    />
  }
}

module OptimizedRenderField = {
  @react.component
  let make = React.memo((~fieldProps: fieldProps) => {
    let localeObject = GetLocale.useGetLocalObj()
    let styleProps = ThemebasedStyle.useThemeBasedStyle()

    

    let value = getFieldValueOptimized(fieldProps.finalJsonDict, fieldProps.required_fields_type.required_field)
    let initialValue = value === "" ? None : Some(value)
    
    let (state, dispatch) = React.useReducer(fieldReducer, {
      value: initialValue,
      errorMessage: None,
      isFocus: false,
    })

    let placeholder = RequiredFieldsTypes.useGetPlaceholder(
      ~field_type=fieldProps.required_fields_type.field_type,
      ~display_name=fieldProps.required_fields_type.display_name,
      ~required_field=fieldProps.required_fields_type.required_field,
    )()

    let isValid = React.useMemo1(() => state.errorMessage->Option.isNone, [state.errorMessage])
    let isValidForFocus = React.useMemo2(() => state.isFocus || isValid, (state.isFocus, isValid))

    let countryItems = React.useMemo2(() => {
      switch fieldProps.required_fields_type.field_type {
      | AddressCountry(countryArr) =>
        switch fieldProps.statesAndCountry {
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
    }, (fieldProps.required_fields_type.field_type, fieldProps.statesAndCountry))

    let stateItems = React.useMemo2(() => {
      switch fieldProps.required_fields_type.field_type {
      | AddressState =>
        switch fieldProps.statesAndCountry {
        | FetchData(statesAndCountryVal) | Localdata(statesAndCountryVal) =>
          let country = switch fieldProps.required_fields_type.required_field {
          | StringField(x) => 
            fieldProps.finalJsonDict
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
    }, (fieldProps.required_fields_type.field_type, fieldProps.finalJsonDict))

    let isLoading = React.useMemo1(() => {
      switch fieldProps.statesAndCountry {
      | Loading => true
      | _ => false
      }
    }, [fieldProps.statesAndCountry])

    let validateAndUpdate = React.useCallback1((newValue) => {
      let requiredFieldPath = RequiredFieldsTypes.getRequiredFieldPath(
        ~isSaveCardsFlow=fieldProps.isSaveCardsFlow,
        ~requiredField=fieldProps.required_fields_type,
      )
      
      switch requiredFieldPath {
      | StringField(stringFieldPath) | EmailField(stringFieldPath) =>
        let validationErrMsg = FieldValidator.validateStringField(
          newValue,
          fieldProps.required_fields_type.field_type,
          localeObject,
          fieldProps.required_fields_type.display_name,
          fieldProps.paymentMethodType,
        )
        let isCountryField = switch fieldProps.required_fields_type.field_type {
        | AddressCountry(_) => true
        | _ => false
        }

        dispatch(SetError(validationErrMsg))
        fieldProps.setFinalJsonDict(prev => {
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
        let isBillingFields = fieldProps.required_fields_type.field_type === BillingName || fieldProps.required_fields_type.field_type === ShippingName
        
        let ((firstNameVal, firstNameErrorMessage), (lastNameVal, lastNameErrorMessage)) = 
          FieldValidator.validateFullName(firstNameVal, lastNameVal, localeObject, isBillingFields)

        dispatch(SetError(
          switch firstNameErrorMessage {
          | Some(_) => firstNameErrorMessage
          | None => lastNameErrorMessage
          }
        ))

        fieldProps.setFinalJsonDict(prev => {
          updateMultipleDictEntries(prev, [
            (firstNameFieldPath, (firstNameVal, firstNameErrorMessage)),
            (lastNameFieldPath, (lastNameVal, lastNameErrorMessage))
          ])
        })

      | PhoneField(phoneCodePath, phoneNumberPath) =>
        let phoneCodeVal = newValue->RequiredFieldsTypes.getFirstValue->JSON.Encode.string
        let phoneNumberVal = newValue->RequiredFieldsTypes.getLastValue

        let errorMessage = FieldValidator.validatePhoneField(
          phoneNumberVal,
          fieldProps.required_fields_type.field_type,
          localeObject,
          fieldProps.required_fields_type.display_name,
          fieldProps.paymentMethodType,
        )
        dispatch(SetError(errorMessage))
        fieldProps.setFinalJsonDict(prev => {
          updateMultipleDictEntries(prev, [
            (phoneCodePath, (phoneCodeVal, None)),
            (phoneNumberPath, (phoneNumberVal->JSON.Encode.string, errorMessage))
          ])
        })
      }
    }, [fieldProps.setFinalJsonDict])

    let onChange = React.useCallback1((text) => {
      let processedText = RequiredFieldsTypes.allowOnlyDigits(
        ~text=Some(text),
        ~fieldType=fieldProps.required_fields_type.field_type,
        ~prev=state.value,
        ~paymentMethodType=fieldProps.paymentMethodType,
      )
      dispatch(SetValue(processedText))
    }, [dispatch])

    let onChangeCountry = React.useCallback1((func) => {
      dispatch(SetValue(func(state.value)))
    }, [dispatch])

    let onChangePhone = React.useCallback1((text) => {
      dispatch(SetValue(Some(
        state.value->Option.getOr("")->RequiredFieldsTypes.getFirstValue ++
        " " ++
        RequiredFieldsTypes.allowOnlyDigits(
          ~text=Some(text),
          ~fieldType=fieldProps.required_fields_type.field_type,
          ~prev=state.value,
          ~paymentMethodType=fieldProps.paymentMethodType,
        )->Option.getOr(""),
      )))
    }, [dispatch])

    let onChangePhoneCode = React.useCallback1((value) => {
      dispatch(SetValue(Some(
        value(state.value)->Option.getOr("") ++
        " " ++
        state.value->Option.getOr("")->RequiredFieldsTypes.getLastValue,
      )))
    }, [dispatch])

    let onFocus = React.useCallback0(() => {
      dispatch(SetFocus(true))
    })

    let onBlur = React.useCallback0(() => {
      dispatch(SetFocus(false))
    })

    React.useEffect1(() => {
      switch state.value {
      | Some(text) => validateAndUpdate(text)
      | None => ()
      }
      None
    }, [state.value])

    React.useEffect2(() => {
      if !state.isFocus {
        dispatch(SetValue(initialValue))
      }
      None
    }, (initialValue, state.isFocus))

    React.useEffect1(() => {
      fieldProps.keyToTrigerButtonClickError != 0
        ? dispatch(SetValue(state.value->Option.isNone ? Some("") : state.value))
        : ()
      None
    }, [fieldProps.keyToTrigerButtonClickError])

    <>
      {switch (fieldProps.required_fields_type.required_field, fieldProps.required_fields_type.field_type) {
      | (StringField(_) | EmailField(_) | FullNameField(_, _), AddressCountry(_)) =>
        <CountryField
          value=state.value
          setValue=onChangeCountry
          items=countryItems
          placeholder
          isValid
          isLoading
          borderRadius=styleProps.borderRadius
          borderWidth=styleProps.borderWidth
        />
      | (StringField(_) | EmailField(_) | FullNameField(_, _), AddressState) =>
        <StateField
          value=state.value
          setValue=onChangeCountry
          items=stateItems
          placeholder
          isValid
          isLoading
          borderRadius=styleProps.borderRadius
          borderWidth=styleProps.borderWidth
        />
      | (StringField(_) | EmailField(_) | FullNameField(_, _), _) =>
        <TextInputField
          value=state.value
          onChange
          placeholder
          fieldType=fieldProps.required_fields_type.field_type
          isValidForFocus
          onFocus
          onBlur
          component=styleProps.component
          dangerColor=styleProps.dangerColor
          borderRadius=styleProps.borderRadius
          borderWidth=styleProps.borderWidth
        />
      | (PhoneField(_, _), _) =>
        <PhoneField
          value=state.value
          onChangePhoneCode
          onChangePhone
          countryCodes=fieldProps.countryCodes
          placeholder
          isValid
          isLoading
          borderRadius=styleProps.borderRadius
          borderWidth=styleProps.borderWidth
          isValidForFocus
          onFocus
          onBlur
          component=styleProps.component
          dangerColor=styleProps.dangerColor
          fieldType=fieldProps.required_fields_type.field_type
        />
      }}
      {!state.isFocus ? <ErrorText text=state.errorMessage /> : React.null}
    </>
  })
}

module OptimizedFields = {
  @react.component
  let make = React.memo((
    ~fields: array<RequiredFieldsTypes.required_fields_type>,
    ~baseFieldProps: fieldProps,
  ) => {
    let renderedFields = React.useMemo1(() => {
      fields
      ->Array.mapWithIndex((item, index) =>
        <React.Fragment key={index->Int.toString}>
          {index == 0 ? React.null : <Space height=18. />}
          <OptimizedRenderField
            fieldProps={{...baseFieldProps, required_fields_type: item}}
            key={index->Int.toString}
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

  let processedRequiredFields = React.useMemo3(() => {
    requiredFields
    ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
    ->RequiredFieldsTypes.filterRequiredFieldsForShipping(shouldRenderShippingFields)
  }, (requiredFields, isSaveCardsFlow, shouldRenderShippingFields))

  let initialKeysValDict = React.useMemo3(() => {
    switch statesAndCountry {
    | FetchData(statesAndCountryData) | Localdata(statesAndCountryData) =>
      processedRequiredFields->RequiredFieldsTypes.getKeysValArray(
        isSaveCardsFlow,
        clientCountry.isoAlpha2,
        statesAndCountryData.countries->Array.map(item => {item.isoAlpha2}),
        statesAndCountryData.phoneCountryCodes,
      )
    | _ =>
      processedRequiredFields->RequiredFieldsTypes.getKeysValArray(isSaveCardsFlow, clientCountry.isoAlpha2, [], [])
    }
  }, (processedRequiredFields, statesAndCountry, clientCountry.isoAlpha2))

  let filteredFields = React.useMemo2(() => {
    let fields = displayPreValueFields
      ? processedRequiredFields
      : requiredFields->RequiredFieldsTypes.filterDynamicFieldsFromRendering(initialKeysValDict)
    fields
  }, (displayPreValueFields, initialKeysValDict))

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
    | FetchData(data) | Localdata(data) =>
      data.phoneCountryCodes->Array.map((countryCode): CustomPicker.customPickerType => {
        label: `${countryCode.country_name} ${countryCode.phone_number_code}`,
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
            baseFieldProps={{
              required_fields_type: {
                required_field: StringField(""),
                field_type: AddressLine1,
                display_name: "",
                value:""
              },
              finalJsonDict,
              setFinalJsonDict,
              isSaveCardsFlow,
              statesAndCountry,
              keyToTrigerButtonClickError,
              paymentMethodType,
              countryCodes: mappedCountryCodes,
            }}
          />
        </>
      : React.null}
  </View>
}
