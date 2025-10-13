open PaymentConfirmTypes
open AllPaymentHelperHooks

let useHandleSuccessFailure = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {exit} = HyperModule.useExitPaymentsheet()
  let exitCard = HyperModule.useExitCard()
  let exitWidget = HyperModule.useExitWidget()
  (~apiResStatus: error, ~closeSDK=true, ~reset=true, ()) => {
    switch nativeProp.sdkState {
    | PaymentSheet | TabSheet | ButtonSheet | HostedCheckout | PaymentMethodsManagement =>
      if closeSDK {
        exit(apiResStatus, reset)
      }
    | CardWidget => exitCard(apiResStatus)
    | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet =>
      if closeSDK {
        exit(apiResStatus, reset)
      }
    | CustomWidget(str) =>
      exitWidget(apiResStatus, str->SdkTypes.widgetToStrMapper->String.toLowerCase)
    | ExpressCheckoutWidget => exitWidget(apiResStatus, "expressCheckout")
    | _ => ()
    }
  }
}

let useRetrieveHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  (type_, clientSecret, publishableKey, ~isForceSync=false) => {
    switch (WebKit.platform, type_) {
    | (#next, Types.List) => Promise.resolve(Next.listRes)
    | (_, type_) =>
      let headers = Utils.getHeader(publishableKey, nativeProp.hyperParams.appId)
      let (uri, eventName: LoggerTypes.eventName) = switch type_ {
      | Payment => (
          `${baseUrl}/payments/${String.split(clientSecret, "_secret_")
            ->Array.get(0)
            ->Option.getOr("")}?force_sync=${isForceSync
              ? "true"
              : "false"}&client_secret=${clientSecret}`,
          RETRIEVE_CALL,
        )
      | List => (
          `${baseUrl}/account/payment_methods?client_secret=${clientSecret}`,
          PAYMENT_METHODS_CALL,
        )
      }

      APIUtils.fetchApiWrapper(~uri, ~method=Get, ~headers, ~eventName, ~apiLogWrapper)
    }
  }
}

let usePaymentMethodHook = (~customerLevel=false) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  () => {
    switch WebKit.platform {
    | #next => Promise.resolve(Next.clistRes)
    | _ =>
      APIUtils.fetchApiWrapper(
        ~uri=`${baseUrl}/${customerLevel
            ? "customers"
            : "account"}/payment_methods?client_secret=${nativeProp.clientSecret}`,
        ~method=Fetch.Get,
        ~headers=Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId),
        ~eventName={customerLevel ? CUSTOMER_PAYMENT_METHODS_CALL : PAYMENT_METHODS_CALL},
        ~apiLogWrapper,
      )
    }
  }
}

let useSessionTokenHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  (~wallet=[]) => {
    switch WebKit.platform {
    | #next => Promise.resolve(Next.sessionsRes)
    | _ =>
      APIUtils.fetchApiWrapper(
        ~uri=`${baseUrl}/payments/session_tokens`,
        ~body=PaymentUtils.generateSessionsTokenBody(
          ~clientSecret=nativeProp.clientSecret,
          ~wallet,
        ),
        ~method=Fetch.Post,
        ~headers=Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId),
        ~eventName=LoggerTypes.SESSIONS_CALL,
        ~apiLogWrapper,
      )
    }
  }
}

