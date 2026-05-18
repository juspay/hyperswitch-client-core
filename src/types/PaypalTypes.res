type status = Success | Cancelled | Failed

type callbackResponse = {
  status: status,
  orderId: string,
  payerId: string,
  error_message: string,
}

type requestParams = {
  clientId: string,
  orderId: string,
  environment: string,
  returnUrl: string,
}

let parseStatus = (statusStr: string): status => {
  switch statusStr {
  | "success" => Success
  | "cancelled" => Cancelled
  | _ => Failed
  }
}

let parseCallback = (result: PaypalModule.paypalCallbackResult): callbackResponse => {
  {
    status: result.status->parseStatus,
    orderId: result.orderId,
    payerId: result.payerId,
    error_message: result.error_message,
  }
}

let encodeRequestParams = (params: requestParams): string => {
  [
    ("clientId", params.clientId->JSON.Encode.string),
    ("orderId", params.orderId->JSON.Encode.string),
    ("environment", params.environment->JSON.Encode.string),
    ("returnUrl", params.returnUrl->JSON.Encode.string),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
  ->JSON.stringify
}
