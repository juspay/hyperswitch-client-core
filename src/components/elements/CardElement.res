open ReactNative
open Style
open Validation

type cardFormType = {isZipAvailable: bool}
type viewType = PaymentSheet | CardForm(cardFormType)

module CardBrandAndScanCardIcon = {
  @react.component
  let make = (
    ~isScanCardAvailable,
    ~cardNumber,
    ~enabledCardSchemes,
    ~onScanCard,
    ~expireRef,
    ~cvvRef,
  ) => {
    <View style={s({flexDirection: #row, alignItems: #center})}>
      <CardSchemeComponent cardNumber enabledCardSchemes />
      <UIUtils.RenderIf condition={isScanCardAvailable && cardNumber === ""}>
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
) => {
  switch (
    fields->Array.get(0),
    fields->Array.get(1),
    fields->Array.get(2),
    fields->Array.get(3),
    fields->Array.get(4),
  ) {
  | (
      Some(cardNumberConfig),
      Some(cardExpiryMonthConfig),
      Some(cardExpiryYearConfig),
      Some(cardCvcConfig),
      Some(cardNetworkConfig),
    ) => {
      let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

      // let (cardNumber, setCardNumber) = React.useState(() => "")
      let (expireDate, setExpireDate) = React.useState(() => "")
      // let (cvv, setCvv) = React.useState(() => "")

      let {component, dangerColor, borderRadius, borderWidth} = ThemebasedStyle.useThemeBasedStyle()
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
        (),
      )

      let {input: cardExpiryMonthInput, meta: cardExpiryMonthMeta} = ReactFinalForm.useField(
        cardExpiryMonthConfig.outputPath,
        ~config={validate: createFieldValidator(Required)},
        (),
      )

      let {input: cardExpiryYearInput, meta: cardExpiryYearMeta} = ReactFinalForm.useField(
        cardExpiryYearConfig.outputPath,
        ~config={validate: createFieldValidator(Required)},
        (),
      )

      let {input: cardCvcInput, meta: cardCvcMeta} = ReactFinalForm.useField(
        cardCvcConfig.outputPath,
        ~config={validate: createFieldValidator(Required)},
        (),
      )

      let {input: cardNetworkInput, meta: _cardNetworkMeta} = ReactFinalForm.useField(
        cardNetworkConfig.outputPath,
        ~config={validate: createFieldValidator(Required)},
        (),
      )

      let cardBrand = getCardBrand(cardNumberInput.value->Option.getOr(""))

      let onChangeCardNumber = (
        text,
        expireRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
      ) => {
        let validCardBrand = getFirstValidCardScheme(~cardNumber=text, ~enabledCardSchemes)
        let cardBrand = validCardBrand === "" ? getCardBrand(text) : validCardBrand
        let num = formatCardNumber(text, cardType(cardBrand))

        cardNumberInput.onChange(num)
        cardNetworkInput.onChange(cardBrand)

        let isthisValid = cardValid(num, cardBrand)
        let shouldShiftFocusToNextField = isCardNumberEqualsMax(num, cardBrand)

        // Adding support for 19 digit card hence disabling ref
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

      let onScanCard = (
        pan,
        expiry,
        expireRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
        cvvRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
      ) => {
        let cardBrand = getCardBrand(pan)
        let cardNumber = formatCardNumber(pan, cardType(cardBrand))
        let isCardValid = cardValid(cardNumber, cardBrand)
        let expireDate = formatCardExpiryNumber(expiry)
        let isExpiryValid = checkCardExpiry(expireDate)
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
        <View style={s({marginBottom: 16.->dp})}>
          <View style={s({width: 100.->pct, borderRadius})}>
            <View style={s({width: 100.->pct})}>
              <CustomInput
                name={TestUtils.cardNumberInputTestId}
                reference={None} // previously Some(cardRef->toInputRef)
                state={cardNumberInput.value->Option.getOr("")}
                setState={text => onChangeCardNumber(text, expireRef)}
                placeholder=nativeProp.configuration.placeholder.cardNumber
                keyboardType=#"number-pad"
                isValid={cardNumberMeta.error->Option.isNone || !cardNumberMeta.touched}
                maxLength=Some(23)
                borderTopLeftRadius=borderRadius
                borderTopRightRadius=borderRadius
                borderBottomWidth=borderWidth
                borderLeftWidth=borderWidth
                borderRightWidth=borderWidth
                borderTopWidth=borderWidth
                borderBottomLeftRadius=0.
                borderBottomRightRadius=0.
                textColor={{cardNumberMeta.error->Option.isNone || !cardNumberMeta.touched}
                  ? component.color
                  : dangerColor}
                enableCrossIcon=false
                iconRight=CustomInput.CustomIcon(
                  <CardBrandAndScanCardIcon
                    isScanCardAvailable=ScanCardModule.isAvailable
                    cardNumber={cardNumberInput.value->Option.getOr("")}
                    enabledCardSchemes
                    onScanCard
                    expireRef
                    cvvRef
                  />,
                )
                onFocus={() => {
                  cardNumberInput.onFocus()
                  onChangeCardNumber({cardNumberInput.value->Option.getOr("")}, nullRef)
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
                  isValid={cardExpiryMonthMeta.error->Option.isNone ||
                  !cardExpiryMonthMeta.touched ||
                  cardExpiryYearMeta.error->Option.isNone ||
                  !cardExpiryYearMeta.touched}
                  borderTopWidth=0.25
                  borderRightWidth=borderWidth
                  borderTopLeftRadius=0.
                  borderTopRightRadius=0.
                  borderBottomRightRadius=0.
                  borderBottomLeftRadius=borderRadius
                  borderBottomWidth=borderWidth
                  borderLeftWidth=borderWidth
                  textColor={cardExpiryMonthMeta.error->Option.isNone ||
                  !cardExpiryMonthMeta.touched ||
                  cardExpiryYearMeta.error->Option.isNone ||
                  !cardExpiryYearMeta.touched
                    ? component.color
                    : dangerColor}
                  onFocus={() => {
                    cardExpiryMonthInput.onFocus()
                    cardExpiryYearInput.onFocus()
                    onChangeCardExpire(expireDate, nullRef)
                  }}
                  onBlur={() => {
                    cardExpiryMonthInput.onBlur()
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
                  isValid={cardCvcMeta.error->Option.isNone || !cardCvcMeta.touched}
                  setState={text => onChangeCvv(text, cvvRef)}
                  placeholder=nativeProp.configuration.placeholder.cvv
                  keyboardType=#"number-pad"
                  enableCrossIcon=false
                  onFocus={() => {
                    cardCvcInput.onFocus()
                    onChangeCvv(cardCvcInput.value->Option.getOr(""), nullRef)
                  }}
                  onBlur={() => {
                    cardCvcInput.onBlur()
                  }}
                  textColor={{cardCvcMeta.error->Option.isNone || !cardCvcMeta.touched}
                    ? component.color
                    : dangerColor}
                  iconRight=CustomIcon({
                    checkCardCVC(cardCvcInput.value->Option.getOr(""), cardBrand)
                      ? <Icon name="cvvfilled" height=35. width=35. fill="black" />
                      : <Icon name="cvvempty" height=35. width=35. fill="black" />
                  })
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
                />
              </View>
            </View>
          </View>
          {switch (cardNumberMeta.error, cardNumberMeta.touched) {
          | (Some(error), true) => <ErrorText text={Some(error)} />
          | _ =>
            switch (cardExpiryMonthMeta.error, cardExpiryMonthMeta.touched) {
            | (Some(error), true) => <ErrorText text={Some(error)} />
            | _ =>
              switch (cardExpiryYearMeta.error, cardExpiryYearMeta.touched) {
              | (Some(error), true) => <ErrorText text={Some(error)} />
              | _ =>
                switch (cardCvcMeta.error, cardCvcMeta.touched) {
                | (Some(error), true) => <ErrorText text={Some(error)} />
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