let useBrowserHook = () => {
  let retrievePayment = useRetrieveHook()
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
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
    let res = await BrowserHook.openUrl(
      openUrl,
      Utils.getReturnUrl(
        ~appId=nativeProp.hyperParams.appId,
        ~appURL=accountPaymentMethodData->Option.map(accountPaymentMethods =>
          accountPaymentMethods.redirect_url
        ),
      ),
      intervalId,
      ~useEphemeralWebSession,
      ~appearance=nativeProp.configuration.appearance,
    )

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
  let logger = LoggerHook.useLoggerHook()
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
    ~paymentExperience: option<array<AccountPaymentMethodType.payment_experience>>=?,
    ~responseCallback: (~paymentStatus: LoadingContext.sdkPaymentState, ~status: error) => unit,
    ~isCardPayment=false,
    (),
  ) => {
    let uriPram = String.split(clientSecret, "_secret_")->Array.get(0)->Option.getOr("")
    let uri = `${baseUrl}/payments/${uriPram}/confirm`
    let headers = Utils.getHeader(publishableKey, nativeProp.hyperParams.appId)

    let handleInvokeThreeDSFlow = (~nextAction) => {
      let netceteraSDKApiKey = nativeProp.configuration.netceteraSDKApiKey->Option.getOr("")
      handleNativeThreeDS(
        ~baseUrl,
        ~appId=nativeProp.hyperParams.appId,
        ~netceteraSDKApiKey,
        ~clientSecret,
        ~publishableKey,
        ~nextAction,
        ~retrievePayment,
        ~sdkEnvironment=nativeProp.env,
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
      // TODO: add event loggers for analytics
      let session_token = Option.getOr(nextAction, defaultNextAction).session_token
      let openProps = getOpenProps(retrievePayment, responseCallback, errorCallback)
      switch session_token {
      | Some(token) =>
        Plaid.create({token: token.open_banking_session_token})
        Plaid.open_(openProps)->ignore
      | None => ()
      }
    }

    let handleBankTransferFlow = (~nextAction) => {
      switch nextAction {
      | None => ()
      | Some(_data) => setLoading(ProcessingPayments)
      }
    }

    let handleDefaultPaymentFlows = (~status, ~reUri, ~error: error) => {
      let terminalStatusHandler = () => {status, message: "", code: "", type_: ""}

      switch status {
      | "succeeded" =>
        logger(
          ~logType=INFO,
          ~value="",
          ~category=USER_EVENT,
          ~eventName=PAYMENT_SUCCESS,
          ~paymentMethod,
          ~paymentExperience?,
          (),
        )
        responseCallback(~paymentStatus=PaymentSuccess, ~status=terminalStatusHandler())

      | "requires_capture"
      | "processing"
      | "requires_confirmation"
      | "requires_merchant_action" =>
        responseCallback(~paymentStatus=ProcessingPayments, ~status=terminalStatusHandler())
      | "requires_customer_action" =>
        terminalStatusHandler()->ignore
        logger(
          ~logType=INFO,
          ~category=USER_EVENT,
          ~value="",
          ~internalMetadata=reUri,
          ~eventName=REDIRECTING_USER,
          ~paymentMethod,
          (),
        )
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
        logger(
          ~logType=ERROR,
          ~value={statusVal ++ error.message->Option.getOr("")},
          ~category=USER_EVENT,
          ~eventName=PAYMENT_FAILED,
          ~paymentMethod,
          ~paymentExperience?,
          (),
        )
        errorCallback(~errorMessage=error, ~closeSDK=true, ())
        terminalStatusHandler()->ignore
      }
    }

    let handleApiRes = (~status, ~reUri, ~error: error, ~nextAction: option<nextAction>=?) => {
      switch nextAction->PaymentUtils.getActionType {
      | "three_ds_invoke" => handleInvokeThreeDSFlow(~nextAction)
      | "third_party_sdk_session_token" => handleThirdPartySDKSessionFlow(~nextAction)
      | "display_bank_transfer_information" => handleBankTransferFlow(~nextAction)
      | _ => handleDefaultPaymentFlows(~status, ~reUri, ~error)
      }
    }

    redirectionHandler(~body, ~errorCallback, ~handleApiRes, ~headers, ~uri)->ignore
  }
}

let useGetSavedPMHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  () => {
    switch WebKit.platform {
    | #next => Promise.resolve(Next.clistRes)
    | _ =>
      APIUtils.fetchApiWrapper(
        ~uri=`${baseUrl}/customers/payment_methods?client_secret=${nativeProp.clientSecret}`,
        ~method=Fetch.Get,
        ~headers=Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId),
        ~eventName=LoggerTypes.CUSTOMER_PAYMENT_METHODS_CALL,
        ~apiLogWrapper,
      )
    }
  }
}

let useDeleteSavedPaymentMethod = () => {
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  (~paymentMethodId: string) => {
    let uri = `${baseUrl}/payment_methods/${paymentMethodId}`
    apiLogWrapper(
      ~logType=INFO,
      ~eventName=DELETE_PAYMENT_METHODS_CALL_INIT,
      ~url=uri,
      ~statusCode="",
      ~apiLogType=Request,
      ~data=JSON.Encode.null,
      (),
    )

    if nativeProp.ephemeralKey->Option.isSome {
      APIUtils.fetchApiWrapper(
        ~uri,
        ~method=Fetch.Delete,
        ~headers=Utils.getHeader(
          nativeProp.ephemeralKey->Option.getOr(""),
          nativeProp.hyperParams.appId,
        ),
        ~eventName=LoggerTypes.DELETE_PAYMENT_METHODS_CALL,
        ~apiLogWrapper,
      )
    } else {
      JSON.Null->Promise.resolve
    }
  }
}

let useSavePaymentMethod = () => {
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  (~body: PaymentConfirmTypes.redirectType) => {
    let uriParam = nativeProp.paymentMethodId
    let uri = `${baseUrl}/payment_methods/${uriParam}/save`

    APIUtils.fetchApiWrapper(
      ~uri,
      ~method=Fetch.Post,
      ~headers=Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId),
      ~eventName=LoggerTypes.ADD_PAYMENT_METHOD_CALL,
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~apiLogWrapper,
    )
  }
}
