open ReactNative
open Style

@react.component
let make = (~onScanCard, ~expireRef, ~cvvRef) => {
  let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()
  let logger = LoggerHook.useLoggerHook()
  let showAlert = AlertHook.useAlerts()
  // The scan card package turned out to be missing from this build: the button
  // stays as a ghost mark rather than telling the shopper so.
  let (unavailable, setUnavailable) = React.useState(() => false)

  let scanCardCallback = (scanCardReturnType: ScanCardModule.scanCardReturnStatus) => {
    switch scanCardReturnType {
    | Succeeded(data) => {
        onScanCard(data.pan, `${data.expiryMonth} / ${data.expiryYear}`, expireRef, cvvRef)
        logger(~logType=INFO, ~value="Succeeded", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
      }
    | Cancelled =>
      logger(~logType=WARNING, ~value="Cancelled", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
    | Unavailable => {
        setUnavailable(_ => true)
        logger(
          ~logType=ERROR,
          ~value="@juspay-tech/react-native-hyperswitch-scancard is not in this build",
          ~category=USER_EVENT,
          ~eventName=SCAN_CARD,
          (),
        )
      }
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
    {unavailable
      ? <View
          style={s({
            height: 100.->pct,
            width: 28.->dp,
            alignItems: #"flex-start",
            justifyContent: #center,
          })}>
          <GhostMark height=26. width={26.->dp} radius=6. testID="scan-card-unavailable" />
        </View>
      : <CustomPressable
          testID="scan-card-button"
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
          }}>
          <Icon name={"CAMERA"} height=26. width=26. fill=primaryColor />
        </CustomPressable>}
  </>
}
