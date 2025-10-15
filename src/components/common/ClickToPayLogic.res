type screenState = NONE | LOADING | OTP_INPUT | CARDS_DISPLAY | NOT_YOU

type clickToPayUIState = {
  screenState: screenState,
  setScreenState: (screenState => screenState) => unit,
  previousScreenState: screenState,
  setPreviousScreenState: (screenState => screenState) => unit,
  clickToPay: ClickToPay.Types.clickToPayHook,
  otp: array<string>,
  setOtp: (array<string> => array<string>) => unit,
  otpRefs: array<option<React.ref<Nullable.t<ReactNative.TextInput.element>>>>,
  maskedChannel: option<string>,
  setMaskedChannel: (option<string> => option<string>) => unit,
  resendTimer: int,
  setResendTimer: (int => int) => unit,
  resendLoading: bool,
  setResendLoading: (bool => bool) => unit,
  rememberMe: bool,
  setRememberMe: (bool => bool) => unit,
  otpError: string,
  setOtpError: (string => string) => unit,
  selectedCardId: option<string>,
  setSelectedCardId: (option<string> => option<string>) => unit,
  newIdentifier: string,
  setNewIdentifier: (string => string) => unit,
  userIdentity: option<ClickToPay.Types.userIdentity>,
  setUserIdentity: (
    option<ClickToPay.Types.userIdentity> => option<ClickToPay.Types.userIdentity>
  ) => unit,
  handleOtpChange: (int, string) => unit,
  handleKeyPress: (int, ReactNative.TextInput.KeyPressEvent.t) => unit,
  submitOtp: unit => promise<unit>,
  resendOtp: unit => promise<unit>,
  handleCheckout: unit => promise<JSON.t>,
  switchIdentity: string => promise<unit>,
}

