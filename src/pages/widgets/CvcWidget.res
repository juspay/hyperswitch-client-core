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
  let lastEmittedStatusRef = React.useRef("")
  let emitter = PaymentEvents.usePaymentEventEmitter()
  let localeObject = GetLocale.useGetLocalObj()
  let {component, dangerColor, primaryColor} = ThemebasedStyle.useThemeBasedStyle()

  let cardNetwork = ""

  let isCvcValid =
    cvcValue->String.length === 0 ? true : Validation.cvcNumberInRange(cvcValue, cardNetwork)

  let isCvcEmpty = cvcValue->String.length === 0

  let isCvcComplete = Validation.checkCardCVC(cvcValue, cardNetwork)

  let onCvcChange = cvc => {
    let formatted = Validation.formatCVCNumber(cvc, cardNetwork)
    setCvcValue(_ => formatted)
    cvcValueRef.current = formatted
  }

  let emitCvcStatusEvent = (~focused: bool, ~blur: bool) => {
    let statusKey =
      [
        focused ? "1" : "0",
        blur ? "1" : "0",
        isCvcEmpty ? "1" : "0",
        isCvcComplete ? "1" : "0",
      ]->Array.join("")
    if lastEmittedStatusRef.current !== statusKey {
      lastEmittedStatusRef.current = statusKey
      emitter.emitCvcStatus(
        ~event={
          isCvcFocused: Some(focused),
          isCvcBlur: Some(blur),
          isCvcEmpty,
          isCvcComplete,
        },
      )
    }
  }

  let headlessModule = HeadlessCommon.makeHeadlessModule()

  React.useEffect0(() => {
    setLoading(LoadingContext.FillingDetails)
    let cleanup = NativeEventListener.setupWidgetActionListener(~onWidgetAction=(
      actionData: NativeModulesType.widgetActionData,
    ) => {
      switch actionData.actionType {
      | ConfirmCvcPayment =>
        if actionData.rootTag === nativeProp.rootTag {
          let isCvcCompleteNow = Validation.checkCardCVC(cvcValueRef.current, cardNetwork)
          if !isCvcCompleteNow {
            let cvcValidationError: PaymentConfirmTypes.error = {
              type_: "validation_error",
              status: "failed",
              code: "cvc_validation_failed",
              message: "CVC is not complete. Please enter a valid CVC.",
            }
            headlessModule.exitHeadless(
              nativeProp.rootTag,
              cvcValidationError->HyperModule.stringifiedResStatus,
            )
          } else {
            HeadlessCommon.confirmCardPayment(
              headlessModule,
              nativeProp,
              ~sdkAuthorization=actionData.sdkAuthorization->Option.getOr(""),
              ~paymentToken=actionData.paymentToken->Option.getOr(""),
              ~cvc=cvcValueRef.current->JSON.Encode.string,
              ~billing=?actionData.billing,
            )
          }
        }
      | _ => ()
      }
    })

    Some(() => cleanup())
  })

  React.useEffect2(_ => {
    emitCvcStatusEvent(~focused=isFocused, ~blur=!isFocused)
    None
  }, (cvcValue, isFocused))

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
      placeholder={nativeProp.configuration.placeholder.cvv->Option.getOr(
        localeObject.cvcTextLabel,
      )}
      returnKeyType=#done
      animateLabel={localeObject.cvcTextLabel}
      keyboardType=#"number-pad"
      enableCrossIcon=false
      maxLength=Some(4)
      isValid={isCvcValid}
      secureTextEntry=true
      textColor={isCvcValid ? component.color : dangerColor}
      onFocus={() => {
        setIsFocused(_ => true)
      }}
      onBlur={() => {
        setIsFocused(_ => false)
      }}
      iconRight=?{nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.cvcIcon ===
        Hidden
        ? None
        : Some(
            CustomIcon(
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
            ),
          )}
    />
    <Space height=2. />
  </View>
}
