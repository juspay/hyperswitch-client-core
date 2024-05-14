open ErrorUtils
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
    `.+_secret_[A-Za-z0-9]+`->Re.fromString,
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
