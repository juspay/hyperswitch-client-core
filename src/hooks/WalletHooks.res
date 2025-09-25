open LoadingContext

type samsungPayStatus = {
  status: JSON.t,
  message: string,
}

let useWallet = (
  ~selectedObj: SavedPaymentMethodContext.selectedPMObject,
  ~setMissingFieldsData as _,
  ~processRequestFn as _,
  ~isWidget as _=false,
): (
  (Dict.t<JSON.t>, ~walletTypeStr: string) => unit,
  (Dict.t<JSON.t>, ~walletTypeStr: string) => unit,
  (
    ExternalThreeDsTypes.statusType,
    option<SamsungPayType.addressCollectedFromSpay>,
    ~walletTypeStr: string,
  ) => unit,
) => {
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (_, _setPaymentScreenType) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()

  let handleGooglePayPayment = (var, ~walletTypeStr as _) => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let paymentDataFromGPay = json->Utils.getDictFromJson->WalletType.itemToObjMapper
      let _billingAddress = switch paymentDataFromGPay.paymentMethodData.info {
      | Some(info) => info.billing_address
      | None => None
      }
      let _shippingAddress = paymentDataFromGPay.shippingDetails

      let _walletType =
        allApiData.paymentMethodList->Array.find(pm =>
          pm.payment_method_type == selectedObj.walletName->SdkTypes.walletTypeToStrMapper
        )

    | "Cancel" =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | err =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message=err)
    }
  }

  let handleApplePayPayment = (var, ~walletTypeStr as _) => {
    switch var
    ->Dict.get("status")
    ->Option.getOr(JSON.Encode.null)
    ->JSON.Decode.string
    ->Option.getOr("") {
    | "Cancelled" =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Cancelled")
    | "Failed" =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message="Failed")
    | "Error" =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Error")
    | _ =>
      let _payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)
      let _payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)
      let transaction_identifier =
        var->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null)

      if (
        transaction_identifier->Utils.getStringFromJson(
          "Simulated Identifier",
        ) == "Simulated Identifier"
      ) {
        setTimeout(() => {
          setLoading(FillingDetails)
          showAlert(
            ~errorType="warning",
            ~message="Apple Pay is not supported in Simulated Environment",
          )
        }, 2000)->ignore
      } else {
        let _billingAddress =
          var->AddressUtils.getApplePayBillingAddress("billing_contact", Some("shipping_contact"))
        let _shippingAddress = var->AddressUtils.getApplePayBillingAddress("shipping_contact", None)

        let _walletType =
          allApiData.paymentMethodList->Array.find(pm =>
            pm.payment_method_type == selectedObj.walletName->SdkTypes.walletTypeToStrMapper
          )
      }
    }
  }

  let handleSamsungPayPayment = (status, billingDetails, ~walletTypeStr as _) => {
    if status->ThreeDsUtils.isStatusSuccess {
      let response = status.message->JSON.parseExn->JSON.Decode.object->Option.getOr(Dict.make())

      let _billingAddress = billingDetails->SamsungPayType.getAddressObj(BILLING_ADDRESS)
      let _shippingAddress = billingDetails->SamsungPayType.getAddressObj(SHIPPING_ADDRESS)
      let _samsungPayData = SamsungPayType.itemToObjMapper(response)

      let _walletType =
        allApiData.paymentMethodList->Array.find(pm =>
          pm.payment_method_type == selectedObj.walletName->SdkTypes.walletTypeToStrMapper
        )
    } else {
      setLoading(FillingDetails)
      showAlert(
        ~errorType="warning",
        ~message=`Samsung Pay Error, Please try again ${status.message}`,
      )
    }
    logger(
      ~logType=LoggerTypes.INFO,
      ~value=`SPAY result from native ${status.status->JSON.stringifyAny->Option.getOr("")}`,
      ~category=LoggerTypes.USER_EVENT,
      ~eventName=SAMSUNG_PAY,
      (),
    )
  }
  (handleGooglePayPayment, handleApplePayPayment, handleSamsungPayPayment)
}
