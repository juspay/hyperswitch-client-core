@module("./ButtonHookImpl")
external usePayButton: unit => (
  (~sessionObject: SessionsType.sessions, ~resolve: 'a) => unit,
  (~sessionObject: SessionsType.sessions) => unit,
) = "usePayButton"

type walletStatus =
  | Success(
      RescriptCore.Dict.t<Core__JSON.t>,
      option<SdkTypes.addressDetails>,
      option<SdkTypes.addressDetails>,
    )
  | Cancelled
  | Failed(string)
  | Simulated

let useProcessPayButtonResult = () => {
  (walletType: SdkTypes.payment_method_type_wallet, var) => {
    switch walletType {
    | GOOGLE_PAY =>
      let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
      switch paymentData.error {
      | "" =>
        let json = paymentData.paymentMethodData->JSON.parseExn
        let paymentDataFromGPay =
          json
          ->Utils.getDictFromJson
          ->WalletType.itemToObjMapper
        let billingAddress = switch paymentDataFromGPay.paymentMethodData.info {
        | Some(info) => info.billing_address
        | None => None
        }
        let shippingAddress = paymentDataFromGPay.shippingDetails

        Success(
          paymentDataFromGPay.paymentMethodData->Utils.getJsonObjectFromRecord,
          billingAddress,
          shippingAddress,
        )
      | "Cancel" => Cancelled
      | err => Failed(err)
      }
    | APPLE_PAY =>
      switch var
      ->Dict.get("status")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.string
      ->Option.getOr("") {
      | "Cancelled" => Cancelled
      | "Failed" | "Error" =>
        Failed(
          var
          ->Dict.get("status")
          ->Option.getOr(JSON.Encode.null)
          ->JSON.Decode.string
          ->Option.getOr("Failed"),
        )
      | _ => {
          let transaction_identifier =
            var->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null)

          if (
            transaction_identifier->Utils.getStringFromJson(
              "Simulated Identifier",
            ) == "Simulated Identifier"
          ) {
            Simulated
          } else {
            let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)
            let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)

            let billingAddress =
              var->AddressUtils.getApplePayBillingAddress(
                "billing_contact",
                Some("shipping_contact"),
              )
            let shippingAddress =
              var->AddressUtils.getApplePayBillingAddress("shipping_contact", None)

            let paymentData =
              [
                ("payment_data", payment_data),
                ("payment_method", payment_method),
                ("transaction_identifier", transaction_identifier),
              ]->Dict.fromArray

            Success(paymentData, billingAddress, shippingAddress)
          }
        }
      }
    | PAYPAL =>
      let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
      switch paymentData.error {
      | "" =>
        let json = paymentData.paymentMethodData->JSON.Encode.string
        let paymentData = [("token", json)]->Dict.fromArray
        Success(paymentData, None, None)
      | "User has canceled" => Cancelled
      | err => Failed(err)
      }
    | SAMSUNG_PAY =>
      let status =
        var
        ->Dict.get("status")
        ->Option.getOr(JSON.Encode.null)
        ->JSON.Decode.string
        ->Option.getOr("")
      let message =
        var
        ->Dict.get("message")
        ->Option.getOr(JSON.Encode.null)
        ->JSON.Decode.string
        ->Option.getOr("")
      if status === "success" {
        let response =
          message
          ->JSON.parseExn
          ->JSON.Decode.object
          ->Option.getOr(Dict.make())

        let samsungPayData = SamsungPayType.itemToObjMapper(response)->Utils.getJsonObjectFromRecord
        Success(samsungPayData, None, None)
      } else {
        Failed(message)
      }
    | _ => Cancelled
    }
  }
}
