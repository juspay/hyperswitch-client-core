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

/* The wrappers send "normal"/"italic" and "none"/"underline"; anything else is ignored. */
let toFontStyle = (fontStyle): option<Style.fontStyle> =>
  switch fontStyle {
  | "normal" => Some(#normal)
  | "italic" => Some(#italic)
  | _ => None
  }

let toTextDecoration = (decoration): option<Style.textDecorationLine> =>
  switch decoration {
  | "none" => Some(#none)
  | "underline" => Some(#underline)
  | _ => None
  }

/* Element style (already merged over elementStyles.action) wins; the theme fills the rest. */
let actionStyle = (style: PaymentMessageTypes.elementStyle, ~linkColor, ~fontScale) =>
  s({
    color: style.color->Option.getOr(linkColor),
    fontSize: ?style.fontSize->Option.map(size => size *. fontScale),
    fontWeight: ?style.fontWeight->Option.flatMap(toFontWeight),
    fontStyle: ?style.fontStyle->Option.flatMap(toFontStyle),
    textDecorationLine: ?style.textDecoration->Option.flatMap(toTextDecoration),
  })

/* A shown custom message: its segments and the payment method type a tap reports. */
let customContent = (configs, ~paymentMethod, ~paymentMethodType) =>
  switch PaymentMessageUtils.resolve(configs, ~paymentMethod, ~paymentMethodType) {
  | Some((message, tapType)) if PaymentMessageUtils.displayModeOf(message) === #custom_message =>
    let segments = message.value->Option.getOr([])
    /* Empty text alone would still reserve the message's space. */
    segments->Array.some(segment =>
      switch segment {
      | Text(text) => text != ""
      | Action(_) => true
      }
    )
      ? Some((segments, message.elementStyles.action, tapType))
      : None
  | _ => None
  }

module Content = {
  @react.component
  let make = (~paymentMethod, ~content, ~textType, ~overrideStyle) => {
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let {linkColor, fontScale} = ThemebasedStyle.useThemeBasedStyle()
    let (segments, defaultStyle, tapPaymentMethodType) = content
    <TextWrapper textType overrideStyle>
      {segments
      ->Array.mapWithIndex((segment, index) =>
        switch segment {
        | PaymentMessageTypes.Text(text) => React.string(text)
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
              HyperModule.emitMessageAction(
                nativeProp.rootTag,
                paymentMethod,
                tapPaymentMethodType,
                actionIndex,
                text,
              )
            }}>
            {React.string(text)}
          </Text>
        }
      )
      ->React.array}
    </TextWrapper>
  }
}

@react.component
let make = (~paymentMethod, ~paymentMethodType) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  switch customContent(
    nativeProp.configuration.paymentMethodsConfig,
    ~paymentMethod,
    ~paymentMethodType,
  ) {
  | Some(content) =>
    <Content
      paymentMethod content textType=ModalTextBold overrideStyle=Some(s({marginBottom: 15.->dp}))
    />
  | None => React.null
  }
}
