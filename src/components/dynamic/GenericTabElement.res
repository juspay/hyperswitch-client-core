open ReactNative
open Style
open Validation

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~accessible=?,
) => {
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)
  let {country, setCountry} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let getValidationRuleFromFieldType = (fieldType: SuperpositionTypes.fieldType) => {
    switch fieldType {
    | CardNumberTextInput => CardNumber
    | CvcPasswordInput => CardCVC("default")
    | EmailInput => Email
    | PhoneInput => Phone
    // | TextInput | PasswordInput => MinLength(1)
    | _ => Required
    }
  }

  let renderFieldInput = (
    field: SuperpositionTypes.fieldConfig,
    {input, meta}: ReactFinalForm.Field.fieldProps,
  ) => {
    React.useEffect0(() => {
      switch field.fieldType {
      | CountrySelect =>
        let inputVal =
          field.options->Array.includes(country)
            ? country
            : field.options->Array.get(0)->Option.getOr(AddressUtils.defaultCountry)
        let timeoutId = setTimeout(() => {
          input.onChange(inputVal)
        }, 300)

        Some(() => clearTimeout(timeoutId))
      | _ => None
      }
    })

    let handleInputChange = (value: string) => {
      let formattedValue = value //formatValue(value, field.fieldType)
      input.onChange(formattedValue)
    }
    let handlePickerChange = (value: unit => option<string>) => {
      let data = value()->Option.getOr("")
      switch field.fieldType {
      | CountrySelect =>
        setCountry(data)
        setTimeout(() => {
          input.onChange(data)
        }, 0)->ignore
      | _ => input.onChange(data)
      }
    }

    let placeholder = GetLocale.getLocalString(field.displayName)

    switch field.fieldType {
    | CardNumberTextInput
    | CvcPasswordInput
    | TextInput
    | PasswordInput
    | EmailInput
    | PhoneInput
    | MonthSelect
    | YearSelect
    | DatePicker =>
      <>
        <CustomInput
          state={input.value->Option.getOr("")}
          setState=handleInputChange
          placeholder
          enableCrossIcon=false
          isValid={meta.error->Option.isNone || !meta.touched || meta.active}
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
          textColor={meta.error->Option.isNone || !meta.touched || meta.active
            ? component.color
            : dangerColor}
          ?accessible
        />
        {switch (meta.error, meta.touched, meta.active) {
        | (Some(error), true, false) => <ErrorText text={Some(error)} />
        | _ => React.null
        }}
      </>
    | CountrySelect =>
      <>
        <CustomPicker
          value=input.value
          setValue=handlePickerChange
          items={switch countryStateData {
          | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
            field.options->AddressUtils.getCountryData(res.countries)
          | _ => []
          }}
          placeholderText=placeholder
          isValid={meta.error->Option.isNone || !meta.touched || meta.active}
          isLoading=false
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
          isCountryStateFields=true
          ?accessible
        />
        {switch (meta.error, meta.touched, meta.active) {
        | (Some(error), true, false) => <ErrorText text={Some(error)} />
        | _ => React.null
        }}
      </>
    | CountryCodeSelect =>
      <>
        <CustomPicker
          value={input.value}
          setValue=handlePickerChange
          items={switch countryStateData {
          | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
            AddressUtils.getPhoneCodeData(res.countries)
          | _ => []
          }}
          placeholderText=placeholder
          isValid={meta.error->Option.isNone || !meta.touched || meta.active}
          isLoading=false
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
          isCountryStateFields=true
          ?accessible
        />
        {switch (meta.error, meta.touched, meta.active) {
        | (Some(error), true, false) => <ErrorText text={Some(error)} />
        | _ => React.null
        }}
      </>
    | StateSelect =>
      let items = switch countryStateData {
      | FetchData(statesAndCountryVal) | Localdata(statesAndCountryVal) =>
        AddressUtils.getStateData(statesAndCountryVal.states, country)
      | _ => []
      }
      <>
        <CustomPicker
          value={switch input.value {
          | None | Some("") => input.value
          | Some(value) =>
            items->Array.find(c => c.value === value || c.label === value)->Option.map(c => c.label)
          }}
          setValue=handlePickerChange
          items
          placeholderText=placeholder
          isValid={meta.error->Option.isNone || !meta.touched || meta.active}
          isLoading=false
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
          ?accessible
        />
        {switch (meta.error, meta.touched, meta.active) {
        | (Some(error), true, false) => <ErrorText text={Some(error)} />
        | _ => React.null
        }}
      </>
    | CurrencySelect | DropdownSelect =>
      <>
        <CustomPicker
          value=input.value
          setValue=handlePickerChange
          items={field.options->Array.map(opt => {
            SdkTypes.label: placeholder === "Language"
              ? `${LocaleDataType.localeStringToLocaleName(opt)} - ${opt}`
              : opt,
            value: opt,
          })}
          placeholderText=placeholder
          isValid={meta.error->Option.isNone || !meta.touched || meta.active}
          isLoading=false
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
          ?accessible
        />
        {switch (meta.error, meta.touched, meta.active) {
        | (Some(error), true, false) => <ErrorText text={Some(error)} />
        | _ => React.null
        }}
      </>
    }
  }

  let renderField = (field: SuperpositionTypes.fieldConfig) => {
    <React.Fragment key={field.outputPath}>
      <View style={s({marginBottom: 16.->dp})}>
        <ReactFinalForm.Field
          name=field.outputPath
          validate=Some(createFieldValidator(getValidationRuleFromFieldType(field.fieldType)))>
          {fieldProps => renderFieldInput(field, fieldProps)}
        </ReactFinalForm.Field>
      </View>
    </React.Fragment>
  }
  {fields->Array.map(renderField)->React.array}
}
