open ReactNative
open Style

@react.component
let make = (
  ~value: ClickToPay.Types.phoneValue={phoneCode: "", phoneNumber: ""},
  ~onChange: ClickToPay.Types.phoneValue => unit,
  ~onValidationChange: bool => unit=_ => (),
  ~phoneCodePlaceholder="Phone Code",
  ~phoneNumberPlaceholder="Phone Number",
  ~showErrors=false,
  ~accessible=?,
) => {
  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let {country} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let localeObject = GetLocale.useGetLocalObj()

  let (phoneCodeError, setPhoneCodeError) = React.useState(_ => None)
  let (phoneNumberError, setPhoneNumberError) = React.useState(_ => None)
  let (phoneCodeTouched, setPhoneCodeTouched) = React.useState(_ => false)
  let (phoneNumberTouched, setPhoneNumberTouched) = React.useState(_ => false)
  let (phoneCodeActive, setPhoneCodeActive) = React.useState(_ => false)
  let (phoneNumberActive, setPhoneNumberActive) = React.useState(_ => false)

  let stripPlusFromCode = (code: string) => {
    code->String.startsWith("+") ? code->String.sliceToEnd(~start=1) : code
  }

  React.useEffect0(() => {
    let (code: string, phone) = switch countryStateData {
    | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
      switch value.phoneCode {
      | "" =>
        switch value.phoneNumber {
        | "" => (
            res.countries
            ->Array.find(countryData => countryData.country_code === country)
            ->Option.map(country => country.phone_number_code)
            ->Option.getOr(""),
            "",
          )
        | phoneNumber =>
          switch PhoneNumberValidation.formatPhoneNumber(phoneNumber, res.countries) {
          | ("", phone) => (
              res.countries
              ->Array.find(countryData => countryData.country_code === country)
              ->Option.map(country => country.phone_number_code)
              ->Option.getOr(""),
              phone,
            )
          | (code, phone) => (code, phone)
          }
        }
      | code => (code, value.phoneNumber)
      }
    | _ => ("", "")
    }
    let strippedCode = stripPlusFromCode(code)
    if strippedCode != value.phoneCode || phone != value.phoneNumber {
      onChange({phoneCode: strippedCode, phoneNumber: phone})
    }
    None
  })

  React.useEffect1(() => {
    let error = Validation.validateField(
      value.phoneCode,
      [Validation.Required],
      ~enabledCardSchemes=[],
      ~localeObject,
    )
    setPhoneCodeError(_ => error)
    None
  }, [value.phoneCode])

  React.useEffect1(() => {
    let error = Validation.validateField(
      value.phoneNumber,
      [Validation.Phone],
      ~enabledCardSchemes=[],
      ~localeObject,
    )
    setPhoneNumberError(_ => error)
    None
  }, [value.phoneNumber])

  React.useEffect2(() => {
    let isValid =
      phoneCodeError->Option.isNone &&
      phoneNumberError->Option.isNone &&
      value.phoneCode != "" &&
      value.phoneNumber != ""
    onValidationChange(isValid)
    None
  }, (phoneCodeError, phoneNumberError))

  <View style={s({marginBottom: 16.->dp})}>
    <View style={s({flexDirection: #row})}>
      {
        let handlePickerChange = (newValue: unit => option<string>) => {
          let code = newValue()->Option.getOr("")
          onChange({...value, phoneCode: stripPlusFromCode(code)})
        }
        <CustomPicker
          style={s({flex: 0.36})}
          value={Some(
            value.phoneCode == ""
              ? ""
              : value.phoneCode->String.startsWith("+")
              ? value.phoneCode
              : "+" ++ value.phoneCode,
          )}
          setValue=handlePickerChange
          items={switch countryStateData {
          | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) =>
            AddressUtils.getPhoneCodeData(res.countries)
          | _ => []
          }}
          placeholderText=phoneCodePlaceholder
          isValid={phoneCodeError->Option.isNone ||
          !(phoneCodeTouched || showErrors) ||
          phoneCodeActive}
          isLoading=false
          onFocus={_ => setPhoneCodeActive(_ => true)}
          onBlur={_ => {
            setPhoneCodeActive(_ => false)
            setPhoneCodeTouched(_ => true)
          }}
          isCountryStateFields=true
          showValue=true
          ?accessible
        />
      }
      <Space width=10. />
      {
        let handleInputChange = (newValue: string) => {
          onChange({...value, phoneNumber: newValue})
        }
        <CustomInput
          style={s({flex: 1.})}
          state={value.phoneNumber}
          setState=handleInputChange
          placeholder=phoneNumberPlaceholder
          enableCrossIcon=false
          isValid={phoneNumberError->Option.isNone ||
          !(phoneNumberTouched || showErrors) ||
          phoneNumberActive}
          onFocus={_ => setPhoneNumberActive(_ => true)}
          onBlur={_ => {
            setPhoneNumberActive(_ => false)
            setPhoneNumberTouched(_ => true)
          }}
          textColor={phoneNumberError->Option.isNone ||
          !(phoneNumberTouched || showErrors) ||
          phoneNumberActive
            ? component.color
            : dangerColor}
          ?accessible
        />
      }
    </View>
    {switch (phoneCodeError, phoneCodeTouched || showErrors, phoneCodeActive) {
    | (Some(error), true, false) => <ErrorText text={Some(error)} />
    | _ =>
      switch (phoneNumberError, phoneNumberTouched || showErrors, phoneNumberActive) {
      | (Some(error), true, false) => <ErrorText text={Some(error)} />
      | _ => React.null
      }
    }}
  </View>
}
