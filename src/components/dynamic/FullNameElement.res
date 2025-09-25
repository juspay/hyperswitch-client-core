open ReactNative
open Style
@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~isCardPayment,
  ~accessible=?,
) => {
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  switch (fields->Array.get(0), fields->Array.get(1)) {
  | (Some(firstNameConfig), Some(lastNameConfig)) =>
    let {input: firstNameInput, meta: firstNameMeta} = ReactFinalForm.useField(
      firstNameConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.FirstName)},
      (),
    )
    let {input: lastNameInput, meta: lastNameMeta} = ReactFinalForm.useField(
      lastNameConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.LastName)},
      (),
    )
    <React.Fragment>
      <View style={s({marginBottom: 16.->dp})}>
        {
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
          <>
            <CustomInput
              state=inputValue
              setState=handleInputChange
              placeholder={isCardPayment ? "Card Holder Name" : "Full Name"}
              enableCrossIcon=false
              isValid={firstNameMeta.error->Option.isNone ||
              !lastNameMeta.touched ||
              lastNameMeta.active ||
              lastNameMeta.error->Option.isNone}
              onFocus={_ => {
                lastNameInput.onFocus()
              }}
              onBlur={_ => {
                lastNameInput.onBlur()
              }}
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
          </>
        }
      </View>
    </React.Fragment>
  | _ => React.null
  }
}
