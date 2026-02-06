open ReactNative
open Style

@react.component
let make = (
  ~keyboardDismissMode=#auto,
  ~swipeEnabled=true,
  ~animationEnabled=true,
  ~onSwipeStart=?,
  ~onSwipeEnd=?,
  ~onIndexChange,
  ~onTabSelect=?,
  ~navigationState: TabViewType.navigationState,
  ~renderLazyPlaceholder=(~route as _) => React.null,
  ~tabBarPosition=#top,
  ~renderTabBar,
  ~lazy_=?,
  ~lazyBool=false,
  ~lazyPreloadDistance=0,
  ~direction=TabViewType.i18nManager.getConstants().isRTL ? #rtl : #ltr,
  ~pagerStyle=?,
  ~style=empty,
  ~renderScene: (
    ~route: TabViewType.route,
    ~jumpTo: string => unit,
    ~position: Animated.Interpolation.t,
  ) => React.element,
  ~options as sceneOptions: option<dict<TabViewType.tabDescriptor>>=?,
  ~commonOptions: option<TabViewType.tabDescriptor>=?,
) => {
  if (
    Platform.os !== #web &&
      direction !== (TabViewType.i18nManager.getConstants().isRTL ? #rtl : #ltr)
  ) {
    Console.warn(
      `The 'direction' prop is set to '${direction->TabViewType.localeDirectionToString}' but the effective value is '${TabViewType.localeDirectionToString(
          TabViewType.i18nManager.getConstants().isRTL ? #rtl : #ltr,
        )}'. This is not supported. Make sure to match the 'direction' prop with the writing direction of the app.`,
    )
  }

  let jumpToIndex = index => {
    if index !== navigationState.index {
      onIndexChange(index)
    }
  }

  let options = React.useMemo3(() => {
    let dict = Dict.make()

    navigationState.routes->Array.forEach(route => {
      let routeOptions = sceneOptions->Option.flatMap(opts => opts->Dict.get(route.key))
      let merged: option<TabViewType.tabDescriptor> = switch (commonOptions, routeOptions) {
      | (Some(common), Some(routeOpt)) =>
        Some({
          accessibilityLabel: ?(
            routeOpt.accessibilityLabel->Option.orElse(common.accessibilityLabel)
          ),
          accessible: ?(routeOpt.accessible->Option.orElse(common.accessible)),
          testID: ?(routeOpt.testID->Option.orElse(common.testID)),
          labelText: ?(routeOpt.labelText->Option.orElse(common.labelText)),
          labelAllowFontScaling: ?(
            routeOpt.labelAllowFontScaling->Option.orElse(common.labelAllowFontScaling)
          ),
          href: ?(routeOpt.href->Option.orElse(common.href)),
          label: ?(routeOpt.label->Option.orElse(common.label)),
          labelStyle: ?(routeOpt.labelStyle->Option.orElse(common.labelStyle)),
          icon: ?(routeOpt.icon->Option.orElse(common.icon)),
          badge: ?(routeOpt.badge->Option.orElse(common.badge)),
          sceneStyle: ?(routeOpt.sceneStyle->Option.orElse(common.sceneStyle)),
        })
      | (Some(common), None) => Some(common)
      | (None, Some(routeOpt)) => Some(routeOpt)
      | (None, None) => None
      }

      switch merged {
      | Some(opt) => dict->Dict.set(route.key, opt)
      | None => ()
      }
    })

    Some(dict)
  }, (navigationState.routes, sceneOptions, commonOptions))

  let renderContent = (
    ~position: Animated.Interpolation.t,
    ~render: array<React.element> => React.element,
    ~jumpTo: string => unit,
    ~subscribe: TabViewType.listener => unit => unit,
  ) => {
    <React.Fragment>
      {tabBarPosition === #top
        ? renderTabBar(~position, ~jumpTo, ~navigationState, ~options)
        : React.null}
      {render(
        navigationState.routes->Array.mapWithIndex((route, i) => {
          let sceneStyle =
            options
            ->Option.flatMap(opts => opts->Dict.get(route.key))
            ->Option.flatMap(opt => opt.sceneStyle)

          let isLazy = switch lazy_ {
          | Some(fn) => fn(route)
          | None => lazyBool
          }
          <SceneView
            key={route.key}
            subscribe
            index=i
            lazy_=isLazy
            lazyPreloadDistance
            navigationState
            style=?sceneStyle
          >
            {({loading}) =>
              loading ? renderLazyPlaceholder(~route) : renderScene(~route, ~position, ~jumpTo)}
          </SceneView>
        }),
      )}
      {tabBarPosition === #bottom
        ? renderTabBar(~position, ~jumpTo, ~navigationState, ~options)
        : React.null}
    </React.Fragment>
  }

  <Animated.View style={array([s({overflow: #hidden}), style])}>
    <Pager
      navigationState
      keyboardDismissMode
      swipeEnabled
      ?onSwipeStart
      ?onSwipeEnd
      onIndexChange=jumpToIndex
      ?onTabSelect
      animationEnabled
      layoutDirection=direction
      style=?pagerStyle
    >
      {renderContent}
    </Pager>
  </Animated.View>
}
