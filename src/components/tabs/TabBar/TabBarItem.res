open ReactNative
open Style

let defaultActiveColor = Color.rgba(~r=0, ~g=0, ~b=0, ~a=1.0)
let defaultInactiveColor = Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.5)
let iconSize = 24
let androidRippleDefault = {"borderless": true}

let getActiveOpacity = (
  position: Animated.value<Animated.calculated>,
  routesLength: int,
  tabIndex: int,
) => {
  if routesLength > 1 {
    let inputRange = Array.fromInitializer(~length=routesLength, i => i->Int.toFloat)

    position->Animated.Interpolation.interpolate({
      inputRange,
      outputRange: inputRange
      ->Array.map(i => i->Float.toInt === tabIndex ? 1.0 : 0.0)
      ->Animated.Interpolation.fromFloatArray,
    })
  } else {
    1.->Animated.Value.create->Animated.Value.add(0.->Animated.Value.create)
  }
}

let getInactiveOpacity = (
  position: Animated.value<Animated.calculated>,
  routesLength: int,
  tabIndex: int,
) => {
  if routesLength > 1 {
    let inputRange = Array.fromInitializer(~length=routesLength, i => i->Int.toFloat)

    position->Animated.Interpolation.interpolate({
      inputRange,
      outputRange: inputRange
      ->Array.map(i => i->Float.toInt === tabIndex ? 0.0 : 1.0)
      ->Animated.Interpolation.fromFloatArray,
    })
  } else {
    0.->Animated.Value.create->Animated.Value.add(0.->Animated.Value.create)
  }
}

module TabBarItemInternal = {
  @react.component
  let make = (
    ~accessibilityLabel,
    ~accessible: bool,
    ~label: option<React.component<TabViewType.labelProps>>,
    ~testID,
    ~onLongPress: option<Event.pressEvent => unit>,
    ~onPress: option<Event.pressEvent => unit>,
    ~isFocused: bool,
    ~position: Animated.value<Animated.calculated>,
    ~style: option<Style.t>,
    ~inactiveColor: option<Color.t>,
    ~activeColor: option<Color.t>,
    ~labelStyle: option<Style.t>,
    ~onLayout: option<Event.layoutEvent => unit>,
    ~index: int,
    ~pressColor: option<Color.t>,
    ~pressOpacity as _: option<float>,
    ~defaultTabWidth: option<float>,
    ~icon: option<React.component<TabViewType.iconProps>>,
    ~badge: option<React.component<TabViewType.badgeProps>>,
    ~href: option<string>,
    ~labelText,
    ~routesLength,
    ~android_ripple,
    ~labelAllowFontScaling,
    ~route: TabViewType.route,
    ~disabled=false,
    ~isLoading=false,
  ) => {
    let {
      component,
      primaryColor,
      borderRadius,
      bgColor,
      borderWidth,
      shadowColor,
      shadowIntensity,
    } = ThemebasedStyle.useThemeBasedStyle()
    let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

    let labelColorFromStyle = switch labelStyle {
    // | Some(s) => s.color
    | _ => None
    }

    let activeColorFinal = switch activeColor {
    | Some(c) => c
    | None =>
      switch labelColorFromStyle {
      | Some(c) => c
      | None => defaultActiveColor
      }
    }

    let inactiveColorFinal = switch inactiveColor {
    | Some(c) => c
    | None =>
      switch labelColorFromStyle {
      | Some(c) => c
      | None => defaultInactiveColor
      }
    }

    let activeOpacity = getActiveOpacity(position, routesLength, index)
    let inactiveOpacity = getInactiveOpacity(position, routesLength, index)

    let iconElement = React.useMemo6(() => {
      switch icon {
      | None => React.null
      | Some(customIcon) =>
        let inactiveIcon = customIcon({
          focused: false,
          color: inactiveColorFinal,
          size: iconSize,
          route,
        })

        let activeIcon = customIcon({focused: true, color: activeColorFinal, size: iconSize, route})

        <View style={s({margin: 2.->dp})}>
          <Animated.View style={s({opacity: inactiveOpacity->Animated.StyleProp.float})}>
            {inactiveIcon}
          </Animated.View>
          <Animated.View
            style={array([
              StyleSheet.absoluteFill,
              s({opacity: activeOpacity->Animated.StyleProp.float}),
            ])}
          >
            {activeIcon}
          </Animated.View>
        </View>
      }
    }, (activeColorFinal, activeOpacity, icon, inactiveColorFinal, inactiveOpacity, route))

    let renderLabel = React.useCallback7(focused => {
      switch label {
      | Some(customLabel) =>
        customLabel({
          focused,
          color: focused ? activeColorFinal : inactiveColorFinal,
          style: ?labelStyle,
          ?labelText,
          allowFontScaling: ?labelAllowFontScaling,
          route,
        })
      | None => React.null
      }
    }, (
      label,
      activeColorFinal,
      labelStyle,
      labelText,
      labelAllowFontScaling,
      route,
      inactiveColorFinal,
    ))

    let styleDict = style->Option.getOr(Style.s({width: auto}))->Obj.magic
    let tabWidth = TabViewType.parseSize(styleDict, "width")

    let isWidthSet = tabWidth !== #none

    let tabContainerStyle = if !isWidthSet {
      switch defaultTabWidth {
      | Some(width) => Some(s({width: width->dp}))
      | None => None
      }
    } else {
      None
    }

    let ariaLabel = switch accessibilityLabel {
    | Some(label) => Some(label)
    | None => labelText
    }

    let handlePress = (e: Event.pressEvent) => {
      if Platform.os === #web && href->Option.isSome {
        e->Event.PressEvent.preventDefault
      }
      switch onPress {
      | Some(fun) => fun(e)
      | None => ()
      }
    }

