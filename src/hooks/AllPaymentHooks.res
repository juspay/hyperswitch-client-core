open PaymentConfirmTypes

external parse: Fetch.response => JSON.t = "%identity"
external toJson: 't => JSON.t = "%identity"

type apiLogType = Request | Response | NoResponse | Err
external jsonToString: JSON.t => string = "%identity"

let useApiLogWrapper = () => {
  let logger = LoggerHook.useLoggerHook()
  (
    ~logType,
    ~eventName,
    ~url,
    ~statusCode,
    ~apiLogType,
    ~data,
    ~paymentMethod=?,
    ~paymentExperience=?,
    (),
  ) => {
    let (value, internalMetadata) = switch apiLogType {
    | Request => ([("url", url->JSON.Encode.string)], [])
    | Response => (
        [("url", url->JSON.Encode.string), ("statusCode", statusCode->JSON.Encode.string)],
        [("response", data)],
      )
    | NoResponse => (
        [
          ("url", url->JSON.Encode.string),
          ("statusCode", "504"->JSON.Encode.string),
          ("response", data),
        ],
        [("response", data)],
      )
    | Err => (
        [
          ("url", url->JSON.Encode.string),
          ("statusCode", statusCode->JSON.Encode.string),
          ("response", data),
        ],
        [("response", data)],
      )
    }
    logger(
      ~logType,
      ~value=value->Dict.fromArray->JSON.Encode.object->JSON.stringify,
      ~internalMetadata=internalMetadata->Dict.fromArray->JSON.Encode.object->JSON.stringify,
      ~category=API,
      ~eventName,
      ~paymentMethod?,
      ~paymentExperience?,
      (),
    )
  }
}

