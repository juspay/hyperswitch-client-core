open ReactNative
open Style

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~accessible=?,
) => {
  let {component, dangerColor, gap} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let getLocalized = key => GetLocale.lookupLocaleString(localeObject, key)

  let emailFields = fields->Array.filter((f: SuperpositionTypes.fieldConfig) =>
    switch f.fieldRenderType {
    | Email => true
    | _ => false
    }
  )

  let fieldData = emailFields->Array.map(fieldConfig => {
    let {input, meta} = ReactFinalForm.useField(
      fieldConfig.confirmRequestWritePath,
      ~config={validate: createFieldValidator(Validation.Email)},
    )
    (input, meta)
  })

  let onChangeArray = fieldData->Array.map(((input, _)) => input.onChange)

  switch fieldData->Array.get(0) {
  | Some((input, meta)) =>
    <React.Fragment>
      <View style={s({marginBottom: gap->dp})}>
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
              placeholder={emailFields
              ->Array.get(0)
              ->Option.map(f => FieldLabelResolver.resolvePlaceholder(f, getLocalized))
              ->Option.getOr("Email")}
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
