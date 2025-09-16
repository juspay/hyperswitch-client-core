open ReactNative
open Style

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~isCardPayment,
) => {
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

  switch (fields->Array.get(0), fields->Array.get(1)) {
  | (Some(firstNameConfig), Some(lastNameConfig)) =>
    let {input: firstNameInput, meta: firstNameMeta} = ReactFinalForm.useField(
      firstNameConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.FullName)},
      (),
    )

    let {input: lastNameInput, meta: lastNameMeta} = ReactFinalForm.useField(
      lastNameConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.FullName)},
      (),
    )
    <React.Fragment>
      <View style={s({marginBottom: 16.->dp})}>
        {
          let state = Utils.getCombinedFirstAndLast(
            ~first=firstNameInput.value,
            ~last=lastNameInput.value,
            ~delimiter=" ",
          )

          let handleInputChange = (value: string) => {
            let split = value->String.split(" ")
            firstNameInput.onChange(split->Array.get(0)->Option.getOr(""))
            lastNameInput.onChange(split->Array.get(1)->Option.getOr(""))
          }
          <>
            <CustomInput
              state
              setState=handleInputChange
              placeholder={isCardPayment ? "Card Holder Name" : "Full Name"}
              enableCrossIcon=false
              isValid={firstNameMeta.error->Option.isNone ||
              !firstNameMeta.touched ||
              lastNameMeta.error->Option.isNone}
              onFocus={_ => {
                firstNameInput.onFocus()
                lastNameInput.onFocus()
              }}
              onBlur={_ => {
                firstNameInput.onBlur()
                lastNameInput.onBlur()
              }}
              textColor={firstNameMeta.active ||
              firstNameMeta.error->Option.isNone ||
              !firstNameMeta.touched ||
              lastNameMeta.active ||
              lastNameMeta.error->Option.isNone ||
              !lastNameMeta.touched
                ? component.color
                : dangerColor}
            />
            {switch (firstNameMeta.error, firstNameMeta.touched) {
            | (Some(error), true) => <ErrorText text={Some(error)} />
            | _ =>
              switch (lastNameMeta.error, lastNameMeta.touched) {
              | (Some(error), true) => <ErrorText text={Some(error)} />
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
