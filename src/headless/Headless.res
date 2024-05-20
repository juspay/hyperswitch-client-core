open ReactNative
open LoggerHook

type jsonFun = JSON.t => unit
external jsonToStrFun: JSON.t => jsonFun = "%identity"

type jsonWithCallback = (JSON.t => unit) => unit
external jsonWithCallback: JSON.t => jsonWithCallback = "%identity"

type jsonFunWithCallback = (JSON.t, JSON.t => unit) => unit
external jsonToStrFunWithCallback: JSON.t => jsonFunWithCallback = "%identity"

type jsonFun2WithCallback = (JSON.t, JSON.t, JSON.t => unit) => unit
external jsonToStrFun2WithCallback: JSON.t => jsonFun2WithCallback = "%identity"

external toJson: 't => JSON.t = "%identity"

let sendLogs = (logFile, customLogUrl, env: GlobalVars.envType) => {
  let uri = switch customLogUrl {
  | Some(url) => url
  | None =>
    switch env {
    | PROD => "https://api.hyperswitch.io/logs/sdk"
    | _ => "https://sandbox.hyperswitch.io/logs/sdk"
    }
  }
  if Next.getNextEnv != "next" {
    let data = logFile->LoggerHook.logFileToObj->JSON.stringify
    CommonHooks.fetchApi(~uri, ~method_=Post, ~bodyStr=data, ~headers=Dict.make(), ~mode=NoCORS, ())
    ->Promise.then(res => res->Fetch.Response.json)
    ->Promise.catch(_ => {
      Promise.resolve(JSON.Encode.null)
    })
    ->ignore
  }
}

let logWrapper = (
  ~logType: logType,
  ~eventName: eventName,
  ~url: string,
  ~statusCode: string,
  ~apiLogType,
  ~category,
  ~data: JSON.t,
  ~paymentMethod: option<string>,
  ~paymentExperience: option<PaymentMethodListType.payment_experience_type>,
  ~publishableKey: string,
  ~paymentId: string,
  ~timestamp,
  ~latency,
  ~env,
  ~customLogUrl,
  (),
) => {
  let (value, internalMetadata) = switch apiLogType {
  | None => ([], [])
  | Some(AllPaymentHooks.Request) => ([("url", url->JSON.Encode.string)], [])
  | Some(AllPaymentHooks.Response) => (
      [("url", url->JSON.Encode.string), ("statusCode", statusCode->JSON.Encode.string)],
      [("response", data)],
    )
  | Some(AllPaymentHooks.NoResponse) => (
      [
        ("url", url->JSON.Encode.string),
        ("statusCode", "504"->JSON.Encode.string),
        ("response", data),
      ],
      [("response", data)],
    )
  | Some(AllPaymentHooks.Err) => (
      [
        ("url", url->JSON.Encode.string),
        ("statusCode", statusCode->JSON.Encode.string),
        ("response", data),
      ],
      [("response", data)],
    )
  }
  let logFile = {
    logType,
    timestamp: timestamp->Float.toString,
    sessionId: "",
    version: "repoVersion",
    codePushVersion: getCodePushVersionNoFromRef(),
    component: MOBILE,
    value: value->Dict.fromArray->JSON.Encode.object->JSON.stringify,
    internalMetadata: internalMetadata->Dict.fromArray->JSON.Encode.object->JSON.stringify,
    category,
    paymentId,
    merchantId: publishableKey,
    platform: ReactNative.Platform.os->toPlatform,
    userAgent: "userAgent",
    eventName,
    firstEvent: true,
    source: Headless->SdkTypes.sdkStateToStrMapper,
    paymentMethod: paymentMethod->Option.getOr(""),
    paymentExperience: paymentExperience->Option.getOr(
      (NONE: PaymentMethodListType.payment_experience_type),
    ),
    latency: latency->Float.toString,
  }
  sendLogs(logFile, customLogUrl, env)
}

