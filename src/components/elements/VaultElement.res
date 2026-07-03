open ReactNative
open Style
type formHandle = {submit: unit => promise<DynamicFieldsContext.vaultSubmitResult>}

type fieldState = {
  kind: string,
  isValid: bool,
  isEmpty: bool,
  isFocused: bool,
  isDirty: bool,
  validationErrors: array<string>,
}

module HyperswitchForm = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~ref: React.ref<Js.nullable<formHandle>>=?,
    ~config: SessionsType.providerConfig,
    ~onError: exn => unit=?,
    ~children: React.element,
  ) => React.element = "HyperswitchForm"
}

module CardNumberWidget = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~style: Style.t=?,
    ~textStyle: Style.t=?,
    ~placeholder: string=?,
    ~onStateChange: fieldState => unit=?,
  ) => React.element = "CardNumberWidget"
}

module CardExpiryWidget = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~style: Style.t=?,
    ~textStyle: Style.t=?,
    ~placeholder: string=?,
    ~onStateChange: fieldState => unit=?,
  ) => React.element = "CardExpiryWidget"
}

module CardCVCWidget = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~style: Style.t=?,
    ~textStyle: Style.t=?,
    ~placeholder: string=?,
    ~onStateChange: fieldState => unit=?,
  ) => React.element = "CardCVCWidget"
}

