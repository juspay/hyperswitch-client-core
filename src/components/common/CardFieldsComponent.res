open ReactNative
open Style
open SuperpositionTypes
open ReactFinalForm

@react.component
let make = (~fields: array<fieldConfig>, ~createSyntheticEvent: string => ReactEvent.Form.t, ~lastActiveRef: option<string>=?, ~setLastActiveRef: option<string => unit>=?, ~submitAttempted: bool=false) => {
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
  let cvvFieldConfig = fields->Array.find(field => 
    field.outputPath->String.endsWith("card_cvc"))

  <View>
    <View style={Style.s({marginBottom: 12.->Style.dp})}>
    </View>
    
    <View style={Style.s({width: 100.->Style.pct})}>
      {switch (cardNumberField, cardNetworkField, expiryMonthField, expiryYearField, cvvFieldConfig) {
      | (Some(cardField), Some(networkField), Some(monthField), Some(yearField), Some(cvvField)) =>
        <ReactFinalForm.Field
          name={cardField.name}
          validate={(value, _allValues) => {
            let cardNumber = value->Option.getOr("")
            if cardNumber->String.length == 0 {
              Promise.resolve(Nullable.make(localeObject.inValidCardErrorText))
            } else {
              if !Validation.cardValid(cardNumber, Validation.getCardBrand(cardNumber)) {
                Promise.resolve(Nullable.make(localeObject.inValidCardErrorText))
              } else {
                Promise.resolve(Nullable.null)
              }
            }
          }}
          render={({input: cardInput, meta: cardMeta}) => {
            <ReactFinalForm.Field
              name={networkField.name}
              render={({input: networkInput, meta: _}) => {
                <ReactFinalForm.Field
                  name={monthField.name}
                  validate={(value, _allValues) => {
                    let expireDate = value->Option.getOr("")
                    if expireDate->String.length == 0 {
                      Promise.resolve(Nullable.make(localeObject.inValidExpiryErrorText))
                    } else {
                      if !Validation.checkCardExpiry(expireDate) {
                        Promise.resolve(Nullable.make(localeObject.inValidExpiryErrorText))
                      } else {
                        Promise.resolve(Nullable.null)
                      }
                    }
                  }}
                  render={({input: expiryInput, meta: expiryMeta}) => {
                    <ReactFinalForm.Field
                      name={yearField.name}
                      render={({input: yearInput, meta: _}) => {
                        <ReactFinalForm.Field
                          name={cvvField.name}
                          validate={(value, allValues) => {
                            let cvvValue = value->Option.getOr("")
                            let cardNumber = switch allValues->JSON.Decode.object {
                            | Some(obj) => 
                              switch obj->Dict.get(cardField.name) {
                              | Some(cardVal) => cardVal->JSON.Decode.string->Option.getOr("")
                              | None => ""
                              }
                            | None => ""
                            }
                            
                            if cvvValue->String.length == 0 {
                              Promise.resolve(Nullable.make(localeObject.inValidCVCErrorText))
                            } else {
                              let cardBrand = Validation.getCardBrand(cardNumber)
                              if !Validation.checkCardCVC(cvvValue, cardBrand) {
                                Promise.resolve(Nullable.make(localeObject.inValidCVCErrorText))
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
                            
                            let cleanCardNumber = cardNumber->CardValidations.clearSpaces
                            let maxLength = Validation.maxCardLength(cardBrand)
                            let isAtMaxLength = cleanCardNumber->String.length == maxLength                            
                            let shouldValidateCard = (cardMeta.touched && !cardMeta.active) || isAtMaxLength || submitAttempted
                            let isCardNumberValid = if shouldValidateCard {
                              if cardNumber->String.length == 0 {
                                false
                              } else {
                                Validation.cardValid(cardNumber, cardBrand)
                              }
                            } else {
                              true
                            }
                            
                            let expiryMaxLength = 7
                            let isExpiryAtMaxLength = expireDate->String.length == expiryMaxLength
                            let shouldValidateExpiry = (expiryMeta.touched && !expiryMeta.active) || isExpiryAtMaxLength || submitAttempted
                            let isExpireDateValid = if shouldValidateExpiry {
                              if expireDate->String.length == 0 {
                                false 
                              } else {
                                Validation.checkCardExpiry(expireDate)
                              }
                            } else {
                              true 
                            }
                            
                            let isCvvAtMaxLength = Validation.checkMaxCardCvv(cvv, cardBrand)
                            let shouldValidateCvv = (cvvMeta.touched && !cvvMeta.active) || isCvvAtMaxLength || submitAttempted
                            let isCvvValid = if shouldValidateCvv {
                              if cvv->String.length == 0 {
                                false
                              } else {
                                Validation.checkCardCVC(cvv, cardBrand)
                              }
                            } else {
                              true 
                            }
                            
                            let errorMsgText = switch lastActiveRef {
                            | Some(lastActiveFieldName) => 
                              if lastActiveFieldName == cardField.name && (cardMeta.touched || submitAttempted) && !isCardNumberValid {
                                Some(localeObject.inValidCardErrorText)
                              } else if lastActiveFieldName == monthField.name && (expiryMeta.touched || submitAttempted) && !isExpireDateValid {
                                Some(localeObject.inValidExpiryErrorText)
                              } else if lastActiveFieldName == cvvField.name && (cvvMeta.touched || submitAttempted) && !isCvvValid {
                                Some(localeObject.inValidCVCErrorText)
                              } else {
                                if (isAtMaxLength || submitAttempted) && !isCardNumberValid {
                                  Some(localeObject.inValidCardErrorText)
                                } else if (isExpiryAtMaxLength || submitAttempted) && !isExpireDateValid {
                                  Some(localeObject.inValidExpiryErrorText)
                                } else if (isCvvAtMaxLength || submitAttempted) && !isCvvValid {
                                  Some(localeObject.inValidCVCErrorText)
                                } else {
                                  None
                                }
                              }
                            | None => 
                              if (isAtMaxLength || submitAttempted) && !isCardNumberValid {
                                Some(localeObject.inValidCardErrorText)
                              } else if (isExpiryAtMaxLength || submitAttempted) && !isExpireDateValid {
                                Some(localeObject.inValidExpiryErrorText)
                              } else if (isCvvAtMaxLength || submitAttempted) && !isCvvValid {
                                Some(localeObject.inValidCVCErrorText)
                              } else {
                                None
                              }
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
                                  onFocusRFF=cardInput.onFocus
                                  onBlurRFF={(event) => {
                                    cardInput.onBlur(event)
                                    switch setLastActiveRef {
                                    | Some(setFn) => setFn(cardField.name)
                                    | None => ()
                                    }
                                  }}
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
                                    onFocusRFF=expiryInput.onFocus
                                    onBlurRFF={(event) => {
                                      expiryInput.onBlur(event)
                                      switch setLastActiveRef {
                                      | Some(setFn) => setFn(monthField.name)
                                      | None => ()
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
                                    onFocusRFF=cvvInput.onFocus
                                    onBlurRFF={(event) => {
                                      cvvInput.onBlur(event)
                                      switch setLastActiveRef {
                                      | Some(setFn) => setFn(cvvField.name)
                                      | None => ()
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
