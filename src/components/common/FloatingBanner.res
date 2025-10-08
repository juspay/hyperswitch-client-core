open ReactNative
open Style

@react.component
let make = (
  ~message: string,
  ~bannerType: BannerContext.bannerType=#none,
  ~isVisible: bool=false,
  ~onDismiss: unit => unit=() => (),
  ~isConnected=true,
  ~autoDismiss: bool=true,
  ~dismissTimeout: int=10000,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (slideAnim, _) = React.useState(_ => Animated.Value.create(-200.))
  let {toastColorConfig} = ThemebasedStyle.useThemeBasedStyle()

  React.useEffect(() => {
    if isVisible && autoDismiss {
      let timeoutId = setTimeout(() => onDismiss(), dismissTimeout)
      Some(() => clearTimeout(timeoutId))
    } else {
      None
    }
  }, (isVisible, autoDismiss, dismissTimeout))

  React.useEffect(() => {
    if isVisible {
      Animated.timing(
        slideAnim,
        {
          toValue: 0.->Animated.Value.Timing.fromRawValue,
          duration: 300.,
          useNativeDriver: false,
          easing: Easing.ease,
        },
      )->Animated.start
    } else {
      Animated.timing(
        slideAnim,
        {
          toValue: -200.->Animated.Value.Timing.fromRawValue,
          duration: 300.,
          useNativeDriver: false,
          easing: Easing.ease,
        },
      )->Animated.start
    }
    None
  }, [isVisible])

  let getBannerColors = (bannerType: BannerContext.bannerType) => {
    switch bannerType {
    | #error => Some("#FF6B6B", "#FFFFFF")
    | #warning => Some("#FFB347", "#000000")
    | #success => Some("#53e46c", "#FFFFFF")
    | #info => Some(toastColorConfig.backgroundColor, toastColorConfig.textColor)
    | #none => None
    }
  }

  let (backgroundColor, textColor) = getBannerColors(bannerType)->Option.getOr(("", ""))

  <UIUtils.RenderIf condition={bannerType !== #none}>
    <Animated.View
      style={array([
        s({
          position: #absolute,
          display: #flex,
          flex: 1.,
          width: 100.->pct,
          top: 0.->dp,
          paddingTop: (
            WebKit.platform === #web
              ? 10.
              : WebKit.platform === #androidWebView
              ? 75.
              : nativeProp.hyperParams.topInset->Option.getOr(75.)
          )->dp,
          zIndex: 9999,
          backgroundColor,
          shadowColor: "#000000",
          shadowOffset: {width: 0., height: 2.},
          shadowOpacity: 0.25,
          shadowRadius: 4.,
          elevation: 5.,
          alignItems: #center,
        }),
        s({transform: [translateY(~translateY=slideAnim->Animated.StyleProp.size)]}),
      ])}>
      <CustomPressable
        style={s({
          display: #flex,
          padding: 20.->dp,
        })}>
        <View
          style={s({
            flexDirection: #row,
            alignItems: #center,
            justifyContent: #"space-between",
            marginHorizontal: 10.->dp,
          })}>
          <Icon name={isConnected ? "wifi" : "wifioff"} width=24. height=24. />
          <Space width=15. />
          <TextWrapper
            text=message textType={HeadingBold} overrideStyle={Some(s({color: textColor}))}
          />
        </View>
      </CustomPressable>
    </Animated.View>
  </UIUtils.RenderIf>
}
