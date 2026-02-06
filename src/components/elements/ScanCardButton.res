open ReactNative
open Style

@react.component
let make = (~onScanCard, ~expireRef, ~cvvRef) => {
  let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()
  let logger = LoggerHook.useLoggerHook()
  let showAlert = AlertHook.useAlerts()

  let scanCardCallback = (scanCardReturnType: ScanCardModule.scanCardReturnStatus) => {
    switch scanCardReturnType {
    | Succeeded(data) => {
        onScanCard(data.pan, `${data.expiryMonth} / ${data.expiryYear}`, expireRef, cvvRef)
        logger(~logType=INFO, ~value="Succeeded", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
      }
    | Cancelled =>
      logger(~logType=WARNING, ~value="Cancelled", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
    | Failed => {
        showAlert(~errorType="warning", ~message="Failed to scan card")
        logger(~logType=ERROR, ~value="Failed", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
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
        ScanCardModule.launchScanCard(scanCardCallback)
        logger(~logType=INFO, ~value="Launch", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
      }}
    >
      <Icon name={"CAMERA"} height=26. width=26. fill=primaryColor />
    </CustomPressable>
  </>
}
