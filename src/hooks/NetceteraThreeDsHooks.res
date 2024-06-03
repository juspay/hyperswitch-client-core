open ExternalThreeDsTypes
open ThreeDsUtils
open SdkStatusMessages
external toJson: 't => JSON.t = "%identity"
let useNetceteraThreeDsHook = () => {
  let logger = LoggerHook.useLoggerHook()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()

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
    let retriveAndShowStatus = () => {
      retrievePayment(Types.Payment, clientSecret, publishableKey)
      ->Promise.then(res => {
        if res == JSON.Encode.null {
          onFailure(retrievePaymentStatus.apiCallFailure)
        } else {
          let status = res->Utils.getDictFromJson->Utils.getString("status", "")

          switch status {
          | "processing" | "succeeded" => onSuccess(retrievePaymentStatus.successMsg)
          | _ => onFailure(retrievePaymentStatus.errorMsg)
          }
        }->ignore
        Promise.resolve()
      })
      ->Promise.catch(_ => {
        onFailure(SdkStatusMessages.retrievePaymentStatus.apiCallFailure)
        Promise.resolve()
      })
      ->ignore
    }

    let shortPollexternalThreeDsAuthStatus = (
      ~pollConfig: PaymentConfirmTypes.pollConfig,
      ~onSuccess,
      ~onFailure: string => unit,
    ) => {
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

      let pollCounter = ref(0)
      let paymentStatus = ref("")

      let intervalId: ref<RescriptCore.intervalId> = ref(setInterval(() => (), 0))
      intervalId.contents = setInterval(() => {
        if pollCounter.contents >= pollConfig.frequency {
          clearInterval(intervalId.contents)
          if paymentStatus.contents !== "completed" {
            onSuccess()
          }
        }

        let headers = getAuthCallHeaders(publishableKey)
        CommonHooks.fetchApi(~uri, ~headers, ~method_=Fetch.Get, ())
        ->Promise.then(data => {
          pollCounter := pollCounter.contents + 1
          let statusCode = data->Fetch.Response.status->string_of_int
          if statusCode->String.charAt(0) === "2" {
            data
            ->Fetch.Response.json
            ->Promise.then(
              res => {
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

                paymentStatus := pollResponse.status
                if pollResponse.status === "completed" {
                  clearInterval(intervalId.contents)
                  onSuccess()
                }
                Some(data)->Promise.resolve
              },
            )
          } else {
            data
            ->Fetch.Response.json
            ->Promise.then(
              res => {
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
              },
            )
            ->ignore
            onFailure(pollingCallStatus.apiCallFailure)
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
          Promise.resolve(None)
        })
        ->ignore
      }, pollConfig.delayInSecs * 1000)
    }
    let hsAuthorizeCall = (
      ~authorizeUrl,
      ~onSuccess: string => unit,
      ~onFailure: string => unit,
    ) => {
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
          onSuccess("")
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
            retriveAndShowStatus()
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
        retriveAndShowStatus()
        Promise.resolve(None)
      })
    }
    let shortPollStatusAndRetrieve = (~pollConfig) => {
      shortPollexternalThreeDsAuthStatus(~pollConfig, ~onSuccess=retriveAndShowStatus, ~onFailure)
    }

    let sendChallengeParamsAndGenerateChallenge = (
      ~challengeParams,
      ~onSuccess: string => unit,
      ~onFailure: string => unit,
    ) => {
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
                status->isStatusSuccess
                  ? {
                      let authorizeUrl = threeDsData.threeDsAuthorizeUrl
                      hsAuthorizeCall(~authorizeUrl, ~onSuccess, ~onFailure)->ignore
                    }
                  : shortPollStatusAndRetrieve(~pollConfig=threeDsData.pollConfig)
              })
            : onFailure(threeDsSdkChallengeStatus.errorMsg)
        },
      )
    }

    let frictionlessAuthroiseAndContinue = (
      ~onSuccess: string => unit,
      ~onFailure: string => unit,
    ) => {
      hsAuthorizeCall(~authorizeUrl=threeDsData.threeDsAuthorizeUrl, ~onSuccess, ~onFailure)->ignore
    }

    let hsThreeDsAuthCall = (
      aReqParams: aReqParams,
      onSuccess: string => unit,
      onFailure: string => unit,
    ) => {
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
              | "C" =>
                sendChallengeParamsAndGenerateChallenge(~challengeParams, ~onSuccess, ~onFailure)
              | _ => frictionlessAuthroiseAndContinue(~onSuccess, ~onFailure)
              }
            | AUTH_ERROR(errObj) => {
                logger(
                  ~logType=ERROR,
                  ~value=errObj.errorMessage,
                  ~category=USER_EVENT,
                  ~eventName=DISPLAY_THREE_DS_SDK,
                  (),
                )
                frictionlessAuthroiseAndContinue(~onSuccess, ~onFailure)
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
            frictionlessAuthroiseAndContinue(~onSuccess, ~onFailure)
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

    let startNetcetera3DSFlow = (
      ~netceteraSDKApiKey: string,
      ~onSuccess: string => unit,
      ~onFailure: string => unit,
    ) => {
      try {
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
                      ? hsThreeDsAuthCall(aReqParams, onSuccess, onFailure)->ignore
                      : onFailure(threeDsSDKGetAReqStatus.errorMsg)
                  },
                )
              : onFailure(status.message)
          },
        )
      } catch {
      | _ => retriveAndShowStatus()
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
      }

      let onChallengeCompletionCallback = message => {
        retrievePayment(Payment, clientSecret, publishableKey)
        ->Promise.then(res => {
          if res == JSON.Encode.null {
            onFailure(retrievePaymentStatus.apiCallFailure)
          } else {
            let status = res->Utils.getDictFromJson->Utils.getString("status", "")
            switch status {
            | "processing"
            | "succeeded" =>
              onSuccess(retrievePaymentStatus.successMsg)
            | "failed" => onFailure(retrievePaymentStatus.errorMsg)
            | _ => shortPollStatusAndRetrieve(~pollConfig=threeDsData.pollConfig)
            }
          }
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          onFailure(retrievePaymentStatus.apiCallFailure)
          Promise.resolve()
        })
        ->ignore
      }

      startNetcetera3DSFlow(
        ~netceteraSDKApiKey,
        ~onSuccess=onChallengeCompletionCallback,
        ~onFailure,
      )->ignore
    }
    handleNativeThreeDs()
  }
}
