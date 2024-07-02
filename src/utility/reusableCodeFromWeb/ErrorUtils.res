type errorType = Error | Warning
type errorStringType = Dynamic(string => string) | Static(string)
type errorTupple = (errorType, errorStringType)
type errorKey =
  | INVALID_PK(errorTupple)
  | DEPRECATED_LOADSTRIPE(errorTupple)
  | REQUIRED_PARAMETER(errorTupple)
  | UNKNOWN_KEY(errorTupple)
  | UNKNOWN_VALUE(errorTupple)
  | TYPE_BOOL_ERROR(errorTupple)
  | TYPE_STRING_ERROR(errorTupple)
  | INVALID_FORMAT(errorTupple)
  | USED_CL(errorTupple)
  | INVALID_CL(errorTupple)
  | NO_DATA(errorTupple)

type errorWarning = {
  invalidPk: errorKey,
  deprecatedLoadStripe: errorKey,
  reguirParameter: errorKey,
  typeBoolError: errorKey,
  unknownKey: errorKey,
  typeStringError: errorKey,
  unknownValue: errorKey,
  invalidFormat: errorKey,
  usedCL: errorKey,
  invalidCL: errorKey,
  noData: errorKey,
}

let isError = (res: JSON.t) => {
  res
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("error")
  ->Option.isSome
}

let getErrorCode = (res: JSON.t) => {
  res
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("error")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("code")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.stringify
}

let getErrorMessage = (res: JSON.t) => {
  res
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("error")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("message")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.stringify
}

let errorWarning = {
  invalidPk: INVALID_PK(
    Error,
    Static(
      "INTEGRATION ERROR: Invalid Publishable key, starts with pk_snd_(sandbox/test) or pk_prd_(production/live)",
    ),
  ),
  deprecatedLoadStripe: DEPRECATED_LOADSTRIPE(
    Warning,
    Static("loadStripe is deprecated. Please use loadOrca instead."),
  ),
  reguirParameter: REQUIRED_PARAMETER(
    Error,
    Dynamic(
      // str => {`INTEGRATION ERROR: ${str} is a required field/parameter or ${str} cannot be empty`},
      str => {`INTEGRATION ERROR: ${str}`},
    ),
  ),
  unknownKey: UNKNOWN_KEY(
    Warning,
    Dynamic(
      str => {
        `Unknown Key: ${str} is a unknown/invalid key, please provide a correct key. This might cause issue in the future`
      },
    ),
  ),
  typeBoolError: TYPE_BOOL_ERROR(
    Warning,
    Dynamic(
      str => {
        `Type Error: '${str}' Expected boolean`
      },
    ),
  ),
  typeStringError: TYPE_STRING_ERROR(
    Warning,
    Dynamic(
      str => {
        `Type Error: '${str}' Expected string`
      },
    ),
  ),
  unknownValue: UNKNOWN_VALUE(
    Warning,
    Dynamic(
      str => {
        `Unknown Value: ${str}. Please provide a correct value. This might cause issue in the future`
      },
    ),
  ),
  invalidFormat: INVALID_FORMAT(Error, Dynamic(str => {str})),
  usedCL: USED_CL(Error, Static("Data Error: The client secret has been already used.")),
  invalidCL: INVALID_CL(Error, Static("Data Error: The client secret is invalid.")),
  noData: NO_DATA(Error, Static("There is no customer default saved payment method data")),
}

let useShowErrorOrWarning = () => {
  let customAlert = AlertHook.useAlerts()
  (inputKey: errorKey, ~dynamicStr="", ()) => {
    let (type_, str) = switch inputKey {
    | INVALID_PK(var) => var
    | DEPRECATED_LOADSTRIPE(var) => var
    | REQUIRED_PARAMETER(var) => var
    | UNKNOWN_KEY(var) => var
    | UNKNOWN_VALUE(var) => var
    | TYPE_BOOL_ERROR(var) => var
    | TYPE_STRING_ERROR(var) => var
    | INVALID_FORMAT(var) => var
    | USED_CL(var) => var
    | INVALID_CL(var) => var
    | NO_DATA(var) => var
    }
    switch (type_, str) {
    | (Error, Static(string)) => customAlert(~errorType="error", ~message=string)
    | (Warning, Static(string)) => customAlert(~errorType="warning", ~message=string)
    | (Error, Dynamic(fn)) => customAlert(~errorType="error", ~message=fn(dynamicStr))
    | (Warning, Dynamic(fn)) => customAlert(~errorType="warning", ~message=fn(dynamicStr))
    }
  }
}

let useErrorWarningValidationOnLoad = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let isPublishableKeyValid = GlobalVars.isValidPK(nativeProp.env, nativeProp.publishableKey)

  let isClientSecretValid = RegExp.test(
    `.+_secret_[A-Za-z0-9]+`->Js.Re.fromString,
    nativeProp.clientSecret,
  )
  let showErrorOrWarning = useShowErrorOrWarning()
  () => {
    if !isPublishableKeyValid {
      switch nativeProp.sdkState {
      | PaymentSheet | WidgetPaymentSheet => showErrorOrWarning(errorWarning.invalidPk, ())
      | HostedCheckout => showErrorOrWarning(errorWarning.invalidPk, ())
      | CardWidget | CustomWidget(_) | ExpressCheckoutWidget => ()
      | Headless => showErrorOrWarning(errorWarning.invalidPk, ())
      | NoView => ()
      }
    } else if !isClientSecretValid {
      let dynamicStr = "ClientSecret is expected to be in format pay_******_secret_*****"
      switch nativeProp.sdkState {
      | PaymentSheet | WidgetPaymentSheet =>
        showErrorOrWarning(errorWarning.invalidFormat, ~dynamicStr, ())
      | HostedCheckout => showErrorOrWarning(errorWarning.invalidFormat, ~dynamicStr, ())
      | CardWidget | CustomWidget(_) | ExpressCheckoutWidget => ()
      | Headless => showErrorOrWarning(errorWarning.invalidFormat, ~dynamicStr, ())
      | NoView => ()
      }
    }
    // else if nativeProp.configuration.merchantDisplayName === "" {
    //   let dynamicStr = "When  a configuration is passed to PaymentSheet, the merchant display name cannot be an empty string"
    //   showErrorOrWarning(errorWarning.reguirParameter, ~dynamicStr, ())
    // }
  }
}
