type online = {
  user_agent?: string,
  accept_header?: string,
  language?: string,
  color_depth?: int,
  java_enabled?: bool,
  java_script_enabled?: bool,
  screen_height?: int,
  screen_width?: int,
  time_zone?: int,
  device_model?: string,
  os_type?: string,
  os_version?: string,
}

type customer_acceptance = {
  acceptance_type: string,
  accepted_at: string,
  online: online,
}

type mandate_data = {customer_acceptance: customer_acceptance}

type redirectType = {
  client_secret: string,
  return_url?: string,
  email?: string,
  payment_method?: string,
  payment_method_type?: string,
  payment_method_data?: JSON.t,
  payment_experience?: string,
  payment_token?: string,
  mandate_data?: mandate_data,
  browser_info?: online,
  customer_acceptance?: customer_acceptance,
  card_cvc?: string,
}

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
type ach_credit_transfer = {
  account_number: string,
  bank_name: string,
  routing_number: string,
  swift_code: string,
}
type bank_transfer_steps_and_charges_details = {ach_credit_transfer?: ach_credit_transfer}

type upiInformation = {sdk_uri: string}

type waitScreenPollConfig = {
  delay_in_secs: int,
  frequency: int,
}

type waitScreenInformation = {
  display_from_timestamp: float,
  display_to_timestamp: float,
  poll_config: waitScreenPollConfig,
}

type nextAction = {
  redirectToUrl: string,
  type_: string,
  threeDsData?: threeDsData,
  session_token?: sessionToken,
  bank_transfer_steps_and_charges_detail?: bank_transfer_steps_and_charges_details,
  upiInformation?: upiInformation,
  waitScreenInformation?: waitScreenInformation,
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
let defaultSuccess = {
  type_: "",
  status: "Processing",
  code: "",
  message: "",
}
let getACH_bank_transfer = (data: option<bank_transfer_steps_and_charges_details>) => {
  switch data {
  | Some(data) => data.ach_credit_transfer
  | None =>
    Some({
      account_number: "",
      bank_name: "",
      routing_number: "",
      swift_code: "",
    })
  }
}

let getACH_details = (data: option<ach_credit_transfer>) => {
  data->Option.getOr({
    account_number: "",
    bank_name: "",
    routing_number: "",
    swift_code: "",
  })
}
let getDict = (json, key) =>
  json
  ->Dict.get(key)
  ->Option.getOr(JSON.Encode.null)
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())

let parseThreeDSData = json => {
  let threeDSDataDict = getDict(json, "three_ds_data")
  let pollConfigDict = getDict(threeDSDataDict, "poll_config")

  {
    threeDsAuthorizeUrl: getString(threeDSDataDict, "three_ds_authorize_url", ""),
    threeDsAuthenticationUrl: getString(threeDSDataDict, "three_ds_authentication_url", ""),
    messageVersion: getString(threeDSDataDict, "message_version", ""),
    directoryServerId: getString(threeDSDataDict, "directory_server_id", ""),
    pollConfig: {
      pollId: getString(pollConfigDict, "poll_id", ""),
      delayInSecs: getOptionFloat(pollConfigDict, "delay_in_secs")->Option.getOr(0.)->Int.fromFloat,
      frequency: getOptionFloat(pollConfigDict, "frequency")->Option.getOr(0.)->Int.fromFloat,
    },
  }
}

let parseBankTransferDetails = json => {
  let stepsDict = getDict(json, "bank_transfer_steps_and_charges_details")
  let achCreditDict = getDict(stepsDict, "ach_credit_transfer")

  {
    ach_credit_transfer: {
      account_number: getString(achCreditDict, "account_number", ""),
      bank_name: getString(achCreditDict, "bank_name", ""),
      routing_number: getString(achCreditDict, "routing_number", ""),
      swift_code: getString(achCreditDict, "swift_code", ""),
    },
  }
}

let parseSessionToken = json => {
  let sessionDict = getDict(json, "session_token")

  {
    wallet_name: getString(sessionDict, "wallet_name", ""),
    open_banking_session_token: getString(sessionDict, "open_banking_session_token", ""),
  }
}

// let parseUpiIntent = json => {
//   let upiDict = json->Dict.get("sdk_uri")->Option.isSome ? json : Dict.make()

//   upiDict->Dict.get("sdk_uri")->Option.isSome
//     ? Some({
//         sdk_uri: getString(upiDict, "sdk_uri", ""),
//       })
//     : None
// }

let parseUpiInformation = json => {
  let uri = switch json->Dict.get("sdk_uri") {
  | Some(_) => getString(json, "sdk_uri", "")
  | None =>
    switch json->Dict.get("qr_code_url") {
    | Some(_) => getString(json, "qr_code_url", "")
    | None => ""
    }
  }

  {sdk_uri: uri}
}

let parseWaitScreenInformation = json => {
  let pollConfigDict = getDict(json, "poll_config")
  {
    display_from_timestamp: getOptionFloat(json, "display_from_timestamp")->Option.getOr(0.),
    display_to_timestamp: getOptionFloat(json, "display_to_timestamp")->Option.getOr(0.),
    poll_config: {
      delay_in_secs: getOptionFloat(pollConfigDict, "delay_in_secs")
      ->Option.getOr(0.)
      ->Int.fromFloat,
      frequency: getOptionFloat(pollConfigDict, "frequency")
      ->Option.getOr(0.)
      ->Int.fromFloat,
    },
  }
}

let buildNextAction = json => {
  {
    redirectToUrl: getString(json, "redirect_to_url", ""),
    type_: getString(json, "type", ""),
    threeDsData: parseThreeDSData(json),
    bank_transfer_steps_and_charges_detail: parseBankTransferDetails(json),
    session_token: parseSessionToken(json),
    upiInformation: parseUpiInformation(json),
    waitScreenInformation: parseWaitScreenInformation(json),
  }
}

let getNextAction = (dict, key) =>
  dict
  ->Dict.get(key)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(buildNextAction)
  ->Option.getOr(defaultNextAction)

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
