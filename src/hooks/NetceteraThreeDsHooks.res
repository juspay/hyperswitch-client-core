open ExternalThreeDsTypes
open ThreeDsUtils
open SdkStatusMessages
external toJson: 't => JSON.t = "%identity"
let isInitialisedPromiseRef = ref(None)

let initialisedNetceteraOnce = (~netceteraSDKApiKey, ~sdkEnvironment) => {
  switch isInitialisedPromiseRef.contents {
  | Some(promiseVal) => promiseVal
  | None => {
      let promiseVal = Promise.make((resolve, _reject) => {
        Netcetera3dsModule.initialiseNetceteraSDK(
          netceteraSDKApiKey,
          sdkEnvironment->sdkEnvironmentToStrMapper,
          status => resolve(status),
        )
      })

      isInitialisedPromiseRef := Some(promiseVal)
      promiseVal
    }
  }
}

let useInitNetcetera = () => {
  let logger = LoggerHook.useLoggerHook()
  (~netceteraSDKApiKey, ~sdkEnvironment: GlobalVars.envType) => {
    initialisedNetceteraOnce(~netceteraSDKApiKey, ~sdkEnvironment)
    ->Promise.then(promiseVal => {
      logger(
        ~logType=INFO,
        ~value=promiseVal->JSON.stringifyAny->Option.getOr(""),
        ~category=USER_EVENT,
        ~eventName=NETCETERA_SDK,
        (),
      )
      Promise.resolve(promiseVal)
    })
    ->ignore
  }
}

type postAReqParamsGenerationDecision = RetrieveAgain | Make3DsCall(ExternalThreeDsTypes.aReqParams)
type threeDsAuthCallDecision =
  | GenerateChallenge({challengeParams: ExternalThreeDsTypes.authCallResponse})
  | FrictionlessFlow

