open ReactNative
open Style
open Validation

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~enabledCardSchemes,
  ~country,
) => {
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)

  let getValidationRuleFromFieldType = (fieldType: SuperpositionTypes.fieldType) => {
    switch fieldType {
    | CardNumberTextInput => CardNumber
    | CvcPasswordInput => CardCVC("default")
    | DatePicker => CardExpiry
    | EmailInput => Email
    | PhoneInput => Phone
    | TextInput | PasswordInput => MinLength(1)
    | _ => MinLength(1)
    }
  }

  let createFieldValidatorLocal = React.useMemo1(() => {
    (validationRule: validationRule) => {
      createFieldValidator(validationRule, ~enabledCardSchemes)
    }
  }, [enabledCardSchemes])

  let renderFieldInput = (
    field: SuperpositionTypes.fieldConfig,
    {input, meta}: ReactFinalForm.Field.fieldProps,
  ) => {
    let handleInputChange = (value: string) => {
      let formattedValue = value //formatValue(value, field.fieldType)
      input.onChange(formattedValue)
    }
    let handlePickerChange = (value: unit => option<string>) => {
      input.onChange(value()->Option.getOr(""))
    }

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
          placeholder=field.displayName
          enableCrossIcon=false
          isValid={meta.error->Option.isNone || !meta.touched}
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
          textColor={meta.active || meta.error->Option.isNone || !meta.touched
            ? component.color
            : dangerColor}
        />
        {switch (meta.error, meta.touched) {
        | (Some(error), true) => <ErrorText text={Some(error)} />
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
          placeholderText=field.displayName
          isValid={meta.error->Option.isNone || !meta.touched}
          isLoading=false
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
          isCountryStateFields=true
        />
        {switch (meta.error, meta.touched) {
        | (Some(error), true) => <ErrorText text={Some(error)} />
        | _ => React.null
        }}
      </>
    | CountryCodeSelect =>
      <>
        <CustomPicker
          value={input.value->Option.getOr("")->Some}
          setValue=handlePickerChange
          items={switch countryStateData {
          | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
            AddressUtils.getPhoneCodeData(res.countries)
          | _ => []
          }}
          placeholderText=field.displayName
          isValid={meta.error->Option.isNone || !meta.touched}
          isLoading=false
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
          isCountryStateFields=true
        />
        {switch (meta.error, meta.touched) {
        | (Some(error), true) => <ErrorText text={Some(error)} />
        | _ => React.null
        }}
      </>
    | StateSelect =>
      <>
        <CustomPicker
          value=input.value
          setValue=handlePickerChange
          items={switch countryStateData {
          | FetchData(statesAndCountryVal) | Localdata(statesAndCountryVal) =>
            AddressUtils.getStateData(statesAndCountryVal.states, country)
          | _ => []
          }}
          placeholderText=field.displayName
          isValid={meta.error->Option.isNone || !meta.touched}
          isLoading=false
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
        />
        {switch (meta.error, meta.touched) {
        | (Some(error), true) => <ErrorText text={Some(error)} />
        | _ => React.null
        }}
      </>
    | CurrencySelect =>
      <>
        <CustomPicker
          value=input.value
          setValue=handlePickerChange
          items={field.options->Array.map(opt => {
            CustomPicker.label: opt,
            value: opt,
            icon: Utils.getCountryFlags(opt),
          })}
          placeholderText=field.displayName
          isValid={meta.error->Option.isNone || !meta.touched}
          isLoading=false
          onFocus={_ => input.onFocus()}
          onBlur={_ => input.onBlur()}
        />
        {switch (meta.error, meta.touched) {
        | (Some(error), true) => <ErrorText text={Some(error)} />
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
          validate=Some(createFieldValidatorLocal(getValidationRuleFromFieldType(field.fieldType)))>
          {fieldProps => renderFieldInput(field, fieldProps)}
        </ReactFinalForm.Field>
      </View>
    </React.Fragment>
  }
  {fields->Array.map(renderField)->React.array}
}