    <CustomPressable
      android_ripple=?{disabled
        ? None
        : switch android_ripple {
          | Some(android_ripple) => Some({...android_ripple, color: ?pressColor})
          | None => None
          }}
      ?testID
      accessible
      accessibilityRole=#tab
      accessibilityLabel=?ariaLabel
      unstable_pressDelay={0}
      ?onLayout
      onPress=handlePress
      ?onLongPress
      style={array([
        bgColor,
        getShadowStyle,
        s({
          backgroundColor: component.background,
          borderWidth: isFocused ? borderWidth +. 1.5 : borderWidth,
          borderColor: isFocused ? primaryColor : component.borderColor,
          minWidth: 115.->dp,
          padding: (isFocused ? 10. : 11.5)->dp,
          margin: 6.->dp,
          borderRadius,
        }),
        tabContainerStyle->Option.getOr(empty),
      ])}
    >
      <View pointerEvents=#none ?style>
        {iconElement}
        <Space height=2. />
        <View>
          <Animated.View style={s({opacity: inactiveOpacity->Animated.StyleProp.float})}>
            {renderLabel(false)}
          </Animated.View>
          <Animated.View
            style={array([
              StyleSheet.absoluteFill,
              s({opacity: activeOpacity->Animated.StyleProp.float}),
            ])}
          >
            {renderLabel(true)}
          </Animated.View>
        </View>
        {switch badge {
        | Some(customBadge) =>
          <View style={s({position: #absolute, top: 0.->dp, end: 0.->dp})}>
            {customBadge({route: route})}
          </View>
        | None => React.null
        }}
      </View>
    </CustomPressable>
  }
}

module MemoizedTabBarItemInternal = {
  let make = React.memoCustomCompareProps(TabBarItemInternal.make, (prevProps, nextProps) => {
    prevProps.isFocused === nextProps.isFocused &&
    prevProps.index === nextProps.index &&
    prevProps.route.key === nextProps.route.key &&
    prevProps.isLoading === nextProps.isLoading &&
    prevProps.position === nextProps.position
  })
}

@react.component
let make = (
  ~onPress,
  ~onLongPress,
  ~onLayout,
  ~navigationState: TabViewType.navigationState,
  ~route: TabViewType.route,
  ~position,
  ~activeColor=?,
  ~inactiveColor=?,
  ~pressColor=?,
  ~pressOpacity=?,
  ~defaultTabWidth=?,
  ~style=?,
  ~android_ripple=?,
  ~accessibilityLabel=?,
  ~accessible=true,
  ~testID=?,
  ~labelText=?,
  ~labelAllowFontScaling=?,
  ~href=?,
  ~label=?,
  ~labelStyle=?,
  ~icon=?,
  ~badge=?,
  ~isLoading,
) => {
  let onPressLatest = React.useCallback0(onPress)
  let onLongPressLatest = React.useCallback0(onLongPress)
  let onLayoutLatest = React.useCallback1(
    switch onLayout {
    | Some(fn) => fn
    | None => _ => ()
    },
    [onLayout],
  )

  let tabIndex = navigationState.routes->Array.findIndex(r => r.key === route.key)

  <MemoizedTabBarItemInternal
    accessibilityLabel
    accessible
    label
    testID
    onLongPress=onLongPressLatest
    onPress=onPressLatest
    isFocused={navigationState.index === tabIndex}
    position
    style
    inactiveColor
    activeColor
    labelStyle
    onLayout=Some(onLayoutLatest)
    index=tabIndex
    pressColor
    pressOpacity
    defaultTabWidth
    icon
    badge
    href
    labelText
    routesLength={navigationState.routes->Array.length}
    android_ripple
    labelAllowFontScaling
    route
    isLoading
  />
}
