let superpositionBaseContextToJson = (context: SuperpositionTypes.superpositionBaseContext) => {
  let dict = [
    ("payment_method", context.payment_method->JSON.Encode.string),
    ("payment_method_type", context.payment_method_type->JSON.Encode.string),
    ("platform", context.platform->JSON.Encode.string),
    ("country", context.country->JSON.Encode.string),
    ("mandate_type", context.mandate_type->JSON.Encode.string),
    (
      "always_collect_shipping_details_from_wallet_connector",
      context.always_collect_shipping_details_from_wallet_connector->JSON.Encode.bool,
    ),
    (
      "always_collect_billing_details_from_wallet_connector",
      context.always_collect_billing_details_from_wallet_connector->JSON.Encode.bool,
    ),
  ]->Dict.fromArray

  [
    ("currency", context.currency),
    ("profile_id", context.profile_id),
    ("processor_merchant_id", context.processor_merchant_id),
    ("provider_merchant_id", context.provider_merchant_id),
    ("organization_id", context.organization_id),
  ]->Array.forEach(((key, value)) =>
    value->Option.forEach(value => dict->Dict.set(key, value->JSON.Encode.string))
  )

  dict->JSON.Encode.object
}

let useLogDynamicFieldsRendered = (~rawConfigs: option<JSON.t>) => {
  let logger = LoggerHook.useLoggerHook()
  let loggedFieldKeys = React.useRef(Dict.make())
  (
    fields: array<SuperpositionTypes.fieldConfig>,
    configParams: SuperpositionTypes.superpositionBaseContext,
    eligibleConnectors: array<JSON.t>,
  ) => {
    let dedupeKey = configParams.payment_method ++ "|" ++ configParams.payment_method_type
    if rawConfigs->Option.isSome &&
      !(loggedFieldKeys.current->Dict.get(dedupeKey)->Option.getOr(false)) {
      // All tabs share this provider, so dedupe each method independently.
      loggedFieldKeys.current->Dict.set(dedupeKey, true)
      let fieldsJson =
        fields
        ->Array.map(field =>
          [
            ("field_type", (field.fieldRenderType :> string)->JSON.Encode.string),
            ("write_path", field.confirmRequestWritePath->JSON.Encode.string),
            (
              "intent_data_read_path",
              field.intentDataReadPath->Option.map(JSON.Encode.string)->Option.getOr(JSON.Null),
            ),
            ("is_required", field.isRequired->JSON.Encode.bool),
            (
              "validation_rule_type",
              field.validationRuleType->Option.map(JSON.Encode.string)->Option.getOr(JSON.Null),
            ),
            (
              "validation_regex_pattern",
              field.validationRegexPattern
              ->Option.map(JSON.Encode.string)
              ->Option.getOr(JSON.Null),
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
        )
        ->JSON.Encode.array
      let payload =
        [
          ("superposition_base_context", configParams->superpositionBaseContextToJson),
          ("eligible_connectors", eligibleConnectors->JSON.Encode.array),
          ("field_count", fields->Array.length->JSON.Encode.int),
          ("fields", fieldsJson),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
        ->JSON.stringify
      logger(
        ~logType=INFO,
        ~category=USER_EVENT,
        ~eventName=DYNAMIC_FIELDS_RENDERED,
        ~paymentMethod=configParams.payment_method,
        ~value=payload,
        (),
      )
    }
  }
}
