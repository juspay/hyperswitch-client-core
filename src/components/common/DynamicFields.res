open ReactNative
open Style

module RenderField = {
  @react.component
  let make = (
    ~required_fields_type: RequiredFieldsTypes.required_fields_type,
    ~setFinalJson,
    ~isSaveCardsFlow,
    ~statesJson: option<JSON.t>,
    ~country,
    ~finalJson: array<(string, JSON.t, bool)>,
  ) => {
    let {component} = ThemebasedStyle.useThemeBasedStyle()

    let (_, value, _) =
      finalJson
      ->Array.find(((key, _, _)) => {
        key === required_fields_type.required_field
      })
      ->Option.getOr(("", JSON.Encode.null, false))

    let initialValue = switch value->JSON.Decode.string->Option.getOr("") {
    | "" => None
    | value => Some(value)
    }
    let (val, setVal) = React.useState(_ => initialValue)

    React.useEffect2(() => {
      setVal(_ => initialValue)
      None
    }, (required_fields_type, isSaveCardsFlow))

    let (isValid, setIsValid) = React.useState(_ => None)
    let (isFocus, setisFocus) = React.useState(_ => false)
    React.useEffect1(() => {
      switch val {
      | Some(text) => {
          let tempValid = RequiredFieldsTypes.checkIsValid(
            ~text,
            ~field_type=required_fields_type.field_type,
          )
          setIsValid(_ => tempValid)
          setFinalJson(prev => {
            prev->Array.map(
              item => {
                let requiredFieldPath = RequiredFieldsTypes.getRequiredFieldPath(
                  ~isSaveCardsFlow,
                  ~requiredField={required_fields_type},
                )
                let (key, _, _) = item
                if key == requiredFieldPath {
                  (key, text->JSON.Encode.string, tempValid->Option.getOr(false))
                } else {
                  item
                }
              },
            )
          })
        }
      | None => ()
      }
      None
    }, [val])
    let onChangeCountry = val => {
      setVal(val)
    }
    let onChange = text => {
      setVal(_ => Some(text))
    }
    let isValidForFocus = {
      isFocus ? true : isValid->Option.getOr(true)
    }
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
          />
        | None => React.null
        }
      | _ =>
        <CustomInput
          state={val->Option.getOr("")}
          setState={text => onChange(text)}
          placeholder={placeholder()}
          keyboardType={RequiredFieldsTypes.getKeyboardType(
            ~field_type=required_fields_type.field_type,
          )}
          enableCrossIcon=false
          isValid=isValidForFocus
          onFocus={_ => {
            setisFocus(_ => true)
          }}
          onBlur={_ => {
            setisFocus(_ => false)
          }}
          textColor={component.color}
        />
      }}
      //    <Space />
    </>
  }
}
@react.component
let make = (
  ~requiredFields: RequiredFieldsTypes.required_fields,
  ~setIsAllDynamicFieldValid,
  ~setDynamicFieldsJson,
  ~isSaveCardsFlow=false,
  ~saveCardsData: option<SdkTypes.savedDataType>,
) => {
  let localeObject = GetLocale.useGetLocalObj()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let filteredRequiredFields =
    requiredFields->RequiredFieldsTypes.filterRequiredFields(isSaveCardsFlow, saveCardsData)

  let clientTimeZone = Utils.dateTimeFormat().resolvedOptions().timeZone
  let clientCountry = Utils.getClientCountry(clientTimeZone)

  let keysValArray =
    filteredRequiredFields->RequiredFieldsTypes.getKeysValArray(
      isSaveCardsFlow,
      clientCountry.isoAlpha2,
    )
  let (finalJson, setFinalJson) = React.useState(_ => keysValArray)

  React.useEffect2(() => {
    setFinalJson(_ => keysValArray)
    None
  }, (isSaveCardsFlow, saveCardsData))
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
      accumulator && key
    })
    setIsAllDynamicFieldValid(_ => temp)
    setDynamicFieldsJson(_ => finalJson)
    None
  }, [finalJson])

  let filteredRequiredFieldsFromRendering =
    filteredRequiredFields->RequiredFieldsTypes.filterDynamicFieldsFromRendering

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

  let (
    requiredFieldsOutsideBilling,
    requiredFieldsInsideBilling,
  ) = filteredRequiredFieldsFromRendering->Array.reduce(([], []), (
    (outsideBilling, insideBilling),
    item,
  ) => {
    let isBillingAvailable =
      item.required_field
      ->String.split(".")
      ->Array.get(0)
      ->Option.getOr("") == "billing"
    let _ = isBillingAvailable ? insideBilling->Array.push(item) : outsideBilling->Array.push(item)
    (outsideBilling, insideBilling)
  })

  {
    filteredRequiredFieldsFromRendering->Array.length > 0
      ? <View style={viewStyle()}>
          {requiredFieldsOutsideBilling->Array.length > 0
            ? <>
                {requiredFieldsOutsideBilling
                ->Array.mapWithIndex((item: RequiredFieldsTypes.required_fields_type, index) =>
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
                    />
                  </React.Fragment>
                )
                ->React.array}
              </>
            : React.null}
          {requiredFieldsInsideBilling->Array.length > 0
            ? <>
                <Space height=24. />
                <TextWrapper text=localeObject.billingDetails textType={SubheadingBold} />
                <Space height=8. />
                {requiredFieldsInsideBilling
                ->Array.mapWithIndex((item: RequiredFieldsTypes.required_fields_type, index) =>
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
                    />
                  </React.Fragment>
                )
                ->React.array}
              </>
            : React.null}
        </View>
      : React.null
  }
}
