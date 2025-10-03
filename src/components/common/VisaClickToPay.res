open ReactNative
open ReactNative.Style

module VisaSDK = {
  type visaSDKRef
  type methods = array<string>

  type dpaTransactionOptions = {
    transactionAmount: {"transactionAmount": string, "transactionCurrencyCode": string},
    dpaBillingPreference: string,
    dpaAcceptedBillingCountries: array<string>,
    merchantCategoryCode: string,
    merchantCountryCode: string,
    payloadTypeIndicator: string,
    merchantOrderId: string,
    paymentOptions: array<{"dpaDynamicDataTtlMinutes": int, "dynamicDataType": string}>,
    dpaLocale: string,
  }

  type initializeParams = {
    dpaTransactionOptions: dpaTransactionOptions,
    correlationId: string,
  }

  type consumerIdentity = {
    identityProvider: string,
    identityValue: string,
    identityType: string,
  }

  type getCardsParams = {
    consumerIdentity: consumerIdentity,
    validationData?: string,
  }

  type maskedCard = {
    srcDigitalCardId: string,
    paymentCardDescriptor: string,
    panLastFour: string,
    panExpirationMonth: string,
    panExpirationYear: string,
  }

  type checkoutParams = {
    srcDigitalCardId: string,
    payloadTypeIndicatorCheckout: string,
    dpaTransactionOptions: {
      "authenticationPreferences": {
        "authenticationMethods": array<{
          "authenticationMethodType": string,
          "authenticationSubject": string,
          "methodAttributes": {"challengeIndicator": string},
        }>,
        "payloadRequested": string,
      },
      "acquirerBIN": string,
      "acquirerMerchantId": string,
      "merchantName": string,
    },
  }

  @module("react-native-hyperswitch-click-to-pay") @react.component
  external make: (
    ~ref: React.ref<Nullable.t<visaSDKRef>>=?,
    ~onSDKReady: methods => unit=?,
    ~onError: {..} => unit=?,
  ) => React.element = "VisaSDKIntegration"

