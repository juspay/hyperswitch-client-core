open ExternalThreeDsTypes
open ThreeDsUtils
open SdkStatusMessages
external toJson: 't => JSON.t = "%identity"
let useNetceteraThreeDsHook = () => {
  let logger = LoggerHook.useLoggerHook()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let isNetceteraSDKInitialised = React.useRef(false)

  (
    (~netceteraSDKApiKey, ~sdkEnvironment: GlobalVars.envType) => {
      if !isNetceteraSDKInitialised.current {
        Netcetera3dsModule.initialiseNetceteraSDK(
          netceteraSDKApiKey,
          sdkEnvironment->sdkEnvironmentToStrMapper,
          status => {
            logger(
              ~logType=INFO,
              ~value=status->JSON.stringifyAny->Option.getOr(""),
              ~category=USER_EVENT,
              ~eventName=NETCETERA_SDK,
              (),
            )
            isNetceteraSDKInitialised.current = status->isStatusSuccess
          },
        )
      }
    },
    (
      ~baseUrl,
      ~netceteraSDKApiKey,
      ~clientSecret,
      ~publishableKey,
      ~nextAction,
      ~sdkEnvironment: GlobalVars.envType,
      ~retrievePayment,
      ~onSuccess: string => unit,
      ~onFailure: string => unit,
    ) => {
      let threeDsData =
        nextAction->ThreeDsUtils.getThreeDsNextActionObj->ThreeDsUtils.getThreeDsDataObj

      let rec shortPollExternalThreeDsAuthStatus = (
        ~pollConfig: PaymentConfirmTypes.pollConfig,
        ~pollCount,
        ~onPollCompletion: (~isFinalRetrieve: bool=?) => unit,
      ) => {
        if pollCount >= pollConfig.frequency {
          onPollCompletion()
        } else {
          setLoading(ProcessingPayments)
          let uri = `${baseUrl}/poll/status/${pollConfig.pollId}`
          apiLogWrapper(
            ~logType=INFO,
            ~eventName=POLL_STATUS_CALL_INIT,
            ~url=uri,
            ~statusCode="",
            ~apiLogType=Request,
            ~data=JSON.Encode.null,
            (),
          )

          let headers = getAuthCallHeaders(publishableKey)
          CommonHooks.fetchApi(~uri, ~headers, ~method_=Fetch.Get, ())
          ->Promise.then(data => {
            let statusCode = data->Fetch.Response.status->string_of_int
            if statusCode->String.charAt(0) === "2" {
              data
              ->Fetch.Response.json
              ->Promise.then(res => {
                let pollResponse =
                  res
                  ->Utils.getDictFromJson
                  ->ExternalThreeDsTypes.pollResponseItemToObjMapper

                let logData =
                  [
                    ("url", uri->JSON.Encode.string),
                    ("statusCode", statusCode->JSON.Encode.string),
                    ("response", pollResponse.status->JSON.Encode.string),
                  ]
                  ->Dict.fromArray
                  ->JSON.Encode.object
                apiLogWrapper(
                  ~logType=INFO,
                  ~eventName=POLL_STATUS_CALL,
                  ~url=uri,
                  ~statusCode,
                  ~apiLogType=Response,
                  ~data=logData,
                  (),
                )
                if pollResponse.status === "completed" {
                  onPollCompletion()
                } else {
                  setTimeout(
                    () => {
                      shortPollExternalThreeDsAuthStatus(
                        ~pollConfig,
                        ~pollCount=pollCount + 1,
                        ~onPollCompletion,
                      )
                    },
                    pollConfig.delayInSecs * 1000,
                  )->ignore
                }
                Some(data)->Promise.resolve
              })
            } else {
              data
              ->Fetch.Response.json
              ->Promise.then(res => {
                apiLogWrapper(
                  ~logType=ERROR,
                  ~eventName=POLL_STATUS_CALL,
                  ~url=uri,
                  ~statusCode,
                  ~apiLogType=Err,
                  ~data=res,
                  (),
                )
                Some(data)->Promise.resolve
              })
              ->ignore
              onPollCompletion()
              Some(data)->Promise.resolve
            }
          })
          ->Promise.catch(err => {
            apiLogWrapper(
              ~logType=ERROR,
              ~eventName=POLL_STATUS_CALL,
              ~url=uri,
              ~statusCode="504",
              ~apiLogType=NoResponse,
              ~data=err->toJson,
              (),
            )
            onPollCompletion()
            Promise.resolve(None)
          })
          ->ignore
        }
      }

      let rec retrieveAndShowStatus = (~isFinalRetrieve=?) => {
        apiLogWrapper(
          ~logType=INFO,
          ~eventName=RETRIEVE_CALL_INIT,
          ~url=baseUrl,
          ~statusCode="",
          ~apiLogType=Request,
          ~data=JSON.Encode.null,
          (),
        )
        setLoading(ProcessingPayments)

        retrievePayment(Types.Payment, clientSecret, publishableKey)
        ->Promise.then(res => {
          if res == JSON.Encode.null {
            onFailure(retrievePaymentStatus.apiCallFailure)
          } else {
            let status = res->Utils.getDictFromJson->Utils.getString("status", "")
            let isFinalRetrieve = isFinalRetrieve->Option.getOr(true)
            switch (status, isFinalRetrieve) {
            | ("processing" | "succeeded", _) => onSuccess(retrievePaymentStatus.successMsg)
            | ("failed", _) => onFailure(retrievePaymentStatus.errorMsg)
            | (_, true) => onFailure(retrievePaymentStatus.errorMsg)
            | (_, false) =>
              shortPollExternalThreeDsAuthStatus(
                ~pollConfig=threeDsData.pollConfig,
                ~pollCount=0,
                ~onPollCompletion=retrieveAndShowStatus,
              )
            }
          }->ignore
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          onFailure(retrievePaymentStatus.apiCallFailure)
          Promise.resolve()
        })
        ->ignore
      }

      let hsAuthorizeCall = (~authorizeUrl) => {
        apiLogWrapper(
          ~logType=INFO,
          ~eventName=AUTHORIZE_CALL_INIT,
          ~url=authorizeUrl,
          ~statusCode="",
          ~apiLogType=Request,
          ~data=JSON.Encode.null,
          (),
        )
        let headers = [("Content-Type", "application/json")]->Dict.fromArray
        CommonHooks.fetchApi(~uri=authorizeUrl, ~bodyStr="", ~headers, ~method_=Fetch.Post, ())
        ->Promise.then(data => {
          setLoading(ProcessingPayments)
          let statusCode = data->Fetch.Response.status->string_of_int
          if statusCode->String.charAt(0) === "2" {
            apiLogWrapper(
              ~logType=INFO,
              ~eventName=AUTHORIZE_CALL,
              ~url=authorizeUrl,
              ~statusCode,
              ~apiLogType=Response,
              ~data=JSON.Encode.null,
              (),
            )
            retrieveAndShowStatus(~isFinalRetrieve=false)
            Some(data)->Promise.resolve
          } else {
            data
            ->Fetch.Response.json
            ->Promise.then(error => {
              apiLogWrapper(
                ~logType=ERROR,
                ~eventName=AUTHORIZE_CALL,
                ~url=authorizeUrl,
                ~statusCode,
                ~apiLogType=Err,
                ~data=error,
                (),
              )
              retrieveAndShowStatus(~isFinalRetrieve=false)
              Some(data)->Promise.resolve
            })
          }
        })
        ->Promise.catch(err => {
          apiLogWrapper(
            ~logType=ERROR,
            ~eventName=AUTHORIZE_CALL,
            ~url=authorizeUrl,
            ~statusCode="504",
            ~apiLogType=NoResponse,
            ~data=err->toJson,
            (),
          )
          retrieveAndShowStatus()
          Promise.resolve(None)
        })
      }

      let sendChallengeParamsAndGenerateChallenge = (~challengeParams) => {
        Netcetera3dsModule.recieveChallengeParamsFromRN(
          challengeParams.acsSignedContent,
          challengeParams.acsRefNumber,
          challengeParams.acsTransactionId,
          challengeParams.threeDSRequestorURL,
          challengeParams.threeDSServerTransId,
          status => {
            logger(
              ~logType=INFO,
              ~value=status->JSON.stringifyAny->Option.getOr(""),
              ~category=USER_EVENT,
              ~eventName=NETCETERA_SDK,
              (),
            )
            status->isStatusSuccess
              ? Netcetera3dsModule.generateChallenge(status => {
                  logger(
                    ~logType=INFO,
                    ~value=status->JSON.stringifyAny->Option.getOr(""),
                    ~category=USER_EVENT,
                    ~eventName=NETCETERA_SDK,
                    (),
                  )
                  setLoading(ProcessingPayments)
                  let authorizeUrl = threeDsData.threeDsAuthorizeUrl
                  hsAuthorizeCall(~authorizeUrl)->ignore

                  // status->isStatusSuccess
                  //   ? {
                  //       let authorizeUrl = threeDsData.threeDsAuthorizeUrl
                  //       hsAuthorizeCall(~authorizeUrl, ~onSuccess, ~onFailure)->ignore
                  //     }
                  //   : retrieveAndShowStatus()
                })
              : retrieveAndShowStatus()
          },
        )
      }

      let hsThreeDsAuthCall = (aReqParams: aReqParams) => {
        let uri = threeDsData.threeDsAuthenticationUrl
        let bodyStr = generateAuthenticationCallBody(clientSecret, aReqParams)
        let headers = getAuthCallHeaders(publishableKey)

        apiLogWrapper(
          ~logType=INFO,
          ~eventName=AUTHENTICATION_CALL_INIT,
          ~url=uri,
          ~statusCode="",
          ~apiLogType=Request,
          ~data=JSON.Encode.null,
          (),
        )

        CommonHooks.fetchApi(~uri, ~bodyStr, ~headers, ~method_=Post, ())
        ->Promise.then(data => {
          let statusCode = data->Fetch.Response.status->string_of_int
          if statusCode->String.charAt(0) === "2" {
            data
            ->Fetch.Response.json
            ->Promise.then(res => {
              apiLogWrapper(
                ~logType=INFO,
                ~eventName=AUTHENTICATION_CALL,
                ~url=uri,
                ~statusCode,
                ~apiLogType=Response,
                ~data=JSON.Encode.null,
                (),
              )
              let authResponse = res->authResponseItemToObjMapper

              switch authResponse {
              | AUTH_RESPONSE(challengeParams) =>
                logger(
                  ~logType=INFO,
                  ~value=challengeParams.transStatus,
                  ~category=USER_EVENT,
                  ~eventName=DISPLAY_THREE_DS_SDK,
                  (),
                )
                switch challengeParams.transStatus {
                | "C" => {
                    setLoading(ExternalThreeDSLoading)
                    sendChallengeParamsAndGenerateChallenge(~challengeParams)
                  }
                | _ => hsAuthorizeCall(~authorizeUrl=threeDsData.threeDsAuthorizeUrl)->ignore
                }
              | AUTH_ERROR(errObj) => {
                  logger(
                    ~logType=ERROR,
                    ~value=errObj.errorMessage,
                    ~category=USER_EVENT,
                    ~eventName=DISPLAY_THREE_DS_SDK,
                    (),
                  )
                  hsAuthorizeCall(~authorizeUrl=threeDsData.threeDsAuthorizeUrl)->ignore
                }
              }

              Some(data)->Promise.resolve
            })
          } else {
            data
            ->Fetch.Response.json
            ->Promise.then(err => {
              apiLogWrapper(
                ~logType=ERROR,
                ~eventName=AUTHENTICATION_CALL,
                ~url=uri,
                ~statusCode,
                ~apiLogType=Err,
                ~data=err->toJson,
                (),
              )
              hsAuthorizeCall(~authorizeUrl=threeDsData.threeDsAuthorizeUrl)->ignore
              Some(data)->Promise.resolve
            })
          }
        })
        ->Promise.catch(err => {
          apiLogWrapper(
            ~logType=ERROR,
            ~eventName=AUTHENTICATION_CALL,
            ~url=uri,
            ~statusCode="504",
            ~apiLogType=NoResponse,
            ~data=err->toJson,
            (),
          )
          Promise.resolve(None)
        })
      }

      let startNetcetera3DSFlow = () => {
        try {
          Netcetera3dsModule.initialiseNetceteraSDK(
            netceteraSDKApiKey,
            sdkEnvironment->sdkEnvironmentToStrMapper,
            status => {
              status->isStatusSuccess
                ? Netcetera3dsModule.generateAReqParams(
                    threeDsData.messageVersion,
                    threeDsData.directoryServerId,
                    (aReqParams, status) => {
                      logger(
                        ~logType=INFO,
                        ~value=status->JSON.stringifyAny->Option.getOr(""),
                        ~category=USER_EVENT,
                        ~eventName=NETCETERA_SDK,
                        (),
                      )
                      status->isStatusSuccess
                        ? hsThreeDsAuthCall(aReqParams)->ignore
                        : retrieveAndShowStatus()
                    },
                  )
                : retrieveAndShowStatus()
            },
          )
        } catch {
        | _ => retrieveAndShowStatus()
        }
      }

      let handleNativeThreeDs = () => {
        if !Netcetera3dsModule.isAvailable {
          logger(
            ~logType=DEBUG,
            ~value="Netcetera SDK dependency not added",
            ~category=USER_EVENT,
            ~eventName=NETCETERA_SDK,
            (),
          )
          onFailure(externalThreeDsModuleStatus.errorMsg)
        } else {
          startNetcetera3DSFlow()->ignore
        }
      }
      handleNativeThreeDs()
    },
  )
}
