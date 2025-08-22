open ReactNative
open Style
open SuperpositionHelper
open ReactFinalForm

@react.component
let make = (~fields: array<fieldConfig>, ~createSyntheticEvent: string => ReactEvent.Form.t) => {
  let cardRef = React.useRef(Nullable.null)
  let expireRef = React.useRef(Nullable.null)
  let cvvRef = React.useRef(Nullable.null)
  
  let {borderRadius, borderWidth, component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let localeObject = GetLocale.useGetLocalObj()
  
  let focusField = (fieldRef: React.ref<Nullable.t<ReactNative.TextInput.element>>) => {
    switch fieldRef.current->Nullable.toOption {
    | None => ()
    | Some(ref) => ref->ReactNative.TextInputElement.focus
    }
  }
  
  let blurField = (fieldRef: React.ref<Nullable.t<ReactNative.TextInput.element>>) => {
    switch fieldRef.current->Nullable.toOption {
    | None => ()
    | Some(ref) => ref->ReactNative.TextInputElement.blur
    }
  }

  let cardNumberField = fields->Array.find(field => field.outputPath->String.endsWith("card_number"))
  let cardNetworkField = fields->Array.find(field => field.outputPath->String.endsWith("card_network"))
  let expiryMonthField = fields->Array.find(field => field.outputPath->String.endsWith("card_exp_month"))
  let expiryYearField = fields->Array.find(field => field.outputPath->String.endsWith("card_exp_year"))
  let cvvField = fields->Array.find(field => 
    field.outputPath->String.endsWith("card_cvc")
    // field.outputPath->String.endsWith("cvv") ||
    // field.fieldType == "cvv_input"
  )

  <View>
    <View style={Style.s({marginBottom: 12.->Style.dp})}>
      <Space height=5. />
      <TextWrapper text="Card Details" textType=ModalText />
    </View>
    
    <View style={Style.s({width: 100.->Style.pct})}>
      {switch (cardNumberField, cardNetworkField, expiryMonthField, expiryYearField, cvvField) {
      | (Some(cardField), Some(networkField), Some(monthField), Some(yearField), Some(cvv)) =>
        <ReactFinalForm.Field
          name={cardField.name}
          validate={(value, _) => {
            let cardNumber = value->Option.getOr("")->CardValidations.clearSpaces
            let cardBrand = Validation.getCardBrand(cardNumber)
            
            if cardNumber->String.length == 0 {
              Promise.resolve(Nullable.null)
            } else if !Validation.cardValid(cardNumber, cardBrand) {
              Promise.resolve(Nullable.make("Please enter a valid card number"))
            } else {
              Promise.resolve(Nullable.null)
            }
          }}
          render={({input: cardInput, meta: cardMeta}) => {
            <ReactFinalForm.Field
              name={networkField.name}
              render={({input: networkInput, meta: _}) => {
                <ReactFinalForm.Field
                  name={monthField.name}
                  validate={(value, _) => {
                    let expiry = value->Option.getOr("")
                    
                    if expiry->String.length == 0 {
                      Promise.resolve(Nullable.null)
                    } else if !Validation.checkCardExpiry(expiry) {
                      Promise.resolve(Nullable.make("Please enter a valid expiry date"))
                    } else {
                      Promise.resolve(Nullable.null)
                    }
                  }}
                  render={({input: expiryInput, meta: expiryMeta}) => {
                    <ReactFinalForm.Field
                      name={yearField.name}
                      render={({input: yearInput, meta: _}) => {
                        <ReactFinalForm.Field
                          name={cvv.name}
                          validate={(value, formObject) => {
                            let cvv = value->Option.getOr("")
                            
                            if cvv->String.length == 0 {
                              Promise.resolve(Nullable.null)
                            } else {
                              let cardBrand = try {
                                let formValues = formObject->JSON.Decode.object->Option.getOr(Dict.make())
                                let cardNumberField = formValues->Dict.toArray->Array.find(((key, _)) => 
                                  key->String.includes("card_number")
                                )
                                switch cardNumberField {
                                | Some((_, cardNumberValue)) => 
                                  let cardNumber = cardNumberValue->JSON.Decode.string->Option.getOr("")
                                  Validation.getCardBrand(cardNumber)
                                | None => ""
                                }
                              } catch {
                              | _ => ""
                              }
                              
                              if !Validation.checkCardCVC(cvv, cardBrand) {
                                Promise.resolve(Nullable.make("Please enter a valid CVV"))
                              } else {
                                Promise.resolve(Nullable.null)
                              }
                            }
                          }}
                          render={({input: cvvInput, meta: cvvMeta}) => {
                            let cardNumber = cardInput.value->JSON.Decode.string->Option.getOr("")
                            let expireDate = expiryInput.value->JSON.Decode.string->Option.getOr("")
                            let cvv = cvvInput.value->JSON.Decode.string->Option.getOr("")
                            let cardBrand = Validation.getCardBrand(cardNumber)
                            
                            let isMaxCardLength = cardNumber->CardValidations.clearSpaces->String.length == Validation.maxCardLength(cardBrand)
                            let isCardNumberValid = cardMeta.active ? cardMeta.valid || !isMaxCardLength : cardMeta.valid
                            let isExpireDateValid = expiryMeta.active ? expiryMeta.valid || expireDate->String.length < 7 : expiryMeta.valid
                            let isCvvValid = cvvMeta.active ? cvvMeta.valid || !Validation.cvcNumberInRange(cvv, cardBrand) : cvvMeta.valid
                            
                            let errorMsgText = if !isCardNumberValid {
                              Some(localeObject.inValidCardErrorText)
                            } else if !isExpireDateValid {
                              Some(localeObject.inValidExpiryErrorText)
                            } else if !isCvvValid {
                              Some(localeObject.inValidCVCErrorText)
                            } else {
                              None
                            }
                            
                            let handleCardNumberChange = (event: ReactEvent.Form.t) => {
                              let value = ReactEvent.Form.target(event)["value"]
                              let previousCardNumber = cardInput.value->JSON.Decode.string->Option.getOr("")
                              let cardBrand = Validation.getCardBrand(value)
                              let formattedCardNumber = Validation.formatCardNumber(value, Validation.cardType(cardBrand))
                              let detectedNetwork = Validation.getCardBrand(formattedCardNumber)
                              
                              let wasCleared = previousCardNumber->String.length > 0 && formattedCardNumber->String.length == 0
                              
                              let isCardValid = Validation.cardValid(formattedCardNumber, cardBrand)
                              let shouldShiftFocus = Validation.isCardNumberEqualsMax(formattedCardNumber, cardBrand)
                              
                              cardInput.onChange(createSyntheticEvent(formattedCardNumber))
                              networkInput.onChange(createSyntheticEvent(detectedNetwork))
                              
                              if wasCleared {
                                expiryInput.onChange(createSyntheticEvent(""))
                                yearInput.onChange(createSyntheticEvent(""))
                                cvvInput.onChange(createSyntheticEvent(""))
                              }
                              
                              if isCardValid && shouldShiftFocus {
                                focusField(expireRef)
                              }
                            }
                            
                            <View style={Style.s({width: 100.->Style.pct})}>
                              <View style={Style.s({position: #relative})}>
                                <CustomInput
                                  reference={Some(cardRef)}
                                  state={cardInput.value->JSON.Decode.string->Option.getOr("")}
                                  setState={_ => ()}
                                  onChange={handleCardNumberChange}
                                  placeholder=nativeProp.configuration.placeholder.cardNumber
                                  animateLabel=localeObject.cardNumberLabel
                                  isValid={isCardNumberValid}
                                  textColor={isCardNumberValid ? component.color : dangerColor}
                                  keyboardType=#"numeric"
                                  borderTopLeftRadius=borderRadius
                                  borderTopRightRadius=borderRadius
                                  borderBottomWidth=borderWidth
                                  borderLeftWidth=borderWidth
                                  borderRightWidth=borderWidth
                                  borderTopWidth=borderWidth
                                  borderBottomLeftRadius=0.
                                  borderBottomRightRadius=0.
                                  iconRight=CustomInput.CustomIcon(
                                    <View style={s({flexDirection: #row, alignItems: #center})}>
                                      <CardSchemeComponent cardNumber={cardInput.value->JSON.Decode.string->Option.getOr("")} cardNetworks={None} />
                                      <UIUtils.RenderIf condition={ScanCardModule.isAvailable && cardInput.value->JSON.Decode.string->Option.getOr("") === ""}>
                                        <ScanCardButton 
                                          onScanCard={(pan, _, expireRef, _) => {
                                            let cardBrand = Validation.getCardBrand(pan)
                                            let formattedCardNumber = Validation.formatCardNumber(pan, Validation.cardType(cardBrand))
                                            cardInput.onChange(createSyntheticEvent(formattedCardNumber))
                                            networkInput.onChange(createSyntheticEvent(cardBrand))
                                            focusField(expireRef)
                                          }}
                                          expireRef
                                          cvvRef
                                        />
                                      </UIUtils.RenderIf>
                                    </View>
                                  )
                                />
                              </View>
                              
                              <View style={Style.s({
                                width: 100.->Style.pct,
                                flexDirection: #row,
                              })}>
                                <View style={Style.s({width: 50.->Style.pct})}>
                                  <CustomInput
                                    reference={Some(expireRef)}
                                    state={expiryInput.value->JSON.Decode.string->Option.getOr("")}
                                    setState={_ => ()}
                                    onChange={(event) => {
                                      let rawValue = ReactEvent.Form.target(event)["value"]
                                      let formattedExpiry = CardValidations.formatCardExpiryNumber(rawValue)
                                      let isExpiryValid = Validation.checkCardExpiry(formattedExpiry)
                                      
                                      expiryInput.onChange(createSyntheticEvent(formattedExpiry))
                                      let (_, year) = Validation.getExpiryDates(formattedExpiry)
                                      yearInput.onChange(createSyntheticEvent(year))
                                      
                                      if isExpiryValid {
                                        focusField(cvvRef)
                                      }
                                    }}
                                    placeholder=nativeProp.configuration.placeholder.expiryDate
                                    animateLabel=localeObject.validThruText
                                    isValid={isExpireDateValid}
                                    textColor={isExpireDateValid ? component.color : dangerColor}
                                    keyboardType=#"numeric"                      
                                    onKeyPress={(ev: ReactNative.TextInput.KeyPressEvent.t) => {
                                      if ev.nativeEvent.key == "Backspace" && expiryInput.value->JSON.Decode.string->Option.getOr("") == "" {
                                        focusField(cardRef)
                                      }
                                    }}
                                    borderTopWidth=0.25
                                    borderRightWidth=borderWidth
                                    borderTopLeftRadius=0.
                                    borderTopRightRadius=0.
                                    borderBottomRightRadius=0.
                                    borderBottomLeftRadius=borderRadius
                                    borderBottomWidth=borderWidth
                                    borderLeftWidth=borderWidth
                                  />
                                </View>
                                <View style={Style.s({width: 50.->Style.pct})}>
                                  <CustomInput
                                    reference={Some(cvvRef)}
                                    state={cvvInput.value->JSON.Decode.string->Option.getOr("")}
                                    setState={_ => ()}
                                    onChange={(event) => {
                                      let value = ReactEvent.Form.target(event)["value"]
                                      let currentCardNumber = cardInput.value->JSON.Decode.string->Option.getOr("")
                                      let cardBrand = Validation.getCardBrand(currentCardNumber)
                                      
                                      let formattedCvv = CardValidations.formatCVCNumber(value, cardBrand)
                                      let isCvvValid = Validation.checkCardCVC(formattedCvv, cardBrand)
                                      let shouldBlur = Validation.checkMaxCardCvv(formattedCvv, cardBrand)
                                      
                                      cvvInput.onChange(createSyntheticEvent(formattedCvv))
                                      
                                      if isCvvValid && shouldBlur {
                                        blurField(cvvRef)
                                      }
                                    }}
                                    placeholder=nativeProp.configuration.placeholder.cvv
                                    animateLabel=localeObject.cvcTextLabel
                                    isValid={isCvvValid}
                                    textColor={isCvvValid ? component.color : dangerColor}
                                    keyboardType=#"numeric"
                                    secureTextEntry={true}
                                    iconRight=CustomInput.CustomIcon(
                                      {Validation.checkCardCVC(cvvInput.value->JSON.Decode.string->Option.getOr(""), Validation.getCardBrand(cardInput.value->JSON.Decode.string->Option.getOr("")))
                                        ? <Icon name="cvvfilled" height=35. width=35. fill="black" />
                                        : <Icon name="cvvempty" height=35. width=35. fill="black" />}
                                    )
                                    onKeyPress={(ev: ReactNative.TextInput.KeyPressEvent.t) => {
                                      if ev.nativeEvent.key == "Backspace" && cvvInput.value->JSON.Decode.string->Option.getOr("") == "" {
                                        focusField(expireRef)
                                      }
                                    }}
                                    borderTopWidth=0.25
                                    borderLeftWidth=0.5
                                    borderTopLeftRadius=0.
                                    borderTopRightRadius=0.
                                    borderBottomLeftRadius=0.
                                    borderBottomRightRadius=borderRadius
                                    borderBottomWidth=borderWidth
                                    borderRightWidth=borderWidth
                                  />
                                </View>
                              </View>
                            
                              <ErrorText text=errorMsgText />
                            </View>
                          }}
                        />
                      }}
                    />
                  }}
                />
              }}
            />
          }}
        />
      | _ => React.null
      }}
    </View>
  </View>
}
