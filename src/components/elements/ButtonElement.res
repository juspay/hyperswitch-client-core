open ReactNative
open Style
open PaymentMethodListType

type item = {
  linearGradientColorTuple: option<ThemebasedStyle.buttonColorConfig>,
  name: string,
  iconName: string,
  iconNameRight: option<string>,
}

@react.component
let make = (
  ~walletType: PaymentMethodListType.payment_method_types_wallet,
  ~sessionObject,
  ~isWidget=false,
  ~confirm=false,
) => {
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (_, setPaymentScreenType) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let showAlert = AlertHook.useAlerts()

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (buttomFlex, _) = React.useState(_ => Animated.Value.create(1.))
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

  let logger = LoggerHook.useLoggerHook()
  let {
    paypalButonColor,
    googlePayButtonColor,
    applePayButtonColor,
    buttonBorderRadius,
    primaryButtonHeight,
    samsungPayButtonColor,
  } = ThemebasedStyle.useThemeBasedStyle()

  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  // let (show, setShow) = React.useState(_ => true)
  let animateFlex = (~flexval, ~value, ~endCallback=() => (), ()) => {
    Animated.timing(
      flexval,
      {
        toValue: {value->Animated.Value.Timing.fromRawValue},
        isInteraction: true,
        useNativeDriver: false,
        delay: 0.,
      },
    )->Animated.start(~endCallback=_ => {endCallback()})
  }

  let processRequest = (
    ~payment_method_data,
    ~walletTypeAlt=?,
    ~email=?,
    ~shipping=None,
    ~billing=None,
    (),
  ) => {
    let walletType = switch walletTypeAlt {
    | Some(wallet) => wallet
    | None => walletType
    }

    let errorCallback = (~errorMessage, ~closeSDK, ()) => {
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_FAILED,
        ~paymentMethod={walletType.payment_method_type},
        ~paymentExperience=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience =>
          getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
        ),
        (),
      )
      if !closeSDK {
        setLoading(FillingDetails)
      }
      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }
    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_DATA_FILLED,
        ~paymentMethod={walletType.payment_method_type},
        ~paymentExperience=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience =>
          getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
        ),
        (),
      )
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_ATTEMPT,
        ~paymentMethod=walletType.payment_method_type,
        ~paymentExperience=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience =>
          getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
        ),
        (),
      )
      switch paymentStatus {
      | PaymentSuccess => {
          logger(
            ~logType=INFO,
            ~value="",
            ~category=USER_EVENT,
            ~eventName=PAYMENT_SUCCESS,
            ~paymentMethod={walletType.payment_method_type},
            ~paymentExperience=?walletType.payment_experience
            ->Array.get(0)
            ->Option.map(paymentExperience =>
              getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
            ),
            (),
          )
          setLoading(PaymentSuccess)
          animateFlex(
            ~flexval=buttomFlex,
            ~value=0.01,
            ~endCallback=() => {
              setTimeout(() => {
                handleSuccessFailure(~apiResStatus=status, ())
              }, 600)->ignore
            },
            (),
          )
        }
      | _ => handleSuccessFailure(~apiResStatus=status, ())
      }
    }

    let body: redirectType = {
      client_secret: nativeProp.clientSecret,
      return_url: ?Utils.getReturnUrl(
        ~appId=nativeProp.hyperParams.appId,
        ~appURL=allApiData.additionalPMLData.redirect_url,
      ),
      ?email,
      // customer_id: ?switch nativeProp.configuration.customer {
      // | Some(customer) => customer.id
      // | None => None
      // },
      payment_method: walletType.payment_method,
      payment_method_type: walletType.payment_method_type,
      payment_experience: ?(
        walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.payment_experience_type)
      ),
      connector: ?(
        walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.eligible_connectors)
      ),
      payment_method_data,
      billing: ?billing->Option.orElse(nativeProp.configuration.defaultBillingDetails),
      shipping: ?shipping->Option.orElse(nativeProp.configuration.shippingDetails),
      payment_type: ?allApiData.additionalPMLData.paymentType,
      customer_acceptance: ?(
        if (
          allApiData.additionalPMLData.mandateType->PaymentUtils.checkIfMandate &&
            !savedPaymentMethodsData.isGuestCustomer
        ) {
          Some({
            acceptance_type: "online",
            accepted_at: Date.now()->Date.fromTime->Date.toISOString,
            online: {
              user_agent: ?nativeProp.hyperParams.userAgent,
            },
          })
        } else {
          None
        }
      ),
      browser_info: {
        user_agent: ?nativeProp.hyperParams.userAgent,
        device_model: ?nativeProp.hyperParams.device_model,
        os_type: ?nativeProp.hyperParams.os_type,
        os_version: ?nativeProp.hyperParams.os_version,
      },
    }

    fetchAndRedirect(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=walletType.payment_method_type,
      ~paymentExperience=?walletType.payment_experience
      ->Array.get(0)
      ->Option.map(paymentExperience =>
        getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
      ),
      (),
    )
  }

  let confirmPayPal = var => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.Encode.string
      let paymentData = [("token", json)]->Dict.fromArray->JSON.Encode.object
      let payment_method_data =
        [
          (
            walletType.payment_method,
            [(walletType.payment_method_type ++ "_sdk", paymentData)]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
      processRequest(~payment_method_data, ())
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

      let (
        hasMissingFields,
        updatedRequiredFields,
        paymentMethodData,
      ) = WalletType.getMissingFieldsAndPaymentMethodData(
        walletType.required_field,
        ~billingAddress,
        ~shippingAddress,
        ~email=paymentDataFromGPay.email,
        ~collectBillingDetailsFromWallets=allApiData.additionalPMLData.collectBillingDetailsFromWallets,
      )
      hasMissingFields && !isWidget
        ? {
            setPaymentScreenType(
              WALLET_MISSING_FIELDS(
                updatedRequiredFields,
                walletType,
                GooglePayData(paymentDataFromGPay),
              ),
            )
            setLoading(FillingDetails)
          }
        : {
            paymentMethodData->Dict.set(
              walletType.payment_method,
              [
                (
                  walletType.payment_method_type,
                  paymentDataFromGPay.paymentMethodData->Utils.getJsonObjectFromRecord,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            )
            processRequest(
              ~payment_method_data=paymentMethodData->JSON.Encode.object,
              ~email=?paymentDataFromGPay.email,
              ~shipping=shippingAddress,
              ~billing=billingAddress,
              (),
            )
          }
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

      let (
        hasMissingFields,
        updatedRequiredFields,
        paymentMethodData,
      ) = WalletType.getMissingFieldsAndPaymentMethodData(
        walletType.required_field,
        ~billingAddress,
        ~shippingAddress,
        ~collectBillingDetailsFromWallets=allApiData.additionalPMLData.collectBillingDetailsFromWallets,
      )

      hasMissingFields && !isWidget
        ? {
            setPaymentScreenType(
              WALLET_MISSING_FIELDS(
                updatedRequiredFields,
                walletType,
                SamsungPayData(samsungPayData, billingAddress, shippingAddress),
              ),
            )
            setLoading(FillingDetails)
          }
        : {
            paymentMethodData->Dict.set(
              walletType.payment_method,
              [(walletType.payment_method_type, samsungPayData->Utils.getJsonObjectFromRecord)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            )

            processRequest(
              ~payment_method_data=paymentMethodData->JSON.Encode.object,
              ~shipping=shippingAddress,
              ~billing=billingAddress,
              ~email=?billingAddress
              ->WalletType.getEmailAddress
              ->Option.orElse(shippingAddress->WalletType.getEmailAddress),
              (),
            )
          }
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
      ~value=walletType.payment_method_type,
      ~category=USER_EVENT,
      ~paymentMethod=walletType.payment_method_type,
      ~eventName=APPLE_PAY_CALLBACK_FROM_NATIVE,
      ~paymentExperience=?walletType.payment_experience
      ->Array.get(0)
      ->Option.map(paymentExperience =>
        getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
      ),
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

          let billingAddress = var->WalletType.getBillingContact("billing_contact")
          let shippingAddress = var->WalletType.getBillingContact("shipping_contact")

          let (
            hasMissingFields,
            updatedRequiredFields,
            paymentMethodData,
          ) = WalletType.getMissingFieldsAndPaymentMethodData(
            walletType.required_field,
            ~billingAddress,
            ~shippingAddress,
            ~collectBillingDetailsFromWallets=allApiData.additionalPMLData.collectBillingDetailsFromWallets,
          )

          hasMissingFields && !isWidget
            ? {
                let paymentDataFromApplePay = var->WalletType.applePayItemToObjMapper
                setPaymentScreenType(
                  WALLET_MISSING_FIELDS(
                    updatedRequiredFields,
                    walletType,
                    ApplePayData(paymentDataFromApplePay),
                  ),
                )
                setLoading(FillingDetails)
              }
            : {
                let paymentData =
                  [
                    ("payment_data", payment_data),
                    ("payment_method", payment_method),
                    ("transaction_identifier", transaction_identifier),
                  ]
                  ->Dict.fromArray
                  ->JSON.Encode.object

                paymentMethodData->Dict.set(
                  walletType.payment_method,
                  [(walletType.payment_method_type, paymentData)]
                  ->Dict.fromArray
                  ->JSON.Encode.object,
                )

                processRequest(
                  ~payment_method_data=paymentMethodData->JSON.Encode.object,
                  ~shipping=shippingAddress,
                  ~billing=billingAddress,
                  ~email=?billingAddress
                  ->WalletType.getEmailAddress
                  ->Option.orElse(shippingAddress->WalletType.getEmailAddress),
                  (),
                )
              }
        }
      }
    }
  }

  React.useEffect1(() => {
    switch walletType.payment_method_type_wallet {
    | APPLE_PAY => Window.registerEventListener("applePayData", confirmApplePay)
    | GOOGLE_PAY => Window.registerEventListener("googlePayData", confirmGPay)
    | _ => ()
    }

    None
  }, [walletType.payment_method_type_wallet])

  let pressHandler = () => {
    setLoading(ProcessingPayments(None))
    logger(
      ~logType=INFO,
      ~value=walletType.payment_method_type,
      ~category=USER_EVENT,
      ~paymentMethod=walletType.payment_method_type,
      ~eventName=PAYMENT_METHOD_CHANGED,
      ~paymentExperience=?walletType.payment_experience
      ->Array.get(0)
      ->Option.map(paymentExperience =>
        getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
      ),
      (),
    )
    setTimeout(_ => {
      if (
        walletType.payment_experience
        ->Array.find(exp => exp.payment_experience_type_decode == INVOKE_SDK_CLIENT)
        ->Option.isSome
      ) {
        switch walletType.payment_method_type_wallet {
        | GOOGLE_PAY =>
          HyperModule.launchGPay(
            WalletType.getGpayTokenStringified(
              ~obj=sessionObject,
              ~appEnv=nativeProp.env,
              ~requiredFields=walletType.required_field,
            ),
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
            walletType.payment_experience
            ->Array.find(exp => exp.payment_experience_type_decode == REDIRECT_TO_URL)
            ->Option.isSome
          ) {
            let redirectData = []->Dict.fromArray->JSON.Encode.object
            let payment_method_data =
              [
                (
                  walletType.payment_method,
                  [(walletType.payment_method_type ++ "_redirect", redirectData)]
                  ->Dict.fromArray
                  ->JSON.Encode.object,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object
            let altPaymentExperience =
              walletType.payment_experience->Array.find(x =>
                x.payment_experience_type_decode === REDIRECT_TO_URL
              )
            let walletTypeAlt = {
              ...walletType,
              payment_experience: [
                altPaymentExperience->Option.getOr({
                  payment_experience_type: "",
                  payment_experience_type_decode: NONE,
                  eligible_connectors: [],
                }),
              ],
            }
            // when session token for paypal is absent, switch to redirect flow
            processRequest(~payment_method_data, ~walletTypeAlt, ())
          } else {
            let redirectData = []->Dict.fromArray->JSON.Encode.object
            let payment_method_data =
              [
                (
                  walletType.payment_method,
                  [(walletType.payment_method_type ++ "_redirect", redirectData)]
                  ->Dict.fromArray
                  ->JSON.Encode.object,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object
            processRequest(~payment_method_data, ())
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
              ~value=walletType.payment_method_type,
              ~category=USER_EVENT,
              ~paymentMethod=walletType.payment_method_type,
              ~eventName=APPLE_PAY_STARTED_FROM_JS,
              ~paymentExperience=?walletType.payment_experience
              ->Array.get(0)
              ->Option.map(paymentExperience =>
                getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
              ),
              (),
            )

            let timerId = setTimeout(() => {
              setLoading(FillingDetails)
              showAlert(~errorType="warning", ~message="Apple Pay Error, Please try again")
              logger(
                ~logType=DEBUG,
                ~value=walletType.payment_method_type,
                ~category=USER_EVENT,
                ~paymentMethod=walletType.payment_method_type,
                ~eventName=APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
                ~paymentExperience=?walletType.payment_experience
                ->Array.get(0)
                ->Option.map(
                  paymentExperience =>
                    getPaymentExperienceType(paymentExperience.payment_experience_type_decode),
                ),
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
                  ~value=walletType.payment_method_type,
                  ~category=USER_EVENT,
                  ~paymentMethod=walletType.payment_method_type,
                  ~eventName=APPLE_PAY_BRIDGE_SUCCESS,
                  ~paymentExperience=?walletType.payment_experience
                  ->Array.get(0)
                  ->Option.map(paymentExperience =>
                    getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
                  ),
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
              ~value=walletType.payment_method_type,
              ~category=USER_EVENT,
              ~paymentMethod=walletType.payment_method_type,
              ~eventName=NO_WALLET_ERROR,
              ~paymentExperience=?walletType.payment_experience
              ->Array.get(0)
              ->Option.map(paymentExperience =>
                getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
              ),
              (),
            )
            setLoading(FillingDetails)
            showAlert(~errorType="warning", ~message="Waiting for Sessions API")
          }
        }
      } else if (
        walletType.payment_experience
        ->Array.find(exp => exp.payment_experience_type_decode == REDIRECT_TO_URL)
        ->Option.isSome
      ) {
        let redirectData = []->Dict.fromArray->JSON.Encode.object
        let payment_method_data =
          [
            (
              walletType.payment_method,
              [(walletType.payment_method_type ++ "_redirect", redirectData)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
        processRequest(~payment_method_data, ())
      } else {
        logger(
          ~logType=DEBUG,
          ~value=walletType.payment_method_type,
          ~category=USER_EVENT,
          ~paymentMethod=walletType.payment_method_type,
          ~eventName=NO_WALLET_ERROR,
          ~paymentExperience=?walletType.payment_experience
          ->Array.get(0)
          ->Option.map(paymentExperience =>
            getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
          ),
          (),
        )
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message="Payment Method Unavailable")
      }
    }, 1000)->ignore
  }

  React.useEffect1(_ => {
    if confirm {
      pressHandler()
    }
    None
  }, [confirm])
  <>
    <CustomButton
      borderRadius=buttonBorderRadius
      linearGradientColorTuple=?{switch walletType.payment_method_type_wallet {
      | PAYPAL => Some(Some(paypalButonColor))
      | SAMSUNG_PAY => Some(Some(samsungPayButtonColor))
      | _ => None
      }}
      leftIcon=CustomIcon(<Icon name=walletType.payment_method_type width=24. height=32. />)
      onPress={_ => pressHandler()}
      name=walletType.payment_method_type>
      {switch walletType.payment_method_type_wallet {
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
            <Icon name=walletType.payment_method_type width=240. height=60. />
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
            allowedPaymentMethods={WalletType.getAllowedPaymentMethods(
              ~obj=sessionObject,
              ~requiredFields=walletType.required_field,
            )}
            style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
            buttonType=nativeProp.configuration.appearance.googlePay.buttonType
            buttonStyle=googlePayButtonColor
            borderRadius={buttonBorderRadius}
          />,
        )
      | PAYPAL =>
        Some(
          <View style={s({flexDirection: #row, alignItems: #center, justifyContent: #center})}>
            <Icon name=walletType.payment_method_type width=22. height=28. />
            <Space width=10. />
            <Icon name={walletType.payment_method_type ++ "2"} width=90. height=28. />
          </View>,
        )
      | _ => None
      }}
    </CustomButton>
    <Space height=12. />
  </>
}
