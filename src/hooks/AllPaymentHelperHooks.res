open PaymentConfirmTypes
module BrowserRedirectionHooks = {
  let useBrowserRedirectionSuccessHook = () => {
    (~s, ~errorCallback, ~responseCallback) => {
      if s == JSON.Encode.null {
        errorCallback(~errorMessage=PaymentConfirmTypes.defaultConfirmError, ~closeSDK=true, ())
      } else {
        let status =
          s
          ->Utils.getDictFromJson
          ->Dict.get("status")
          ->Option.flatMap(JSON.Decode.string)
          ->Option.getOr("")

        switch status {
        | "succeeded" =>
          responseCallback(
            ~paymentStatus=LoadingContext.PaymentSuccess,
            ~status={status, message: "", code: "", type_: ""},
          )
        | "processing"
        | "requires_capture"
        | "requires_confirmation"
        | "cancelled"
        | "requires_merchant_action" =>
          responseCallback(
            ~paymentStatus=LoadingContext.ProcessingPayments,
            ~status={status, message: "", code: "", type_: ""},
          )
        | _ =>
          errorCallback(
            ~errorMessage={status, message: "", type_: "", code: ""},
            ~closeSDK={true},
            (),
          )
        }
      }
    }
  }

  let useBrowserRedirectionCancelHook = () => {
    (~errorCallback, ~responseCallback, ~paymentMethod: option<string>) => {
      if paymentMethod->Option.getOr("") == "ach" {
        responseCallback(
          ~paymentStatus=LoadingContext.ProcessingPayments,
          ~status={
            message: "",
            code: "",
            type_: "",
            status: "Pending",
          },
        )
      } else {
        errorCallback(
          ~errorMessage={status: "cancelled", message: "", type_: "", code: ""},
          ~closeSDK={true},
          (),
        )
      }
    }
  }

  let useBrowserRedirectionFailedHook = () => {
    (~errorCallback) => {
      errorCallback(
        ~errorMessage={status: "failed", message: "", type_: "", code: ""},
        ~closeSDK={true},
        (),
      )
    }
  }
}

module RedirectionHooks = {
  let useRedirectionHelperHook = () => {
    let apiLogWrapper = LoggerHook.useApiLogWrapper()
    async (
      ~body,
      ~errorCallback,
      ~handleApiRes: (
        ~status: string,
        ~reUri: string,
        ~error: PaymentConfirmTypes.error,
        ~nextAction: PaymentConfirmTypes.nextAction=?,
      ) => unit,
      ~headers,
      ~uri,
    ) => {
      try {
        let jsonResponse = await APIUtils.fetchApiWrapper(
          ~body,
          ~eventName=LoggerTypes.CONFIRM_CALL,
          ~headers,
          ~method=Fetch.Post,
          ~uri,
          ~apiLogWrapper,
        )
        let confirmResponse = jsonResponse->Utils.getDictFromJson
        let {nextAction, status, error} = itemToObjMapper(confirmResponse)
        handleApiRes(~status, ~reUri=nextAction.redirectToUrl, ~error, ~nextAction)
      } catch {
      | _ => errorCallback(~errorMessage=defaultConfirmError, ~closeSDK=false, ())
      }
    }
  }
}
