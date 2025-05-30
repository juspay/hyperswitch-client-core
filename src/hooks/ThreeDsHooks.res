open ExternalThreeDsTypes
open ThreeDsUtils
open SdkStatusMessages
open ThreeDsModuleType
open LoggerTypes

let isInitialisedPromiseRef = ref(None)

let initialisedSdkOnce = (
  ~sdkApiKey,
  ~sdkEnvironment,
  ~initialiseSdkFunc: (sdkConfig, statusType => unit) => unit,
) => {
  switch isInitialisedPromiseRef.contents {
  | Some(promiseVal) => promiseVal
  | None => {
      let promiseVal = Promise.make((resolve, _reject) => {
        let sdkConfig: sdkConfig = {
          apiKey: sdkApiKey,
          environment: sdkEnvironment,
        }
        initialiseSdkFunc(sdkConfig, status => resolve(status))
      })
      isInitialisedPromiseRef := Some(promiseVal)
      promiseVal
    }
  }
}

let useInitThreeDs = (
  ~initialiseSdkFunc: (sdkConfig, statusType => unit) => unit,
  ~sdkEventName: eventName,
) => {
  let logger = LoggerHook.useLoggerHook()
  (~sdkApiKey, ~sdkEnvironment: GlobalVars.envType) => {
    initialisedSdkOnce(~sdkApiKey, ~sdkEnvironment, ~initialiseSdkFunc)
    ->Promise.then(promiseVal => {
      logger(
        ~logType=INFO,
        ~value=promiseVal->JSON.stringifyAny->Option.getOr(""),
        ~category=USER_EVENT,
        ~eventName=sdkEventName,
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
  let (cardData, _) = React.useContext(CardDataContext.cardDataContext)

  (
    ~isSdkAvailableFunc: bool,
    ~initialiseSdkFunc: (sdkConfig, statusType => unit) => unit,
    ~generateAReqParamsFunc: (
      string,
      string,
      option<string>, // cardNetworkForTridentOnly
      (statusType, ExternalThreeDsTypes.aReqParams) => unit,
    ) => unit,
    ~receiveChallengeParamsFunc: (
      string,
      string,
      string,
      string,
      statusType => unit,
      option<string>,
    ) => unit,
    ~generateChallengeFunc: (statusType => unit) => unit,
    ~baseUrl,
    ~appId,
    ~sdkApiKey,
    ~clientSecret,
    ~publishableKey,
    ~nextAction,
    ~sdkEnvironment: GlobalVars.envType,
    ~retrievePayment: (Types.retrieve, string, string, ~isForceSync: bool=?) => promise<Js.Json.t>,
    ~onSuccess: string => unit,
    ~onFailure: string => unit,
    ~sdkEventName: eventName,
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
          logError(
            ~statusCode="504",
            ~apiLogType=NoResponse,
            ~data=err->Utils.getError("3DS SDK Error"),
          )
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
          ~data=err->Utils.getError("3DS SDK Error"),
          (),
        )
        Promise.resolve(true)
      })
    }

    let sendChallengeParamsAndGenerateChallenge = (~challengeParams) => {
      let threeDSRequestorAppURLForLog = Utils.getReturnUrl(
        ~appId,
        ~appURL=challengeParams.threeDSRequestorAppURL,
        ~useAppUrl=true,
      )
      Promise.make((resolve, reject) => {
        receiveChallengeParamsFunc(
          challengeParams.acsSignedContent,
          challengeParams.acsRefNumber,
          challengeParams.acsTransactionId,
          challengeParams.threeDSServerTransId,
          status => {
            logger(
              ~logType=INFO,
              ~value={
                "status": status.status,
                "message": status.message,
                "threeDSRequestorAppURL": threeDSRequestorAppURLForLog,
              }
              ->JSON.stringifyAny
              ->Option.getOr(""),
              ~category=USER_EVENT,
              ~eventName=sdkEventName,
              (),
            )
            if status->isStatusSuccess {
              generateChallengeFunc(status => {
                logger(
                  ~logType=INFO,
                  ~value={
                    "status": status.status,
                    "message": status.message,
                  }
                  ->JSON.stringifyAny
                  ->Option.getOr(""),
                  ~category=USER_EVENT,
                  ~eventName=sdkEventName,
                  (),
                )
                resolve()
              })
            } else {
              retrieveAndShowStatus()
              reject()
            }
          },
          challengeParams.threeDSRequestorAppURL,
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
              ~data=err,
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
          ~data=err->Utils.getError("3DS SDK Error"),
          (),
        )
        Promise.resolve(FrictionlessFlow)
      })
    }

    let startThreeDsFlow = () => {
      initialisedSdkOnce(~sdkApiKey, ~sdkEnvironment, ~initialiseSdkFunc)
      ->Promise.then(statusInfo => {
        let isSuccess = statusInfo->isStatusSuccess

        logger(
          ~logType=INFO,
          ~value={
            "status": statusInfo.status,
            "message": statusInfo.message,
          }
          ->JSON.stringifyAny
          ->Option.getOr(""),
          ~category=USER_EVENT,
          ~eventName=sdkEventName,
          (),
        )
        if isSuccess {
          Promise.make((resolve, _reject) => {
            let cardNetwork = cardData.cardBrand
            generateAReqParamsFunc(
              threeDsData.messageVersion,
              threeDsData.directoryServerId,
              sdkEventName == LoggerTypes.TRIDENT_SDK ? Some(cardNetwork) : None,
              (status, aReqParams) => {
                logger(
                  ~logType=INFO,
                  ~value={
                    "status": status.status,
                    "message": status.message,
                  }
                  ->JSON.stringifyAny
                  ->Option.getOr(""),
                  ~category=USER_EVENT,
                  ~eventName=sdkEventName,
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
      ->Promise.catch(_ => {
        Promise.resolve(RetrieveAgain)
      })
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
        if !isSdkAvailableFunc {
          logger(
            ~logType=DEBUG,
            ~value="3DS SDK dependency not added or not available",
            ~category=USER_EVENT,
            ~eventName=sdkEventName,
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
        let aReqParams = await startThreeDsFlow()
        let authCallDecision = await hsThreeDsAuthCall(aReqParams)

        switch authCallDecision {
        | GenerateChallenge({challengeParams}) =>
          await sendChallengeParamsAndGenerateChallenge(~challengeParams)
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
