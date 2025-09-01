open ReactNative
open Style

@react.component
let make = (~paymentMethodName: string) => {
  let { primaryColor} = ThemebasedStyle.useThemeBasedStyle()

  <View
    style={s({
      flexDirection: #row,
      alignItems: #center,
      justifyContent: #center,
      marginTop: -20.->dp,
      paddingBottom: 10.->dp,
      paddingHorizontal: 20.->dp,
    })}>
    <Icon name={paymentMethodName} width=24. height=24. fill={primaryColor} />
    <Space width=10. />
    <TextWrapper
      text={`${paymentMethodName->String.toUpperCase}`}
      textType={TextWrapper.Heading}
      overrideStyle=Some(Style.s({fontWeight: #600, fontSize: 18.0}))
    />
  </View>
}
