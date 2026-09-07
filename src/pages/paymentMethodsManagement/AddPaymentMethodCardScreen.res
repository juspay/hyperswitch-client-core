open ReactNative
open Style

@react.component
let make = (
  ~paymentMethodsEnabled: array<PaymentMethodSessionTypes.paymentMethodEnabled>,
  ~showBackButton: bool,
  ~onBack: unit => unit,
  ~addConfirmRef: React.ref<option<unit => unit>>,
  ~onInvalidSubmit: unit => unit,
  ~setIsSaving: (bool => bool) => unit,
  ~fillHeight: bool=true,
) => {
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let confirmPaymentMethodSession = PaymentMethodSessionHooks.useConfirmPaymentMethodSession()
  let localeObject = GetLocale.useGetLocalObj()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()

  let (cardNumber, setCardNumber) = React.useState(_ => "")
  let (expiryDate, setExpiryDate) = React.useState(_ => "")
  let (cvv, setCvv) = React.useState(_ => "")
  let (cardHolderName, setCardHolderName) = React.useState(_ => "")
  let (nickName, setNickName) = React.useState(_ => "")

  let (cardNumberError, setCardNumberError) = React.useState((_): option<string> => None)
  let (expiryError, setExpiryError) = React.useState((_): option<string> => None)
  let (cvcError, setCvcError) = React.useState((_): option<string> => None)

  let cardBrand = Validation.getCardBrand(cardNumber)
  let cardType = Validation.cardType(cardBrand)

  let cardEntrySupported =
    paymentMethodsEnabled->Array.some(item => item.payment_method_type == "card")

  let isCardNumberValid = Validation.cardValid(cardNumber, cardBrand)
  let isExpiryValid = Validation.checkCardExpiry(expiryDate)
  let isCvcValid = Validation.checkCardCVC(cvv, cardBrand)
  let isFormValid = isCardNumberValid && isExpiryValid && isCvcValid

  let cardNumberErrorMessage = () =>
    cardNumber == ""
      ? Some(localeObject.cardNumberEmptyText)
      : isCardNumberValid
      ? None
      : Some(localeObject.inValidCardErrorText)
  let isExpiryComplete = {
    let (month, year) = Validation.splitExpiryDates(expiryDate)
    month->String.length == 2 && year->String.length == 2
  }
  let expiryErrorMessage = () =>
    expiryDate == ""
      ? Some(localeObject.cardExpiryDateEmptyText)
      : isExpiryValid
      ? None
      : isExpiryComplete
      ? Some(localeObject.pastExpiryErrorText)
      : Some(localeObject.inCompleteExpiryErrorText)
  let cvcErrorMessage = () =>
    cvv == ""
      ? Some(localeObject.cvcNumberEmptyText)
      : isCvcValid
      ? None
      : Some(localeObject.inCompleteCVCErrorText)

  let handleSaveCard = _ => {
    if !isFormValid {
      setCardNumberError(_ => cardNumberErrorMessage())
      setExpiryError(_ => expiryErrorMessage())
      setCvcError(_ => cvcErrorMessage())
      onInvalidSubmit()
    } else {
      setIsSaving(_ => true)
      let (month, year) = Validation.getExpiryDates(expiryDate)
      let body =
        [
          ("payment_method_type", "card"->JSON.Encode.string),
          ("payment_method_subtype", "card"->JSON.Encode.string),
          (
            "payment_method_data",
            [
              (
                "card",
                [
                  ("card_number", cardNumber->Validation.clearSpaces->JSON.Encode.string),
                  ("card_exp_month", month->JSON.Encode.string),
                  ("card_exp_year", year->JSON.Encode.string),
                  ("card_cvc", cvv->JSON.Encode.string),
                  ("card_holder_name", cardHolderName->JSON.Encode.string),
                  ("nick_name", nickName->JSON.Encode.string),
                  ("card_network", cardBrand->JSON.Encode.string),
                ]
                ->Dict.fromArray
                ->JSON.Encode.object,
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object

      confirmPaymentMethodSession(~body)
      ->Promise.then(res => {
        setIsSaving(_ => false)
        if res->ErrorUtils.isError || res == JSON.Encode.null {
          handleSuccessFailure(
            ~apiResStatus={
              type_: "payment_method_session",
              status: "failed",
              code: "",
              message: ErrorUtils.getErrorMessage(res),
            },
            (),
          )
        } else {
          let dict = res->Utils.getDictFromJson
          handleSuccessFailure(
            ~apiResStatus={
              type_: "payment_method_session",
              status: dict->Utils.getString("status", "succeeded"),
              code: "",
              message: dict->Utils.getString("status", "Card saved successfully"),
            },
            (),
          )
        }
        Promise.resolve()
      })
      ->ignore
    }
  }

  React.useEffect1(() => {
    addConfirmRef.current = Some(handleSaveCard)
    None
  }, [handleSaveCard])

  <ScrollView
    keyboardShouldPersistTaps=#handled
    style={s(
      fillHeight
        ? {backgroundColor: component.background, height: 100.->pct}
        : {backgroundColor: component.background, flexShrink: 1.},
    )}>
    {showBackButton
      ? <CustomPressable
          onPress={_ => onBack()}
          style={s({paddingHorizontal: 24.->dp, paddingTop: 16.->dp, alignSelf: #"flex-start"})}>
          <Icon name={"arrow-back"} height=18. width=18. />
        </CustomPressable>
      : React.null}
    {cardEntrySupported
      ? <>
          <View style={s({paddingHorizontal: 24.->dp, paddingTop: 16.->dp})}>
            <CustomInput
              state=cardNumber
              setState={val => {
                setCardNumberError(_ => None)
                setCardNumber(_ => val->Validation.formatCardNumber(cardType))
              }}
              placeholder="Card number"
              keyboardType=#"number-pad"
              enableCrossIcon=false
              maxLength={Some(Validation.maxCardLength(cardBrand) + 3)}
              isValid={cardNumberError->Option.isNone}
              textColor={cardNumberError->Option.isNone ? component.color : dangerColor}
              onBlur={_ =>
                cardNumber != "" ? setCardNumberError(_ => cardNumberErrorMessage()) : ()}
              iconRight={CustomInput.CustomIcon(
                <Icon
                  name={cardBrand == "" ? "waitcard" : cardBrand} height=28. width=28. fill="black"
                />,
              )}
            />
            <ErrorText text=cardNumberError />
            <Space height=10. />
            <View style={s({flexDirection: #row, flexWrap: #nowrap})}>
              <View style={s({flex: 1.})}>
                <CustomInput
                  state=expiryDate
                  setState={val => {
                    setExpiryError(_ => None)
                    setExpiryDate(_ => val->Validation.formatCardExpiryNumber)
                  }}
                  placeholder="MM / YY"
                  keyboardType=#"number-pad"
                  enableCrossIcon=false
                  maxLength={Some(8)}
                  isValid={expiryError->Option.isNone}
                  textColor={expiryError->Option.isNone ? component.color : dangerColor}
                  onBlur={_ => expiryDate != "" ? setExpiryError(_ => expiryErrorMessage()) : ()}
                />
                <ErrorText text=expiryError />
              </View>
              <Space width=10. />
              <View style={s({flex: 1.})}>
                <CustomInput
                  state=cvv
                  setState={val => {
                    setCvcError(_ => None)
                    setCvv(_ => val->Validation.formatCVCNumber(cardBrand))
                  }}
                  placeholder="CVV"
                  keyboardType=#"number-pad"
                  secureTextEntry=true
                  enableCrossIcon=false
                  maxLength={Some(4)}
                  isValid={cvcError->Option.isNone}
                  textColor={cvcError->Option.isNone ? component.color : dangerColor}
                  onBlur={_ => cvv != "" ? setCvcError(_ => cvcErrorMessage()) : ()}
                />
                <ErrorText text=cvcError />
              </View>
            </View>
            <Space height=10. />
            <CustomInput
              state=cardHolderName
              setState={val => setCardHolderName(_ => val)}
              placeholder="Card holder name (optional)"
              enableCrossIcon=false
            />
            <Space height=10. />
            <CustomInput
              state=nickName
              setState={val => setNickName(_ => val)}
              placeholder="Nickname (optional)"
              enableCrossIcon=false
            />
          </View>
        </>
      : <View
          style={s({
            width: 100.->pct,
            padding: 24.->dp,
            backgroundColor: component.background,
            alignItems: #center,
          })}>
          <TextWrapper text={"No payment methods available."} textType={ModalTextLight} />
        </View>}
  </ScrollView>
}
