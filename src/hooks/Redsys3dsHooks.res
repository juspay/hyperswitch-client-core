open PaymentConfirmTypes

let useRedsys3dsFlow = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let logger = LoggerHook.useLoggerHook()

  async (
    ~clientSecret: string,
    ~publishableKey: string,
    ~nextAction: nextAction,
    ~responseCallback: (
      ~paymentStatus: LoadingContext.sdkPaymentState,
      ~status: error,
    ) => unit,
    ~errorCallback: (~errorMessage: error, ~closeSDK: bool, unit) => unit,
    ~paymentMethod: string,
    ~browserRedirectionHandler: (
      ~clientSecret: string,
      ~publishableKey: string,
      ~openUrl: string,
      ~responseCallback: (
        ~paymentStatus: LoadingContext.sdkPaymentState,
        ~status: error,
      ) => unit,
      ~errorCallback: (~errorMessage: error, ~closeSDK: bool, unit) => unit,
      ~paymentMethod: string,
    ) => promise<promise<unit>>,
  ) => {
    switch nextAction.iframeData {
    | Some(iframeData) if iframeData.threeDsMethodUrl !== "" =>
      let paymentId = clientSecret->String.split("_secret_")->Array.get(0)->Option.getOr("")

      // Step 1: Perform 3DS method POST via native module
      logger(
        ~logType=INFO,
        ~value="Redsys 3DS method call started",
        ~category=API,
        ~eventName=THREE_DS_METHOD_CALL,
        (),
      )

      let indicator = try {
        await ThreeDsMethodModule.performThreeDsMethod(
          ~url=iframeData.threeDsMethodUrl,
          ~data=iframeData.threeDsMethodData,
          ~methodKey=iframeData.methodKey,
          ~timeoutMs=10000,
        )
      } catch {
      | _ => "N" // On any error, fall back to "N"
      }

      // Step 2: Call complete_authorize
      let uri = `${baseUrl}/payments/${paymentId}/complete_authorize`
      let headers = Utils.getHeader(publishableKey, nativeProp.hyperParams.appId)
      let body =
        [
          ("client_secret", clientSecret->JSON.Encode.string),
          ("threeds_method_comp_ind", indicator->JSON.Encode.string),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
        ->JSON.stringify

      logger(
        ~logType=INFO,
        ~value=`complete_authorize indicator: ${indicator}`,
        ~category=API,
        ~eventName=COMPLETE_AUTHORIZE_CALL_INIT,
        (),
      )

      let jsonResponse = try {
        await APIUtils.fetchApiWrapper(
          ~uri,
          ~body,
          ~method=#POST,
          ~headers,
          ~eventName=LoggerTypes.COMPLETE_AUTHORIZE_CALL,
          ~apiLogWrapper,
        )
      } catch {
      | _ => JSON.Encode.null
      }

      // Step 3: Route response
      if jsonResponse == JSON.Encode.null {
        errorCallback(~errorMessage=defaultConfirmError, ~closeSDK=true, ())
      } else {
        let {nextAction: completeNextAction, status, error} =
          jsonResponse->Utils.getDictFromJson->itemToObjMapper

        switch status {
        | "succeeded" =>
          responseCallback(
            ~paymentStatus=LoadingContext.PaymentSuccess,
            ~status={status: "succeeded", message: "", code: "", type_: ""},
          )
        | "processing" | "requires_capture" | "requires_confirmation" | "requires_merchant_action" =>
          responseCallback(
            ~paymentStatus=ProcessingPayments,
            ~status={status, message: "", code: "", type_: ""},
          )
        | "requires_customer_action" =>
          let redirectUrl = completeNextAction.redirectToUrl
          if redirectUrl !== "" {
            browserRedirectionHandler(
              ~clientSecret,
              ~publishableKey,
              ~openUrl=redirectUrl,
              ~responseCallback,
              ~errorCallback,
              ~paymentMethod,
            )->ignore
          } else {
            errorCallback(
              ~errorMessage={
                status: "failed",
                message: "Missing redirect URL for 3DS challenge",
                type_: "",
                code: "",
              },
              ~closeSDK=true,
              (),
            )
          }
        | _ => errorCallback(~errorMessage=error, ~closeSDK=true, ())
        }
      }
    | _ =>
      errorCallback(
        ~errorMessage={
          status: "failed",
          message: "Missing or invalid iframe data for Redsys 3DS",
          type_: "",
          code: "",
        },
        ~closeSDK=true,
        (),
      )
    }
  }
}