  @send external callFunction: (visaSDKRef, string, 'a) => promise<'b> = "callFunction"
}

@react.component
let make = () => {
  let sdkRef = React.useRef(Nullable.null)
  let (sdkReady, setSdkReady) = React.useState(() => false)
  let (otp, setOtp) = React.useState(() => ["", "", "", "", "", ""])
  let (showOtpInput, setShowOtpInput) = React.useState(() => false)
  let (cardsArray, setCardsArray) = React.useState(() => [])
  let (srcId, setSrcId) = React.useState(() => "")
  let (isLoading, setIsLoading) = React.useState(() => false)
  let {borderRadius, component} = ThemebasedStyle.useThemeBasedStyle()


  let consumerIdentity: VisaSDK.consumerIdentity = {
    identityProvider: "SRC",
    identityValue: "pradeep.kumar@juspay.in",
    identityType: "EMAIL_ADDRESS",
  }

  let handleGetCardsOutput = cards => {
  open Belt.Option

  let actionCode = cards->Js.Dict.get("actionCode")->flatMap(JSON.Decode.string)

  switch actionCode {
  | Some("PENDING_CONSUMER_IDV") => setShowOtpInput(_ => true)
  | Some("SUCCESS") =>
    setShowOtpInput(_ => false)

    let maskedCards =
      cards
      ->Js.Dict.get("profiles")
      ->flatMap(JSON.Decode.array)
      ->flatMap(arr => Array.get(arr, 0))
      ->flatMap(JSON.Decode.object)
      ->flatMap(profile => profile->Js.Dict.get("maskedCards"))
      ->flatMap(JSON.Decode.array)

    switch maskedCards {
    | Some(cards) => setCardsArray(_ => cards)
    | None => ()
    }
  | _ => setShowOtpInput(_ => false)
  }
}

  let initVisaClickToPayAndGetCards = async () => {
    try {
      setIsLoading(_ => true)
      Console.log("Auto-initializing Visa Click to Pay...")
      let sdkRefValue = sdkRef.current->Nullable.toOption

      switch sdkRefValue {
      | Some(sdk) => {
          let initParams: VisaSDK.initializeParams = {
            dpaTransactionOptions: {
              transactionAmount: {
                "transactionAmount": "123.94",
                "transactionCurrencyCode": "USD",
              },
              dpaBillingPreference: "NONE",
              dpaAcceptedBillingCountries: ["US", "CA"],
              merchantCategoryCode: "4829",
              merchantCountryCode: "US",
              payloadTypeIndicator: "FULL",
              merchantOrderId: "order_" ++ Date.now()->Float.toString,
              paymentOptions: [
                {
                  "dpaDynamicDataTtlMinutes": 2,
                  "dynamicDataType": "CARD_APPLICATION_CRYPTOGRAM_LONG_FORM",
                },
              ],
              dpaLocale: "en_US",
            },
            correlationId: "my-id",
          }

          let _ = await VisaSDK.callFunction(sdk, "initialize", initParams)
          Console.log("Visa Click to Pay initialized")

          let getCardsParams: VisaSDK.getCardsParams = {consumerIdentity: consumerIdentity}
          let cards = await VisaSDK.callFunction(sdk, "getCards", getCardsParams)
          handleGetCardsOutput(cards)
          setIsLoading(_ => false)
        }
      | None => {
          Console.log("SDK ref not available")
          setIsLoading(_ => false)
        }
      }
    } catch {
    | error => {
        setShowOtpInput(_ => false)
        setIsLoading(_ => false)
        Console.log2("Error during Visa Click to Pay:", error)
      }
    }
  }

  React.useEffect1(() => {
    if sdkReady {
      initVisaClickToPayAndGetCards()->ignore
    }
    None
  }, [sdkReady])

  let submitOtp = async () => {
    try {
      setIsLoading(_ => true)
      let otpString = otp->Array.join("")
      let sdkRefValue = sdkRef.current->Nullable.toOption

      switch sdkRefValue {
      | Some(sdk) => {
          let getCardsParams: VisaSDK.getCardsParams = {
            consumerIdentity: consumerIdentity,
            validationData: otpString,
          }
          let cards = await VisaSDK.callFunction(sdk, "getCards", getCardsParams)
          handleGetCardsOutput(cards)
          setIsLoading(_ => false)
        }
      | None => {
          Console.log("SDK ref not available")
          setIsLoading(_ => false)
        }
      }
    } catch {
    | error => {
        Console.log2("Error submitting OTP:", error)
        setIsLoading(_ => false)
      }
    }
  }

  let handleOtpChange = (index, value) => {
    if String.length(value) <= 1 {
      let newOtp = otp->Array.mapWithIndex((item, i) => i === index ? value : item)
      setOtp(_ => newOtp)
    }
  }

  let handleCheckout = async () => {
    try {
      setIsLoading(_ => true)
      let sdkRefValue = sdkRef.current->Nullable.toOption

      switch sdkRefValue {
      | Some(sdk) => {
          let checkoutParams: VisaSDK.checkoutParams = {
            srcDigitalCardId: srcId,
            payloadTypeIndicatorCheckout: "FULL",
            dpaTransactionOptions: {
              "authenticationPreferences": {
                "authenticationMethods": [
                  {
                    "authenticationMethodType": "3DS",
                    "authenticationSubject": "CARDHOLDER",
                    "methodAttributes": {"challengeIndicator": "01"},
                  },
                ],
                "payloadRequested": "AUTHENTICATED",
              },
              "acquirerBIN": "455555",
              "acquirerMerchantId": "12345678",
              "merchantName": "TestMerchant",
            },
          }
          let checkoutResponse = await VisaSDK.callFunction(sdk, "checkout", checkoutParams)
          Console.log2("===> Checkout Response:", checkoutResponse)
          setIsLoading(_ => false)
          // TODO: Handle checkout response and process payment
        }
      | None => {
          Console.log("SDK ref not available")
          setIsLoading(_ => false)
        }
      }
    } catch {
    | error => {
        Console.log2("Error during checkout:", error)
        setIsLoading(_ => false)
      }
    }
  }

  <>
    <View style={s({marginVertical: 12.->dp})}>
      <View
        style={s({
          flexDirection: #row,
          alignItems: #center,
          marginBottom: 12.->dp,
          paddingVertical: 8.->dp,
        })}>
        <View
          style={s({
            backgroundColor: "#1434CB",
            paddingHorizontal: 8.->dp,
            paddingVertical: 4.->dp,
            borderRadius: 4.,
          })}>
          <Text style={s({color: "#FFFFFF", fontSize: 12., fontWeight: #bold})}>
            {"VISA"->React.string}
          </Text>
        </View>
        <Text style={s({marginLeft: 8.->dp, fontSize: 14., fontWeight: #\"600"})}>
          {"Click to Pay"->React.string}
        </Text>
      </View>
      {isLoading
        ? <View style={s({paddingVertical: 16.->dp, alignItems: #center})}>
            <Text style={s({fontSize: 14., color: "#666"})}>
              {"Loading..."->React.string}
            </Text>
          </View>
        : React.null}
      {showOtpInput && !isLoading
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
              {otp
              ->Array.mapWithIndex((digit, index) => {
                <TextInput
                  key={index->Int.toString}
                  style={s({
                    width: 45.->dp,
                    height: 50.->dp,
                    borderWidth: 1.,
                    borderColor: component.borderColor,
                    borderRadius,
                    textAlign: #center,
                    fontSize: 20.,
                    fontWeight: #\"600",
                    backgroundColor: component.background,
                  })}
                  value=digit
                  onChangeText={value => handleOtpChange(index, value)}
                  keyboardType=#numeric
                  maxLength=1
                />
              })
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
          </View>
        : React.null}
      {cardsArray->Array.length > 0 && !showOtpInput && !isLoading
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

              <TouchableOpacity
                key={index->Int.toString}
                onPress={_ => setSrcId(_ => srcDigitalCardId)}
                style={s({
                  flexDirection: #row,
                  alignItems: #center,
                  padding: 12.->dp,
                  marginBottom: 8.->dp,
                  borderWidth: 1.,
                  borderColor: isSelected ? "#007AFF" : component.borderColor,
                  borderRadius,
                  backgroundColor: component.background,
                })}>
                // Radio button
                <View
                  style={s({
                    width: 20.->dp,
                    height: 20.->dp,
                    borderRadius: 10.,
                    borderWidth: 2.,
                    borderColor: isSelected ? "#007AFF" : "#CCC",
                    marginRight: 12.->dp,
                    justifyContent: #center,
                    alignItems: #center,
                  })}>
                  {isSelected
                    ? <View
                        style={s({
                          width: 10.->dp,
                          height: 10.->dp,
                          borderRadius: 5.,
                          backgroundColor: "#007AFF",
                        })}
                      />
                    : React.null}
                </View>
                <View
                  style={s({
                    backgroundColor: "#1434CB",
                    paddingHorizontal: 6.->dp,
                    paddingVertical: 3.->dp,
                    borderRadius: 3.,
                    marginRight: 8.->dp,
                  })}>
                  <Text style={s({color: "#FFFFFF", fontSize: 10., fontWeight: #bold})}>
                    {paymentCardDescriptor->React.string}
                  </Text>
                </View>
                <View style={s({flex: 1.})}>
                  <Text style={s({fontSize: 14., fontWeight: #\"600", marginBottom: 2.->dp})}>
                    {`•••• ${panLastFour}`->React.string}
                  </Text>
                  <Text style={s({fontSize: 12., color: "#666"})}>
                    {`${panExpirationMonth} / ${panExpirationYear}`->React.string}
                  </Text>
                </View>
              </TouchableOpacity>
            })
            ->React.array}
            {srcId !== ""
              ? <TouchableOpacity
                  onPress={_ => handleCheckout()->ignore}
                  disabled=isLoading
                  style={s({
                    backgroundColor: isLoading ? "#CCC" : "#007AFF",
                    padding: 14.->dp,
                    borderRadius,
                    alignItems: #center,
                    marginTop: 12.->dp,
                  })}>
                  <Text style={s({color: "#FFFFFF", fontSize: 16., fontWeight: #\"600"})}>
                    {(isLoading ? "Processing..." : "Pay with Click to Pay")->React.string}
                  </Text>
                </TouchableOpacity>
              : React.null}
          </View>
        : React.null}
    </View>
    <VisaSDK
      ref={sdkRef}
      onSDKReady={methods => {
        Console.log2("Visa SDK Ready! Available methods:", methods)
        setSdkReady(_ => true)
      }}
      onError={error => {
        Console.log2("Visa SDK Error:", error)
      }}
    />
  </>
}
