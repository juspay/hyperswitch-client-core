open ReactNative
open PaymentMethodListType
open CustomPicker
open Style

type klarnaSessionCheck = {
  isKlarna: bool,
  session_token: string,
}

/**
`getIndexZeroAndApplyTransform(array, fn)` applies `Option.map` using transformer function `fn` on element at `index 0` of `array`.

### Implementation
```rescript
(arr, fn) => arr->Array.get(0)->Option.map(fn)
```
*/
let getIndexZeroAndApplyTransform = (arr, fn) => arr->Array.get(0)->Option.map(fn)

/**
 This component redirects to payment methods other than Card type.
 
 Payment methods:
 - WALLET
 - PAY_LATER
 - BANK_REDIRECT
 - CRYPTO
 */
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
  let showAlert = AlertHook.useAlerts()

  let (launchKlarna, setLaunchKlarna) = React.useState(_ => None)
  let (email, setEmail) = React.useState(_ => None)
  let (isEmailValid, setIsEmailValid) = React.useState(_ => None)
  let (emailIsFocus, setEmailIsFocus) = React.useState(_ => false)
  let (name, setName) = React.useState(_ => None)
  let (isNameValid, setIsNameValid) = React.useState(_ => None)
  let (nameIsFocus, setNameIsFocus) = React.useState(_ => false)
  let (country, setCountry) = React.useState(_ => Some(nativeProp.hyperParams.country))
  let (blikCode, setBlikCode) = React.useState(_ => None)
  let (error, setError) = React.useState(_ => None)

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
    ->Array.map(x => x.bank_name)
    ->Array.reduce([], (acc, item) => acc->Array.concat(item))
    ->Array.map(x => x->JSON.parseExn->JSON.Decode.string->Option.getOr(""))
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
    prop.payment_experience->getIndexZeroAndApplyTransform(paymentExperience =>
      paymentExperience.payment_experience_type_decode
    )
  | PAY_LATER(prop) =>
    prop.payment_experience->getIndexZeroAndApplyTransform(paymentExperience =>
      paymentExperience.payment_experience_type_decode
    )
  | BANK_REDIRECT(_) => None
  | CRYPTO(prop) =>
    prop.payment_experience->getIndexZeroAndApplyTransform(paymentExperience =>
      paymentExperience.payment_experience_type_decode
    )
  }

  let bankList = switch paymentMethod {
  | "ideal" => getBankNames(bankName)->Js.Array.sortInPlace
  | "eps" => getBankNames(bankName)->Js.Array.sortInPlace
  | _ => []
  }

  let bankItems = Bank.bankNameConverter(bankList)

  let bankData = bankItems->Array.map(item => {
    name: item.displayName,
    value: item.hyperSwitch,
  })

  let countryData = Country.country->Array.map(item => {
    name: item.countryName,
    value: item.isoAlpha2,
    icon: Utils.getCountryFlags(item.isoAlpha2),
  })

  let bankDefault = switch bankItems->Array.get(0) {
  | Some(x) => x.hyperSwitch
  | _ => ""
  }
  let (selectedBank, setSelectedBank) = React.useState(_ => Some(bankDefault))

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

  let onChangeBank = val => setSelectedBank(val)

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
        setTimeout(() => handleSuccessFailure(~apiResStatus=status, ()), 300)->ignore
        setTimeout(() => handleSuccessFailure(~apiResStatus=status, ()), 300)->ignore
      }
    | _ => handleSuccessFailure(~apiResStatus=status, ())
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
            ~walletType,
            ~paymentMethod,
            ~paymentExperience,
            ~errorCallback,
            ~responseCallback,
            ~setLoading,
            ~showAlert,
            ~nativeProp,
            ~allApiData,
            ~fetchAndRedirect,
            ~logger,
          )
    | BANK_REDIRECT(prop) =>
      ProcessPaymentRequest.processRequestBankRedirect(
        ~prop,
        ~country,
        ~selectedBank,
        ~name,
        ~blikCode,
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
        ~prop,
        ~paymentMethod,
        ~paymentExperience,
        ~responseCallback,
        ~errorCallback,
        ~nativeProp,
        ~allApiData,
        ~fetchAndRedirect,
      )
    | WALLET(prop) =>
      ProcessPaymentRequest.processRequestWallet(
        ~env=nativeProp.env,
        ~wallet=prop,
        ~setLoading,
        ~setError,
        ~showAlert,
        ~sessionObject,
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
    let y = text->String.length >= 3 ? Some(true) : None
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
    ((fields.fields->Array.includes(Email) ? isEmailValid->Option.getOr(false) : true) && (
      fields.fields->Array.includes(Name) ? isNameValid->Option.getOr(false) : true
    )) || (fields.name == "klarna" && isKlarna)
  }, (isEmailValid, isNameValid, sessionData))

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
    country,
    email,
    selectedBank,
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
              walletType
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
                | Email =>
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
                    onFocus={_ => setEmailIsFocus(_ => true)}
                    onBlur={_ => setEmailIsFocus(_ => false)}
                    textColor=component.color
                  />
                | Name =>
                  <CustomInput
                    state={name->Option.getOr("")}
                    setState={handlePressName}
                    placeholder=localeObject.fullNameLabel
                    keyboardType=#default
                    isValid=isNameValidForFocus
                    onFocus={_ => setNameIsFocus(_ => true)}
                    onBlur={_ => setNameIsFocus(_ => false)}
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
                | Country =>
                  <CustomPicker
                    value=country
                    setValue=onChangeCountry
                    borderBottomLeftRadius=borderRadius
                    borderBottomRightRadius=borderRadius
                    borderBottomWidth=borderWidth
                    items=countryData
                    placeholderText=localeObject.countryLabel
                  />
                | Bank =>
                  <CustomPicker
                    value=selectedBank
                    setValue=onChangeBank
                    borderBottomLeftRadius=borderRadius
                    borderBottomRightRadius=borderRadius
                    borderBottomWidth=borderWidth
                    items=bankData
                    placeholderText=localeObject.bankLabel
                  />
                | BlikCode =>
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
