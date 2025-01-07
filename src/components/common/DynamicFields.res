open ReactNative
open Style
open RequiredFieldsTypes

module RenderField = {
  let getStateData = (states, country) => {
    states
    ->Utils.getStateNames(country)
    ->Array.map((item): CustomPicker.customPickerType => {
      {
        label: item.label != "" ? item.label ++ " - " ++ item.value : item.value,
        value: item.value,
      }
    })
  }

  let getCountryData = (countryArr, contextCountryData: CountryStateDataHookTypes.countries) => {
    contextCountryData
    ->Array.filter(item => {
      countryArr->Array.includes(item.isoAlpha2)
    })
    ->Array.map((item): CustomPicker.customPickerType => {
      {
        label: item.label != "" ? item.label ++ " - " ++ item.value : item.value,
        value: item.isoAlpha2,
        icon: Utils.getCountryFlags(item.isoAlpha2),
      }
    })
  }

  let getCountryValueOfRelativePath = (path, finalJsonDict) => {
    if path->String.length != 0 {
      let key = getKey(path, "country")
      let value = finalJsonDict->Dict.get(key)
      value
      ->Option.map(((value, _)) => value->JSON.Decode.string->Option.getOr(""))
      ->Option.getOr("")
    } else {
      ""
    }
  }

