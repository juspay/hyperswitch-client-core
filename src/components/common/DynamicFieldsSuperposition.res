open ReactNative
open Style
open SuperpositionHelper
open ReactFinalForm

// Creates React-compatible synthetic events for ReactFinalForm integration
let createSyntheticEvent = (_value: string): ReactEvent.Form.t => {
  %raw(`{target: {value: _value}}`)
}

let validateEmailAdapter = (value: option<string>, _formObject: JSON.t, _fieldConfig: fieldConfig) => {
  let email = value->Option.getOr("")->String.trim
  
  if email->String.length == 0 {
    None 
  } else {
    switch email->EmailValidation.isEmailValid {
    | Some(false) => Some("Please enter a valid email address")
    | Some(true) => None
    | None => None
    }
  }
}

let getValidationFunction = (field: fieldConfig) => {
  if field.outputPath->String.endsWith("email") || field.fieldType == "email_input" {
    Some(validateEmailAdapter)
  } else {
    None
  }
}

let renderFieldByType = (field: fieldConfig, input: ReactFinalForm.fieldRenderPropsInput, meta: ReactFinalForm.fieldRenderPropsMeta) => {
  switch field.fieldType {
  | "text_input" =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
    />
  | "email_input" =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
      keyboardType=#"email-address"
    />
  | "password_input" =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
      secureTextEntry={true}
    />
  | "phone_input" =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
      keyboardType=#"phone-pad"
    />
  | "country_select" =>
    <CustomPicker
      value={Some(input.value->JSON.Decode.string->Option.getOr(""))}
      setValue={_ => ()}
      onChange={input.onChange}
      items={field.options->Array.map(option => {
        CustomPicker.label: option,
        value: option,
        icon: Utils.getCountryFlags(option),
      })}
      placeholderText={field.displayName}
      isValid={meta.valid}
    />
  | "country_code_select" | "dropdown_select" | "currency_select" =>
    <CustomPicker
      value={Some(input.value->JSON.Decode.string->Option.getOr(""))}
      setValue={_ => ()}
      onChange={input.onChange}
      items={field.options->Array.map(option => {
        CustomPicker.label: option,
        value: option,
        icon: Utils.getCountryFlags(option),
      })}
      placeholderText={field.displayName}
      isValid={meta.valid}
    />
  | "month_select" =>
    // For now, use text input for month selection - can be enhanced later with CustomPicker
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
      keyboardType=#"numeric"
    />
  | "year_select" =>
    // For now, use text input for year selection - can be enhanced later with CustomPicker
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
      keyboardType=#"numeric"
    />
  | "date_picker" =>
    // For now, use text input for date picker - can be enhanced later
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
    />
  | _ =>
    <CustomInput
      state={input.value->JSON.Decode.string->Option.getOr("")}
      setState={_ => ()}
      onChange={input.onChange}
      placeholder={field.displayName}
      isValid={meta.valid}
    />
  }
}

