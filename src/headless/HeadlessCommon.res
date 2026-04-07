// HeadlessCommon.res
// Shared headless logic used by HeadlessTask.res (all get + non-CVC confirms)
// and CvcWidget.res (card confirms with CVC via confirmCardPayment).

open SdkTypes
open HeadlessUtils

type headlessModule = {
  getPaymentSession: (JSON.t, JSON.t, array<JSON.t>, JSON.t => unit) => unit,
  exitHeadless: string => unit,
}

let makeHeadlessModule = (): headlessModule => {
  let hyperSwitchHeadlessDict =
    Dict.get(ReactNative.NativeModules.nativeModules, "HyperHeadless")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.getOr(Dict.make())

  let getFn = (key, default) => {
    switch hyperSwitchHeadlessDict->Dict.get(key) {
    | Some(fn) => Obj.magic(fn)
    | None => default
    }
  }

  {
    getPaymentSession: getFn("getPaymentSession", (_, _, _, _) => ()),
    exitHeadless: getFn("exitHeadless", _ => ()),
  }
}

let getDefaultPaymentSession = (headlessModule, error) => {
  headlessModule.getPaymentSession(
    error->Utils.getJsonObjectFromRecord,
    error->Utils.getJsonObjectFromRecord,
    []->Utils.getJsonObjectFromRecord,
    _response => {
      headlessModule.exitHeadless(error->HyperModule.stringifiedResStatus)
    },
  )
}

let confirmCall = async (headlessModule, body, nativeProp) => {
  let res = await confirmAPICall(nativeProp, body)
  let confirmRes =
    res
    ->Option.getOr(JSON.Encode.null)
    ->Utils.getDictFromJson
    ->PaymentConfirmTypes.itemToObjMapper
  headlessModule.exitHeadless(
    confirmRes.error->HyperModule.stringifiedResStatus,
  )
}

// Standalone card confirm: builds the confirm body and calls the API.
// Used by both HeadlessTask (via processRequest) and CvcWidget (via confirmPayment event).
let confirmCardPayment = (
  headlessModule,
  nativeProp,
  ~paymentToken: string,
  ~cvc: JSON.t,
  ~billing: option<JSON.t>=?,
) => {
  let bodyArr = [
    ("client_secret", nativeProp.clientSecret->JSON.Encode.string),
    ("payment_method", "card"->JSON.Encode.string),
    ("payment_token", paymentToken->JSON.Encode.string),
    ("card_cvc", cvc),
  ]

  billing
  ->Option.map(address => {
    bodyArr->Array.push((
      "payment_method_data",
      [("billing", address)]
      ->Dict.fromArray
      ->JSON.Encode.object,
    ))
  })
  ->Option.getOr()

  let body =
    bodyArr
    ->Dict.fromArray
    ->JSON.Encode.object
  confirmCall(headlessModule, body->JSON.stringify, nativeProp)->ignore
}

let confirmGPay = (
  headlessModule,
  reRegisterCallback,
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
    ->(confirmCall(headlessModule, _, nativeProp))
    ->ignore
  | "Cancel" => reRegisterCallback.contents()
  | err =>
    headlessModule.exitHeadless(
      {message: err, status: "failed"}->HyperModule.stringifiedResStatus,
    )
  }
}

let confirmApplePay = (
  headlessModule,
  reRegisterCallback,
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
            switch var->AddressUtils.getApplePayBillingAddress(
              "billing_contact",
              Some("shipping_contact"),
            ) {
            | Some(billing) => billing->Utils.getJsonObjectFromRecord
            | None => JSON.Encode.null
            },
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object

      generateWalletConfirmBody(~data, ~nativeProp, ~payment_method_data)
      ->(confirmCall(headlessModule, _, nativeProp))
      ->ignore
    }
  }
}

