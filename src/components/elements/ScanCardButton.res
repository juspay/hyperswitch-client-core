open ReactNative
open Style

@react.component
let make = (~onScanCard, ~expireRef, ~cvvRef) => {
  let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()
  let showAlert = AlertHook.useAlerts()
  let scanCardCallback = (
    scanCardReturnType: ScanCardModule.scanCardReturnStatus,
    ~scan: NativeSdkLogger.call,
  ) => {
    switch scanCardReturnType {
    | Succeeded(data) => {
        onScanCard(data.pan, `${data.expiryMonth} / ${data.expiryYear}`, expireRef, cvvRef)
        scan.done()
      }
    | Cancelled => scan.returned([("cancelled", true->JSON.Encode.bool)])
    | Failed => {
        showAlert(~errorType="warning", ~message="Failed to scan card")
        scan.failed()
      }
    | _ => showAlert(~errorType="warning", ~message="Failed to scan card")
    }
  }

  <>
    <View
      style={s({
        backgroundColor: component.borderColor,
        marginLeft: 10.->dp,
        marginRight: 10.->dp,
        height: 80.->pct,
        width: 1.->dp,
      })}
    />
    <CustomPressable
      style={s({
        height: 100.->pct,
        width: 28.->dp,
        display: #flex,
        alignItems: #"flex-start",
        justifyContent: #center,
      })}
      onPress={_pressEvent => {
        SdkLogger.logUser(~event=CardScanRequested, ~paymentMethod=Card)
        let scan = NativeSdkLogger.startCall(~event=LaunchScanCard, ~paymentMethod=Card)
        ScanCardModule.launchScanCard(result => result->scanCardCallback(~scan))
      }}>
      <Icon name={"CAMERA"} height=26. width=26. fill=primaryColor />
    </CustomPressable>
  </>
}
