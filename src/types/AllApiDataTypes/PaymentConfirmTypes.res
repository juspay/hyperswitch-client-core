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
  payment_type?: string,
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

type nextAction = {
  redirectToUrl: string,
  type_: string,
  threeDsData?: threeDsData,
  session_token?: sessionToken,
  bank_transfer_steps_and_charges_detail?: bank_transfer_steps_and_charges_details,
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
    let bankTransferStepsAndChargesDetailsDict =
      json
      ->Dict.get("bank_transfer_steps_and_charges_details")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.object
      ->Option.getOr(Dict.make())
    let achCreditTransferDict =
      bankTransferStepsAndChargesDetailsDict
      ->Dict.get("ach_credit_transfer")
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
      bank_transfer_steps_and_charges_detail: {
        ach_credit_transfer: {
          account_number: getString(achCreditTransferDict, "account_number", ""),
          bank_name: getString(achCreditTransferDict, "bank_name", ""),
          routing_number: getString(achCreditTransferDict, "routing_number", ""),
          swift_code: getString(achCreditTransferDict, "swift_code", ""),
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