module CardHolderWidget = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~style: Style.t=?,
    ~textStyle: Style.t=?,
    ~placeholder: string=?,
    ~onStateChange: fieldState => unit=?,
  ) => React.element = "CardHolderWidget"
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
  // The vault widgets tokenize inside VGS, so ReactFinalForm validation/formatting
  // and the card-scheme allowlist don't apply here — they are accepted only for
  // interface parity with CardElement. `fields` and `accessible` are used below.
  let _ = (createFieldValidator, formatValue, enabledCardSchemes, checkEligibility)

  let (error, setError) = React.useState((): option<string> => None)
  let formRef: React.ref<Js.nullable<formHandle>> = React.useRef(
    Js.Nullable.null,
  )
  let (_, _, sessionData, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let vaultConfig = sessionData->Option.flatMap(d => d.vaultDetails)
  let {vaultSubmitRef, setVaultFormValid, vaultShowErrors} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )
  let (fieldStates, setFieldStates) = React.useState(() => Dict.make())

  let {
    component,
    bgColor,
    borderWidth,
    borderRadius,
    gap,
    inputHeight,
    normalTextInputBoderColor,
    shadowConfig,
  } = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let splitCardFields = nativeProp.configuration.splitCardFields
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowConfig, ())

  let findField = (rt: SuperpositionTypes.fieldType) =>
    fields->Array.find((f: SuperpositionTypes.fieldConfig) => f.fieldRenderType === rt)
  let hasCvc = findField(SuperpositionTypes.Cvc)->Option.isSome
  let hasCardHolder = false //findField(SuperpositionTypes.CardHolderName)->Option.isSome

  let onFieldState = (st: fieldState) =>
    setFieldStates(prev => {
      let next = prev->Dict.copy
      next->Dict.set(st.kind, st)
      next
    })

  let requiredKinds =
    ["card_number", "card_expiry"]
    ->Array.concat(hasCvc ? ["card_cvc"] : [])
    ->Array.concat(hasCardHolder ? ["card_holder"] : [])

  let mapVaultError = codeOpt =>
    switch codeOpt {
    | Some("INVALID_CARD_NUMBER") => localeObject.inValidCardErrorText
    | Some("INVALID_EXP_DATE") => localeObject.inValidExpiryErrorText
    | Some("INVALID_CVC") => localeObject.inValidCVCErrorText
    | Some("INVALID_CVC_LEHGTH") => localeObject.inCompleteCVCErrorText
    | Some(other) => other
    | None => ""
    }

  let emptyText = kind =>
    switch kind {
    | "card_number" => localeObject.cardNumberEmptyText
    | "card_expiry" => localeObject.cardExpiryDateEmptyText
    | "card_cvc" => localeObject.cvcNumberEmptyText
    | "card_holder" => localeObject.cardHolderNameRequiredText
    | _ => ""
    }

  let fieldError = kind =>
    switch fieldStates->Dict.get(kind) {
    | Some(st) if st.isFocused => None
    | Some(st) if !st.isValid && !st.isEmpty && (st.isDirty || vaultShowErrors) =>
      Some(mapVaultError(st.validationErrors->Array.get(0)))
    | Some(st) if st.isEmpty && vaultShowErrors => Some(emptyText(kind))
    | None if vaultShowErrors => Some(emptyText(kind))
    | _ => None
    }

  React.useEffect1(() => {
    let allValid = requiredKinds->Array.every(k =>
      switch fieldStates->Dict.get(k) {
      | Some(st) => st.isValid && !st.isEmpty
      | None => false
      }
    )
    setVaultFormValid(allValid)
    None
  }, [fieldStates])

  React.useEffect0(() => {
    let submit = (): promise<DynamicFieldsContext.vaultSubmitResult> =>
      switch formRef.current->Js.Nullable.toOption {
      | Some(h) => h.submit()
      | None =>
        Promise.resolve(
          ({status: "not_ready", data: None, errors: None}: DynamicFieldsContext.vaultSubmitResult),
        )
      }
    switch vaultSubmitRef {
    | Some(r) => r.current = Some(submit)
    | None => ()
    }
    Some(
      () =>
        switch vaultSubmitRef {
        | Some(r) => r.current = None
        | None => ()
        },
    )
  })

  let fieldBox = (
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
        borderColor: normalTextInputBoderColor,
        paddingHorizontal: 13.->dp,
        alignItems: #center,
        justifyContent: #center,
      }),
      shadowStyle,
    ])

  // `style` -> the widget's container (drawn by the wrapper View here it just
  // fills); `textStyle` -> the secure input's text so it matches the theme.
  let widgetBoxFill = s({flex: 1., height: 100.->pct})
  let widgetTextStyle = s({color: component.color, fontSize: 16.})

  let firstFieldError = requiredKinds->Array.reduce(None, (acc, k) =>
    switch acc {
    | Some(_) => acc
    | None => fieldError(k)
    }
  )

  <View ?accessible>
    {switch vaultConfig {
    | None => React.null
    | Some(config) =>
      <HyperswitchForm
        ref=formRef
        config
        onError={e => {
          let msg =
            Js.Exn.asJsExn(e)->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("Unknown error")
          setError(_ => Some(msg))
        }}>
      <View style={s({marginBottom: gap->dp})}>
        <View style={s({width: 100.->pct, borderRadius})}>
          <View
            style={s({
              width: 100.->pct,
              marginBottom: ?(splitCardFields ? Some(gap->dp) : None),
            })}>
            <View
              style={fieldBox(
                ~borderBottomWidth=?{splitCardFields ? None : Some(borderWidth /. 2.)},
                ~borderBottomLeftRadius=?{splitCardFields ? None : Some(0.)},
                ~borderBottomRightRadius=?{splitCardFields ? None : Some(0.)},
                (),
              )}>
              <CardNumberWidget
                style={widgetBoxFill}
                textStyle={widgetTextStyle}
                onStateChange={onFieldState}
                placeholder={nativeProp.configuration.placeholder.cardNumber->Option.getOr(
                  localeObject.cardNumberLabel,
                )}
              />
            </View>
          </View>
          <View
            style={s({
              flexDirection: localeObject.localeDirection === "rtl" ? #"row-reverse" : #row,
              gap: ?(splitCardFields ? Some(gap->dp) : None),
            })}>
            <View style={s({flex: 1.})}>
              <View
                style={fieldBox(
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
                <CardExpiryWidget
                  style={widgetBoxFill}
                  textStyle={widgetTextStyle}
                  onStateChange={onFieldState}
                  placeholder={nativeProp.configuration.placeholder.expiryDate->Option.getOr(
                    localeObject.validThruText,
                  )}
                />
              </View>
            </View>
            <UIUtils.RenderIf condition={hasCvc}>
              <View style={s({flex: 1.})}>
                <View
                  style={fieldBox(
                    ~borderTopWidth={splitCardFields ? borderWidth : borderWidth /. 2.},
                    ~borderLeftWidth={splitCardFields ? borderWidth : borderWidth /. 2.},
                    ~borderTopLeftRadius={splitCardFields ? borderRadius : 0.},
                    ~borderTopRightRadius={splitCardFields ? borderRadius : 0.},
                    ~borderBottomLeftRadius={splitCardFields ? borderRadius : 0.},
                    (),
                  )}>
                  <CardCVCWidget
                    style={widgetBoxFill}
                    textStyle={widgetTextStyle}
                    onStateChange={onFieldState}
                    placeholder={nativeProp.configuration.placeholder.cvv->Option.getOr(
                      localeObject.cvcTextLabel,
                    )}
                  />
                </View>
              </View>
            </UIUtils.RenderIf>
          </View>
          <UIUtils.RenderIf condition={hasCardHolder}>
            <View style={s({marginTop: gap->dp})}>
              <View style={fieldBox()}>
                <CardHolderWidget
                  style={widgetBoxFill}
                  textStyle={widgetTextStyle}
                  onStateChange={onFieldState}
                  placeholder={localeObject.cardHolderName}
                />
              </View>
            </View>
          </UIUtils.RenderIf>
        </View>
        <ErrorText text={firstFieldError} />
      </View>
    </HyperswitchForm>
    }}
    <ErrorText text={error} />
  </View>
}
