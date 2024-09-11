open ReactNative
open Style

module RenderField = {
  let getValueForKey = (finalJson, key) => {
    finalJson
    ->Array.filterMap(((currKey, value, _)) => {
      if key === currKey {
        Some(value)
      } else {
        None
      }
    })
    ->Array.get(0)
    ->Option.getOr(JSON.Encode.null)
  }

  @react.component
  let make = (
    ~required_fields_type: RequiredFieldsTypes.required_fields_type,
    ~setFinalJson,
    ~isSaveCardsFlow,
    ~statesJson: option<JSON.t>,
    ~country,
    ~finalJson: array<(string, JSON.t, option<string>)>,
    ~keyToTrigerButtonClickError,
  ) => {
    let localeObject = GetLocale.useGetLocalObj()
    let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

    let value = switch required_fields_type.required_field {
    | StringField(x) => finalJson->getValueForKey(x)

    | FullNameField(firstName, lastName) =>
      let firstNameValue = finalJson->getValueForKey(firstName)
      let lastNameValue = finalJson->getValueForKey(lastName)

      switch (firstNameValue, lastNameValue) {
      | (String(firstName), String(lastName)) =>
        if firstName === "" && lastName === "" {
          JSON.Encode.null
        } else {
          JSON.Encode.string([firstName, lastName]->Array.join(" "))
        }
      | (String(firstName), _) => JSON.Encode.string(firstName)
      | (_, String(lastName)) => JSON.Encode.string(lastName)
      | _ => JSON.Encode.null
      }
    }

    let initialValue = switch value->JSON.Decode.string->Option.getOr("") {
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
            setFinalJson(prev => {
              prev->Array.map(
                item => {
                  let (key, _, _) = item

                  let isStateKey = key->String.split(".")->Array.includes("state")

                  if isCountryField && isStateKey {
                    (key, JSON.Encode.null, Some(localeObject.requiredText))
                  } else if key == stringFieldPath {
                    (key, text->JSON.Encode.string, tempValid)
                  } else {
                    item
                  }
                },
              )
            })
          | FullNameField(firstNameFieldPath, lastNameFieldPath) =>
            let arr = text->String.split(" ")

            let firstNameVal = arr->Array.get(0)->Option.getOr("")
            let lastNameVal = arr->Array.filterWithIndex((_, index) => index !== 0)->Array.join(" ")

            let (firstNameVal, firstNameErrorMessage) =
              firstNameVal === ""
                ? (JSON.Encode.null, Some(localeObject.cardHolderNameRequiredText))
                : (JSON.Encode.string(firstNameVal), None)
            let (lastNameVal, lastNameErrorMessage) =
              lastNameVal === ""
                ? (JSON.Encode.null, Some(localeObject.lastNameRequiredText))
                : (JSON.Encode.string(lastNameVal), None)

            setErrorMesage(_ =>
              switch firstNameErrorMessage {
              | Some(_) => firstNameErrorMessage
              | None => lastNameErrorMessage
              }
            )
            setFinalJson(prev => {
              prev->Array.map(
                item => {
                  let (key, _, _) = item

                  if key === firstNameFieldPath {
                    (key, firstNameVal, firstNameErrorMessage)
                  } else if key === lastNameFieldPath {
                    (key, lastNameVal, lastNameErrorMessage)
                  } else {
                    item
                  }
                },
              )
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
    let getStateData = states => {
      states
      ->Utils.getStateNames(country)
      ->Array.map((item): CustomPicker.customPickerType => {
        {
          name: item,
          value: item,
        }
      })
    }

    let getCountryData = countryArr => {
      Country.country
      ->Array.filter(item => {
        countryArr->Array.includes(item.isoAlpha2)
      })
      ->Array.map((item): CustomPicker.customPickerType => {
        {
          name: item.countryName,
          value: item.isoAlpha2,
          icon: Utils.getCountryFlags(item.isoAlpha2),
        }
      })
    }

    let placeholder = RequiredFieldsTypes.useGetPlaceholder(
      ~field_type=required_fields_type.field_type,
      ~display_name=required_fields_type.display_name,
      ~required_field=required_fields_type.required_field,
    )
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
          items={countryArr->getCountryData}
          placeholderText={placeholder()}
          isValid
        />
      | AddressState =>
        switch statesJson {
        | Some(options) =>
          <CustomPicker
            value=val
            setValue=onChangeCountry
            borderBottomLeftRadius=borderRadius
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            items={options->getStateData}
            placeholderText={placeholder()}
            isValid
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
    ~setFinalJson,
    ~isSaveCardsFlow,
    ~statesJson,
    ~country,
    ~finalJson,
    ~keyToTrigerButtonClickError,
  ) => {
    fields
    ->Array.mapWithIndex((item, index) =>
      <React.Fragment key={index->Int.toString}>
        {index == 0 ? React.null : <Space height=18. />}
        <RenderField
          required_fields_type=item
          setFinalJson
          key={index->Int.toString}
          isSaveCardsFlow
          statesJson
          country
          finalJson
          keyToTrigerButtonClickError
        />
      </React.Fragment>
    )
    ->React.array
  }
}

@react.component
let make = (
  ~requiredFields: RequiredFieldsTypes.required_fields,
  ~setIsAllDynamicFieldValid,
  ~setDynamicFieldsJson,
  ~isSaveCardsFlow=false,
  ~savedCardsData: option<SdkTypes.savedDataType>,
  ~keyToTrigerButtonClickError,
) => {
  // let localeObject = GetLocale.useGetLocalObj()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let clientTimeZone = Utils.dateTimeFormat().resolvedOptions().timeZone
  let clientCountry = Utils.getClientCountry(clientTimeZone)

  let keysValArray =
    requiredFields
    ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
    ->RequiredFieldsTypes.getKeysValArray(isSaveCardsFlow, clientCountry.isoAlpha2)

  let (finalJson, setFinalJson) = React.useState(_ => keysValArray)

  React.useEffect1(() => {
    setFinalJson(_ => keysValArray)
    None
  }, [isSaveCardsFlow])
  let (country, setCountry) = React.useState(_ => nativeProp.hyperParams.country)
  React.useEffect1(() => {
    let countryVal =
      finalJson
      ->Array.find(((path, _, _)) => {
        path->String.includes("country")
      })
      ->Option.flatMap(((_, value, _)) => Some(value))
      ->Option.flatMap(JSON.Decode.string)
      ->Option.getOr(clientCountry.isoAlpha2)

    setCountry(_ => countryVal)

    let temp = Array.reduce(finalJson, true, (accumulator, item) => {
      let (_, _, key) = item
      accumulator && key->Option.isNone
    })
    setIsAllDynamicFieldValid(_ => temp)

    setDynamicFieldsJson(_ => finalJson)
    None
  }, [finalJson])

  let filteredRequiredFieldsFromRendering =
    requiredFields->RequiredFieldsTypes.filterDynamicFieldsFromRendering(keysValArray)

  let (statesJson, setStatesJson) = React.useState(_ => None)

  React.useEffect0(() => {
    // Dynamically import/download Postal codes and states JSON
    RequiredFieldsTypes.importStates("./../../utility/reusableCodeFromWeb/States.json")
    ->Promise.then(res => {
      setStatesJson(_ => Some(res.states))
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      setStatesJson(_ => None)
      Promise.resolve()
    })
    ->ignore

    None
  })

  let requiredFieldsOutsideBilling = []
  let requiredFieldsInsideBilling = []
  filteredRequiredFieldsFromRendering->Array.forEach(item => {
    let isBillingSectionField =
      item.required_field
      ->RequiredFieldsTypes.getRequiredFieldName
      ->String.split(".")
      ->Array.includes("billing")

    if isBillingSectionField {
      requiredFieldsInsideBilling->Array.push(item)
    } else {
      requiredFieldsOutsideBilling->Array.push(item)
    }
  })

  if filteredRequiredFieldsFromRendering->Array.length > 0 {
    <View style={viewStyle()}>
      {requiredFieldsOutsideBilling->Array.length > 0 ? <Space height=24. /> : React.null}
      <Fields
        fields=requiredFieldsOutsideBilling
        setFinalJson
        isSaveCardsFlow
        statesJson
        country
        finalJson
        keyToTrigerButtonClickError
      />
      {if requiredFieldsInsideBilling->Array.length > 0 {
        <>
          <Space height=24. />
          // <TextWrapper text=localeObject.billingDetails textType={ModalText} />
          // <Space height=8. />
          <Fields
            fields=requiredFieldsInsideBilling
            setFinalJson
            isSaveCardsFlow
            statesJson
            country
            finalJson
            keyToTrigerButtonClickError
          />
        </>
      } else {
        React.null
      }}
    </View>
  } else {
    React.null
  }
}