// Process a confirm request for a given payment method.
// Called by HeadlessJsTask when the native confirm callback fires.
// ~getCvc: function that returns the CVC value given the native callback response.
//   - HeadlessTask passes: response => response["cvc"]  (CVC from native callback, null when no CvcWidget)
let processRequest = async (
  headlessModule,
  reRegisterCallback,
  nativeProp,
  data: CustomerPaymentMethodType.customer_payment_method_type,
  response,
  sessions: option<array<SessionsType.sessions>>,
  ~getCvc: JSON.t => JSON.t,
) => {
  switch data.payment_method {
  | CARD =>
    confirmCardPayment(
      headlessModule,
      nativeProp,
      ~paymentToken=data.payment_token,
      ~cvc=getCvc(response),
      ~billing=?data.billing->Option.map(Utils.getJsonObjectFromRecord),
    )

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
            confirmGPay(headlessModule, reRegisterCallback, var, data, nativeProp)
          } catch {
          | _ => confirmGPay(headlessModule, reRegisterCallback, var, data, nativeProp)
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
          confirmApplePay(headlessModule, reRegisterCallback, var, data, nativeProp)
        } catch {
        | _ => confirmApplePay(headlessModule, reRegisterCallback, var, data, nativeProp)
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

// Set up the payment session: compute default/lastUsed, register callback with native.
// ~getCvc: function that returns the CVC value given the native callback response.
let getPaymentSession = (
  headlessModule,
  reRegisterCallback,
  nativeProp,
  spmData: CustomerPaymentMethodType.customer_payment_methods,
  sessions: option<array<SessionsType.sessions>>,
  ~getCvc: JSON.t => JSON.t,
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

    reRegisterCallback :=
      (
        () => {
          headlessModule.getPaymentSession(
            defaultSpmData,
            lastUsedSpmData,
            spmData->Utils.getJsonObjectFromRecord,
            response => {
              switch response->Utils.getDictFromJson->Utils.getOptionString("paymentToken") {
              | Some(token) =>
                switch spmData->Array.find(x => x.payment_token == token) {
                | Some(data) =>
                  processRequest(
                    headlessModule,
                    reRegisterCallback,
                    nativeProp,
                    data,
                    response,
                    sessions,
                    ~getCvc,
                  )->ignore
                | None =>
                  headlessModule.exitHeadless(
                    getDefaultError->HyperModule.stringifiedResStatus,
                  )
                }
              | None =>
                headlessModule.exitHeadless(
                  getDefaultError->HyperModule.stringifiedResStatus,
                )
              }
            },
          )
        }
      )

    reRegisterCallback.contents()
  } else {
    getDefaultPaymentSession(headlessModule, getDefaultError)
  }
}

// Main orchestrator: fetch saved payment methods, session tokens, set up payment session.
// ~getCvc: function that returns the CVC value given the native callback response.
let apiHandler = async (
  headlessModule,
  reRegisterCallback,
  nativeProp,
  ~getCvc: JSON.t => JSON.t,
) => {
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
          ->(getDefaultPaymentSession(headlessModule, _))
        } else if session->ErrorUtils.getErrorCode == "\"IR_09\"" {
          ErrorUtils.errorWarning.invalidCL
          ->errorOnApiCalls
          ->(getDefaultPaymentSession(headlessModule, _))
        } else {
          // Unknown session API error — surface it rather than silently dead-ending
          getDefaultPaymentSession(headlessModule, getDefaultError)
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

          getPaymentSession(
            headlessModule,
            reRegisterCallback,
            nativeProp,
            filteredSpmData,
            Some(sessions),
            ~getCvc,
          )
        | None =>
          getPaymentSession(
            headlessModule,
            reRegisterCallback,
            nativeProp,
            cardSpmData,
            None,
            ~getCvc,
          )
        }
      } else {
        getPaymentSession(
          headlessModule,
          reRegisterCallback,
          nativeProp,
          walletSpmData->Array.concat(cardSpmData),
          None,
          ~getCvc,
        )
      }
    } else {
      getPaymentSession(
        headlessModule,
        reRegisterCallback,
        nativeProp,
        walletSpmData->Array.concat(cardSpmData),
        None,
        ~getCvc,
      )
    }

  | None => customerSavedPMData->getErrorFromResponse->(getDefaultPaymentSession(headlessModule, _))
  }
}

// Validate nativeProp and run the headless flow.
// ~getCvc: function that returns the CVC value given the native callback response.
let runHeadlessFlow = (
  headlessModule,
  reRegisterCallback,
  nativeProp,
  ~getCvc: JSON.t => JSON.t,
) => {
  let isPublishableKeyValid = GlobalVars.isValidPK(nativeProp.env, nativeProp.publishableKey)

  let isClientSecretValid = RegExp.test(
    `.+_secret_[A-Za-z0-9]+`->Js.Re.fromString,
    nativeProp.clientSecret,
  )

  if isPublishableKeyValid && isClientSecretValid {
    apiHandler(headlessModule, reRegisterCallback, nativeProp, ~getCvc)->ignore
  } else if !isPublishableKeyValid {
    errorOnApiCalls(INVALID_PK(Error, Static("")))->(getDefaultPaymentSession(headlessModule, _))
  } else if !isClientSecretValid {
    errorOnApiCalls(INVALID_CL(Error, Static("")))->(getDefaultPaymentSession(headlessModule, _))
  }
}
