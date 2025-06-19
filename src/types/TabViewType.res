type route = {
  key: int,
  icon?: string,
  title: string,
  accessible?: bool,
  accessibilityLabel?: string,
  testID?: string,
  componentHoc: (
    ~isScreenFocus: bool,
    ~setConfirmButtonDataRef: React.element => unit,
  ) => React.element,
}

type scene = {route: route}

type navigationState = {
  index: int,
  routes: array<route>,
}

type listener = int => unit

type sceneRendererProps = {
  layout: ReactNative.Event.LayoutEvent.layout,
  position: ReactNative.Animated.Interpolation.t,
  jumpTo: string => unit,
}

type eventEmitterProps = {addEnterListener: (listener, unit) => unit}

type onPageScrollEventData = {
  position: float,
  offset: float,
}

type onPageSelectedEventData = {position: float, offset: float}

type pageScrollState = [#idle | #dragging | #settling]

type onPageScrollStateChangedEventData = {pageScrollState: pageScrollState}

type localeDirection = [#ltr | #rtl]

type orientation = [#horizontal | #vertical]

type overScrollMode = [#auto | #always | #never]

type keyboardDismissMode = [#auto | #none | #"on-drag"]

type tabBarPosition = [#top | #bottom]

type pagerViewProps = {
  scrollEnabled: option<bool>,
  layoutDirection: option<localeDirection>,
  initialPage: option<int>,
  orientation: option<orientation>,
  offscreenPageLimit: option<int>,
  pageMargin: option<int>,
  overScrollMode: option<overScrollMode>,
  overdrag: option<bool>,
  keyboardDismissMode: option<keyboardDismissMode>,
  onPageScroll: onPageScrollEventData => unit,
  onPageSelected: onPageSelectedEventData => unit,
  onPageScrollStateChanged: onPageScrollStateChangedEventData => unit,
}

type pagerProps = {
  scrollEnabled: option<bool>,
  layoutDirection: option<localeDirection>,
  initialPage: option<int>,
  orientation: option<orientation>,
  offscreenPageLimit: option<int>,
  pageMargin: option<int>,
  overScrollMode: option<overScrollMode>,
  overdrag: option<bool>,
  keyboardDismissMode: option<keyboardDismissMode>,
  swipeEnabled: option<bool>,
  animationEnabled: option<bool>,
  onSwipeStart: unit => unit,
  onSwipeEnd: unit => unit,
}
