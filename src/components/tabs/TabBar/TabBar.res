open ReactNative
open Style
open TabViewType

let measurePerBatch = 10

type calculationOptions = {
  layoutWidth: float,
  gap: option<float>,
  scrollEnabled: option<bool>,
  tabWidths: dict<float>,
  flattenedPaddingStart: option<Style.size>,
  flattenedPaddingEnd: option<Style.size>,
  flattenedTabWidth: option<Style.size>,
}

let getFlattenedTabWidth = (style: option<Style.t>) => {
  let styleDict = style->Option.getOr(Style.s({width: auto}))->Obj.magic
  parseSize(styleDict, "width")
}

let getFlattenedPaddingStart = (style: option<Style.t>) => {
  let styleDict = style->Option.getOr(Style.empty)->Obj.magic
  let paddingLeft = parseSize(styleDict, "paddingLeft")
  switch paddingLeft {
  | #none =>
    let paddingStart = parseSize(styleDict, "paddingStart")
    switch paddingStart {
    | #none => parseSize(styleDict, "paddingHorizontal")
    | _ => paddingStart
    }
  | _ => paddingLeft
  }
}

let getFlattenedPaddingEnd = (style: option<Style.t>) => {
  let styleDict = style->Option.getOr(Style.empty)->Obj.magic
  let paddingRight = parseSize(styleDict, "paddingRight")
  switch paddingRight {
  | #none =>
    let paddingEnd = parseSize(styleDict, "paddingEnd")
    switch paddingEnd {
    | #none => parseSize(styleDict, "paddingHorizontal")
    | _ => paddingEnd
    }
  | _ => paddingRight
  }
}

let convertPaddingPercentToSize = (value: tabSize, layoutWidth: float): float => {
  switch value {
  | #dp(num) => num
  | #pct(num) => layoutWidth *. (num /. 100.)
  | _ => 0.
  }
}

let getComputedTabWidth = (
  ~index: int,
  ~layoutWidth: float,
  ~routes: array<route>,
  ~scrollEnabled: option<bool>,
  ~tabWidths: dict<float>,
  ~flattenedTabWidth: tabSize,
  ~flattenedPaddingStart: tabSize,
  ~flattenedPaddingEnd: tabSize,
  ~gap: option<float>,
) => {
  switch switch flattenedTabWidth {
  | #auto =>
    switch routes[index] {
    | Some(route) => Some(tabWidths->Dict.get(route.key)->Option.getOr(0.))
    | None => Some(0.)
    }
  | #dp(num) => Some(num)
  | #pct(num) => Some(layoutWidth *. (num /. 100.))
  | #none => None
  } {
  | Some(val) => val
  | None =>
    if scrollEnabled->Option.getOr(false) {
      layoutWidth /. 5. *. 2.
    } else {
      let gapTotalWidth = gap->Option.getOr(0.) *. (routes->Array.length - 1)->Int.toFloat
      let paddingTotalWidth =
        convertPaddingPercentToSize(flattenedPaddingStart, layoutWidth) +.
        convertPaddingPercentToSize(flattenedPaddingEnd, layoutWidth)
      (layoutWidth -. gapTotalWidth -. paddingTotalWidth) /. routes->Array.length->Int.toFloat
    }
  }
}

let getMaxScrollDistance = (tabBarWidth: float, layoutWidth: float) => tabBarWidth -. layoutWidth

let getTranslateX = (
  scrollAmount: Animated.Value.t,
  maxScrollDistance: float,
  direction: localeDirection,
) => {
  Animated.Value.multiply(
    if WebKit.platform === #android && direction == #rtl {
      Animated.Value.add(
        maxScrollDistance->Animated.Value.create,
        Animated.Value.multiply(scrollAmount, -1.->Animated.Value.create),
      )
    } else {
      scrollAmount->Animated.Value.multiply(1.->Animated.Value.create)
    },
    if direction == #rtl {
      1.->Animated.Value.create
    } else {
      -1.->Animated.Value.create
    },
  )
}

