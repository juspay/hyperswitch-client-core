open ReactNative
open Style

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~accessible=?,
) => {
  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

  let {country} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  switch (fields->Array.get(0), fields->Array.get(1)) {
  | (Some(phoneCodeConfig), Some(phoneNumberConfig)) =>
    let {input: phoneCodeInput, meta: phoneCodeMeta} = ReactFinalForm.useField(
      phoneCodeConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.Required)},
      (),
    )

    let {input: phoneNumberInput, meta: phoneNumberMeta} = ReactFinalForm.useField(
      phoneNumberConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.Phone)},
      (),
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
      <View style={s({marginBottom: 16.->dp})}>
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
              placeholderText=phoneCodeConfig.displayName
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
              let formattedValue = value //formatValue(value, phoneNumberConfig.fieldType)
              phoneNumberInput.onChange(formattedValue)
            }
            <CustomInput
              style={s({flex: 1.})}
              state={phoneNumberInput.value->Option.getOr("")}
              setState=handleInputChange
              placeholder={GetLocale.getLocalString(phoneNumberConfig.displayName)}
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
  | _ => React.null
  }
}
