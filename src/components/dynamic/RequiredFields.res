open ReactNative
open ParentElement

@react.component
let make = (
  ~fields,
  ~initialValues,
  ~setFormData,
  ~setIsFormValid,
  ~setFormMethods,
  ~isCardPayment,
  ~enabledCardSchemes,
  ~accessible=?,
  ~onSubmit=?,
) => {
  let categorizedFields = React.useMemo1(() => {
    fields->Array.reduce(([], [], [], [], [], [], [], []), (
      (
        cardFields,
        emailFields,
        billingNameFields,
        billingPhoneFields,
        billingOtherFields,
        cryptoFields,
        datePickerFields,
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
      } else if fieldConfig.fieldType === DatePicker {
        datePickerFields->Array.push(fieldConfig)
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
        datePickerFields,
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
    datePickerFields,
    otherFields,
  ) = categorizedFields

  let elements = [
    CARD(cardFields),
    GENERIC(otherFields),
    CRYPTO(cryptoFields),
    EMAIL(emailFields),
    DATE(datePickerFields),
  ]

  let addressElements = [
    FULLNAME(billingNameFields),
    GENERIC(billingOtherFields),
    PHONE(billingPhoneFields),
  ]

  let localeObject = GetLocale.useGetLocalObj()

  let createFieldValidator = (validationRule: Validation.validationRule) => {
    Validation.createFieldValidator(validationRule, ~enabledCardSchemes, ~localeObject)
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
      ReactFinalForm.useFormStateHandler(
        ~onFormChange=setFormData,
        ~onValidationChange=setIsFormValid,
        ~formProps,
      )
      React.useEffect0(() => {
        setFormMethods(Some(formProps.form))
        None
      })

      <View>
        {elements
        ->Array.mapWithIndex((element, index) =>
          <ParentElement
            key={index->Int.toString}
            element
            createFieldValidator
            formatValue
            isCardPayment
            enabledCardSchemes
            ?accessible
          />
        )
        ->React.array}
        <AddressElement
          addressElements
          createFieldValidator
          formatValue
          isCardPayment
          enabledCardSchemes
          ?accessible
        />
      </View>
    }}
  />
}
