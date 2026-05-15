open ReactNative
open Style
open PaymentEvents

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (cvcValue, setCvcValue) = React.useState(_ => "")
  let cvcValueRef = React.useRef("")
  let (isFocused, setIsFocused) = React.useState(_ => false)
  let emitter = PaymentEvents.usePaymentEventEmitter()
  let localeObject = GetLocale.useGetLocalObj()
  let {
    component,
    dangerColor,
    borderRadius,
    borderWidth,
    primaryColor,
  } = ThemebasedStyle.useThemeBasedStyle()

  let cardNetwork = ""

  let requiresCvv = true

  let isCvcValid =
    cvcValue->String.length === 0 ? true : Validation.cvcNumberInRange(cvcValue, cardNetwork)

  let isCvcEmpty = cvcValue->String.length === 0

  let onCvcChange = cvc => {
    let formatted = Validation.formatCVCNumber(cvc, cardNetwork)
    setCvcValue(_ => formatted)
    cvcValueRef.current = formatted
  }

  let emitCvcStatusEvent = (~focused: bool, ~blur: bool) => {
    emitter.emitCvcStatus(
      ~event={
        isCvcFocused: focused,
        isCvcBlur: blur,
        isCvcEmpty,
      },
    )
  }

  // HyperHeadless module — needed only for exitHeadless after confirm
  let headlessModule = HeadlessCommon.makeHeadlessModule()

  React.useEffect0(() => {
    setLoading(LoadingContext.FillingDetails)
    let cleanup = NativeEventListener.setupWidgetActionListener(~onWidgetAction=(
      actionData: NativeModulesType.widgetActionData,
    ) => {
      switch actionData.actionType {
      | ConfirmCvcPayment =>
        if actionData.rootTag === nativeProp.rootTag {
          HeadlessCommon.confirmCardPayment(
            headlessModule,
            nativeProp,
            ~sdkAuthorization=actionData.sdkAuthorization->Option.getOr(""),
            ~paymentToken=actionData.paymentToken->Option.getOr(""),
            ~cvc=cvcValueRef.current->JSON.Encode.string,
            ~billing=?actionData.billing,
          )
        }
      | _ => ()
      }
    })

    Some(() => cleanup())
  })

  React.useEffect1(_ => {
    emitCvcStatusEvent(~focused=isFocused, ~blur=!isFocused)
    None
  }, [isCvcEmpty])

  if !requiresCvv {
    <View style={s({height: 0.->dp})} />
  } else {
    <View
      style={s({
        width: 100.->pct,
        flex: 1.,
        backgroundColor: "transparent",
        justifyContent: #center,
        padding: 2.->dp,
      })}>
      <CustomInput
        state={cvcValue}
        setState={onCvcChange}
        placeholder={nativeProp.configuration.placeholder.cvv}
        animateLabel={localeObject.cvcTextLabel}
        keyboardType=#"number-pad"
        enableCrossIcon=false
        maxLength=Some(4)
        isValid={isCvcValid}
        secureTextEntry=true
        borderTopLeftRadius=borderRadius
        borderTopRightRadius=borderRadius
        borderBottomLeftRadius=borderRadius
        borderBottomRightRadius=borderRadius
        borderTopWidth=borderWidth
        borderBottomWidth=borderWidth
        borderLeftWidth=borderWidth
        borderRightWidth=borderWidth
        textColor={isCvcValid ? component.color : dangerColor}
        onFocus={() => {
          setIsFocused(_ => true)
          emitCvcStatusEvent(~focused=true, ~blur=false)
        }}
        onBlur={() => {
          setIsFocused(_ => false)
          emitCvcStatusEvent(~focused=false, ~blur=true)
        }}
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
              fill={Validation.checkCardCVC(cvcValue, cardNetwork) ? primaryColor : "#858F97"}
            />
          </View>,
        )
      />
      <Space height=2. />
    </View>
  }
}
