open VisaClickToPaySDK

type componentState = NONE | CARDS_LOADING | OTP_INPUT | CARDS_DISPLAY

type clickToPayHook = {
  sdkRef: React.ref<Nullable.t<VisaSDK.visaSDKRef>>,
  sdkReady: bool,
  setSdkReady: (bool => bool) => unit,
  otp: array<string>,
  setOtp: (array<string> => array<string>) => unit,
  otpRefs: array<React.ref<Nullable.t<ReactNative.TextInput.element>>>,
  componentState: componentState,
  setComponentState: (componentState => componentState) => unit,
  cardsArray: array<JSON.t>,
  setCardsArray: (array<JSON.t> => array<JSON.t>) => unit,
  srcId: string,
  setSrcId: (string => string) => unit,
  showNotYouScreen: bool,
  setShowNotYouScreen: (bool => bool) => unit,
  newIdentifier: string,
  setNewIdentifier: (string => string) => unit,
  resendLoading: bool,
  setResendLoading: (bool => bool) => unit,
  resendTimer: int,
  setResendTimer: (int => int) => unit,
  rememberMe: bool,
  setRememberMe: (bool => bool) => unit,
  handleGetCardsOutput: Js.Dict.t<JSON.t> => unit,
  initVisaClickToPayAndGetCards: unit => promise<unit>,
  submitOtp: (~otpValue: array<string>=?) => promise<unit>,
  resendOtp: unit => promise<unit>,
  handleOtpChange: (int, string) => unit,
  handleCheckout: unit => promise<unit>,
  switchIdentity: string => promise<unit>,
}

