type screenState = LOADING | OTP_INPUT | CARDS_DISPLAY | NOT_YOU | NONE

// Return types for each hook
type otpManagementState = {
  otp: array<string>,
  setOtp: (array<string> => array<string>) => unit,
  otpRefs: array<option<React.ref<Nullable.t<ReactNative.TextInput.element>>>>,
  resendTimer: int,
  setResendTimer: (int => int) => unit,
  resendLoading: bool,
  setResendLoading: (bool => bool) => unit,
  otpError: string,
  setOtpError: (string => string) => unit,
  handleOtpChange: (int, string) => unit,
  handleKeyPress: (int, ReactNative.TextInput.KeyPressEvent.t) => unit,
  submitOtp: unit => promise<unit>,
  resendOtp: unit => promise<unit>,
}

type identityManagementState = {
  newIdentifier: string,
  setNewIdentifier: (string => string) => unit,
  switchIdentity: string => promise<unit>,
}

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
  handleCheckout: option<CustomerPaymentMethodType.customer_payment_method_type> => promise<JSON.t>,
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
  switchIdentity: string => promise<unit>,
}

let useOTPManagement = (
  ~clickToPay: ClickToPay.Types.clickToPayHook,
  ~userIdentity: option<ClickToPay.Types.userIdentity>,
  ~setScreenState: (screenState => screenState) => unit,
) => {
  let (otp, setOtp) = React.useState(() => ["", "", "", "", "", ""])
  let (resendTimer, setResendTimer) = React.useState(() => 0)
  let (resendLoading, setResendLoading) = React.useState(() => false)
  let (otpError, setOtpError) = React.useState(() => "NONE")

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

  {
    otp,
    setOtp,
    otpRefs,
    resendTimer,
    setResendTimer,
    resendLoading,
    setResendLoading,
    otpError,
    setOtpError,
    handleOtpChange,
    handleKeyPress,
    submitOtp,
    resendOtp,
  }
}

let useIdentityManagement = (
  ~clickToPay: ClickToPay.Types.clickToPayHook,
  ~setScreenState: (screenState => screenState) => unit,
  ~setMaskedChannel: (option<string> => option<string>) => unit,
  ~setUserIdentity: (
    option<ClickToPay.Types.userIdentity> => option<ClickToPay.Types.userIdentity>
  ) => unit,
) => {
  let (newIdentifier, setNewIdentifier) = React.useState(() => "")

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
    newIdentifier,
    setNewIdentifier,
    switchIdentity,
  }
}

let useClickToPayUI = () => {
  let clickToPay = ClickToPay.useClickToPay()

  let (screenState, setScreenState) = React.useState(() => NONE)
  let (previousScreenState, setPreviousScreenState) = React.useState(() => OTP_INPUT)
  let (rememberMe, setRememberMe) = React.useState(() => false)

  let (userIdentity, setUserIdentity) = React.useState(() => None)
  let (maskedChannel, setMaskedChannel) = React.useState(() => None)

  let otpManagement = useOTPManagement(~clickToPay, ~userIdentity, ~setScreenState)

  let handleCheckout = React.useCallback3(
    async (selectedToken: option<CustomerPaymentMethodType.customer_payment_method_type>) => {
      try {
        setScreenState(_ => LOADING)

        switch selectedToken {
        | Some(card) => {
            let checkoutParams: ClickToPay.Types.checkoutParams = {
              srcDigitalCardId: card.payment_method_id,
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
      | _ => {
          setScreenState(_ => CARDS_DISPLAY)
          JSON.Encode.null
        }
      }
    },
    (rememberMe, setScreenState, clickToPay),
  )

  let identityManagement = useIdentityManagement(
    ~clickToPay,
    ~setScreenState,
    ~setMaskedChannel,
    ~setUserIdentity,
  )

  {
    screenState,
    setScreenState,
    previousScreenState,
    setPreviousScreenState,
    clickToPay,
    otp: otpManagement.otp,
    setOtp: otpManagement.setOtp,
    otpRefs: otpManagement.otpRefs,
    maskedChannel,
    setMaskedChannel,
    resendTimer: otpManagement.resendTimer,
    setResendTimer: otpManagement.setResendTimer,
    resendLoading: otpManagement.resendLoading,
    setResendLoading: otpManagement.setResendLoading,
    rememberMe,
    setRememberMe,
    handleCheckout,
    otpError: otpManagement.otpError,
    setOtpError: otpManagement.setOtpError,
    newIdentifier: identityManagement.newIdentifier,
    setNewIdentifier: identityManagement.setNewIdentifier,
    userIdentity,
    setUserIdentity,
    handleOtpChange: otpManagement.handleOtpChange,
    handleKeyPress: otpManagement.handleKeyPress,
    submitOtp: otpManagement.submitOtp,
    resendOtp: otpManagement.resendOtp,
    switchIdentity: identityManagement.switchIdentity,
  }
}
