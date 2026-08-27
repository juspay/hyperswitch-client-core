open ReactNative

@react.component
let make = (
  ~fields,
  ~initialValues,
  ~setFormData,
  ~setIsFormValid,
  ~setIsPristine=?,
  ~setFormMethods,
  ~isCardPayment,
  ~enabledCardSchemes,
  ~accessible=?,
  ~onSubmit=?,
  ~isFocused: bool=false,
) => {
  let groups = React.useMemo1(() => FieldGrouper.groupFields(fields), [fields])

  let cardholderNameMode: VaultCardForm.cardholderNameMode = React.useMemo1(
    () =>
      fields->Array.some((f: SuperpositionTypes.fieldConfig) =>
        f.fieldRenderType === SuperpositionTypes.CardHolderName ||
          f.confirmRequestWritePath->String.endsWith("card_holder_name")
      )
        ? #"external"
        : #omit,
    [fields],
  )

  let localeObject = GetLocale.useGetLocalObj()

  let createFieldValidator = (validationRule: Validation.validationRule) => {
    Validation.createFieldValidator([validationRule], ~enabledCardSchemes, ~localeObject)
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
        ~onPristineChange=?setIsPristine,
        ~formProps,
      )
      React.useEffect0(() => {
        setFormMethods(Some(formProps.form))
        None
      })

      <View>
        <AddressEmitterInsideForm isFocused />
        {groups
        ->Array.map(element =>
          <ParentElement
            key={FieldGrouper.keyOf(element)}
            element
            createFieldValidator
            formatValue
            isCardPayment
            enabledCardSchemes
            ?accessible
            cardholderNameMode
          />
        )
        ->React.array}
      </View>
    }}
  />
}
