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
        value: item.code,
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
    ~paymentMethodType: option<RequiredFieldsTypes.payment_method_types_in_bank_debit>,
    ~countryCodes,
  ) => {
    let localeObject = GetLocale.useGetLocalObj()
    let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

    let value = switch required_fields_type.required_field {
    | StringField(x) | EmailField(x) =>
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
    | PhoneField(_, phoneNumber) =>
      let phoneNumberValue =
        finalJsonDict
        ->Dict.get(phoneNumber)
        ->Option.map(((value, _)) => value->JSON.Decode.string)
        ->Option.getOr(None)
      phoneNumberValue->Option.getOr("")
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
          | StringField(stringFieldPath) | EmailField(stringFieldPath) =>
            let validationErrMsg = RequiredFieldsTypes.checkIsValid(
              ~text,
              ~field_type=required_fields_type.field_type,
              ~localeObject,
              ~display_name=required_fields_type.display_name,
              ~paymentMethodType,
            )
            let isCountryField = switch required_fields_type.field_type {
            | AddressCountry(_) => true
            | _ => false
            }

            setErrorMesage(_ => validationErrMsg)
            setFinalJsonDict(prev => {
              let newData = Dict.assign(Dict.make(), prev)
              if isCountryField {
                let stateKey = getKey(stringFieldPath, "state")
                switch newData->Dict.get(stateKey) {
                | Some(_) => newData->Dict.set(stateKey, (JSON.Encode.null, Some("required")))
                | None => ()
                }
              }
              newData->Dict.set(stringFieldPath, (text->JSON.Encode.string, validationErrMsg))
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
                      ? Some(localeObject.mandatoryFieldText)
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

          | PhoneField(phoneCodePath, phoneNumberPath) =>
            let phoneCodeVal = text->RequiredFieldsTypes.getFirstValue->JSON.Encode.string
            let phoneNumberVal = text->RequiredFieldsTypes.getLastValue->Validation.clearSpaces

            let errorMessage = RequiredFieldsTypes.checkIsValid(
              ~text=phoneNumberVal,
              ~field_type=required_fields_type.field_type,
              ~localeObject,
              ~display_name=required_fields_type.display_name,
              ~paymentMethodType,
            )
            setErrorMesage(_ => errorMessage)
            setFinalJsonDict(prev => {
              let newData = Dict.assign(Dict.make(), prev)
              newData->Dict.set(phoneCodePath, (phoneCodeVal, None))
              newData->Dict.set(phoneNumberPath, (text->JSON.Encode.string, errorMessage))
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
      setVal(prev =>
        RequiredFieldsTypes.allowOnlyDigits(
          ~text,
          ~fieldType=required_fields_type.field_type,
          ~prev,
          ~paymentMethodType,
        )
      )
    }
    let onChangePhone = text => {
      let phone = text->RequiredFieldsTypes.getLastValue

      setVal(prev => Some(
        prev->Option.getOr("")->RequiredFieldsTypes.getFirstValue ++
        " " ++
        RequiredFieldsTypes.allowOnlyDigits(
          ~text=Some(phone),
          ~fieldType=required_fields_type.field_type,
          ~prev,
          ~paymentMethodType,
        )->Option.getOr(""),
      ))
    }
    let onChangePhoneCode: (option<string> => option<string>) => unit = (
      value: option<string> => option<string>,
    ) => {
      setVal(prev => Some(
        value(prev)->Option.getOr("") ++
        " " ++
        prev->Option.getOr("")->RequiredFieldsTypes.getLastValue,
      ))
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
      {switch required_fields_type.required_field {
      | StringField(_) | EmailField(_) | FullNameField(_, _) =>
        switch required_fields_type.field_type {
        | AddressCountry(countryArr) =>
          <CustomPicker
            value=val
            setValue=onChangeCountry
            isCountryStateFields=true
            borderBottomLeftRadius=borderRadius
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            items={switch countryStateData {
            | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
              switch countryArr {
              | UseContextData => res.countries->Array.map(item => item.isoAlpha2)
              | UseBackEndData(data) => data
              }->getCountryData(res.countries)
            | _ => []
            }}
            placeholderText={placeholder()}
            isValid
            isLoading={switch statesAndCountry {
            | Loading => true
            | _ => false
            }}
          />
        | AddressState =>
          <CustomPicker
            value=val
            isCountryStateFields=true
            setValue=onChangeCountry
            borderBottomLeftRadius=borderRadius
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            items={switch statesAndCountry {
            | FetchData(statesAndCountryVal) | Localdata(statesAndCountryVal) =>
              getStateData(
                statesAndCountryVal.states,
                getCountryValueOfRelativePath(
                  switch required_fields_type.required_field {
                  | StringField(x) => x
                  | _ => ""
                  },
                  finalJsonDict,
                ),
              )
            | _ => []
            }}
            placeholderText={placeholder()}
            isValid
            isLoading={switch statesAndCountry {
            | Loading => true
            | _ => false
            }}
          />

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
        }
      | PhoneField(_, _) =>
        <View
          style={viewStyle(
            ~display=#flex,
            ~flexDirection=#row,
            ~justifyContent=#"space-between",
            ~gap=8.,
            (),
          )}>
          <CustomPicker
            value={Some(val->Option.getOr("")->RequiredFieldsTypes.getFirstValue)}
            setValue=onChangePhoneCode
            borderBottomLeftRadius=borderRadius
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            items={countryCodes}
            placeholderText={"Code"}
            isValid
            isLoading={switch statesAndCountry {
            | Loading => true
            | _ => false
            }}
            showIcon=true
            style={viewStyle(~flex=1., ())}
          />
          <CustomInput
            state={val->Option.getOr("")}
            setState=onChangePhone
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
            style={viewStyle(~flex=3., ())}
          />
        </View>
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
    ~paymentMethodType,
    ~countryCodes,
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
          paymentMethodType
          countryCodes
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
  ~paymentMethodType=?,
  ~fieldsOrder: array<fieldType>=[Other, Billing, Shipping],
) => {
  // let {component} = ThemebasedStyle.useThemeBasedStyle()
  let clientTimeZone = Intl.DateTimeFormat.resolvedOptions(Intl.DateTimeFormat.make()).timeZone
  let (statesAndCountry, _) = React.useContext(CountryStateDataContext.countryStateDataContext)
  let (countryCodes, setCountryCodes) = React.useState(_ => [])

  let clientCountry = Utils.getClientCountry(
    switch statesAndCountry {
    | FetchData(data) | Localdata(data) => data.countries
    | _ => []
    },
    clientTimeZone,
  )

  let initialKeysValDict = React.useMemo(() => {
    switch statesAndCountry {
    | FetchData(statesAndCountryData)
    | Localdata(statesAndCountryData) =>
      requiredFields
      ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
      ->RequiredFieldsTypes.filterRequiredFieldsForShipping(shouldRenderShippingFields)
      ->RequiredFieldsTypes.getKeysValArray(
        isSaveCardsFlow,
        clientCountry.isoAlpha2,
        statesAndCountryData.countries->Array.map(item => {item.isoAlpha2}),
        countryCodes,
      )
    | _ =>
      requiredFields
      ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
      ->RequiredFieldsTypes.filterRequiredFieldsForShipping(shouldRenderShippingFields)
      ->RequiredFieldsTypes.getKeysValArray(
        isSaveCardsFlow,
        clientCountry.isoAlpha2,
        [],
        countryCodes,
      )
    }
  }, (
    requiredFields,
    isSaveCardsFlow,
    savedCardsData,
    clientCountry.isoAlpha2,
    shouldRenderShippingFields,
    statesAndCountry,
    displayPreValueFields,
    countryCodes,
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

  let filteredFields =
    (
      displayPreValueFields
        ? requiredFields
        : requiredFields->RequiredFieldsTypes.filterDynamicFieldsFromRendering(initialKeysValDict)
    )
    ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
    ->RequiredFieldsTypes.filterRequiredFieldsForShipping(shouldRenderShippingFields)

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
  React.useEffect0(() => {
    RequiredFieldsTypes.importStatesAndCountries(
      "./../../utility/reusableCodeFromWeb/Phone_number.json",
    )
    ->Promise.then(async json => {
      switch json->Js.Json.decodeObject {
      | Some(res) =>
        res
        ->Js.Dict.get("countries")
        ->Option.getOr([]->Js.Json.Array)
        ->Js.Json.decodeArray
        ->Option.getOr([])
        ->Array.map(
          item => {
            switch item->Js.Json.decodeObject {
            | Some(res) => {
                phone_number_code: Utils.getString(res, "phone_number_code", ""),
                country_name: Utils.getString(res, "country_name", ""),
                country_code: Utils.getString(res, "country_code", ""),

                // phone_number_code: Utils.getString(res, "phone_number_code", ""),
                // validation_regex: Utils.getString(res, "validation_regex", ""),
                // format_example: Utils.getString(res, "format_example", ""),
                // format_regex: Utils.getString(res, "format_regex", ""),
              }
            | None => {
                phone_number_code: "+1",
                country_name: "United States",
                country_code: "US",
              }
            }
          },
        )
      | None => []
      }
    })
    ->Promise.thenResolve(v => {
      setCountryCodes(_ => v)
    })
    ->ignore

    None
  })

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
    | FetchData(_) | Localdata(_) =>
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
  let mappedCountryCodes = countryCodes->Array.map((countryCode): CustomPicker.customPickerType => {
    label: countryCode.country_name ++ " " ++ countryCode.phone_number_code,
    value: countryCode.phone_number_code,
    icon: Utils.getCountryFlags(countryCode.country_code),
  })

  let renderFields = (fields, extraSpacing) =>
    fields->Array.length > 0
      ? <>
          {extraSpacing ? <Space height=24. /> : React.null}
          <Fields
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
