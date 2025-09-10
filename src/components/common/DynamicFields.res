open ReactNative
open Style
open CardValidations
open EmailValidation

type selectOption = {
  label: string,
  value: string,
}

type existingValues = {
  billing: SdkTypes.addressDetails,
  shipping: SdkTypes.addressDetails,
}

type validationRule =
  | Required
  | MinLength(int)
  | MaxLength(int)
  | CardNumber
  | CVC(string)
  | ExpiryDate
  | Email

type displayMode =
  | Form
  | Summary

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~initialValues: Dict.t<JSON.t>,
  ~onFormChange: Dict.t<JSON.t> => unit,
  ~onValidationChange: bool => unit,
  ~onSubmit: option<Dict.t<string> => unit>=?,
  ~onFormMethodsChange: option<ReactFinalForm.Form.formMethods => unit>=?,
  ~cardNetworks: array<PaymentMethodListType.card_networks>,
  ~displayMode: displayMode=Form,
) => {
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

  let onChangePress = Some(
    () => {
      ()
    },
  )

  let fieldCheck = (fieldConfig: SuperpositionTypes.fieldConfig, value) =>
    fieldConfig.name->String.split(".")->Array.get(0)->Option.getOr("") === value
  let cardFieldCheck = (fieldConfig: SuperpositionTypes.fieldConfig) =>
    fieldCheck(fieldConfig, "card")
  let billingFieldCheck = (fieldConfig: SuperpositionTypes.fieldConfig) =>
    fieldCheck(fieldConfig, "billing")

  let cardFields = fields->Array.filter(cardFieldCheck)
  let billingFields = fields->Array.filter(billingFieldCheck)
  let otherFields =
    fields->Array.filter(fieldConfig =>
      !(["card", "billing"]->Array.includes(
        fieldConfig.name->String.split(".")->Array.get(0)->Option.getOr(""),
      ))
    )

  let validateField = (value: string, rules: array<validationRule>) => {
    rules->Array.reduce(None, (acc, rule) => {
      switch acc {
      | Some(_) => acc
      | None =>
        switch rule {
        | Required => {
            let trimmedValue = switch value {
            | "" => ""
            | v => v->String.trim
            }
            if trimmedValue === "" {
              Some("This field is required")
            } else {
              None
            }
          }
        | MinLength(min) =>
          if value->String.length < min {
            Some(`Minimum ${min->Int.toString} characters required`)
          } else {
            None
          }
        | MaxLength(max) =>
          if value->String.length > max {
            Some(`Maximum ${max->Int.toString} characters allowed`)
          } else {
            None
          }
        | CardNumber => {
            let enabledCardSchemes = PaymentUtils.getCardNetworks(cardNetworks->Some)
            let validCardBrand = Validation.getFirstValidCardScheme(
              ~cardNumber=value,
              ~enabledCardSchemes,
            )
            let cardBrand = validCardBrand === "" ? Validation.getCardBrand(value) : validCardBrand
            let num = formatCardNumber(value, cardType(cardBrand))
            Validation.cardValid(num, cardBrand) ? None : Some(`Enter a valid Card Number`)
          }
        | CVC(cardType) => {
            let cleanValue = value->clearSpaces
            let obj = getobjFromCardPattern(cardType)
            let minCVCLength = obj.cvcLength->Array.get(0)->Option.getOr(3)
            let maxCVCLength = obj.maxCVCLength
            if (
              cleanValue->String.length < minCVCLength || cleanValue->String.length > maxCVCLength
            ) {
              Some(`CVC must be ${minCVCLength->Int.toString}-${maxCVCLength->Int.toString} digits`)
            } else {
              None
            }
          }
        | ExpiryDate => {
            let (month, year) = value->splitExpiryDates
            let monthInt = month->Int.fromString->Option.getOr(0)
            let yearInt = year->Int.fromString->Option.getOr(0)

            if monthInt < 1 || monthInt > 12 {
              Some("Invalid month")
            } else if yearInt < 0 {
              Some("Invalid year")
            } else {
              None
            }
          }
        | Email =>
          switch value->isEmailValid {
          | Some(true) => None
          | Some(false) => Some("Invalid email address")
          | None => None
          }
        }
      }
    })
  }

  let createFieldValidator = (fieldType: SuperpositionTypes.fieldType) => {
    let rules = []
    rules->Array.push(Required)->ignore
    switch fieldType {
    | CardNumberTextInput => rules->Array.push(CardNumber)->ignore
    | CvcPasswordInput => rules->Array.push(CVC("default"))->ignore
    | EmailInput => rules->Array.push(Email)->ignore
    | DatePicker => rules->Array.push(ExpiryDate)->ignore
    | _ => ()
    }

    (value: option<string>) => {
      validateField(value->Option.getOr(""), rules)
    }
  }

  let getKeyboardType = (fieldType: SuperpositionTypes.fieldType) => {
    switch fieldType {
    | CardNumberTextInput => #numeric
    | CvcPasswordInput => #numeric
    | EmailInput => #"email-address"
    | PhoneInput => #"phone-pad"
    | _ => #default
    }
  }

  let getSecureTextEntry = (fieldType: SuperpositionTypes.fieldType) => {
    switch fieldType {
    | CvcPasswordInput => true
    | PasswordInput => true
    | _ => false
    }
  }

  let formatValue = (value: string, fieldType: SuperpositionTypes.fieldType) => {
    let cardBrand = Validation.getCardBrand(value)
    switch fieldType {
    | CardNumberTextInput => {
        let cleanValue = value->formatCardNumber(cardType(cardBrand))
        cleanValue
      }
    | CvcPasswordInput => value->formatCVCNumber(cardBrand)
    | DatePicker =>
      if value->String.includes("/") || value->String.length <= 5 {
        value->formatCardExpiryNumber
      } else {
        value
      }
    | _ => value
    }
  }

  let {payNowButtonColor} = ThemebasedStyle.useThemeBasedStyle()
  let (color, _) = payNowButtonColor

  let renderSummaryCard = (formProps: ReactFinalForm.Form.formProps) => {
    if billingFields->Array.length === 0 {
      React.null
    } else {
      let values = formProps.values
      let getNestedValue = (path: array<string>) => {
        path
        ->Array.reduce(Some(values->Js.Json.object_), (acc, key) => {
          acc->Option.flatMap(obj => obj->Utils.getDictFromJson->Dict.get(key))
        })
        ->Option.flatMap(JSON.Decode.string)
        ->Option.getOr("")
      }

      let firstName = getNestedValue(["payment_method_data", "billing", "address", "first_name"])
      let lastName = getNestedValue(["payment_method_data", "billing", "address", "last_name"])
      let line1 = getNestedValue(["payment_method_data", "billing", "address", "line1"])
      let city = getNestedValue(["payment_method_data", "billing", "address", "city"])
      let state = getNestedValue(["payment_method_data", "billing", "address", "state"])
      let zip = getNestedValue(["payment_method_data", "billing", "address", "zip"])
      let country = getNestedValue(["payment_method_data", "billing", "address", "country"])

      let fullName = [firstName, lastName]->Array.filter(s => s !== "")->Array.join(" ")
      let cityStateZip = [city, state, zip]->Array.filter(s => s !== "")->Array.join(", ")
      let fullAddress = [cityStateZip, country]->Array.filter(s => s !== "")->Array.join(" ")

      // line1 ++ city ++ state ++ zip != ""

      <View
        style={s({
          backgroundColor: "#f8f9fa",
          borderRadius: 12.,
          padding: 24.->dp,
          marginBottom: 8.->dp,
          borderWidth: 1.,
          borderColor: "#e9ecef",
        })}>
        <View
          style={s({
            flexDirection: #row,
            justifyContent: #"space-between",
            alignItems: #center,
          })}>
          <View>
            {fullName !== ""
              ? <Text
                  style={s({
                    fontSize: 16.,
                    fontWeight: #600,
                    color: "#212529",
                    marginBottom: 8.->dp,
                  })}>
                  {fullName->React.string}
                </Text>
              : React.null}
            {line1 !== ""
              ? <Text
                  style={s({
                    fontSize: 14.,
                    fontWeight: #400,
                    color: "#6c757d",
                    lineHeight: 20.,
                  })}>
                  {line1->React.string}
                </Text>
              : React.null}
            {fullAddress !== ""
              ? <Text
                  style={s({
                    fontSize: 14.,
                    fontWeight: #400,
                    color: "#6c757d",
                    lineHeight: 20.,
                  })}>
                  {fullAddress->React.string}
                </Text>
              : React.null}
          </View>
          {switch onChangePress {
          | Some(callback) =>
            <TouchableOpacity onPress={_ => callback()}>
              <Text style={s({fontSize: 14., color, fontWeight: #500})}>
                {"Change"->React.string}
              </Text>
            </TouchableOpacity>
          | None => React.null
          }}
        </View>
      </View>
    }
  }

  let renderFieldInput = (
    field: SuperpositionTypes.fieldConfig,
    {input, meta}: ReactFinalForm.Field.fieldProps,
  ) => {
    let handleInputChange = (value: string) => {
      let formattedValue = formatValue(value, field.fieldType)
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
    | DatePicker =>
      <>
        <CustomInput
          state={input.value->Option.getOr("")}
          setState=handleInputChange
          placeholder=field.displayName
          keyboardType={getKeyboardType(field.fieldType)}
          secureTextEntry={getSecureTextEntry(field.fieldType)}
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
    | MonthSelect | YearSelect | StateSelect | CountrySelect | CountryCodeSelect | CurrencySelect =>
      <>
        <CustomPicker
          value=input.value
          setValue=handlePickerChange
          items={field.options->Array.map(opt => {
            CustomPicker.label: opt,
            value: opt,
            icon: ?None,
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
          name=field.outputPath validate=Some(createFieldValidator(field.fieldType))>
          {fieldProps => renderFieldInput(field, fieldProps)}
        </ReactFinalForm.Field>
      </View>
    </React.Fragment>
  }

  let formValidator = React.useMemo(() => {
    _ => Dict.make()
  }, [fields])

  let handleSubmit = ReactFinalForm.createSubmitHandler(onSubmit)

  <ReactFinalForm.Form
    onSubmit=handleSubmit
    validate=Some(formValidator)
    initialValues={Some(initialValues)}
    render={formProps => {
      ReactFinalForm.useFormStateHandler(~onFormChange, ~onValidationChange, ~formProps)
      React.useEffect0(() => {
        switch onFormMethodsChange {
        | Some(callback) => callback(formProps.form)
        | None => ()
        }
        None
      })

      <View>
        <CardElement cardFields createFieldValidator renderFieldInput />
        {otherFields->Array.map(renderField)->React.array}
        {switch displayMode {
        | Summary => renderSummaryCard(formProps)
        | Form => billingFields->Array.map(renderField)->React.array
        }}
      </View>
    }}
  />
}
