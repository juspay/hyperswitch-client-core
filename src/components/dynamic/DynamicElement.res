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
  ~setCountry,
  ~onSubmit=?,
  ~accessible=?,
) => {
  let categorizedFields = React.useMemo1(() => {
    fields->Array.reduce(([], [], [], [], [], [], []), (
      (
        cardFields,
        emailFields,
        billingNameFields,
        billingPhoneFields,
        billingOtherFields,
        cryptoFields,
        otherFields,
      ),
      fieldConfig: SuperpositionTypes.fieldConfig,
    ) => {
      let fieldName = fieldConfig.name

      if fieldName->String.startsWith("card.") {
        cardFields->Array.push(fieldConfig)
      } else if fieldConfig.fieldType === EmailInput {
        emailFields->Array.push(fieldConfig)
      } else if (
        fieldName->String.includes("billing.address.first_name") ||
          fieldName->String.includes("billing.address.last_name")
      ) {
        billingNameFields->Array.push(fieldConfig)
      } else if (
        fieldConfig.fieldType === CountryCodeSelect || fieldConfig.fieldType === PhoneInput
      ) {
        billingPhoneFields->Array.push(fieldConfig)
      } else if fieldName->String.includes("billing.address.") {
        billingOtherFields->Array.push(fieldConfig)
      } else if fieldName->String.includes("crypto.") {
        cryptoFields->Array.push(fieldConfig)
      } else {
        otherFields->Array.push(fieldConfig)
      }
      (
        cardFields,
        emailFields,
        billingNameFields,
        billingPhoneFields,
        billingOtherFields,
        cryptoFields,
        otherFields,
      )
    })
  }, [fields])

  let (
    cardFields,
    emailFields,
    billingNameFields,
    billingPhoneFields,
    billingOtherFields,
    cryptoFields,
    otherFields,
  ) = categorizedFields

  let createFieldValidator = (validationRule: Validation.validationRule) => {
    Validation.createFieldValidator(validationRule, ~enabledCardSchemes)
  }

  let formatValue = Validation.formatValue

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
          fields=cardFields createFieldValidator formatValue enabledCardSchemes ?accessible
        />
        <GenericElement
          fields=otherFields createFieldValidator formatValue country setCountry ?accessible
        />
        <CryptoElement fields=cryptoFields createFieldValidator formatValue ?accessible />
        <MergedElement fields=emailFields createFieldValidator formatValue ?accessible />
        <AddressElement
          nameFields=billingNameFields
          billingFields=billingOtherFields
          phoneFields=billingPhoneFields
          createFieldValidator
          formatValue
          isCardPayment
          country
          setCountry
          ?accessible
        />
      </View>
    }}
  />
}
