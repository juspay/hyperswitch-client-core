open SdkTypes
open HeadlessUtils
open HeadlessNative

external parser: GooglePayTypeNew.paymentMethodData => JSON.t = "%identity"
external parser2: SdkTypes.addressDetails => JSON.t = "%identity"
external toJson: 't => JSON.t = "%identity"

let reRegisterCallback = ref(() => ())

let registerHeadless = headless => {
  let headlessModule = initialise(headless)

  let getDefaultPaymentSession = error => {
    headlessModule.getPaymentSession(error->toJson, error->toJson, []->toJson, _response => {
      headlessModule.exitHeadless(error->HyperModule.stringifiedResStatus)
    })
  }

  let confirmCall = (body, nativeProp) =>
    confirmAPICall(nativeProp, body)
    ->Promise.then(res => {
      let confirmRes =
        res
        ->Option.getOr(JSON.Encode.null)
        ->Utils.getDictFromJson
        ->PaymentConfirmTypes.itemToObjMapper
      headlessModule.exitHeadless(confirmRes.error->HyperModule.stringifiedResStatus)
      Promise.resolve()
    })
    ->ignore

  let confirmGPay = (var, statesJson, data, nativeProp) => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let obj = json->Utils.getDictFromJson->GooglePayTypeNew.itemToObjMapper(statesJson)

      let payment_method_data =
        [
          (
            "wallet",
            [(data.payment_method_type->Option.getOr(""), obj.paymentMethodData->parser)]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
          (
            "billing",
            switch obj.paymentMethodData.info {
            | Some(info) =>
              switch info.billing_address {
              | Some(address) => address->parser2
              | None => JSON.Encode.null
              }
            | None => JSON.Encode.null
            },
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object

      [
        ("client_secret", nativeProp.clientSecret->JSON.Encode.string),
        ("payment_method", "wallet"->JSON.Encode.string),
        ("payment_method_type", data.payment_method_type->Option.getOr("")->JSON.Encode.string),
        ("payment_method_data", payment_method_data),
        ("setup_future_usage", "off_session"->JSON.Encode.string),
        ("payment_type", "new_mandate"->JSON.Encode.string),
        (
          "customer_acceptance",
          [
            ("acceptance_type", "online"->JSON.Encode.string),
            ("accepted_at", Date.now()->Date.fromTime->Date.toISOString->JSON.Encode.string),
            (
              "online",
              [
                ("ip_address", nativeProp.hyperParams.ip->Option.getOr("")->JSON.Encode.string),
                (
                  "user_agent",
                  nativeProp.hyperParams.userAgent->Option.getOr("")->JSON.Encode.string,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object
      ->JSON.stringify
      ->confirmCall(nativeProp)
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

  let confirmApplePay = (var, statesJson, data, nativeProp) => {
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

      if transaction_identifier == "Simulated Identifier"->JSON.Encode.string {
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
              switch var->GooglePayTypeNew.getBillingContact("billing_contact", statesJson) {
              | Some(billing) => billing->parser2
              | None => JSON.Encode.null
              },
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        [
          ("client_secret", nativeProp.clientSecret->JSON.Encode.string),
          ("payment_method", "wallet"->JSON.Encode.string),
          ("payment_method_type", data.payment_method_type->Option.getOr("")->JSON.Encode.string),
          ("payment_method_data", payment_method_data),
          ("setup_future_usage", "off_session"->JSON.Encode.string),
          ("payment_type", "new_mandate"->JSON.Encode.string),
          (
            "customer_acceptance",
            [
              ("acceptance_type", "online"->JSON.Encode.string),
              ("accepted_at", Date.now()->Date.fromTime->Date.toISOString->JSON.Encode.string),
              (
                "online",
                [
                  ("ip_address", nativeProp.hyperParams.ip->Option.getOr("")->JSON.Encode.string),
                  (
                    "user_agent",
                    nativeProp.hyperParams.userAgent->Option.getOr("")->JSON.Encode.string,
                  ),
                ]
                ->Dict.fromArray
                ->JSON.Encode.object,
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
        ->JSON.stringify
        ->confirmCall(nativeProp)
      }
    }
  }

  let processRequest = (
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
      confirmCall(body->JSON.stringify, nativeProp)

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
      | GOOGLE_PAY =>
        HyperModule.launchGPay(
          GooglePayTypeNew.getGpayTokenStringified(
            ~obj=session,
            ~appEnv=nativeProp.env,
            ~requiredFields=[],
          ), //walletType.required_field,
          var => {
            RequiredFieldsTypes.importStates("./../utility/reusableCodeFromWeb/States.json")
            ->Promise.then(res => {
              confirmGPay(var, Some(res.states), data, nativeProp)
              Promise.resolve()
            })
            ->Promise.catch(_ => {
              confirmGPay(var, None, data, nativeProp)
              Promise.resolve()
            })
            ->ignore
          },
        )
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
            (),
          )
          headlessModule.exitHeadless(getDefaultError->HyperModule.stringifiedResStatus)
        }, 5000)

        HyperModule.launchApplePay(
          [
            ("session_token_data", session.session_token_data),
            ("payment_request_data", session.payment_request_data),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
          ->JSON.stringify,
          var => {
            RequiredFieldsTypes.importStates("./../utility/reusableCodeFromWeb/States.json")
            ->Promise.then(res => {
              confirmApplePay(var, Some(res.states), data, nativeProp)
              Promise.resolve()
            })
            ->Promise.catch(_ => {
              confirmApplePay(var, None, data, nativeProp)
              Promise.resolve()
            })
            ->ignore
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
      | NONE => getDefaultError->toJson
      | x => x->toJson
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
      | NONE => getDefaultError->toJson
      | x => x->toJson
      }

      reRegisterCallback.contents = () => {
        headlessModule.getPaymentSession(
          defaultSpmData,
          lastUsedSpmData,
          spmData->toJson,
          response => {
            switch response->Utils.getDictFromJson->Dict.get("paymentToken") {
            | Some(token) =>
              switch spmData->Array.find(x =>
                switch x {
                | SAVEDLISTCARD(savedCard) => savedCard.payment_token == token->JSON.Decode.string
                | SAVEDLISTWALLET(savedWallet) =>
                  savedWallet.payment_token == token->JSON.Decode.string
                | NONE => false
                }
              ) {
              | Some(data) => processRequest(nativeProp, data, response, sessions)
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

  let getNativePropCallback = response => {
    let nativeProp = nativeJsonToRecord(response, 0)

    let isPublishableKeyValid = GlobalVars.isValidPK(nativeProp.env, nativeProp.publishableKey)

    let isClientSecretValid = RegExp.test(
      `.+_secret_[A-Za-z0-9]+`->Js.Re.fromString,
      nativeProp.clientSecret,
    )

    if isPublishableKeyValid && isClientSecretValid {
      let timestamp = Date.now()
      let paymentId =
        String.split(nativeProp.clientSecret, "_secret_")
        ->Array.get(0)
        ->Option.getOr("")

      logWrapper(
        ~logType=INFO,
        ~eventName=PAYMENT_SESSION_INITIATED,
        ~url="",
        ~customLogUrl=nativeProp.customLogUrl,
        ~env=nativeProp.env,
        ~category=API,
        ~statusCode="",
        ~apiLogType=None,
        ~data=JSON.Encode.null,
        ~publishableKey=nativeProp.publishableKey,
        ~paymentId,
        ~paymentMethod=None,
        ~paymentExperience=None,
        ~timestamp,
        ~latency=0.,
        (),
      )
      savedPaymentMethodAPICall(nativeProp)
      ->Promise.then(customerSavedPMData => {
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
            sessionAPICall(nativeProp)
            ->Promise.then(session => {
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
                  let filteredSessionSpmData = sessionSpmData->Array.filter(
                    data =>
                      switch data {
                      | SAVEDLISTWALLET(data) =>
                        walletNameArray->Array.includes(
                          data.walletType->Option.getOr("")->walletNameToTypeMapper,
                        )
                      | _ => false
                      },
                  )
                  let filteredSpmData =
                    filteredSessionSpmData->Array.concat(walletSpmData->Array.concat(cardSpmData))

                  getPaymentSession(nativeProp, filteredSpmData, Some(sessions))
                | None => getPaymentSession(nativeProp, cardSpmData, None)
                }
              } else {
                getPaymentSession(nativeProp, walletSpmData->Array.concat(cardSpmData), None)
              }
              Promise.resolve()
            })
            ->ignore
          } else {
            getPaymentSession(nativeProp, walletSpmData->Array.concat(cardSpmData), None)
          }

        | None => customerSavedPMData->getErrorFromResponse->getDefaultPaymentSession
        }
        Promise.resolve()
      })
      ->ignore
    } else if !isPublishableKeyValid {
      errorOnApiCalls(INVALID_PK(Error, Static("")))->getDefaultPaymentSession
    } else if !isClientSecretValid {
      errorOnApiCalls(INVALID_CL(Error, Static("")))->getDefaultPaymentSession
    }
  }

  headlessModule.initialisePaymentSession(getNativePropCallback)
}
