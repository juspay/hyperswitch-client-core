open ExternalThreeDsTypes
open ThreeDsUtils
open SdkStatusMessages
let isInitialisedPromiseRef = ref(None)

let netceteraFailure = (status: statusType) =>
  status->isStatusSuccess
    ? None
    : Some(
        LoggerUtils.summary(
          ~name=switch status.status {
          | "" => "UNKNOWN_STATUS"
          | status => status->LoggerUtils.screamingSnakeCase
          },
          ~message=status.message,
        ),
      )

// Netcetera reports failures as a returned status, so the logger classifies it
// instead of waiting for a rejection.
let observeNetcetera = (~event, ~details=?, ~timeoutMs=?, ~statusOf, ~call) =>
  SdkLogger.observeFunction(
    ~event,
    ~details?,
    ~timeoutMs?,
    ~failureOf=result => result->statusOf->netceteraFailure,
    ~detailsOf=result => [("status", (result->statusOf).status->JSON.Encode.string)],
    ~paymentMethod=Card,
    ~call,
  )

let initialisedNetceteraOnce = (~netceteraSDKApiKey, ~sdkEnvironment) => {
  switch isInitialisedPromiseRef.contents {
  | Some(promiseVal) => promiseVal
  | None => {
      let promiseVal = observeNetcetera(
        ~event=InitialiseNetcetera,
        ~statusOf=status => status,
        ~call=() =>
          Promise.make((resolve, _reject) => {
            Netcetera3dsModule.initialiseNetceteraSDK(
              netceteraSDKApiKey,
              sdkEnvironment->sdkEnvironmentToStrMapper,
              status => resolve(status),
            )
          }),
      )

      isInitialisedPromiseRef := Some(promiseVal)
      promiseVal
    }
  }
}

let useInitNetcetera = () => {
  (~netceteraSDKApiKey, ~sdkEnvironment: GlobalVars.envType) => {
    initialisedNetceteraOnce(~netceteraSDKApiKey, ~sdkEnvironment)->ignore
  }
}

type postAReqParamsGenerationDecision = RetrieveAgain | Make3DsCall(ExternalThreeDsTypes.aReqParams)
type threeDsAuthCallDecision =
  | GenerateChallenge({challengeParams: ExternalThreeDsTypes.authCallResponse})
  | FrictionlessFlow

