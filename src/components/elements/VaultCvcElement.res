open ReactNative
open Style

@react.component
let make = (~placeholderCVC=?, ~width=?, ~hideCardExpiry=false) => {
  let (error, setError) = React.useState((): option<string> => None)
  let formRef: React.ref<Js.nullable<VaultElement.formHandle>> = React.useRef(Js.Nullable.null)
  let (_, _, sessionData, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let vaultConfig = sessionData->Option.flatMap(d => d.vaultDetails)
  let {vaultSubmitRef, setVaultFormValid, vaultShowErrors} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )
  let (cvcState, setCvcState) = React.useState((): option<VaultElement.fieldState> => None)

  let {
    component,
    bgColor,
    borderWidth,
    borderRadius,
    inputHeight,
    normalTextInputBoderColor,
    shadowConfig,
  } = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowConfig, ())

  let onCvcState = (st: VaultElement.fieldState) => setCvcState(_ => Some(st))

  React.useEffect1(() => {
    let valid = switch cvcState {
    | Some(st) => st.isValid && !st.isEmpty
    | None => false
    }
    setVaultFormValid(valid)
    None
  }, [cvcState])

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

  let cvcError = switch cvcState {
  | Some(st) if st.isFocused => None
  | Some(st) if !st.isValid && !st.isEmpty && (st.isDirty || vaultShowErrors) =>
    Some(
      switch st.validationErrors->Array.get(0) {
      | Some("INVALID_CVC") => localeObject.inValidCVCErrorText
      | Some("INVALID_CVC_LEHGTH") => localeObject.inCompleteCVCErrorText
      | Some(other) => other
      | None => localeObject.inValidCVCErrorText
      },
    )
  | Some(st) if st.isEmpty && vaultShowErrors => Some(localeObject.cvcNumberEmptyText)
  | None if vaultShowErrors => Some(localeObject.cvcNumberEmptyText)
  | _ => None
  }

  let boxStyle = array([
    bgColor,
    s({
      backgroundColor: component.background,
      borderWidth,
      borderRadius,
      width: ?width->Option.map(w => w->dp),
      height: inputHeight->dp,
      flexDirection: #row,
      borderColor: normalTextInputBoderColor,
      paddingLeft: 13.->dp,
      alignItems: #center,
      justifyContent: #center,
    }),
    shadowStyle,
  ])
  let widgetBoxFill = s({flex: 1., height: 100.->pct})
  let widgetTextStyle = s({color: component.color, fontSize: 16.})

  <View style=s({alignItems: hideCardExpiry ? #"flex-end" : #"flex-start", justifyContent: #center})>
    {switch vaultConfig {
    | None => React.null
    | Some(config) =>
      <VaultElement.HyperswitchForm
        ref=formRef
        config
        onError={e => {
          let msg =
            Js.Exn.asJsExn(e)->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("Unknown error")
          setError(_ => Some(msg))
        }}>
        <View style={boxStyle}>
          <VaultElement.CardCVCWidget
            style={widgetBoxFill}
            textStyle={widgetTextStyle}
            onStateChange={onCvcState}
            placeholder={placeholderCVC->Option.getOr(localeObject.cvcTextLabel)}
          />
        </View>
      </VaultElement.HyperswitchForm>
    }}
    <ErrorText text={cvcError} />
    <ErrorText text={error} />
  </View>
}
