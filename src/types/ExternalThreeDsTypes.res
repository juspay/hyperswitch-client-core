type statusType = {
  status: string,
  message: string,
}

type sdkEphemeralKey = {
  kty: string,
  crv: string,
  x: string,
  y: string,
}

type sdkInformation = {
  sdk_app_id: string,
  sdk_enc_data: string,
  sdk_ephem_pub_key: sdkEphemeralKey,
  sdk_trans_id: string,
  sdk_reference_number: string,
  sdk_max_timeout: int,
}
type authCallBody = {
  client_secret: string,
  device_channel: string,
  threeds_method_comp_ind: string,
  sdk_information: sdkInformation,
}

type aReqParams = {
  deviceData: string,
  messageVersion: string,
  sdkTransId: string,
  sdkAppId: string,
  sdkEphemeralKey: JSON.t,
  sdkReferenceNo: string,
}
type authCallResponse = {
  transStatus: string,
  acsSignedContent: string,
  acsRefNumber: string,
  acsTransactionId: string,
  threeDSRequestorAppURL: option<string>,
  threeDSServerTransId: string,
  dsTransactionId: string,
}

type pollCallResponse = {
  pollId: string,
  status: string,
}

type errorType = {
  errorCode: string,
  errorMessage: string,
}

type authResponse = AUTH_RESPONSE(authCallResponse) | AUTH_ERROR(errorType)

let authResponseItemToObjMapper = (dict): authResponse => {
  dict->ErrorUtils.isError
    ? AUTH_ERROR({
        errorCode: dict->ErrorUtils.getErrorCode,
        errorMessage: dict->ErrorUtils.getErrorMessage,
      })
    : AUTH_RESPONSE({
        transStatus: dict->Utils.getDictFromJson->Utils.getString("trans_status", ""),
        acsSignedContent: dict->Utils.getDictFromJson->Utils.getString("acs_signed_content", ""),
        acsRefNumber: dict->Utils.getDictFromJson->Utils.getString("acs_reference_number", ""),
        acsTransactionId: dict->Utils.getDictFromJson->Utils.getString("acs_trans_id", ""),
        threeDSRequestorAppURL: dict
        ->Utils.getDictFromJson
        ->Utils.getOptionString("three_ds_requestor_app_url"),
        threeDSServerTransId: dict
        ->Utils.getDictFromJson
        ->Utils.getString("three_dsserver_trans_id", ""),
        dsTransactionId: "",
      })
}

let pollResponseItemToObjMapper = (dict): pollCallResponse => {
  {
    pollId: dict->Utils.getString("poll_id", ""),
    status: dict->Utils.getString("status", ""),
  }
}