let useVisaClickToPay = (clickToPaySession: option<SessionsType.sessions>) => {
  let sdkRef = React.useRef(Nullable.null)
  let (sdkReady, setSdkReady) = React.useState(() => false)
  let (otp, setOtp) = React.useState(() => ["", "", "", "", "", ""])

  let otpRef0 = React.useRef(Nullable.null)
  let otpRef1 = React.useRef(Nullable.null)
  let otpRef2 = React.useRef(Nullable.null)
  let otpRef3 = React.useRef(Nullable.null)
  let otpRef4 = React.useRef(Nullable.null)
  let otpRef5 = React.useRef(Nullable.null)

  let otpRefs = [otpRef0, otpRef1, otpRef2, otpRef3, otpRef4, otpRef5]

  let (componentState, setComponentState) = React.useState(() => CARDS_LOADING)
  let (cardsArray, setCardsArray) = React.useState(() => [])
  let (srcId, setSrcId) = React.useState(() => "")
  let (showNotYouScreen, setShowNotYouScreen) = React.useState(() => false)
  let (newIdentifier, setNewIdentifier) = React.useState(() => "")
  let (resendLoading, setResendLoading) = React.useState(() => false)
  let (resendTimer, setResendTimer) = React.useState(() => 0)
  let (rememberMe, setRememberMe) = React.useState(() => false)

  let consumerIdentity: VisaSDK.consumerIdentity = {
    identityProvider: "SRC",
    identityValue: clickToPaySession->Option.flatMap(session => session.email)->Option.getOr(""),
    identityType: "EMAIL_ADDRESS",
  }

  let handleGetCardsOutput = cards => {
    open Belt.Option

    let actionCode = cards->Js.Dict.get("actionCode")->flatMap(JSON.Decode.string)

    switch actionCode {
    | Some("PENDING_CONSUMER_IDV") => setComponentState(_ => OTP_INPUT)
    | Some("SUCCESS") => {
        let maskedCards =
          cards
          ->Js.Dict.get("profiles")
          ->flatMap(JSON.Decode.array)
          ->flatMap(arr => Array.get(arr, 0))
          ->flatMap(JSON.Decode.object)
          ->flatMap(profile => profile->Js.Dict.get("maskedCards"))
          ->flatMap(JSON.Decode.array)

        switch maskedCards {
        | Some(cards) => {
            setCardsArray(_ => cards)
            setComponentState(_ => CARDS_DISPLAY)
          }
        | None => setComponentState(_ => NONE)
        }
      }
    | _ => setComponentState(_ => NONE)
    }
  }

  let initVisaClickToPayAndGetCards = async () => {
    try {
      setComponentState(_ => CARDS_LOADING)
      let sdkRefValue = sdkRef.current->Nullable.toOption
      switch sdkRefValue {
      | Some(sdk) => {
          let initParams: VisaSDK.initializeParams = {
            dpaTransactionOptions: {
              transactionAmount: {
                transactionAmount: clickToPaySession
                ->Option.flatMap(session => session.transaction_amount)
                ->Option.getOr(""),
                transactionCurrencyCode: clickToPaySession
                ->Option.flatMap(session => session.transaction_currency_code)
                ->Option.getOr(""),
              },
              dpaBillingPreference: "NONE",
              dpaAcceptedBillingCountries: ["US", "CA"],
              merchantCategoryCode: clickToPaySession
              ->Option.flatMap(session => session.merchant_category_code)
              ->Option.getOr(""),
              merchantCountryCode: clickToPaySession
              ->Option.flatMap(session => session.merchant_country_code)
              ->Option.getOr(""),
              payloadTypeIndicator: "FULL",
              merchantOrderId: "order_" ++ Date.now()->Float.toString,
              paymentOptions: [
                {
                  dpaDynamicDataTtlMinutes: 2,
                  dynamicDataType: "CARD_APPLICATION_CRYPTOGRAM_SHORT_FORM",
                },
              ],
              dpaLocale: clickToPaySession
              ->Option.flatMap(session => session.locale)
              ->Option.getOr(""),
            },
            correlationId: clickToPaySession
            ->Option.flatMap(session => session.dpa_id)
            ->Option.getOr(""),
          }

          let _ = await VisaSDK.callFunction(sdk, "initialize", initParams)

          let getCardsParams: VisaSDK.getCardsParams = {consumerIdentity: consumerIdentity}
          let cards = await VisaSDK.callFunction(sdk, "getCards", getCardsParams)
          handleGetCardsOutput(cards)
        }
      | None => setComponentState(_ => NONE)
      }
    } catch {
    | _ => setComponentState(_ => NONE)
    }
  }

  let submitOtp = async (~otpValue=?) => {
    try {
      setComponentState(_ => CARDS_LOADING)
      let otpString = switch otpValue {
      | Some(otpArr) => otpArr->Array.join("")
      | None => otp->Array.join("")
      }

      let sdkRefValue = sdkRef.current->Nullable.toOption

      switch sdkRefValue {
      | Some(sdk) => {
          let getCardsParams: VisaSDK.getCardsParams = {
            consumerIdentity: consumerIdentity,
            validationData: otpString,
          }
          let cards = await VisaSDK.callFunction(sdk, "getCards", getCardsParams)
          handleGetCardsOutput(cards)
        }
      | None => setComponentState(_ => OTP_INPUT)
      }
    } catch {
    | _ => setComponentState(_ => OTP_INPUT)
    }
  }

  let resendOtp = async () => {
    try {
      setResendLoading(_ => true)
      setResendTimer(_ => 30)
      let sdkRefValue = sdkRef.current->Nullable.toOption

      switch sdkRefValue {
      | Some(sdk) => {
          let getCardsParams = {
            "consumerIdentity": {
              "identityProvider": consumerIdentity.identityProvider,
              "identityValue": consumerIdentity.identityValue,
              "identityType": consumerIdentity.identityType,
            },
          }
          let cards = await VisaSDK.callFunction(sdk, "getCards", getCardsParams)
          handleGetCardsOutput(cards)
          setOtp(_ => ["", "", "", "", "", ""])
          setResendLoading(_ => false)
        }
      | None => setResendLoading(_ => false)
      }
    } catch {
    | _ => setResendLoading(_ => false)
    }
  }

  let handleOtpChange = (index, value) => {
    let focusInput = idx => {
      otpRefs[idx]
      ->Option.flatMap(ref => ref.current->Nullable.toOption)
      ->Option.forEach(input => input->ReactNative.TextInput.focus)
    }

    if String.length(value) > 1 {
      let digits = value->String.split("")->Array.filter(d => d >= "0" && d <= "9")
      let newOtp = otp->Array.mapWithIndex((_, i) => {
        if i >= index && i < index + Array.length(digits) {
          digits[i - index]->Option.getOr("")
        } else {
          otp[i]->Option.getOr("")
        }
      })
      setOtp(_ => newOtp)

      if newOtp->Array.every(d => d !== "") {
        submitOtp(~otpValue=newOtp)->ignore
      } else {
        let nextIndex = index + Array.length(digits) > 5 ? 5 : index + Array.length(digits)
        focusInput(nextIndex)
      }
    } else if String.length(value) == 1 && value >= "0" && value <= "9" {
      let newOtp = otp->Array.mapWithIndex((item, i) => i === index ? value : item)
      setOtp(_ => newOtp)

      if newOtp->Array.every(d => d !== "") {
        submitOtp(~otpValue=newOtp)->ignore
      } else if index < 5 {
        focusInput(index + 1)
      }
    } else if String.length(value) == 0 {
      let newOtp = otp->Array.mapWithIndex((item, i) => i === index ? "" : item)
      setOtp(_ => newOtp)
    }
  }

  let handleCheckout = async () => {
    try {
      let sdkRefValue = sdkRef.current->Nullable.toOption
      switch sdkRefValue {
      | Some(sdk) => {
          let checkoutParams: VisaSDK.checkoutParams = {
            srcDigitalCardId: srcId,
            payloadTypeIndicatorCheckout: "FULL",
            dpaTransactionOptions: {
              // authenticationPreferences: {
              //   authenticationMethods: [
              //     {
              //       authenticationMethodType: "3DS",
              //       authenticationSubject: "CARDHOLDER",
              //       methodAttributes: {
              //         challengeIndicator: "01",
              //       },
              //     },
              //   ],
              //   payloadRequested: "AUTHENTICATED",
              // },
              acquirerBIN: clickToPaySession
              ->Option.flatMap(session => session.acquirer_bin)
              ->Option.getOr(""),
              acquirerMerchantId: clickToPaySession
              ->Option.flatMap(session => session.acquirer_merchant_id)
              ->Option.getOr(""),
              merchantName: clickToPaySession
              ->Option.flatMap(session => session.dpa_name)
              ->Option.getOr(""),
            },
          }
          let _checkoutResponse = await VisaSDK.callFunction(sdk, "checkout", checkoutParams)
          // TODO: Handle checkout response and process payment
        }
      | None => {
          setComponentState(_ => CARDS_DISPLAY)
        }
      }
    } catch {
    | _ => {
        setComponentState(_ => CARDS_DISPLAY)
      }
    }
  }

  let switchIdentity = async (newEmail: string) => {
    try {
      setComponentState(_ => CARDS_LOADING)
      setShowNotYouScreen(_ => false)

      setCardsArray(_ => [])
      setSrcId(_ => "")

      let sdkRefValue = sdkRef.current->Nullable.toOption

      switch sdkRefValue {
      | Some(sdk) => {
          let _ = await VisaSDK.callFunction(sdk, "unbindAppInstance", null)
          let initParams: VisaSDK.initializeParams = {
            dpaTransactionOptions: {
              transactionAmount: {
                transactionAmount: clickToPaySession
                ->Option.flatMap(session => session.transaction_amount)
                ->Option.getOr(""),
                transactionCurrencyCode: clickToPaySession
                ->Option.flatMap(session => session.transaction_currency_code)
                ->Option.getOr(""),
              },
              dpaBillingPreference: "NONE",
              dpaAcceptedBillingCountries: ["US", "CA"],
              merchantCategoryCode: clickToPaySession
              ->Option.flatMap(session => session.merchant_category_code)
              ->Option.getOr(""),
              merchantCountryCode: clickToPaySession
              ->Option.flatMap(session => session.merchant_country_code)
              ->Option.getOr(""),
              payloadTypeIndicator: "FULL",
              merchantOrderId: "order_" ++ Date.now()->Float.toString,
              paymentOptions: [
                {
                  dpaDynamicDataTtlMinutes: 2,
                  dynamicDataType: "CARD_APPLICATION_CRYPTOGRAM_SHORT_FORM",
                },
              ],
              dpaLocale: clickToPaySession
              ->Option.flatMap(session => session.locale)
              ->Option.getOr(""),
            },
            correlationId: clickToPaySession
            ->Option.flatMap(session => session.dpa_id)
            ->Option.getOr(""),
          }

          let _ = await VisaSDK.callFunction(sdk, "initialize", initParams)

          let newConsumerIdentity: VisaSDK.consumerIdentity = {
            identityProvider: "SRC",
            identityValue: newEmail,
            identityType: "EMAIL_ADDRESS",
          }
          let getCardsParams: VisaSDK.getCardsParams = {
            consumerIdentity: newConsumerIdentity,
          }
          let cards = await VisaSDK.callFunction(sdk, "getCards", getCardsParams)
          handleGetCardsOutput(cards)
          setNewIdentifier(_ => "")
        }
      | None => setComponentState(_ => NONE)
      }
    } catch {
    | _ => {
        setComponentState(_ => NONE)
        setShowNotYouScreen(_ => true)
      }
    }
  }

  {
    sdkRef,
    sdkReady,
    setSdkReady,
    otp,
    setOtp,
    otpRefs,
    componentState,
    setComponentState,
    cardsArray,
    setCardsArray,
    srcId,
    setSrcId,
    showNotYouScreen,
    setShowNotYouScreen,
    newIdentifier,
    setNewIdentifier,
    resendLoading,
    setResendLoading,
    resendTimer,
    setResendTimer,
    rememberMe,
    setRememberMe,
    handleGetCardsOutput,
    initVisaClickToPayAndGetCards,
    submitOtp,
    resendOtp,
    handleOtpChange,
    handleCheckout,
    switchIdentity,
  }
}
