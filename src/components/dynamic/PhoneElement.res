open ReactNative
open Style

module SinglePhoneInput = {
  @react.component
  let make = (
    ~config: SuperpositionTypes.fieldConfig,
    ~createFieldValidator,
    ~getLocalized,
    ~accessible=?,
  ) => {
    let {component, dangerColor, gap} = ThemebasedStyle.useThemeBasedStyle()
    let {input, meta} = ReactFinalForm.useField(
      config.confirmRequestWritePath,
      ~config={
        validate: createFieldValidator(
          FieldValidationResolver.resolveRule(config, ~fallback=Validation.Phone),
        ),
      },
    )
    <View style={s({marginBottom: gap->dp})}>
      <CustomInput
        state={input.value->Option.getOr("")}
        setState={value => input.onChange(value)}
        placeholder={FieldLabelResolver.resolvePlaceholder(config, getLocalized)}
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
    </View>
  }
}

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~accessible=?,
) => {
  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)
  let {component, dangerColor, gap} = ThemebasedStyle.useThemeBasedStyle()

  let {country} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let localeObject = GetLocale.useGetLocalObj()
  let getLocalized = key => GetLocale.lookupLocaleString(localeObject, key)
  let phoneCodeConfig =
    fields->Array.find((f: SuperpositionTypes.fieldConfig) =>
      f.fieldRenderType === SuperpositionTypes.PhoneCountryCode
    )
  let phoneNumberConfig =
    fields->Array.find((f: SuperpositionTypes.fieldConfig) =>
      f.fieldRenderType === SuperpositionTypes.Phone
    )
  switch (phoneCodeConfig, phoneNumberConfig) {
  | (Some(phoneCodeConfig), Some(phoneNumberConfig)) =>
    let {input: phoneCodeInput, meta: phoneCodeMeta} = ReactFinalForm.useField(
      phoneCodeConfig.confirmRequestWritePath,
      ~config={
        validate: createFieldValidator(
          FieldValidationResolver.resolveRule(phoneCodeConfig, ~fallback=Validation.Required(None)),
        ),
      },
    )

    let {input: phoneNumberInput, meta: phoneNumberMeta} = ReactFinalForm.useField(
      phoneNumberConfig.confirmRequestWritePath,
      ~config={
        validate: createFieldValidator(
          FieldValidationResolver.resolveRule(phoneNumberConfig, ~fallback=Validation.Phone),
        ),
      },
    )

    React.useEffect1(() => {
      let (code, phone) = switch countryStateData {
      | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
        switch phoneCodeInput.value {
        | None | Some("") =>
          switch phoneNumberInput.value {
          | None | Some("") => (
              res.countries
              ->Array.find(countryData => countryData.country_code === country)
              ->Option.map(country => country.phone_number_code),
              None,
            )
          | Some(phoneNumber) =>
            switch PhoneNumberValidation.formatPhoneNumber(phoneNumber, res.countries) {
            | ("", phone) => (
                res.countries
                ->Array.find(countryData => countryData.country_code === country)
                ->Option.map(country => country.phone_number_code),
                Some(phone),
              )
            | (code, phone) => (Some(code), Some(phone))
            }
          }
        | Some(code) => (Some(code), phoneNumberInput.value)
        }
      | _ => (None, None)
      }

      let timeoutId = setTimeout(() => {
        switch code {
        | None | Some("") => ()
        | Some(code) => phoneCodeInput.onChange(code)
        }

        switch phone {
        | None | Some("") => ()
        | Some(phone) => phoneNumberInput.onChange(phone)
        }
      }, 300)

      Some(() => clearTimeout(timeoutId))
    }, [countryStateData])

    <React.Fragment>
      <View style={s({marginBottom: gap->dp})}>
        <View style={s({flexDirection: #row})}>
          {
            let handlePickerChange = (value: unit => option<string>) => {
              phoneCodeInput.onChange(value()->Option.getOr(""))
            }
            <CustomPicker
              style={s({flex: 0.36, minWidth: 25.->dp})}
              value=phoneCodeInput.value
              setValue=handlePickerChange
              items={switch countryStateData {
              | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
                AddressUtils.getPhoneCodeData(res.countries)
              | _ => []
              }}
              placeholderText={FieldLabelResolver.resolvePlaceholder(phoneCodeConfig, getLocalized)}
              isValid={phoneCodeMeta.error->Option.isNone ||
              !phoneCodeMeta.touched ||
              phoneCodeMeta.active}
              isLoading=false
              onFocus={_ => phoneCodeInput.onFocus()}
              onBlur={_ => phoneCodeInput.onBlur()}
              isCountryStateFields=true
              showValue=true
              ?accessible
            />
          }
          <Space width=10. />
          {
            let handleInputChange = (value: string) => {
              phoneNumberInput.onChange(value)
            }
            <CustomInput
              style={s({flex: 1.})}
              state={phoneNumberInput.value->Option.getOr("")}
              setState=handleInputChange
              placeholder={FieldLabelResolver.resolvePlaceholder(phoneNumberConfig, getLocalized)}
              enableCrossIcon=false
              isValid={phoneNumberMeta.error->Option.isNone ||
              !phoneNumberMeta.touched ||
              phoneNumberMeta.active}
              onFocus={_ => {
                phoneNumberInput.onFocus()
              }}
              onBlur={_ => {
                phoneNumberInput.onBlur()
              }}
              textColor={phoneNumberMeta.error->Option.isNone ||
              !phoneNumberMeta.touched ||
              phoneNumberMeta.active
                ? component.color
                : dangerColor}
              ?accessible
            />
          }
        </View>
        {switch (phoneCodeMeta.error, phoneCodeMeta.touched, phoneCodeMeta.active) {
        | (Some(error), true, false) => <ErrorText text={Some(error)} />
        | _ =>
          switch (phoneNumberMeta.error, phoneNumberMeta.touched, phoneNumberMeta.active) {
          | (Some(error), true, false) => <ErrorText text={Some(error)} />
          | _ => React.null
          }
        }}
      </View>
    </React.Fragment>
  | (None, Some(phoneNumberConfig)) =>
    <SinglePhoneInput config=phoneNumberConfig createFieldValidator getLocalized ?accessible />
  | (Some(_), None) | (None, None) => React.null
  }
}
