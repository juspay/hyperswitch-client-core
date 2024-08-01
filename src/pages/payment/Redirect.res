open ReactNative
open PaymentMethodListType
open CustomPicker
open Style

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
  let (sessionData, _) = React.useContext(SessionContext.sessionContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let logger = LoggerHook.useLoggerHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let localeObject = GetLocale.useGetLocalObj()
  let {component, borderWidth, borderRadius} = ThemebasedStyle.useThemeBasedStyle()

  let (launchKlarna, setLaunchKlarna) = React.useState(_ => None)
  let (email, setEmail) = React.useState(_ => None)
  let (isEmailValid, setIsEmailValid) = React.useState(_ => None)
  let (emailIsFocus, setEmailIsFocus) = React.useState(_ => false)
  let (name, setName) = React.useState(_ => None)
  let (isNameValid, setIsNameValid) = React.useState(_ => None)
  let (nameIsFocus, setNameIsFocus) = React.useState(_ => false)
  let (country, setCountry) = React.useState(_ => Some(nativeProp.hyperParams.country))
  let (error, setError) = React.useState(_ => None)
  let (statesJson, setStatesJson) = React.useState(_ => None)

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
  }

  let paymentExperience = switch redirectProp {
  | CARD(_) => None
  | WALLET(prop) =>
    prop.payment_experience[0]->Option.map(paymentExperience =>
      paymentExperience.payment_experience_type_decode
    )

  | PAY_LATER(prop) =>
    prop.payment_experience[0]->Option.map(paymentExperience =>
      paymentExperience.payment_experience_type_decode
    )

  | BANK_REDIRECT(_) => None
  | CRYPTO(prop) =>
    prop.payment_experience[0]->Option.map(paymentExperience =>
      paymentExperience.payment_experience_type_decode
    )
  }

  let bankList = switch paymentMethod {
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
    | Some(x) => x.displayName
    | _ => ""
    },
  ))

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

  let {isKlarna, session_token} = React.useMemo1(() => {
    switch sessionData {
    | Some(sessionData) =>
      switch sessionData->Array.find(item => item.wallet_name == KLARNA) {
      | Some(tok) => {isKlarna: tok.wallet_name === KLARNA, session_token: tok.session_token}
      | None => {isKlarna: false, session_token: ""}
      }
    | _ => {isKlarna: false, session_token: ""}
    }
  }, [sessionData])

  let errorCallback = (
    ~errorMessage: PaymentConfirmTypes.error,
    ~closeSDK,
    ~doHandleSuccessFailure=true,
    (),
  ) => {
    if !closeSDK {
      setLoading(FillingDetails)
      switch errorMessage.message {
      | Some(message) => setError(_ => Some(message))
      | None => ()
      }
    }
    if doHandleSuccessFailure {
      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }
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
      ProcessPaymentRequest.processRequest(
        ~payment_method=walletType.payment_method,
        ~payment_method_data,
        ~payment_method_type=paymentMethod,
        ~payment_experience_type=?walletType.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.payment_experience_type
        ),
        ~eligible_connectors=?walletType.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.eligible_connectors
        ),
        ~errorCallback,
        ~responseCallback,
        ~paymentMethod,
        ~paymentExperience,
        ~nativeProp,
        ~allApiData,
        ~fetchAndRedirect,
        (),
      )
    | "User has canceled" => {
        let error: PaymentConfirmTypes.error = {
          message: "Payment was Cancelled",
        }
        errorCallback(~errorMessage=error, ~closeSDK=false, ~doHandleSuccessFailure=false, ())
      }
    | err => setError(_ => Some(err))
    }
  }

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
            [(walletType.payment_method_type, obj.paymentMethodData->ButtonElement.parser)]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
      ProcessPaymentRequest.processRequest(
        ~payment_method=walletType.payment_method,
        ~payment_method_data,
        ~payment_method_type=paymentMethod,
        ~payment_experience_type=?walletType.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.payment_experience_type
        ),
        ~eligible_connectors=?walletType.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.eligible_connectors
        ),
        ~errorCallback,
        ~responseCallback,
        ~paymentMethod,
        ~paymentExperience,
        ~nativeProp,
        ~allApiData,
        ~fetchAndRedirect,
        (),
      )
    | "Cancel" => {
        let error: PaymentConfirmTypes.error = {
          message: "Payment was Cancelled",
        }
        errorCallback(~errorMessage=error, ~closeSDK=false, ~doHandleSuccessFailure=false, ())
      }
    | err => {
        let error: PaymentConfirmTypes.error = {
          message: err,
        }
        errorCallback(~errorMessage=error, ~closeSDK=false, ~doHandleSuccessFailure=false, ())
        setError(_ => Some(err))
      }
    }
  }

  let confirmApplePay = var => {
    switch var
    ->Dict.get("status")
    ->Option.getOr(JSON.Encode.null)
    ->JSON.Decode.string
    ->Option.getOr("") {
    | "Cancelled" => {
        let error: PaymentConfirmTypes.error = {
          message: "Cancelled",
        }
        errorCallback(~errorMessage=error, ~closeSDK=false, ~doHandleSuccessFailure=false, ())
        setError(_ => Some("Cancelled"))
      }
    | "Failed" => {
        let error: PaymentConfirmTypes.error = {
          message: "Failed",
        }
        errorCallback(~errorMessage=error, ~closeSDK=false, ~doHandleSuccessFailure=false, ())
        setError(_ => Some("Failed"))
      }
    | "Error" => {
        let error: PaymentConfirmTypes.error = {
          message: "Error",
        }
        errorCallback(~errorMessage=error, ~closeSDK=false, ~doHandleSuccessFailure=false, ())
        setError(_ => Some("Error"))
      }
    | _ =>
      let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)

      let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)

      let transaction_identifier =
        var->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null)

      if transaction_identifier->JSON.stringify == "Simulated Identifier" {
        let error: PaymentConfirmTypes.error = {
          message: "Apple Pay is not supported in Simulated Environment",
        }
        errorCallback(~errorMessage=error, ~closeSDK=false, ~doHandleSuccessFailure=false, ())
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

        ProcessPaymentRequest.processRequest(
          ~payment_method=walletType.payment_method,
          ~payment_method_data,
          ~payment_method_type=paymentMethod,
          ~payment_experience_type=?walletType.payment_experience[0]->Option.map(
            paymentExperience => paymentExperience.payment_experience_type,
          ),
          ~eligible_connectors=?walletType.payment_experience[0]->Option.map(paymentExperience =>
            paymentExperience.eligible_connectors
          ),
          ~errorCallback,
          ~responseCallback,
          ~paymentMethod,
          ~paymentExperience,
          ~nativeProp,
          ~allApiData,
          ~fetchAndRedirect,
          (),
        )
      }
    }
  }

  let handlePress = _ => {
    setLoading(ProcessingPayments(None))
    switch redirectProp {
    | PAY_LATER(prop) =>
      fields.name == "klarna" && isKlarna
        ? setLaunchKlarna(_ => Some(prop))
        : ProcessPaymentRequest.processRequestPayLater(
            ~prop,
            ~authToken="redirect",
            ~name,
            ~email,
            ~country,
            ~paymentMethod,
            ~paymentExperience,
            ~errorCallback,
            ~responseCallback,
            ~nativeProp,
            ~allApiData,
            ~fetchAndRedirect,
          )
    | BANK_REDIRECT(prop) =>
      ProcessPaymentRequest.processRequestBankRedirect(
        ~prop,
        ~country,
        ~selectedBank,
        ~name,
        ~paymentMethod,
        ~paymentExperience,
        ~responseCallback,
        ~errorCallback,
        ~nativeProp,
        ~allApiData,
        ~fetchAndRedirect,
      )
    | CRYPTO(prop) =>
      ProcessPaymentRequest.processRequestCrypto(
        prop,
        paymentMethod,
        paymentExperience,
        responseCallback,
        errorCallback,
        ~nativeProp,
        ~allApiData,
        ~fetchAndRedirect,
      )
    | WALLET(prop) =>
      ProcessPaymentRequest.processRequestWallet(
        ~env=nativeProp.env,
        ~wallet=prop,
        ~setError,
        ~sessionObject,
        ~confirmGPay,
        ~confirmPayPal,
        ~confirmApplePay,
        ~errorCallback,
        ~responseCallback,
        ~paymentMethod,
        ~paymentExperience,
        ~nativeProp,
        ~allApiData,
        ~fetchAndRedirect,
        ~logger,
      )
    | _ => ()
    }
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
  }, (isEmailValid, isNameValid, sessionData))

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
    name,
    country,
    email,
  ))

  <View style={viewStyle(~marginHorizontal=18.->dp, ())}>
    <Space />
    <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
      <UIUtils.RenderIf condition={fields.header->String.length > 0}>
        <TextWrapper text={fields.header} textType=Subheading />
      </UIUtils.RenderIf>
      {KlarnaModule.klarnaReactPaymentView->Option.isSome && fields.name == "klarna" && isKlarna
        ? <>
            <Space />
            <Klarna
              launchKlarna
              userData={
                ?name,
                ?email,
                ?country,
              }
              paymentMethod
              paymentExperience
              errorCallback
              responseCallback
              return_url={switch nativeProp.hyperParams.appId {
              | Some(id) => Some(id ++ ".hyperswitch://")
              | None => None
              }}
              klarnaSessionTokens=session_token
              nativeProp
              allApiData
              fetchAndRedirect
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
                | _ => React.null
                }}
              </View>
            )
            ->React.array}
            <Space />
            <RedirectionText />
          </>}
    </ErrorBoundary>
    <Space height=5. />
  </View>
}