@react.component
let make = (~componentWiseRequiredFields: array<(string, array<fieldConfig>)>) => {
  <View style={Style.empty}>
    <ReactFinalForm.Form
      onSubmit={(_, _) => Promise.resolve(Nullable.null)}
      render={_ =>
        <View>
          {componentWiseRequiredFields
          ->Array.mapWithIndex((componentWithField, index) => {
            let (componentName, fields) = componentWithField
            switch componentName {
            | "card" =>
              <View key={index->Int.toString}>
                <CardFieldsComponent fields={fields} createSyntheticEvent={createSyntheticEvent} />
              </View>
            | "billing" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                <Space height=15. />
                  <TextWrapper text="Billing Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    validate={
                      switch getValidationFunction(field) {
                      | Some(validationFn) => (value, formObject) => {
                          let error = validationFn(value, formObject, field)
                          Promise.resolve(error->Nullable.fromOption)
                        }
                      | None => (_, _) => Promise.resolve(Nullable.null)
                      }
                    }
                    render={({input, meta}) => {
                      let fieldName = getFieldNameFromOutputPath(field.outputPath)
                      let fieldType = field.fieldType
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {switch fieldName {
                        | "email" =>
                          <CustomInput
                            state={input.value->JSON.Decode.string->Option.getOr("")}
                            setState={_ => ()}
                            onChange={input.onChange}
                            placeholder="Email Address"
                            isValid={meta.valid}
                            keyboardType=#"email-address"
                          />
                        | "line1" =>
                          <CustomInput
                            state={input.value->JSON.Decode.string->Option.getOr("")}
                            setState={_ => ()}
                            onChange={input.onChange}
                            placeholder="Address Line 1"
                            isValid={meta.valid}
                          />
                        | "line2" =>
                          <CustomInput
                            state={input.value->JSON.Decode.string->Option.getOr("")}
                            setState={_ => ()}
                            onChange={input.onChange}
                            placeholder="Address Line 2"
                            isValid={meta.valid}
                          />
                        | "city" =>
                          <CustomInput
                            state={input.value->JSON.Decode.string->Option.getOr("")}
                            setState={_ => ()}
                            onChange={input.onChange}
                            placeholder="City"
                            isValid={meta.valid}
                          />
                        | "state" =>
                          <CustomInput
                            state={input.value->JSON.Decode.string->Option.getOr("")}
                            setState={_ => ()}
                            onChange={input.onChange}
                            placeholder="State/Province"
                            isValid={meta.valid}
                          />
                        | "zip" =>
                          <CustomInput
                            state={input.value->JSON.Decode.string->Option.getOr("")}
                            setState={_ => ()}
                            onChange={input.onChange}
                            placeholder="ZIP/Postal Code"
                            isValid={meta.valid}
                          />
                        | "country" =>
                          <CustomPicker
                            value={Some(input.value->JSON.Decode.string->Option.getOr(""))}
                            setValue={_ => ()}
                            onChange={input.onChange}
                            items={field.options->Array.map(option => {
                              CustomPicker.label: option,
                              value: option,
                              icon: Utils.getCountryFlags(option),
                            })}
                            placeholderText="Country"
                            isValid={meta.valid}
                          />
                        | "first_name" =>
                          <CustomInput
                            state={input.value->JSON.Decode.string->Option.getOr("")}
                            setState={_ => ()}
                            onChange={input.onChange}
                            placeholder="First Name"
                            isValid={meta.valid}
                          />
                        | "last_name" =>
                          <CustomInput
                            state={input.value->JSON.Decode.string->Option.getOr("")}
                            setState={_ => ()}
                            onChange={input.onChange}
                            placeholder="Last Name"
                            isValid={meta.valid}
                          />
                        | "number" if fieldType == "phone_input" =>
                          <CustomInput
                            state={input.value->JSON.Decode.string->Option.getOr("")}
                            setState={_ => ()}
                            onChange={input.onChange}
                            placeholder="Phone Number"
                            isValid={meta.valid}
                            keyboardType=#"phone-pad"
                          />
                        | _ => 
                          {renderFieldByType(field, input, meta)}
                        }}
                      </View>
                    }}
                  />
                })
                ->React.array}
              </View>
            | "shipping" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Shipping Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
            | "bank" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Bank Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
            | "wallet" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Wallet Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
            | "crypto" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Crypto Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
            | "upi" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="UPI Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
            | "voucher" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Voucher Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
            | "gift_card" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Gift Card Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
            | "mobile_payment" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Mobile Payment Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
            | "other" =>
              <View key={index->Int.toString}>
                <View style={Style.s({marginBottom: 12.->Style.dp})}>
                  <TextWrapper text="Other Details" textType=ModalText />
                </View>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <ReactFinalForm.Field 
                    name={field.name} 
                    key={fieldIndex->Int.toString}
                    render={({input, meta}) =>
                      <View style={Style.s({marginVertical: 8.->Style.dp})}>
                        <Space height=5. />
                        {renderFieldByType(field, input, meta)}
                      </View>
                    }
                  />
                })
                ->React.array}
              </View>
            | _ =>
              <View key={index->Int.toString}>
                {fields
                ->Array.mapWithIndex((field, fieldIndex) => {
                  <View key={fieldIndex->Int.toString} style={Style.s({marginVertical: 4.->Style.dp})}>
                    <TextWrapper text={field.displayName} textType=ModalText />
                  </View>
                })
                ->React.array}
              </View>
            }
          })
          ->React.array}
        </View>
      }
    />
  </View>
}
