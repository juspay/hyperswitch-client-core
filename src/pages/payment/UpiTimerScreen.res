open ReactNative
open Style

@react.component
let make = (~displayFromTimestamp: float, ~displayToTimestamp: float) => {
  let {primaryColor, disableBgColor, filterHeaderColor} = ThemebasedStyle.useThemeBasedStyle()

  <View
    style={s({
      flex: 1.,
      // padding: 20.->dp,
      justifyContent: #center,
    })}>
    <View
      style={s({
        flex: 1.,
        justifyContent: #center,
        alignItems: #center,
      })}>
      <Icon name="rupeereceive" width=57. height=56. fill={primaryColor} />
      <Space height=10. />
      <TextWrapper
        text={`Payable Amount has been sent`}
        textType={CardText}
        overrideStyle={Some(Style.s({textAlign: #center, color: filterHeaderColor}))}
      />
    </View>
    <Space height=30. />
    <View
      style={s({
        flex: 1.,
        justifyContent: #center,
        alignItems: #center,
        alignSelf: #center,
      })}>
      <UpiTimerComponent displayFromTimestamp displayToTimestamp />
    </View>
    <Space height=20. />
    <DottedLine />
    <Space height=20. />
    <View
      style={s({
        backgroundColor: disableBgColor,
        borderRadius: 8.,
        padding: 10.->dp,
      })}>
      <TextWrapper
        text="You will be automatically redirected once the payment is done"
        textType={ModalText}
        overrideStyle={Some(
          Style.s({
            textAlign: #center,
            color: filterHeaderColor,
            marginBottom: 0.->dp,
          }),
        )}
      />
    </View>
  </View>
}