let getTabBarWidth = (
  ~routes: array<route>,
  ~layoutWidth: float,
  ~gap: option<float>,
  ~scrollEnabled: option<bool>,
  ~flattenedTabWidth: tabSize,
  ~flattenedPaddingStart: tabSize,
  ~flattenedPaddingEnd: tabSize,
  ~tabWidths: dict<float>,
) => {
  let paddingsWidth = Math.max(
    0.,
    convertPaddingPercentToSize(flattenedPaddingStart, layoutWidth) +.
    convertPaddingPercentToSize(flattenedPaddingEnd, layoutWidth),
  )

  routes->Array.reduceWithIndex(paddingsWidth, (acc, _, i) => {
    acc +.
    (i > 0 ? gap->Option.getOr(0.) : 0.) +.
    getComputedTabWidth(
      ~index=i,
      ~layoutWidth,
      ~routes,
      ~scrollEnabled,
      ~tabWidths,
      ~flattenedTabWidth,
      ~flattenedPaddingStart,
      ~flattenedPaddingEnd,
      ~gap,
    )
  })
}

let normalizeScrollValue = (
  ~layoutWidth: float,
  ~routes: array<route>,
  ~gap: option<float>,
  ~scrollEnabled: option<bool>,
  ~tabWidths: dict<float>,
  ~value: float,
  ~flattenedTabWidth: tabSize,
  ~flattenedPaddingStart: tabSize,
  ~flattenedPaddingEnd: tabSize,
  ~direction: localeDirection,
) => {
  let tabBarWidth = getTabBarWidth(
    ~layoutWidth,
    ~routes,
    ~tabWidths,
    ~gap,
    ~scrollEnabled,
    ~flattenedTabWidth,
    ~flattenedPaddingStart,
    ~flattenedPaddingEnd,
  )
  let maxDistance = getMaxScrollDistance(tabBarWidth, layoutWidth)
  let scrollValue = Math.max(Math.min(value, maxDistance), 0.)

  if WebKit.platform === #android && direction == #rtl {
    maxDistance -. scrollValue
  } else {
    scrollValue
  }
}

let getScrollAmount = (
  ~index: int,
  ~routes: array<route>,
  ~layoutWidth: float,
  ~gap: option<float>,
  ~scrollEnabled: option<bool>,
  ~flattenedTabWidth: tabSize,
  ~tabWidths: dict<float>,
  ~flattenedPaddingStart: tabSize,
  ~flattenedPaddingEnd: tabSize,
  ~direction: localeDirection,
) => {
  let paddingInitial = if direction == #rtl {
    convertPaddingPercentToSize(flattenedPaddingEnd, layoutWidth)
  } else {
    convertPaddingPercentToSize(flattenedPaddingStart, layoutWidth)
  }

  let centerDistance = Array.fromInitializer(~length=index + 1, i =>
    i
  )->Array.reduce(paddingInitial, (total, i) => {
    let tabWidth = getComputedTabWidth(
      ~index=i,
      ~layoutWidth,
      ~routes,
      ~scrollEnabled,
      ~tabWidths,
      ~flattenedTabWidth,
      ~flattenedPaddingStart,
      ~flattenedPaddingEnd,
      ~gap,
    )

    total +.
    (i > 0 ? gap->Option.getOr(0.) : 0.) +. if index === i {
      tabWidth /. 2.
    } else {
      tabWidth
    }
  })

  let scrollAmount = centerDistance -. layoutWidth /. 2.

  normalizeScrollValue(
    ~layoutWidth,
    ~routes,
    ~tabWidths,
    ~value=scrollAmount,
    ~gap,
    ~scrollEnabled,
    ~flattenedTabWidth,
    ~flattenedPaddingStart,
    ~flattenedPaddingEnd,
    ~direction,
  )
}

let getLabelTextDefault = ({route}: scene) => route.title

let getAccessibleDefault = ({route}: scene) => route.accessible->Option.getOr(true)

let getAccessibilityLabelDefault = ({route}: scene) =>
  route.accessibilityLabel->Option.orElse(route.title)

let getTestIdDefault = ({route}: scene) => route.testID

