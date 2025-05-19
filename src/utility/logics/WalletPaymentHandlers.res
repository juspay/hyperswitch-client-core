open SdkTypes

type samsungPayStatus = {
  status: JSON.t,
  message: string,
}

let confirmGPay = (
  var: Dict.t<JSON.t>,
  ~walletTypeStr: string,
  ~countryStateData: CountryStateDataContext.data,
  ~setLoading: LoadingContext.sdkPaymentState => unit,
  ~showAlert,
  ~processRequestFn: (
    ~payment_method: string,
    ~payment_method_data: JSON.t,
    ~payment_method_type: string,
    ~email: string=?,
    unit,
  ) => unit,
  (),
) => {
  let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
  switch paymentData.error {
  | "" =>
    let json = paymentData.paymentMethodData->JSON.parseExn
    let obj =
      json
      ->Utils.getDictFromJson
      ->GooglePayTypeNew.itemToObjMapper(
        switch countryStateData {
        | FetchData(data) | Localdata(data) => data.states
        | _ => Dict.make()
        },
      )
    let payment_method_data =
      [
        (
          "wallet",
          [(walletTypeStr, obj.paymentMethodData->Utils.getJsonObjectFromRecord)]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
        (
          "billing",
          switch obj.paymentMethodData.info {
          | Some(info) =>
            switch info.billing_address {
            | Some(address) => address->Utils.getJsonObjectFromRecord
            | None => JSON.Encode.null
            }
          | None => JSON.Encode.null
          },
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object
    processRequestFn(
      ~payment_method="wallet",
      ~payment_method_data,
      ~payment_method_type=walletTypeStr,
      ~email=?obj.email,
      (),
    )
  | "Cancel" =>
    setLoading(FillingDetails)
    showAlert(~errorType="warning", ~message="Payment was Cancelled")
  | err =>
    setLoading(FillingDetails)
    showAlert(~errorType="error", ~message=err)
  }
}

let confirmApplePay = (
  var: Dict.t<JSON.t>, // Data from Apple Pay
  ~walletTypeStr: string,
  ~countryStateData: CountryStateDataContext.data,
  ~setLoading: LoadingContext.sdkPaymentState => unit,
  ~showAlert,
  ~processRequestFn: (
    ~payment_method: string,
    ~payment_method_data: JSON.t,
    ~payment_method_type: string,
    ~email: string=?,
    unit,
  ) => unit,
  (),
) => {
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
    let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)
    let payment_method_json = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)
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
      let applePayPaymentData =
        [
          ("payment_data", payment_data),
          ("payment_method", payment_method_json),
          ("transaction_identifier", transaction_identifier),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object

      let payment_method_data =
        [
          ("wallet", [(walletTypeStr, applePayPaymentData)]->Dict.fromArray->JSON.Encode.object),
          (
            "billing",
            switch var->GooglePayTypeNew.getBillingContact(
              "billing_contact",
              switch countryStateData {
              | FetchData(data) | Localdata(data) => data.states
              | _ => Dict.make()
              },
            ) {
            | Some(billing) => billing->Utils.getJsonObjectFromRecord
            | None => JSON.Encode.null
            },
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
      processRequestFn(
        ~payment_method="wallet",
        ~payment_method_data,
        ~payment_method_type=walletTypeStr,
        ~email=?switch var->GooglePayTypeNew.getBillingContact(
          "billing_contact",
          switch countryStateData {
          | FetchData(data) | Localdata(data) => data.states
          | _ => Dict.make()
          },
        ) {
        | Some(billing) => billing.email
        | None => None
        },
        (),
      )
    }
  }
}

let confirmSamsungPay = (
  samsungPayResult,
  billingDetails: option<SamsungPayType.addressCollectedFromSpay>,
  ~walletTypeStr: string,
  ~setLoading: LoadingContext.sdkPaymentState => unit,
  ~showAlert,
  ~logger: (
    // Correct type for the logger function from LoggerHook
    ~logType: LoggerTypes.logType,
    ~value: string,
    ~category: LoggerTypes.logCategory,
    ~paymentMethod: string=?,
    ~paymentExperience: string=?,
    ~internalMetadata: string=?,
    ~eventName: LoggerTypes.eventName,
    ~latency: float=?,
    unit,
  ) => unit,
  ~processRequestFn: (
    ~payment_method: string,
    ~payment_method_data: JSON.t,
    ~payment_method_type: string,
    ~email: string=?,
    unit,
  ) => unit,
  (),
) => {
  if samsungPayResult->ThreeDsUtils.isStatusSuccess {
    let response =
      samsungPayResult.message
      ->JSON.parseExn
      ->JSON.Decode.object
      ->Option.getOr(Dict.make())

    let billingAddress = billingDetails->SamsungPayType.getAddressObj(BILLING_ADDRESS)
    let obj = SamsungPayType.itemToObjMapper(response)
    let payment_method_data =
      [
        (
          "wallet",
          [(walletTypeStr, obj->Utils.getJsonObjectFromRecord)]->Dict.fromArray->JSON.Encode.object,
        ),
        (
          "billing",
          switch billingAddress {
          | Some(address) => address->Utils.getJsonObjectFromRecord
          | None => JSON.Encode.null
          },
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object

    processRequestFn(
      ~payment_method="wallet",
      ~payment_method_data,
      ~payment_method_type=walletTypeStr,
      ~email=?switch billingAddress {
      | Some(address) => address.email
      | None => None
      },
      (),
    )
  } else {
    setLoading(FillingDetails)
    showAlert(
      ~errorType="warning",
      ~message=`Samsung Pay Error, Please try again ${samsungPayResult.message}`,
    )
  }
  logger(
    ~logType=LoggerTypes.INFO,
    ~value=`SPAY result from native ${samsungPayResult.status
      ->JSON.stringifyAny
      ->Option.getOr("")}`,
    ~category=LoggerTypes.USER_EVENT,
    ~eventName=SAMSUNG_PAY,
    (),
  )
}
