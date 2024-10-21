// type redirectToUrl = {
//   returnUrl: string,
//   url: string,
// }

type pollConfig = {
  pollId: string,
  delayInSecs: int,
  frequency: int,
}
type threeDsData = {
  threeDsAuthenticationUrl: string,
  threeDsAuthorizeUrl: string,
  messageVersion: string,
  directoryServerId: string,
  pollConfig: pollConfig,
}

type sessionToken = {
  wallet_name: string,
  open_banking_session_token: string,
}

type nextAction = {
  redirectToUrl: string,
  type_: string,
  threeDsData?: threeDsData,
  session_token?: sessionToken,
}
type error = {message?: string, code?: string, type_?: string, status?: string}
type intent = {nextAction: nextAction, status: string, error: error}
open Utils

let defaultNextAction = {
  redirectToUrl: "",
  type_: "",
}

let defaultConfirmError = {
  type_: "",
  status: "failed",
  code: "confirmPayment failed",
  message: "An unknown error has occurred please retry",
}

let defaultCancelError = {
  type_: "",
  status: "cancelled",
  code: "",
  message: "",
}

let getNextAction = (dict, str) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    let threeDSDataDict =
      json
      ->Dict.get("three_ds_data")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.object
      ->Option.getOr(Dict.make())

    let pollConfigDict =
      threeDSDataDict
      ->Dict.get("poll_config")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.object
      ->Option.getOr(Dict.make())

    let sessionTokenDict =
      json
      ->Dict.get("session_token")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.object
      ->Option.getOr(Dict.make())

    {
      redirectToUrl: getString(json, "redirect_to_url", ""),
      type_: getString(json, "type", ""),
      threeDsData: {
        threeDsAuthorizeUrl: getString(threeDSDataDict, "three_ds_authorize_url", ""),
        threeDsAuthenticationUrl: getString(threeDSDataDict, "three_ds_authentication_url", ""),
        messageVersion: getString(threeDSDataDict, "message_version", ""),
        directoryServerId: getString(threeDSDataDict, "directory_server_id", ""),
        pollConfig: {
          pollId: getString(pollConfigDict, "poll_id", ""),
          delayInSecs: getOptionFloat(pollConfigDict, "delay_in_secs")
          ->Option.getOr(0.)
          ->Int.fromFloat,
          frequency: getOptionFloat(pollConfigDict, "frequency")->Option.getOr(0.)->Int.fromFloat,
        },
      },
      session_token: {
        wallet_name: getString(sessionTokenDict, "wallet_name", ""),
        open_banking_session_token: getString(sessionTokenDict, "open_banking_session_token", ""),
      },
    }
  })
  ->Option.getOr(defaultNextAction)
}

let itemToObjMapper = dict => {
  let errorDict =
    Dict.get(dict, "error")
    ->Option.getOr(JSON.Encode.null)
    ->JSON.Decode.object
    ->Option.getOr(Dict.make())
  {
    nextAction: getNextAction(dict, "next_action"),
    status: getString(dict, "status", ""),
    error: {
      message: getString(
        errorDict,
        "message",
        getString(dict, "error_message", getString(dict, "error", "confirmPayment failed")),
      ),
      code: getString(errorDict, "code", getString(dict, "error_code", "")),
      type_: getString(errorDict, "type", getString(dict, "type", "confirmPayment failed")),
      status: getString(dict, "status", "failed"),
    },
  }
}

type responseFromJava = {
  paymentMethodData: string,
  clientSecret: string,
  paymentMethodType: string,
  publishableKey: string,
  error: string,
  confirm: bool,
}

let itemToObjMapperJava = dict => {
  {
    paymentMethodData: getString(dict, "paymentMethodData", ""),
    clientSecret: getString(dict, "clientSecret", ""),
    paymentMethodType: getString(dict, "paymentMethodType", ""),
    publishableKey: getString(dict, "publishableKey", ""),
    error: getString(dict, "error", ""),
    confirm: getBool(dict, "confirm", false),
  }
}
