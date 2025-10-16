open ReactNative
open Style

type clickToPayUIState = {
  selectedCardId: option<string>,
  handleCheckout: unit => Promise.t<JSON.t>,
  screenState: ClickToPayLogic.screenState,
}

@react.component
let make = (
  ~sessionTokenData: option<array<SessionsType.sessions>>,
  ~onClearSavedPayment: unit => unit,
  ~onStateChange: clickToPayUIState => unit,
  ~onRequiresNewCard: unit => unit,
) => {
  let clickToPayUI = ClickToPayLogic.useClickToPayUI()

  let hasValidated = React.useRef(false)
  let showAlert = AlertHook.useAlerts()

  let (userEmail, maskedPhone) = React.useMemo2(() => {
    switch (clickToPayUI.userIdentity, clickToPayUI.maskedChannel) {
    | (Some(identity), Some(channel)) =>
      if channel->String.includes("@") {
        (Some(identity.value), None)
      } else {
        (Some(identity.value), Some(channel))
      }
    | (Some(identity), None) => (Some(identity.value), None)
    | (None, Some(channel)) =>
      if channel->String.includes("@") {
        (Some(channel), None)
      } else {
        (None, Some(channel))
      }
    | (None, None) => (None, None)
    }
  }, (clickToPayUI.userIdentity, clickToPayUI.maskedChannel))

  let cardBrands = React.useMemo1(() => {
    switch sessionTokenData {
    | Some(sessionData) =>
      sessionData
      ->Array.find(item => item.wallet_name == CLICK_TO_PAY)
      ->Option.map(session =>
        session.card_brands
        ->Array.map(brand => brand->JSON.Decode.string->Option.getOr(""))
        ->Array.filter(brand => brand != "")
      )
      ->Option.getOr([])
    | None => []
    }
  }, [sessionTokenData])

  let {
    borderWidth,
    borderRadius,
    component,
    shadowIntensity,
    shadowColor,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

  let setClickToPayCardAndClearSaved = React.useCallback2(cardId => {
    clickToPayUI.setSelectedCardId(cardId)
    onClearSavedPayment()
  }, (clickToPayUI.setSelectedCardId, onClearSavedPayment))

  // Initialize Click to Pay when session token data is available
  React.useEffect1(() => {
    let clickToPaySessionObject = switch sessionTokenData {
    | Some(sessionData) => sessionData->Array.find(item => item.wallet_name == CLICK_TO_PAY)
    | _ => None
    }

    switch clickToPaySessionObject {
    | Some(sessionObject) =>
      let provider = switch sessionObject.provider {
      | Some("mastercard") => #mastercard
      | Some("visa") => #visa
      | _ => #visa
      }

      let cardBrands =
        sessionObject.card_brands
        ->Array.map(brand => brand->JSON.Decode.string->Option.getOr(""))
        ->Array.filter(brand => brand != "")
        ->Array.join(",")

      let clickToPayConfig: ClickToPay.Types.clickToPayConfig = {
        dpaId: sessionObject.dpa_id->Option.getOr(""),
        environment: #sandbox,
        provider,
        locale: ?sessionObject.locale,
        cardBrands: cardBrands != "" ? cardBrands : "visa,mastercard",
        clientId: ?sessionObject.dpa_name,
        transactionAmount: ?sessionObject.transaction_amount,
        transactionCurrency: ?sessionObject.transaction_currency_code,
        // timeout: 150000,
      }

      if clickToPayUI.clickToPay.config->Nullable.isNullable {
        clickToPayUI.setScreenState(_ => ClickToPayLogic.LOADING)

        clickToPayUI.clickToPay.initialize(clickToPayConfig)
        ->Promise.then(() => {
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)
          Promise.resolve()
        })
        ->ignore
      }
    | None => ()
    }

    None
  }, [sessionTokenData])

  // Validate user identity after initialization
  React.useEffect2(() => {
    let clickToPaySessionObject = switch sessionTokenData {
    | Some(sessionData) => sessionData->Array.find(item => item.wallet_name == CLICK_TO_PAY)
    | _ => None
    }

    switch clickToPaySessionObject {
    | Some(sessionObject) =>
      if (
        !clickToPayUI.clickToPay.isLoading &&
        !(clickToPayUI.clickToPay.config->Nullable.isNullable) &&
        !hasValidated.current
      ) {
        hasValidated.current = true

        let emailValue = sessionObject.email->Option.getOr("")

        if emailValue != "" {
          let userIdentity: ClickToPay.Types.userIdentity = {
            value: emailValue,
            type_: "EMAIL_ADDRESS",
          }

          clickToPayUI.setUserIdentity(_ => Some(userIdentity))

          clickToPayUI.clickToPay.validate(userIdentity)
          ->Promise.then(result => {
            switch (result.requiresOTP, result.requiresNewCard, result.cards) {
            | (Some(true), _, _) => {
                clickToPayUI.setMaskedChannel(_ => result.maskedValidationChannel)
                clickToPayUI.setScreenState(_ => ClickToPayLogic.OTP_INPUT)
              }
            | (_, Some(true), _) => onRequiresNewCard()
            | (_, _, Some(cards)) if cards->Array.length > 0 =>
              clickToPayUI.setScreenState(_ => ClickToPayLogic.CARDS_DISPLAY)
            | _ => {
                clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)
                showAlert(~errorType="warning", ~message="No cards found")
              }
            }

            Promise.resolve()
          })
          ->Promise.catch(_ => {
            clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)
            Promise.resolve()
          })
          ->ignore
        } else {
          clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)
        }
      }
    | None => ()
    }

    None
  }, (clickToPayUI.clickToPay.isLoading, sessionTokenData))

  // Notify parent component when Click to Pay state changes
  React.useEffect2(() => {
    let state: clickToPayUIState = {
      selectedCardId: clickToPayUI.selectedCardId,
      handleCheckout: clickToPayUI.handleCheckout,
      screenState: clickToPayUI.screenState,
    }
    onStateChange(state)
    None
  }, (clickToPayUI.selectedCardId, clickToPayUI.screenState))

  <>
    {switch clickToPayUI.screenState {
    | ClickToPayLogic.OTP_INPUT =>
      <View
        style={array([
          getShadowStyle,
          s({
            paddingHorizontal: 16.->dp,
            paddingVertical: 16.->dp,
            borderRadius,
            borderWidth,
            borderColor: component.borderColor,
            backgroundColor: component.background,
          }),
        ])}>
        <ClickToPayOTPScreen
          ?userEmail
          ?maskedPhone
          otp=clickToPayUI.otp
          otpRefs=clickToPayUI.otpRefs
          handleOtpChange=clickToPayUI.handleOtpChange
          handleKeyPress=clickToPayUI.handleKeyPress
          onSubmit={() => clickToPayUI.submitOtp()->ignore}
          onNotYouPress={() => {
            clickToPayUI.setPreviousScreenState(_ => ClickToPayLogic.OTP_INPUT)
            clickToPayUI.setScreenState(_ => ClickToPayLogic.NOT_YOU)
          }}
          resendOtp=clickToPayUI.resendOtp
          resendTimer=clickToPayUI.resendTimer
          resendLoading=clickToPayUI.resendLoading
          rememberMe=clickToPayUI.rememberMe
          setRememberMe=clickToPayUI.setRememberMe
          otpError=clickToPayUI.otpError
          disabled={clickToPayUI.screenState == ClickToPayLogic.LOADING}
          cardBrands
        />
      </View>
    | ClickToPayLogic.CARDS_DISPLAY =>
      <View
        style={array([
          getShadowStyle,
          s({
            paddingHorizontal: 16.->dp,
            paddingVertical: 16.->dp,
            borderRadius,
            borderWidth,
            borderColor: component.borderColor,
            backgroundColor: component.background,
          }),
        ])}>
        <ClickToPayCardsScreen
          cards=clickToPayUI.clickToPay.cards
          selectedCardId=clickToPayUI.selectedCardId
          setSelectedCardId=setClickToPayCardAndClearSaved
          onNotYouPress={() => {
            clickToPayUI.setPreviousScreenState(_ => ClickToPayLogic.CARDS_DISPLAY)
            clickToPayUI.setScreenState(_ => ClickToPayLogic.NOT_YOU)
          }}
          disabled={clickToPayUI.screenState == ClickToPayLogic.LOADING}
          cardBrands
        />
      </View>
    | ClickToPayLogic.LOADING =>
      <View
        style={array([
          getShadowStyle,
          s({
            paddingHorizontal: 16.->dp,
            paddingVertical: 16.->dp,
            borderRadius,
            borderWidth,
            borderColor: component.borderColor,
            backgroundColor: component.background,
          }),
        ])}>
        <ClickToPayShimmer />
      </View>
    | ClickToPayLogic.NOT_YOU =>
      <View
        style={array([
          getShadowStyle,
          s({
            paddingHorizontal: 16.->dp,
            paddingVertical: 16.->dp,
            borderRadius,
            borderWidth,
            borderColor: component.borderColor,
            backgroundColor: component.background,
          }),
        ])}>
        <ClickToPayNotYouScreen
          newIdentifier=clickToPayUI.newIdentifier
          setNewIdentifier=clickToPayUI.setNewIdentifier
          onBack={() => clickToPayUI.setScreenState(_ => clickToPayUI.previousScreenState)}
          onSwitch={email => clickToPayUI.switchIdentity(email)->ignore}
          cardBrands
          disabled={clickToPayUI.screenState == ClickToPayLogic.LOADING}
        />
      </View>
    | _ => React.null
    }}
  </>
}

// Export a function to be used by parent to check if Click to Pay is active
let shouldShowClickToPay = (sessionTokenData: option<array<SessionsType.sessions>>) => {
  switch sessionTokenData {
  | Some(sessionData) => sessionData->Array.some(item => item.wallet_name == CLICK_TO_PAY)
  | _ => false
  }
}
