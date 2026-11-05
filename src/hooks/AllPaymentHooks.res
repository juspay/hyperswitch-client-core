open PaymentConfirmTypes
open AllPaymentHelperHooks

let useHandleSuccessFailure = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {exit} = HyperModule.useExitPaymentsheet()
  let exitCard = HyperModule.useExitCard()
  let exitWidget = HyperModule.useExitWidget()
  (~apiResStatus: error, ~closeSDK=true, ~reset=true, ()) => {
    switch nativeProp.sdkState {
    | PaymentSheet
    | TabSheet
    | ButtonSheet
    | HostedCheckout =>
      if closeSDK {
        exit(apiResStatus, reset)
      }
    | CardWidget => exitCard(apiResStatus)
    | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet =>
      if closeSDK {
        exit(apiResStatus, reset)
      } else {
        HyperModule.notifyWidgetPaymentResult(
          nativeProp.rootTag,
          {...apiResStatus, status: "failed"}->HyperModule.resStatusPayload,
        )
      }
    | CustomWidget(str) =>
      exitWidget(apiResStatus, str->SdkTypes.widgetToStrMapper->String.toLowerCase)
    | ExpressCheckoutWidget => exitWidget(apiResStatus, "expressCheckout")
    | _ =>
      // PMM states live on `pmmState` (their `sdkState` parses to NoView).
      switch nativeProp.pmmState {
      | Some(_) =>
        if closeSDK {
          exit(apiResStatus, reset)
        }
      | None => ()
      }
    }
  }
}

let useRetrieveHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  (type_, clientSecret, publishableKey, ~isForceSync=false) => {
    switch type_ {
    | Types.Payment =>
      let headers = Utils.getHeader(
        ~apiKey=publishableKey,
        ~appId=nativeProp.sdkParams.appId,
        ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
        (),
      )
      let uri = switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
      | Some(_) =>
        `${baseUrl}/payments/${nativeProp.paymentSessionConfig.paymentId}?force_sync=${isForceSync
            ? "true"
            : "false"}`
      | None =>
        `${baseUrl}/payments/${nativeProp.paymentSessionConfig.paymentId}?force_sync=${isForceSync
            ? "true"
            : "false"}&client_secret=${clientSecret}`
      }

      APIUtils.fetchApiWrapper(
        ~uri,
        ~method=#GET,
        ~headers,
        ~observed=SdkApi(RetrievePaymentIntent),
      )
    }
  }
}

let useFetchClientData = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  () => {
    switch WebKit.platform {
    | #next => Promise.resolve(Next.clientResponse)
    | _ =>
      let paymentId = nativeProp.paymentSessionConfig.paymentId
      let uri = switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
      | Some(_) => `${baseUrl}/payments/${paymentId}/client`
      | None =>
        `${baseUrl}/payments/${paymentId}/client?client_secret=${nativeProp.paymentSessionConfig.clientSecret}`
      }
      APIUtils.fetchApiWrapper(
        ~uri,
        ~method=#GET,
        ~headers=Utils.getHeader(
          ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
          ~appId=nativeProp.sdkParams.appId,
          ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
          (),
        ),
        ~observed=SdkApi(ClientList),
      )
    }
  }
}

let useSessionTokenHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  (~wallet=[]) => {
    switch WebKit.platform {
    | #next => Promise.resolve(Next.sessionsRes)
    | _ =>
      APIUtils.fetchApiWrapper(
        ~uri=`${baseUrl}/payments/session_tokens`,
        ~body=PaymentUtils.generateSessionsTokenBody(
          ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
          ~paymentId=nativeProp.paymentSessionConfig.paymentId,
          ~sdkAuthorization=?nativeProp.paymentSessionConfig.sdkAuthorization,
          ~wallet,
        ),
        ~method=#POST,
        ~headers=Utils.getHeader(
          ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
          ~appId=nativeProp.sdkParams.appId,
          ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
          (),
        ),
        ~observed=SdkApi(Sessions),
      )
    }
  }
}

//add a hook for /sdk-config
let useSdkConfigHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  () => {
    let uri = `${baseUrl}/v1/sdk/configs/${WebKit.platformGroup}/sdk_config.json?client_secret=${nativeProp.paymentSessionConfig.clientSecret}`

    APIUtils.fetchApiWrapper(
      ~uri,
      ~method=#GET,
      ~headers=Utils.getHeader(
        ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
        ~appId=nativeProp.sdkParams.appId,
        ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
        (),
      ),
      ~observed=SdkStaticAsset(SdkConfigs),
    )
  }
}

let usePostSessionTokensHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (clientData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  (
    ~paymentMethodData: ClientResponseType.paymentMethodEnabled,
    ~sessionObject: SessionsType.sessions,
    (),
  ) => {
    let payment_type_str =
      clientData
      ->Option.map(a => a.intent_data.payment_type_str)
      ->Option.getOr(None)

    let body =
      PaymentUtils.generatePostSessionTokensBody(
        ~nativeProp,
        ~paymentMethodData,
        ~sessionObject,
        ~payment_type_str?,
        (),
      )->JSON.stringify

    APIUtils.fetchApiWrapper(
      ~uri=`${baseUrl}/payments/${nativeProp.paymentSessionConfig.paymentId}/post_session_tokens`,
      ~body,
      ~method=#POST,
      ~headers=Utils.getHeader(
        ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
        ~appId=nativeProp.sdkParams.appId,
        ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
        (),
      ),
      ~observed=SdkApi(PostSessionTokens),
    )
  }
}

let useBrowserHook = () => {
  let retrievePayment = useRetrieveHook()
  let (clientData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let intervalId = React.useRef(Nullable.null)
  let redirectionSuccessHandler = BrowserRedirectionHooks.useBrowserRedirectionSuccessHook()
  let redirectionCancelHandler = BrowserRedirectionHooks.useBrowserRedirectionCancelHook()
  let redirectionFailureHandler = BrowserRedirectionHooks.useBrowserRedirectionFailedHook()
  async (
    ~clientSecret,
    ~publishableKey,
    ~openUrl,
    ~responseCallback,
    ~errorCallback,
    ~paymentMethod: option<string>=?,
    ~useEphemeralWebSession=false,
  ) => {
    let loggedPaymentMethod = paymentMethod->Option.flatMap(LoggerPaymentMethod.ofTypeName)
    PaymentFlowLogger.logRedirectStarted(~url=openUrl, ~paymentMethod=?loggedPaymentMethod)
    let res = await BrowserHook.openUrl(
      openUrl,
      Utils.getReturnUrl(
        ~appId=nativeProp.sdkParams.appId,
        ~appURL=clientData->Option.map(data => data.intent_data.return_url),
      ),
      intervalId,
      ~useEphemeralWebSession,
      ~appearance=nativeProp.configuration.appearance,
    )
    res.status->PaymentFlowLogger.logRedirectReturned(~paymentMethod=?loggedPaymentMethod)

    switch res.status {
    | Success => {
        let s = await retrievePayment(Payment, clientSecret, publishableKey)
        redirectionSuccessHandler(~s, ~errorCallback, ~responseCallback)
      }
    | Cancel => redirectionCancelHandler(~errorCallback, ~paymentMethod, ~responseCallback)
    | Failed => redirectionFailureHandler(~errorCallback)
    | _ =>
      errorCallback(
        ~errorMessage={
          status: res->JSON.stringifyAny->Option.getOr(""),
          message: "",
          type_: "",
          code: "",
        },
        ~closeSDK={false},
        (),
      )
    }
    Promise.resolve()
  }
}

let useRedirectHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let browserRedirectionHandler = useBrowserHook()
  let retrievePayment = useRetrieveHook()
  let redirectionSuccessHandler = BrowserRedirectionHooks.useBrowserRedirectionSuccessHook()
  let redirectionFailureHandler = BrowserRedirectionHooks.useBrowserRedirectionFailedHook()
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let handleNativeThreeDS = NetceteraThreeDsHooks.useExternalThreeDs()
  let getOpenProps = PlaidHelperHook.usePlaidProps()
  let redirectionHandler = RedirectionHooks.useRedirectionHelperHook()

  (
    ~body: string,
    ~publishableKey: string,
    ~clientSecret: string,
    ~errorCallback: (~errorMessage: error, ~closeSDK: bool, unit) => unit,
    ~paymentMethod,
    ~responseCallback: (~paymentStatus: LoadingContext.sdkPaymentState, ~status: error) => unit,
    ~isCardPayment=false,
    (),
  ) => {
    let uriPram = nativeProp.paymentSessionConfig.paymentId
    let uri = `${baseUrl}/payments/${uriPram}/confirm`
    let loggedPaymentMethod = body->LoggerPaymentMethod.fromRequestBody
    let headers = Utils.getHeader(
      ~apiKey=publishableKey,
      ~appId=nativeProp.sdkParams.appId,
      ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
      (),
    )

    let handleInvokeThreeDSFlow = (~nextAction) => {
      let netceteraSDKApiKey = nativeProp.configuration.netceteraSDKApiKey->Option.getOr("")
      handleNativeThreeDS(
        ~baseUrl,
        ~appId=nativeProp.sdkParams.appId,
        ~netceteraSDKApiKey,
        ~clientSecret,
        ~publishableKey,
        ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
        ~nextAction,
        ~retrievePayment,
        ~sdkEnvironment=nativeProp.hyperswitchConfig.environment,
        ~onSuccess=message => {
          responseCallback(
            ~paymentStatus=PaymentSuccess,
            ~status={status: "succeeded", message, code: "", type_: ""},
          )
        },
        ~onFailure=message => {
          errorCallback(
            ~errorMessage={status: "failed", message, type_: "", code: ""},
            ~closeSDK={true},
            (),
          )
        },
      )
    }

    let handleThirdPartySDKSessionFlow = (~nextAction) => {
      let session_token = Option.getOr(nextAction, defaultNextAction).session_token
      let openProps = getOpenProps(retrievePayment, responseCallback, errorCallback)
      switch session_token {
      | Some(token) =>
        let paymentMethod = LoggerPaymentMethod.OpenBanking(Plaid)
        SdkLogger.observeFunction(~event=PlaidCreate, ~paymentMethod, ~call=() =>
          Plaid.create({token: token.open_banking_session_token})
        )
        Plaid.open_({
          ...openProps,
          onSuccess: SdkLogger.observeFunctionCallback(
            ~event=OnSuccess,
            ~paymentMethod,
            ~callback=openProps.onSuccess,
          ),
          onExit: ?openProps.onExit->Option.map(onExit =>
            SdkLogger.observeFunctionCallback(~event=OnExit, ~paymentMethod, ~callback=onExit)
          ),
        })->ignore
      | None => ()
      }
    }

    let handleBankTransferFlow = (~nextAction) => {
      switch nextAction {
      | None => ()
      | Some(_data) =>
        SdkLogger.logLifecycle(~event=BankTransferShown, ~paymentMethod=?loggedPaymentMethod)
        setLoading(ProcessingPayments)
      }
    }

    let handleDefaultPaymentFlows = (~status, ~reUri, ~error: error) => {
      let terminalStatusHandler = () => {status, message: "", code: "", type_: ""}

      switch status {
      | "succeeded" =>
        PaymentFlowLogger.logOutcome(~status, ~paymentMethod=?loggedPaymentMethod)
        responseCallback(~paymentStatus=PaymentSuccess, ~status=terminalStatusHandler())

      | "requires_capture"
      | "processing"
      | "requires_confirmation"
      | "requires_merchant_action" =>
        responseCallback(~paymentStatus=ProcessingPayments, ~status=terminalStatusHandler())
      | "requires_customer_action" =>
        terminalStatusHandler()->ignore
        browserRedirectionHandler(
          ~clientSecret,
          ~publishableKey,
          ~openUrl=reUri,
          ~responseCallback,
          ~errorCallback,
          ~useEphemeralWebSession=isCardPayment,
          ~paymentMethod,
        )->ignore

      | statusVal =>
        PaymentFlowLogger.logOutcome(
          ~status=statusVal,
          ~details=PaymentErrorLoggerDetails.ofError(error),
          ~paymentMethod=?loggedPaymentMethod,
        )
        errorCallback(~errorMessage=error, ~closeSDK=true, ())
        terminalStatusHandler()->ignore
      }
    }

    let handleInvokeDDCFlow = (~nextAction) => {
      let {iframeUrl, timeoutMs} =
        (nextAction->Option.getOr(defaultNextAction)).ddc_data->Option.getOr(
          DdcTypes.defaultDdcData,
        )
      PaymentFlowLogger.logDdcStarted(~iframeUrl, ~paymentMethod=?loggedPaymentMethod)
      HyperModule.openIframeBridge(iframeUrl, timeoutMs, rawMessage => {
        if rawMessage === "" {
          PaymentFlowLogger.logDdcNoResult(~timeoutMs, ~paymentMethod=?loggedPaymentMethod)
          errorCallback(
            ~errorMessage={
              status: "failed",
              message: "DDC failed or timed out",
              type_: "invoke_ddc_error",
              code: "ddc_failure",
            },
            ~closeSDK=true,
            (),
          )
        } else {
          let parsed =
            rawMessage
            ->PaymentFlowLogger.parseDdcResult(~paymentMethod=?loggedPaymentMethod)
            ->Utils.getDictFromJson
          let nextActionType =
            parsed
            ->Dict.get("next_action")
            ->Option.flatMap(JSON.Decode.object)
            ->Option.flatMap(d => d->Dict.get("type"))
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr("")
          let redirectUrl =
            parsed
            ->Dict.get("next_action")
            ->Option.flatMap(JSON.Decode.object)
            ->Option.flatMap(d => d->Dict.get("url"))
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr("")
          PaymentFlowLogger.logDdcResult(
            ~nextActionType,
            ~redirectUrl,
            ~paymentMethod=?loggedPaymentMethod,
          )
          switch nextActionType {
          | "redirect_to_url" if redirectUrl !== "" =>
            if (
              redirectUrl->String.includes("status=succeeded") ||
              redirectUrl->String.includes("status=processing") ||
              redirectUrl->String.includes("status=requires_capture") ||
              redirectUrl->String.includes("status=partially_captured")
            ) {
              let _ = (
                async () => {
                  let s = await retrievePayment(Payment, clientSecret, publishableKey)
                  redirectionSuccessHandler(~s, ~errorCallback, ~responseCallback)
                }
              )()
            } else if (
              redirectUrl->String.includes("status=failed") ||
                redirectUrl->String.includes("status=requires_payment_method")
            ) {
              PaymentFlowLogger.logDdcPaymentFailed(~paymentMethod=?loggedPaymentMethod)
              redirectionFailureHandler(~errorCallback)
            } else {
              browserRedirectionHandler(
                ~clientSecret,
                ~publishableKey,
                ~openUrl=redirectUrl,
                ~responseCallback,
                ~errorCallback,
                ~paymentMethod,
              )->ignore
            }
          | _ =>
            errorCallback(
              ~errorMessage={
                status: "failed",
                message: `DDC failed: invalid next action type - ${nextActionType}`,
                type_: "invoke_ddc_error",
                code: "ddc_failure",
              },
              ~closeSDK=true,
              (),
            )
          }
        }
      })
    }

    let handleApiRes = (~status, ~reUri, ~error: error, ~nextAction: option<nextAction>=?) => {
      switch nextAction->PaymentUtils.getActionType {
      | "three_ds_invoke" => handleInvokeThreeDSFlow(~nextAction)
      | "third_party_sdk_session_token" => handleThirdPartySDKSessionFlow(~nextAction)
      | "display_bank_transfer_information" => handleBankTransferFlow(~nextAction)
      | "invoke_ddc" => handleInvokeDDCFlow(~nextAction)
      | _ => handleDefaultPaymentFlows(~status, ~reUri, ~error)
      }
    }

    SdkLogger.logLifecycle(
      ~event=PaymentAttempted,
      ~details=[("content_length", body->String.length->JSON.Encode.int)],
      ~paymentMethod=?loggedPaymentMethod,
    )
    redirectionHandler(~body, ~errorCallback, ~handleApiRes, ~headers, ~uri)->ignore
  }
}

let useEligibilityCheckHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  (~paymentMethodType: string, ~paymentMethodData: JSON.t) => {
    switch WebKit.platform {
    | #next => Promise.resolve(`{"sdk_next_action":{"next_action":"confirm"}}`->JSON.parseExn)
    | _ =>
      let uri = `${baseUrl}/payments/${nativeProp.paymentSessionConfig.paymentId}/eligibility`
      let body =
        [
          ("payment_method_type", paymentMethodType->JSON.Encode.string),
          ("payment_method_data", paymentMethodData),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
        ->JSON.stringify
      APIUtils.fetchApi(
        ~uri,
        ~bodyStr=body,
        ~method_=#POST,
        ~headers=Utils.getHeader(
          ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
          ~appId=nativeProp.sdkParams.appId,
          ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
          (),
        ),
      )->Promise.then(response => response->Fetch.Response.json)
    }
  }
}

let useSavePaymentMethod = () => {
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  (~body: PaymentConfirmTypes.redirectType) => {
    let uriParam = nativeProp.paymentSessionConfig.paymentId
    let uri = `${baseUrl}/payment_methods/${uriParam}/save`

    APIUtils.fetchApiWrapper(
      ~uri,
      ~method=#POST,
      ~headers=Utils.getHeader(
        ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
        ~appId=nativeProp.sdkParams.appId,
        ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
        (),
      ),
      ~observed=SdkApi(CreateCustomerPaymentMethods),
      ~body=body->JSON.stringifyAny->Option.getOr(""),
    )
  }
}
