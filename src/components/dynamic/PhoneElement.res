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

  switch (fields->Array.get(0), fields->Array.get(1)) {
  | (Some(phoneCodeConfig), Some(phoneNumberConfig)) =>
    let {input: phoneCodeInput, meta: phoneCodeMeta} = ReactFinalForm.useField(
      phoneCodeConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.Required)},
      (),
    )

    let {input: phoneNumberInput, meta: phoneNumberMeta} = ReactFinalForm.useField(
      phoneNumberConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.Required)},
      (),
    )
    <React.Fragment>
      <View style={s({marginBottom: 16.->dp})}>
        <View style={s({flexDirection: #row})}>
          {
            let handlePickerChange = (value: unit => option<string>) => {
              phoneCodeInput.onChange(value()->Option.getOr(""))
            }
            <CustomPicker
              style={s({flex: 0.36})}
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