  @react.component
  let make = (
    ~required_fields_type: RequiredFieldsTypes.required_fields_type,
    ~setFinalJsonDict,
    ~finalJsonDict,
    ~isSaveCardsFlow,
    ~statesAndCountry: CountryStateDataContext.data,
    ~keyToTrigerButtonClickError,
  ) => {
    let localeObject = GetLocale.useGetLocalObj()
    let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

    let value = switch required_fields_type.required_field {
    | StringField(x) =>
      finalJsonDict
      ->Dict.get(x)
      ->Option.map(((value, _)) => value->JSON.Decode.string->Option.getOr(""))
      ->Option.getOr("")
    | FullNameField(firstName, lastName) =>
      let firstNameValue =
        finalJsonDict
        ->Dict.get(firstName)
        ->Option.map(((value, _)) => value->JSON.Decode.string)
        ->Option.getOr(None)

      let lastNameValue =
        finalJsonDict
        ->Dict.get(lastName)
        ->Option.map(((value, _)) => value->JSON.Decode.string)
        ->Option.getOr(None)
      switch (firstNameValue, lastNameValue) {
      | (Some(firstName), Some(lastName)) => [firstName, lastName]->Array.join(" ")
      | (Some(firstName), _) => firstName
      | (_, Some(lastName)) => lastName
      | _ => ""
      }
    }

    let initialValue = switch value {
    | "" => None
    | value => Some(value)
    }
    let (val, setVal) = React.useState(_ => initialValue)

    React.useEffect(() => {
      setVal(_ => initialValue)
      None
    }, (required_fields_type, isSaveCardsFlow, initialValue))

    let (errorMessage, setErrorMesage) = React.useState(_ => None)

    let (isFocus, setisFocus) = React.useState(_ => false)
    React.useEffect1(() => {
      switch val {
      | Some(text) => {
          let requiredFieldPath = RequiredFieldsTypes.getRequiredFieldPath(
            ~isSaveCardsFlow,
            ~requiredField={required_fields_type},
          )
          switch requiredFieldPath {
          | StringField(stringFieldPath) =>
            let tempValid = RequiredFieldsTypes.checkIsValid(
              ~text,
              ~field_type=required_fields_type.field_type,
              ~localeObject,
            )

            let isCountryField = switch required_fields_type.field_type {
            | AddressCountry(_) => true
            | _ => false
            }

            setErrorMesage(_ => tempValid)
            setFinalJsonDict(prev => {
              let newData = Dict.assign(Dict.make(), prev)
              if isCountryField {
                let stateKey = getKey(stringFieldPath, "state")
                switch newData->Dict.get(stateKey) {
                | Some(_) => newData->Dict.set(stateKey, (JSON.Encode.null, tempValid))
                | None => ()
                }
              }
              newData->Dict.set(stringFieldPath, (text->JSON.Encode.string, tempValid))
              newData
            })
          | FullNameField(firstNameFieldPath, lastNameFieldPath) =>
            let arr = text->String.split(" ")

            let firstNameVal = arr->Array.get(0)->Option.getOr("")
            let lastNameVal = arr->Array.filterWithIndex((_, index) => index !== 0)->Array.join(" ")
            let isBillingFields =
              required_fields_type.field_type === BillingName ||
                required_fields_type.field_type === ShippingName
            let (firstNameVal, firstNameErrorMessage) =
              firstNameVal === ""
                ? (
                    JSON.Encode.null,
                    isBillingFields
                      ? Some(localeObject.requiredText)
                      : Some(localeObject.cardHolderNameRequiredText),
                  )
                : (
                    JSON.Encode.string(firstNameVal),
                    firstNameVal->Validation.containsDigit
                      ? Some(localeObject.invalidDigitsCardHolderNameError)
                      : None,
                  )
            let (lastNameVal, lastNameErrorMessage) =
              lastNameVal === ""
                ? (JSON.Encode.null, Some(localeObject.lastNameRequiredText))
                : (
                    JSON.Encode.string(lastNameVal),
                    lastNameVal->Validation.containsDigit
                      ? Some(localeObject.invalidDigitsCardHolderNameError)
                      : None,
                  )

            setErrorMesage(_ =>
              switch firstNameErrorMessage {
              | Some(_) => firstNameErrorMessage
              | None => lastNameErrorMessage
              }
            )

            setFinalJsonDict(prev => {
              let newData = Dict.assign(Dict.make(), prev)
              newData->Dict.set(firstNameFieldPath, (firstNameVal, firstNameErrorMessage))
              newData->Dict.set(lastNameFieldPath, (lastNameVal, lastNameErrorMessage))
              newData
            })
          }
        }
      | None => ()
      }
      None
    }, [val])

    let onChangeCountry = val => {
      setVal(val)
    }
    let onChange = text => {
      setVal(_ => text)
    }
    React.useEffect1(() => {
      keyToTrigerButtonClickError != 0
        ? {
            setVal(prev => prev->Option.isNone ? Some("") : prev)
          }
        : ()
      None
    }, [keyToTrigerButtonClickError])

    let isValid = errorMessage->Option.isNone
    let isValidForFocus = isFocus || isValid

    let {borderWidth, borderRadius} = ThemebasedStyle.useThemeBasedStyle()

    let placeholder = RequiredFieldsTypes.useGetPlaceholder(
      ~field_type=required_fields_type.field_type,
      ~display_name=required_fields_type.display_name,
      ~required_field=required_fields_type.required_field,
    )
    let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)
    <>
      // <TextWrapper text={placeholder()} textType=SubheadingBold />
      // <Space height=5. />
      {switch required_fields_type.field_type {
      | AddressCountry(countryArr) =>
        <CustomPicker
          value=val
          setValue=onChangeCountry
          borderBottomLeftRadius=borderRadius
          borderBottomRightRadius=borderRadius
          borderBottomWidth=borderWidth
          items={switch countryStateData {
          | Some(res: CountryStateDataHookTypes.countryStateData) =>
            switch countryArr {
            | UseContextData => res.countries->Array.map(item => item.isoAlpha2)
            | UseBackEndData(data) => data
            }->getCountryData(res.countries)
          | _ => []
          }}
          placeholderText={placeholder()}
          isValid
          isLoading={switch statesAndCountry {
          | Loading(_) => true
          | _ => false
          }}
        />
      | AddressState =>
        switch statesAndCountry {
        | Loading(statesAndCountryVal) | Some(statesAndCountryVal) =>
          let stateData = getStateData(
            statesAndCountryVal.states,
            getCountryValueOfRelativePath(
              switch required_fields_type.required_field {
              | StringField(x) => x
              | _ => ""
              },
              finalJsonDict,
            ),
          )
          <CustomPicker
            value=val
            setValue=onChangeCountry
            borderBottomLeftRadius=borderRadius
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            items=stateData
            placeholderText={placeholder()}
            isValid
            isLoading={switch statesAndCountry {
            | Loading(_) => true
            | _ => false
            }}
          />

        | None => React.null
        }
      | _ =>
        <CustomInput
          state={val->Option.getOr("")}
          setState={text => onChange(Some(text))}
          placeholder={placeholder()}
          keyboardType={RequiredFieldsTypes.getKeyboardType(
            ~field_type=required_fields_type.field_type,
          )}
          enableCrossIcon=false
          isValid=isValidForFocus
          onFocus={_ => {
            setisFocus(_ => true)
            val->Option.isNone ? setVal(_ => Some("")) : ()
          }}
          onBlur={_ => {
            setisFocus(_ => false)
          }}
          textColor={isFocus || errorMessage->Option.isNone ? component.color : dangerColor}
          borderTopLeftRadius=borderRadius
          borderTopRightRadius=borderRadius
          borderBottomWidth=borderWidth
          borderLeftWidth=borderWidth
          borderRightWidth=borderWidth
          borderTopWidth=borderWidth
        />
      }}
      {if isFocus {
        React.null
      } else {
        <ErrorText text=errorMessage />
      }}
      //    <Space />
    </>
  }
}

