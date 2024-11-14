open ReactNative
open Style
open RequiredFieldsTypes

module RenderField = {
  let getStateData = (states, country) => {
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

  let getCountryValueOfRelativePath = (path, finalJsonDict) => {
    let key = getKey(path, "country")

    let value = finalJsonDict->Dict.get(key)
    value
    ->Option.map(((value, _)) => value->JSON.Decode.string->Option.getOr(""))
    ->Option.getOr("")
  }

  @react.component
  let make = (
    ~required_fields_type: RequiredFieldsTypes.required_fields_type,
    ~setFinalJsonDict,
    ~finalJsonDict,
    ~isSaveCardsFlow,
    ~statesJson: option<JSON.t>,
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
                newData->Dict.set(stateKey, (JSON.Encode.null, tempValid))
                Console.log2("stateKey", stateKey)
                Console.log2("newData", newData)
              }
              newData->Dict.set(stringFieldPath, (text->JSON.Encode.string, tempValid))
              newData
            })
          | FullNameField(firstNameFieldPath, lastNameFieldPath) =>
            let arr = text->String.split(" ")

            let firstNameVal = arr->Array.get(0)->Option.getOr("")
            let lastNameVal = arr->Array.filterWithIndex((_, index) => index !== 0)->Array.join("")
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
    <>
      // <TextWrapper text={placeholder()} textType=SubheadingBold />
      // <Space height=5. />
      {switch required_fields_type.field_type {
      | Email =>
        <CustomInput
          state={val->Option.getOr("")}
          setState={text => onChange(Some(text))}
          placeholder=localeObject.emailLabel
          keyboardType=#"email-address"
          borderBottomLeftRadius=borderRadius
          borderBottomRightRadius=borderRadius
          borderTopLeftRadius=borderRadius
          borderTopRightRadius=borderRadius
          borderTopWidth=borderWidth
          borderBottomWidth=borderWidth
          borderLeftWidth=borderWidth
          borderRightWidth=borderWidth
          textColor=component.color
        />
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
            items={options->getStateData(
              getCountryValueOfRelativePath(
                switch required_fields_type.required_field {
                | StringField(x) => x
                | _ => ""
                },
                finalJsonDict,
              ),
            )}
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
    ~finalJsonDict,
    ~setFinalJsonDict,
    ~isSaveCardsFlow,
    ~statesJson,
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
          statesJson
          finalJsonDict
          setFinalJsonDict
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
  ~renderShippingFields=true, //To render shipping fields
  ~displayPreValueFields=false,
) => {
  //To render pre value fields

  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let clientTimeZone = Intl.DateTimeFormat.resolvedOptions(Intl.DateTimeFormat.make()).timeZone
  let clientCountry = Utils.getClientCountry(clientTimeZone)

  let initialKeysValArray = React.useMemo(() =>
    requiredFields
    ->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, savedCardsData)
    ->RequiredFieldsTypes.getKeysValArray(isSaveCardsFlow, clientCountry.isoAlpha2)
  , (requiredFields, isSaveCardsFlow, savedCardsData, clientCountry.isoAlpha2))

  let initialKeysValDict = initialKeysValArray->Array.reduce(Dict.make(), (
    acc,
    (key, value, isValid),
  ) => {
    acc->Dict.set(key, (value, isValid))
    acc
  })
  let (finalJsonDict, setFinalJsonDict) = React.useState(_ => initialKeysValDict)
  let (statesJson, setStatesJson) = React.useState(_ => None)

  React.useEffect1(() => {
    let (isAllValid, dynamicFieldsJson) =
      finalJsonDict
      ->Dict.toArray
      ->Array.reduce((true, []), ((isValid, acc), (key, (value, errorMessage))) => {
        (isValid && errorMessage->Option.isNone, acc->Array.concat([(key, value, errorMessage)]))
      })

    setIsAllDynamicFieldValid(_ => isAllValid)
    setDynamicFieldsJson(_ => dynamicFieldsJson)
    None
  }, [finalJsonDict])

  React.useEffect0(() => {
    RequiredFieldsTypes.importStates("./../../utility/reusableCodeFromWeb/States.json")
    ->Promise.then(res => {
      setStatesJson(_ => Some(res.states))
      Promise.resolve()
    })
    ->Promise.catch(_ => Promise.resolve())
    ->ignore
    None
  })

  let filteredFields = displayPreValueFields
    ? requiredFields
    : requiredFields->RequiredFieldsTypes.filterDynamicFieldsFromRendering(initialKeysValArray)
  let (outsideBilling, insideBilling, shippingFields) = filteredFields->Array.reduce(([], [], []), (
    (outside, inside, shipping),
    item,
  ) => {
    let isBillingField =
      item.required_field
      ->RequiredFieldsTypes.getRequiredFieldName
      ->String.split(".")
      ->Array.includes("billing")
    let isShippingField =
      item.required_field
      ->RequiredFieldsTypes.getRequiredFieldName
      ->String.split(".")
      ->Array.includes("shipping")
    switch (isBillingField, isShippingField, renderShippingFields) {
    | (true, _, _) => (outside, inside->Array.concat([item]), shipping)
    | (_, true, true) => (outside, inside, shipping->Array.concat([item]))
    | (_, true, false) => (outside, inside, shipping)
    | _ => (outside->Array.concat([item]), inside, shipping)
    }
  })

  // Render nothing if no fields to display
  let renderFields = (fields, extraSpacing) =>
    fields->Array.length > 0
      ? <>
          {extraSpacing ? <Space height=24. /> : React.null}
          <Fields
            fields
            finalJsonDict
            setFinalJsonDict
            isSaveCardsFlow
            statesJson
            keyToTrigerButtonClickError
          />
        </>
      : React.null

  let renderSectionTitle = (title, show) =>
    show
      ? <Text style={textStyle(~color=component.color, ~fontSize=16., ~marginVertical=10.->dp, ())}>
          {title->React.string}
        </Text>
      : React.null

  <View style={viewStyle()}>
    {renderFields(outsideBilling, true)}
    <Space height=10. />
    {renderSectionTitle("Billing", insideBilling->Array.length > 0)}
    {renderFields(insideBilling, false)}
    <Space height=10. />
    {renderSectionTitle("Shipping", renderShippingFields && shippingFields->Array.length > 0)}
    {renderFields(shippingFields, false)}
  </View>
}
