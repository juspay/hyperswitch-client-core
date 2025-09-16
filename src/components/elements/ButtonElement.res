open ReactNative
open Style

@react.component
let make = (
  ~paymentMethodData: PaymentMethodListType.payment_method_type,
  ~sessionObject,
  ~processRequest,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
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

  let getSuperpositionFinalFields = ConfigurationService.useConfigurationService()

  let ((requiredFields, initialValues, walletDict, country), setWalletData) = React.useState(_ => (
    [],
    Dict.make(),
    Dict.make(),
    "US",
  ))

  let setWalletData = React.useCallback1((requiredFields, initialValues, walletDict, country) => {
    setWalletData(_ => (requiredFields, initialValues, walletDict, country))
  }, [setWalletData])

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let (formMethods: option<ReactFinalForm.Form.formMethods>, setFormMethods) = React.useState(_ =>
    None
  )

  let setFormData = React.useCallback1(data => {
    setFormData(_ => data)
  }, [setFormData])

  let setIsFormValid = React.useCallback1(isValid => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let setFormMethods = React.useCallback1(formSubmit => {
    setFormMethods(_ => formSubmit)
  }, [setFormMethods])

  let handlePressInternal = (walletDict) => {
    Console.log3(">>>>>>>>>>>>", isFormValid, requiredFields->Array.length)

    if isFormValid || requiredFields->Array.length === 0 {
      // let walletDict = [("payment_method_data", walletDict->Js.Json.object_)]->Dict.fromArray

      // let formDataDict = formData->Dict.get("payment_method_data")->Option.getOr(JSON.Null)->Utils.getDictFromJson

      Console.log2(">>>>>>>>>>>>", CommonUtils.mergeDict(walletDict, formData))
      processRequest(
        CommonUtils.mergeDict(walletDict, formData),
        formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
      )
    } else {
      switch formMethods {
      | Some(methods) => methods.submit()
      | None => ()
      }
    }
  }

  let handlePress = () => {
    handlePressInternal(walletDict)
  }

  let processWalletData = React.useCallback1(
    (walletDict, ~billingAddress: option<SdkTypes.addressDetails>=?, ~shippingAddress=?) => {
      if allApiData.additionalPMLData.collectBillingDetailsFromWallets {
        let eligibleConnectors = switch paymentMethodData.payment_method {
        | CARD =>
          paymentMethodData.card_networks
          ->Array.get(0)
          ->Option.mapOr([], network => network.eligible_connectors)
        | _ =>
          paymentMethodData.payment_experience
          ->Array.get(0)
          ->Option.mapOr([], experience => experience.eligible_connectors)
        }

        let country: string = switch billingAddress {
        | Some(billingAddress) =>
          switch billingAddress.address {
          | Some(address) => address.country
          | None => None
          }
        | None => None
        }->Option.getOr(nativeProp.hyperParams.country)

        let configParams: SuperpositionTypes.superpositionBaseContext = {
          payment_method: paymentMethodData.payment_method_str,
          payment_method_type: paymentMethodData.payment_method_type,
          mandate_type: allApiData.additionalPMLData.mandateType->JSON.stringifyAny,
          collect_billing_details_from_wallet_connector: allApiData.additionalPMLData.collectBillingDetailsFromWallets,
          collect_shipping_details_from_wallet_connector: allApiData.additionalPMLData.collectShippingDetailsFromWallets,
          country,
        }

        let (requiredFields, initialValues) = getSuperpositionFinalFields(
          eligibleConnectors,
          configParams,
          AddressUtils.getFlatAddressDict(~billingAddress, ~shippingAddress),
          false,
        )

        if requiredFields->Array.length === 0 {
          handlePressInternal(walletDict)
        } else {

        setWalletData(requiredFields, initialValues, walletDict, country)
        }
      } else {
        let eligibleConnectors = switch paymentMethodData.payment_method {
        | CARD =>
          paymentMethodData.card_networks
          ->Array.get(0)
          ->Option.mapOr([], network => network.eligible_connectors)
        | _ =>
          paymentMethodData.payment_experience
          ->Array.get(0)
          ->Option.mapOr([], experience => experience.eligible_connectors)
        }

        let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
          paymentMethodData.required_fields,
        )

        let country: string =
          requiredFieldsFromPML
          ->Dict.get("payment_method_data.billing.address.country")
          ->Option.getOr(nativeProp.hyperParams.country)

        let configParams: SuperpositionTypes.superpositionBaseContext = {
          payment_method: paymentMethodData.payment_method_str,
          payment_method_type: paymentMethodData.payment_method_type,
          mandate_type: allApiData.additionalPMLData.mandateType->JSON.stringifyAny,
          collect_billing_details_from_wallet_connector: allApiData.additionalPMLData.collectBillingDetailsFromWallets,
          collect_shipping_details_from_wallet_connector: allApiData.additionalPMLData.collectShippingDetailsFromWallets,
          country,
        }

        let (requiredFields, initialValues) = getSuperpositionFinalFields(
          eligibleConnectors,
          configParams,
          requiredFieldsFromPML,
          false,
        )

        Console.log2("requiredFields", requiredFields)

        if requiredFields->Array.length === 0 {
          handlePressInternal(walletDict)
        } else {

        setWalletData(requiredFields, initialValues, walletDict, country)
        }
      }
    },
    [paymentMethodData.payment_method_type],
  )

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
      processWalletData(payment_method_data)
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
      let billingAddress = switch paymentDataFromGPay.paymentMethodData.info {
      | Some(info) => info.billing_address
      | None => None
      }
      let shippingAddress = paymentDataFromGPay.shippingDetails

      let payment_method_data = [
        (
          paymentMethodData.payment_method_str,
          [
            (
              paymentMethodData.payment_method_type,
              paymentDataFromGPay.paymentMethodData->Utils.getJsonObjectFromRecord,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]->Dict.fromArray

      processWalletData(payment_method_data, ~billingAddress?, ~shippingAddress?)
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

      let billingAddress =
        addressFromSPay->SamsungPayType.getAddressObj(SamsungPayType.BILLING_ADDRESS)
      let shippingAddress =
        addressFromSPay->SamsungPayType.getAddressObj(SamsungPayType.SHIPPING_ADDRESS)
      let samsungPayData = SamsungPayType.itemToObjMapper(response)

      let payment_method_data = [
        (
          paymentMethodData.payment_method_str,
          [(paymentMethodData.payment_method_type, samsungPayData->Utils.getJsonObjectFromRecord)]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]->Dict.fromArray

      processWalletData(payment_method_data, ~billingAddress?, ~shippingAddress?)
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
          let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)
          let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)

          let billingAddress = var->AddressUtils.getApplePayBillingAddress("billing_contact")
          let shippingAddress = var->AddressUtils.getApplePayBillingAddress("shipping_contact")

          let paymentData =
            [
              ("payment_data", payment_data),
              ("payment_method", payment_method),
              ("transaction_identifier", transaction_identifier),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object

          let payment_method_data = [
            (
              paymentMethodData.payment_method_str,
              [(paymentMethodData.payment_method_type, paymentData)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]->Dict.fromArray

          processWalletData(payment_method_data, ~billingAddress?, ~shippingAddress?)
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

          processWalletData(payment_method_data)
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

      processWalletData(payment_method_data)
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
    <DynamicFields2
      fields=requiredFields
      initialValues
      setFormData
      setIsFormValid
      setFormMethods
      country
      handlePress
      showInSheet=true
    />
  </>
}
