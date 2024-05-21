open ReactNative

let useAlerts = () => {
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
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
    | ("error", #android) =>
      ToastAndroid.show(message, ToastAndroid.long)
      handleSuccessFailure(~apiResStatus, ())
    | ("error", #ios) =>
      Alert.alert(~title="Error", ~message, ())
      handleSuccessFailure(~apiResStatus, ())
    | ("warning", #android) => ToastAndroid.show(message, ToastAndroid.long)
    | ("warning", #ios) => Alert.alert(~title="Warning", ~message, ())
    | ("error", _) => Exn.raiseError(message)
    | _ => Console.error(message)
    }
  }
}
