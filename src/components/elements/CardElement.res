open ReactNative
open Style

@react.component
let make = (~cardFields, ~createFieldValidator, ~renderFieldInput) => {
  let renderField = (field: SuperpositionTypes.fieldConfig) => {
    <React.Fragment key={field.outputPath}>
      <View style={s({marginBottom: 16.->dp})}>
        <ReactFinalForm.Field
          name=field.outputPath validate=Some(createFieldValidator(field.fieldType))>
          {fieldProps => renderFieldInput(field, fieldProps)}
        </ReactFinalForm.Field>
      </View>
    </React.Fragment>
  }

  {cardFields->Array.map(renderField)->React.array}
}
