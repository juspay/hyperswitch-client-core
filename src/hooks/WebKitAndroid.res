type useWebKit = {
  sdkInitialised: string => unit,
  exitPaymentSheet: string => unit,
  launchGPay: string => unit,
}

@scope("window") @val external androidInterface: Nullable.t<useWebKit> = "AndroidInterface"

let useWebKit = () => {
  let sdkInitialised = str => {
    switch androidInterface->Nullable.toOption {
    | Some(interface) => interface.sdkInitialised(str)
    | None => ()
    }
  }
  let launchGPay = str => {
    switch androidInterface->Nullable.toOption {
    | Some(interface) => interface.launchGPay(str)
    | None => ()
    }
  }
  let exitPaymentSheet = str => {
    switch androidInterface->Nullable.toOption {
    | Some(interface) => interface.exitPaymentSheet(str)
    | None => ()
    }
  }

  {
    sdkInitialised,
    launchGPay,
    exitPaymentSheet,
  }
}