let useExternalThreeDs = () => {
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  (
    ~baseUrl,
    ~appId,
    ~netceteraSDKApiKey,
    ~clientSecret,
    ~publishableKey,
    ~sdkAuthorization="",
    ~nextAction,
    ~sdkEnvironment: GlobalVars.envType,
    ~retrievePayment: (Types.retrieve, string, string, ~isForceSync: bool=?) => promise<Js.Json.t>,
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
        if pollCount > 0 {
          SdkLogger.logLifecycle(~event=PaymentStatusPollExhausted, ~paymentMethod=Card)
        }
        onPollCompletion()
      } else {
        setLoading(ProcessingPayments)
        let uri = `${baseUrl}/poll/status/${pollConfig.pollId}`
        let headers = getAuthCallHeaders(~publishableKey, ~sdkAuthorization, ())
        SdkLogger.observeApi(
          ~event=PollStatus,
          ~url=uri,
          ~failureOf=LoggerUtils.httpFailure,
          ~detailsOf=LoggerUtils.httpDetails,
          ~paymentMethod=Card,
          ~call=() => APIUtils.fetchApi(~uri, ~headers, ~method_=#GET),
        )
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
            Promise.resolve()
          }
        })
        ->Promise.catch(_ => Promise.resolve())
        ->Promise.finally(_ => {
          onPollCompletion()
        })
        ->ignore
      }
    }

    let rec retrieveAndShowStatus = (~isFinalRetrieve=?) => {
      setLoading(ProcessingPayments)

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
      ->Promise.catch(exn => {
        SdkLogger.logLifecycle(~event=PaymentErrorHandlingFailed, ~exn, ~paymentMethod=Card)
        onFailure(retrievePaymentStatus.apiCallFailure)
        Promise.resolve()
      })
      ->ignore
    }

    let hsAuthorizeCall = (~authorizeUrl) => {
      let headers = switch sdkAuthorization->String.length > 0 {
      | true =>
        [("Content-Type", "application/json"), ("Authorization", sdkAuthorization)]->Dict.fromArray
      | false => [("Content-Type", "application/json")]->Dict.fromArray
      }
      SdkLogger.observeApi(
        ~event=ThreeDsAuthorize,
        ~url=authorizeUrl,
        ~failureOf=LoggerUtils.httpBodyFailure,
        ~detailsOf=LoggerUtils.httpBodyDetails,
        ~paymentMethod=Card,
        ~call=async () => {
          let response = await APIUtils.fetchApi(
            ~uri=authorizeUrl,
            ~bodyStr="",
            ~headers,
            ~method_=#POST,
          )
          let data =
            response->Fetch.Response.ok ? JSON.Encode.null : await response->Fetch.Response.json
          (response, data)
        },
      )
      ->Promise.then(_ => {
        setLoading(ProcessingPayments)
        Promise.resolve(false)
      })
      ->Promise.catch(_ => Promise.resolve(true))
    }

    let sendChallengeParamsAndGenerateChallenge = async (~challengeParams) => {
      let threeDSRequestorAppURL = Utils.getReturnUrl(
        ~appId,
        ~appURL=challengeParams.threeDSRequestorAppURL,
        ~useAppUrl=true,
      )
      let status = await observeNetcetera(
        ~event=ReceiveChallengeParams,
        ~details=[("requestor_app_url", threeDSRequestorAppURL)]->LoggerUtils.stringDetails,
        ~statusOf=status => status,
        ~call=() =>
          Promise.make((resolve, _reject) => {
            Netcetera3dsModule.recieveChallengeParamsFromRN(
              challengeParams.acsSignedContent,
              challengeParams.acsRefNumber,
              challengeParams.acsTransactionId,
              challengeParams.threeDSServerTransId,
              resolve,
              threeDSRequestorAppURL,
            )
          }),
      )
      if status->isStatusSuccess {
        let _ = await observeNetcetera(
          ~event=GenerateChallenge,
          ~timeoutMs=LoggerConfig.userGatedTimeoutMs,
          ~statusOf=status => status,
          ~call=() =>
            Promise.make((resolve, _reject) => Netcetera3dsModule.generateChallenge(resolve)),
        )
      } else {
        retrieveAndShowStatus()
        Exn.raiseError("Netcetera rejected the challenge parameters")
      }
    }

    let hsThreeDsAuthCall = (aReqParams: aReqParams) => {
      let uri = threeDsData.threeDsAuthenticationUrl
      let bodyStr = generateAuthenticationCallBody(clientSecret, ~sdkAuthorization, aReqParams)
      let headers = getAuthCallHeaders(~publishableKey, ~sdkAuthorization, ())

      SdkLogger.observeApi(
        ~event=Authentication,
        ~url=uri,
        ~failureOf=LoggerUtils.httpBodyFailure,
        ~detailsOf=LoggerUtils.httpBodyDetails,
        ~details=bodyStr->LoggerUtils.payloadDetails,
        ~paymentMethod=Card,
        ~call=async () => {
          let response = await APIUtils.fetchApi(~uri, ~bodyStr, ~headers, ~method_=#POST)
          let data = await response->Fetch.Response.json
          (response, data)
        },
      )
      ->Promise.then(((response, res)) => {
        if response->Fetch.Response.ok {
          switch res->authResponseItemToObjMapper {
          | AUTH_RESPONSE(challengeParams) =>
            let transStatusData: SdkLogger.transStatusData = {
              transStatus: challengeParams.transStatus,
            }
            switch challengeParams.transStatus {
            | "C" =>
              SdkLogger.logLifecycle(
                ~event=ThreeDsChallengeShown(transStatusData),
                ~paymentMethod=Card,
              )
              GenerateChallenge({challengeParams: challengeParams})
            | _ =>
              SdkLogger.logLifecycle(
                ~event=ThreeDsFrictionlessResolved(transStatusData),
                ~paymentMethod=Card,
              )
              FrictionlessFlow
            }
          | AUTH_ERROR(errObj) =>
            SdkLogger.logLifecycle(
              ~event=ThreeDsAuthRequestFailed,
              ~paymentMethod=Card,
              ~message=errObj.errorMessage,
            )
            FrictionlessFlow
          }
        } else {
          SdkLogger.logLifecycle(~event=ThreeDsAuthRequestFailed, ~failure=res, ~paymentMethod=Card)
          FrictionlessFlow
        }->Promise.resolve
      })
      ->Promise.catch(_ => Promise.resolve(FrictionlessFlow))
    }

    let startNetcetera3DSFlow = () => {
      initialisedNetceteraOnce(~netceteraSDKApiKey, ~sdkEnvironment)
      ->Promise.then(statusInfo => {
        if statusInfo->isStatusSuccess {
          observeNetcetera(
            ~event=GenerateAreqParams,
            ~statusOf=((status, _)) => status,
            ~call=() =>
              Promise.make((resolve, _reject) => {
                Netcetera3dsModule.generateAReqParams(
                  threeDsData.messageVersion,
                  threeDsData.directoryServerId,
                  (status, aReqParams) => resolve((status, aReqParams)),
                )
              }),
          )->Promise.thenResolve(((status, aReqParams)) =>
            status->isStatusSuccess ? Make3DsCall(aReqParams) : RetrieveAgain
          )
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
          SdkLogger.logLifecycle(
            ~event=ThreeDsSdkUnavailable,
            ~paymentMethod=Card,
            ~message="Netcetera SDK dependency not added",
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
