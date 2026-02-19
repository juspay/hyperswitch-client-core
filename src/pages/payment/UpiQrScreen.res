open ReactNative
open Style

@react.component
let make = (~qrDataUrl: string, ~displayFromTimestamp: float, ~displayToTimestamp: float) => {
  let {disableBgColor, filterHeaderColor} = ThemebasedStyle.useThemeBasedStyle()

  let qrCode = React.useMemo1(() => {
    let qr = QRGenerator.make(0, "M")
    qr.addData(qrDataUrl, "Byte")
    qr.make()
    qr
  }, [qrDataUrl])

  <View
    style={s({
      flex: 1.,
      justifyContent: #center,
      padding: 20.->dp,
    })}>
    <View
      style={s({
        flex: 1.,
        justifyContent: #center,
        alignItems: #center,
      })}>
      <TextWrapper
        text="Scan QR Code to Pay"
        textType={CardTextBold}
        overrideStyle={Some(Style.s({textAlign: #center, color: filterHeaderColor}))}
      />
      <Space height=20. />
      <View
        style={s({
          width: 164.->dp,
          height: 164.->dp,
          borderWidth: 1.,
          borderColor: "#E0E0E0",
          borderRadius: 8.,
          padding: 8.->dp,
          backgroundColor: "white",
        })}>
        <Image
          source={Image.Source.fromUriSource({uri: qrCode.createDataURL(5, 0)})}
          style={s({
            width: 100.->pct,
            height: 100.->pct,
          })}
          resizeMode=#contain
        />
      </View>
    </View>
    <Space height=30. />
    <View
      style={s({
        flex: 1.,
        justifyContent: #center,
        alignItems: #center,
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
