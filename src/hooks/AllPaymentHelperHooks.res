open PaymentConfirmTypes
module BrowserRedirectionHooks = {
  let useBrowserRedirectionSuccessHook = () => {
    let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
    (~s, ~errorCallback, ~responseCallback) => {
      if s == JSON.Encode.null {
        setAllApiData({
          ...allApiData,
          additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
        })
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
          setAllApiData({
            ...allApiData,
            additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
          })
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
          setAllApiData({
            ...allApiData,
            additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
          })
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
    let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
    (~errorCallback, ~responseCallback, ~processor, ~openUrl, ~paymentMethod: option<string>) => {
      setAllApiData({
        ...allApiData,
        additionalPMLData: {
          ...allApiData.additionalPMLData,
          retryEnabled: Some(
            (
              {
                processor,
                redirectUrl: openUrl,
              }: AllApiDataContext.retryObject
            ),
          ),
        },
      })
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
          ~closeSDK={false},
          (),
        )
      }
    }
  }

  let useBrowserRedirectionFailedHook = () => {
    let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
    (~errorCallback) => {
      setAllApiData({
        ...allApiData,
        additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
      })
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
    let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
    let apiLogWrapper = LoggerHook.useApiLogWrapper()
    async (
      ~body,
      ~retrievePayment: (
        Types.retrieve,
        string,
        Js.String.t,
        ~isForceSync: bool=?,
      ) => RescriptCore.Promise.t<RescriptCore.JSON.t>,
      ~clientSecret,
      ~publishableKey,
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
      switch allApiData.additionalPMLData.retryEnabled {
      | Some({redirectUrl, processor}) =>
        if processor == body {
          try {
            let res = await retrievePayment(Types.Payment, clientSecret, publishableKey)
            if res == JSON.Encode.null {
              errorCallback(~errorMessage={defaultConfirmError}, ~closeSDK=false, ())
            } else {
              let status = res->Utils.getDictFromJson->Utils.getString("status", "")
              handleApiRes(
                ~status,
                ~reUri=redirectUrl,
                ~error={
                  code: "",
                  message: "hardcoded retrieve payment error",
                  type_: "",
                  status: "failed",
                },
              )
            }
          } catch {
          | _ => ()
          }
        } else {
          try {
            let jsonResponse = await APIUtils.fetchApiWrapper(
              ~body,
              ~eventName=LoggerTypes.CONFIRM_CALL,
              ~headers,
              ~method=Fetch.Post,
              ~uri,
              ~apiLogWrapper,
            )
            let {nextAction, status, error} = itemToObjMapper(jsonResponse->Utils.getDictFromJson)
            handleApiRes(~status, ~reUri=nextAction.redirectToUrl, ~error)
          } catch {
          | _ => errorCallback(~errorMessage=defaultConfirmError, ~closeSDK=false, ())
          }
        }

      | _ =>
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
}
