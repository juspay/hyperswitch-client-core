open ReactNative
open PaymentMethodListType
open CustomPicker

type klarnaSessionCheck = {
  isKlarna: bool,
  session_token: string,
}

@react.component
let make = (
  ~redirectProp: payment_method,
  ~fields: Types.redirectTypeJson,
  ~isScreenFocus,
  ~setConfirmButtonDataRef: React.element => unit,
  ~sessionObject: SessionsType.sessions=SessionsType.defaultToken,
) => {
  let walletType: PaymentMethodListType.payment_method_types_wallet = switch redirectProp {
  | WALLET(walletVal) => walletVal
  | _ => {
      payment_method: "",
      payment_method_type: "",
      payment_method_type_wallet: NONE,
      payment_experience: [],
      required_field: [],
    }
  }
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (launchKlarna, setLaunchKlarna) = React.useState(_ => None)
  let (email, setEmail) = React.useState(_ => None)
  let (isEmailValid, setIsEmailValid) = React.useState(_ => None)
  let (emailIsFocus, setEmailIsFocus) = React.useState(_ => false)
  let (phone, setphone) = React.useState(_ => None)
  let (accountnum, setaccountnum) = React.useState(_ => None)
  let (isaccountnumValid, setisaccountnumValid) = React.useState(_ => None)
  let (accountnumbecs, setaccountnumbecs) = React.useState(_ => None)
  let (isaccountnumbecsValid, setisaccountnumbecsValid) = React.useState(_ => None)
  let (line1, setLine1) = React.useState(() => None)
  let (zip, setZip) = React.useState(() => None)
  let (routingnum, setroutingnum) = React.useState(_ => None)
  let (isroutingnumValid, setisroutingnumValid) = React.useState(_ => None)
  let (address, setaddress) = React.useState(_ => None)
  let (address2, setaddress2) = React.useState(_ => None)
  let (isAddressValid, setIsAddressValid) = React.useState(_ => None)
  let (isAddress2Valid, setIsAddress2Valid) = React.useState(_ => None)
  let (account, setaccount) = React.useState(_ => None)
  let (isNicknameSelected, setIsNicknameSelected) = React.useState(_ => false)
  let (state, setState) = React.useState(_ => Some(nativeProp.hyperParams.state))
  let (postalCode, setpostalCode) = React.useState(_ => None)
  let (city, setcity) = React.useState(_ => None)
  let (iscityValid, setIscityValid) = React.useState(_ => None)
  let (statesJson, setStatesJson) = React.useState(_ => None)
  let (bsbnum, setbsbnum) = React.useState(_ => None)
  let (isbsbnumValid, setisbsbnumValid) = React.useState(_ => None)
  let (iban, setiban) = React.useState(_ => None)
  let (sortCode, setsortCode) = React.useState(_ => None)
  //let (AddressIsFocus, setAddressIsFocus) = React.useState(_ => false)

  let (name, setName) = React.useState(_ => None)
  let (isNameValid, setIsNameValid) = React.useState(_ => None)
  let (nameIsFocus, setNameIsFocus) = React.useState(_ => false)

  let (country, setCountry) = React.useState(_ => Some(nativeProp.hyperParams.country))

  let (blikCode, setBlikCode) = React.useState(_ => None)
  let showAlert = AlertHook.useAlerts()

  let bankName = switch redirectProp {
  | BANK_REDIRECT(prop) => prop.bank_names
  | _ => []
  }

  let getBankNames = bankNames => {
    bankNames
    ->Array.map(x => {
      x.bank_name
    })
    ->Array.reduce([], (acc, item) => {
      acc->Array.concat(item)
    })
    ->Array.map(x => {
      x->JSON.parseExn->JSON.Decode.string->Option.getOr("")
    })
  }
  let paymentMethod = switch redirectProp {
  | CARD(prop) => prop.payment_method_type
  | WALLET(prop) => prop.payment_method_type
  | PAY_LATER(prop) => prop.payment_method_type
  | BANK_REDIRECT(prop) => prop.payment_method_type
  | CRYPTO(prop) => prop.payment_method_type
  | OPEN_BANKING(prop) => prop.payment_method_type
  | BANK_DEBIT(prop) => prop.payment_method_type
  | BECS_DEBIT(prop) => prop.payment_method_type
  | SEPA_DEBIT(prop) => prop.payment_method_type
  | BACS_DEBIT(prop) => prop.payment_method_type
  }
  let paymentExperience = switch redirectProp {
  | CARD(_) => None
  | WALLET(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)

  | PAY_LATER(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)

  | BANK_REDIRECT(_) => None
  | OPEN_BANKING(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  | CRYPTO(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  | BANK_DEBIT(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  | BECS_DEBIT(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  | SEPA_DEBIT(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  | BACS_DEBIT(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  }
  let paymentMethodType = switch redirectProp {
  | BANK_REDIRECT(prop) => prop.payment_method_type
  | _ => ""
  }
  let bankList = switch paymentMethodType {
  | "ideal" => getBankNames(bankName)->Js.Array.sortInPlace
  | "eps" => getBankNames(bankName)->Js.Array.sortInPlace
  | _ => []
  }

  let bankItems = Bank.bankNameConverter(bankList)

  let bankData: array<customPickerType> = bankItems->Array.map(item => {
    {
      name: item.displayName,
      value: item.hyperSwitch,
    }
  })

  let countryData: array<customPickerType> = Country.country->Array.map(item => {
    {
      name: item.countryName,
      value: item.isoAlpha2,
      icon: Utils.getCountryFlags(item.isoAlpha2),
    }
  })

  let (selectedBank, setSelectedBank) = React.useState(_ => Some(
    switch bankItems->Array.get(0) {
    | Some(x) => x.hyperSwitch
    | _ => ""
    },
  ))

  let logger = LoggerHook.useLoggerHook()

  let onChangeCountry = val => {
    setCountry(val)
    logger(
      ~logType=INFO,
      ~value=country->Option.getOr(""),
      ~category=USER_EVENT,
      ~eventName=COUNTRY_CHANGED,
      ~paymentMethod,
      ~paymentExperience?,
      (),
    )
  }

  let onChangeBank = val => {
    setSelectedBank(val)
  }

  let onChangeBlikCode = (val: string) => {
    let onlyNumerics = val->String.replaceRegExp(%re("/\D+/g"), "")
    let firstPart = onlyNumerics->String.slice(~start=0, ~end=3)
    let secondPart = onlyNumerics->String.slice(~start=3, ~end=6)

    let finalVal = if onlyNumerics->String.length <= 3 {
      firstPart
    } else if onlyNumerics->String.length > 3 && onlyNumerics->String.length <= 6 {
      `${firstPart}-${secondPart}`
    } else {
      onlyNumerics
    }
    setBlikCode(_ => Some(finalVal))
  }

  let onChangebsbnum = number => {
    let onlyNumerics = number->String.replaceRegExp(%re("/\D+/g"), "")
    let y = if number->String.length === 6 {
      Some(true)
    } else {
      None
    }
    setisbsbnumValid(_ => y)
    setbsbnum(_ => Some(onlyNumerics))
  }
  let onChangeiban = (val: string) => {
    setiban(_ => Some(val))
  }
  let onChangeSortCode = (val: string) => {
    let onlyNumerics = val->String.replaceRegExp(%re("/\D+/g"), "")
    setsortCode(_ => Some(onlyNumerics))
  }
  let onChangePhoneNum = (val: string) => {
    let onlyNumerics = val->String.replaceRegExp(%re("/\D+/g"), "")
    setphone(_ => Some(onlyNumerics))
  }
  let onChangePostalCode = (val: string) => {
    let onlyNumerics = val->String.replaceRegExp(%re("/\D+/g"), "")
    setpostalCode(_ => Some(onlyNumerics))
  }

  let (error, setError) = React.useState(_ => None)

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let localeObject = GetLocale.useGetLocalObj()
  let {component, borderWidth, borderRadius} = ThemebasedStyle.useThemeBasedStyle()

  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let {isKlarna, session_token} = React.useMemo1(() => {
    switch allApiData.sessions {
    | Some(sessionData) =>
      switch sessionData->Array.find(item => item.wallet_name == KLARNA) {
      | Some(tok) => {isKlarna: tok.wallet_name === KLARNA, session_token: tok.session_token}
      | None => {isKlarna: false, session_token: ""}
      }
    | _ => {isKlarna: false, session_token: ""}
    }
  }, [allApiData.sessions])

  let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
    if !closeSDK {
      setLoading(FillingDetails)
      switch errorMessage.message {
      | Some(message) => setError(_ => Some(message))
      | None => ()
      }
    }
    handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
  }
  let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
    switch paymentStatus {
    | PaymentSuccess => {
        setLoading(PaymentSuccess)
        setTimeout(() => {
          handleSuccessFailure(~apiResStatus=status, ())
        }, 300)->ignore
      }
    | _ => handleSuccessFailure(~apiResStatus=status, ())
    }
    /* setLoading(PaymentSuccess)
    animateFlex(
      ~flexval=buttomFlex,
      ~value=0.01,
      ~endCallback=() => {
        setTimeout(() => {
          handleSuccessFailure(~apiResStatus=status, ())
        }, 300)->ignore
      },
      (),
    ) */
  }

  let processRequest = (
    ~payment_method_data,
    ~payment_method,
    ~payment_method_type,
    ~payment_experience_type="redirect_to_url",
    ~eligible_connectors=?,
    (),
  ) => {
    let body: redirectType = {
      client_secret: nativeProp.clientSecret,
      return_url: ?Utils.getReturnUrl(nativeProp.hyperParams.appId),
      payment_method,
      payment_method_type,
      payment_experience: payment_experience_type,
      connector: ?eligible_connectors,
      payment_method_data,
      billing: ?nativeProp.configuration.defaultBillingDetails,
      shipping: ?nativeProp.configuration.shippingDetails,
      setup_future_usage: ?(
        allApiData.additionalPMLData.mandateType == NORMAL ? Some("off_session") : None
      ),
      payment_type: ?allApiData.additionalPMLData.paymentType,
      mandate_data: ?(
        allApiData.additionalPMLData.mandateType == NORMAL
          ? Some({
              customer_acceptance: {
                acceptance_type: "offline",
                accepted_at: "1963-05-03T04:07:52.723Z",
                online: {
                  ip_address: "125.0.0.1",
                  user_agent: "amet irure esse",
                },
              },
              mandate_type: {
                multi_use: {
                  amount: 1000,
                  currency: "USD",
                  start_date: "2023-04-21T00:00:00Z",
                  end_date: "2023-05-21T00:00:00Z",
                  metadata: {
                    frequency: "13",
                  },
                },
              },
            })
          : None
      ),
      customer_acceptance: ?(
        allApiData.additionalPMLData.mandateType->PaymentUtils.checkIfMandate
          ? Some({
              acceptance_type: "online",
              accepted_at: Date.now()->Date.fromTime->Date.toISOString,
              online: {
                ip_address: ?nativeProp.hyperParams.ip,
                user_agent: ?nativeProp.hyperParams.userAgent,
              },
            })
          : None
      ),
      browser_info: {
        user_agent: ?nativeProp.hyperParams.userAgent,
        language: ?nativeProp.configuration.appearance.locale,
        // TODO: Remove these hardcoded values and get actual values from web-view (iOS and android)
        // accept_header: "",
        // color_depth: 0,
        // java_enabled: true,
        // java_script_enabled: true,
        // screen_height: 932,
        // screen_width: 430,
        // time_zone: -330,
      },
    }

    fetchAndRedirect(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod,
      ~paymentExperience?,
      (),
    )
  }

  let processRequestPayLater = (prop: payment_method_types_pay_later, authToken) => {
    let payment_experience_type_decode =
      authToken == "redirect" ? REDIRECT_TO_URL : INVOKE_SDK_CLIENT
    switch prop.payment_experience->Array.find(exp =>
      exp.payment_experience_type_decode === payment_experience_type_decode
    ) {
    | Some(exp) =>
      let redirectData =
        [
          ("billing_email", email->Option.getOr("")->JSON.Encode.string),
          ("billing_name", name->Option.getOr("")->JSON.Encode.string),
          ("billing_country", country->Option.getOr("")->JSON.Encode.string),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
      let sdkData = [("token", authToken->JSON.Encode.string)]->Dict.fromArray->JSON.Encode.object
      let payment_method_data =
        [
          (
            prop.payment_method,
            [
              (
                prop.payment_method_type ++ (authToken == "redirect" ? "_redirect" : "_sdk"),
                authToken == "redirect" ? redirectData : sdkData,
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object

      processRequest(
        ~payment_method_data,
        ~payment_method=prop.payment_method,
        ~payment_method_type=prop.payment_method_type,
        ~payment_experience_type=exp.payment_experience_type,
        (),
      )
    | None =>
      logger(
        ~logType=DEBUG,
        ~value=walletType.payment_method_type,
        ~category=USER_EVENT,
        ~paymentMethod=walletType.payment_method_type,
        ~eventName=NO_WALLET_ERROR,
        ~paymentExperience=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode),
        (),
      )
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment Method Unavailable")
    }
  }

  let processRequestBankRedirect = (prop: payment_method_types_bank_redirect) => {
    let payment_method_data =
      [
        (
          prop.payment_method,
          [
            (
              prop.payment_method_type,
              [
                (
                  "country",
                  switch country {
                  | Some(country) => country != "" ? country->JSON.Encode.string : JSON.Encode.null
                  | _ => JSON.Encode.null
                  },
                ),
                ("bank_name", selectedBank->Option.getOr("")->JSON.Encode.string),
                (
                  "blik_code",
                  blikCode->Option.getOr("")->String.replace("-", "")->JSON.Encode.string,
                ),
                ("preferred_language", "en"->JSON.Encode.string),
                (
                  "billing_details",
                  [("billing_name", name->Option.getOr("")->JSON.Encode.string)]
                  ->Dict.fromArray
                  ->JSON.Encode.object,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object

    processRequest(
      ~payment_method_data,
      ~payment_method=prop.payment_method,
      ~payment_method_type=prop.payment_method_type,
      (),
    )
  }

  let processRequestCrypto = (prop: payment_method_types_pay_later) => {
    let payment_method_data =
      [(prop.payment_method, []->Dict.fromArray->JSON.Encode.object)]
      ->Dict.fromArray
      ->JSON.Encode.object
    processRequest(
      ~payment_method_data,
      ~payment_method=prop.payment_method,
      ~payment_method_type=prop.payment_method_type,
      ~eligible_connectors=?prop.payment_experience
      ->Array.get(0)
      ->Option.map(paymentExperience => paymentExperience.eligible_connectors),
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
      processRequest(
        ~payment_method=walletType.payment_method,
        ~payment_method_data,
        ~payment_method_type=paymentMethod,
        ~payment_experience_type=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.payment_experience_type),
        ~eligible_connectors=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.eligible_connectors),
        (),
      )
    | "User has canceled" =>
      setLoading(FillingDetails)
      setError(_ => Some("Payment was Cancelled"))
    | err => setError(_ => Some(err))
    }
  }

  let (statesJson, setStatesJson) = React.useState(_ => None)

  React.useEffect0(() => {
    // Dynamically import/download Postal codes and states JSON
    RequiredFieldsTypes.importStates("./../../utility/reusableCodeFromWeb/States.json")
    ->Promise.then(res => {
      setStatesJson(_ => Some(res.states))
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      setStatesJson(_ => None)
      Promise.resolve()
    })
    ->ignore

    None
  })

  let confirmGPay = var => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let obj = json->Utils.getDictFromJson->GooglePayTypeNew.itemToObjMapper(statesJson)
      let payment_method_data =
        [
          (
            walletType.payment_method,
            [(walletType.payment_method_type, obj.paymentMethodData->Utils.getJsonObjectFromRecord)]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
      processRequest(
        ~payment_method=walletType.payment_method,
        ~payment_method_data,
        ~payment_method_type=paymentMethod,
        ~payment_experience_type=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.payment_experience_type),
        ~eligible_connectors=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.eligible_connectors),
        (),
      )
    | "Cancel" =>
      setLoading(FillingDetails)
      setError(_ => Some("Payment was Cancelled"))
    | err =>
      setLoading(FillingDetails)
      setError(_ => Some(err))
    }
  }

  let confirmApplePay = var => {
    switch var
    ->Dict.get("status")
    ->Option.getOr(JSON.Encode.null)
    ->JSON.Decode.string
    ->Option.getOr("") {
    | "Cancelled" =>
      setLoading(FillingDetails)
      setError(_ => Some("Cancelled"))
    | "Failed" =>
      setLoading(FillingDetails)
      setError(_ => Some("Failed"))
    | "Error" =>
      setLoading(FillingDetails)
      setError(_ => Some("Error"))
    | _ =>
      let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)

      let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)

      let transaction_identifier =
        var->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null)

      if transaction_identifier->JSON.stringify == "Simulated Identifier" {
        setLoading(FillingDetails)
        setError(_ => Some("Apple Pay is not supported in Simulated Environment"))
      } else {
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
              [(walletType.payment_method_type, paymentData)]->Dict.fromArray->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        processRequest(
          ~payment_method=walletType.payment_method,
          ~payment_method_data,
          ~payment_method_type=paymentMethod,
          ~payment_experience_type=?walletType.payment_experience
          ->Array.get(0)
          ->Option.map(paymentExperience => paymentExperience.payment_experience_type),
          ~eligible_connectors=?walletType.payment_experience
          ->Array.get(0)
          ->Option.map(paymentExperience => paymentExperience.eligible_connectors),
          (),
        )
      }
    }
  }

  let processRequestWallet = (walletType: payment_method_types_wallet) => {
    // let payment_method_data =
    //   [
    //     (
    //       prop.payment_method,
    //       [
    //         (
    //           prop.payment_method_type ++ "_redirect",
    //           [
    //             //Telephone number is for MB Way
    //             // (
    //             //   "telephone_number",
    //             //   phoneNumber
    //             //   ->Option.getOr("")
    //             //   ->String.replaceString(" ", "")
    //             //   ->JSON.Encode.string,
    //             // ),
    //           ]
    //           ->Dict.fromArray
    //           ->JSON.Encode.object,
    //         ),
    //       ]
    //       ->Dict.fromArray
    //       ->JSON.Encode.object,
    //     ),
    //   ]
    //   ->Dict.fromArray
    //   ->JSON.Encode.object

    // processRequest(
    //   ~payment_method_data,
    //   ~payment_method=prop.payment_method,
    //   ~payment_method_type=prop.payment_method_type,
    //   // connector: prop.bank_namesArray.get(0).eligible_connectors,
    //   // setup_future_usage:"off_session",
    //   (),
    // )

    setLoading(ProcessingPayments(None))
    logger(
      ~logType=INFO,
      ~value=walletType.payment_method_type,
      ~category=USER_EVENT,
      ~paymentMethod=walletType.payment_method_type,
      ~eventName=PAYMENT_METHOD_CHANGED,
      ~paymentExperience=?walletType.payment_experience
      ->Array.get(0)
      ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode),
      (),
    )
    if (
      walletType.payment_experience
      ->Array.find(exp => exp.payment_experience_type_decode == INVOKE_SDK_CLIENT)
      ->Option.isSome
    ) {
      switch walletType.payment_method_type_wallet {
      | GOOGLE_PAY =>
        HyperModule.launchGPay(
          GooglePayTypeNew.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
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
          processRequest(
            ~payment_method=walletType.payment_method,
            ~payment_method_data,
            ~payment_method_type=paymentMethod,
            ~payment_experience_type=?walletTypeAlt.payment_experience
            ->Array.get(0)
            ->Option.map(paymentExperience => paymentExperience.payment_experience_type),
            ~eligible_connectors=?walletTypeAlt.payment_experience
            ->Array.get(0)
            ->Option.map(paymentExperience => paymentExperience.eligible_connectors),
            (),
          )
        }
      | APPLE_PAY =>
        if (
          sessionObject.session_token_data == JSON.Encode.null ||
            sessionObject.payment_request_data == JSON.Encode.null
        ) {
          setLoading(FillingDetails)
          setError(_ => Some("Waiting for Sessions API"))
        } else {
          let timerId = setTimeout(() => {
            setLoading(FillingDetails)
            setError(_ => Some("Apple Pay Error, Please try again"))
            logger(
              ~logType=DEBUG,
              ~value="apple_pay",
              ~category=USER_EVENT,
              ~paymentMethod="apple_pay",
              ~eventName=APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
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
                ~value="apple_pay",
                ~category=USER_EVENT,
                ~paymentMethod="apple_pay",
                ~eventName=APPLE_PAY_BRIDGE_SUCCESS,
                (),
              )
            },
            _ => {
              clearTimeout(timerId)
            },
          )
        }
      | _ => setLoading(FillingDetails)
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
      processRequest(
        ~payment_method=walletType.payment_method,
        ~payment_method_data,
        ~payment_method_type=paymentMethod,
        (),
      )
    } else {
      logger(
        ~logType=DEBUG,
        ~value=walletType.payment_method_type,
        ~category=USER_EVENT,
        ~paymentMethod=walletType.payment_method_type,
        ~eventName=NO_WALLET_ERROR,
        ~paymentExperience=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode),
        (),
      )
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment Method Unavailable")
    }
  }

  let processRequestOpenBanking = (prop: payment_method_types_open_banking) => {
    let payment_method_data =
      [
        (
          prop.payment_method,
          [
            (
              prop.payment_method_type,
              []
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object

    processRequest(
      ~payment_method_data,
      ~payment_method=prop.payment_method,
      ~payment_method_type=prop.payment_method_type,
      (),
    )
  }

  let processRequestBankDebit = (payment_method: string, payment_method_type: string) => {
    let redirectData =
      [
        ("account_number", accountnum->Option.getOr("")->JSON.Encode.string),
        ("routing_number", routingnum->Option.getOr("")->JSON.Encode.string),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object
    let payment_method_data =
      [
        (
          payment_method,
          [
            (
              "ach_bank_debit",
              [
                ("account_number", accountnum->Option.getOr("")->JSON.Encode.string),
                ("routing_number", routingnum->Option.getOr("")->JSON.Encode.string),
                ("ach" ++ "_redirect", redirectData),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
        (
          "billing",
          [
            (
              "address",
              [
                (
                  "first_name",
                  switch name {
                  | Some(text) => text->String.split(" ")->Array.get(0)
                  | _ => Some("")
                  }
                  ->Option.getOr("")
                  ->JSON.Encode.string,
                ),
                (
                  "last_name",
                  switch name {
                  | Some(text) => text->String.split(" ")->Array.get(1)
                  | _ => Some("")
                  }
                  ->Option.getOr("")
                  ->JSON.Encode.string,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object

    Console.log4("ACh", paymentMethodType, paymentMethod, payment_method_data)
    processRequest(~payment_method_data, ~payment_method, ~payment_method_type, ())
  }
  let processRequestBecsDebit = (payment_method: string, payment_method_type: string) => {
    let payment_method_data =
      [
        (
          payment_method,
          [
            (
              "becs_bank_debit",
              [
                ("account_number", accountnum->Option.getOr("")->JSON.Encode.string),
                ("bsb_number", bsbnum->Option.getOr("")->JSON.Encode.string),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
        (
          "billing",
          [
            (
              "address",
              [
                (
                  "first_name",
                  switch name {
                  | Some(text) => text->String.split(" ")->Array.get(0)
                  | _ => Some("")
                  }
                  ->Option.getOr("")
                  ->JSON.Encode.string,
                ),
                (
                  "last_name",
                  switch name {
                  | Some(text) => text->String.split(" ")->Array.get(1)
                  | _ => Some("")
                  }
                  ->Option.getOr("")
                  ->JSON.Encode.string,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
            ("email", email->Option.getOr("")->JSON.Encode.string),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object
    Console.log2("bsbnum", bsbnum)
    Console.log2("acc num", accountnum)
    processRequest(~payment_method_data, ~payment_method, ~payment_method_type, ())
  }
  let processRequestSepaDebit = (payment_method: string, payment_method_type: string) => {
    let payment_method_data =
      [
        (
          payment_method,
          [
            (
              "sepa_bank_debit",
              [("iban", iban->Option.getOr("")->JSON.Encode.string)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
        (
          "billing",
          [
            (
              "address",
              [
                (
                  "first_name",
                  switch name {
                  | Some(text) => text->String.split(" ")->Array.get(0)
                  | _ => Some("")
                  }
                  ->Option.getOr("")
                  ->JSON.Encode.string,
                ),
                (
                  "last_name",
                  switch name {
                  | Some(text) => text->String.split(" ")->Array.get(1)
                  | _ => Some("")
                  }
                  ->Option.getOr("")
                  ->JSON.Encode.string,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
            ("email", email->Option.getOr("")->JSON.Encode.string),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object
    processRequest(~payment_method_data, ~payment_method, ~payment_method_type, ())
  }
  let processRequestBacsDebit = (payment_method: string, payment_method_type: string) => {
    let payment_method_data =
      [
        (
          payment_method,
          [
            (
              "bacs_bank_debit",
              [
                ("account_number", accountnum->Option.getOr("")->JSON.Encode.string),
                ("sort_code", sortCode->Option.getOr("")->JSON.Encode.string),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
        (
          // "billing",
          // [
          //   (
          //     "address",
          //     [
          //       (
          //         "country",
          //         switch name {
          //         | Some(text) => text->String.split(" ")->Array.get(0)
          //         | _ => Some("")
          //         }
          //         ->Option.getOr("")
          //         ->JSON.Encode.string,
          //       ),
          //       (
          //         "first_name",
          //         switch name {
          //         | Some(text) => text->String.split(" ")->Array.get(1)
          //         | _ => Some("")
          //         }
          //         ->Option.getOr("")
          //         ->JSON.Encode.string,
          //       ),
          //       (
          //         "line1",
          //         switch name {
          //         | Some(text) => text->String.split(" ")->Array.get(3)
          //         | _ => Some("")
          //         }
          //         ->Option.getOr("")
          //         ->JSON.Encode.string,
          //       ),
          //       (
          //         "zip",
          //         switch name {
          //         | Some(text) => text->String.split(" ")->Array.get(4)
          //         | _ => Some("")
          //         }
          //     ->Option.getOr("")
          //     ->JSON.Encode.string,
          //   ),
          // ]
          // ->Dict.fromArray
          // ->JSON.Encode.object,
          "billing",
          [
            (
              "address",
              [
                ("country", country->Option.getOr("")->JSON.Encode.string),
                ("first_name", name->Option.getOr("")->JSON.Encode.string),
                ("line1", line1->Option.getOr("")->JSON.Encode.string),
                ("zip", zip->Option.getOr("")->JSON.Encode.string),
                ("city", city->Option.getOr("")->JSON.Encode.string),
                //  ("state", state->Option.getOr("")->JSON.Encode.string),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
            ("email", email->Option.getOr("")->JSON.Encode.string),
            // ("phone", phone->Option.getOr("")->JSON.Encode.string),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object
    processRequest(~payment_method_data, ~payment_method, ~payment_method_type, ())
  }

  let processBankDebit = (bank_debit: payment_method_types_ach_bank_debit) => {
    switch bank_debit.payment_method_type_bank_debit {
    | ACH => processRequestBankDebit(bank_debit.payment_method, bank_debit.payment_method_type)
    | BECS => processRequestBecsDebit(bank_debit.payment_method, bank_debit.payment_method_type)
    | SEPA => processRequestSepaDebit(bank_debit.payment_method, bank_debit.payment_method_type)
    | BACS => processRequestBacsDebit(bank_debit.payment_method, bank_debit.payment_method_type)
    | NONE => ()
    }
  }

  let handlePress = _ => {
    setLoading(ProcessingPayments(None))
    switch redirectProp {
    | PAY_LATER(prop) =>
      fields.name == "klarna" && isKlarna
        ? setLaunchKlarna(_ => Some(prop))
        : processRequestPayLater(prop, "redirect")
    | BANK_REDIRECT(prop) => processRequestBankRedirect(prop)
    | CRYPTO(prop) => processRequestCrypto(prop)
    | WALLET(prop) => processRequestWallet(prop)
    | OPEN_BANKING(prop) => processRequestOpenBanking(prop)
    | BANK_DEBIT(prop) => processBankDebit(prop)
    | _ => ()
    }
    Console.log2("Payment Redirect", redirectProp)
  }

  let handlePressEmail = text => {
    setIsEmailValid(_ => text->ValidationFunctions.isValidEmail)
    setEmail(_ => Some(text))
  }
  let handlePressName = text => {
    let y = if text->String.length >= 3 {
      Some(true)
    } else {
      None
    }
    setIsNameValid(_ => y)
    setName(_ => Some(text))
  }
  let handlecity = text => {
    let y = if text->String.length >= 3 {
      Some(true)
    } else {
      None
    }
    setIscityValid(_ => y)
    setcity(_ => Some(text))
  }
  let handleAddress1 = text => {
    let y = if text->String.length >= 5 {
      Some(true)
    } else {
      None
    }
    setIsAddressValid(_ => y)
    setaddress(_ => Some(text))
  }
  let handleAddress2 = text => {
    let y = if text->String.length >= 5 {
      Some(true)
    } else {
      None
    }
    setIsAddress2Valid(_ => y)
    setaddress2(_ => Some(text))
  }
  let handlePressAccNum = number => {
    let onlyNumerics = number->String.replaceRegExp(%re("/\D+/g"), "")
    let y = if number->String.length <= 12 {
      Some(true)
    } else {
      None
    }
    setisaccountnumValid(_ => y)
    setaccountnum(_ => Some(onlyNumerics))
  }
  let handlePressAccNumBECS = number => {
    let onlyNumerics = number->String.replaceRegExp(%re("/\D+/g"), "")
    let y = if number->String.length == 9 {
      Some(true)
    } else {
      None
    }
    setisaccountnumbecsValid(_ => y)
    setaccountnumbecs(_ => Some(onlyNumerics))
  }

  let handlePressRouNum = number => {
    let onlyNumerics = number->String.replaceRegExp(%re("/\D+/g"), "")
    let y = if number->String.length === 9 {
      Some(true)
    } else {
      None
    }
    setisroutingnumValid(_ => y)
    setroutingnum(_ => Some(onlyNumerics))
  }

  let isEmailValidForFocus = {
    emailIsFocus ? true : isEmailValid->Option.getOr(true)
  }
  let isNameValidForFocus = {
    nameIsFocus ? true : isNameValid->Option.getOr(true)
  }

  let hasSomeFields = fields.fields->Array.length > 0

  let isAllValuesValid = React.useMemo3(() => {
    ((fields.fields->Array.includes("email") ? isEmailValid->Option.getOr(false) : true) && (
      fields.fields->Array.includes("name") ? isNameValid->Option.getOr(false) : true
    )) || (fields.name == "klarna" && isKlarna)
  }, (isEmailValid, isNameValid, allApiData.sessions))

  React.useEffect(() => {
    if isScreenFocus {
      setConfirmButtonDataRef(
        <ConfirmButton
          loading=false
          isAllValuesValid
          handlePress
          hasSomeFields
          paymentMethod
          ?paymentExperience
          errorText=error
        />,
      )
    }
    None
  }, (
    isAllValuesValid,
    hasSomeFields,
    paymentMethod,
    paymentExperience,
    isScreenFocus,
    error,
    blikCode,
    name,
    email,
    country,
    selectedBank,
    address,
    address2,
    city,
    isEmailValid,
    isNameValid,
    isAddressValid,
    isAddress2Valid,
    iscityValid,
    isaccountnumValid,
    isroutingnumValid,
    isaccountnumbecsValid,
    accountnum,
    routingnum,
    accountnumbecs,
    bsbnum,
    iban,
    setiban,
    sortCode,
  ))

  <>
    <Space />
    {switch paymentMethod {
    | "ach" => <TextWrapper text="Bank Details" textType={SubheadingBold} />
    | "becs" => <TextWrapper text="Bank Details" textType={SubheadingBold} />
    | _ => React.null
    }}
    {<>
      <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
        <UIUtils.RenderIf condition={fields.header->String.length > 0}>
          <TextWrapper text={fields.header} textType=Subheading />
        </UIUtils.RenderIf>
        {KlarnaModule.klarnaReactPaymentView->Option.isSome && fields.name == "klarna" && isKlarna
          ? <>
              <Space />
              <Klarna
                launchKlarna
                processRequest=processRequestPayLater
                return_url={Utils.getReturnUrl(nativeProp.hyperParams.appId)}
                klarnaSessionTokens=session_token
              />
              <ErrorText text=error />
            </>
          : <>
              {fields.fields
              ->Array.mapWithIndex((field, index) =>
                <View key={`field-${fields.text}${index->Int.toString}`}>
                  <Space />
                  {switch field {
                  | "email" =>
                    <CustomInput
                      state={email->Option.getOr("")}
                      setState={handlePressEmail}
                      placeholder=localeObject.emailLabel
                      keyboardType=#"email-address"
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderTopLeftRadius=borderRadius
                      borderTopRightRadius=borderRadius
                      borderTopWidth=borderWidth
                      borderBottomWidth=borderWidth
                      borderLeftWidth=borderWidth
                      borderRightWidth=borderWidth
                      isValid=isEmailValidForFocus
                      onFocus={_ => {
                        setEmailIsFocus(_ => true)
                      }}
                      onBlur={_ => {
                        setEmailIsFocus(_ => false)
                      }}
                      textColor=component.color
                    />
                  | "name" =>
                    <CustomInput
                      state={name->Option.getOr("")}
                      setState={handlePressName}
                      placeholder=localeObject.fullNameLabel
                      keyboardType=#default
                      isValid=isNameValidForFocus
                      onFocus={_ => {
                        setNameIsFocus(_ => true)
                      }}
                      onBlur={_ => {
                        setNameIsFocus(_ => false)
                      }}
                      textColor=component.color
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderTopLeftRadius=borderRadius
                      borderTopRightRadius=borderRadius
                      borderTopWidth=borderWidth
                      borderBottomWidth=borderWidth
                      borderLeftWidth=borderWidth
                      borderRightWidth=borderWidth
                    />
                  | "country" =>
                    <CustomPicker
                      value=country
                      setValue=onChangeCountry
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      items=countryData
                      placeholderText=localeObject.countryLabel
                    />

                  // | "State" =>
                  //   switch statesJson {
                  //   | Some(states) =>
                  //     <CustomPicker
                  //       value=state
                  //       setValue=onChangeState
                  //       borderBottomLeftRadius=borderRadius
                  //       borderBottomRightRadius=borderRadius
                  //       borderBottomWidth=borderWidth
                  //       items={states->getStateData}
                  //       placeholderText=localeObject.stateLabel
                  //     />
                  //   | None => React.null
                  //   }

                  | "bank" =>
                    <CustomPicker
                      value=selectedBank
                      setValue=onChangeBank
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      items=bankData
                      placeholderText=localeObject.bankLabel
                    />
                  | "blik_code" =>
                    <CustomInput
                      state={blikCode->Option.getOr("")}
                      setState={onChangeBlikCode}
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      placeholder="000-000"
                      keyboardType=#numeric
                      maxLength=Some(7)
                    />
                  | "Address_Line_1" =>
                    <CustomInput
                      state={address->Option.getOr("")}
                      setState={handleAddress1}
                      placeholder="Address Line 1"
                      keyboardType=#default
                      textColor=component.color
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderTopLeftRadius=borderRadius
                      borderTopRightRadius=borderRadius
                      borderTopWidth=borderWidth
                      borderBottomWidth=borderWidth
                      borderLeftWidth=borderWidth
                      borderRightWidth=borderWidth
                    />
                  | "line1" =>
                    <CustomInput
                      state={line1->Option.getOr("")}
                      setState={text => setLine1(_ => Some(text))}
                      placeholder="Address Line 1"
                      keyboardType=#default
                      textColor=component.color
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderTopLeftRadius=borderRadius
                      borderTopRightRadius=borderRadius
                      borderTopWidth=borderWidth
                      borderBottomWidth=borderWidth
                      borderLeftWidth=borderWidth
                      borderRightWidth=borderWidth
                    />

                  | "Address_Line_2" =>
                    <CustomInput
                      state={address2->Option.getOr("")}
                      setState={handleAddress2}
                      placeholder="Address Line 2"
                      keyboardType=#default
                      textColor=component.color
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderTopLeftRadius=borderRadius
                      borderTopRightRadius=borderRadius
                      borderTopWidth=borderWidth
                      borderBottomWidth=borderWidth
                      borderLeftWidth=borderWidth
                      borderRightWidth=borderWidth
                    />
                  | "City" =>
                    <CustomInput
                      state={city->Option.getOr("")}
                      setState={handlecity}
                      placeholder="City"
                      keyboardType=#default
                      textColor=component.color
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderTopLeftRadius=borderRadius
                      borderTopRightRadius=borderRadius
                      borderTopWidth=borderWidth
                      borderBottomWidth=borderWidth
                      borderLeftWidth=borderWidth
                      borderRightWidth=borderWidth
                    />
                  | "city" =>
                    <CustomInput
                      state={city->Option.getOr("")}
                      setState={text => setcity(_ => Some(text))}
                      placeholder="City"
                      keyboardType=#default
                      textColor=component.color
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderTopLeftRadius=borderRadius
                      borderTopRightRadius=borderRadius
                      borderTopWidth=borderWidth
                      borderBottomWidth=borderWidth
                      borderLeftWidth=borderWidth
                      borderRightWidth=borderWidth
                    />
                  // | "account_type" =>
                  //   <>
                  //     <CustomPicker
                  //       value=account
                  //       setValue=onChangeAccountType
                  //       borderBottomLeftRadius=borderRadius
                  //       borderBottomRightRadius=borderRadius
                  //       borderBottomWidth=borderWidth
                  //       items=accountTypes
                  //       placeholderText="Account Type"
                  //     />
                  //     <Space />
                  //     <ClickableTextElement
                  //       disabled={false}
                  //       initialIconName="checkboxClicked"
                  //       updateIconName=Some("checkboxNotClicked")
                  //       text=" Save this bank Details for faster payments"
                  //       isSelected=isNicknameSelected
                  //       setIsSelected=setIsNicknameSelected
                  //       textType={ModalText}
                  //       disableScreenSwitch=true
                  //     />
                  //   <Space />
                  //   <Space />
                  //   <TextWrapper text="Billing Address" textType=SubheadingBold />
                  //   <Space />
                  // </>

                  | "postal_code" =>
                    <CustomInput
                      state={postalCode->Option.getOr("")}
                      setState={onChangePostalCode}
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      placeholder="Postal Code"
                      keyboardType=#numeric
                      maxLength=Some(120)
                    />
                  | "zip" =>
                    <CustomInput
                      state={zip->Option.getOr("")}
                      setState={text => setZip(_ => Some(text))}
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      placeholder="Zip Code"
                      keyboardType=#numeric
                      maxLength=Some(10)
                    />
                  | "sort_code" =>
                    <CustomInput
                      state={sortCode->Option.getOr("")}
                      setState={onChangeSortCode}
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      placeholder="Sort Code"
                      keyboardType=#numeric
                      maxLength=Some(6)
                    />
                  | "iban" =>
                    <CustomInput
                      state={iban->Option.getOr("")}
                      setState={onChangeiban}
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      placeholder="IBAN Number"
                      keyboardType=#numeric
                      maxLength=Some(36)
                    />
                  | "phone" =>
                    <CustomInput
                      state={phone->Option.getOr("")}
                      setState={onChangePhoneNum}
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      placeholder="Phone Number"
                      keyboardType=#numeric
                      maxLength=Some(10)
                    />

                  | "account_number" =>
                    <CustomInput
                      state={accountnum->Option.getOr("")}
                      setState={handlePressAccNum}
                      placeholder="Account Number"
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      maxLength=Some(12)
                      keyboardType=#numeric
                    />
                  | "account_number_BECS" =>
                    <CustomInput
                      state={accountnumbecs->Option.getOr("")}
                      setState={handlePressAccNumBECS}
                      placeholder="Account Number"
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      maxLength=Some(9)
                      keyboardType=#numeric
                    />
                  | "bsb_number" =>
                    // <>
                    <CustomInput
                      state={bsbnum->Option.getOr("")}
                      setState={onChangebsbnum}
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      placeholder="BSB Number"
                      keyboardType=#numeric
                      maxLength=Some(6)
                    />
                  // <Space />
                  // <ClickableTextElement
                  //   disabled={false}
                  //   initialIconName="checkboxClicked"
                  //   updateIconName=Some("checkboxNotClicked")
                  //   text=" Save this bank Details for faster payments"
                  //   isSelected=isNicknameSelected
                  //   setIsSelected=setIsNicknameSelected
                  //   textType={ModalText}
                  //   disableScreenSwitch=true
                  // />
                  // <Space />
                  // <Space />
                  // <TextWrapper text="Billing Address" textType=SubheadingBold />
                  // <Space />
                  //</>
                  | "routing_number" =>
                    <CustomInput
                      state={routingnum->Option.getOr("")}
                      setState={handlePressRouNum}
                      placeholder="Routing Number"
                      keyboardType=#numeric
                      borderBottomLeftRadius=borderRadius
                      borderBottomRightRadius=borderRadius
                      borderBottomWidth=borderWidth
                      maxLength=Some(9)
                    />

                  | _ => React.null
                  }}
                </View>
              )
              ->React.array}
              <Space />
              {switch paymentMethod {
              | "ach" => React.null
              | "becs" => React.null
              | "sepa" => React.null
              | "bacs" => React.null
              | _ => <RedirectionText />
              }}
            </>}
      </ErrorBoundary>
      <Space height=5. />
    </>}
  </>
}
