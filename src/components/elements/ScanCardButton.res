open ReactNative
open Style

@react.component
let make = (~onScanCard, ~expireRef, ~cvvRef) => {
  let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()
  let showAlert = AlertHook.useAlerts()

  let scanCardCallback = (~startedAt, scanCardReturnType: ScanCardModule.scanCardReturnStatus) => {
    let logResult = (~outcome, result) =>
      SdkLogger.logFunction(
        ~event=LaunchScanCard,
        ~outcome,
        ~startedAt,
        ~details=[("result", result->JSON.Encode.string)],
        ~paymentMethod=Card,
      )
    switch scanCardReturnType {
    | Succeeded(data) => {
        onScanCard(data.pan, `${data.expiryMonth} / ${data.expiryYear}`, expireRef, cvvRef)
        logResult(~outcome=Done, "SUCCEEDED")
      }
    | Cancelled => logResult(~outcome=Done, "CANCELLED")
    | Failed => {
        showAlert(~errorType="warning", ~message="Failed to scan card")
        logResult(~outcome=Failed, "FAILED")
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
        let startedAt = Date.now()
        SdkLogger.logFunction(~event=LaunchScanCard, ~outcome=Started, ~paymentMethod=Card)
        ScanCardModule.launchScanCard(status => scanCardCallback(~startedAt, status))
      }}>
      <Icon name={"CAMERA"} height=26. width=26. fill=primaryColor />
    </CustomPressable>
  </>
}
