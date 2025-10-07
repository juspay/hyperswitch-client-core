open ReactNative
open ReactNative.Style
open VisaClickToPaySDK
open VisaClickToPayLogic

@react.component
let make = () => {
  let {borderRadius, component, primaryColor} = ThemebasedStyle.useThemeBasedStyle()

  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let clickToPaySession = switch allApiData.sessions {
  | Some(sessions) => sessions->Array.find(session => session.wallet_name == CLICK_TO_PAY)
  | _ => None
  }

  let {
    sdkRef,
    sdkReady,
    setSdkReady,
    otp,
    otpRefs,
    componentState,
    srcId,
    setSrcId,
    showNotYouScreen,
    setShowNotYouScreen,
    newIdentifier,
    setNewIdentifier,
    resendLoading,
    resendTimer,
    setResendTimer,
    rememberMe,
    setRememberMe,
    cardsArray,
    initVisaClickToPayAndGetCards,
    submitOtp,
    resendOtp,
    handleOtpChange,
    handleCheckout,
    switchIdentity,
  } = useVisaClickToPay(clickToPaySession)

  React.useEffect1(() => {
    if sdkReady {
      initVisaClickToPayAndGetCards()->ignore
    }
    None
  }, [sdkReady])

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
    if componentState == OTP_INPUT {
      otpRefs[0]
      ->Option.flatMap(ref => ref.current->Nullable.toOption)
      ->Option.forEach(input => input->ReactNative.TextInput.focus)
    }
    None
  }, [componentState])

  let cardBrands = switch clickToPaySession {
  | Some(session) =>
    session.card_brands
    ->Array.map(json => json->JSON.Decode.string->Option.getOr(""))
    ->Array.filter(brand => brand !== "")
  | None => []
  }

  let maskEmail = email => {
    switch email->String.split("@") {
    | [localPart, domain] => {
        let prefix = localPart->String.substring(~start=0, ~end=2)
        prefix ++ "•••@" ++ domain
      }
    | _ => email
    }
  }

  let maskedEmail = switch clickToPaySession {
  | Some(session) => session.email->Option.map(maskEmail)->Option.getOr("")
  | None => ""
  }

  <>
    {componentState == CARDS_LOADING
      ? <View
          style={s({
            flex: 1.,
            justifyContent: #center,
            alignItems: #center,
            paddingVertical: 40.->dp,
          })}>
          <VisaClickToPaySDK.SrcLoader height=200. width=200. />
        </View>
      : React.null}
    {componentState == OTP_INPUT || componentState == CARDS_DISPLAY
      ? <View style={s({marginVertical: 12.->dp})}>
          <View style={s({alignItems: #"flex-start", marginBottom: 12.->dp})}>
            {cardBrands->Array.length > 0
              ? <SrcMark cardBrands height=32. width=150. />
              : React.null}
          </View>
          {maskedEmail !== ""
            ? <View style={s({alignItems: #"flex-start", marginBottom: 16.->dp})}>
                <View style={s({flexDirection: #row, alignItems: #center})}>
                  <Text style={s({fontSize: 14., color: "#666", marginRight: 8.->dp})}>
                    {maskedEmail->React.string}
                  </Text>
                  <TouchableOpacity onPress={_ => setShowNotYouScreen(_ => true)}>
                    <Text style={s({fontSize: 14., color: "#007AFF"})}>
                      {"Not you?"->React.string}
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>
            : React.null}
          {componentState == OTP_INPUT
            ? <View style={s({marginTop: 8.->dp})}>
                <Text style={s({fontSize: 14., marginBottom: 12.->dp, fontWeight: #\"600"})}>
                  {"Enter verification code"->React.string}
                </Text>
            <View
              style={s({
                flexDirection: #row,
                justifyContent: #\"space-between",
                marginBottom: 16.->dp,
              })}>
              {[0, 1, 2, 3, 4, 5]
              ->Array.mapWithIndex((index, _) =>
                <TextInput
                  key={index->Int.toString}
                  ref={otpRefs[index]->Option.getExn->ReactNative.Ref.value}
                  style={s({
                    width: 45.->dp,
                    height: 50.->dp,
                    borderWidth: 2.,
                    borderColor: otp[index]->Option.getOr("") !== ""
                      ? primaryColor
                      : component.borderColor,
                    borderRadius,
                    textAlign: #center,
                    fontSize: 20.,
                    fontWeight: #\"600",
                    backgroundColor: component.background,
                    color: component.color,
                  })}
                  value={otp[index]->Option.getOr("")}
                  onChangeText={value => handleOtpChange(index, value)}
                  keyboardType=#numeric
                  maxLength=1
                  autoFocus={index === 0}
                  selectTextOnFocus=true
                />
              )
              ->React.array}
            </View>
            <TouchableOpacity
              onPress={_ => submitOtp()->ignore}
              disabled={otp->Array.some(d => d === "")}
              style={s({
                backgroundColor: otp->Array.some(d => d === "") ? "#CCC" : "#007AFF",
                padding: 14.->dp,
                borderRadius,
                alignItems: #center,
              })}>
              <Text style={s({color: "#FFFFFF", fontSize: 16., fontWeight: #\"600"})}>
                {"Continue"->React.string}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={_ => resendOtp()->ignore}
              disabled={resendTimer > 0 || resendLoading}
              style={s({marginTop: 12.->dp, alignItems: #center})}>
              <Text
                style={s({
                  fontSize: 14.,
                  color: resendTimer > 0 || resendLoading ? "#CCC" : "#007AFF",
                  fontWeight: #\"500",
                })}>
                {(resendTimer > 0
                    ? `Resend code in ${resendTimer->Int.toString}s`
                    : resendLoading
                    ? "Sending..."
                    : "Resend code")->React.string}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={_ => setRememberMe(prev => !prev)}
              style={s({
                flexDirection: #row,
                alignItems: #center,
                marginTop: 16.->dp,
              })}>
              <View
                style={s({
                  width: 20.->dp,
                  height: 20.->dp,
                  borderWidth: 2.,
                  borderColor: rememberMe ? "#007AFF" : "#CCC",
                  borderRadius: 3.,
                  marginRight: 8.->dp,
                  justifyContent: #center,
                  alignItems: #center,
                  backgroundColor: rememberMe ? "#007AFF" : "transparent",
                })}>
                {rememberMe
                  ? <Text style={s({color: "#FFFFFF", fontSize: 14., fontWeight: #bold})}>
                      {"\u2713"->React.string}
                    </Text>
                  : React.null}
              </View>
              <Text style={s({fontSize: 12., color: "#666"})}>
                {"Remember me on this browser"->React.string}
              </Text>
            </TouchableOpacity>
          </View>
        : React.null}
          {componentState == CARDS_DISPLAY
            ? <View style={s({marginTop: 12.->dp})}>
                {cardsArray
            ->Array.mapWithIndex((card, index) => {
              let cardDict = card->JSON.Decode.object->Option.getOr(Js.Dict.empty())
              let srcDigitalCardId =
                cardDict
                ->Js.Dict.get("srcDigitalCardId")
                ->Option.flatMap(JSON.Decode.string)
                ->Option.getOr("")
              let paymentCardDescriptor =
                cardDict
                ->Js.Dict.get("paymentCardDescriptor")
                ->Option.flatMap(JSON.Decode.string)
                ->Option.getOr("")
              let panLastFour =
                cardDict
                ->Js.Dict.get("panLastFour")
                ->Option.flatMap(JSON.Decode.string)
                ->Option.getOr("")
              let panExpirationMonth =
                cardDict
                ->Js.Dict.get("panExpirationMonth")
                ->Option.flatMap(JSON.Decode.string)
                ->Option.getOr("")
              let panExpirationYear =
                cardDict
                ->Js.Dict.get("panExpirationYear")
                ->Option.flatMap(JSON.Decode.string)
                ->Option.getOr("")

              let isSelected = srcId === srcDigitalCardId
              let isLastCard = index === cardsArray->Array.length - 1

              <TouchableOpacity
                key={index->Int.toString}
                onPress={_ => setSrcId(_ => srcDigitalCardId)}
                style={s({
                  minHeight: 60.->dp,
                  paddingVertical: 16.->dp,
                  borderBottomWidth: isLastCard ? 0. : 1.,
                  borderBottomColor: component.borderColor,
                  justifyContent: #center,
                })}>
                <View
                  style={s({
                    flexDirection: #row,
                    alignItems: #center,
                    justifyContent: #"space-between",
                  })}>
                  <View style={s({flexDirection: #row, alignItems: #center, maxWidth: 60.->pct})}>
                    <CustomRadioButton size=20.5 selected=isSelected color=primaryColor />
                    <Space />
                    <View style={s({flexDirection: #row, alignItems: #center})}>
                      <Icon
                        name={paymentCardDescriptor->String.toLowerCase}
                        height=25.
                        width=24.
                        style={s({marginEnd: 5.->dp})}
                      />
                      <TextWrapper
                        text={`•••• ${panLastFour}`}
                        textType={{CardTextBold}}
                      />
                    </View>
                  </View>
                  <TextWrapper
                    text={`${panExpirationMonth}/${panExpirationYear->String.slice(~start=-2, ~end=String.length(panExpirationYear))}`}
                    textType={{{ModalTextLight}}}
                  />
                </View>
              </TouchableOpacity>
            })
            ->React.array}
                {srcId !== ""
                  ? <TouchableOpacity
                      onPress={_ => handleCheckout()->ignore}
                      style={s({
                        backgroundColor: "#007AFF",
                        padding: 14.->dp,
                        borderRadius,
                        alignItems: #center,
                        marginTop: 12.->dp,
                      })}>
                      <Text style={s({color: "#FFFFFF", fontSize: 16., fontWeight: #\"600"})}>
                        {"Pay with Click to Pay"->React.string}
                      </Text>
                    </TouchableOpacity>
                  : React.null}
              </View>
            : React.null}
        </View>
      : React.null}
    <View
      style={s({
        position: #absolute,
        top: 0.->dp,
        left: 0.->dp,
        width: 1.->dp,
        height: 1.->dp,
        opacity: 0.,
        zIndex: -999,
      })}>
      <VisaSDK
        ref={sdkRef}
        style={s({
          height: 1.->dp,
          width: 1.->dp,
        })}
        onSDKReady={_ => setSdkReady(_ => true)}
        onError={_ => ()}
      />
    </View>
    {showNotYouScreen
      ? <View
          style={s({
            position: #absolute,
            top: 0.->dp,
            left: 0.->dp,
            right: 0.->dp,
            bottom: 0.->dp,
            backgroundColor: "white",
            padding: 16.->dp,
          })}>
          <TouchableOpacity
            onPress={_ => setShowNotYouScreen(_ => false)}
            style={s({marginBottom: 16.->dp})}>
            <Text style={s({fontSize: 16., color: "#007AFF"})}> {"← Back"->React.string} </Text>
          </TouchableOpacity>
          <View style={s({alignItems: #center, marginBottom: 16.->dp})}>
            {cardBrands->Array.length > 0
              ? <SrcMark cardBrands height=32. width=150. />
              : React.null}
          </View>
          <Text
            style={s({
              fontSize: 14.,
              color: "#666",
              textAlign: #center,
              marginBottom: 16.->dp,
            })}>
            {"Enter a new email or mobile number to access a different set of linked cards."->React.string}
          </Text>
          <TextInput
            value=newIdentifier
            onChangeText={value => setNewIdentifier(_ => value)}
            placeholder="Enter email"
            keyboardType=#"email-address"
            autoCapitalize=#none
            style={s({
              borderWidth: 1.,
              borderColor: component.borderColor,
              borderRadius,
              padding: 12.->dp,
              fontSize: 14.,
              marginBottom: 16.->dp,
              backgroundColor: component.background,
            })}
          />
          <TouchableOpacity
            onPress={_ => {
              switchIdentity(newIdentifier)->ignore
            }}
            disabled={newIdentifier === ""}
            style={s({
              backgroundColor: newIdentifier === "" ? "#CCC" : "#007AFF",
              padding: 14.->dp,
              borderRadius,
              alignItems: #center,
            })}>
            <Text style={s({color: "#FFFFFF", fontSize: 16., fontWeight: #\"600"})}>
              {"Switch ID"->React.string}
            </Text>
          </TouchableOpacity>
        </View>
      : React.null}
  </>
}
