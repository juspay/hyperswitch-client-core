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

  let maskedEmail = React.useMemo1(() => {
    switch sessionTokenData {
    | Some(sessionData) =>
      sessionData
      ->Array.find(item => item.wallet_name == CLICK_TO_PAY)
      ->Option.flatMap(session => session.email)
      ->Option.map(email => {
        let parts = email->String.split("@")
        switch parts {
        | [username, domain] =>
          let maskedUsername =
            username->String.length > 2
              ? username->String.substring(~start=0, ~end=2) ++ "***"
              : username
          maskedUsername ++ "@" ++ domain
        | _ => email
        }
      })
    | None => None
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
      | Some("mastercard") => #visa // change it to mastercard while pushing.
      | Some("visa") => #visa
      | _ => #visa
      }

      let cardBrands =
        sessionObject.card_brands
        ->Array.map(brand => brand->JSON.Decode.string->Option.getOr(""))
        ->Array.filter(brand => brand != "")
        ->Array.join(",")

      let clickToPayConfig: ClickToPay.Types.clickToPayConfig = {
        dpaId: "498WCF39JVQVH1UK4TGG21leLAj_MJQoapP5f12IanfEYaSno", //sessionObject.dpa_id->Option.getOr(""),
        environment: #sandbox,
        provider,
        locale: ?sessionObject.locale,
        cardBrands: cardBrands != "" ? cardBrands : "visa,mastercard",
        clientId: ?sessionObject.dpa_name,
        transactionAmount: ?sessionObject.transaction_amount,
        transactionCurrency: ?sessionObject.transaction_currency_code,
        timeout: 3000,
        // debug: nativeProp.env != "live",
      }

      if clickToPayUI.clickToPay.config->Nullable.isNullable {
        clickToPayUI.setScreenState(_ => ClickToPayLogic.LOADING)

        clickToPayUI.clickToPay.initialize(clickToPayConfig)
        ->Promise.then(() => {
          Console.log("[ClickToPay] SDK initialized successfully")
          Promise.resolve()
        })
        ->Promise.catch(error => {
          Console.error2("[ClickToPay] Error initializing SDK:", error)
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
            Console.log2("[ClickToPay] Validation result:", result)

            switch (result.requiresOTP, result.requiresNewCard, result.cards) {
            | (Some(true), _, _) => {
                Console.log("[ClickToPay] OTP required")
                clickToPayUI.setMaskedChannel(_ => result.maskedValidationChannel)
                clickToPayUI.setScreenState(_ => ClickToPayLogic.OTP_INPUT)
              }
            | (_, Some(true), _) => {
                Console.log("[ClickToPay] Add card flow required")
                onRequiresNewCard()
              }
            | (_, _, Some(cards)) if cards->Array.length > 0 => {
                Console.log("[ClickToPay] Cards fetched successfully")
                clickToPayUI.setScreenState(_ => ClickToPayLogic.CARDS_DISPLAY)
              }
            | _ => {
                Console.log("[ClickToPay] No cards found")
                clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)
                showAlert(~errorType="warning", ~message="No cards found")
              }
            }

            Promise.resolve()
          })
          ->Promise.catch(error => {
            Console.error2("[ClickToPay] Validation error:", error)
            clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)
            Promise.resolve()
          })
          ->ignore
        } else {
          Console.warn("[ClickToPay] No email found in session token")
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
          ?maskedEmail
          otp=clickToPayUI.otp
          otpRefs=clickToPayUI.otpRefs
          handleOtpChange=clickToPayUI.handleOtpChange
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
          ?maskedEmail
          onNotYouPress={() => {
            clickToPayUI.setPreviousScreenState(_ => ClickToPayLogic.CARDS_DISPLAY)
            clickToPayUI.setScreenState(_ => ClickToPayLogic.NOT_YOU)
          }}
          disabled={clickToPayUI.screenState == ClickToPayLogic.LOADING}
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
          cardBrands=[]
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
