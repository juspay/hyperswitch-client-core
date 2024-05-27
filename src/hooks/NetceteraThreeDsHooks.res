open ExternalThreeDsTypes
open ThreeDsUtils
open SdkStatusMessages

let useNetceteraThreeDsHook = (~retrievePayment) => {
  let logger = LoggerHook.useLoggerHook()
  let apiLogWrapper = LoggerHook.useApiLogWrapper()

  (
    ~baseUrl,
    ~netceteraSDKApiKey,
    ~clientSecret,
    ~publishableKey,
    ~nextAction,
    ~sdkEnvironment: GlobalVars.envType,
    ~onSuccess: string => unit,
    ~onFailure: string => unit,
  ) => {
    let retriveAndShowStatus = () => {
      apiLogWrapper(
        ~logType=INFO,
        ~eventName=RETRIEVE_CALL_INIT,
        ~url=baseUrl,
        ~statusCode="",
        ~apiLogType=Request,
        ~data=JSON.Encode.null,
        (),
      )
      retrievePayment(Types.Payment, clientSecret, publishableKey)
      ->Promise.then(res => {
        if res == JSON.Encode.null {
          onFailure(retrievePaymentStatus.apiCallFailure)
        } else {
          let status = res->Utils.getDictFromJson->Utils.getString("status", "")

          apiLogWrapper(
            ~logType=INFO,
            ~eventName=RETRIEVE_CALL,
            ~url=baseUrl,
            ~statusCode="",
            ~apiLogType=Response,
            ~data=res,
            (),
          )

          switch status {
          | "processing" | "succeeded" => onSuccess(retrievePaymentStatus.successMsg)
          | _ => onFailure(retrievePaymentStatus.errorMsg)
          }
        }->ignore
        Promise.resolve()
      })
      ->ignore
    }

    let shortPollexternalThreeDsAuthStatus = (
      ~baseUrl,
      ~pollConfig: PaymentConfirmTypes.pollConfig,
      ~publishableKey,
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
            apiLogWrapper(
              ~logType=ERROR,
              ~eventName=POLL_STATUS_CALL,
              ~url=uri,
              ~statusCode,
              ~apiLogType=Request,
              ~data=JSON.Encode.null,
              (),
            )
            onFailure(pollingCallStatus.apiCallFailure)
            Some(data)->Promise.resolve
          }
        })
        ->ignore
      }, pollConfig.delayInSecs * 1000)
    }
    let hsAuthoriseCall = (
      ~authoriseUrl,
      ~onSuccess: string => unit,
      ~onFailure: string => unit,
    ) => {
      apiLogWrapper(
        ~logType=INFO,
        ~eventName=AUTHORIZE_CALL_INIT,
        ~url=authoriseUrl,
        ~statusCode="",
        ~apiLogType=Request,
        ~data=JSON.Encode.null,
        (),
      )
      let headers = [("Content-Type", "application/json")]->Dict.fromArray
      CommonHooks.fetchApi(
        ~uri=authoriseUrl,
        ~bodyStr="",
        ~headers,
        ~method_=Fetch.Post,
        (),
      )->Promise.then(data => {
        let statusCode = data->Fetch.Response.status->string_of_int
        if statusCode->String.charAt(0) === "2" {
          apiLogWrapper(
            ~logType=INFO,
            ~eventName=AUTHORIZE_CALL,
            ~url=authoriseUrl,
            ~statusCode,
            ~apiLogType=Request,
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
              ~url=authoriseUrl,
              ~statusCode,
              ~apiLogType=Response,
              ~data=error,
              (),
            )
            retriveAndShowStatus()
            Some(data)->Promise.resolve
          })
        }
      })
    }
    let shortPollStatusAndRetrieve = (~pollConfig, ~publishableKey) => {
      shortPollexternalThreeDsAuthStatus(
        ~baseUrl,
        ~pollConfig,
        ~publishableKey,
        ~onSuccess=retriveAndShowStatus,
        ~onFailure,
      )
    }

    let sendChallengeParamsAndGenerateChallenge = (
      ~challengeParams,
      ~threeDsData: PaymentConfirmTypes.threeDsData,
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
                switch (status.status, status.message) {
                | ("success", _) => {
                    let authoriseUrl = threeDsData.threeDsAuthorizeUrl
                    hsAuthoriseCall(~authoriseUrl, ~onSuccess, ~onFailure)->ignore
                  }
                | (_, _) =>
                  shortPollStatusAndRetrieve(~pollConfig=threeDsData.pollConfig, ~publishableKey)
                }
              })
            : onFailure(threeDsSdkChallengeStatus.errorMsg)
        },
      )
    }

    let frictionlessAuthroiseAndContinue = (
      ~threeDsData: PaymentConfirmTypes.threeDsData,
      ~onSuccess: string => unit,
      ~onFailure: string => unit,
    ) => {
      hsAuthoriseCall(~authoriseUrl=threeDsData.threeDsAuthorizeUrl, ~onSuccess, ~onFailure)->ignore
    }

    let hsThreeDsAuthCall = (
      clientSecret: string,
      publishableKey: string,
      aReqParams: aReqParams,
      threeDsData: PaymentConfirmTypes.threeDsData,
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
                sendChallengeParamsAndGenerateChallenge(
                  ~challengeParams,
                  ~threeDsData,
                  ~onSuccess,
                  ~onFailure,
                )
              | _ => frictionlessAuthroiseAndContinue(~threeDsData, ~onSuccess, ~onFailure)
              }
            | AUTH_ERROR(errorObj) =>
              frictionlessAuthroiseAndContinue(~threeDsData, ~onSuccess, ~onFailure)
            }

            Some(data)->Promise.resolve
          })
        } else {
          data
          ->Fetch.Response.json
          ->Promise.then(error => {
            apiLogWrapper(
              ~logType=ERROR,
              ~eventName=AUTHENTICATION_CALL,
              ~url=uri,
              ~statusCode,
              ~apiLogType=Response,
              ~data=error,
              (),
            )
            frictionlessAuthroiseAndContinue(~threeDsData, ~onSuccess, ~onFailure)
            Some(data)->Promise.resolve
          })
        }
      })
      ->Promise.catch(err => {
        None->Promise.resolve
      })
    }

    let handleNetcetera3DS = (
      ~netceteraSDKApiKey: string,
      ~clientSecret: string,
      ~publishableKey: string,
      ~threeDsData: PaymentConfirmTypes.threeDsData,
      ~sdkEnvironment: GlobalVars.envType,
      ~onSuccess: string => unit,
      ~onFailure: string => unit,
    ) => {
      try {
        Netcetera3dsModule.initialiseNetceteraSDK(
          netceteraSDKApiKey,
          sdkEnvironment->sdkEnvironmentToStrMapper,
          threeDsData.messageVersion,
          threeDsData.directoryServerId,
          status => {
            logger(
              ~logType=INFO,
              ~value=status->JSON.stringifyAny->Option.getOr(""),
              ~category=USER_EVENT,
              ~eventName=NETCETERA_SDK,
              (),
            )
            status->isStatusSuccess
              ? Netcetera3dsModule.generateAReqParams((aReqParams, status) => {
                  logger(
                    ~logType=INFO,
                    ~value=status->JSON.stringifyAny->Option.getOr(""),
                    ~category=USER_EVENT,
                    ~eventName=NETCETERA_SDK,
                    (),
                  )
                  status->isStatusSuccess
                    ? hsThreeDsAuthCall(
                        clientSecret,
                        publishableKey,
                        aReqParams,
                        threeDsData,
                        onSuccess,
                        onFailure,
                      )->ignore
                    : onFailure(threeDsSDKGetAReqStatus.errorMsg)
                })
              : onFailure(status.message)
          },
        )
      } catch {
      | err => onFailure("")
      }
    }

    let handleNativeThreeDs = nextAction => {
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

      let threeDsData =
        nextAction->ThreeDsUtils.getThreeDsNextActionObj->ThreeDsUtils.getThreeDsDataObj

      let onChallengeCompletionCallback = message => {
        retrievePayment(Payment, clientSecret, publishableKey)
        ->Promise.then(res => {
          if res == JSON.Encode.null {
            onFailure(retrievePaymentStatus.apiCallFailure)
          } else {
            let status = res->Utils.getDictFromJson->Utils.getString("status", "")
            switch status {
            | "processing" => onSuccess(retrievePaymentStatus.successMsg)
            | "failed" => onFailure(retrievePaymentStatus.errorMsg)
            | _ => shortPollStatusAndRetrieve(~pollConfig=threeDsData.pollConfig, ~publishableKey)
            }
          }
          Promise.resolve()
        })
        ->ignore
      }

      handleNetcetera3DS(
        ~netceteraSDKApiKey,
        ~clientSecret,
        ~publishableKey,
        ~threeDsData,
        ~sdkEnvironment,
        ~onSuccess=onChallengeCompletionCallback,
        ~onFailure,
      )->ignore
    }
    handleNativeThreeDs(nextAction)
  }
}
