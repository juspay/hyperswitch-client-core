@react.component
let make = (
  ~field: SuperpositionTypes.fieldConfig,
  ~fieldProps: ReactFinalForm.Field.fieldProps,
  ~country,
  ~items: array<SdkTypes.customPickerType>,
  ~isCountryStateDataLoading,
  ~placeholder,
  ~accessible=?,
) => {
  let {input, meta} = fieldProps
  let logger = LoggerHook.useLoggerHook()

  /*
   * `_dropdown_options` is the merchant's state allowlist; empty means no restriction.
   * When it matches no state of the selected country, fall back to the full list so the
   * field stays fillable.
   */
  let allowedCodes = field.dropdownOptions->Option.getOr([])
  let allowedItems =
    items->Array.filter(item =>
      allowedCodes->Array.length === 0 || allowedCodes->Array.includes(item.value)
    )

  // The merchant's allowlist was discarded and the field is showing the full list in its place.
  let isShowingFallbackStateList = allowedItems->Array.length === 0 && items->Array.length > 0
  let items = isShowingFallbackStateList ? items : allowedItems
  let configuredStateCodes = allowedCodes->Array.join(", ")

  React.useEffect(() => {
    if isShowingFallbackStateList {
      logger(
        ~logType=WARNING,
        ~category=MERCHANT_EVENT,
        ~eventName=DYNAMIC_FIELDS_CONFIG,
        ~value=`None of the configured state options [${configuredStateCodes}] for '${field.confirmRequestWritePath}' are valid states of country '${country}'. Falling back to the complete state list.`,
        (),
      )
    }
    None
  }, (isShowingFallbackStateList, country, configuredStateCodes, field.confirmRequestWritePath))

  let selectedLabel = switch input.value {
  | None | Some("") => input.value
  | Some(value) =>
    items
    ->Array.find(item => item.value === value || item.label === value)
    ->Option.map(item => item.label)
  }
  // Clear a state the list no longer offers so the required check makes the user pick again.
  // Wait for country-state data before deciding whether the selected state is still eligible.
  React.useEffect(() => {
    let isValueNotAllowed = selectedLabel->Option.isNone && input.value->Option.isSome
    if !isCountryStateDataLoading && isValueNotAllowed {
      let timeoutId = setTimeout(() => input.onChange(""), 0)
      Some(() => clearTimeout(timeoutId))
    } else {
      None
    }
  }, (isCountryStateDataLoading, selectedLabel, input.value))

  <>
    <CustomPicker
      value=selectedLabel
      setValue={value => input.onChange(value()->Option.getOr(""))}
      items
      placeholderText=placeholder
      isValid={meta.error->Option.isNone || !meta.touched || meta.active}
      isLoading=false
      onFocus={_ => input.onFocus()}
      onBlur={_ => input.onBlur()}
      ?accessible
    />
    {switch (meta.error, meta.touched, meta.active) {
    | (Some(error), true, false) => <ErrorText text={Some(error)} />
    | _ => React.null
    }}
  </>
}