let savedPaymentMethodAPICall = (publishableKey, clientSecret, appId, env, customLogUrl) => {
  let paymentId = String.split(clientSecret, "_secret_")->Array.get(0)->Option.getOr("")

  let uri = `https://sandbox.hyperswitch.io/customers/payment_methods?client_secret=${clientSecret}`
  let initTimestamp = Date.now()
  logWrapper(
    ~logType=INFO,
    ~eventName=CUSTOMER_PAYMENT_METHODS_CALL_INIT,
    ~url=uri,
    ~customLogUrl,
    ~env,
    ~category=API,
    ~statusCode="",
    ~apiLogType=Some(Request),
    ~data=JSON.Encode.null,
    ~publishableKey,
    ~paymentId,
    ~paymentMethod=None,
    ~paymentExperience=None,
    ~timestamp=initTimestamp,
    ~latency=0.,
    (),
  )
  CommonHooks.fetchApi(~uri, ~method_=Get, ~headers=Utils.getHeader(publishableKey, appId), ())
  ->Promise.then(data => {
    let respTimestamp = Date.now()
    let statusCode = data->Fetch.Response.status->string_of_int
    if statusCode->String.charAt(0) === "2" {
      data
      ->Fetch.Response.json
      ->Promise.then(data => {
        logWrapper(
          ~logType=INFO,
          ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
          ~url=uri,
          ~customLogUrl,
          ~env,
          ~category=API,
          ~statusCode,
          ~apiLogType=Some(Response),
          ~data=JSON.Encode.null,
          ~publishableKey,
          ~paymentId,
          ~paymentMethod=None,
          ~paymentExperience=None,
          ~timestamp=respTimestamp,
          ~latency={respTimestamp -. initTimestamp},
          (),
        )
        Some(data)->Promise.resolve
      })
    } else {
      data
      ->Fetch.Response.json
      ->Promise.then(error => {
        let value =
          [
            ("url", uri->JSON.Encode.string),
            ("statusCode", statusCode->JSON.Encode.string),
            ("response", error),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        logWrapper(
          ~logType=ERROR,
          ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
          ~url=uri,
          ~customLogUrl,
          ~env,
          ~category=API,
          ~statusCode,
          ~apiLogType=Some(Err),
          ~data=value,
          ~publishableKey,
          ~paymentId,
          ~paymentMethod=None,
          ~paymentExperience=None,
          ~timestamp=respTimestamp,
          ~latency={respTimestamp -. initTimestamp},
          (),
        )
        Some(error)->Promise.resolve
      })
    }
  })
  ->Promise.catch(err => {
    let respTimestamp = Date.now()
    logWrapper(
      ~logType=ERROR,
      ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
      ~url=uri,
      ~customLogUrl,
      ~env,
      ~category=API,
      ~statusCode="504",
      ~apiLogType=Some(NoResponse),
      ~data=err->toJson,
      ~publishableKey,
      ~paymentId,
      ~paymentMethod=None,
      ~paymentExperience=None,
      ~timestamp=respTimestamp,
      ~latency={respTimestamp -. initTimestamp},
      (),
    )
    None->Promise.resolve
  })
}

let confirmAPICall = (publishableKey, clientSecret, body, appId, env, customLogUrl) => {
  let paymentId = String.split(clientSecret, "_secret_")->Array.get(0)->Option.getOr("")
  let uri = `https://sandbox.hyperswitch.io/payments/${paymentId}/confirm`
  let headers = Utils.getHeader(publishableKey, appId)
  let initTimestamp = Date.now()
  logWrapper(
    ~logType=INFO,
    ~eventName=CONFIRM_CALL_INIT,
    ~url=uri,
    ~customLogUrl,
    ~env,
    ~category=API,
    ~statusCode="",
    ~apiLogType=Some(Request),
    ~data=JSON.Encode.null,
    ~publishableKey,
    ~paymentId,
    ~paymentMethod=None,
    ~paymentExperience=None,
    ~timestamp=initTimestamp,
    ~latency=0.,
    (),
  )

  CommonHooks.fetchApi(~uri, ~method_=Post, ~headers, ~bodyStr=body, ())
  ->Promise.then(data => {
    let respTimestamp = Date.now()
    let statusCode = data->Fetch.Response.status->string_of_int
    if statusCode->String.charAt(0) === "2" {
      logWrapper(
        ~logType=INFO,
        ~eventName=CONFIRM_CALL,
        ~url=uri,
        ~customLogUrl,
        ~env,
        ~category=API,
        ~statusCode,
        ~apiLogType=Some(Response),
        ~data=JSON.Encode.null,
        ~publishableKey,
        ~paymentId,
        ~paymentMethod=None,
        ~paymentExperience=None,
        ~timestamp=respTimestamp,
        ~latency={respTimestamp -. initTimestamp},
        (),
      )
      data->Fetch.Response.json
    } else {
      data
      ->Fetch.Response.json
      ->Promise.then(error => {
        let value =
          [
            ("url", uri->JSON.Encode.string),
            ("statusCode", statusCode->JSON.Encode.string),
            ("response", error),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        logWrapper(
          ~logType=ERROR,
          ~eventName=CONFIRM_CALL,
          ~url=uri,
          ~customLogUrl,
          ~env,
          ~category=API,
          ~statusCode,
          ~apiLogType=Some(Err),
          ~data=value,
          ~publishableKey,
          ~paymentId,
          ~paymentMethod=None,
          ~paymentExperience=None,
          ~timestamp=respTimestamp,
          ~latency={respTimestamp -. initTimestamp},
          (),
        )
        Promise.resolve(error)
      })
    }
  })
  ->Promise.then(jsonResponse => {
    Promise.resolve(Some(jsonResponse))
  })
  ->Promise.catch(err => {
    let respTimestamp = Date.now()
    logWrapper(
      ~logType=ERROR,
      ~eventName=CONFIRM_CALL,
      ~url=uri,
      ~customLogUrl,
      ~env,
      ~category=API,
      ~statusCode="504",
      ~apiLogType=Some(NoResponse),
      ~data=err->toJson,
      ~publishableKey,
      ~paymentId,
      ~paymentMethod=None,
      ~paymentExperience=None,
      ~timestamp=respTimestamp,
      ~latency={respTimestamp -. initTimestamp},
      (),
    )
    Promise.resolve(None)
  })
}

@react.component
let dummy = () => {
  React.null
}

let initialise = headless => {
  AppRegistry.registerComponent("dummy", _ => dummy)
  AppRegistry.registerHeadlessTask("dummy", () => {
    _data => {
      Promise.resolve()
    }
  })

  Dict.get(ReactNative.NativeModules.nativeModules, headless)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.getOr(Dict.make())

  //   let eventEmitter = NativeEventEmitter.make(hyperSwitchHeadlessDict)
  //   eventEmitter->NativeEventEmitter.removeAllListeners("test")
  //   eventEmitter->NativeEventEmitter.addListener("test", event => Console.log2(">>>>>>>>>>>>>>>>>", event))
}

let registerHeadless = headless => {
  let hyperSwitchHeadlessDict = initialise(headless)

  let exitHeadless = response =>
    switch hyperSwitchHeadlessDict->Dict.get("exitHeadless") {
    | Some(exitHeadless) => jsonToStrFun(exitHeadless)(response)
    | None => ()
    }

  let getPaymentSession = (publishableKey, clientSecret, appId, data, env, customLogUrl) =>
    switch hyperSwitchHeadlessDict->Dict.get("getPaymentSession") {
    | Some(getPaymentSession) =>
      let spmData = switch data {
      | Some(spmData) => spmData->AllPaymentHooks.jsonToSavedPMObj
      | None => []
      }

      let defaultSpmData =
        spmData
        ->Array.find(x =>
          switch x {
          | SAVEDLISTCARD(savedCard) => savedCard.isDefaultPaymentMethod->Option.getOr(false)
          | SAVEDLISTWALLET(savedWallet) => savedWallet.isDefaultPaymentMethod->Option.getOr(false)
          | NONE => false
          }
        )
        ->Option.getOr(NONE)

      if spmData->Array.length > 0 && defaultSpmData != NONE {
        jsonToStrFun2WithCallback(getPaymentSession)(
          defaultSpmData->toJson,
          spmData->toJson,
          _response => {
            let body = switch defaultSpmData {
            | SAVEDLISTCARD(data) =>
              [
                ("client_secret", clientSecret->JSON.Encode.string),
                ("payment_method", "card"->JSON.Encode.string),
                ("payment_token", data.payment_token->Option.getOr("")->JSON.Encode.string),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object
            | SAVEDLISTWALLET(data) =>
              [
                ("client_secret", clientSecret->JSON.Encode.string),
                ("payment_method", "wallet"->JSON.Encode.string),
                (
                  "payment_method_type",
                  data.payment_method_type->Option.getOr("")->JSON.Encode.string,
                ),
                ("payment_token", data.payment_token->Option.getOr("")->JSON.Encode.string),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object
            | NONE => JSON.Encode.null
            }

            confirmAPICall(
              publishableKey,
              clientSecret,
              body->JSON.stringify,
              appId,
              env,
              customLogUrl,
            )
            ->Promise.then(res => {
              let confirmRes =
                res
                ->Option.getOr(JSON.Encode.null)
                ->Utils.getDictFromJson
                ->PaymentConfirmTypes.itemToObjMapper
              exitHeadless(confirmRes.error->toJson)
              Promise.resolve()
            })
            ->ignore
          },
        )
      } else {
        let itemToObjMapper = data => {
          switch data {
          | Some(data) =>
            let dict = data->Utils.getDictFromJson
            let errorDict =
              Dict.get(dict, "error")
              ->Option.getOr(JSON.Encode.null)
              ->JSON.Decode.object
              ->Option.getOr(Dict.make())
            let error: PaymentConfirmTypes.error = {
              message: Utils.getString(
                errorDict,
                "message",
                Utils.getString(
                  dict,
                  "error_message",
                  Utils.getString(
                    dict,
                    "error",
                    "There is no customer default saved payment method data",
                  ),
                ),
              ),
              code: Utils.getString(
                errorDict,
                "code",
                Utils.getString(dict, "error_code", "no_data"),
              ),
              type_: Utils.getString(errorDict, "type", Utils.getString(dict, "type", "no_data")),
              status: Utils.getString(dict, "status", "failed"),
            }
            error
          | None =>
            if publishableKey == "" {
              {
                message: "Missing Required Field - Publishable Key",
                code: "no_data",
                type_: "no_data",
                status: "failed",
              }
            } else if clientSecret == "" {
              {
                message: "Missing Required Field - Client Secret",
                code: "no_data",
                type_: "no_data",
                status: "failed",
              }
            } else {
              {
                message: "There is no customer default saved payment method data",
                code: "no_data",
                type_: "no_data",
                status: "failed",
              }
            }
          }
        }

        let error = itemToObjMapper(data)->toJson

        jsonToStrFun2WithCallback(getPaymentSession)(error, []->toJson, _response => {
          exitHeadless(error)
        })
      }
    | None => ()
    }

  let getNativePropCallback = response => {
    let nativeProp = SdkTypes.nativeJsonToRecord(response, 0)

    if nativeProp.publishableKey != "" && nativeProp.clientSecret != "" {
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
      savedPaymentMethodAPICall(
        nativeProp.publishableKey,
        nativeProp.clientSecret,
        nativeProp.hyperParams.appId,
        nativeProp.env,
        nativeProp.customLogUrl,
      )
      ->Promise.then(res => {
        getPaymentSession(
          nativeProp.publishableKey,
          nativeProp.clientSecret,
          nativeProp.hyperParams.appId,
          res,
          nativeProp.env,
          nativeProp.customLogUrl,
        )

        Promise.resolve()
      })
      ->ignore
    } else {
      getPaymentSession(
        nativeProp.publishableKey,
        nativeProp.clientSecret,
        nativeProp.hyperParams.appId,
        None,
        nativeProp.env,
        nativeProp.customLogUrl,
      )
    }
  }

  let initialisePaymentSession = () => {
    switch hyperSwitchHeadlessDict->Dict.get("initialisePaymentSession") {
    | Some(initialisePaymentSession) =>
      jsonWithCallback(initialisePaymentSession)(getNativePropCallback)
    | None => ()
    }
  }

  initialisePaymentSession()
}

let _ = registerHeadless
