open PaymentMethodListType

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
  ~dynamicFields: RequiredFieldsTypes.required_fields,
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

  let (isAllDynamicFieldValid, setIsAllDynamicFieldValid) = React.useState(_ => false)
  let (dynamicFieldsJson, setDynamicFieldsJson) = React.useState(_ => [])
  let (keyToTrigerButtonClickError, setKeyToTrigerButtonClickError) = React.useState(_ => 0)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (launchKlarna, setLaunchKlarna) = React.useState(_ => None)
  
  let showAlert = AlertHook.useAlerts()

  let paymentMethod = switch redirectProp {
  | CARD(prop) => prop.payment_method_type
  | WALLET(prop) => prop.payment_method_type
  | PAY_LATER(prop) => prop.payment_method_type
  | BANK_REDIRECT(prop) => prop.payment_method_type
  | CRYPTO(prop) => prop.payment_method_type
  | OPEN_BANKING(prop) => prop.payment_method_type
  }
  let paymentExperience = switch redirectProp {
  // | CARD(_) => None
  // | WALLET(prop) =>
  //   prop.payment_experience
  //   ->Array.get(0)
  //   ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)

  | PAY_LATER(prop) =>
    prop.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  | _ => None
  // | BANK_REDIRECT(_) => None
  // | OPEN_BANKING(prop) =>
  //   prop.payment_experience
  //   ->Array.get(0)
  //   ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  // | CRYPTO(prop) =>
  //   prop.payment_experience
  //   ->Array.get(0)
  //   ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode)
  }

  let logger = LoggerHook.useLoggerHook()

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
        allApiData.additionalPMLData.mandateType != NORMAL ? Some("off_session") : None
      ),
      payment_type: ?allApiData.additionalPMLData.paymentType,
      // mandate_data: ?(
      //   allApiData.mandateType != NORMAL
      //     ? Some({
      //         customer_acceptance: {
      //           acceptance_type: "online",
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
      ~body=body->JSON.stringifyAny->Option.getOr("{}"),
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
      let dynamicFieldsJsonDict = dynamicFieldsJson->Array.reduce(Dict.make(), (
        acc,
        (key, val, _),
      ) => {
        acc->Dict.set(key, val)
        acc
      })
      let redirectData =
        [
          (
            "billing_email",
            switch dynamicFieldsJson->Array.find(((key, _, _)) => key->String.includes("email")) {
            | Some((_, value, _)) => value
            | None => JSON.Encode.string("")
            },
          ),
          ("billing_name", ""->JSON.Encode.string),
          (
            "billing_country",
            switch dynamicFieldsJson->Array.find(((key, _, _)) => key->String.includes("country")) {
            | Some((_, value, _)) => value
            | None => ""->JSON.Encode.string
            },
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object

      let sdkData = [("token", authToken->JSON.Encode.string)]->Dict.fromArray->JSON.Encode.object
      // need dynamic data
      let payment_method_data = Dict.make()

      let innerData = Dict.make()
      innerData->Dict.set(
        prop.payment_method_type ++ (authToken == "redirect" ? "_redirect" : "_sdk"),
        authToken == "redirect" ? redirectData : sdkData,
      )

      let middleData = Dict.make()
      middleData->Dict.set(prop.payment_method, innerData->JSON.Encode.object)

      payment_method_data->Dict.set("payment_method_data", middleData->JSON.Encode.object)
      let dynamic_pmd =
        payment_method_data->RequiredFieldsTypes.mergeTwoFlattenedJsonDicts(dynamicFieldsJsonDict)

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
      ()
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

  let handlePress = _ => {
    setLoading(ProcessingPayments(None))
    setKeyToTrigerButtonClickError(prev => prev + 1)
    if isAllDynamicFieldValid {
      switch redirectProp {
      | PAY_LATER(prop) =>
        fields.name == "klarna" && isKlarna
          ? setLaunchKlarna(_ => Some(prop))
          : processRequestPayLater(prop, "redirect")
      //   | BANK_REDIRECT(prop) => processRequestBankRedirect(prop)
      //   | CRYPTO(prop) => processRequestCrypto(prop)
      //   | WALLET(prop) => processRequestWallet(prop)
      //   | OPEN_BANKING(prop) => processRequestOpenBanking(prop)
      | _ => ()
      }
    }
  }

  React.useEffect(() => {
    if isScreenFocus {
      setConfirmButtonDataRef(
        <ConfirmButton
          loading=false
          isAllValuesValid=isAllDynamicFieldValid
          handlePress
          hasSomeFields={dynamicFields->Array.length > 0}
          paymentMethod
          ?paymentExperience
          errorText=error
        />,
      )
    }
    None
  }, (
    isAllDynamicFieldValid,
    dynamicFieldsJson,
    paymentMethod,
    paymentExperience,
    isScreenFocus,
    error,
  ))

  <>
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
              processRequest=processRequestPayLater
              return_url={Utils.getReturnUrl(nativeProp.hyperParams.appId)}
              klarnaSessionTokens=session_token
            />
            <ErrorText text=error />
          </>
        : <>
            <DynamicFieldsRedirect
              requiredFields=dynamicFields
              setIsAllDynamicFieldValid
              setDynamicFieldsJson
              keyToTrigerButtonClickError
              savedCardsData=None
       
            />
            <Space />
            <RedirectionText />
          </>}
    </ErrorBoundary>
    <Space height=5. />
  </>
}
