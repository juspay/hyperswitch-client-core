open ReactNative
open Style

/* Element style (already merged over elementStyles.action) wins; the theme fills the rest. */
let actionStyle = (style: PaymentMessageTypes.elementStyle, ~linkColor, ~fontScale) =>
  s({
    color: style.color->Option.getOr(linkColor),
    fontSize: ?style.fontSize->Option.map(size => size *. fontScale),
    fontWeight: ?style.fontWeight->Option.map(weight => (weight :> Style.fontWeight)),
    fontStyle: ?style.fontStyle,
    textDecorationLine: ?style.textDecoration->Option.map(decoration =>
      (decoration :> Style.textDecorationLine)
    ),
  })

@react.component
let make = (~paymentMethod, ~paymentMethodType) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {linkColor, fontScale} = ThemebasedStyle.useThemeBasedStyle()
  let emitter = PaymentEvents.usePaymentEventEmitter()
  let subscribed = PaymentEventData.shouldEmitEvent(
    ~eventType=CustomMessageElementClicked,
    ~subscribedEvents=nativeProp.configuration.subscribedEvents,
  )
  let message = PaymentMessageUtils.resolve(
    nativeProp.configuration.paymentMethodsConfig,
    ~paymentMethod,
  )
  let content = React.useMemo2(() => {
    message->Option.mapOr({PaymentMessageUtils.segments: [], warnings: []}, message =>
      PaymentMessageUtils.renderContent(message, ~subscribed)
    )
  }, (message, subscribed))
  React.useEffect1(() => {
    content.warnings->Array.forEach(warning =>
      PaymentMessageUtils.warn(paymentMethod ++ "." ++ paymentMethodType ++ ": " ++ warning)
    )
    None
  }, [content])

  if content.segments->Array.length == 0 {
    React.null
  } else {
    <TextWrapper textType=ModalTextBold overrideStyle=Some(s({marginBottom: 15.->dp}))>
      {content.segments
      ->Array.mapWithIndex((segment, index) =>
        switch segment {
        | Text(text) => React.string(text)
        | CallbackAction({key, label, style}) =>
          <Text
            key={Int.toString(index)}
            accessibilityRole=#button
            style={actionStyle(style, ~linkColor, ~fontScale)}
            onPress={event => {
              event->Event.PressEvent.stopPropagation
              emitter.emitCustomMessageElementClicked(
                ~event={key, \"type": "action", paymentMethod, paymentMethodType},
              )
            }}>
            {React.string(label)}
          </Text>
        }
      )
      ->React.array}
    </TextWrapper>
  }
}