@react.component
let make = (
  ~gap=0.,
  ~scrollEnabled=?,
  ~jumpTo,
  ~navigationState,
  ~position,
  ~activeColor=?,
  ~bounces=?,
  ~contentContainerStyle=?,
  ~inactiveColor=?,
  ~onTabLongPress=?,
  ~onTabPress=?,
  ~pressColor=?,
  ~pressOpacity=?,
  ~direction=i18nManager.getConstants().isRTL ? #rtl : #ltr,
  ~style=?,
  ~tabStyle=?,
  ~testID=?,
  ~android_ripple=?,
  ~options: option<dict<tabDescriptor>>=?,
  ~isLoading,
) => {
  let containerRef = React.useRef(Nullable.null)
  let (layout, onLayout) = MeasureLayoutHook.useMeasureLayout(containerRef)

  let (tabWidths, setTabWidths) = React.useState(() => Dict.make())
  let flatListRef = React.useRef(Nullable.null)
  let isFirst = React.useRef(true)
  let scrollAmount = AnimatedValue.useAnimatedValue(0.)
  let measuredTabWidths = React.useRef(Dict.make())

  let {routes} = navigationState
  let flattenedTabWidth = getFlattenedTabWidth(tabStyle)
  let isWidthDynamic = flattenedTabWidth == #auto
  let flattenedPaddingEnd = getFlattenedPaddingEnd(contentContainerStyle)
  let flattenedPaddingStart = getFlattenedPaddingStart(contentContainerStyle)

  let scrollOffset = getScrollAmount(
    ~layoutWidth=layout.width,
    ~routes,
    ~index=navigationState.index,
    ~tabWidths,
    ~gap=Some(gap),
    ~scrollEnabled,
    ~flattenedTabWidth,
    ~flattenedPaddingStart,
    ~flattenedPaddingEnd,
    ~direction,
  )

  let hasMeasuredTabWidths =
    layout.width != 0. &&
      routes
      ->Array.slice(~start=0, ~end=navigationState.index)
      ->Array.every(r => tabWidths->Dict.get(r.key)->Option.isSome)

  React.useEffect4(() => {
    if isFirst.current {
      isFirst.current = false
      None
    } else if isWidthDynamic && !hasMeasuredTabWidths {
      None
    } else if scrollEnabled->Option.getOr(false) {
      switch flatListRef.current->Nullable.toOption {
      | Some(flatList) => flatList->FlatList.scrollToOffset({offset: scrollOffset, animated: true})
      | None => ()
      }
      None
    } else {
      None
    }
  }, (hasMeasuredTabWidths, isWidthDynamic, scrollEnabled, scrollOffset))

  let tabBarWidth = getTabBarWidth(
    ~layoutWidth=layout.width,
    ~routes,
    ~tabWidths,
    ~gap=Some(gap),
    ~scrollEnabled,
    ~flattenedTabWidth,
    ~flattenedPaddingStart,
    ~flattenedPaddingEnd,
  )

  let renderItem: VirtualizedList.renderItemCallback<route> = React.useCallback(
    ({item: route, index}: VirtualizedList.renderItemProps<route>) => {
      let descriptor = options->Option.flatMap(opts => opts->Dict.get(route.key))

      let testID =
        descriptor
        ->Option.flatMap(d => d.testID)
        ->Option.orElse(getTestIdDefault({route: route}))

      let labelText =
        descriptor
        ->Option.flatMap(d => d.labelText)
        ->Option.orElse(getLabelTextDefault({route: route}))

      let accessible =
        descriptor
        ->Option.flatMap(d => d.accessible)
        ->Option.getOr(getAccessibleDefault({route: route}))

      let accessibilityLabel =
        descriptor
        ->Option.flatMap(d => d.accessibilityLabel)
        ->Option.orElse(getAccessibilityLabelDefault({route: route}))

      let onLayoutHandler = isWidthDynamic
        ? Some(
            (event: Event.layoutEvent) => {
              measuredTabWidths.current->Dict.set(route.key, event.nativeEvent.layout.width)
              if (
                routes->Array.length > measurePerBatch &&
                index === measurePerBatch &&
                routes
                ->Array.slice(~start=0, ~end=measurePerBatch)
                ->Array.every(r => measuredTabWidths.current->Dict.get(r.key)->Option.isSome)
              ) {
                setTabWidths(_ => measuredTabWidths.current)
              } else if (
                routes->Array.every(r => measuredTabWidths.current->Dict.get(r.key)->Option.isSome)
              ) {
                setTabWidths(_ => measuredTabWidths.current)
              }
            },
          )
        : None

      let onPress = _ => {
        let rec event: event = {
          defaultPrevented: false,
          preventDefault: () => {
            event.defaultPrevented = true
          },
        }

        switch onTabPress {
        | Some(fn) => fn(({route: route}: TabViewType.scene))
        | None => ()
        }

        if !event.defaultPrevented {
          jumpTo(route.key)
        }
      }

      let onLongPress = _ => {
        switch onTabLongPress {
        | Some(fn) => fn(({route: route}: TabViewType.scene))
        | None => ()
        }
      }

      let defaultTabWidth = !isWidthDynamic
        ? Some(
            getComputedTabWidth(
              ~index,
              ~layoutWidth=layout.width,
              ~routes,
              ~scrollEnabled,
              ~tabWidths,
              ~flattenedTabWidth,
              ~flattenedPaddingStart,
              ~flattenedPaddingEnd,
              ~gap=Some(gap),
            ),
          )
        : None

      <>
        {gap > 0. && index > 0 ? <Space width={gap} /> : React.null}
        <TabBarItem
          position
          route
          navigationState
          ?testID
          ?labelText
          accessible
          ?accessibilityLabel
          ?activeColor
          ?inactiveColor
          ?pressColor
          ?pressOpacity
          onLayout=onLayoutHandler
          onPress=Some(onPress)
          onLongPress=Some(onLongPress)
          style=?tabStyle
          ?defaultTabWidth
          ?android_ripple
          label=?{descriptor->Option.flatMap(d => d.label)}
          labelStyle=?{descriptor->Option.flatMap(d => d.labelStyle)}
          icon=?{descriptor->Option.flatMap(d => d.icon)}
          badge=?{descriptor->Option.flatMap(d => d.badge)}
          labelAllowFontScaling=?{descriptor->Option.flatMap(d => d.labelAllowFontScaling)}
          href=?{descriptor->Option.flatMap(d => d.href)}
          isLoading
        />
      </>
    },
    (
      isLoading,
      position,
      navigationState,
      options,
      activeColor,
      inactiveColor,
      pressColor,
      pressOpacity,
      isWidthDynamic,
      tabStyle,
      layout,
      routes,
      scrollEnabled,
      tabWidths,
      contentContainerStyle,
      gap,
      android_ripple,
      onTabPress,
      jumpTo,
      onTabLongPress,
    ),
  )

  let keyExtractor = React.useCallback0((item: route, _) => item.key)

  let {sheetContentPadding} = ThemebasedStyle.useThemeBasedStyle()

  let contentContainerStyleMemoized = React.useMemo3(() => {
    array([
      s({
        flexGrow: 1.,
        flexDirection: #row,
        flexWrap: #nowrap,
        padding: (sheetContentPadding -. 6.)->dp,
      }),
      // scrollEnabled->Option.getOr(false) ? s({width: tabBarWidth->dp}) : empty,
      contentContainerStyle->Option.getOr(empty),
    ])
  }, (contentContainerStyle, scrollEnabled, tabBarWidth))

  let handleScroll = React.useMemo1(() => {
    Animated.event1(
      [
        {
          "nativeEvent": {
            "contentOffset": {"x": scrollAmount},
          },
        },
      ],
      {useNativeDriver: false},
    )
  }, [scrollAmount])

  let handleViewableItemsChanged = React.useCallback0((
    {changed}: VirtualizedList.viewableItemsChanged<route>,
  ) => {
    if routes->Array.length > measurePerBatch {
      switch changed->Array.get(changed->Array.length - 1) {
      | Some(item) =>
        let index = item.index->Js.undefinedToOption->Option.getOr(0)
        let isViewable = item.isViewable
        if (
          isViewable &&
          (mod(index, 10) === 0 ||
          index === navigationState.index ||
          index === routes->Array.length - 1)
        ) {
          setTabWidths(_ => measuredTabWidths.current)
        }
      | None => ()
      }
    }
  })

  <Animated.View
    ref={containerRef->ReactNative.Ref.value}
    onLayout
    style={array([s({zIndex: 1}), style->Option.getOr(empty)])}
  >
    <View style={s({overflow: #scroll})}>
      <Animated.FlatList
        data={routes}
        keyExtractor
        horizontal=true
        role=#tablist
        keyboardShouldPersistTaps=#handled
        scrollEnabled={scrollEnabled->Option.getOr(false)}
        bounces={bounces->Option.getOr(false)}
        initialNumToRender={measurePerBatch + 1}
        onViewableItemsChanged={handleViewableItemsChanged}
        alwaysBounceHorizontal=false
        scrollsToTop=false
        showsHorizontalScrollIndicator=false
        showsVerticalScrollIndicator=false
        automaticallyAdjustContentInsets=false
        contentContainerStyle={contentContainerStyleMemoized}
        scrollEventThrottle=16
        renderItem
        onScroll={handleScroll}
        ref={flatListRef->ReactNative.Ref.value}
        ?testID
      />
    </View>
  </Animated.View>
}
