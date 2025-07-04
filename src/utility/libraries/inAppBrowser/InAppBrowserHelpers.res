open InAppBrowserTypes
let determineStatus = (message: string, res: InAppBrowserTypes.res) => {
  if (
    message->String.includes("status=succeeded") ||
    message->String.includes("status=processing") ||
    message->String.includes("status=requires_capture") ||
    message->String.includes("status=partially_captured")
  ) {
    Success
  } else if (
    message->String.includes("status=failed") ||
      message->String.includes("status=requires_payment_method")
  ) {
    Failed
  } else if res.\"type" == "cancel" {
    Cancel
  } else {
    InAppBrowserTypes.Error
  }
}

let parsePaymentData = (message: string) => {
  let params = message->String.split("&")
  let paymentID = (params[1]->Option.getOr("")->String.split("="))[1]->Option.getOr("")
  let amount = (params[2]->Option.getOr("")->String.split("="))[1]->Option.getOr("")
  (paymentID, amount)
}
