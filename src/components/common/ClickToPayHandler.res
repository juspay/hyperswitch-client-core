open ReactNative
open Style

type clickToPayUIState = {screenState: ClickToPayHooks.screenState}

@react.component
let make = (
  ~sessionTokenData: option<array<SessionsType.sessions>>,
  ~onStateChange: clickToPayUIState => unit,
  ~selectedToken: option<CustomerPaymentMethodType.customer_payment_method_type>,
  ~setSelectedToken: option<CustomerPaymentMethodType.customer_payment_method_type> => unit,
  ~clickToPayUI: ClickToPayHooks.clickToPayUIState,
) => {
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

  let clickToPaySessionObject = switch sessionTokenData {
  | Some(sessionData) => sessionData->Array.find(item => item.wallet_name == CLICK_TO_PAY)
  | _ => None
  }

  let provider = switch clickToPaySessionObject {
  | Some(session) =>
    switch session.provider {
    | Some("mastercard") => #mastercard
    | Some("visa") => #visa
    | _ => #visa
    }
  | None => #visa
  }

  React.useEffect1(() => {
    let state: clickToPayUIState = {
      screenState: clickToPayUI.screenState,
    }
    onStateChange(state)
    None
  }, [clickToPayUI.screenState])

  <>
    {switch clickToPayUI.screenState {
    | ClickToPayHooks.OTP_INPUT =>
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
            clickToPayUI.setOtp(_ => ["", "", "", "", "", ""])
            clickToPayUI.setOtpError(_ => "NONE")
            clickToPayUI.setPreviousScreenState(_ => ClickToPayHooks.OTP_INPUT)
            clickToPayUI.setScreenState(_ => ClickToPayHooks.NOT_YOU)
          }}
          resendOtp=clickToPayUI.resendOtp
          resendTimer=clickToPayUI.resendTimer
          resendLoading=clickToPayUI.resendLoading
          rememberMe=clickToPayUI.rememberMe
          setRememberMe=clickToPayUI.setRememberMe
          otpError=clickToPayUI.otpError
          disabled={clickToPayUI.screenState == ClickToPayHooks.LOADING}
          cardBrands
        />
      </View>
    | ClickToPayHooks.CARDS_DISPLAY =>
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
          selectedToken
          setSelectedToken
          onNotYouPress={() => {
            clickToPayUI.setPreviousScreenState(_ => ClickToPayHooks.CARDS_DISPLAY)
            clickToPayUI.setScreenState(_ => ClickToPayHooks.NOT_YOU)
          }}
          disabled={clickToPayUI.screenState == ClickToPayHooks.LOADING}
          cardBrands
          provider
        />
      </View>
    | ClickToPayHooks.LOADING =>
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
    | ClickToPayHooks.NOT_YOU =>
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
          onBack={() => clickToPayUI.setScreenState(_ => clickToPayUI.previousScreenState)}
          onSwitch={email => clickToPayUI.switchIdentity(email)->ignore}
          cardBrands
          disabled={clickToPayUI.screenState == ClickToPayHooks.LOADING}
          showBackButton={clickToPayUI.previousScreenState != ClickToPayHooks.NONE}
        />
      </View>
    | _ => React.null
    }}
  </>
}

let shouldShowClickToPay = (sessionTokenData: option<array<SessionsType.sessions>>) => {
  switch sessionTokenData {
  | Some(sessionData) => sessionData->Array.some(item => item.wallet_name == CLICK_TO_PAY)
  | _ => false
  }
}
