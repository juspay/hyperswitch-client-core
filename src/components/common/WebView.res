open ReactNative
include NativeElement

module Source = {
  type t

  @obj
  external uri: (
    ~uri: string=?,
    ~method: [
      | #CONNECT
      | #DELETE
      | #GET
      | #HEAD
      | #OPTIONS
      | #PATCH
      | #POST
      | #PUT
      | #TRACE
    ]=?,
    ~headers: {..}=?,
    ~body: string=?,
    unit,
  ) => t = ""

  @obj external html: (~html: string=?, ~baseUrl: string=?, unit) => t = ""
}

// module DataDetectorTypes = ReactNativeWebView_DataDetectorTypes
// module DecelerationRate = ReactNativeWebView_DecelerationRate
// module NavigationType = ReactNativeWebView_NavigationType

type webViewNativeEvent = {
  target: ReactNative.NativeTypes.nodeHandle,
  url: string,
  title: string,
  loading: bool,
  canGoBack: bool,
  canGoForward: bool,
}

type webViewError = {
  description: string,
  domain: option<string>,
  code: int,
  didFailProvisionalNavigation: option<bool>,
}

type webViewHttpError = {
  description: string,
  statusCode: int,
}

type webViewMessage = {data: string}

type webViewNativeProgressEvent = {progress: float}

type webViewNavigation = {
  //   navigationType: ReactNativeWebView_NavigationType.t,
  mainDocumentURL: option<string>,
}

type webViewShouldStartLoadWithRequest = {
  //   navigationType: ReactNativeWebView_NavigationType.t,
  mainDocumentURL: option<string>,
  lockIdentifier: int,
  isTopFrame: bool,
}

type webViewNavigationOrError

module WebViewDownloadEvent = {
  type payload = {downloadUrl: string}

  include Event.SyntheticEvent({
    type _payload = payload
  })
}

module WebViewErrorEvent = {
  type payload = webViewError
  include Event.SyntheticEvent({
    type _payload = payload
  })
}
module WebViewHttpErrorEvent = {
  type payload = webViewHttpError
  include Event.SyntheticEvent({
    type _payload = payload
  })
}
module WebViewMessageEvent = {
  type payload = webViewMessage
  include Event.SyntheticEvent({
    type _payload = payload
  })
}
module WebViewNavigationEvent = {
  type payload = webViewNavigation
  include Event.SyntheticEvent({
    type _payload = payload
  })
}
module WebViewProgressEvent = {
  type payload = webViewNativeProgressEvent
  include Event.SyntheticEvent({
    type _payload = payload
  })
}
module WebViewRenderProcessGone = {
  type payload = {didCrash: bool}
  include Event.SyntheticEvent({
    type _payload = payload
  })
}
module WebViewTerminatedEvent = {
  type payload = webViewNativeEvent
  include Event.SyntheticEvent({
    type _payload = payload
  })
}

// module UnionCallback = ReactNativeWebView_UnionCallback.Make({
//   type union = webViewNavigationOrError
//   type navigationEvent = WebViewNavigationEvent.t
//   type errorEvent = WebViewErrorEvent.t
// })

type nativeConfig

@obj
external nativeConfig: (
  ~component: React.component<'a>=?,
  ~props: {..}=?,
  ~viewManager: 'viewManager=?,
) => nativeConfig = ""

