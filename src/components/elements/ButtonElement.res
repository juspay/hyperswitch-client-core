open ReactNative
open Style

@react.component
let make = (
  ~paymentMethodData: PaymentMethodListType.payment_method_type,
  ~sessionObject,
  ~processToken,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()
  let {
    paypalButonColor,
    googlePayButtonColor,
    applePayButtonColor,
    buttonBorderRadius,
    primaryButtonHeight,
    samsungPayButtonColor,
  } = ThemebasedStyle.useThemeBasedStyle()

  let confirmPayPal = var => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.Encode.string
      let paymentData = [("token", json)]->Dict.fromArray->JSON.Encode.object
      let payment_method_data = [
        (
          paymentMethodData.payment_method_str,
          [(paymentMethodData.payment_method_type ++ "_sdk", paymentData)]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]->Dict.fromArray
      processToken(payment_method_data)
    | "User has canceled" =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | err => showAlert(~errorType="error", ~message=err)
    }
  }

  let confirmGPay = var => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let paymentDataFromGPay =
        json
        ->Utils.getDictFromJson
        ->WalletType.itemToObjMapper
      let _billingAddress = switch paymentDataFromGPay.paymentMethodData.info {
      | Some(info) => info.billing_address
      | None => None
      }
      let _shippingAddress = paymentDataFromGPay.shippingDetails

      processToken(Dict.make())
    | "Cancel" =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | err =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message=err)
    }
  }

  let confirmSamsungPay = (
    status,
    addressFromSPay: option<SamsungPayType.addressCollectedFromSpay>,
  ) => {
    if status->ThreeDsUtils.isStatusSuccess {
      let response =
        status.message
        ->JSON.parseExn
        ->JSON.Decode.object
        ->Option.getOr(Dict.make())

      let _billingAddress =
        addressFromSPay->SamsungPayType.getAddressObj(SamsungPayType.BILLING_ADDRESS)
      let _shippingAddress =
        addressFromSPay->SamsungPayType.getAddressObj(SamsungPayType.SHIPPING_ADDRESS)
      let _samsungPayData = SamsungPayType.itemToObjMapper(response)

      processToken(Dict.make())
    } else {
      setLoading(FillingDetails)
      showAlert(
        ~errorType="warning",
        ~message=`Samsung Pay Error, Please try again ${status.message}`,
      )
    }

    logger(
      ~logType=INFO,
      ~value=`SPAY result from native ${status.status->JSON.stringifyAny->Option.getOr("")}`,
      ~category=USER_EVENT,
      ~eventName=SAMSUNG_PAY,
      (),
    )
  }

  let confirmApplePay = (var: dict<JSON.t>) => {
    logger(
      ~logType=DEBUG,
      ~value=paymentMethodData.payment_method_type,
      ~category=USER_EVENT,
      ~paymentMethod=paymentMethodData.payment_method_type,
      ~eventName=APPLE_PAY_CALLBACK_FROM_NATIVE,
      ~paymentExperience=paymentMethodData.payment_experience,
      (),
    )
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
    | _ => {
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
          let _payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)
          let _payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)

          let _billingAddress = var->AddressUtils.getApplePayBillingAddress("billing_contact")
          let _shippingAddress = var->AddressUtils.getApplePayBillingAddress("shipping_contact")

          processToken(Dict.make())
        }
      }
    }
  }

  React.useEffect1(() => {
    switch paymentMethodData.payment_method_type_wallet {
    | APPLE_PAY => Window.registerEventListener("applePayData", confirmApplePay)
    | GOOGLE_PAY => Window.registerEventListener("googlePayData", confirmGPay)
    | _ => ()
    }
    None
  }, [paymentMethodData.payment_method_type_wallet])

  let pressHandler = () => {
    setLoading(ProcessingPayments)
    logger(
      ~logType=INFO,
      ~value=paymentMethodData.payment_method_type,
      ~category=USER_EVENT,
      ~paymentMethod=paymentMethodData.payment_method_type,
      ~eventName=PAYMENT_METHOD_CHANGED,
      ~paymentExperience=paymentMethodData.payment_experience,
      (),
    )

    if (
      paymentMethodData.payment_experience
      ->Array.find(exp => exp.payment_experience_type_decode == INVOKE_SDK_CLIENT)
      ->Option.isSome
    ) {
      switch paymentMethodData.payment_method_type_wallet {
      | GOOGLE_PAY =>
        HyperModule.launchGPay(
          WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
          confirmGPay,
        )
      | PAYPAL =>
        if (
          sessionObject.session_token !== "" &&
          WebKit.platform == #android &&
          PaypalModule.payPalModule->Option.isSome
        ) {
          PaypalModule.launchPayPal(sessionObject.session_token, confirmPayPal)
        } else if (
          paymentMethodData.payment_experience
          ->Array.find(exp => exp.payment_experience_type_decode == REDIRECT_TO_URL)
          ->Option.isSome
        ) {
          let redirectData = []->Dict.fromArray->JSON.Encode.object
          let payment_method_data = [
            (
              paymentMethodData.payment_method_str,
              [(paymentMethodData.payment_method_type ++ "_redirect", redirectData)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]->Dict.fromArray

          processToken(payment_method_data)
        } else {
          setLoading(FillingDetails)
          showAlert(~errorType="warning", ~message="Payment Method Unavailable")
        }
      | APPLE_PAY =>
        if (
          sessionObject.session_token_data == JSON.Encode.null ||
            sessionObject.payment_request_data == JSON.Encode.null
        ) {
          setLoading(FillingDetails)
          showAlert(~errorType="warning", ~message="Waiting for Sessions API")
        } else {
          logger(
            ~logType=DEBUG,
            ~value=paymentMethodData.payment_method_type,
            ~category=USER_EVENT,
            ~paymentMethod=paymentMethodData.payment_method_type,
            ~eventName=APPLE_PAY_STARTED_FROM_JS,
            ~paymentExperience=paymentMethodData.payment_experience,
            (),
          )

          let timerId = setTimeout(() => {
            setLoading(FillingDetails)
            showAlert(~errorType="warning", ~message="Apple Pay Error, Please try again")
            logger(
              ~logType=DEBUG,
              ~value=paymentMethodData.payment_method_type,
              ~category=USER_EVENT,
              ~paymentMethod=paymentMethodData.payment_method_type,
              ~eventName=APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
              ~paymentExperience=paymentMethodData.payment_experience,
              (),
            )
          }, 5000)

          HyperModule.launchApplePay(
            [
              ("session_token_data", sessionObject.session_token_data),
              ("payment_request_data", sessionObject.payment_request_data),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object
            ->JSON.stringify,
            confirmApplePay,
            _ => {
              logger(
                ~logType=DEBUG,
                ~value=paymentMethodData.payment_method_type,
                ~category=USER_EVENT,
                ~paymentMethod=paymentMethodData.payment_method_type,
                ~eventName=APPLE_PAY_BRIDGE_SUCCESS,
                ~paymentExperience=paymentMethodData.payment_experience,
                (),
              )
            },
            _ => {
              clearTimeout(timerId)
            },
          )
        }
      | SAMSUNG_PAY => {
          logger(
            ~logType=INFO,
            ~value="Samsung Pay Button Clicked",
            ~category=USER_EVENT,
            ~eventName=SAMSUNG_PAY,
            (),
          )
          SamsungPayModule.presentSamsungPayPaymentSheet(confirmSamsungPay)
        }
      | _ => {
          logger(
            ~logType=DEBUG,
            ~value=paymentMethodData.payment_method_type,
            ~category=USER_EVENT,
            ~paymentMethod=paymentMethodData.payment_method_type,
            ~eventName=NO_WALLET_ERROR,
            ~paymentExperience=paymentMethodData.payment_experience,
            (),
          )
          setLoading(FillingDetails)
          showAlert(~errorType="warning", ~message="Waiting for Sessions API")
        }
      }
    } else if (
      paymentMethodData.payment_experience
      ->Array.find(exp => exp.payment_experience_type_decode == REDIRECT_TO_URL)
      ->Option.isSome
    ) {
      let redirectData = []->Dict.fromArray->JSON.Encode.object
      let payment_method_data = [
        (
          paymentMethodData.payment_method_str,
          [(paymentMethodData.payment_method_type ++ "_redirect", redirectData)]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]->Dict.fromArray

      processToken(payment_method_data)
    } else {
      logger(
        ~logType=DEBUG,
        ~value=paymentMethodData.payment_method_type,
        ~category=USER_EVENT,
        ~paymentMethod=paymentMethodData.payment_method_type,
        ~eventName=NO_WALLET_ERROR,
        ~paymentExperience=paymentMethodData.payment_experience,
        (),
      )
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment Method Unavailable")
    }
  }

  <>
    <CustomButton
      borderRadius=buttonBorderRadius
      linearGradientColorTuple=?{switch paymentMethodData.payment_method_type_wallet {
      | PAYPAL => Some(Some(paypalButonColor))
      | SAMSUNG_PAY => Some(Some(samsungPayButtonColor))
      | _ => None
      }}
      leftIcon=CustomIcon(<Icon name=paymentMethodData.payment_method_type width=24. height=32. />)
      onPress={_ => pressHandler()}
      name=paymentMethodData.payment_method_type>
      {switch paymentMethodData.payment_method_type_wallet {
      | SAMSUNG_PAY =>
        Some(
          <View
            style={s({
              display: #flex,
              flexDirection: #row,
              alignItems: #center,
              justifyContent: #center,
              width: 100.->pct,
              height: 100.->pct,
            })}>
            <Icon name=paymentMethodData.payment_method_type width=240. height=60. />
          </View>,
        )
      | APPLE_PAY =>
        Some(
          <ApplePayButtonView
            style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
            cornerRadius=buttonBorderRadius
            buttonType=nativeProp.configuration.appearance.applePay.buttonType
            buttonStyle=applePayButtonColor
          />,
        )
      | GOOGLE_PAY =>
        Some(
          <GooglePayButtonView
            allowedPaymentMethods={WalletType.getAllowedPaymentMethods(~obj=sessionObject)}
            style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
            buttonType=nativeProp.configuration.appearance.googlePay.buttonType
            buttonStyle=googlePayButtonColor
            borderRadius={buttonBorderRadius}
          />,
        )
      | PAYPAL =>
        Some(
          <View style={s({flexDirection: #row, alignItems: #center, justifyContent: #center})}>
            <Icon name=paymentMethodData.payment_method_type width=22. height=28. />
            <Space width=10. />
            <Icon name={paymentMethodData.payment_method_type ++ "2"} width=90. height=28. />
          </View>,
        )
      | _ => None
      }}
    </CustomButton>
    <Space height=12. />
  </>
}
