open ReactNative
open Style

module CombinedNameInput = {
  @react.component
  let make = (
    ~firstNameConfig: SuperpositionTypes.fieldConfig,
    ~lastNameConfig: SuperpositionTypes.fieldConfig,
    ~createFieldValidator,
    ~isCardPayment,
    ~accessible=?,
  ) => {
    let {component, dangerColor, gap} = ThemebasedStyle.useThemeBasedStyle()
    let {input: firstNameInput, meta: firstNameMeta} = ReactFinalForm.useField(
      firstNameConfig.confirmRequestWritePath,
      ~config={
        validate: createFieldValidator(
          FieldValidationResolver.resolveRule(firstNameConfig, ~fallback=Validation.FirstName),
        ),
      },
    )
    let {input: lastNameInput, meta: lastNameMeta} = ReactFinalForm.useField(
      lastNameConfig.confirmRequestWritePath,
      ~config={
        validate: createFieldValidator(
          FieldValidationResolver.resolveRule(lastNameConfig, ~fallback=Validation.LastName),
        ),
      },
    )
    let (inputValue, setInputValue) = React.useState(() => "")
    React.useEffect2(() => {
      let firstName = firstNameInput.value->Option.getOr("")
      let lastName = lastNameInput.value->Option.getOr("")
      let combined = if firstName != "" && lastName != "" {
        firstName ++ " " ++ lastName
      } else if firstName != "" {
        firstName
      } else {
        lastName
      }
      setInputValue(_ => combined)
      None
    }, (firstNameInput.value, lastNameInput.value))
    let handleInputChange = (value: string) => {
      setInputValue(_ => value)
      let spaceIndex = value->String.indexOf(" ")
      if spaceIndex === -1 {
        firstNameInput.onChange(value)
        lastNameInput.onChange("")
      } else {
        let firstName = value->String.substring(~start=0, ~end=spaceIndex)
        let lastName = value->String.substringToEnd(~start=spaceIndex + 1)
        firstNameInput.onChange(firstName)
        lastNameInput.onChange(lastName)
      }
    }
    <View style={s({marginBottom: gap->dp})}>
      <CustomInput
        state=inputValue
        setState=handleInputChange
        placeholder={isCardPayment ? "Card Holder Name" : "Full Name"}
        enableCrossIcon=false
        isValid={firstNameMeta.error->Option.isNone ||
        !lastNameMeta.touched ||
        lastNameMeta.active ||
        lastNameMeta.error->Option.isNone}
        onFocus={_ => lastNameInput.onFocus()}
        onBlur={_ => lastNameInput.onBlur()}
        textColor={firstNameMeta.error->Option.isNone &&
          (lastNameMeta.active || lastNameMeta.error->Option.isNone || !lastNameMeta.touched)
          ? component.color
          : dangerColor}
        ?accessible
      />
      {switch (firstNameMeta.error, lastNameMeta.touched, lastNameMeta.active) {
      | (Some(error), true, false) => <ErrorText text={Some(error)} />
      | _ =>
        switch (lastNameMeta.error, lastNameMeta.touched, lastNameMeta.active) {
        | (Some(error), true, false) => <ErrorText text={Some(error)} />
        | _ => React.null
        }
      }}
    </View>
  }
}

module SingleNameInput = {
  @react.component
  let make = (~config: SuperpositionTypes.fieldConfig, ~createFieldValidator, ~accessible=?) => {
    let {component, dangerColor, gap} = ThemebasedStyle.useThemeBasedStyle()
    let localeObject = GetLocale.useGetLocalObj()
    let getLocalized = key => GetLocale.lookupLocaleString(localeObject, key)
    let validationRule = switch config.fieldRenderType {
    | FirstName => Validation.FirstName
    | LastName => Validation.LastName
    | _ => Validation.Required(None)
    }
    let {input, meta} = ReactFinalForm.useField(
      config.confirmRequestWritePath,
      ~config={
        validate: createFieldValidator(
          FieldValidationResolver.resolveRule(config, ~fallback=validationRule),
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
  ~isCardPayment,
  ~accessible=?,
) => {
  let sortedNameFields = fields->Array.copy
  sortedNameFields->Array.sort((a, b) => Int.compare(a.fieldDisplayOrder, b.fieldDisplayOrder))
  switch (sortedNameFields->Array.get(0), sortedNameFields->Array.get(1)) {
  | (Some(firstNameConfig), Some(lastNameConfig)) =>
    let extraNameFields = sortedNameFields->Array.sliceToEnd(~start=2)
    <>
      <CombinedNameInput
        firstNameConfig lastNameConfig createFieldValidator isCardPayment ?accessible
      />
      {extraNameFields
      ->Array.map(config =>
        <SingleNameInput
          key={config.confirmRequestWritePath} config createFieldValidator ?accessible
        />
      )
      ->React.array}
    </>
  | (Some(config), None) => <SingleNameInput config createFieldValidator ?accessible />
  | (None, _) => React.null
  }
}
