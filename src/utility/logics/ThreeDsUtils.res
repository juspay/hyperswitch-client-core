open ExternalThreeDsTypes
let getThreeDsNextActionObj = (
  nextActionObj: option<PaymentConfirmTypes.nextAction>,
): PaymentConfirmTypes.nextAction => {
  nextActionObj->Option.getOr({
    redirectToUrl: "",
    type_: "",
    threeDsData: {
      threeDsAuthenticationUrl: "",
      threeDsAuthorizeUrl: "",
      messageVersion: "",
      directoryServerId: "",
      pollConfig: {
        pollId: "",
        delayInSecs: 0,
        frequency: 0,
      },
    },
  })
}

let getThreeDsDataObj = (
  nextActionObj: PaymentConfirmTypes.nextAction,
): PaymentConfirmTypes.threeDsData => {
  nextActionObj.threeDsData->Option.getOr({
    threeDsAuthenticationUrl: "",
    threeDsAuthorizeUrl: "",
    messageVersion: "",
    directoryServerId: "",
    pollConfig: {
      pollId: "",
      delayInSecs: 0,
      frequency: 0,
    },
  })
}

let generateAuthenticationCallBody = (clientSecret, aReqParams) => {
  let ephemeralKeyDict =
    aReqParams.sdkEphemeralKey
    ->JSON.Decode.string
    ->Option.getOr("")
    ->JSON.parseExn
    ->JSON.Decode.object
    ->Option.getOr(Dict.make())

  let body: authCallBody = {
    client_secret: clientSecret,
    device_channel: "APP",
    threeds_method_comp_ind: "N",
    sdk_information: {
      sdk_app_id: aReqParams.sdkAppId,
      sdk_enc_data: aReqParams.deviceData,
      sdk_ephem_pub_key: {
        kty: ephemeralKeyDict->Utils.getString("kty", ""),
        crv: ephemeralKeyDict->Utils.getString("crv", ""),
        x: ephemeralKeyDict->Utils.getString("x", ""),
        y: ephemeralKeyDict->Utils.getString("y", ""),
      },
      sdk_trans_id: aReqParams.sdkTransId,
      sdk_reference_number: aReqParams.sdkReferenceNo,
      sdk_max_timeout: 10,
    },
  }
  let stringifiedBody = body->JSON.stringifyAny->Option.getOr("")
  stringifiedBody
}

let getAuthCallHeaders = publishableKey => {
  [
    ("Content-Type", "application/json"),
    ("api-key", publishableKey),
    ("Accept", "application/json"),
    // ("x-feature", "router-custom-be"),
  ]->Dict.fromArray
}

let isStatusSuccess = (status: statusType) => {
  status.status === "success"
}

// let getMessageVersionFromConfirmResponse = dict => {
//   let externalAuthDict =
//     Dict.get(dict, "external_authentication_details")
//     ->Option.getOr(JSON.Encode.null)
//     ->JSON.Decode.object
//     ->Option.getOr(Dict.make())

//   Utils.getString(externalAuthDict, "version", "")
// }

let sdkEnvironmentToStrMapper = (env: GlobalVars.envType) => {
  switch env {
  | GlobalVars.SANDBOX => "SANDBOX"
  | GlobalVars.PROD => "PROD"
  | GlobalVars.INTEG => "INTEG"
  }
}
