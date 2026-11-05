open ReactNative
open Style

@react.component
let make = (~onScanCard, ~expireRef, ~cvvRef) => {
  let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()
  let showAlert = AlertHook.useAlerts()
  let scanStartedAt = React.useRef(Date.now())

  let logScanResult = (~outcome, ~details=?) =>
    SdkLogger.logFunction(
      ~event=LaunchScanCard,
      ~outcome,
      ~startedAt=scanStartedAt.current,
      ~details?,
      ~paymentMethod=Card,
    )

  let scanCardCallback = (scanCardReturnType: ScanCardModule.scanCardReturnStatus) => {
    switch scanCardReturnType {
    | Succeeded(data) => {
        onScanCard(data.pan, `${data.expiryMonth} / ${data.expiryYear}`, expireRef, cvvRef)
        logScanResult(~outcome=Done)
      }
    | Cancelled =>
      logScanResult(~outcome=Returned, ~details=[("cancelled", true->JSON.Encode.bool)])
    | Failed => {
        showAlert(~errorType="warning", ~message="Failed to scan card")
        logScanResult(~outcome=Failed)
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
        scanStartedAt.current = Date.now()
        SdkLogger.logFunction(~event=LaunchScanCard, ~outcome=Started, ~paymentMethod=Card)
        ScanCardModule.launchScanCard(scanCardCallback)
      }}>
      <Icon name={"CAMERA"} height=26. width=26. fill=primaryColor />
    </CustomPressable>
  </>
}