@react.component @module("react-native-webview")
external make: (
  ~ref: ref=?,
  ~allowingReadAccessToURL: // WebView props
  string=?,
  ~allowFileAccess: bool=?,
  ~allowUniversalAccessFromFileURLs: bool=?,
  ~allowsBackForwardNavigationGestures: bool=?,
  ~allowsFullscreenVideo: bool=?,
  ~allowsInlineMediaPlayback: bool=?,
  ~allowsLinkPreview: bool=?,
  ~androidHardwareAccelerationDisabled: bool=?,
  ~androidLayerType: [#none | #software | #hardware]=?,
  ~applicationNameForUserAgent: string=?,
  ~automaticallyAdjustContentInsets: bool=?,
  ~bounces: bool=?,
  ~cacheEnabled: bool=?,
  ~cacheMode: [
    | @as("LOAD_DEFAULT") #default
    | @as("LOAD_CACHE_ONLY") #cacheOnly
    | @as("LOAD_CACHE_ELSE_NETWORK") #cacheElseNetwork
    | @as("LOAD_NO_CACHE") #noCache
  ]=?,
  ~containerStyle: ReactNative.Style.t=?,
  ~contentInset: Rect.t=?,
  ~contentInsetAdjustmentBehavior: [
    | #never
    | #always
    | #automatic
    | #scrollableAxes
  ]=?,
  ~contentMode: [#recommended | #mobile | #desktop]=?,
  //   ~dataDetectorTypes: array<DataDetectorTypes.t>=?,
  //   ~decelerationRate: DecelerationRate.t=?,
  ~directionalLockEnabled: bool=?,
  ~domStorageEnabled: bool=?,
  ~geolocationEnabled: bool=?,
  ~hideKeyboardAccessoryView: bool=?,
  ~incognito: bool=?,
  ~injectedJavaScript: string=?,
  ~injectedJavaScriptForMainFrameOnly: bool=?,
  ~injectedJavaScriptBeforeContentLoaded: string=?,
  ~injectedJavaScriptBeforeContentLoadedForMainFrameOnly: bool=?,
  ~javaScriptCanOpenWindowsAutomatically: bool=?,
  ~javaScriptEnabled: bool=?,
  ~keyboardDisplayRequiresUserAction: bool=?,
  ~mediaPlaybackRequiresUserAction: bool=?,
  ~mixedContentMode: [#never | #always | #compatibility]=?,
  ~nativeConfig: nativeConfig=?,
  ~onContentProcessDidTerminate: WebViewTerminatedEvent.t => unit=?,
  ~onFileDownload: WebViewDownloadEvent.t => unit=?,
  ~onError: WebViewErrorEvent.t => unit=?,
  ~onHttpError: WebViewHttpErrorEvent.t => unit=?,
  ~onLoad: WebViewNavigationEvent.t => unit=?,
  //   ~onLoadEnd: UnionCallback.t=?,
  ~onLoadProgress: WebViewProgressEvent.t => unit=?,
  ~onLoadStart: WebViewNavigationEvent.t => unit=?,
  ~onMessage: WebViewMessageEvent.t => unit=?,
  ~onNavigationStateChange: webViewNavigation => unit=?,
  ~onRenderProcessGone: WebViewRenderProcessGone.t => unit=?,
  ~onShouldStartLoadWithRequest: webViewShouldStartLoadWithRequest => bool=?,
  ~originWhitelist: array<string>=?,
  ~overScrollMode: [#never | #always | #content]=?,
  ~pagingEnabled: bool=?,
  ~pullToRefreshEnabled: bool=?,
  ~renderError: string => React.element=?,
  ~renderLoading: unit => React.element=?,
  ~saveFormDataDisabled: bool=?,
  ~scalesPageToFit: bool=?,
  ~scrollEnabled: bool=?,
  ~sharedCookiesEnabled: bool=?,
  ~showsHorizontalScrollIndicator: bool=?,
  ~showsVerticalScrollIndicator: bool=?,
  ~source: Source.t=?,
  ~startInLoadingState: bool=?,
  ~textZoom: float=?,
  ~ignoreSilentHardwareSwitch: bool=?,
  ~thirdPartyCookiesEnabled: bool=?,
  ~userAgent: string=?,
  ~accessibilityActions: // View props 0.63.0
  array<Accessibility.actionInfo>=?,
  ~accessibilityElementsHidden: bool=?,
  ~accessibilityHint: string=?,
  ~accessibilityIgnoresInvertColors: bool=?,
  ~accessibilityLabel: string=?,
  ~accessibilityLiveRegion: Accessibility.liveRegion=?,
  ~accessibilityRole: Accessibility.role=?,
  ~accessibilityState: Accessibility.state=?,
  ~accessibilityValue: Accessibility.value=?,
  ~accessibilityViewIsModal: bool=?,
  ~accessible: bool=?,
  ~collapsable: bool=?,
  ~hitSlop: Rect.t=?,
  ~importantForAccessibility: [
    | #auto
    | #yes
    | #no
    | @as("no-hide-descendants") #noHideDescendants
  ]=?,
  ~nativeID: string=?,
  ~needsOffscreenAlphaCompositing: bool=?,
  ~onAccessibilityAction: Accessibility.actionEvent => unit=?,
  ~onAccessibilityEscape: unit => unit=?,
  ~onAccessibilityTap: unit => unit=?,
  ~onLayout: Event.layoutEvent => unit=?,
  ~onMagicTap: unit => unit=?,
  ~onMoveShouldSetResponder: // Gesture Responder props
  Event.pressEvent => bool=?,
  ~onMoveShouldSetResponderCapture: Event.pressEvent => bool=?,
  ~onResponderEnd: Event.pressEvent => unit=?,
  ~onResponderGrant: Event.pressEvent => unit=?,
  ~onResponderMove: Event.pressEvent => unit=?,
  ~onResponderReject: Event.pressEvent => unit=?,
  ~onResponderRelease: Event.pressEvent => unit=?,
  ~onResponderStart: Event.pressEvent => unit=?,
  ~onResponderTerminate: Event.pressEvent => unit=?,
  ~onResponderTerminationRequest: Event.pressEvent => bool=?,
  ~onStartShouldSetResponder: Event.pressEvent => bool=?,
  ~onStartShouldSetResponderCapture: Event.pressEvent => bool=?,
  ~pointerEvents: [
    | #auto
    | #none
    | @as("box-none") #boxNone
    | @as("box-only") #boxOnly
  ]=?,
  ~removeClippedSubviews: bool=?,
  ~renderToHardwareTextureAndroid: bool=?,
  ~shouldRasterizeIOS: bool=?,
  ~style: Style.t=?,
  ~testID: string=?,
  ~children: React.element=?,
  ~onMouseDown: // React Native Web Props
  ReactEvent.Mouse.t => unit=?,
  ~onMouseEnter: ReactEvent.Mouse.t => unit=?,
  ~onMouseLeave: ReactEvent.Mouse.t => unit=?,
  ~onMouseMove: ReactEvent.Mouse.t => unit=?,
  ~onMouseOver: ReactEvent.Mouse.t => unit=?,
  ~onMouseOut: ReactEvent.Mouse.t => unit=?,
  ~onMouseUp: ReactEvent.Mouse.t => unit=?,
) => React.element = "default"
