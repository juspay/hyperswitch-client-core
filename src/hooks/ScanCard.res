open ReactNative
open Style

/**
Hook returns an icon (`React.element`) for card brand.

Additonaly, returns the `scan-card` button (if feature is available for the platform).
*/
let useScanCardComponent = () => (~isScanCardAvailable, ~cardBrand, ~cardNumber, ~onScanCard) => {
  let {
    primaryColor,
    component,
  } = ThemebasedStyle.useThemeBasedStyle()
  let logger = LoggerHook.useLoggerHook()

  CustomInput.CustomIcon(
    <View style={array([viewStyle(~flexDirection=#row, ~alignItems=#center, ())])}>
      <Icon name={cardBrand === "" ? "waitcard" : cardBrand} height=30. width=30. fill="black" />
      <UIUtils.RenderIf condition={isScanCardAvailable && cardNumber === ""}>
        {<>
          <View
            style={viewStyle(
              ~backgroundColor=component.borderColor,
              ~marginLeft=10.->dp,
              ~marginRight=10.->dp,
              ~height=80.->pct,
              ~width=1.->dp,
              (),
            )}
          />
          <TouchableOpacity
            style={viewStyle(
              ~height=100.->pct,
              ~width=27.5->dp,
              ~display=#flex,
              ~alignItems=#"flex-start",
              ~justifyContent=#center,
              (),
            )}
            onPress={_pressEvent => {
              ScanCardModule.launchScanCard(onScanCard)
              logger(~logType=INFO, ~value="Launch", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
            }}>
            <Icon name={"CAMERA"} height=25. width=25. fill=primaryColor />
          </TouchableOpacity>
        </>}
      </UIUtils.RenderIf>
    </View>,
  )
}