module Fields = {
  @react.component
  let make = (
    ~fields: array<RequiredFieldsTypes.required_fields_type>,
    ~finalJsonDict,
    ~setFinalJsonDict,
    ~isSaveCardsFlow,
    ~statesAndCountry: CountryStateDataContext.data,
    ~keyToTrigerButtonClickError,
  ) => {
    fields
    ->Array.mapWithIndex((item, index) =>
      <React.Fragment key={index->Int.toString}>
        {index == 0 ? React.null : <Space height=18. />}
        <RenderField
          required_fields_type=item
          key={index->Int.toString}
          isSaveCardsFlow
          statesAndCountry
          finalJsonDict
          setFinalJsonDict
          keyToTrigerButtonClickError
        />
      </React.Fragment>
    )
    ->React.array
  }
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
  ~shouldRenderShippingFields=false, //To render shipping fields
  ~displayPreValueFields=false,
  ~fieldsOrder: array<fieldType>=[Other, Billing, Shipping],
) => {
  // let {component} = ThemebasedStyle.useThemeBasedStyle()
  let clientTimeZone = Intl.DateTimeFormat.resolvedOptions(Intl.DateTimeFormat.make()).timeZone
  let (statesAndCountry, _) = React.useContext(CountryStateDataContext.countryStateDataContext)

  let clientCountry = Utils.getClientCountry(
    switch statesAndCountry {
    | Some(data) => data.countries
    | _ => []
    },
    clientTimeZone,
  )

  let initialKeysValDict = React.useMemo(() => {
    switch statesAndCountry {
    | Some(statesAndCountryData) =>
      requiredFields
      ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
      ->RequiredFieldsTypes.filterRequiredFieldsForShipping(shouldRenderShippingFields)
      ->RequiredFieldsTypes.getKeysValArray(
        isSaveCardsFlow,
        clientCountry.isoAlpha2,
        statesAndCountryData.countries->Array.map(item => {item.isoAlpha2}),
      )
    | _ =>
      requiredFields
      ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
      ->RequiredFieldsTypes.filterRequiredFieldsForShipping(shouldRenderShippingFields)
      ->RequiredFieldsTypes.getKeysValArray(isSaveCardsFlow, clientCountry.isoAlpha2, [])
    }
  }, (
    requiredFields,
    isSaveCardsFlow,
    savedCardsData,
    clientCountry.isoAlpha2,
    shouldRenderShippingFields,
    statesAndCountry,
  ))

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

  let filteredFields = displayPreValueFields
    ? requiredFields
    : requiredFields->RequiredFieldsTypes.filterDynamicFieldsFromRendering(initialKeysValDict)

  // let (outsideBilling, insideBilling, shippingFields) = React.useMemo(() =>
  //   filteredFields->Array.reduce(([], [], []), ((outside, inside, shipping), item) => {
  //     let isBillingField =
  //       item.required_field
  //       ->RequiredFieldsTypes.getRequiredFieldName
  //       ->String.split(".")
  //       ->Array.includes("billing")
  //     let isShippingField =
  //       item.required_field
  //       ->RequiredFieldsTypes.getRequiredFieldName
  //       ->String.split(".")
  //       ->Array.includes("shipping")
  //     switch (isBillingField, isShippingField, renderShippingFields) {
  //     | (true, _, _) => (outside, inside->Array.concat([item]), shipping)
  //     | (_, true, true) => (outside, inside, shipping->Array.concat([item]))
  //     | (_, true, false) => (outside, inside, shipping)
  //     | _ => (outside->Array.concat([item]), inside, shipping)
  //     }
  //   })
  // , (filteredFields, renderShippingFields))

  //logic to sort the fields based on the fieldsOrder
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

  let fields = React.useMemo(() => {
    filteredFields->Array.sort((a, b) => {
      let aPath = getOrderValue(a)
      let bPath = getOrderValue(b)
      float(aPath - bPath)
    })
    filteredFields
  }, (
    requiredFields,
    isSaveCardsFlow,
    savedCardsData,
    clientCountry.isoAlpha2,
    fieldsOrder,
    displayPreValueFields,
    shouldRenderShippingFields,
  ))

  // React.useEffect1(() => {
  //   switch statesAndCountry {
  //   | Some(_) => {
  //       switch requiredFields->Array.find(required_fields_type => {
  //         switch required_fields_type.field_type {
  //         | AddressCountry(_) => true
  //         | _ => false
  //         }
  //       }) {
  //       | Some(required) =>
  //         switch required.required_field {
  //         | StringField(path) =>
  //           setFinalJsonDict(prev => {
  //             let newData = Dict.assign(Dict.make(), prev)
  //             newData->Dict.set(path, (clientCountry.isoAlpha2->JSON.Encode.string, None))
  //             newData
  //           })
  //         | _ => ()
  //         }
  //       | _ => ()
  //       }
  //       ()
  //     }
  //   | _ => ()
  //   }
  //   None
  // }, [statesAndCountry])

  let isAddressCountryField = fieldType =>
    switch fieldType.field_type {
    | AddressCountry(_) => true
    | _ => false
    }

  let updateDictWithCountry = (dict, path, countryCode) => {
    let newDict = Dict.assign(Dict.make(), dict)
    newDict->Dict.set(path, (countryCode->JSON.Encode.string, None))
    newDict
  }

  let handleStringField = (path, prevDict, countryCode) =>
    switch prevDict->Dict.get(path) {
    | Some((key, _)) if key->JSON.Decode.string->Option.getOr("") != "" => prevDict
    | _ => updateDictWithCountry(prevDict, path, countryCode)
    }

  React.useEffect2(() => {
    switch statesAndCountry {
    | Some(_) =>
      requiredFields
      ->Array.find(isAddressCountryField)
      ->Option.forEach(required => {
        switch required.required_field {
        | StringField(path) =>
          setFinalJsonDict(prev => handleStringField(path, prev, clientCountry.isoAlpha2))
        | _ => ()
        }
      })
    | _ => ()
    }
    None
  }, (statesAndCountry, clientCountry.isoAlpha2))

  let renderFields = (fields, extraSpacing) =>
    fields->Array.length > 0
      ? <>
          {extraSpacing ? <Space height=24. /> : React.null}
          <Fields
            fields
            finalJsonDict
            setFinalJsonDict
            isSaveCardsFlow
            statesAndCountry
            keyToTrigerButtonClickError
          />
        </>
      : React.null

  // let renderSectionTitle = (title, show) =>
  //   show
  //     ? <Text style={textStyle(~color=component.color, ~fontSize=16., ~marginVertical=10.->dp, ())}>
  //         {title->React.string}
  //       </Text>
  //     : React.null

  <View style={viewStyle()}>
    {renderFields(fields, true)}
    // <Space height=10. />
    // {renderSectionTitle("Billing", insideBilling->Array.length > 0)}
    // {renderFields(insideBilling, false)}
    // <Space height=10. />
    // {renderSectionTitle("Shipping", renderShippingFields && shippingFields->Array.length > 0)}
    // {renderFields(shippingFields, false)}
  </View>
}
