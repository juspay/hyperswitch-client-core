open ReactNative

@val external alert: string => unit = "alert"

let useAlerts = () => {
  // Uses the standalone hook (not AllPaymentHooks) so the PMM bundle does not
  // drag the payments hook stack; behavior is identical.
  let handleSuccessFailure = HandleSuccessFailureHook.useHandleSuccessFailure()
  (
    // let exitRN = HyperModule.useExitRN()
    ~errorType: string,
    ~message,
  ) => {
    let apiResStatus: PaymentConfirmTypes.error = {
      type_: "",
      status: "failed",
      code: "",
      message,
    }

    switch (errorType, Platform.os) {
    | ("error", _) => handleSuccessFailure(~apiResStatus, ())

    | ("warning", #android) => ToastAndroid.show(message, ToastAndroid.long)
    | ("warning", #ios) => Alert.alert(~title="Warning", ~message)
    | ("warning", #web) => alert(message)
    | _ => Console.error(message)
    }
  }
}
