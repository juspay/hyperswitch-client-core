open ReactNative
open Style

let formIdFor = (token: ClientResponseType.customerPaymentMethod) =>
  "saved-" ++ token.payment_method_id

@react.component
let make = (
  ~savedPaymentMethod: ClientResponseType.customerPaymentMethod,
  ~vaultDetails: VaultDetailsType.vaultDetails,
  ~hideCardExpiry,
  ~hideCVCError,
  ~hideCvcIcon,
  ~placeholderCVC,
) => {
  let formId = formIdFor(savedPaymentMethod)
  let {getFormState, setFormValid} = React.useContext(CardStrategyContext.cardStrategyContext)
  let {showErrors} = getFormState(formId)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let localeObject = GetLocale.useGetLocalObj()
  let {
    component,
    bgColor,
    borderWidth,
    borderRadius,
    inputHeight,
    primaryColor,
    errorTextInputColor,
    normalTextInputBoderColor,
    shadowConfig,
  } = ThemebasedStyle.useThemeBasedStyle()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowConfig, ())

  let cvcRef = React.useRef(Nullable.null)
  let (cvcState, setCvcState) = React.useState(() => None)
  let (isCvcFocus, setIsCvcFocus) = React.useState(_ => false)
  let (hasBlurred, setHasBlurred) = React.useState(_ => false)
  let (mountError, setMountError) = React.useState(() => None)

  let vaultDetailsProp = React.useMemo2(
    () =>
      VaultDetailsType.toCardFormProp(
        vaultDetails,
        ~environment=nativeProp.hyperswitchConfig.environment,
      ),
    (vaultDetails, nativeProp.hyperswitchConfig.environment),
  )

  let isHyperswitchVault = switch vaultDetails.config {
  | VaultDetailsType.HyperswitchVault(_) => true
  | VaultDetailsType.VgsVault(_) => false
  }
  let useProviderIcon = !isHyperswitchVault && !hideCvcIcon
  let boxWidth = hideCvcIcon ? 72. : useProviderIcon ? 128. : 100.
  let savedCardToken = isHyperswitchVault ? None : Some(savedPaymentMethod.payment_token)

  let savedCard: VaultBindings.fieldOptions = {
    savedCard: {
      paymentMethodToken: ?savedCardToken,
      paymentMethodData: {
        card: {
          cardNetwork: ?savedPaymentMethod.card
          ->Option.map(card => card.card_network)
          ->Utils.getNonEmptyOption,
        },
      },
    },
  }

  let onFormChange = (event: VaultBindings.cardFormChange) => {
    setFormValid(formId, event.complete && event.valid)
    setCvcState(_ => event.fields->Dict.get("cardCvc"))
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

  React.useEffect0(() => {
    Some(() => setFormValid(formId, false))
  })

  let touched = hasBlurred || showErrors
  let isCvcValid =
    isCvcFocus || !touched
      ? true
      : switch cvcState {
        | Some(change) => !change.empty && change.valid
        | None => false
        }
  let errorMsgText = !isCvcValid ? Some(localeObject.inCompleteCVCErrorText) : None

  <View
    style={s({
      display: #flex,
      flexDirection: #column,
      alignItems: hideCardExpiry ? #"flex-end" : #"flex-start",
      marginHorizontal: hideCardExpiry ? 7.5->dp : 47.5->dp,
    })}>
    <View
      style={s({
        flex: 1.,
        display: #flex,
        flexDirection: #row,
        alignItems: #center,
        width: ?(hideCardExpiry ? None : Some(100.->pct)),
        marginTop: hideCardExpiry
          ? (errorMsgText->Option.isSome && !hideCVCError ? 2. : 0.)->dp
          : 10.->dp,
      })}>
      {hideCardExpiry
        ? React.null
        : <View style={s({width: {50.->dp}})}>
            <TextWrapper text="CVC:" textType={ModalText} />
          </View>}
      <VaultBindings.CardForm
        id=formId vaultDetails=vaultDetailsProp onChange=onFormChange onError=onFormError>
        <View style={s({width: boxWidth->dp})}>
          <View
            style={array([
              bgColor,
              s({
                backgroundColor: component.background,
                borderWidth,
                borderRadius,
                height: (inputHeight *. 0.9)->dp,
                flexDirection: #row,
                borderColor: isCvcValid
                  ? isCvcFocus ? primaryColor : normalTextInputBoderColor
                  : errorTextInputColor,
                width: boxWidth->dp,
                paddingHorizontal: 13.->dp,
                alignItems: #center,
                justifyContent: #center,
              }),
              shadowStyle,
            ])}>
            <VaultInput
              elementType="cardCvc"
              height={inputHeight *. 0.9}
              reference=cvcRef
              label=localeObject.cvcTextLabel
              active=isCvcFocus
              empty={cvcState->Option.mapOr(true, field => field.empty)}
              valid=isCvcValid
              useProviderIcon
              iconRight=?{hideCvcIcon || useProviderIcon
                ? None
                : Some(
                    <Icon
                      name={cvcState->Option.mapOr(false, field => field.complete)
                        ? "cvvfilled"
                        : "cvvempty"}
                      height=35.
                      width=35.
                      fill="black"
                    />,
                  )}
              options=savedCard
              placeholder={hideCardExpiry
                ? placeholderCVC->Option.getOr(localeObject.cvcTextLabel)
                : "123"}
              onFocus={_ => setIsCvcFocus(_ => true)}
              onBlur={_ => {
                setIsCvcFocus(_ => false)
                setHasBlurred(_ => true)
              }}
            />
          </View>
        </View>
      </VaultBindings.CardForm>
    </View>
    {errorMsgText->Option.isSome && !hideCVCError ? <ErrorText text=errorMsgText /> : React.null}
    <ErrorText text={mountError} />
  </View>
}
