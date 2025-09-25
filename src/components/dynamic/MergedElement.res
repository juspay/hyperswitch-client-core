open ReactNative
open Style

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~accessible=?,
) => {
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

  let fieldData = fields->Array.map(fieldConfig => {
    let {input, meta} = ReactFinalForm.useField(
      fieldConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.Email)},
      (),
    )
    (input, meta)
  })

  let onChangeArray = fieldData->Array.map(((input, _)) => input.onChange)

  switch fieldData->Array.get(0) {
  | Some((input, meta)) =>
    <React.Fragment>
      <View style={s({marginBottom: 16.->dp})}>
        {
          let handleInputChange = (value: string) => {
            onChangeArray->Array.forEach(onChange => {
              onChange(value)
            })
          }
          <>
            <CustomInput
              state={input.value->Option.getOr("")}
              setState=handleInputChange
              placeholder={GetLocale.getLocalString("Email")}
              enableCrossIcon=false
              isValid={meta.error->Option.isNone || !meta.touched || meta.active}
              onFocus={_ => {
                input.onFocus()
              }}
              onBlur={_ => {
                input.onBlur()
              }}
              textColor={meta.error->Option.isNone || !meta.touched || meta.active
                ? component.color
                : dangerColor}
              ?accessible
            />
            {switch (meta.error, meta.touched, meta.active) {
            | (Some(error), true, false) => <ErrorText text={Some(error)} />
            | _ => React.null
            }}
          </>
        }
      </View>
    </React.Fragment>
  | _ => React.null
  }
}
