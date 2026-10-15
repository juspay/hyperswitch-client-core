open ReactNative
open Style

let defaultActiveColor = Color.rgba(~r=0, ~g=0, ~b=0, ~a=1.0)
let defaultInactiveColor = Color.rgba(~r=0, ~g=0, ~b=0, ~a=0.5)
let iconSize = 24
let androidRippleDefault = {"borderless": true}

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
    ~style: option<Style.t>,
    ~inactiveColor: option<Color.t>,
    ~activeColor: option<Color.t>,
    ~labelStyle: option<Style.t>,
    ~onLayout: option<Event.layoutEvent => unit>,
    ~index as _: int,
    ~pressColor: option<Color.t>,
    ~pressOpacity as _: option<float>,
    ~defaultTabWidth: option<float>,
    ~icon: option<React.component<TabViewType.iconProps>>,
    ~badge: option<React.component<TabViewType.badgeProps>>,
    ~href: option<string>,
    ~labelText,
    ~android_ripple,
    ~labelAllowFontScaling,
    ~route: TabViewType.route,
    ~disabled=false,
    ~isLoading=false,
  ) => {
    let {
      component,
      borderRadius,
      bgColor,
      borderWidth,
      shadowConfig,
    } = ThemebasedStyle.useThemeBasedStyle()
    let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowConfig, ())

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

    let iconElement = React.useMemo5(() => {
      switch icon {
      | None => React.null
      | Some(customIcon) =>
        <View style={s({margin: 2.->dp})}>
          {customIcon({
            focused: isFocused,
            color: isFocused ? activeColorFinal : inactiveColorFinal,
            size: iconSize,
            route,
          })}
        </View>
      }
    }, (activeColorFinal, icon, inactiveColorFinal, isFocused, route))

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
          backgroundColor: isFocused ? component.selected.background : component.background,
          borderWidth: isFocused ? component.selected.borderWidth : borderWidth,
          borderColor: isFocused ? component.selected.borderColor : component.borderColor,
          minWidth: 115.->dp,
          padding: (isFocused ? 10. : 11.5)->dp,
          margin: 6.->dp,
          borderRadius,
        }),
        tabContainerStyle->Option.getOr(empty),
      ])}>
      <View pointerEvents=#none ?style>
        {iconElement}
        <Space height=2. />
        <View>
          <View style={s({opacity: 0.})}> {renderLabel(true)} </View>
          <View style={StyleSheet.absoluteFill}> {renderLabel(isFocused)} </View>
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
    prevProps.label === nextProps.label
  })
}

@react.component
let make = (
  ~onPress,
  ~onLongPress,
  ~onLayout,
  ~navigationState: TabViewType.navigationState,
  ~route: TabViewType.route,
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
    android_ripple
    labelAllowFontScaling
    route
    isLoading
  />
}
