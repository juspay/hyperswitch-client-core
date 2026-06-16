open ReactNative
open Style
open Validation

let isCountryDropdown = (field: SuperpositionTypes.fieldConfig) =>
  field.fieldRenderType === Country ||
    (field.fieldRenderType === Dropdown && field.confirmRequestWritePath->String.endsWith(".country"))

let isPhoneCodeDropdown = (field: SuperpositionTypes.fieldConfig) =>
  field.fieldRenderType === Dropdown && field.confirmRequestWritePath->String.endsWith(".country_code")

let isStateDropdown = (field: SuperpositionTypes.fieldConfig) =>
  field.fieldRenderType === State ||
    (field.fieldRenderType === Dropdown && field.confirmRequestWritePath->String.endsWith(".state"))

let toRnKeyboardType = (kb: option<string>) =>
  switch kb {
  | Some("numeric") => #numeric
  | Some("email-address") => #"email-address"
  | Some("phone-pad") => #"phone-pad"
  | Some(_) | None => #default
  }

let getValidationRuleForField = (field: SuperpositionTypes.fieldConfig) =>
  switch field.fieldRenderType {
  | CardNumber => CardNumber
  | Cvc => CardCVC("default")
  | Email => Email
  | Phone => Phone
  | CardExpiryMonth
  | CardExpiryYear
  | CardNetwork
  | PhoneCountryCode
  | CryptoCurrency
  | CryptoNetwork
  | Generic
  | Dropdown
  | Date
  | DateOfBirth
  | State
  | Country
  | FirstName
  | LastName
  | CardHolderName => Required(None)
  }

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~accessible=?,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {component, dangerColor, gap} = ThemebasedStyle.useThemeBasedStyle()
  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)
  let {country, setCountry} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let localeObject = GetLocale.useGetLocalObj()
  let getLocalized = key => GetLocale.lookupLocaleString(localeObject, key)

  let renderFieldInput = (
    field: SuperpositionTypes.fieldConfig,
    {input, meta}: ReactFinalForm.Field.fieldProps,
  ) => {
    let handleInputChange = (value: string) => {
      input.onChange(value)
    }
    let handlePickerChange = (value: unit => option<string>) => {
      let data = value()
      if isCountryDropdown(field) {
        setCountry(Some(data->Option.getOr(nativeProp.sdkParams.country)))
        setTimeout(() => {
          input.onChange(data->Option.getOr(nativeProp.sdkParams.country))
        }, 0)->ignore
      } else {
        input.onChange(data->Option.getOr(""))
      }
    }

    let placeholder = FieldLabelResolver.resolvePlaceholder(field, getLocalized)

    switch field.fieldRenderType {
    | Country | Dropdown if isCountryDropdown(field) =>
      <>
        <CustomPicker
          value=input.value
          setValue=handlePickerChange
          items={switch countryStateData {
          | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
            field.dropdownOptions->Option.getOr([])->AddressUtils.getCountryData(res.countries)
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
    | Dropdown if isPhoneCodeDropdown(field) =>
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
    | State | Dropdown if isStateDropdown(field) => {
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
      }
    | Dropdown if field.dropdownOptions->Option.getOr([])->Array.length > 0 => {
        let isLanguageDropdown =
          field.confirmRequestWritePath->String.includes("language_preference")
        <>
          <CustomPicker
            value=input.value
            setValue=handlePickerChange
            items={field.dropdownOptions->Option.getOr([])->Array.map(opt => {
              SdkTypes.label: isLanguageDropdown
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
    | _ =>
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
          maxLength={field.maxInputLength}
          keyboardType={toRnKeyboardType(field.keyboardType)}
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
    <React.Fragment key={field.confirmRequestWritePath}>
      <View style={s({marginBottom: gap->dp})}>
        <ReactFinalForm.Field
          name=field.confirmRequestWritePath
          validate=Some(createFieldValidator(getValidationRuleForField(field)))>
          {fieldProps => renderFieldInput(field, fieldProps)}
        </ReactFinalForm.Field>
      </View>
    </React.Fragment>
  }
  {fields
  ->Array.filter((field: SuperpositionTypes.fieldConfig) =>
    switch field.fieldRenderType {
    | Generic | Dropdown | Country | State => true
    | _ => false
    }
  )
  ->Array.map(renderField)
  ->React.array}
}
