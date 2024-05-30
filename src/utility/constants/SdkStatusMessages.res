type statusMessages = {
  successMsg: string,
  errorMsg: string,
  apiCallFailure: string,
}

let retrievePaymentStatus = {
  successMsg: "payment successful",
  errorMsg: "payment failed",
  apiCallFailure: "retrieve failure, cannot fetch the status of payment",
}

let pollingCallStatus = {
  successMsg: "polling status complete",
  errorMsg: "payment status pending",
  apiCallFailure: "polling failure, cannot fetch the status of payment",
}

let externalThreeDsModuleStatus = {
  successMsg: "external 3DS dependency found",
  errorMsg: "integration error, external 3DS dependency not found",
  apiCallFailure: "",
}

let authorizeCallStatus = {
  successMsg: "payment authorised successfully",
  errorMsg: "authorize failed",
  apiCallFailure: "authorize failure, cannot process this payment",
}

let authenticationCallStatus = {
  successMsg: "authentication call successful",
  errorMsg: "authentication call fail",
  apiCallFailure: "authentication failure,something wrong with AReq",
}

let threeDsSdkChallengeStatus = {
  successMsg: "challenge generated successfully",
  errorMsg: "challenge generation failed",
  apiCallFailure: "",
}

let threeDsSDKGetAReqStatus = {
  successMsg: "",
  errorMsg: "3DS SDK DDC failure, cannot generate AReq params",
  apiCallFailure: "",
}
