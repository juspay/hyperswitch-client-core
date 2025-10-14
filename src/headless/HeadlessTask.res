open SdkTypes
open HeadlessUtils

type headlessModule = {
  getPaymentSession: (JSON.t, JSON.t, array<JSON.t>, JSON.t => unit) => unit,
  exitHeadless: string => unit,
}

let getFunctionFromModule = (dict: Dict.t<'a>, key: string, default: 'b): 'b => {
  switch dict->Dict.get(key) {
  | Some(fn) => Obj.magic(fn)
  | None => default
  }
}

let reRegisterCallback = ref(() => ())

@react.component
let make = (~props) => {
  let hyperSwitchHeadlessDict =
    Dict.get(ReactNative.NativeModules.nativeModules, "HyperHeadless")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.getOr(Dict.make())

  let headlessModule = {
    getPaymentSession: getFunctionFromModule(hyperSwitchHeadlessDict, "getPaymentSession", (
      _,
      _,
      _,
      _,
    ) => ()),
    exitHeadless: getFunctionFromModule(hyperSwitchHeadlessDict, "exitHeadless", _ => ()),
  }

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

  let confirmGPay = (
    var,
    data: CustomerPaymentMethodType.customer_payment_method_type,
    nativeProp,
  ) => {
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
            [(data.payment_method_type, obj.paymentMethodData->Utils.getJsonObjectFromRecord)]
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

  let confirmApplePay = (
    var,
    data: CustomerPaymentMethodType.customer_payment_method_type,
    nativeProp,
  ) => {
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
              [(data.payment_method_type, paymentData)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
            (
              "billing",
              switch var->AddressUtils.getGooglePayBillingAddress("billing_contact") {
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
    data: CustomerPaymentMethodType.customer_payment_method_type,
    response,
    sessions: option<array<SessionsType.sessions>>,
  ) => {
    switch data.payment_method {
    | CARD =>
      let bodyArr = [
        ("client_secret", nativeProp.clientSecret->JSON.Encode.string),
        ("payment_method", "card"->JSON.Encode.string),
        ("payment_token", data.payment_token->JSON.Encode.string),
        (
          "card_cvc",
          switch response->Utils.getDictFromJson->Dict.get("cvc") {
          | Some(cvc) => cvc
          | None => JSON.Encode.null
          },
        ),
      ]

      data.billing
      ->Option.map(address => {
        bodyArr->Array.push((
          "payment_method_data",
          [("billing", address->Utils.getJsonObjectFromRecord)]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ))
      })
      ->Option.getOr()

      let body =
        bodyArr
        ->Dict.fromArray
        ->JSON.Encode.object
      confirmCall(body->JSON.stringify, nativeProp)->ignore

    | WALLET =>
      let session = switch sessions {
      | Some(sessionData) =>
        sessionData
        ->Array.find(item => item.wallet_name == data.payment_method_type_wallet)
        ->Option.getOr(SessionsType.defaultToken)
      | None => SessionsType.defaultToken
      }
      switch data.payment_method_type_wallet {
      | GOOGLE_PAY => {
          let gPayCallback = async var => {
            try {
              confirmGPay(var, data, nativeProp)
            } catch {
            | _ => confirmGPay(var, data, nativeProp)
            }
          }
          HyperModule.launchGPay(
            WalletType.getGpayTokenStringified(~obj=session, ~appEnv=nativeProp.env),
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
    | _ => headlessModule.exitHeadless(getDefaultError->HyperModule.stringifiedResStatus)
    }
  }

  let getPaymentSession = (
    nativeProp,
    spmData: CustomerPaymentMethodType.customer_payment_methods,
    sessions: option<array<SessionsType.sessions>>,
  ) => {
    if spmData->Array.length > 0 {
      let defaultSpmData = switch spmData->Array.find(savedCard =>
        savedCard.default_payment_method_set
      ) {
      | None => getDefaultError->Utils.getJsonObjectFromRecord
      | Some(x) => x->Utils.getJsonObjectFromRecord
      }

      let lastUsedSpmData = switch spmData->Array.reduce(None, (
        a: option<CustomerPaymentMethodType.customer_payment_method_type>,
        b: CustomerPaymentMethodType.customer_payment_method_type,
      ) => {
        let lastUsedAtA = switch a {
        | Some(a) => Some(a.last_used_at)
        | None => None
        }
        lastUsedAtA
        ->Option.map(date =>
          compare(
            Date.fromString(date)->Js.Date.getTime,
            Date.fromString(b.last_used_at)->Js.Date.getTime,
          ) < 0
            ? Some(b)
            : a
        )
        ->Option.getOr(Some(b))
      }) {
      | None => getDefaultError->Utils.getJsonObjectFromRecord
      | Some(x) => x->Utils.getJsonObjectFromRecord
      }

      reRegisterCallback.contents = () => {
        headlessModule.getPaymentSession(
          defaultSpmData,
          lastUsedSpmData,
          spmData->Utils.getJsonObjectFromRecord,
          response => {
            switch response->Utils.getDictFromJson->Utils.getOptionString("paymentToken") {
            | Some(token) =>
              switch spmData->Array.find(x => x.payment_token == token) {
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
    let customerSavedPMData = await savedPaymentMethodAPICall(nativeProp)
    switch customerSavedPMData {
    | Some(obj) =>
      let spmData = obj->CustomerPaymentMethodType.jsonToCustomerPaymentMethodType
      let sessionSpmData = spmData.customer_payment_methods->Array.filter(data => {
        switch (data.payment_method_type_wallet, ReactNative.Platform.os) {
        | (GOOGLE_PAY, #android) | (APPLE_PAY, #ios) => true
        | _ => false
        }
      })

      let walletSpmData = spmData.customer_payment_methods->Array.filter(data => {
        switch (data.payment_method_type_wallet, ReactNative.Platform.os) {
        | (GOOGLE_PAY, _) | (APPLE_PAY, _) => false
        | _ => true
        }
      })

      let cardSpmData = spmData.customer_payment_methods->Array.filter(data => {
        switch data.payment_method {
        | CARD => true
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
            let filteredSessionSpmData =
              sessionSpmData->Array.filter(data =>
                walletNameArray->Array.includes(data.payment_method_type_wallet)
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

  let nativeProp = nativeJsonToRecord(props, 0)

  let isPublishableKeyValid = GlobalVars.isValidPK(nativeProp.env, nativeProp.publishableKey)

  let isClientSecretValid = RegExp.test(
    `.+_secret_[A-Za-z0-9]+`->Js.Re.fromString,
    nativeProp.clientSecret,
  )

  if isPublishableKeyValid && isClientSecretValid {
    apiHandler(nativeProp)->ignore
  } else if !isPublishableKeyValid {
    errorOnApiCalls(INVALID_PK(Error, Static("")))->getDefaultPaymentSession
  } else if !isClientSecretValid {
    errorOnApiCalls(INVALID_CL(Error, Static("")))->getDefaultPaymentSession
  }
}
