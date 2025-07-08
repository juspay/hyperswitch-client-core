open PaymentMethodListType
open RequiredFieldsTypes

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

  let (isAllDynamicFieldValid, setIsAllDynamicFieldValid) = React.useState(_ => false)

  let (dynamicFieldsJson, setDynamicFieldsJson) = React.useState((_): dict<(
    JSON.t,
    option<string>,
  )> => Dict.make())
  let (keyToTrigerButtonClickError, setKeyToTrigerButtonClickError) = React.useState(_ => 0)
  // let (country, setCountry) = React.useState(_ => Some(nativeProp.hyperParams.country))

  // let (blikCode, setBlikCode) = React.useState(_ => None)
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
  | BANK_TRANSFER(prop) => prop.payment_method_type
  }

  let bankDebitPMType = switch redirectProp {
  | BANK_DEBIT(prop) => prop.payment_method_type_var
  | _ => Other
  }

  let paymentExperience = switch redirectProp {
  | CARD(_)
  | BANK_REDIRECT(_) =>
    None
  | WALLET(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  | PAY_LATER(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
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
  | BANK_TRANSFER(prop) =>
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

  let bankData: array<CustomPicker.customPickerType> = bankItems->Array.map((item: Bank.bank) => {
    {
      CustomPicker.label: item.displayName,
      value: item.hyperSwitch,
    }
  })
  // let (statesAndCountry, _) = React.useContext(CountryStateDataContext.countryStateDataContext)

  // let countryData: array<customPickerType> = switch statesAndCountry {
  // | Localdata(data) | FetchData(data) =>
  //   data.countries->Array.map(item => {
  //     {
  //       label: item.label != "" ? item.label ++ " - " ++ item.value : item.value,
  //       value: item.isoAlpha2,
  //       icon: Utils.getCountryFlags(item.isoAlpha2),
  //     }
  //   })
  // | _ => []
  // }

  let (selectedBank, setSelectedBank) = React.useState(_ => Some(
    switch bankItems->Array.get(0) {
    | Some(x) => x.hyperSwitch
    | _ => ""
    },
  ))

  let logger = LoggerHook.useLoggerHook()

  let onChangeBank = val => {
    setSelectedBank(val)
  }

  // let onChangeBlikCode = (val: string) => {
  //   let onlyNumerics = val->String.replaceRegExp(%re("/\D+/g"), "")
  //   let firstPart = onlyNumerics->String.slice(~start=0, ~end=3)
  //   let secondPart = onlyNumerics->String.slice(~start=3, ~end=6)

  //   let finalVal = if onlyNumerics->String.length <= 3 {
  //     firstPart
  //   } else if onlyNumerics->String.length > 3 && onlyNumerics->String.length <= 6 {
  //     `${firstPart}-${secondPart}`
  //   } else {
  //     onlyNumerics
  //   }
  //   setBlikCode(_ => Some(finalVal))
  // }

  let (error, setError) = React.useState(_ => None)

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()

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
    ~shipping=?,
    (),
  ) => {
    let body: redirectType = {
      client_secret: nativeProp.clientSecret,
      return_url: ?Utils.getReturnUrl(
        ~appId=nativeProp.hyperParams.appId,
        ~appURL=allApiData.additionalPMLData.redirect_url,
      ),
      payment_method,
      payment_method_type,
      payment_experience: payment_experience_type,
      connector: ?eligible_connectors,
      payment_method_data,
      billing: ?nativeProp.configuration.defaultBillingDetails,
      shipping: shipping->Option.getOr(
        nativeProp.configuration.shippingDetails->Option.getOr({
          phone: None,
          address: None,
          email: None,
        }),
      ),
      setup_future_usage: ?(
        allApiData.additionalPMLData.mandateType != NORMAL ? Some("off_session") : None
      ),
      payment_type: ?allApiData.additionalPMLData.paymentType,
      // mandate_data: ?(
      //   allApiData.additionalPMLData.mandateType != NORMAL
      //     ? Some({
      //         customer_acceptance: {
      //           acceptance_type: "offline",
      //           accepted_at: Date.now()->Date.fromTime->Date.toISOString,
      //           online: {
      //             ip_address: ?nativeProp.hyperParams.ip,
      //             user_agent: ?nativeProp.hyperParams.userAgent,
      //           },
      //         },
      //       })
      //     : None
      // ),
      customer_acceptance: ?(
        allApiData.additionalPMLData.mandateType->PaymentUtils.checkIfMandate
          ? Some({
              acceptance_type: "online",
              accepted_at: Date.now()->Date.fromTime->Date.toISOString,
              online: {
                user_agent: ?nativeProp.hyperParams.userAgent,
              },
            })
          : None
      ),
      browser_info: {
        user_agent: ?nativeProp.hyperParams.userAgent,
        language: ?nativeProp.configuration.appearance.locale,
        device_model: ?nativeProp.hyperParams.device_model,
        os_type: ?nativeProp.hyperParams.os_type,
        os_version: ?nativeProp.hyperParams.os_version,
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
      ~paymentExperience=getPaymentExperienceType(paymentExperience->Option.getOr(NONE)),
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
      let dynamicFieldsArray = dynamicFieldsJson->Dict.toArray
      let dynamicFieldsJsonDict = dynamicFieldsArray->Array.reduce(Dict.make(), (
        acc,
        (key, (val, _)),
      ) => {
        acc->Dict.set(key, val)
        acc
      })
      let redirectData =
        [
          (
            "billing_email",
            dynamicFieldsArray
            ->Array.find(((key, _)) => key->String.includes("email") == true)
            ->Option.map(((_, (value, _))) => value)
            ->Option.getOr(""->JSON.Encode.string),
          ),
          (
            "billing_name",
            dynamicFieldsArray
            ->Array.find(((key, _)) => key->String.includes("first_name") == true)
            ->Option.map(((_, (value, _))) => value->JSON.Decode.string->Option.getOr(""))
            ->Option.getOr("")
            ->String.concat(" ")
            ->String.concat(
              dynamicFieldsArray
              ->Array.find(((key, _)) => key->String.includes("last_name") == true)
              ->Option.map(((_, (value, _))) => value->JSON.Decode.string->Option.getOr(""))
              ->Option.getOr(""),
            )
            ->JSON.Encode.string,
          ),
          (
            "billing_country",
            dynamicFieldsArray
            ->Array.find(((key, _)) => key->String.includes("country") == true)
            ->Option.map(((_, (value, _))) => value)
            ->Option.getOr(""->JSON.Encode.string),
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object

      let sdkData = [("token", authToken->JSON.Encode.string)]->Dict.fromArray->JSON.Encode.object
      // let payment_method_data =
      //   [
      //     (
      //       prop.payment_method,
      //       [
      //         (
      //           prop.payment_method_type ++ (authToken == "redirect" ? "_redirect" : "_sdk"),
      //           authToken == "redirect" ? redirectData : sdkData,
      //         ),
      //       ]
      //       ->Dict.fromArray
      //       ->JSON.Encode.object,
      //     ),
      //   ]
      //   ->Dict.fromArray
      //   ->JSON.Encode.object
      let payment_method_data = Dict.make()
      let innerData = Dict.make()
      innerData->Dict.set(
        prop.payment_method_type ++ (authToken == "redirect" ? "_redirect" : "_sdk"),
        authToken == "redirect" ? redirectData : sdkData,
      )
      let middleData = Dict.make()
      middleData->Dict.set(prop.payment_method, innerData->JSON.Encode.object)
      payment_method_data->Dict.set("payment_method_data", middleData->JSON.Encode.object)
      let dynamic_pmd = payment_method_data->mergeTwoFlattenedJsonDicts(dynamicFieldsJsonDict)
      processRequest(
        ~payment_method_data=dynamic_pmd
        ->Utils.getJsonObjectFromDict("payment_method_data")
        ->JSON.stringifyAny
        ->Option.getOr("{}")
        ->JSON.parseExn,
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
        ->Option.map(paymentExperience =>
          getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
        ),
        (),
      )
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment Method Unavailable")
    }
  }

  let processRequestBankRedirect = (prop: payment_method_types_bank_redirect) => {
    let dynamicFieldsArray = dynamicFieldsJson->Dict.toArray
    let dynamicFieldsJsonDict = dynamicFieldsArray->Array.reduce(Dict.make(), (
      acc,
      (key, (val, _)),
    ) => {
      acc->Dict.set(key, val)
      acc
    })
    switch selectedBank {
    | Some(bank) when bank !== "" =>
      dynamicFieldsJsonDict->Dict.set("payment_method_data.bank_redirect." ++ prop.payment_method_type ++ ".bank", bank->JSON.Encode.string)
    | _ => ()
    }

    let payment_method_data =
      dynamicFieldsJsonDict
      ->JSON.Encode.object
      ->unflattenObject
      ->Utils.getJsonObjectFromDict("payment_method_data")
      ->JSON.stringifyAny
      ->Option.getOr("{}")
      ->JSON.parseExn

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

  let processRequestWallet = (walletType: payment_method_types_wallet) => {
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
    if (
      walletType.payment_experience
      ->Array.find(exp => exp.payment_experience_type_decode == INVOKE_SDK_CLIENT)
      ->Option.isSome
    ) {
      switch walletType.payment_method_type_wallet {
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
      | _ => ()
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
        ->Option.map(paymentExperience =>
          getPaymentExperienceType(paymentExperience.payment_experience_type_decode)
        ),
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

  let processRequestBankDebit = (prop: payment_method_types_bank_debit) => {
    let dynamicFieldsArray = dynamicFieldsJson->Dict.toArray
    let dynamicFieldsJsonDict = dynamicFieldsArray->Array.reduce(Dict.make(), (
      acc,
      (key, (val, _)),
    ) => {
      acc->Dict.set(key, val)
      acc
    })

    let payment_method_data = dynamicFieldsJsonDict->JSON.Encode.object->unflattenObject
    processRequest(
      ~payment_method_data=payment_method_data
      ->Utils.getJsonObjectFromDict("payment_method_data")
      ->JSON.stringifyAny
      ->Option.getOr("{}")
      ->JSON.parseExn,
      ~payment_method=prop.payment_method,
      ~payment_method_type=prop.payment_method_type,
      (),
    )
  }
  let processRequestBankTransfer = (prop: payment_method_types_bank_transfer) => {
    let dynamicFieldsArray = dynamicFieldsJson->Dict.toArray
    let payment_method_data =
      [
        (
          prop.payment_method,
          [
            (
              "ach_bank_transfer",
              []
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
              "email",
              dynamicFieldsArray
              ->Array.find(((key, _)) => key->String.includes("email") == true)
              ->Option.map(((_, (value, _))) => value)
              ->Option.getOr(""->JSON.Encode.string),
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

  let hasSomeFields = fields.fields->Array.length > 0

  let handlePress = _ => {
    if isAllDynamicFieldValid {
      setLoading(ProcessingPayments(None))
      setKeyToTrigerButtonClickError(prev => prev + 1)
      switch redirectProp {
      | PAY_LATER(prop) =>
        fields.name == "klarna" && isKlarna
          ? setLaunchKlarna(_ => Some(prop))
          : processRequestPayLater(prop, "redirect")
      | BANK_REDIRECT(prop) => processRequestBankRedirect(prop)
      | CRYPTO(prop) => processRequestCrypto(prop)
      | WALLET(prop) => processRequestWallet(prop)
      | OPEN_BANKING(prop) => processRequestOpenBanking(prop)
      | BANK_DEBIT(prop) => processRequestBankDebit(prop)
      | BANK_TRANSFER(prop) => processRequestBankTransfer(prop)
      | _ => ()
      }
    } else {
      setKeyToTrigerButtonClickError(prev => prev + 1)
    }
  }

  React.useEffect(() => {
    if isScreenFocus {
      setConfirmButtonDataRef(
        <ConfirmButton
          loading=false
          isAllValuesValid=true
          handlePress
          hasSomeFields
          paymentMethod
          paymentExperience={PaymentMethodListType.getPaymentExperienceType(
            paymentExperience->Option.getOr(NONE),
          )}
          errorText=error
        />,
      )
    }
    None
  }, (
    isAllDynamicFieldValid,
    hasSomeFields,
    paymentMethod,
    paymentExperience,
    isScreenFocus,
    error,
  ))

  <>
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
              return_url={Utils.getReturnUrl(
                ~appId=nativeProp.hyperParams.appId,
                ~appURL=allApiData.additionalPMLData.redirect_url,
              )}
              klarnaSessionTokens=session_token
            />
            <ErrorText text=error />
          </>
        : <>
            {switch (redirectProp, bankData->Array.length > 0) {
            | (BANK_REDIRECT(_), true) =>
              <>
                <CustomPicker
                  value=selectedBank
                  setValue=onChangeBank
                  items=bankData
                  placeholderText="Select Bank"
                />
                <Space height=15. />
              </>
            | _ => React.null
            }}
            <DynamicFields
              requiredFields={switch redirectProp {
              | PAY_LATER(prop) => prop.required_field
              | BANK_REDIRECT(prop) => prop.required_field
              | CRYPTO(prop) => prop.required_field
              | WALLET(prop) => prop.required_field
              | OPEN_BANKING(prop) => prop.required_field
              | BANK_DEBIT(prop) => prop.required_field
              | BANK_TRANSFER(prop) => prop.required_field
              | CARD(prop) => prop.required_field
              }}
              setIsAllDynamicFieldValid
              setDynamicFieldsJson
              keyToTrigerButtonClickError
              savedCardsData=None
              paymentMethodType={bankDebitPMType}
            />
            <Space height=25. />
            <RedirectionText />
          </>}
    </ErrorBoundary>
    <Space height=5. />
  </>
}
