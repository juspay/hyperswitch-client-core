open ExternalThreeDsTypes
open ThreeDsUtils
open SdkStatusMessages

let useNetceteraThreeDsHook = (~retrievePayment) => {
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
      ->ignore
    }

    let shortPollexternalThreeDsAuthStatus = (
      ~baseUrl,
      ~pollConfig: PaymentConfirmTypes.pollConfig,
      ~publishableKey,
      ~onSuccess,
      ~onFailure: string => unit,
    ) => {
      // let fetchApi = CommonHooks.fetchApi()
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

        let uri = `${baseUrl}/poll/status/${pollConfig.pollId}`
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

                paymentStatus := pollResponse.status
                if pollResponse.status === "completed" {
                  clearInterval(intervalId.contents)
                  onSuccess()
                }
                Some(data)->Promise.resolve
              },
            )
          } else {
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
          onSuccess("")
          Some(data)->Promise.resolve
        } else {
          onFailure(authoriseCallStatus.apiCallFailure)
          Some(data)->Promise.resolve
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
          status->isStatusSuccess
            ? Netcetera3dsModule.generateChallenge(status => {
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

      CommonHooks.fetchApi(~uri, ~bodyStr, ~headers, ~method_=Post, ())
      ->Promise.then(data => {
        let statusCode = data->Fetch.Response.status->string_of_int
        if statusCode->String.charAt(0) === "2" {
          data
          ->Fetch.Response.json
          ->Promise.then(res => {
            let authResponse = res->authResponseItemToObjMapper

            switch authResponse {
            | AUTH_RESPONSE(challengeParams) =>
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
              onFailure(authenticationCallStatus.apiCallFailure ++ " " ++ errorObj.errorMessage)
            }

            Some(data)->Promise.resolve
          })
        } else {
          data
          ->Fetch.Response.json
          ->Promise.then(error => {
            onFailure(authenticationCallStatus.apiCallFailure)
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
            Netcetera3dsModule.generateAReqParams((aReqParams, status) => {
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
          },
        )
      } catch {
      | err => onFailure("")
      }
    }

    let handleNativeThreeDs = nextAction => {
      if !Netcetera3dsModule.isAvailable {
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
