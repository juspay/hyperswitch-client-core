open ReactNative
open Style
open Validation

type cardFormType = {isZipAvailable: bool}
type viewType = PaymentSheet | CardForm(cardFormType)

module CardNetworkSync = {
  @react.component
  let make = (
    ~config: SuperpositionTypes.fieldConfig,
    ~brand: string,
    ~enabledCardSchemes: array<string>,
    ~createFieldValidator,
  ) => {
    let {input} = ReactFinalForm.useField(
      config.outputPath,
      ~config={validate: createFieldValidator(Validation.CardNetwork(enabledCardSchemes))},
    )
    React.useEffect1(() => {
      if input.value->Option.getOr("") !== brand {
        input.onChange(brand)
      }
      None
    }, [brand])
    React.null
  }
}

module CardBrandAndScanCardIcon = {
  @react.component
  let make = (
    ~isScanCardAvailable,
    ~eligibleCardSchemes,
    ~showCardSchemeDropDown,
    ~cardNumberFilled,
    ~onScanCard,
    ~expireRef,
    ~cvvRef,
    ~cardBrand,
    ~setCardBrand,
  ) => {
    <View style={s({flexDirection: #row, alignItems: #center})}>
      <CardSchemeComponent eligibleCardSchemes showCardSchemeDropDown cardBrand setCardBrand />
      <UIUtils.RenderIf condition={isScanCardAvailable && !cardNumberFilled}>
        <ScanCardButton onScanCard expireRef cvvRef />
      </UIUtils.RenderIf>
    </View>
  }
}

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue,
  ~enabledCardSchemes: array<string>=[],
  ~accessible=?,
  ~checkEligibility: option<string> => unit=_ => (),
) => {
  let cardNetworkConfig = fields->SuperpositionHelper.findFieldByName("card.card_network")
  switch (
    fields->SuperpositionHelper.findFieldByName("card.card_number"),
    fields->SuperpositionHelper.findFieldByName("card.card_exp_month"),
    fields->SuperpositionHelper.findFieldByName("card.card_exp_year"),
    fields->SuperpositionHelper.findFieldByName("card.card_cvc"),
  ) {
  | (
      Some(cardNumberConfig),
      Some(cardExpiryMonthConfig),
      Some(cardExpiryYearConfig),
      Some(cardCvcConfig),
    ) => {
      let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
      let {eligibilityStatus} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
      let emitter = PaymentEvents.usePaymentEventEmitter()
      let (expireDate, setExpireDate) = React.useState(() => "")

      let {
        component,
        dangerColor,
        borderRadius,
        borderWidth,
        primaryColor,
      } = ThemebasedStyle.useThemeBasedStyle()
      let localeObject = GetLocale.useGetLocalObj()
      let cardRef = React.useRef(Nullable.null)
      let expireRef = React.useRef(Nullable.null)
      let cvvRef = React.useRef(Nullable.null)
      let nullRef = React.useRef(Nullable.null)

      let {input: cardNumberInput, meta: cardNumberMeta} = ReactFinalForm.useField(
        cardNumberConfig.outputPath,
        ~config={
          validate: createFieldValidator(CardNumber),
          format: formatValue(CardNumber),
        },
      )

      let {input: cardExpiryMonthInput, meta: _cardExpiryMonthMeta} = ReactFinalForm.useField(
        cardExpiryMonthConfig.outputPath,
        ~config={validate: createFieldValidator(CardExpiry(expireDate))},
      )

      let {input: cardExpiryYearInput, meta: cardExpiryYearMeta} = ReactFinalForm.useField(
        cardExpiryYearConfig.outputPath,
        ~config={validate: createFieldValidator(CardExpiry(expireDate))},
      )

      let (cardBrand, setCardBrand) = React.useState(() => "")

      let {input: cardCvcInput, meta: cardCvcMeta} = ReactFinalForm.useField(
        cardCvcConfig.outputPath,
        ~config={validate: createFieldValidator(CardCVC(cardBrand))},
      )

      let (
        (eligibleCardSchemes, showCardSchemeDropDown),
        setCardSchemeVariables,
      ) = React.useState(_ => ([], false))

      let onChangeCardNumber = (
        text,
        expireRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
      ) => {
        let matchedCardSchemes = text->Validation.clearSpaces->Validation.getAllMatchedCardSchemes

        let isCardCoBadged = matchedCardSchemes->Array.length > 1
        let showCardSchemeDropDown =
          isCardCoBadged && text->Validation.clearSpaces->String.length >= 16

        let currentCardBrand = matchedCardSchemes->Array.get(0)->Option.getOr("")
        let num = formatCardNumber(text, cardType(currentCardBrand))

        setCardSchemeVariables(_ => (matchedCardSchemes, showCardSchemeDropDown))

        if (
          currentCardBrand !== cardBrand &&
            matchedCardSchemes->Array.find(v => v === currentCardBrand)->Option.isNone
        ) {
          cardExpiryMonthInput.onChange("")
          cardExpiryYearInput.onChange("")
          cardCvcInput.onChange("")
          setExpireDate(_ => "")
        }
        if num !== cardNumberInput.value->Option.getOr("") {
          cardNumberInput.onChange(num)
          setCardBrand(_ => currentCardBrand)
        }

        let isthisValid = cardValid(num, currentCardBrand)
        let shouldShiftFocusToNextField = isCardNumberEqualsMax(num, currentCardBrand)

        if isthisValid && shouldShiftFocusToNextField {
          switch expireRef.current->Nullable.toOption {
          | None => ()
          | Some(ref) => ref->ReactNative.TextInputElement.focus
          }
        }
      }
      let onChangeCardExpire = (
        text,
        cvvRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
      ) => {
        let dateExpire = formatCardExpiryNumber(text)

        let (month, year) = dateExpire->splitExpiryDates

        cardExpiryMonthInput.onChange(month)
        cardExpiryYearInput.onChange(year)
        setExpireDate(_ => dateExpire)

        let isthisValid = checkCardExpiry(dateExpire)
        if isthisValid {
          switch cvvRef.current->Nullable.toOption {
          | None => ()
          | Some(ref) => ref->ReactNative.TextInputElement.focus
          }
        }
      }
      let onChangeCvv = (
        text,
        cvvOrZipRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
      ) => {
        let cvvData = formatCVCNumber(text, cardBrand)

        cardCvcInput.onChange(cvvData)

        let isValidCvv = checkCardCVC(cvvData, cardBrand)
        let shouldShiftFocusToNextField = checkMaxCardCvv(cvvData, cardBrand)
        if isValidCvv && shouldShiftFocusToNextField {
          switch cvvOrZipRef.current->Nullable.toOption {
          | None => ()
          | Some(ref) => ref->ReactNative.TextInputElement.blur
          }
        }
      }

      let cardNumber = cardNumberInput.value->Option.getOr("")
      let cvc = cardCvcInput.value->Option.getOr("")
      let brand = cardBrand

      React.useEffect(() => {
        let info = PaymentEvents.buildCardInfo(~cardNumber, ~expiry=expireDate, ~cvc, ~brand)
        emitter.emitCardInfo(~info)
        None
      }, (cardNumber, expireDate, cvc, brand))

      React.useEffect1(() => {
        let isValid = cardValid(cardNumber, brand)
        let isMaxLength = isCardNumberEqualsMax(cardNumber, brand)
        if isValid && isMaxLength {
          checkEligibility(Some(cardNumber->clearSpaces))
        } else if !isValid && eligibilityStatus !== DynamicFieldsContext.Allowed {
          checkEligibility(None)
        }
        None
      }, [cardNumber])

      let onScanCard = (
        pan,
        expiry,
        expireRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
        cvvRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
      ) => {
        let scannedBrand = getCardBrand(pan)
        let cardNumber = formatCardNumber(pan, cardType(scannedBrand))
        let isCardValid = cardValid(cardNumber, scannedBrand)
        let expireDate = formatCardExpiryNumber(expiry)
        let isExpiryValid = checkCardExpiry(expireDate)
        cardNumberInput.onChange(cardNumber)
        setCardBrand(_ => scannedBrand)
        let (month, year) = expireDate->splitExpiryDates
        cardExpiryMonthInput.onChange(month)
        cardExpiryYearInput.onChange(year)
        setExpireDate(_ => expireDate)
        switch (isCardValid, isExpiryValid) {
        | (true, true) =>
          switch cvvRef.current->Nullable.toOption {
          | None => ()
          | Some(ref) => ref->ReactNative.TextInputElement.focus
          }
        | (true, false) =>
          switch expireRef.current->Nullable.toOption {
          | None => ()
          | Some(ref) => ref->ReactNative.TextInputElement.focus
          }
        | _ => ()
        }
      }

      <React.Fragment>
        {switch cardNetworkConfig {
        | Some(config) =>
          <CardNetworkSync config brand=cardBrand enabledCardSchemes createFieldValidator />
        | None => React.null
        }}
        <View style={s({marginBottom: 16.->dp})}>
          <View style={s({width: 100.->pct, borderRadius})}>
            <View style={s({width: 100.->pct})}>
              <CustomInput
                name={TestUtils.cardNumberInputTestId}
                reference=Some(cardRef)
                state={cardNumberInput.value->Option.getOr("")}
                setState={text => onChangeCardNumber(text, expireRef)}
                placeholder=nativeProp.configuration.placeholder.cardNumber
                keyboardType=#"number-pad"
                isValid={cardNumberMeta.error->Option.isNone ||
                !cardNumberMeta.touched ||
                cardNumberMeta.active}
                maxLength=Some(23)
                borderTopLeftRadius=borderRadius
                borderTopRightRadius=borderRadius
                borderBottomWidth=borderWidth
                borderLeftWidth=borderWidth
                borderRightWidth=borderWidth
                borderTopWidth=borderWidth
                borderBottomLeftRadius=0.
                borderBottomRightRadius=0.
                textColor={{
                  cardNumberMeta.error->Option.isNone ||
                  !cardNumberMeta.touched ||
                  cardNumberMeta.active
                }
                  ? component.color
                  : dangerColor}
                enableCrossIcon=false
                iconRight=CustomInput.CustomIcon(
                  <CardBrandAndScanCardIcon
                    isScanCardAvailable=ScanCardModule.isAvailable
                    eligibleCardSchemes
                    showCardSchemeDropDown
                    cardNumberFilled={switch cardNumberInput.value {
                    | None | Some("") => false
                    | _ => true
                    }}
                    onScanCard
                    expireRef
                    cvvRef
                    cardBrand
                    setCardBrand={b => setCardBrand(_ => b)}
                  />,
                )
                onFocus={() => {
                  cardNumberInput.onFocus()
                }}
                onBlur={() => {
                  cardNumberInput.onBlur()
                }}
                onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
                  if (
                    ev.nativeEvent.key == "Backspace" &&
                      cardNumberInput.value->Option.getOr("") == ""
                  ) {
                    switch cardRef.current->Nullable.toOption {
                    | None => ()
                    | Some(ref) => ref->TextInputElement.blur
                    }
                  }
                }}
                animateLabel=localeObject.cardNumberLabel
                ?accessible
              />
            </View>
            <View
              style={s({
                width: 100.->pct,
                flexDirection: localeObject.localeDirection === "rtl" ? #"row-reverse" : #row,
              })}>
              <View style={s({width: 50.->pct})}>
                <CustomInput
                  name={TestUtils.expiryInputTestId}
                  reference={Some(expireRef)}
                  state=expireDate
                  setState={text => onChangeCardExpire(text, cvvRef)}
                  placeholder=nativeProp.configuration.placeholder.expiryDate
                  keyboardType=#"number-pad"
                  enableCrossIcon=false
                  isValid={((cardExpiryYearMeta.error->Option.isNone ||
                  !cardExpiryYearMeta.touched ||
                  cardExpiryYearMeta.active) && expireDate->String.length < 7) ||
                    (expireDate->String.length === 7 && checkCardExpiry(expireDate))}
                  maxLength=Some(7)
                  borderTopWidth=0.25
                  borderRightWidth=borderWidth
                  borderTopLeftRadius=0.
                  borderTopRightRadius=0.
                  borderBottomRightRadius=0.
                  borderBottomLeftRadius=borderRadius
                  borderBottomWidth=borderWidth
                  borderLeftWidth=borderWidth
                  textColor={((cardExpiryYearMeta.error->Option.isNone ||
                  !cardExpiryYearMeta.touched ||
                  cardExpiryYearMeta.active) && expireDate->String.length < 7) ||
                    (expireDate->String.length === 7 && checkCardExpiry(expireDate))
                    ? component.color
                    : dangerColor}
                  onFocus={() => {
                    cardExpiryYearInput.onFocus()
                  }}
                  onBlur={() => {
                    cardExpiryYearInput.onBlur()
                  }}
                  onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
                    if ev.nativeEvent.key == "Backspace" && expireDate == "" {
                      switch cardRef.current->Nullable.toOption {
                      | None => ()
                      | Some(ref) => ref->TextInputElement.focus
                      }
                    }
                  }}
                  animateLabel=localeObject.validThruText
                  ?accessible
                />
              </View>
              <View style={s({width: 50.->pct})}>
                <CustomInput
                  name={TestUtils.cvcInputTestId}
                  reference={Some(cvvRef)}
                  borderTopWidth=0.25
                  borderLeftWidth=0.5
                  borderTopLeftRadius=0.
                  borderTopRightRadius=0.
                  borderBottomLeftRadius=0.
                  borderBottomRightRadius=borderRadius
                  borderBottomWidth=borderWidth
                  borderRightWidth=borderWidth
                  secureTextEntry=true
                  state={cardCvcInput.value->Option.getOr("")}
                  isValid={cardCvcMeta.error->Option.isNone ||
                  !cardCvcMeta.touched ||
                  cardCvcMeta.active}
                  maxLength=Some(4)
                  setState={text => onChangeCvv(text, nullRef)}
                  placeholder=nativeProp.configuration.placeholder.cvv
                  keyboardType=#"number-pad"
                  enableCrossIcon=false
                  onFocus={() => {
                    cardCvcInput.onFocus()
                  }}
                  onBlur={() => {
                    cardCvcInput.onBlur()
                  }}
                  textColor={cardCvcMeta.error->Option.isNone ||
                  !cardCvcMeta.touched ||
                  cardCvcMeta.active
                    ? component.color
                    : dangerColor}
                  iconRight=CustomIcon(
                    <View
                      style={s({
                        height: 46.->dp,
                        display: #flex,
                        flexDirection: #row,
                        justifyContent: #center,
                        alignItems: #center,
                      })}>
                      <Icon
                        name="cvv"
                        height=32.
                        width=32.
                        fill={checkCardCVC(cardCvcInput.value->Option.getOr(""), cardBrand)
                          ? primaryColor
                          : "#858F97"}
                      />
                    </View>,
                  )
                  onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
                    if (
                      ev.nativeEvent.key == "Backspace" &&
                        cardCvcInput.value->Option.getOr("") == ""
                    ) {
                      switch expireRef.current->Nullable.toOption {
                      | None => ()
                      | Some(ref) => ref->TextInputElement.focus
                      }
                    }
                  }}
                  animateLabel=localeObject.cvcTextLabel
                  ?accessible
                />
              </View>
            </View>
          </View>
          {switch (cardNumberMeta.error, cardNumberMeta.touched) {
          | (Some(error), true) => <ErrorText text={Some(error)} />
          | _ =>
            switch (
              cardExpiryYearMeta.error,
              (expireDate->String.length > 0 || !cardExpiryYearMeta.touched) &&
                (expireDate->String.length < 7 || checkCardExpiry(expireDate)),
            ) {
            | (Some(error), false) => <ErrorText text={Some(error)} />
            | _ =>
              switch (cardCvcMeta.error, cardCvcMeta.touched, cardCvcMeta.active) {
              | (Some(error), true, false) => <ErrorText text={Some(error)} />
              | _ =>
                switch eligibilityStatus {
                | DynamicFieldsContext.Denied =>
                  <ErrorText text={Some(localeObject.cardNotEligibleText)} />
                | DynamicFieldsContext.Pending => React.null
                | _ => React.null
                }
              }
            }
          }}
        </View>
      </React.Fragment>
    }
  | _ => React.null
  }
}
