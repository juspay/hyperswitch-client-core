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
  ~confirm=false,
) => {
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
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
    )->Animated.start(~endCallback=_ => {endCallback()}, ())
  }

  let processRequest = (~payment_method_data, ~walletTypeAlt=?, ~email=?, ()) => {
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
      return_url: ?Utils.getReturnUrl(nativeProp.hyperParams.appId),
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
      billing: ?nativeProp.configuration.defaultBillingDetails,
      shipping: ?nativeProp.configuration.shippingDetails,
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
              ip_address: ?nativeProp.hyperParams.ip,
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

  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)

  let confirmGPay = var => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let obj =
        json
        ->Utils.getDictFromJson
        ->GooglePayTypeNew.itemToObjMapper(
          switch countryStateData {
          | FetchData(data)
          | Localdata(data) =>
            data.states
          | _ => Dict.make()
          },
        )
      let payment_method_data =
        [
          (
            walletType.payment_method,
            [(walletType.payment_method_type, obj.paymentMethodData->Utils.getJsonObjectFromRecord)]
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
      processRequest(~payment_method_data, ~email=?obj.email, ())
    | "Cancel" =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | err =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message=err)
    }
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
    | _ =>
      let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)

      let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)

      Console.log2(
        "APPLEPAY",
        // var,
        walletType,
        // walletType.required_field->Array.map(required_fields_type =>
        //   required_fields_type.required_field
        // ),
      )
      let billing_contact = var->GooglePayTypeNew.getBillingContact(
        "billing_contact",
        switch countryStateData {
        | FetchData(data)
        | Localdata(data) =>
          data.states
        | _ => Dict.make()
        },
      )
      let shipping_contact = var->Dict.get("shipping_contact")->Option.getOr(JSON.Encode.null)
      Console.log4("billing", billing_contact, "shipping", shipping_contact)
      let transaction_identifier =
        var->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null)

      if transaction_identifier == "Simulated Identifier"->JSON.Encode.string {
        setTimeout(() => {
          setLoading(FillingDetails)
          showAlert(
            ~errorType="warning",
            ~message="Apple Pay is not supported in Simulated Environment",
          )
        }, 2000)->ignore
      } else {
        // let finalJson = getPaymentBody(
        //   var,
        //   walletType.required_field
        //   ->Array.map(required_fields_type => required_fields_type.required_field)
        //   ->Dict.toArray
        //   ->Array.map(((key, (value, error))) => (key, value, error)),
        // )

        let paymentData =
          [
            ("payment_data", payment_data),
            ("payment_method", payment_method),
            ("transaction_identifier", transaction_identifier),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        let payment_method_data =
          [
            (
              walletType.payment_method,
              [(walletType.payment_method_type, paymentData)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
            (
              "billing",
              switch var->GooglePayTypeNew.getBillingContact(
                "billing_contact",
                switch countryStateData {
                | FetchData(data)
                | Localdata(data) =>
                  data.states
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

        // let billing_contact = var->Dict.get("billing_contact")->Option.getOr(JSON.Encode.null)

        let billing_contact = var->GooglePayTypeNew.getBillingContact(
          "billing_contact",
          switch countryStateData {
          | FetchData(data)
          | Localdata(data) =>
            data.states
          | _ => Dict.make()
          },
        )
        let shipping_contact = var->GooglePayTypeNew.getBillingContact(
          "shipping_contact",
          switch countryStateData {
          | FetchData(data)
          | Localdata(data) =>
            data.states
          | _ => Dict.make()
          },
        )

        Console.log4("billing", billing_contact, "shipping", shipping_contact)
        // let billing_name = billing_contact->Dict.get("name")->Option.getOr(Dict.make())
        // let first_name =
        //   billing_name
        //   ->Dict.get("givenName")
        //   ->Option.getOr(JSON.Encode.string(""))
        //   ->JSON.Decode.string
        //   ->Option.getOr("")
        // let last_name =
        // billing_name
        // ->Dict.get("familyName")
        // ->Option.getOr(JSON.Encode.string(""))
        // ->JSON.Decode.string
        // ->Option.getOr("")

        // // Extract address information
        // // let postal_address = billing_contact->Dict.get("postalAddress")->Option.getOr(Dict.make())
        // // let street =
        // //   postal_address
        // //   ->Dict.get("street")
        // //   ->Option.getOr(JSON.Encode.string(""))
        // //   ->JSON.Decode.string
        // //   ->Option.getOr("")
        // // let city =
        // //   postal_address
        // //   ->Dict.get("city")
        // //   ->Option.getOr(JSON.Encode.string(""))
        // //   ->JSON.Decode.string
        // //   ->Option.getOr("")
        // // let country =
        // //   postal_address
        // //   ->Dict.get("country")
        // //   ->Option.getOr(JSON.Encode.string(""))
        // //   ->JSON.Decode.string
        // //   ->Option.getOr("")
        // // let state =
        // //   postal_address
        // //   ->Dict.get("state")
        // //   ->Option.getOr(JSON.Encode.string(""))
        // //   ->JSON.Decode.string
        // //   ->Option.getOr("")
        // // let postal_code =
        // //   postal_address
        // //   ->Dict.get("postalCode")
        // //   ->Option.getOr(JSON.Encode.string(""))
        // //   ->JSON.Decode.string
        // //   ->Option.getOr("")
        // // let iso_country_code =
        // // postal_address
        // // ->Dict.get("isoCountryCode")
        // // ->Option.getOr(JSON.Encode.string(""))
        // // ->JSON.Decode.string
        // // ->Option.getOr("")

        // // Extract contact information
        // let email =
        //   shipping_contact
        //   ->Dict.get("emailAddress")
        //   ->Option.getOr(JSON.Encode.string(""))
        //   ->JSON.Decode.string
        //   ->Option.getOr("")
        // let phone_number =
        //   shipping_contact
        //   ->Dict.get("phoneNumber")
        //   ->Option.getOr(JSON.Encode.string(""))
        //   ->JSON.Decode.string
        //   ->Option.getOr("")
        // let country_code = iso_country_code == "IN" ? "+91" : ""

        // // Create data objects
        // let address = Dict.make()
        // let phone = Dict.make()
        // let billing = Dict.make()
        // let pmData = Dict.make()

        // // Check each required field and populate accordingly
        // walletType.required_field->Array.forEach(field => {
        //   switch field["TAG"] {
        //   | "StringField" => {
        //       let path = field["_0"]
        //       switch path {
        //       | "payment_method_data.billing.phone.number" =>
        //         phone->Dict.set("number", JSON.Encode.string(phone_number))
        //       | "payment_method_data.billing.phone.country_code" =>
        //         phone->Dict.set("country_code", JSON.Encode.string(country_code))
        //       | "payment_method_data.billing.email" =>
        //         billing->Dict.set("email", JSON.Encode.string(email))
        //       | "payment_method_data.billing.address.line1" =>
        //         address->Dict.set("line1", JSON.Encode.string(street))
        //       | "payment_method_data.billing.address.line2" =>
        //         address->Dict.set("line2", JSON.Encode.string(""))
        //       | "payment_method_data.billing.address.city" =>
        //         address->Dict.set("city", JSON.Encode.string(city))
        //       | "payment_method_data.billing.address.country" =>
        //         address->Dict.set("country", JSON.Encode.string(country))
        //       | "payment_method_data.billing.address.state" =>
        //         address->Dict.set("state", JSON.Encode.string(state))
        //       | "payment_method_data.billing.address.zip" =>
        //         address->Dict.set("zip", JSON.Encode.string(postal_code))
        //       | _ => ()
        //       }
        //     }
        //   | "FullNameField" => {
        //       // Set name fields - typically first and last name
        //       address->Dict.set("first_name", JSON.Encode.string(first_name))
        //       address->Dict.set("last_name", JSON.Encode.string(last_name))
        //     }
        //   | _ => ()
        //   }
        // })

        // // Assemble the structure
        // // Only add filled objects
        // if phone->Dict.keysToArray->Array.length > 0 {
        //   billing->Dict.set("phone", phone->JSON.Encode.object)
        // }

        // if address->Dict.keysToArray->Array.length > 0 {
        //   billing->Dict.set("address", address->JSON.Encode.object)
        // }

        // pmData->Dict.set("billing", billing->JSON.Encode.object)

        // // Final result
        // let payment_method_data = pmData->JSON.Encode.object

        // // Use the mapped data
        // setPaymentMethodData(payment_method_data)
        // setLoading(FillingDetails)

        // // Continue with payment processing
        // handlePaymentMethodData(payment_method_data)

        processRequest(
          ~payment_method_data,
          ~email=?switch var->GooglePayTypeNew.getBillingContact(
            "shipping_contact",
            switch countryStateData {
            | FetchData(data)
            | Localdata(data) =>
              data.states
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
            GooglePayTypeNew.getGpayTokenStringified(
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
      | _ => None
      }}
      leftIcon=CustomIcon(<Icon name=walletType.payment_method_type width=24. height=32. />)
      onPress={_ => pressHandler()}
      name=walletType.payment_method_type>
      {switch walletType.payment_method_type_wallet {
      | APPLE_PAY =>
        Some(
          <ApplePayButtonView
            style={viewStyle(~height=primaryButtonHeight->dp, ~width=100.->pct, ())}
            cornerRadius=buttonBorderRadius
            buttonType=nativeProp.configuration.appearance.applePay.buttonType
            buttonStyle=applePayButtonColor
          />,
        )
      | GOOGLE_PAY =>
        Some(
          <GooglePayButtonView
            allowedPaymentMethods={GooglePayTypeNew.getAllowedPaymentMethods(
              ~obj=sessionObject,
              ~requiredFields=walletType.required_field,
            )}
            style={viewStyle(~height=primaryButtonHeight->dp, ~width=100.->pct, ())}
            buttonType=nativeProp.configuration.appearance.googlePay.buttonType
            buttonStyle=googlePayButtonColor
            borderRadius={buttonBorderRadius}
          />,
        )
      | PAYPAL =>
        Some(
          <View
            style={viewStyle(
              ~flexDirection=#row,
              ~alignItems=#center,
              ~justifyContent=#center,
              (),
            )}>
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
