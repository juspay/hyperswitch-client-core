open ReactNative
open Style

type isRTL = {isRTL: bool}
type i18nManager = {getConstants: unit => isRTL}
@val @scope("ReactNative") external i18nManager: i18nManager = "I18nManager"

type initialLayout = {
  height?: float,
  width?: float,
}
@live
type state = {navigationState: TabViewType.navigationState}

@react.component
let make = (
  ~indexInFocus,
  ~routes,
  ~onIndexChange=_ => (),
  ~renderScene,
  ~initialLayout: initialLayout={},
  ~keyboardDismissMode=#auto,
  ~lazyFn_: option<(~route: TabViewType.route) => bool>=?,
  ~lazy_: bool=false,
  ~lazyPreloadDistance: int=100,
  ~onSwipeStart: unit => unit=_ => (),
  ~onSwipeEnd: unit => unit=_ => (),
  ~renderLazyPlaceholder: (~route: TabViewType.route) => React.element=(~route as _) => React.null,
  ~renderTabBar,
  ~sceneContainerStyle=viewStyle(~flex=1., ()),
  ~pagerStyle: ReactNative.Style.t=viewStyle(),
  ~style: ReactNative.Style.t=viewStyle(),
  ~direction: TabViewType.localeDirection=i18nManager.getConstants().isRTL ? #rtl : #ltr,
  ~swipeEnabled: bool=true,
  ~tabBarPosition=#top,
  ~animationEnabled=true,
) => {
  let (layout, setLayout) = React.useState(_ => {
    let x: Event.ScrollEvent.dimensions = {
      width: initialLayout.width->Option.getOr(0.),
      height: initialLayout.height->Option.getOr(0.),
    }
    x
  })

  let jumpToIndex = index => {
    if index !== indexInFocus {
      onIndexChange(index)
    }
  }

  let handleLayout = (e: Event.layoutEvent) => {
    let {height, width} = e.nativeEvent.layout

    setLayout(prevLayout =>
      if prevLayout.width === width && prevLayout.height === height {
        prevLayout
      } else {
        {height, width}
      }
    )
  }

  <View onLayout={handleLayout} style={array([viewStyle(~flex=1., ~overflow=#hidden, ()), style])}>
    <Pager
      layout
      indexInFocus
      routes
      keyboardDismissMode
      swipeEnabled
      onSwipeStart
      onSwipeEnd
      onIndexChange=jumpToIndex
      animationEnabled
      style=pagerStyle
      layoutDirection=direction>
      {(~addEnterListener, ~jumpTo, ~position, ~render, ~indexInFocus, ~routes) => {
        <React.Fragment>
          {tabBarPosition === #top
            ? renderTabBar(~indexInFocus, ~routes, ~position, ~layout, ~jumpTo)
            : React.null}
          {routes
          ->Array.mapWithIndex((route, i) => {
            <SceneView
              indexInFocus
              position
              layout
              jumpTo
              addEnterListener
              key={route.title ++ route.key->Int.toString}
              index=i
              lazy_={switch lazyFn_ {
              | Some(fn) => fn(~route)
              | None => lazy_
              }}
              lazyPreloadDistance
              style=sceneContainerStyle>
              {(~loading) =>
                loading
                  ? renderLazyPlaceholder(~route)
                  : renderScene(~route, ~position, ~layout, ~jumpTo)}
            </SceneView>
          })
          ->React.array
          ->render}
          {tabBarPosition === #bottom
            ? renderTabBar(~indexInFocus, ~routes, ~position, ~layout, ~jumpTo)
            : React.null}
        </React.Fragment>
      }}
    </Pager>
  </View>
}
