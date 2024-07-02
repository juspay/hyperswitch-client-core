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

type nextAction = {redirectToUrl: string, type_: string, threeDsData?: threeDsData}
type error = {message?: string, code?: string, type_?: string, status?: string}
type intent = {nextAction: nextAction, status: string, error: error}
open Utils

// let defaultRedirectTourl = {
//   returnUrl: "",
//   url: "",
// }
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

/* let defaultIntent = {
  nextAction: defaultNextAction,
  status: "",
  error: defaultError,
}
let getRedirectToUrl = (dict, str) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      returnUrl: getString(json, "redirect_to_url", ""),
      url: getString(json, "url", ""),
    }
  })
  ->Option.getOr(defaultRedirectTourl)
}*/
let getNextAction = (dict, str) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      redirectToUrl: getString(json, "redirect_to_url", ""),
      type_: getString(json, "type", ""),
    }
  })
  ->Option.getOr(defaultNextAction)
}
/* let getError = (dict, str, status) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      message: getString(json, "message", ""),
      code: getString(json, "code", ""),
      type_: getString(json, "type", ""),
      status,
    }
  })
  ->Option.getOr(defaultError)
}*/

let itemToObjMapper = dict => {
  let errorDict =
    Dict.get(dict, "error")
    ->Option.getOr(JSON.Encode.null)
    ->JSON.Decode.object
    ->Option.getOr(Dict.make())
  {
    nextAction: getNextAction(dict, "next_action"),
    status: getString(dict, "status", ""),
    // error: getError(dict, "error"),
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
