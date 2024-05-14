open ExternalThreeDsTypes
open ThreeDsUtils

let shortPollexternalThreeDsAuthStatus = (
  ~pollConfig: PaymentConfirmTypes.pollConfig,
  ~publishableKey,
  ~onSuccess,
  ~onFailure,
) => {
  let fetchApi = CommonHooks.useApiFetcher()
  let pollCounter = ref(0)
  let paymentStatus = ref("")

  let intervalId: ref<RescriptCore.intervalId> = ref(setInterval(() => (), 0))
  intervalId.contents = setInterval(() => {
    if pollCounter.contents >= pollConfig.frequency {
      clearInterval(intervalId.contents)
      if paymentStatus.contents !== "completed" {
        onFailure()
      }
    }

    let uri = `https://sandbox.hyperswitch.io/poll/status/${pollConfig.pollId}`
    let headers = getAuthCallHeaders(publishableKey)
    fetchApi(~uri, ~headers, ~method_=Fetch.Get, ())
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
        onFailure()
        Some(data)->Promise.resolve
      }
    })
    ->ignore
  }, pollConfig.delayInSecs * 1000)
}
let hsAuthoriseCall = (authoriseUrl, completionCallback, errorCallback: unit => unit) => {
  let fetchApi = CommonHooks.useApiFetcher()
  let headers = [("Content-Type", "application/json")]->Dict.fromArray
  fetchApi(
    ~uri=authoriseUrl,
    ~bodyStr="",
    ~headers,
    ~method_=Fetch.Post,
    (),
  )->Promise.then(data => {
    let statusCode = data->Fetch.Response.status->string_of_int
    if statusCode->String.charAt(0) === "2" {
      completionCallback()
      Some(data)->Promise.resolve
    } else {
      errorCallback()
      Some(data)->Promise.resolve
    }
  })
}

let sendChallengeParamsAndGenerateChallenge = (
  challengeParams,
  threeDsData: PaymentConfirmTypes.threeDsData,
  completionCallback,
  errorCallback: unit => unit,
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
            status->isStatusSuccess
              ? hsAuthoriseCall(
                  threeDsData.threeDsAuthorizeUrl,
                  completionCallback,
                  errorCallback,
                )->ignore
              : errorCallback()
          })
        : errorCallback()
    },
  )
}

let frictionlessAuthroiseAndContinue = (
  threeDsData: PaymentConfirmTypes.threeDsData,
  completionCallback,
  errorCallback: unit => unit,
) => {
  hsAuthoriseCall(threeDsData.threeDsAuthorizeUrl, completionCallback, errorCallback)->ignore
}

let hsThreeDsAuthCall = (
  clientSecret: string,
  publishableKey: string,
  aReqParams: aReqParams,
  threeDsData: PaymentConfirmTypes.threeDsData,
  onSuccess: unit => unit,
  onFailure: unit => unit,
) => {
  let uri = threeDsData.threeDsAuthenticationUrl
  let bodyStr = generateAuthenticationCallBody(clientSecret, aReqParams)
  let headers = getAuthCallHeaders(publishableKey)

  let fetchApi = CommonHooks.useApiFetcher()
  fetchApi(~uri, ~bodyStr, ~headers, ~method_=Post, ())
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
              challengeParams,
              threeDsData,
              onSuccess,
              onFailure,
            )
          | _ => frictionlessAuthroiseAndContinue(threeDsData, onSuccess, onFailure)
          }
        | AUTH_ERROR(errorObj) => onFailure()
        }

        Some(data)->Promise.resolve
      })
    } else {
      data
      ->Fetch.Response.json
      ->Promise.then(error => {
        onFailure()
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
  ~onSuccess: unit => unit,
  ~onFailure: unit => unit,
) => {
  try {
    Netcetera3dsModule.initialiseNetceteraSDK(netceteraSDKApiKey, status => {
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
          : onFailure()
      })
    })
  } catch {
  | err => onFailure()
  }
}

let useNetceteraThreeDsHook = (~retrievePayment) => {
  (~netceteraSDKApiKey, ~clientSecret, ~publishableKey, ~nextAction, ~onSuccess, ~onFailure) => {
    let retriveAndShowStatus = () => {
      retrievePayment(Types.Payment, clientSecret, publishableKey)
      ->Promise.then(res => {
        if res == JSON.Encode.null {
          onFailure()
        } else {
          let status = res->Utils.getDictFromJson->Utils.getString("status", "")

          switch status {
          | "processing" | "succeeded" => onSuccess()
          | _ => onFailure()
          }
        }
        Promise.resolve()
      })
      ->ignore
    }

    let shortPollStatusAndRetrieve = (~pollConfig, ~publishableKey) => {
      shortPollexternalThreeDsAuthStatus(
        ~pollConfig,
        ~publishableKey,
        ~onSuccess=retriveAndShowStatus,
        ~onFailure,
      )
    }

    let handleNativeThreeDs = nextAction => {
      if !Netcetera3dsModule.isAvailable {
        onFailure()
      }

      let threeDsData =
        nextAction->ThreeDsUtils.getThreeDsNextActionObj->ThreeDsUtils.getThreeDsDataObj

      let onChallengeCompletionCallback = () => {
        retrievePayment(Payment, clientSecret, publishableKey)
        ->Promise.then(res => {
          if res == JSON.Encode.null {
            onFailure()
          } else {
            let status = res->Utils.getDictFromJson->Utils.getString("status", "")
            switch status {
            | "processing" => onSuccess()
            | "failed" => onFailure()
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
        ~onSuccess=onChallengeCompletionCallback,
        ~onFailure,
      )->ignore
    }
    handleNativeThreeDs(nextAction)
  }
}
