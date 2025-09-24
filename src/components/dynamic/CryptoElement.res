open ReactNative
open Style

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~accessible=?,
) => {
  let getNetworkArray = currency => {
    switch currency->Option.getOr("") {
    | "BTC" => ["bitcoin", "bnb_smart_chain"]
    | "LTC" => ["litecoin", "bnb_smart_chain"]
    | "ETH" => ["ethereum", "bnb_smart_chain"]
    | "XRP" => ["ripple", "bnb_smart_chain"]
    | "XLM" => ["stellar", "bnb_smart_chain"]
    | "BCH" => ["bitcoin_cash", "bnb_smart_chain"]
    | "ADA" => ["cardano", "bnb_smart_chain"]
    | "SOL" => ["solana", "bnb_smart_chain"]
    | "SHIB" => ["ethereum", "bnb_smart_chain"]
    | "TRX" => ["tron", "bnb_smart_chain"]
    | "DOGE" => ["dogecoin", "bnb_smart_chain"]
    | "BNB" => ["bnb_smart_chain"]
    | "USDT" => ["ethereum", "tron", "bnb_smart_chain"]
    | "USDC" => ["ethereum", "tron", "bnb_smart_chain"]
    | "DAI" => ["ethereum", "bnb_smart_chain"]
    | _ => []
    }
  }

  switch (fields->Array.get(0), fields->Array.get(1)) {
  | (Some(currencyConfig), Some(networkConfig)) =>
    let {input: currencyInput, meta: currencyMeta} = ReactFinalForm.useField(
      currencyConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.Required)},
      (),
    )

    let {input: networkInput, meta: networkMeta} = ReactFinalForm.useField(
      networkConfig.outputPath,
      ~config={validate: createFieldValidator(Validation.Required)},
      (),
    )

    <>
      <React.Fragment>
        <View style={s({marginBottom: 16.->dp})}>
          {
            let handlePickerChange = (value: unit => option<string>) => {
              currencyInput.onChange(value()->Option.getOr(""))
            }
            <>
              <CustomPicker
                value=currencyInput.value
                setValue=handlePickerChange
                items={currencyConfig.options->Array.map(opt => {
                  CustomPicker.label: opt,
                  value: opt,
                })}
                placeholderText={GetLocale.getLocalString(currencyConfig.displayName)}
                isValid={currencyMeta.error->Option.isNone || !currencyMeta.touched}
                isLoading=false
                onFocus={_ => currencyInput.onFocus()}
                onBlur={_ => currencyInput.onBlur()}
                isCountryStateFields=true
                ?accessible
              />
              {switch (currencyMeta.error, currencyMeta.touched) {
              | (Some(error), true) => <ErrorText text={Some(error)} />
              | _ => React.null
              }}
            </>
          }
        </View>
      </React.Fragment>
      <React.Fragment>
        <View style={s({marginBottom: 16.->dp})}>
          {
            let handlePickerChange = (value: unit => option<string>) => {
              networkInput.onChange(value()->Option.getOr(""))
            }
            <>
              <CustomPicker
                value=networkInput.value
                setValue=handlePickerChange
                items={getNetworkArray(currencyInput.value)->Array.map(opt => {
                  CustomPicker.label: opt->CommonUtils.getDisplayName,
                  value: opt,
                })}
                placeholderText={GetLocale.getLocalString(networkConfig.displayName)}
                isValid={networkMeta.error->Option.isNone || !networkMeta.touched}
                isLoading=false
                onFocus={_ => networkInput.onFocus()}
                onBlur={_ => networkInput.onBlur()}
                isCountryStateFields=true
                ?accessible
              />
              {switch (networkMeta.error, networkMeta.touched) {
              | (Some(error), true) => <ErrorText text={Some(error)} />
              | _ => React.null
              }}
            </>
          }
        </View>
      </React.Fragment>
    </>
  | _ => React.null
  }
}
