open ReactNative
open Style

let deadZone = 12.

@get external getValue: Animated.Value.t => float = "_value"
@get external getOffset: Animated.Value.t => float = "_offset"

type defaultTransitionSpec = {
  timing: (Animated.value<Animated.regular>, Animated.Value.Spring.config) => Animated.Animation.t,
  stiffness: float,
  damping: float,
  mass: float,
  overshootClamping: bool,
}

let defaultTransitionSpec = {
  timing: Animated.spring,
  stiffness: 1000.,
  damping: 500.,
  mass: 3.,
  overshootClamping: true,
}

@react.component
let make = (
  ~keyboardDismissMode: TabViewType.keyboardDismissMode=#auto,
  ~swipeEnabled: bool=true,
  ~navigationState: TabViewType.navigationState,
  ~onIndexChange: int => unit,
  ~onTabSelect: option<TabViewType.tabSelect => unit>=?,
  ~onSwipeStart: option<unit => unit>=?,
  ~onSwipeEnd: option<unit => unit>=?,
  ~children: (
    ~position: Animated.Interpolation.t,
    ~render: array<React.element> => React.element,
    ~jumpTo: string => unit,
    ~subscribe: TabViewType.listener => unit => unit,
  ) => React.element,
  ~style: option<Style.t>=empty,
  ~animationEnabled: bool=false,
  ~layoutDirection: TabViewType.localeDirection=#ltr,
) => {
  let {routes, index} = navigationState
  let containerRef = React.useRef(Nullable.null)
  let (layout, onLayout) = MeasureLayoutHook.useMeasureLayout(containerRef)

  let useNativeAnimations = Platform.os !== #web

  let panX = AnimatedValue.useAnimatedValue(0.)

  React.useEffect1(() => {
    let listenerId = panX->Animated.Value.addListener(_ => ())
    Some(() => panX->Animated.Value.removeListener(listenerId))
  }, [panX])

  let listeners = React.useRef(Set.make())

  let navigationStateRef = React.useRef(navigationState)
  let onIndexChangeRef = React.useRef(onIndexChange)
  let onTabSelectRef = React.useRef(onTabSelect)
  let currentIndexRef = React.useRef(index)
  let pendingIndexRef = React.useRef(None)

  let swipeVelocityThreshold = 0.15
  let swipeDistanceThreshold = layout.width /. 1.75

  let jumpToIndex = TabViewType.useLatestCallback((index, animate) => {
    let offset = -.(index->Int.toFloat) *. layout.width

    let {timing, stiffness, damping, mass, overshootClamping} = defaultTransitionSpec

    if animate {
      Animated.parallel(
        [
          timing(
            panX,
            {
              toValue: offset->Animated.Value.Spring.fromRawValue,
              stiffness,
              damping,
              mass,
              overshootClamping,
              useNativeDriver: useNativeAnimations,
            },
          ),
        ],
        {stopTogether: false},
      )->Animated.start(~endCallback=result => {
        if result.finished {
          onIndexChangeRef.current(index)
          switch onTabSelectRef.current {
          | Some(fn) => fn({index: index})
          | None => ()
          }
          pendingIndexRef.current = None
        }
      })
      pendingIndexRef.current = Some(index)
    } else {
      panX->Animated.Value.setValue(offset)
      onIndexChangeRef.current(index)
      switch onTabSelectRef.current {
      | Some(fn) => fn({index: index})
      | None => ()
      }
      pendingIndexRef.current = None
    }
  })

  React.useEffectOnEveryRender(() => {
    navigationStateRef.current = navigationState
    onIndexChangeRef.current = onIndexChange
    onTabSelectRef.current = onTabSelect
    None
  })

  React.useEffect2(() => {
    let offset = -.(navigationStateRef.current.index->Int.toFloat *. layout.width)

    panX->Animated.Value.setValue(offset)
    None
  }, (layout.width, panX))

  React.useEffect4(() => {
    if keyboardDismissMode === #auto {
      Keyboard.dismiss()
    }

    if layout.width != 0. && currentIndexRef.current !== index {
      currentIndexRef.current = index
      jumpToIndex(index, animationEnabled)
    }
    None
  }, (jumpToIndex, keyboardDismissMode, layout.width, index))

  let isMovingHorizontally = (_, gestureState: PanResponder.gestureState) => {
    Math.abs(gestureState.dx) > Math.abs(gestureState.dy *. 2.) &&
      Math.abs(gestureState.vx) > Math.abs(gestureState.vy *. 2.)
  }

  let canMoveScreen = (event, gestureState: PanResponder.gestureState) => {
    if !swipeEnabled {
      false
    } else {
      let diffX = if layoutDirection == #rtl {
        -.gestureState.dx
      } else {
        gestureState.dx
      }

      isMovingHorizontally(event, gestureState) &&
      ((diffX >= deadZone && currentIndexRef.current > 0) ||
        (diffX <= -.deadZone && currentIndexRef.current < routes->Array.length - 1))
    }
  }

  let startGesture = (_, _) => {
    switch onSwipeStart {
    | Some(fn) => fn()
    | None => ()
    }

    if keyboardDismissMode == #"on-drag" {
      Keyboard.dismiss()
    }

    panX->Animated.Value.stopAnimation
    panX->Animated.Value.setOffset(panX->getValue)
  }

  let respondToGesture = (_, gestureState: PanResponder.gestureState) => {
    let diffX = if layoutDirection == #rtl {
      -.gestureState.dx
    } else {
      gestureState.dx
    }

    if (diffX > 0. && index <= 0) || (diffX < 0. && index >= routes->Array.length - 1) {
      ()
    } else if layout.width != 0. {
      let position = (panX->getOffset +. diffX) /. -.layout.width
      let next = if position > index->Int.toFloat {
        position->Math.ceil->Float.toInt
      } else {
        position->Math.floor->Float.toInt
      }

      if next !== index {
        listeners.current->Set.forEach((listener: TabViewType.listener) => {
          listener({\"type": #enter, index: next})
        })
      }
    }

    panX->Animated.Value.setValue(diffX)
  }

  let finishGesture = (_, gestureState: PanResponder.gestureState) => {
    panX->Animated.Value.flattenOffset

    switch onSwipeEnd {
    | Some(fn) => fn()
    | None => ()
    }

    let currentIndex = switch pendingIndexRef.current {
    | Some(value) => value
    | None => currentIndexRef.current
    }

    let nextIndex = if (
      Math.abs(gestureState.dx) > Math.abs(gestureState.dy) &&
      Math.abs(gestureState.vx) > Math.abs(gestureState.vy) &&
      (Math.abs(gestureState.dx) > swipeDistanceThreshold ||
        Math.abs(gestureState.vx) > swipeVelocityThreshold)
    ) {
      let index = Math.round(
        Math.min(
          Math.max(
            0.,
            if layoutDirection == #rtl {
              currentIndex->Int.toFloat +. gestureState.dx /. Math.abs(gestureState.dx)
            } else {
              currentIndex->Int.toFloat -. gestureState.dx /. Math.abs(gestureState.dx)
            },
          ),
          (routes->Array.length - 1)->Int.toFloat,
        ),
      )

      currentIndexRef.current = index->Int.fromFloat
      Float.isFinite(index) ? index->Int.fromFloat : currentIndex
    } else {
      currentIndex
    }

    jumpToIndex(nextIndex, true)
  }

  let subscribe = TabViewType.useLatestCallback(listener => {
    listeners.current->Set.add(listener)

    () => {
      listeners.current->Set.delete(listener)->ignore
    }
  })

  let jumpTo = TabViewType.useLatestCallback(key => {
    let index =
      navigationStateRef.current.routes->Array.findIndex((route: TabViewType.route) =>
        route.key === key
      )

    jumpToIndex(index, animationEnabled)
    onIndexChange(index)
  })

  let panHandlers = PanResponder.create({
    onMoveShouldSetPanResponder: canMoveScreen,
    onMoveShouldSetPanResponderCapture: canMoveScreen,
    onPanResponderGrant: startGesture,
    onPanResponderMove: respondToGesture,
    onPanResponderTerminate: finishGesture,
    onPanResponderRelease: finishGesture,
    onPanResponderTerminationRequest: (_, _) => true,
  })->PanResponder.panHandlers

  let maxTranslate = layout.width *. (routes->Array.length - 1)->Int.toFloat
  let translateX = Animated.Value.multiply(
    panX->Animated.Interpolation.interpolate({
      inputRange: [-.maxTranslate, 0.],
      outputRange: [-.maxTranslate, 0.]->Animated.Interpolation.fromFloatArray,
      extrapolate: #clamp,
    }),
    if layoutDirection == #rtl {
      -1.->Animated.Value.create
    } else {
      1.->Animated.Value.create
    },
  )

  let position = React.useMemo2(() => {
    if layout.width != 0. {
      Animated.Value.divide(panX, -.layout.width->Animated.Value.create)
    } else {
      index->Int.toFloat->Animated.Value.create->Animated.Value.add(0.->Animated.Value.create)
    }
  }, (layout.width, panX))

  let heightValue = AnimatedValue.useAnimatedValue(0.)
  let (heightReady, setHeightReady) = React.useState(() => false)
  let heightReadyRef = React.useRef(false)
  let (heightsVersion, setHeightsVersion) = React.useState(() => 0)
  let measuredTabHeights = React.useRef([])

  React.useEffect2(() => {
    switch measuredTabHeights.current->Array.get(index) {
    | Some(newHeight) =>
      if heightReadyRef.current {
        Animated.timing(
          heightValue,
          {
            toValue: newHeight->Animated.Value.Timing.fromRawValue,
            duration: 250.,
            easing: Easing.inOut(Easing.ease),
            useNativeDriver: false,
          },
        )->Animated.start
      } else {
        heightReadyRef.current = true
        heightValue->Animated.Value.setValue(newHeight)
        setHeightReady(_ => true)
      }
    | None => ()
    }
    None
  }, (index, heightsVersion))

  children(~position, ~subscribe, ~jumpTo, ~render=children => {
    <View ref={containerRef->ReactNative.Ref.value} onLayout style={s({overflow: #hidden})}>
      <Animated.View
        style={heightReady && routes->Array.length > 1
          ? s({overflow: #hidden, height: heightValue->Animated.StyleProp.size})
          : s({overflow: #hidden})}>
      <Animated.View
        style={array([
          s({
            flexDirection: #row,
            alignItems: #stretch,
            transform: [Style.translateX(~translateX=translateX->Animated.StyleProp.size)],
            width: ?(
              layout.width != 0.
                ? Some((routes->Array.length->Int.toFloat *. layout.width)->dp)
                : None
            ),
          }),
          style,
        ])}
        onMoveShouldSetResponder={panHandlers->PanResponder.onMoveShouldSetResponder}
        onMoveShouldSetResponderCapture={panHandlers->PanResponder.onMoveShouldSetResponderCapture}
        onStartShouldSetResponder={panHandlers->PanResponder.onStartShouldSetResponder}
        onStartShouldSetResponderCapture={panHandlers->PanResponder.onStartShouldSetResponderCapture}
        onResponderReject={panHandlers->PanResponder.onResponderReject}
        onResponderGrant={panHandlers->PanResponder.onResponderGrant}
        onResponderRelease={panHandlers->PanResponder.onResponderRelease}
        onResponderMove={panHandlers->PanResponder.onResponderMove}
        onResponderTerminate={panHandlers->PanResponder.onResponderTerminate}
        onResponderStart={panHandlers->PanResponder.onResponderStart}
        onResponderTerminationRequest={panHandlers->PanResponder.onResponderTerminationRequest}
        onResponderEnd={panHandlers->PanResponder.onResponderEnd}>
        {children
        ->Array.mapWithIndex((child, i) => {
          switch routes[i] {
          | Some(route) =>
            let focused = i === index

            if layout.width == 0. && !focused {
              React.null
            } else {
              <View
                key={route.key}
                style=?{if layout.width != 0. {
                  Some(
                    s({
                      width: layout.width->dp,
                    }),
                  )
                } else if focused {
                  Some(StyleSheet.absoluteFill)
                } else {
                  None
                }}>
                <View
                  onLayout={(event: Event.layoutEvent) => {
                    if route.title->Option.getOr("") !== "loading" {
                      let prevHeight = measuredTabHeights.current->Array.get(i)->Option.getOr(0.)
                      let newHeight = event.nativeEvent.layout.height
                      if newHeight > 10. && Math.abs(newHeight -. prevHeight) > 10. {
                        measuredTabHeights.current->Array.set(i, newHeight)
                        setHeightsVersion(v => v + 1)
                      }
                    }
                  }}>
                  {child}
                </View>
              </View>
            }
          | None => React.null
          }
        })
        ->React.array}
      </Animated.View>
      </Animated.View>
    </View>
  })
}
