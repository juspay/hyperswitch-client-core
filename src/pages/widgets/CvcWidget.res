open ReactNative
open Style
open PaymentEvents

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, customerPaymentMethodData, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (cvcValue, setCvcValue) = React.useState(_ => "")
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

  let lastUsedCardPaymentMethod = {
    customerPaymentMethodData
    ->Option.map(customerPaymentMethods => {
      let pmList = customerPaymentMethods.customer_payment_methods
      let cardPaymentMethods = pmList->Array.filter(pm => pm.payment_method === PaymentMethodType.CARD)
      
      if cardPaymentMethods->Array.length === 0 {
        None
      } else {
        cardPaymentMethods->Array.reduce(None, (
          a: option<CustomerPaymentMethodType.customer_payment_method_type>,
          b: CustomerPaymentMethodType.customer_payment_method_type,
        ) => {
          let lastUsedAtA = switch a {
          | Some(a) => Some(a.last_used_at)
          | None => None
          }
          lastUsedAtA
          ->Option.map(date =>
            compare(
              Date.fromString(date)->Js.Date.getTime,
              Date.fromString(b.last_used_at)->Js.Date.getTime,
            ) < 0
              ? Some(b)
              : a
          )
          ->Option.getOr(Some(b))
        })
      }
    })
    ->Option.getOr(None)
  }

  let cardNetwork = switch lastUsedCardPaymentMethod {
  | Some(pm) => pm.card->Option.map(card => card.card_network)->Option.getOr("")
  | None => ""
  }

  let requiresCvv = switch lastUsedCardPaymentMethod {
  | Some(pm) => pm.requires_cvv
  | None => false
  }

  let isCvcValid = cvcValue->String.length === 0
    ? true
    : Validation.cvcNumberInRange(cvcValue, cardNetwork)

  let isCvcComplete = Validation.checkCardCVC(cvcValue, cardNetwork)

  let onCvcChange = cvc => {
    let formatted = Validation.formatCVCNumber(cvc, cardNetwork)
    setCvcValue(_ => formatted)
  }

  let emitCvcStatus = () => {
    emitter.emitCvcStatus(~event={
      requiresCvv,
      isCvcComplete,
      isFocused,
    })
  }

  React.useEffect0(() => {
    // NativeEventListener.sendReadyMessage("cvcWidget")
    setLoading(LoadingContext.FillingDetails)
    Some(() => ())
  })

  React.useEffect1(_ => {
    emitCvcStatus()
    None
  }, [requiresCvv, isCvcComplete, isFocused])

  if !requiresCvv {
    <View style={s({height: 0.->dp})} />
  } else {
    <View
      style={s({
        width: 100.->pct,
        flex: 1.,
        backgroundColor: "transparent",
        justifyContent: #center,
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
        }}
        onBlur={() => {
          setIsFocused(_ => false)
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
              fill={isCvcComplete ? primaryColor : "#858F97"}
            />
          </View>,
        )
      />
    </View>
  }
}
