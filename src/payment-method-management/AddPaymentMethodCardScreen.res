open ReactNative
open Style

type focusState = {active: bool, blurred: bool}
let untouched = {active: false, blurred: false}

type problem = Empty | Invalid

@react.component
let make = (
  ~paymentMethodsEnabled: array<PaymentMethodSessionTypes.paymentMethodEnabled>,
  ~showBackButton: bool,
  ~onBack: unit => unit,
  ~addConfirmRef: React.ref<option<unit => unit>>,
  ~setIsSaving: (bool => bool) => unit,
  ~fillHeight: bool=true,
) => {
  let {
    component,
    gap,
    inputHeight,
    placeholderColor,
    borderWidth,
    borderRadius,
    primaryColor,
    normalTextInputBoderColor,
    dangerColor,
    shadowConfig,
    placeholderTextSizeAdjust,
    fontScale,
  } = ThemebasedStyle.useThemeBasedStyle()
  let fontFamily = FontFamily.useCustomFontFamily()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowConfig, ())
  let localeObject = GetLocale.useGetLocalObj()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let isBusy = switch loading {
  | ProcessingPayments | ProcessingPaymentsWithOverlay => true
  | _ => false
  }

  let numberRef = React.useRef(Nullable.null)
  let expiryRef = React.useRef(Nullable.null)
  let cvcRef = React.useRef(Nullable.null)
  let cardFormRef = React.useRef(Nullable.null)
  let completedRef = React.useRef(Dict.make())
  let inFlightRef = React.useRef(false)
  let (formFields, setFormFields) = React.useState(() => None)
  let (canSubmit, setCanSubmit) = React.useState(() => false)
  let (focusStates, setFocusStates) = React.useState(() => Dict.make())
  let (showErrors, setShowErrors) = React.useState(() => false)
  let (expiryFullyTyped, setExpiryFullyTyped) = React.useState(() => false)
  let (nickName, setNickName) = React.useState(_ => None)
  let (isNicknameValid, setIsNicknameValid) = React.useState(_ => true)

  let changeOf = elementType =>
    formFields->Option.flatMap(fields =>
      switch elementType {
      | "cardNumber" => Some(fields.VaultDirectBindings.cardNumber)
      | "cardExpiry" => Some(fields.VaultDirectBindings.cardExpiry)
      | "cardCvc" => Some(fields.VaultDirectBindings.cardCvc)
      | _ => None
      }
    )

  let onFormChange = (event: VaultDirectBindings.cardFormChange) => {
    setFormFields(_ => Some(event.fields))
    setCanSubmit(_ => event.canSubmit)
    let p = event.payload
    setExpiryFullyTyped(_ =>
      p.expiryMonth->Option.isSome && p.expiryYear->Option.isSome
    )
  }

  let setFocus = (elementType, active) =>
    setFocusStates(prev => {
      let current = prev->Dict.get(elementType)->Option.getOr(untouched)
      let copy = prev->Dict.copy
      copy->Dict.set(
        elementType,
        {active, blurred: current.blurred || (!active && current.active)},
      )
      copy
    })
  let onFieldFocus = (event: VaultDirectBindings.fieldEvent) => setFocus(event.elementType, true)
  let onFieldBlur = (event: VaultDirectBindings.fieldEvent) => setFocus(event.elementType, false)

  let focusOf = elementType => focusStates->Dict.get(elementType)->Option.getOr(untouched)
  let isActive = elementType => focusOf(elementType).active
  let isTouched = elementType => focusOf(elementType).blurred || showErrors
  let problemOf = elementType =>
    switch changeOf(elementType) {
    | Some(change) if change.VaultDirectBindings.empty => Some(Empty)
    | Some(change) if !change.valid => Some(Invalid)
    | Some(_) => None
    | None => Some(Empty)
    }
  let expiryInvalidComplete = expiryFullyTyped && problemOf("cardExpiry") === Some(Invalid)

  let advanceFocus = (event: VaultDirectBindings.fieldChange) => {
    let wasComplete = completedRef.current->Dict.get(event.elementType)->Option.getOr(false)
    completedRef.current->Dict.set(event.elementType, event.complete)
    if event.complete && !wasComplete && isActive(event.elementType) {
      switch event.elementType {
      | "cardNumber" => VaultDirectBindings.focusField(expiryRef)
      | "cardExpiry" => VaultDirectBindings.focusField(cvcRef)
      | _ => ()
      }
    }
  }

  // Reserved for a future card-brand icon in the number field row.
  let _detectedBrand =
    changeOf("cardNumber")
    ->Option.flatMap(change => change.brand)
    ->Option.getOr("")

  let numberMessage = switch problemOf("cardNumber") {
  | Some(Empty) if isTouched("cardNumber") => Some(localeObject.cardNumberEmptyText)
  | Some(Invalid) if isTouched("cardNumber") => Some(localeObject.inValidCardErrorText)
  | _ => None
  }
  let expiryMessage = switch problemOf("cardExpiry") {
  | Some(Empty) if isTouched("cardExpiry") => Some(localeObject.cardExpiryDateEmptyText)
  | Some(Invalid) if (isTouched("cardExpiry") && !isActive("cardExpiry")) || expiryInvalidComplete =>
    Some(localeObject.inValidExpiryErrorText)
  | _ => None
  }
  let cvcMessage = switch problemOf("cardCvc") {
  | Some(Empty) if isTouched("cardCvc") && !isActive("cardCvc") =>
    Some(localeObject.cvcNumberEmptyText)
  | Some(Invalid) if isTouched("cardCvc") && !isActive("cardCvc") =>
    Some(localeObject.inValidCVCErrorText)
  | _ => None
  }
  let firstSome = messages =>
    messages->Array.reduce(None, (acc, m) => acc->Option.isSome ? acc : m)
  let errorLine = messages => <ErrorText text={firstSome(messages)} />

  let refuse = () => {
    setShowErrors(_ => true)
    notifyValidationFailure()
  }

  let cardEntrySupported =
    paymentMethodsEnabled->Array.some(item => item.payment_method_type == "card")

  let notifySaved = () =>
    handleSuccessFailure(
      ~apiResStatus={
        type_: "payment_method_session",
        status: "succeeded",
        code: "",
        message: "Card saved successfully",
      },
      (),
    )

  let notifyFailed = message =>
    handleSuccessFailure(
      ~apiResStatus={
        type_: "payment_method_session",
        status: "failed",
        code: "",
        message,
      },
      (),
    )

  let handleSaveCard = _ =>
    if inFlightRef.current || isBusy {
      ()
    } else if !canSubmit || !isNicknameValid {
      refuse()
    } else {
      inFlightRef.current = true
      setIsSaving(_ => true)
      setLoading(ProcessingPayments)
      switch cardFormRef.current->Nullable.toOption {
      | None => inFlightRef.current = false
      | Some(handle) =>
        let paymentMethodData =
          nickName
          ->Option.map(String.trim)
          ->Option.flatMap(name => name == "" ? None : Some(name))
          ->Option.map(name =>
            [("nickName", name->JSON.Encode.string)]
            ->Dict.fromArray
            ->JSON.Encode.object
          )
        handle.VaultDirectBindings.tokenize(paymentMethodData)
        ->Promise.then(result => {
          inFlightRef.current = false
          switch result.status {
          | "success" => notifySaved()
          | "validation_error" =>
            setLoading(FillingDetails)
            setIsSaving(_ => false)
            refuse()
          | _ =>
            let message = switch result.error {
            | Some(error) => error.VaultDirectBindings.message
            | None => VaultTokenNormalizer.fallbackMessage
            }
            setLoading(FillingDetails)
            notifyFailed(message)
          }
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          inFlightRef.current = false
          setLoading(FillingDetails)
          notifyFailed(VaultTokenNormalizer.fallbackMessage)
          Promise.resolve()
        })
        ->ignore
      }
    }

  React.useEffect1(() => {
    addConfirmRef.current = Some(handleSaveCard)
    None
  }, [handleSaveCard])

  let vaultAppearance =
    [
      (
        "variables",
        [
          ("colorPrimary", primaryColor->JSON.Encode.string),
          ("colorText", component.color->JSON.Encode.string),
          ("colorDanger", dangerColor->JSON.Encode.string),
          ("colorTextPlaceholder", placeholderColor->JSON.Encode.string),
          ("colorBackground", component.background->JSON.Encode.string),
          ("borderColor", normalTextInputBoderColor->JSON.Encode.string),
          ("borderRadius", borderRadius->JSON.Encode.float),
          ("borderWidth", borderWidth->JSON.Encode.float),
          ("fontFamily", fontFamily->JSON.Encode.string),
          ("inputFieldHeight", inputHeight->JSON.Encode.float),
          ("gap", gap->JSON.Encode.float),
          ("fontScale", fontScale->JSON.Encode.float),
          ("placeholderTextSizeAdjust", placeholderTextSizeAdjust->JSON.Encode.float),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object,
      ),
      (
        "labels",
        "floating"->JSON.Encode.string,
      ),
    ]
    ->Dict.fromArray
    ->JSON.Encode.object

  // Same appearance object that drives the outer PMM CustomInput fields.
  let fieldStyles: VaultDirectBindings.fieldStyles = {
    container: array([
      s({
        backgroundColor: component.background,
        borderWidth,
        borderRadius,
        height: inputHeight->dp,
        flexDirection: #row,
        width: 100.->pct,
        paddingHorizontal: 13.->dp,
        alignItems: #center,
        justifyContent: #center,
      }),
      shadowStyle,
    ]),
    input: s({
      padding: 0.->dp,
      height: (inputHeight *. 0.7)->dp,
      width: 100.->pct,
      color: component.color,
      fontFamily,
      fontSize: (16. +. placeholderTextSizeAdjust) *. fontScale,
    }),
    placeholder: s({
      color: placeholderColor,
      fontFamily,
      fontSize: (16. +. placeholderTextSizeAdjust) *. fontScale,
    }),
    label: s({
      color: placeholderColor,
      fontFamily,
      fontWeight: #500,
    }),
  }

  let vaultDetails =
    nativeProp.paymentSessionConfig.sdkAuthorization
    ->Utils.getNonEmptyOption
    ->Option.map(
      sdkAuthorization =>
        (
          {
            vaultTypeStr: "hyperswitch",
            config: VaultDetailsType.HyperswitchVault({sdkAuthorization: sdkAuthorization}),
          }: VaultDetailsType.vaultDetails
        )->VaultDetailsType.toCardFormProp(
          ~environment=nativeProp.hyperswitchConfig.environment,
        ),
    )

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
      ? switch vaultDetails {
        | Some(details) =>
          <VaultDirectBindings.CardForm
            ref=cardFormRef
            vaultDetails=details
            appearance=vaultAppearance
            alwaysSendCustomerAcceptance=true
            environment={VaultDetailsType.environmentName(nativeProp.hyperswitchConfig.environment)}
            onChange=onFormChange>
            // Bottom padding keeps the nickname field fully clear of the pinned
            // "Save card" CTA (sheet) / widget edge — it previously sat flush
            // against it and could be clipped.
            <View style={s({paddingHorizontal: 24.->dp, paddingTop: 16.->dp, paddingBottom: 24.->dp})}>
              <VaultDirectBindings.CardNumberField
                ref=numberRef
                styles=fieldStyles
                errorDisplay="colorOnly"
                placeholder={nativeProp.configuration.placeholder.cardNumber->Option.getOr(
                  localeObject.cardNumberLabel,
                )}
                testID=TestUtils.cardNumberInputTestId
                onChange=advanceFocus
                onFocus=onFieldFocus
                onBlur=onFieldBlur
              />
              {errorLine([numberMessage])}
              <Space height=10. />
              <View style={s({flexDirection: #row, flexWrap: #nowrap})}>
                <View style={s({flex: 1.})}>
                  <VaultDirectBindings.CardExpiryField
                    ref=expiryRef
                    styles=fieldStyles
                    errorDisplay="colorOnly"
                    placeholder={nativeProp.configuration.placeholder.expiryDate->Option.getOr(
                      localeObject.validThruText,
                    )}
                    testID=TestUtils.expiryInputTestId
                    onChange=advanceFocus
                    onFocus=onFieldFocus
                    onBlur=onFieldBlur
                  />
                </View>
                <Space width=10. />
                <View style={s({flex: 1.})}>
                  <VaultDirectBindings.CardCVCField
                    ref=cvcRef
                    styles=fieldStyles
                    errorDisplay="colorOnly"
                    placeholder={nativeProp.configuration.placeholder.cvv->Option.getOr(
                      localeObject.cvcTextLabel,
                    )}
                    testID=TestUtils.cvcInputTestId
                    onChange=advanceFocus
                    onFocus=onFieldFocus
                    onBlur=onFieldBlur
                  />
                </View>
              </View>
              {errorLine([expiryMessage, cvcMessage])}
              <NickNameElement
                nickname=nickName
                setNickname={value => setNickName(_ => value)}
                setIsNicknameValid={value => setIsNicknameValid(_ => value)}
                accessible=true
              />
            </View>
          </VaultDirectBindings.CardForm>
        | None =>
          <View style={s({padding: 24.->dp, justifyContent: #center, alignItems: #center})}>
            <TextWrapper text=localeObject.somethingWentWrongText textType={ModalTextLight} />
          </View>
        }
      : <View
          style={s({
            width: 100.->pct,
            padding: 24.->dp,
            backgroundColor: component.background,
            alignItems: #center,
          })}>
          <TextWrapper text=localeObject.noPaymentMethodsAvailableText textType={ModalTextLight} />
        </View>}
  </ScrollView>
}
