open SdkTypes
open HeadlessUtils
open HeadlessNative

let reRegisterCallback = ref(() => ())

let registerHeadless = headless => {
  let headlessModule = initialise(headless)

  let getDefaultPaymentSession = error => {
    headlessModule.getPaymentSession(
      error->Utils.getJsonObjectFromRecord,
      error->Utils.getJsonObjectFromRecord,
      []->Utils.getJsonObjectFromRecord,
      _response => {
        headlessModule.exitHeadless(error->HyperModule.stringifiedResStatus)
      },
    )
  }

  let confirmCall = async (body, nativeProp) => {
    let res = await confirmAPICall(nativeProp, body)
    let confirmRes =
      res
      ->Option.getOr(JSON.Encode.null)
      ->Utils.getDictFromJson
      ->PaymentConfirmTypes.itemToObjMapper
    headlessModule.exitHeadless(confirmRes.error->HyperModule.stringifiedResStatus)
  }

  let confirmGPay = (var, data, nativeProp) => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let obj =
        json
        ->Utils.getDictFromJson
        ->WalletType.itemToObjMapper

      let payment_method_data =
        [
          (
            "wallet",
            [
              (
                data.payment_method_type->Option.getOr(""),
                obj.paymentMethodData->Utils.getJsonObjectFromRecord,
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
          (
            "billing",
            switch obj.paymentMethodData.info {
            | Some(info) =>
              switch info.billing_address {
              | Some(address) => address->Utils.getJsonObjectFromRecord
              | None => JSON.Encode.null
              }
            | None => JSON.Encode.null
            },
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object

      generateWalletConfirmBody(~data, ~nativeProp, ~payment_method_data)
      ->confirmCall(nativeProp)
      ->ignore
    | "Cancel" => reRegisterCallback.contents()

    // headlessModule.exitHeadless(
    //   PaymentConfirmTypes.defaultCancelError->HyperModule.stringifiedResStatus,
    // )
    | err =>
      headlessModule.exitHeadless(
        {message: err, status: "failed"}->HyperModule.stringifiedResStatus,
      )
    }
  }

  let confirmApplePay = (var, data, nativeProp) => {
    switch var
    ->Dict.get("status")
    ->Option.getOr(JSON.Encode.null)
    ->JSON.Decode.string
    ->Option.getOr("") {
    | "Cancelled" => reRegisterCallback.contents()

    // headlessModule.exitHeadless(
    //   PaymentConfirmTypes.defaultCancelError->HyperModule.stringifiedResStatus,
    // )
    | "Failed" =>
      headlessModule.exitHeadless(
        {message: "failed", status: "failed"}->HyperModule.stringifiedResStatus,
      )
    | "Error" =>
      headlessModule.exitHeadless(
        {message: "failed", status: "failed"}->HyperModule.stringifiedResStatus,
      )
    | _ =>
      let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)

      let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)

      let transaction_identifier =
        var->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null)

      if (
        transaction_identifier->Utils.getStringFromJson(
          "Simulated Identifier",
        ) == "Simulated Identifier"
      ) {
        headlessModule.exitHeadless(
          {message: "Simulated Identifier", status: "failed"}->HyperModule.stringifiedResStatus,
        )
      } else {
        let paymentData =
          [
            ("payment_data", payment_data),
            ("payment_method", payment_method),
            ("transaction_identifier", transaction_identifier),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        let payment_method_data =
          [
            (
              "wallet",
              [(data.payment_method_type->Option.getOr(""), paymentData)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
            (
              "billing",
              switch var->WalletType.getBillingContact("billing_contact") {
              | Some(billing) => billing->Utils.getJsonObjectFromRecord
              | None => JSON.Encode.null
              },
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        generateWalletConfirmBody(~data, ~nativeProp, ~payment_method_data)
        ->confirmCall(nativeProp)
        ->ignore
      }
    }
  }

  let processRequest = async (
    nativeProp,
    data,
    response,
    sessions: option<array<SessionsType.sessions>>,
  ) => {
    switch data {
    | SAVEDLISTCARD(data) =>
      let body =
        [
          ("client_secret", nativeProp.clientSecret->JSON.Encode.string),
          ("payment_method", "card"->JSON.Encode.string),
          ("payment_token", data.payment_token->Option.getOr("")->JSON.Encode.string),
          (
            "card_cvc",
            switch response->Utils.getDictFromJson->Dict.get("cvc") {
            | Some(cvc) => cvc
            | None => JSON.Encode.null
            },
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
      confirmCall(body->JSON.stringify, nativeProp)->ignore

    | SAVEDLISTWALLET(data) =>
      let session = switch sessions {
      | Some(sessionData) =>
        sessionData
        ->Array.find(item =>
          item.wallet_name == data.walletType->Option.getOr("")->walletNameToTypeMapper
        )
        ->Option.getOr(SessionsType.defaultToken)
      | None => SessionsType.defaultToken
      }
      switch data.walletType->Option.getOr("")->walletNameToTypeMapper {
      | GOOGLE_PAY => {
          let gPayCallback = async var => {
            try {
              let _ = await RequiredFieldsTypes.importStatesAndCountries(
                "./../utility/reusableCodeFromWeb/StatesAndCountry.json",
              )
              confirmGPay(var, data, nativeProp)
            } catch {
            | _ => confirmGPay(var, data, nativeProp)
            }
          }
          HyperModule.launchGPay(
            WalletType.getGpayTokenStringified(
              ~obj=session,
              ~appEnv=nativeProp.env,
              ~requiredFields=[],
            ), //walletType.required_field,
            var => {
              gPayCallback(var)->ignore
            },
          )
        }
      | APPLE_PAY =>
        let timerId = setTimeout(() => {
          logWrapper(
            ~logType=DEBUG,
            ~eventName=APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
            ~url="",
            ~customLogUrl=nativeProp.customLogUrl,
            ~env=nativeProp.env,
            ~category=API,
            ~statusCode="",
            ~apiLogType=None,
            ~data=JSON.Encode.null,
            ~publishableKey=nativeProp.publishableKey,
            ~paymentId="",
            ~paymentMethod=None,
            ~paymentExperience=None,
            ~timestamp=0.,
            ~latency=0.,
            ~version=nativeProp.hyperParams.sdkVersion,
            (),
          )
          headlessModule.exitHeadless(getDefaultError->HyperModule.stringifiedResStatus)
        }, 5000)
        let applePayCallback = async var => {
          try {
            let _ = await RequiredFieldsTypes.importStatesAndCountries(
              "./../utility/reusableCodeFromWeb/StatesAndCountry.json",
            )
            confirmApplePay(var, data, nativeProp)
          } catch {
          | _ => confirmApplePay(var, data, nativeProp)
          }
        }
        HyperModule.launchApplePay(
          [
            ("session_token_data", session.session_token_data),
            ("payment_request_data", session.payment_request_data),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
          ->JSON.stringify,
          var => {
            applePayCallback(var)->ignore
          },
          _ => {
            logWrapper(
              ~logType=DEBUG,
              ~eventName=APPLE_PAY_BRIDGE_SUCCESS,
              ~url="",
              ~customLogUrl=nativeProp.customLogUrl,
              ~env=nativeProp.env,
              ~category=API,
              ~statusCode="",
              ~apiLogType=None,
              ~data=JSON.Encode.null,
              ~publishableKey=nativeProp.publishableKey,
              ~paymentId="",
              ~paymentMethod=None,
              ~paymentExperience=None,
              ~timestamp=0.,
              ~latency=0.,
              ~version=nativeProp.hyperParams.sdkVersion,
              (),
            )
          },
          _ => {
            clearTimeout(timerId)
          },
        )
      | _ => ()
      }
    | NONE => headlessModule.exitHeadless(getDefaultError->HyperModule.stringifiedResStatus)
    }
  }

  let getPaymentSession = (nativeProp, spmData, sessions: option<array<SessionsType.sessions>>) => {
    if spmData->Array.length > 0 {
      let defaultSpmData = switch spmData
      ->Array.find(x =>
        switch x {
        | SAVEDLISTCARD(savedCard) => savedCard.isDefaultPaymentMethod->Option.getOr(false)
        | SAVEDLISTWALLET(savedWallet) => savedWallet.isDefaultPaymentMethod->Option.getOr(false)
        | NONE => false
        }
      )
      ->Option.getOr(NONE) {
      | NONE => getDefaultError->Utils.getJsonObjectFromRecord
      | x => x->Utils.getJsonObjectFromRecord
      }

      let lastUsedSpmData = switch spmData
      ->Array.reduce(None, (a: option<SdkTypes.savedDataType>, b: SdkTypes.savedDataType) => {
        let lastUsedAtA = switch a {
        | Some(a) =>
          switch a {
          | SAVEDLISTCARD(savedCard) => savedCard.lastUsedAt
          | SAVEDLISTWALLET(savedWallet) => savedWallet.lastUsedAt
          | NONE => None
          }
        | None => None
        }
        let lastUsedAtB = switch b {
        | SAVEDLISTCARD(savedCard) => savedCard.lastUsedAt
        | SAVEDLISTWALLET(savedWallet) => savedWallet.lastUsedAt
        | NONE => None
        }
        switch (lastUsedAtA, lastUsedAtB) {
        | (None, Some(_)) => Some(b)
        | (Some(_), None) => a
        | (Some(dateA), Some(dateB)) =>
          if (
            compare(
              Date.fromString(dateA)->Js.Date.getTime,
              Date.fromString(dateB)->Js.Date.getTime,
            ) < 0
          ) {
            Some(b)
          } else {
            a
          }
        | (None, None) => a
        }
      })
      ->Option.getOr(NONE) {
      | NONE => getDefaultError->Utils.getJsonObjectFromRecord
      | x => x->Utils.getJsonObjectFromRecord
      }

      reRegisterCallback.contents = () => {
        headlessModule.getPaymentSession(
          defaultSpmData,
          lastUsedSpmData,
          spmData->Utils.getJsonObjectFromRecord,
          response => {
            switch response->Utils.getDictFromJson->Utils.getOptionString("paymentToken") {
            | Some(token) =>
              switch spmData->Array.find(x =>
                switch x {
                | SAVEDLISTCARD(savedCard) =>
                  switch savedCard.payment_token {
                  | Some(payment_token) => payment_token == token
                  | None => false
                  }
                | SAVEDLISTWALLET(savedWallet) =>
                  switch savedWallet.payment_token {
                  | Some(payment_token) => payment_token == token
                  | None => false
                  }
                | NONE => false
                }
              ) {
              | Some(data) => processRequest(nativeProp, data, response, sessions)->ignore
              | None =>
                headlessModule.exitHeadless(getDefaultError->HyperModule.stringifiedResStatus)
              }
            | None => headlessModule.exitHeadless(getDefaultError->HyperModule.stringifiedResStatus)
            }
          },
        )
      }

      reRegisterCallback.contents()
    } else {
      getDefaultPaymentSession(getDefaultError)
    }
  }

  let apiHandler = async nativeProp => {
    //customerSavedPMData
    let customerSavedPMData = await savedPaymentMethodAPICall(nativeProp)

    switch customerSavedPMData {
    | Some(obj) =>
      let spmData = obj->PaymentMethodListType.jsonToSavedPMObj
      let sessionSpmData = spmData->Array.filter(data => {
        switch data {
        | SAVEDLISTWALLET(val) =>
          let walletType = val.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
          switch (walletType, ReactNative.Platform.os) {
          | (GOOGLE_PAY, #android) | (APPLE_PAY, #ios) => true
          | _ => false
          }
        | _ => false
        }
      })

      let walletSpmData = spmData->Array.filter(data => {
        switch data {
        | SAVEDLISTWALLET(val) =>
          let walletType = val.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
          switch (walletType, ReactNative.Platform.os) {
          | (GOOGLE_PAY, _) | (APPLE_PAY, _) => false
          | _ => true
          }
        | _ => false
        }
      })

      let cardSpmData = spmData->Array.filter(data => {
        switch data {
        | SAVEDLISTCARD(_) => true
        | _ => false
        }
      })

      if sessionSpmData->Array.length > 0 {
        let session = await sessionAPICall(nativeProp)

        if session->ErrorUtils.isError {
          if session->ErrorUtils.getErrorCode == "\"IR_16\"" {
            ErrorUtils.errorWarning.usedCL
            ->errorOnApiCalls
            ->getDefaultPaymentSession
          } else if session->ErrorUtils.getErrorCode == "\"IR_09\"" {
            ErrorUtils.errorWarning.invalidCL
            ->errorOnApiCalls
            ->getDefaultPaymentSession
          }
        } else if session != JSON.Encode.null {
          switch session->Utils.getDictFromJson->SessionsType.itemToObjMapper {
          | Some(sessions) =>
            let walletNameArray = sessions->Array.map(wallet => wallet.wallet_name)
            let filteredSessionSpmData = sessionSpmData->Array.filter(data =>
              switch data {
              | SAVEDLISTWALLET(data) =>
                walletNameArray->Array.includes(
                  data.walletType->Option.getOr("")->walletNameToTypeMapper,
                )
              | _ => false
              }
            )
            let filteredSpmData =
              filteredSessionSpmData->Array.concat(walletSpmData->Array.concat(cardSpmData))

            getPaymentSession(nativeProp, filteredSpmData, Some(sessions))
          | None => getPaymentSession(nativeProp, cardSpmData, None)
          }
        } else {
          getPaymentSession(nativeProp, walletSpmData->Array.concat(cardSpmData), None)
        }
      } else {
        getPaymentSession(nativeProp, walletSpmData->Array.concat(cardSpmData), None)
      }

    | None => customerSavedPMData->getErrorFromResponse->getDefaultPaymentSession
    }
  }
  
  let sdkFunctions = ThreeDsSdkResolver.resolveThreeDsSdk(~threeDsSdkApiKey=None)

  let sendResponseToNative = (~status: bool, ~method: string, ~data: option<JSON.t>=?, ~error: option<JSON.t>=?) => {
    let response = Dict.make()

    response->Dict.set("status", JSON.Encode.bool(status))
    response->Dict.set("method", JSON.Encode.string(method))

    switch (data, error) {
    | (Some(successData), None) when status => 
      response->Dict.set("data", successData)
    | (None, Some(errorData)) when !status => 
      response->Dict.set("error", errorData)
    | _ => ()
    }
    
    headlessModule.sendMessageToNative(JSON.Encode.object(response)->JSON.stringify)
  }

  let handleChallengeParamsResponse = response => {
    let responseDict = response->Utils.getDictFromJson
    let acsSignedContent = responseDict->Utils.getString("acsSignedContent", "")
    let acsTransactionId = responseDict->Utils.getString("acsTransactionId", "")
    let acsRefNumber = responseDict->Utils.getString("acsRefNumber", "")
    let threeDSServerTransId = responseDict->Utils.getString("threeDSServerTransId", "")
    let threeDSRequestorAppURL = responseDict->Utils.getOptionString("threeDSRequestorAppURL")

    sdkFunctions.receiveChallengeParamsFunc(
      acsSignedContent,
      acsTransactionId,
      acsRefNumber,
      threeDSServerTransId,
      status => {
        let responseDict = Dict.make()
        responseDict->Dict.set("status", JSON.Encode.string(status.status))
        responseDict->Dict.set("message", JSON.Encode.string(status.message))

        if status->ThreeDsUtils.isStatusSuccess {
          sdkFunctions.generateChallengeFunc(status => {
            let doChallengeResult = Dict.make()
            doChallengeResult->Dict.set("status", JSON.Encode.string(status.status))
            doChallengeResult->Dict.set("message", JSON.Encode.string(status.message))
            responseDict->Dict.set("doChallengeResult", JSON.Encode.object(doChallengeResult))

            sendResponseToNative(~status=true, ~method="generateChallenge", ~data=JSON.Encode.object(responseDict))
          })
        } else {
          let errorData = Dict.make()
          errorData->Dict.set("status", JSON.Encode.string(status.status))
          errorData->Dict.set("message", JSON.Encode.string(status.message))
          sendResponseToNative(~status=false, ~method="generateChallenge", ~error=JSON.Encode.object(errorData))
        }
      },
      threeDSRequestorAppURL,
    )
  }

  let generateAReqParamsCallback = response => {
    let responseDict = response->Utils.getDictFromJson
    let directoryServerId = responseDict->Utils.getString("directoryServerId", "")
    let cardNetwork = responseDict->Utils.getOptionString("cardNetwork")
    let messageVersion = responseDict->Utils.getString("messageVersion", "")

    sdkFunctions.generateAReqParamsFunc(messageVersion, directoryServerId, cardNetwork, (
      status,
      aReqParams,
    ) => {
      let responseDict = Dict.make()
      responseDict->Dict.set("status", JSON.Encode.string(status.status))
      responseDict->Dict.set("message", JSON.Encode.string(status.message))
      responseDict->Dict.set("aReqParams", aReqParams->ExternalThreeDsTypes.aReqParamsToJson)
      if status->ThreeDsUtils.isStatusSuccess {
        headlessModule.sendAReqAndReceiveChallengeParams(
          JSON.Encode.object(responseDict),
          handleChallengeParamsResponse,
        )
      } else {
        let errorData = Dict.make()
        errorData->Dict.set("status", JSON.Encode.string(status.status))
        errorData->Dict.set("message", JSON.Encode.string(status.message))
        sendResponseToNative(~status=false, ~method="generateAReqParams", ~error=JSON.Encode.object(errorData))
      }
    })
  }

  let getNativePropCallback = response => {
    let isAuthSession = response->Utils.getDictFromJson->Utils.getBool("isAuthSession", false)

    let nativeProp = nativeJsonToRecord(response, 0)

    let isPublishableKeyValid = GlobalVars.isValidPK(nativeProp.env, nativeProp.publishableKey)

    let isClientSecretValid = RegExp.test(
      `.+_secret_[A-Za-z0-9]+`->Js.Re.fromString,
      nativeProp.clientSecret,
    )

    if isPublishableKeyValid && isClientSecretValid {
      if isAuthSession {
        sdkFunctions.initialiseSdkFunc(
          {
            apiKey: nativeProp.configuration.netceteraSDKApiKey->Option.getOr(""),
            environment: nativeProp.env,
          },
          status => {
            if status->ThreeDsUtils.isStatusSuccess {
              headlessModule.getAuthRequestParams(generateAReqParamsCallback)
            } else {
              let errorData = Dict.make()
              errorData->Dict.set("status", JSON.Encode.string(status.status))
              errorData->Dict.set("message", JSON.Encode.string(status.message))
              sendResponseToNative(~status=false, ~method="initialiseSdkFunc", ~error=JSON.Encode.object(errorData))
            }
          },
        )
      }

      apiHandler(nativeProp)->ignore
    } else if !isPublishableKeyValid {
      errorOnApiCalls(INVALID_PK(Error, Static("")))->getDefaultPaymentSession
    } else if !isClientSecretValid {
      errorOnApiCalls(INVALID_CL(Error, Static("")))->getDefaultPaymentSession
    }
  }

  headlessModule.initialisePaymentSession(getNativePropCallback)
  headlessModule.initialiseAuthSession(getNativePropCallback)
}
