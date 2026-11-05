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

        PaymentFlowLogger.logOutcome(~status)
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
        let paymentMethod = body->LoggerPaymentMethod.fromRequestBody
        let jsonResponse = await APIUtils.handleApiCall(
          ~body,
          ~observed=SdkApi(ConfirmCall),
          ~paymentMethod?,
          ~headers,
          ~method=#POST,
          ~uri,
          ~processSuccess=json => {
            PaymentFlowLogger.logConfirmResponded(json, ~paymentMethod?)
            json
          },
          ~processError=error => {
            PaymentFlowLogger.logConfirmRejected(error, ~paymentMethod?)
            error
          },
          ~processCatch=_ => JSON.Encode.null,
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
