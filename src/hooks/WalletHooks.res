open SdkTypes
open LoadingContext
open PaymentScreenContext

type samsungPayStatus = {
  status: JSON.t,
  message: string,
}

let useWallet = (
  ~selectedObj: SavedPaymentMethodContext.selectedPMObject,
  ~setMissingFieldsData,
  ~processRequestFn,
  ~isWidget=false,
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
  let (_, setPaymentScreenType) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let getMissingFieldsAndPaymentMethodData = WalletMissingFieldsHook.useGetMissingFields()

  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()

  let handleGooglePayPayment = (var, ~walletTypeStr) => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let paymentDataFromGPay = json->Utils.getDictFromJson->WalletType.itemToObjMapper
      let billingAddress = switch paymentDataFromGPay.paymentMethodData.info {
      | Some(info) => info.billing_address
      | None => None
      }
      let shippingAddress = paymentDataFromGPay.shippingDetails

      let walletType =
        allApiData.paymentList
        ->Array.find(pm =>
          switch pm {
          | WALLET(walletData) =>
            walletData.payment_method_type == selectedObj.walletName->SdkTypes.walletTypeToStrMapper
          | _ => false
          }
        )
        ->Option.flatMap(pm =>
          switch pm {
          | WALLET(walletData) => Some(walletData)
          | _ => None
          }
        )

      switch walletType {
      | Some(walletTypeData) =>
        let (
          hasMissingFields,
          updatedRequiredFields,
          paymentMethodData,
        ) = getMissingFieldsAndPaymentMethodData(
          walletTypeData.required_field,
          ~billingAddress,
          ~shippingAddress,
          ~email=paymentDataFromGPay.email,
          ~collectBillingDetailsFromWallets=allApiData.additionalPMLData.collectBillingDetailsFromWallets,
        )

        if hasMissingFields && !isWidget {
          setPaymentScreenType(
            WALLET_MISSING_FIELDS(
              updatedRequiredFields,
              walletTypeData,
              GooglePayData(paymentDataFromGPay),
            ),
          )
          setLoading(FillingDetails)
        } else {
          paymentMethodData->Dict.set(
            "wallet",
            [
              (
                selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
                paymentDataFromGPay.paymentMethodData->Utils.getJsonObjectFromRecord,
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object,
          )

          processRequestFn(
            ~payment_method="wallet",
            ~payment_method_data=paymentMethodData->JSON.Encode.object,
            ~payment_method_type=walletTypeStr,
            ~email=?paymentDataFromGPay.email,
            (),
          )
        }
      | None => ()
      }
    | "Cancel" =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | err =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message=err)
    }
  }

  let handleApplePayPayment = (var, ~walletTypeStr) => {
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
      let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)
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
        let billingAddress = var->WalletType.getBillingContact("billing_contact")
        let shippingAddress = var->WalletType.getBillingContact("shipping_contact")

        let walletType =
          allApiData.paymentList
          ->Array.find(pm =>
            switch pm {
            | WALLET(walletData) =>
              walletData.payment_method_type ==
                selectedObj.walletName->SdkTypes.walletTypeToStrMapper
            | _ => false
            }
          )
          ->Option.flatMap(pm =>
            switch pm {
            | WALLET(walletData) => Some(walletData)
            | _ => None
            }
          )

        switch walletType {
        | Some(walletTypeData) =>
          let (
            hasMissingFields,
            updatedRequiredFields,
            paymentMethodData,
          ) = getMissingFieldsAndPaymentMethodData(
            walletTypeData.required_field,
            ~billingAddress,
            ~shippingAddress,
            ~collectBillingDetailsFromWallets=allApiData.additionalPMLData.collectBillingDetailsFromWallets,
          )

          if hasMissingFields && !isWidget {
            let paymentDataFromApplePay = var->WalletType.applePayItemToObjMapper
            setMissingFieldsData(_ => updatedRequiredFields)
            setPaymentScreenType(
              WALLET_MISSING_FIELDS(
                updatedRequiredFields,
                walletTypeData,
                ApplePayData(paymentDataFromApplePay),
              ),
            )
            setLoading(FillingDetails)
          } else {
            let paymentData =
              [
                ("payment_data", payment_data),
                ("payment_method", payment_method),
                ("transaction_identifier", transaction_identifier),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object

            paymentMethodData->Dict.set(
              "wallet",
              [(selectedObj.walletName->SdkTypes.walletTypeToStrMapper, paymentData)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            )

            processRequestFn(
              ~payment_method="wallet",
              ~payment_method_data=paymentMethodData->JSON.Encode.object,
              ~payment_method_type=walletTypeStr,
              ~email=?switch billingAddress {
              | Some(billing) => billing.email
              | None => None
              },
              (),
            )
          }
        | None => ()
        }
      }
    }
  }

  let handleSamsungPayPayment = (status, billingDetails, ~walletTypeStr) => {
    if status->ThreeDsUtils.isStatusSuccess {
      let response = status.message->JSON.parseExn->JSON.Decode.object->Option.getOr(Dict.make())

      let billingAddress = billingDetails->SamsungPayType.getAddressObj(BILLING_ADDRESS)
      let shippingAddress = billingDetails->SamsungPayType.getAddressObj(SHIPPING_ADDRESS)
      let samsungPayData = SamsungPayType.itemToObjMapper(response)

      let walletType =
        allApiData.paymentList
        ->Array.find(pm =>
          switch pm {
          | WALLET(walletData) =>
            walletData.payment_method_type == selectedObj.walletName->SdkTypes.walletTypeToStrMapper
          | _ => false
          }
        )
        ->Option.flatMap(pm =>
          switch pm {
          | WALLET(walletData) => Some(walletData)
          | _ => None
          }
        )

      switch walletType {
      | Some(walletTypeData) =>
        let (
          hasMissingFields,
          updatedRequiredFields,
          paymentMethodData,
        ) = getMissingFieldsAndPaymentMethodData(
          walletTypeData.required_field,
          ~billingAddress,
          ~shippingAddress,
          ~collectBillingDetailsFromWallets=allApiData.additionalPMLData.collectBillingDetailsFromWallets,
        )

        if hasMissingFields && !isWidget {
          setMissingFieldsData(_ => updatedRequiredFields)
          setPaymentScreenType(
            WALLET_MISSING_FIELDS(
              updatedRequiredFields,
              walletTypeData,
              SamsungPayData(samsungPayData, billingAddress, shippingAddress),
            ),
          )
          setLoading(FillingDetails)
        } else {
          paymentMethodData->Dict.set(
            "wallet",
            [
              (
                selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
                samsungPayData->Utils.getJsonObjectFromRecord,
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object,
          )

          processRequestFn(
            ~payment_method="wallet",
            ~payment_method_data=paymentMethodData->JSON.Encode.object,
            ~payment_method_type=walletTypeStr,
            ~email=?switch billingAddress {
            | Some(address) => address.email
            | None => None
            },
            (),
          )
        }
      | None => ()
      }
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