let useHandleSuccessFailure = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {exit} = HyperModule.useExitPaymentsheet()
  let exitCard = HyperModule.useExitCard()
  let exitWidget = HyperModule.useExitWidget()
  (~apiResStatus: error, ~closeSDK=true, ~reset=true, ()) => {
    switch nativeProp.sdkState {
    | PaymentSheet | HostedCheckout =>
      if closeSDK {
        exit(apiResStatus, reset)
      }
    | CardWidget => exitCard(apiResStatus)
    | WidgetPaymentSheet =>
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

let useSessionToken = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()

  (~wallet=[], ()) => {
    switch Next.getNextEnv {
    | "next" => Promise.resolve(Next.sessionsRes)
    | _ =>
      let headers = Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId)
      let url = `${baseUrl}/payments/session_tokens`
      let body =
        [
          (
            "payment_id",
            String.split(nativeProp.clientSecret, "_secret_")
            ->Array.get(0)
            ->Option.getOr("")
            ->JSON.Encode.string,
          ),
          ("client_secret", nativeProp.clientSecret->JSON.Encode.string),
          ("wallets", wallet->JSON.Encode.array),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
        ->JSON.stringify
      apiLogWrapper(
        ~logType=INFO,
        ~eventName=SESSIONS_CALL_INIT,
        ~url,
        ~statusCode="",
        ~apiLogType=Request,
        ~data=JSON.Encode.null,
        (),
      )
      CommonHooks.fetchApi(~uri=url, ~method_=Post, ~headers, ~bodyStr=body, ())
      ->Promise.then(data => {
        let statusCode = data->Fetch.Response.status->string_of_int
        if statusCode->String.charAt(0) === "2" {
          apiLogWrapper(
            ~logType=INFO,
            ~eventName=SESSIONS_CALL,
            ~url,
            ~statusCode,
            ~apiLogType=Response,
            ~data=JSON.Encode.null,
            (),
          )
          data->Fetch.Response.json
        } else {
          data
          ->Fetch.Response.json
          ->Promise.then(error => {
            let value =
              [
                ("url", url->JSON.Encode.string),
                ("statusCode", statusCode->JSON.Encode.string),
                ("response", error),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object
            apiLogWrapper(
              ~logType=ERROR,
              ~eventName=SESSIONS_CALL,
              ~url,
              ~statusCode,
              ~apiLogType=Err,
              ~data=value,
              (),
            )
            Promise.resolve(error)
          })
        }
      })
      ->Promise.catch(err => {
        apiLogWrapper(
          ~logType=ERROR,
          ~eventName=SESSIONS_CALL,
          ~url,
          ~statusCode="504",
          ~apiLogType=NoResponse,
          ~data=err->toJson,
          (),
        )
        Promise.resolve(JSON.Encode.null)
      })
    }
  }
}

let useRetrieveHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  (type_, clientSecret, publishableKey) => {
    switch (Next.getNextEnv, type_) {
    | ("next", Types.List) => Promise.resolve(Next.listRes)
    | (_, type_) =>
      let headers = Utils.getHeader(publishableKey, nativeProp.hyperParams.appId)
      let (
        uri,
        eventName: LoggerTypes.eventName,
        initEventName: LoggerTypes.eventName,
      ) = switch type_ {
      | Payment => (
          `${baseUrl}/payments/${String.split(clientSecret, "_secret_")
            ->Array.get(0)
            ->Option.getOr("")}?force_sync=false&client_secret=${clientSecret}`,
          RETRIEVE_CALL,
          RETRIEVE_CALL_INIT,
        )
      | List => (
          `${baseUrl}/account/payment_methods?client_secret=${clientSecret}`,
          PAYMENT_METHODS_CALL,
          PAYMENT_METHODS_CALL_INIT,
        )
      }
      apiLogWrapper(
        ~logType=INFO,
        ~eventName=initEventName,
        ~url=uri,
        ~statusCode="",
        ~apiLogType=Request,
        ~data=JSON.Encode.null,
        (),
      )

      CommonHooks.fetchApi(~uri, ~method_=Get, ~headers, ())
      ->Promise.then(data => {
        let statusCode = data->Fetch.Response.status->string_of_int
        if statusCode->String.charAt(0) === "2" {
          apiLogWrapper(
            ~logType=INFO,
            ~eventName,
            ~url=uri,
            ~statusCode,
            ~apiLogType=Response,
            ~data=JSON.Encode.null,
            (),
          )
          data->Fetch.Response.json
        } else {
          data
          ->Fetch.Response.json
          ->Promise.then(error => {
            let value =
              [
                ("url", uri->JSON.Encode.string),
                ("statusCode", statusCode->JSON.Encode.string),
                ("response", error),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object

            apiLogWrapper(
              ~logType=ERROR,
              ~eventName,
              ~url=uri,
              ~statusCode,
              ~apiLogType=Err,
              ~data=value,
              (),
            )
            Promise.resolve(error)
          })
        }
      })
      ->Promise.catch(err => {
        apiLogWrapper(
          ~logType=ERROR,
          ~eventName,
          ~url=uri,
          ~statusCode="504",
          ~apiLogType=NoResponse,
          ~data=err->toJson,
          (),
        )
        Promise.resolve(JSON.Encode.null)
      })
    }
  }
}

let useBrowserHook = () => {
  let retrievePayment = useRetrieveHook()
  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let intervalId = React.useRef(Nullable.null)
  (~clientSecret, ~publishableKey, ~openUrl, ~responseCallback, ~errorCallback, ~processor) => {
    BrowserHook.openUrl(openUrl, nativeProp.hyperParams.appId, intervalId)
    ->Promise.then(res => {
      if res.error === Success {
        retrievePayment(Payment, clientSecret, publishableKey)
        ->Promise.then(s => {
          if s == JSON.Encode.null {
            setAllApiData({
              ...allApiData,
              additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
            })
            errorCallback(~errorMessage=defaultConfirmError, ~closeSDK=true, ())
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
                ~paymentStatus=LoadingContext.ProcessingPayments(None),
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
          Promise.resolve()
        })
        ->ignore
      } else if res.error == Cancel {
        setAllApiData({
          ...allApiData,
          additionalPMLData: {
            ...allApiData.additionalPMLData,
            retryEnabled: Some({
              processor,
              redirectUrl: openUrl,
            }),
          },
        })
        errorCallback(
          ~errorMessage={status: "cancelled", message: "", type_: "", code: ""},
          ~closeSDK={false},
          (),
        )
      } else if res.error === Failed {
        setAllApiData({
          ...allApiData,
          additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
        })
        errorCallback(
          ~errorMessage={status: "failed", message: "", type_: "", code: ""},
          ~closeSDK={true},
          (),
        )
      } else {
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
    })
    ->ignore
  }
}

let useRedirectHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let redirectioBrowserHook = useBrowserHook()
  let retrievePayment = useRetrieveHook()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let logger = LoggerHook.useLoggerHook()
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let handleNativeThreeDS = NetceteraThreeDsHooks.useExternalThreeDs()

  (
    ~body: string,
    ~publishableKey: string,
    ~clientSecret: string,
    ~errorCallback: (~errorMessage: error, ~closeSDK: bool, unit) => unit,
    ~paymentMethod,
    ~paymentExperience: option<PaymentMethodListType.payment_experience_type>=?,
    ~responseCallback: (~paymentStatus: LoadingContext.sdkPaymentState, ~status: error) => unit,
    (),
  ) => {
    let uriPram = String.split(clientSecret, "_secret_")->Array.get(0)->Option.getOr("")
    let uri = `${baseUrl}/payments/${uriPram}/confirm`
    let headers = Utils.getHeader(publishableKey, nativeProp.hyperParams.appId)

    let handleApiRes = (~status, ~reUri, ~error: error, ~nextAction: option<nextAction>=?) => {
      switch nextAction->ThreeDsUtils.getActionType {
      | "three_ds_invoke" => {
          let netceteraSDKApiKey = nativeProp.configuration.netceteraSDKApiKey->Option.getOr("")

          handleNativeThreeDS(
            ~baseUrl,
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
      | _ =>
        switch status {
        | "succeeded" =>
          logger(
            ~logType=INFO,
            ~value="",
            ~category=USER_EVENT,
            ~eventName=PAYMENT_SUCCESS,
            ~paymentMethod={paymentMethod},
            ~paymentExperience?,
            (),
          )
          setAllApiData({
            ...allApiData,
            additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
          })
          responseCallback(
            ~paymentStatus=PaymentSuccess,
            ~status={status, message: "", code: "", type_: ""},
          )
        | "requires_capture"
        | "processing"
        | "requires_confirmation"
        | "requires_merchant_action" => {
            setAllApiData({
              ...allApiData,
              additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
            })
            responseCallback(
              ~paymentStatus=ProcessingPayments(None),
              ~status={status, message: "", code: "", type_: ""},
            )
          }
        | "requires_customer_action" => {
            setAllApiData({
              ...allApiData,
              additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
            })
            logger(
              ~logType=INFO,
              ~category=USER_EVENT,
              ~value="",
              ~internalMetadata=reUri,
              ~eventName=REDIRECTING_USER,
              ~paymentMethod,
              (),
            )
            redirectioBrowserHook(
              ~clientSecret,
              ~publishableKey,
              ~openUrl=reUri,
              ~responseCallback,
              ~errorCallback,
              ~processor=body,
            )
          }
        | statusVal =>
          logger(
            ~logType=ERROR,
            ~value={statusVal ++ error.message->Option.getOr("")},
            ~category=USER_EVENT,
            ~eventName=PAYMENT_FAILED,
            ~paymentMethod={paymentMethod},
            ~paymentExperience?,
            (),
          )
          setAllApiData({
            ...allApiData,
            additionalPMLData: {...allApiData.additionalPMLData, retryEnabled: None},
          })
          errorCallback(
            ~errorMessage=error,
            //~closeSDK={error.code == "IR_16" || error.code == "HE_00"},
            ~closeSDK=true,
            (),
          )
        }
      }
    }

    switch allApiData.additionalPMLData.retryEnabled {
    | Some({redirectUrl, processor}) =>
      processor == body
        ? retrievePayment(Payment, clientSecret, publishableKey)
          ->Promise.then(res => {
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
            Promise.resolve()
          })
          ->ignore
        : {
            apiLogWrapper(
              ~logType=INFO,
              ~eventName=CONFIRM_CALL_INIT,
              ~url=uri,
              ~statusCode="",
              ~apiLogType=Request,
              ~data=JSON.Encode.null,
              (),
            )
            CommonHooks.fetchApi(~uri, ~method_=Post, ~headers, ~bodyStr=body, ())
            ->Promise.then(data => {
              let statusCode = data->Fetch.Response.status->string_of_int
              if statusCode->String.charAt(0) === "2" {
                apiLogWrapper(
                  ~logType=INFO,
                  ~eventName=CONFIRM_CALL,
                  ~url=uri,
                  ~statusCode,
                  ~apiLogType=Response,
                  ~data=JSON.Encode.null,
                  (),
                )
                data->Fetch.Response.json
              } else {
                data
                ->Fetch.Response.json
                ->Promise.then(error => {
                  let value =
                    [
                      ("url", uri->JSON.Encode.string),
                      ("statusCode", statusCode->JSON.Encode.string),
                      ("response", error),
                    ]
                    ->Dict.fromArray
                    ->JSON.Encode.object

                  apiLogWrapper(
                    ~logType=ERROR,
                    ~eventName=CONFIRM_CALL,
                    ~url=uri,
                    ~statusCode,
                    ~apiLogType=Response,
                    ~data=value,
                    (),
                  )
                  Promise.resolve(error)
                })
              }
            })
            ->Promise.then(jsonResponse => {
              let {nextAction, status, error} = itemToObjMapper(
                jsonResponse->JSON.Decode.object->Option.getOr(Dict.make()),
              )

              handleApiRes(~status, ~reUri=nextAction.redirectToUrl, ~error)
              Promise.resolve()
            })
            ->Promise.catch(err => {
              apiLogWrapper(
                ~logType=ERROR,
                ~eventName=CONFIRM_CALL,
                ~url=uri,
                ~statusCode="504",
                ~apiLogType=NoResponse,
                ~data=err->toJson,
                (),
              )
              errorCallback(~errorMessage=defaultConfirmError, ~closeSDK=false, ())
              Promise.resolve()
            })
            ->ignore
          }

    | _ => {
        apiLogWrapper(
          ~logType=INFO,
          ~eventName=CONFIRM_CALL_INIT,
          ~url=uri,
          ~statusCode="",
          ~apiLogType=Request,
          ~data=JSON.Encode.null,
          (),
        )
        CommonHooks.fetchApi(~uri, ~method_=Post, ~headers, ~bodyStr=body, ())
        ->Promise.then(data => {
          let statusCode = data->Fetch.Response.status->string_of_int
          if statusCode->String.charAt(0) === "2" {
            apiLogWrapper(
              ~logType=INFO,
              ~eventName=CONFIRM_CALL,
              ~url=uri,
              ~statusCode,
              ~apiLogType=Response,
              ~data=JSON.Encode.null,
              (),
            )
            data->Fetch.Response.json
          } else {
            data
            ->Fetch.Response.json
            ->Promise.then(error => {
              let value =
                [
                  ("url", uri->JSON.Encode.string),
                  ("statusCode", statusCode->JSON.Encode.string),
                  ("response", error),
                ]
                ->Dict.fromArray
                ->JSON.Encode.object

              apiLogWrapper(
                ~logType=ERROR,
                ~eventName=CONFIRM_CALL,
                ~url=uri,
                ~statusCode,
                ~apiLogType=Err,
                ~data=value,
                (),
              )
              Promise.resolve(error)
            })
          }
        })
        ->Promise.then(jsonResponse => {
          let confirmResponse = jsonResponse->JSON.Decode.object->Option.getOr(Dict.make())
          let {nextAction, status, error} = itemToObjMapper(confirmResponse)

          handleApiRes(~status, ~reUri=nextAction.redirectToUrl, ~error, ~nextAction)

          Promise.resolve()
        })
        ->Promise.catch(err => {
          apiLogWrapper(
            ~logType=ERROR,
            ~eventName=CONFIRM_CALL,
            ~url=uri,
            ~statusCode="504",
            ~apiLogType=NoResponse,
            ~data=err->toJson,
            (),
          )
          errorCallback(~errorMessage=defaultConfirmError, ~closeSDK=false, ())
          Promise.resolve()
        })
        ->ignore
      }
    }
  }
}

let useGetSavedPMHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  () => {
    // switch customer.id {
    // | Some(_id) =>
    let uri = `${baseUrl}/customers/payment_methods?client_secret=${nativeProp.clientSecret}`
    apiLogWrapper(
      ~logType=INFO,
      ~eventName=CUSTOMER_PAYMENT_METHODS_CALL_INIT,
      ~url=uri,
      ~statusCode="",
      ~apiLogType=Request,
      ~data=JSON.Encode.null,
      (),
    )
    CommonHooks.fetchApi(
      ~uri,
      ~method_=Get,
      ~headers=Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId),
      (),
    )
    ->Promise.then(data => {
      let statusCode = data->Fetch.Response.status->string_of_int
      if statusCode->String.charAt(0) === "2" {
        data
        ->Fetch.Response.json
        ->Promise.then(data => {
          apiLogWrapper(
            ~logType=INFO,
            ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
            ~url=uri,
            ~statusCode,
            ~apiLogType=Response,
            ~data=JSON.Encode.null,
            (),
          )
          Some(data)->Promise.resolve
        })
      } else {
        data
        ->Fetch.Response.json
        ->Promise.then(error => {
          let value =
            [
              ("url", uri->JSON.Encode.string),
              ("statusCode", statusCode->JSON.Encode.string),
              ("response", error),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object

          apiLogWrapper(
            ~logType=ERROR,
            ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
            ~url=uri,
            ~statusCode,
            ~apiLogType=Err,
            ~data=value,
            (),
          )
          None->Promise.resolve
        })
      }
    })
    ->Promise.catch(err => {
      apiLogWrapper(
        ~logType=ERROR,
        ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
        ~url=uri,
        ~statusCode="504",
        ~apiLogType=NoResponse,
        ~data=err->toJson,
        (),
      )
      None->Promise.resolve
    })
  }
}