let useExternalThreeDs = () => {
  let logger = LoggerHook.useLoggerHook()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  (
    ~baseUrl,
    ~netceteraSDKApiKey,
    ~clientSecret,
    ~publishableKey,
    ~nextAction,
    ~sdkEnvironment: GlobalVars.envType,
    ~retrievePayment: (
      Types.retrieve,
      string,
      string,
      ~isForceSync: bool=?,
    ) => promise<Js.Json.t>,
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
        setLoading(ProcessingPayments(None))
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

        let logInfo = (~statusCode, ~apiLogType, ~data) => {
          apiLogWrapper(
            ~logType=INFO,
            ~eventName=POLL_STATUS_CALL,
            ~url=uri,
            ~statusCode,
            ~apiLogType,
            ~data,
            (),
          )
        }
        let logError = (~statusCode, ~apiLogType, ~data) => {
          apiLogWrapper(
            ~logType=ERROR,
            ~eventName=POLL_STATUS_CALL,
            ~url=uri,
            ~statusCode,
            ~apiLogType,
            ~data,
            (),
          )
        }

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
              logInfo(~statusCode, ~apiLogType=Response, ~data=logData)
              if pollResponse.status === "completed" {
                Promise.resolve()
              } else {
                Promise.make(
                  (_resolve, _reject) => {
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
                  },
                )
              }
            })
          } else {
            data
            ->Fetch.Response.json
            ->Promise.thenResolve(res => {
              logError(~statusCode, ~apiLogType=Err, ~data=res)
            })
            ->ignore
            Promise.resolve()
          }
        })
        ->Promise.catch(err => {
          logError(~statusCode="504", ~apiLogType=NoResponse, ~data=err->toJson)
          Promise.resolve()
        })
        ->Promise.finally(_ => {
          onPollCompletion()
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
      setLoading(ProcessingPayments(None))

      retrievePayment(Types.Payment, clientSecret, publishableKey)
      ->Promise.then(res => {
        if res == JSON.Encode.null {
          onFailure(retrievePaymentStatus.apiCallFailure)
        } else {
          let status = res->Utils.getDictFromJson->Utils.getString("status", "")
          let isFinalRetrieve = isFinalRetrieve->Option.getOr(true)
          switch status {
          | "processing" | "succeeded" => onSuccess(retrievePaymentStatus.successMsg)
          | "failed" => onFailure(retrievePaymentStatus.errorMsg)
          | _ =>
            if isFinalRetrieve {
              onFailure(retrievePaymentStatus.errorMsg)
            } else {
              shortPollExternalThreeDsAuthStatus(
                ~pollConfig=threeDsData.pollConfig,
                ~pollCount=0,
                ~onPollCompletion=retrieveAndShowStatus,
              )
            }
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
      ->Promise.then(async data => {
        setLoading(ProcessingPayments(None))
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
        } else {
          await data
          ->Fetch.Response.json
          ->Promise.thenResolve(error => {
            apiLogWrapper(
              ~logType=ERROR,
              ~eventName=AUTHORIZE_CALL,
              ~url=authorizeUrl,
              ~statusCode,
              ~apiLogType=Err,
              ~data=error,
              (),
            )
          })
        }
        false
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

        Promise.resolve(true)
      })
    }

    let sendChallengeParamsAndGenerateChallenge = (~challengeParams) => {
      Promise.make((resolve, reject) => {
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
            if status->isStatusSuccess {
              Netcetera3dsModule.generateChallenge(
                status => {
                  logger(
                    ~logType=INFO,
                    ~value=status->JSON.stringifyAny->Option.getOr(""),
                    ~category=USER_EVENT,
                    ~eventName=NETCETERA_SDK,
                    (),
                  )

                  resolve()
                },
              )
            } else {
              retrieveAndShowStatus()
              reject()
            }
          },
        )
      })
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
          ->Promise.thenResolve(res => {
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
              | "C" => GenerateChallenge({challengeParams: challengeParams})
              | _ => FrictionlessFlow
              }
            | AUTH_ERROR(errObj) => {
                logger(
                  ~logType=ERROR,
                  ~value=errObj.errorMessage,
                  ~category=USER_EVENT,
                  ~eventName=DISPLAY_THREE_DS_SDK,
                  (),
                )
                FrictionlessFlow
              }
            }
          })
        } else {
          data
          ->Fetch.Response.json
          ->Promise.thenResolve(err => {
            apiLogWrapper(
              ~logType=ERROR,
              ~eventName=AUTHENTICATION_CALL,
              ~url=uri,
              ~statusCode,
              ~apiLogType=Err,
              ~data=err->toJson,
              (),
            )
            FrictionlessFlow
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
        Promise.resolve(FrictionlessFlow)
      })
    }

    let startNetcetera3DSFlow = () => {
      initialisedNetceteraOnce(~netceteraSDKApiKey, ~sdkEnvironment)
      ->Promise.then(statusInfo => {
        logger(
          ~logType=INFO,
          ~value=statusInfo->JSON.stringifyAny->Option.getOr(""),
          ~category=USER_EVENT,
          ~eventName=NETCETERA_SDK,
          (),
        )

        if statusInfo->isStatusSuccess {
          Promise.make((resolve, _reject) => {
            Netcetera3dsModule.generateAReqParams(
              threeDsData.messageVersion,
              threeDsData.directoryServerId,
              (status, aReqParams) => {
                logger(
                  ~logType=INFO,
                  ~value=status->JSON.stringifyAny->Option.getOr(""),
                  ~category=USER_EVENT,
                  ~eventName=NETCETERA_SDK,
                  (),
                )
                if status->isStatusSuccess {
                  resolve(Make3DsCall(aReqParams))
                } else {
                  resolve(RetrieveAgain)
                }
              },
            )
          })
        } else {
          Promise.resolve(RetrieveAgain)
        }
      })
      ->Promise.catch(_ => Promise.resolve(RetrieveAgain))
      ->Promise.then(decision => {
        Promise.make((resolve, reject) => {
          switch decision {
          | RetrieveAgain =>
            retrieveAndShowStatus()
            reject()
          | Make3DsCall(aReqParams) => resolve(aReqParams)
          }
        })
      })
    }

    let checkSDKPresence = () => {
      Promise.make((resolve, reject) => {
        if !Netcetera3dsModule.isAvailable {
          logger(
            ~logType=DEBUG,
            ~value="Netcetera SDK dependency not added",
            ~category=USER_EVENT,
            ~eventName=NETCETERA_SDK,
            (),
          )
          onFailure(externalThreeDsModuleStatus.errorMsg)
          reject()
        } else {
          resolve()
        }
      })
    }
    let handleNativeThreeDs = async () => {
      let isFinalRetrieve = try {
        await checkSDKPresence()
        let aReqParams = await startNetcetera3DSFlow()
        let authCallDecision = await hsThreeDsAuthCall(aReqParams)

        switch authCallDecision {
        | GenerateChallenge({challengeParams}) =>
          // setLoading(ExternalThreeDSLoading)
          await sendChallengeParamsAndGenerateChallenge(~challengeParams)
        // setLoading(ProcessingPayments)

        | FrictionlessFlow => ()
        }
        await hsAuthorizeCall(~authorizeUrl=threeDsData.threeDsAuthorizeUrl)
      } catch {
      | _ => true
      }

      retrieveAndShowStatus(~isFinalRetrieve)
    }
    handleNativeThreeDs()->ignore
  }
}
