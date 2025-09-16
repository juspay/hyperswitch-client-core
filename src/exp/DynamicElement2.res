open ReactNative

@react.component
let make = (
  ~fields,
  ~initialValues: RescriptCore.Dict.t<RescriptCore.JSON.t>,
  ~onFormChange,
  ~onFormMethodsChange: ReactFinalForm.Form.formMethods => unit,
  ~onValidationChange,
  ~isCardPayment,
  ~enabledCardSchemes,
  ~country,
  ~onSubmit=?,
) => {
  let categorizedFields = React.useMemo1(() => {
    fields->Array.reduce(([], [], [], [], []), (
      (cardFields, billingNameFields, billingPhoneFields, billingOtherFields, otherFields),
      fieldConfig: SuperpositionTypes.fieldConfig,
    ) => {
      let fieldName = fieldConfig.name

      if fieldName->String.includes("card.") {
        cardFields->Array.push(fieldConfig)
      } else if (
        fieldName->String.includes("billing.address.first_name") ||
          fieldName->String.includes("billing.address.last_name")
      ) {
        billingNameFields->Array.push(fieldConfig)
      } else if (
        fieldName->String.includes("billing.phone.country_code") ||
          fieldName->String.includes("billing.phone.number")
      ) {
        billingPhoneFields->Array.push(fieldConfig)
      } else if fieldName->String.includes("billing.") {
        billingOtherFields->Array.push(fieldConfig)
      } else {
        otherFields->Array.push(fieldConfig)
      }
      (cardFields, billingNameFields, billingPhoneFields, billingOtherFields, otherFields)
    })
  }, [fields])

  let (
    cardFields,
    billingNameFields,
    billingPhoneFields,
    billingOtherFields,
    otherFields,
  ) = categorizedFields

  let createFieldValidatorLocal = React.useMemo1(() => {
    (validationRule: Validation.validationRule) => {
      Validation.createFieldValidator(validationRule, ~enabledCardSchemes)
    }
  }, [enabledCardSchemes])

  let formatValue = Validation.formatValue
  let createFieldValidator = Validation.createFieldValidator

  let formValidator = React.useMemo(() => {
    _ => Dict.make()
  }, [fields])

  <ReactFinalForm.Form
    onSubmit={ReactFinalForm.createSubmitHandler(onSubmit)}
    validate=Some(formValidator)
    initialValues={Some(initialValues)}
    render={formProps => {
      ReactFinalForm.useFormStateHandler(~onFormChange, ~onValidationChange, ~formProps)
      React.useEffect0(() => {
        onFormMethodsChange(formProps.form)
        None
      })

      <View>
        <CardElement
          fields={cardFields}
          createFieldValidator={createFieldValidatorLocal}
          formatValue
          enabledCardSchemes
        />
        <DynamicElement
          fields=otherFields createFieldValidator formatValue enabledCardSchemes country
        />
        <AddressElement2
          nameFields=billingNameFields
          billingFields=billingOtherFields
          phoneFields=billingPhoneFields
          createFieldValidatorLocal
          createFieldValidator
          formatValue
          isCardPayment
          enabledCardSchemes
          country
        />
      </View>
    }}
  />
}
