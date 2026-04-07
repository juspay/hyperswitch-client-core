open ReactNative
open Style
open PaymentEvents

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, customerPaymentMethodData, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  // Ref to hold the latest customerPaymentMethodData so the useEffect0 event listener
  // always reads the current value instead of the stale one captured at mount time.
  let customerPaymentMethodDataRef = React.useRef(customerPaymentMethodData)
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
      let cardPaymentMethods =
        pmList->Array.filter(pm => pm.payment_method === PaymentMethodType.CARD)
        
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
          ->Option.map(
            date =>
              compare(
                Date.fromString(date)->Js.Date.getTime,
                Date.fromString(b.last_used_at)->Js.Date.getTime,
              ) < 0
                ? Some(b)
                : a,
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

  let isCvcValid =
    cvcValue->String.length === 0 ? true : Validation.cvcNumberInRange(cvcValue, cardNetwork)

  // let isCvcComplete = Validation.checkCardCVC(cvcValue, cardNetwork) // commented out for now

  let isCvcEmpty = cvcValue->String.length === 0

  let onCvcChange = cvc => {
    let formatted = Validation.formatCVCNumber(cvc, cardNetwork)
    setCvcValue(_ => formatted)
    // Register CVC in the global registry by widgetId
    CvcRegistry.register(nativeProp.widgetId, formatted)
  }

  // Emit cvcStatus with the new shape: {cvcStatus: {isCvcFocused, isCvcBlur, isCvcEmpty}}
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

  // Keep the ref in sync with the latest context value on every re-render.
  React.useEffect1(() => {
    customerPaymentMethodDataRef.current = customerPaymentMethodData
    None
  }, [customerPaymentMethodData])

  React.useEffect0(() => {
    setLoading(LoadingContext.FillingDetails)

    // Listen for "confirmPayment" event from native.
    // When merchant calls confirm and CvcWidget is active, native emits this event
    // instead of invoking HeadlessJsTask's callback. CvcWidget reads the CVC from
    // CvcRegistry and makes the confirm API call directly in its own JS context.
    let cleanup = NativeEventListener.setupNativeEventListener("confirmPayment", var => {
      let dict = var->Utils.getDictFromJson
      let paymentToken =
        dict->Dict.get("paymentToken")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let paymentMethodId =
        dict->Dict.get("paymentMethodId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let widgetId =
        dict
        ->Dict.get("widgetId")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.getOr(nativeProp.widgetId)

      // Guard: only process events targeted at THIS widget instance.
      // DeviceEventEmitter is global across the shared ReactContext, so ALL mounted
      // CvcWidget instances receive every "confirmPayment" event. Without this guard,
      // a stale widget from a previous payment session (different clientSecret) could
      // also fire confirmCardPayment, causing duplicate API calls with wrong clientSecrets.
      if widgetId != nativeProp.widgetId {
        ()
      } else {
        // Look up the payment method by payment_method_id (stable across API calls)
        // from the React context data to get billing. We match by payment_method_id
        // instead of payment_token because tokens are ephemeral — each API call to
        // /customers/payment_methods generates a new token for the same card. The
        // HeadlessTask and NavigationRouter fetch PMs separately, so their tokens
        // differ, but payment_method_id is always the same for a given saved card.
        // Read from the ref (not the captured closure variable) to avoid stale closure.
        let billing =
          customerPaymentMethodDataRef.current
          ->Option.flatMap(
            cpmd => {
              cpmd.customer_payment_methods->Array.find(pm => pm.payment_method_id == paymentMethodId)
            },
          )
          ->Option.flatMap(pm => pm.billing)
          ->Option.map(Utils.getJsonObjectFromRecord)

        let cvc = CvcRegistry.get(widgetId)

        HeadlessCommon.confirmCardPayment(
          headlessModule,
          nativeProp,
          ~paymentToken,
          ~cvc,
          ~billing?,
        )
      }
    })

    Some(
      () => {
        // Cleanup: remove from CvcRegistry and call event listener cleanup
        CvcRegistry.remove(nativeProp.widgetId)
        cleanup()
      },
    )
  })

  // Emit initial cvcStatus on mount and when isCvcEmpty changes
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
    </View>
  }
}
