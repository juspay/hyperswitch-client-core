open ReactNative
open Style

/* The wrappers send "100" to "900"; anything else is ignored. */
let toFontWeight = (weight): option<Style.fontWeight> =>
  switch weight {
  | "100" => Some(#100)
  | "200" => Some(#200)
  | "300" => Some(#300)
  | "400" => Some(#400)
  | "500" => Some(#500)
  | "600" => Some(#600)
  | "700" => Some(#700)
  | "800" => Some(#800)
  | "900" => Some(#900)
  | _ => None
  }

/* Element style (already merged over elementStyles.action) wins; the theme fills the rest. */
let actionStyle = (style: PaymentMessageTypes.elementStyle, ~linkColor, ~fontScale) =>
  s({
    color: style.color->Option.getOr(linkColor),
    fontSize: ?style.fontSize->Option.map(size => size *. fontScale),
    fontWeight: ?style.fontWeight->Option.flatMap(toFontWeight),
    fontStyle: ?style.fontStyle,
    textDecorationLine: ?style.textDecoration->Option.map(decoration =>
      (decoration :> Style.textDecorationLine)
    ),
  })

@react.component
let make = (~paymentMethod, ~paymentMethodType) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {linkColor, fontScale} = ThemebasedStyle.useThemeBasedStyle()
  let message = PaymentMessageUtils.resolve(
    nativeProp.configuration.paymentMethodsConfig,
    ~paymentMethod,
    ~paymentMethodType,
  )
  let (segments, defaultStyle) = switch message {
  | Some(message) if PaymentMessageUtils.displayModeOf(message) === #custom_message => (
      message.value->Option.getOr([]),
      message.elementStyles.action,
    )
  | _ => ([], {})
  }

  /* Empty text alone would still reserve the message's margin. */
  let visible = segments->Array.some(segment =>
    switch segment {
    | Text(text) => text != ""
    | Action(_) => true
    }
  )

  if !visible {
    React.null
  } else {
    <TextWrapper textType=ModalTextBold overrideStyle=Some(s({marginBottom: 15.->dp}))>
      {segments
      ->Array.mapWithIndex((segment, index) =>
        switch segment {
        | Text(text) => React.string(text)
        | Action({text, style, index: actionIndex}) =>
          <Text
            key={Int.toString(index)}
            accessibilityRole=#button
            style={actionStyle(
              PaymentMessageUtils.mergeStyles(defaultStyle, style),
              ~linkColor,
              ~fontScale,
            )}
            onPress={event => {
              event->Event.PressEvent.stopPropagation
              HyperModule.emitMessageAction(nativeProp.rootTag, actionIndex)
            }}>
            {React.string(text)}
          </Text>
        }
      )
      ->React.array}
    </TextWrapper>
  }
}