let useClickToPayUI = () => {
  let clickToPay = ClickToPay.useClickToPay()

  let (screenState, setScreenState) = React.useState(() => NONE)
  let (previousScreenState, setPreviousScreenState) = React.useState(() => OTP_INPUT)
  let (otp, setOtp) = React.useState(() => ["", "", "", "", "", ""])
  let (maskedChannel, setMaskedChannel) = React.useState(() => None)
  let (resendTimer, setResendTimer) = React.useState(() => 0)
  let (resendLoading, setResendLoading) = React.useState(() => false)
  let (rememberMe, setRememberMe) = React.useState(() => false)
  let (otpError, setOtpError) = React.useState(() => "NONE")
  let (selectedCardId, setSelectedCardId) = React.useState(() => None)
  let (newIdentifier, setNewIdentifier) = React.useState(() => "")
  let (userIdentity, setUserIdentity) = React.useState(() => None)

  let otpRef0 = React.useRef(Nullable.null)
  let otpRef1 = React.useRef(Nullable.null)
  let otpRef2 = React.useRef(Nullable.null)
  let otpRef3 = React.useRef(Nullable.null)
  let otpRef4 = React.useRef(Nullable.null)
  let otpRef5 = React.useRef(Nullable.null)
  let otpRefs = [
    Some(otpRef0),
    Some(otpRef1),
    Some(otpRef2),
    Some(otpRef3),
    Some(otpRef4),
    Some(otpRef5),
  ]

  React.useEffect1(() => {
    if resendTimer > 0 {
      let timerId = setTimeout(() => {
        setResendTimer(prev => prev - 1)
      }, 1000)
      Some(() => clearTimeout(timerId))
    } else {
      None
    }
  }, [resendTimer])

  React.useEffect1(() => {
    if clickToPay.cards->Array.length > 0 && selectedCardId === None {
      clickToPay.cards
      ->Array.get(0)
      ->Option.forEach(card => setSelectedCardId(_ => Some(card.id)))
    }
    None
  }, [clickToPay.cards])

  let submitOtp = async () => {
    try {
      setScreenState(_ => LOADING)
      setOtpError(_ => "NONE")
      let otpString = otp->Array.join("")
      let cards = await clickToPay.authenticate(otpString)

      if cards->Array.length > 0 {
        setOtp(_ => ["", "", "", "", "", ""])
        setScreenState(_ => CARDS_DISPLAY)
      } else {
        setOtpError(_ => "VALIDATION_DATA_INVALID")
        setScreenState(_ => OTP_INPUT)
      }
    } catch {
    | _ => {
        setOtpError(_ => "VALIDATION_DATA_INVALID")
        setScreenState(_ => OTP_INPUT)
      }
    }
  }

  let handleOtpChange = (index, value) => {
    if otpError !== "NONE" {
      setOtpError(_ => "NONE")
    }

    let focusInput = idx => {
      otpRefs
      ->Array.get(idx)
      ->Option.flatMap(optRef => optRef)
      ->Option.flatMap(ref => ref.current->Nullable.toOption)
      ->Option.forEach(input => input->ReactNative.TextInput.focus)
    }

    if String.length(value) > 1 {
      let digits =
        value
        ->String.split("")
        ->Array.filter(d => d >= "0" && d <= "9")
        ->Array.slice(~start=0, ~end=6)

      let newOtp = otp->Array.mapWithIndex((_, i) => {
        if i < Array.length(digits) {
          digits[i]->Option.getOr("")
        } else {
          ""
        }
      })
      setOtp(_ => newOtp)

      let nextIndex = Array.length(digits) >= 6 ? 5 : Array.length(digits)
      focusInput(nextIndex)
    } else if String.length(value) == 1 && value >= "0" && value <= "9" {
      let newOtp = otp->Array.mapWithIndex((item, i) => i === index ? value : item)
      setOtp(_ => newOtp)

      if index < 5 {
        focusInput(index + 1)
      }
    } else if String.length(value) == 0 {
      let newOtp = otp->Array.mapWithIndex((item, i) => i === index ? "" : item)
      setOtp(_ => newOtp)
    }
  }

  let handleKeyPress = (index, event: ReactNative.TextInput.KeyPressEvent.t) => {
    if otpError !== "NONE" {
      setOtpError(_ => "NONE")
    }
    if event.nativeEvent.key == "Backspace" {
      let newOtp = otp->Array.mapWithIndex((item, i) => i === index ? "" : item)
      setOtp(_ => newOtp)
      if index > 0 {
        otpRefs
        ->Array.get(index - 1)
        ->Option.flatMap(optRef => optRef)
        ->Option.flatMap(ref => ref.current->Nullable.toOption)
        ->Option.forEach(input => input->ReactNative.TextInput.focus)
      }
    }
  }

  let resendOtp = async () => {
    try {
      setResendLoading(_ => true)
      setResendTimer(_ => 30)
      setOtpError(_ => "NONE")

      switch userIdentity {
      | Some(identity) => {
          let _result = await clickToPay.validate(identity)
          setOtp(_ => ["", "", "", "", "", ""])
          setResendLoading(_ => false)
        }
      | None => setResendLoading(_ => false)
      }
    } catch {
    | _ => {
        setResendLoading(_ => false)
        setOtpError(_ => "OTP_SEND_FAILED")
      }
    }
  }

  let handleCheckout = async () => {
    try {
      setScreenState(_ => LOADING)

      switch selectedCardId {
      | Some(cardId) => {
          let checkoutParams: ClickToPay.Types.checkoutParams = {
            srcDigitalCardId: cardId,
            amount: "99.99",
            currency: "USD",
            orderId: "order-" ++ Js.Date.now()->Float.toString,
            rememberMe,
          }

          let result = await clickToPay.checkout(checkoutParams)
          result
        }
      | None => {
          setScreenState(_ => CARDS_DISPLAY)
          JSON.Encode.null
        }
      }
    } catch {
    | error => {
        Console.error2("[ClickToPay] Checkout error:", error)
        setScreenState(_ => CARDS_DISPLAY)
        JSON.Encode.null
      }
    }
  }

  let switchIdentity = async (newEmail: string) => {
    try {
      setScreenState(_ => LOADING)

      let newUserIdentity: ClickToPay.Types.userIdentity = {
        value: newEmail,
        type_: "EMAIL_ADDRESS",
      }

      setUserIdentity(_ => Some(newUserIdentity))
      let result = await clickToPay.validate(newUserIdentity)

      switch (result.requiresOTP, result.cards) {
      | (Some(true), _) => {
          setMaskedChannel(_ => result.maskedValidationChannel)
          setScreenState(_ => OTP_INPUT)
        }
      | (_, Some(cards)) if cards->Array.length > 0 => setScreenState(_ => CARDS_DISPLAY)
      | _ => setScreenState(_ => NONE)
      }

      setNewIdentifier(_ => "")
    } catch {
    | _ => setScreenState(_ => NOT_YOU)
    }
  }

  {
    screenState,
    setScreenState,
    previousScreenState,
    setPreviousScreenState,
    clickToPay,
    otp,
    setOtp,
    otpRefs,
    maskedChannel,
    setMaskedChannel,
    resendTimer,
    setResendTimer,
    resendLoading,
    setResendLoading,
    rememberMe,
    setRememberMe,
    otpError,
    setOtpError,
    selectedCardId,
    setSelectedCardId,
    newIdentifier,
    setNewIdentifier,
    userIdentity,
    setUserIdentity,
    handleOtpChange,
    handleKeyPress,
    submitOtp,
    resendOtp,
    handleCheckout,
    switchIdentity,
  }
}
