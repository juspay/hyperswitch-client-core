open ReactNative
open Style

type focusState = {active: bool, blurred: bool}
let untouched = {active: false, blurred: false}

type problem = Empty | Invalid

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~vaultDetails: VaultDetailsType.vaultDetails,
  ~formId: string,
  ~enabledCardSchemes: array<string>=[],
  ~accessible=?,
) => {
  let {getFormState, setFormValid} = React.useContext(CardStrategyContext.cardStrategyContext)
  let {eligibilityStatus} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let emitter = PaymentEvents.usePaymentEventEmitter()
  let {showErrors} = getFormState(formId)

  let numberRef = React.useRef(Nullable.null)
  let expiryRef = React.useRef(Nullable.null)
  let cvcRef = React.useRef(Nullable.null)
  let completedRef = React.useRef(Dict.make())
  let (mountError, setMountError) = React.useState(() => None)
  let (formFields, setFormFields) = React.useState(() => Dict.make())
  let (focusStates, setFocusStates) = React.useState(() => Dict.make())
  let (expiryFullyTyped, setExpiryFullyTyped) = React.useState(() => false)

  let {
    component,
    bgColor,
    borderWidth,
    borderRadius,
    gap,
    inputHeight,
    primaryColor,
    errorTextInputColor,
    normalTextInputBoderColor,
    shadowConfig,
  } = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let splitCardFields = nativeProp.configuration.splitCardFields
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowConfig, ())

  let hasCvc =
    fields
    ->Array.find((f: SuperpositionTypes.fieldConfig) =>
      f.fieldRenderType === SuperpositionTypes.Cvc
    )
    ->Option.isSome

  let vaultDetailsProp = React.useMemo2(
    () =>
      VaultDetailsType.toCardFormProp(
        vaultDetails,
        ~environment=nativeProp.hyperswitchConfig.environment,
      ),
    (vaultDetails, nativeProp.hyperswitchConfig.environment),
  )

  let onFormChange = (event: VaultBindings.cardFormChange) => {
    setFormValid(formId, event.complete && event.valid)
    setFormFields(_ => event.fields)
    let p = event.payload
    setExpiryFullyTyped(_ =>
      p.expiryMonth->Nullable.toOption->Option.isSome &&
        p.expiryYear->Nullable.toOption->Option.isSome
    )
    let info: PaymentEvents.cardInfo = {
      bin: p.bin->Nullable.toOption,
      last4: p.last4->Nullable.toOption,
      brand: p.brand->Nullable.toOption,
      expiryMonth: p.expiryMonth->Nullable.toOption,
      expiryYear: p.expiryYear->Nullable.toOption,
      formattedExpiry: p.formattedExpiry->Nullable.toOption,
      isCardNumberComplete: p.isCardNumberComplete,
      isCvcComplete: p.isCvcComplete,
      isExpiryComplete: p.isExpiryComplete,
      isCardNumberValid: p.isCardNumberValid,
      isExpiryValid: p.isExpiryValid,
    }
    emitter.emitCardInfo(~info)
  }

  let onFormError = (error: JSON.t) => {
    setFormValid(formId, false)
    let msg =
      error
      ->JSON.Decode.object
      ->Option.flatMap(o => o->Dict.get("message"))
      ->Option.flatMap(JSON.Decode.string)
      ->Utils.getNonEmptyOption
      ->Option.getOr(VaultTokenNormalizer.fallbackMessage)
    setMountError(_ => Some(msg))
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
  let onFieldFocus = (event: VaultBindings.fieldEvent) => setFocus(event.elementType, true)
  let onFieldBlur = (event: VaultBindings.fieldEvent) => setFocus(event.elementType, false)

  React.useEffect0(() => {
    Some(() => setFormValid(formId, false))
  })

  let focusOf = elementType => focusStates->Dict.get(elementType)->Option.getOr(untouched)
  let isActive = elementType => focusOf(elementType).active
  let isTouched = elementType => focusOf(elementType).blurred || showErrors
  let problemOf = elementType =>
    switch formFields->Dict.get(elementType) {
    | Some(change) if change.empty => Some(Empty)
    | Some(change) if !change.valid => Some(Invalid)
    | Some(_) => None
    | None => Some(Empty)
    }
  let expiryInvalidComplete = expiryFullyTyped && problemOf("cardExpiry") === Some(Invalid)
  let looksValid = elementType =>
    problemOf(elementType)->Option.isNone ||
      ((!isTouched(elementType) || isActive(elementType)) &&
        !(elementType === "cardExpiry" && expiryInvalidComplete))

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
  | Some(Empty) if hasCvc && isTouched("cardCvc") && !isActive("cardCvc") =>
    Some(localeObject.cvcNumberEmptyText)
  | Some(Invalid) if hasCvc && isTouched("cardCvc") && !isActive("cardCvc") =>
    Some(localeObject.inValidCVCErrorText)
  | _ => None
  }
  let detectedBrand =
    formFields->Dict.get("cardNumber")->Option.flatMap(change => change.brand)->Option.getOr("")
  let networkMessage =
    showErrors &&
    detectedBrand !== "" &&
    enabledCardSchemes->Array.length > 0 &&
    enabledCardSchemes
    ->Array.find(scheme => scheme->String.toLowerCase === detectedBrand->String.toLowerCase)
    ->Option.isNone
      ? Some(localeObject.unsupportedCardErrorText)
      : None
  let eligibilityMessage = switch eligibilityStatus {
  | DynamicFieldsContext.Denied => Some(localeObject.cardNotEligibleText)
  | _ => None
  }
  let firstSome = messages =>
    messages->Array.reduce(None, (acc, m) => acc->Option.isSome ? acc : m)

  let fieldBox = (
    ~elementType,
    ~borderTopWidth=?,
    ~borderBottomWidth=?,
    ~borderLeftWidth=?,
    ~borderRightWidth=?,
    ~borderTopLeftRadius=?,
    ~borderTopRightRadius=?,
    ~borderBottomLeftRadius=?,
    ~borderBottomRightRadius=?,
    (),
  ) =>
    array([
      bgColor,
      s({
        backgroundColor: component.background,
        borderTopWidth: borderTopWidth->Option.getOr(borderWidth),
        borderBottomWidth: borderBottomWidth->Option.getOr(borderWidth),
        borderLeftWidth: borderLeftWidth->Option.getOr(borderWidth),
        borderRightWidth: borderRightWidth->Option.getOr(borderWidth),
        borderTopLeftRadius: borderTopLeftRadius->Option.getOr(borderRadius),
        borderTopRightRadius: borderTopRightRadius->Option.getOr(borderRadius),
        borderBottomLeftRadius: borderBottomLeftRadius->Option.getOr(borderRadius),
        borderBottomRightRadius: borderBottomRightRadius->Option.getOr(borderRadius),
        height: inputHeight->dp,
        flexDirection: #row,
        borderColor: looksValid(elementType)
          ? isActive(elementType) ? primaryColor : normalTextInputBoderColor
          : errorTextInputColor,
        width: 100.->pct,
        paddingHorizontal: 13.->dp,
        alignItems: #center,
        justifyContent: #center,
      }),
      shadowStyle,
    ])

  let emptyOf = kind => formFields->Dict.get(kind)->Option.mapOr(true, field => field.empty)
  let completeOf = kind => formFields->Dict.get(kind)->Option.mapOr(false, field => field.complete)
  let advanceFocus = (event: VaultBindings.fieldChange) => {
    let wasComplete = completedRef.current->Dict.get(event.elementType)->Option.getOr(false)
    completedRef.current->Dict.set(event.elementType, event.complete)
    if event.complete && !wasComplete && isActive(event.elementType) {
      switch event.elementType {
      | "cardNumber" => VaultBindings.focusField(expiryRef)
      | "cardExpiry" if hasCvc => VaultBindings.focusField(cvcRef)
      | _ => ()
      }
    }
  }

  let errorLine = messages => <ErrorText text={firstSome(messages)} />

  let isVgs = switch vaultDetails.config {
  | VaultDetailsType.VgsVault(_) => true
  | VaultDetailsType.HyperswitchVault(_) => false
  }
  let brandIconFromProvider =
    isVgs && nativeProp.configuration.paymentMethodLayout.cardBrandIcon !== Hidden
  let cvcIconFromProvider =
    isVgs && nativeProp.configuration.paymentMethodLayout.cvcIcon === Shown

  let cardBrandIcon = isVgs
    ? None
    : Some(
        <CardSchemeComponent
          eligibleCardSchemes=[]
          showCardSchemeDropDown=false
          cardBrand=detectedBrand
          setCardBrand={_ => ()}
          cardBrandIcon=nativeProp.configuration.paymentMethodLayout.cardBrandIcon
        />,
      )
  let cvcIcon =
    !isVgs && nativeProp.configuration.paymentMethodLayout.cvcIcon === Shown
      ? Some(
          <View
            style={s({
              height: 46.->dp,
              display: #flex,
              flexDirection: #row,
              justifyContent: #center,
              alignItems: #center,
            })}>
            <Icon
              name="cvv" height=32. width=32. fill={completeOf("cardCvc") ? primaryColor : "#858F97"}
            />
          </View>,
        )
      : None

  <View ?accessible>
    <VaultBindings.CardForm
      id=formId vaultDetails=vaultDetailsProp onChange=onFormChange onError=onFormError>
      <View style={s({marginBottom: gap->dp})}>
        <View style={s({width: 100.->pct, borderRadius})}>
          <View
            style={s({
              width: 100.->pct,
              marginBottom: ?(splitCardFields ? Some(gap->dp) : None),
            })}>
            <View
              style={fieldBox(
                ~elementType="cardNumber",
                ~borderBottomWidth=?{splitCardFields ? None : Some(borderWidth /. 2.)},
                ~borderBottomLeftRadius=?{splitCardFields ? None : Some(0.)},
                ~borderBottomRightRadius=?{splitCardFields ? None : Some(0.)},
                (),
              )}>
              <VaultInput
                  elementType="cardNumber"
                  height=inputHeight
                  reference=numberRef
                  label=localeObject.cardNumberLabel
                  active={isActive("cardNumber")}
                  empty={emptyOf("cardNumber")}
                  valid={looksValid("cardNumber")}
                  iconRight=?cardBrandIcon
                  useProviderIcon=brandIconFromProvider
                  onChange=advanceFocus
                testID=TestUtils.cardNumberInputTestId
                placeholder={nativeProp.configuration.placeholder.cardNumber->Option.getOr(
                  localeObject.cardNumberLabel,
                )}
                onFocus=onFieldFocus
                onBlur=onFieldBlur
              />
            </View>
            <UIUtils.RenderIf condition={splitCardFields}> {errorLine([numberMessage])} </UIUtils.RenderIf>
          </View>
          <View
            style={s({
              flexDirection: localeObject.localeDirection === "rtl" ? #"row-reverse" : #row,
              gap: ?(splitCardFields ? Some(gap->dp) : None),
            })}>
            <View style={s({flex: 1.})}>
              <View
                style={fieldBox(
                  ~elementType="cardExpiry",
                  ~borderTopWidth=?{splitCardFields ? None : Some(borderWidth /. 2.)},
                  ~borderRightWidth=?{splitCardFields
                    ? None
                    : Some(hasCvc ? borderWidth /. 2. : borderWidth)},
                  ~borderTopLeftRadius=?{splitCardFields ? None : Some(0.)},
                  ~borderTopRightRadius=?{splitCardFields ? None : Some(0.)},
                  ~borderBottomRightRadius=?{splitCardFields
                    ? None
                    : Some(hasCvc ? 0. : borderRadius)},
                  (),
                )}>
                <VaultInput
                  elementType="cardExpiry"
                  height=inputHeight
                  reference=expiryRef
                  label=localeObject.validThruText
                  active={isActive("cardExpiry")}
                  empty={emptyOf("cardExpiry")}
                  valid={looksValid("cardExpiry")}
                  onChange=advanceFocus
                    testID=TestUtils.expiryInputTestId
                  placeholder={nativeProp.configuration.placeholder.expiryDate->Option.getOr(
                    localeObject.validThruText,
                  )}
                  onFocus=onFieldFocus
                  onBlur=onFieldBlur
                />
              </View>
              <UIUtils.RenderIf condition={splitCardFields}>
                {errorLine([expiryMessage])}
              </UIUtils.RenderIf>
            </View>
            <UIUtils.RenderIf condition={hasCvc}>
              <View style={s({flex: 1.})}>
                <View
                  style={fieldBox(
                    ~elementType="cardCvc",
                    ~borderTopWidth={splitCardFields ? borderWidth : borderWidth /. 2.},
                    ~borderLeftWidth={splitCardFields ? borderWidth : borderWidth /. 2.},
                    ~borderTopLeftRadius={splitCardFields ? borderRadius : 0.},
                    ~borderTopRightRadius={splitCardFields ? borderRadius : 0.},
                    ~borderBottomLeftRadius={splitCardFields ? borderRadius : 0.},
                    (),
                  )}>
                  <VaultInput
                  elementType="cardCvc"
                  height=inputHeight
                  reference=cvcRef
                  label=localeObject.cvcTextLabel
                  active={isActive("cardCvc")}
                  empty={emptyOf("cardCvc")}
                  valid={looksValid("cardCvc")}
                  iconRight=?cvcIcon
                  useProviderIcon=cvcIconFromProvider
                  onChange=advanceFocus
                        testID=TestUtils.cvcInputTestId
                    placeholder={nativeProp.configuration.placeholder.cvv->Option.getOr(
                      localeObject.cvcTextLabel,
                    )}
                    onFocus=onFieldFocus
                    onBlur=onFieldBlur
                  />
                </View>
                <UIUtils.RenderIf condition={splitCardFields}>
                  {errorLine([cvcMessage, networkMessage, eligibilityMessage])}
                </UIUtils.RenderIf>
              </View>
            </UIUtils.RenderIf>
          </View>
        </View>
        <UIUtils.RenderIf condition={!splitCardFields}>
          {errorLine([numberMessage, expiryMessage, cvcMessage, networkMessage, eligibilityMessage])}
        </UIUtils.RenderIf>
      </View>
    </VaultBindings.CardForm>
    <ErrorText text={mountError} />
  </View>
}
