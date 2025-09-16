open ReactNative
open Validation

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~initialValues: Dict.t<JSON.t>,
  ~onFormChange: Dict.t<JSON.t> => unit,
  ~onValidationChange: bool => unit,
  ~onSubmit: option<Dict.t<string> => unit>=?,
  ~onFormMethodsChange: option<ReactFinalForm.Form.formMethods => unit>=?,
  ~enabledCardSchemes: array<string>,
  ~country,
  ~isCardPayment,
  ~summaryComponent=?,
) => {
  let categorizedFields = React.useMemo1(() => {
    fields->Array.reduce(([], [], [], [], []), (
      (cardFields, billingNameFields, billingPhoneFields, billingOtherFields, otherFields),
      fieldConfig,
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
    (validationRule: validationRule) => {
      createFieldValidator(validationRule, ~enabledCardSchemes)
    }
  }, [enabledCardSchemes])

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
        <CardElement
          fields={cardFields}
          createFieldValidator={createFieldValidatorLocal}
          formatValue
          enabledCardSchemes
        />
        <DynamicElement
          fields=otherFields createFieldValidator formatValue enabledCardSchemes country
        />
        {switch summaryComponent {
        | Some(component) => component
        | None =>
          <>
            <FullNameElement
              fields={billingNameFields}
              createFieldValidator={createFieldValidatorLocal}
              formatValue
              isCardPayment
            />
            <DynamicElement
              fields=billingOtherFields createFieldValidator formatValue enabledCardSchemes country
            />
            <PhoneElement
              fields={billingPhoneFields}
              createFieldValidator={createFieldValidatorLocal}
              formatValue
            />
          </>
        }}
      </View>
    }}
  />
}
