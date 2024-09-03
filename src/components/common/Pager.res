open ReactNative
open Style

let deadZone = 12.0

@get external getValue: ReactNative.Animated.Value.t => float = "_value"
@get external getOffset: ReactNative.Animated.Value.t => float = "_offset"
external calcToRegular: Animated.value<Animated.calculated> => Animated.value<Animated.regular> =
  "%identity"
external regToFloat: Animated.value<Animated.regular> => float = "%identity"
external calcToFloat: Animated.value<Animated.calculated> => float = "%identity"

type defaultTransitionSpec = {
  timing: (Animated.value<Animated.regular>, Animated.Value.Spring.config) => Animated.Animation.t,
  stiffness: float,
  damping: float,
  mass: float,
  overshootClamping: bool,
}

let defaultTransitionSpec = {
  timing: Animated.spring,
  stiffness: 1000.0,
  damping: 500.0,
  mass: 3.0,
  overshootClamping: true,
}

@react.component
let make = (
  ~layout: Event.ScrollEvent.dimensions,
  ~keyboardDismissMode: TabViewType.keyboardDismissMode=#auto,
  ~swipeEnabled=true,
  ~indexInFocus,
  ~routes,
  ~onIndexChange: int => unit,
  ~onSwipeStart=?,
  ~onSwipeEnd=?,
  ~children: (
    ~addEnterListener: (int => unit) => unit => unit,
    ~jumpTo: int => unit,
    ~position: int,
    ~render: React.element => React.element,
    ~indexInFocus: int,
    ~routes: array<TabViewType.route>,
  ) => React.element,
  ~style=viewStyle(),
  ~animationEnabled=false,
  ~layoutDirection: TabViewType.localeDirection=#ltr,
) => {
  let panX = AnimatedValue.useAnimatedValue(0.0)

  let listenersRef = React.useRef([])

  let navigationState: TabViewType.navigationState = {index: indexInFocus, routes}
  let navigationStateRef = React.useRef(navigationState)
  let layoutRef = React.useRef(layout)
  let onIndexChangeRef = React.useRef(onIndexChange)

  let currentIndexRef = React.useRef(indexInFocus)
  let pendingIndexRef = React.useRef(None)

  let swipeVelocityThreshold = 0.15
  let swipeDistanceThreshold = layout.width /. 1.75

  let jumpToIndex = React.useCallback2((index, animate) => {
    let offset = -.(index->Int.toFloat *. layoutRef.current.width)

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
              useNativeDriver: false,
            },
          ),
        ],
        {stopTogether: false},
      )->Animated.start(~endCallback=endResult => {
        if endResult.finished {
          onIndexChangeRef.current(index)
          pendingIndexRef.current = None
        }
      }, ())
      pendingIndexRef.current = Some(index)
    } else {
      panX->Animated.Value.setValue(offset)
      onIndexChangeRef.current(index)
      pendingIndexRef.current = None
    }
  }, (animationEnabled, panX))

  React.useEffect2(() => {
    navigationStateRef.current = navigationState
    layoutRef.current = layout
    onIndexChangeRef.current = onIndexChange
    None
  }, (navigationState, onIndexChange))

  React.useEffect2(() => {
    let offset = -.(navigationStateRef.current.index->Int.toFloat *. layout.width)

    panX->Animated.Value.setValue(offset)
    None
  }, (layout.width, panX))

  React.useEffect4(() => {
    if keyboardDismissMode == #auto {
      Keyboard.dismiss()
    }

    if layout.width != 0. && currentIndexRef.current !== indexInFocus {
      currentIndexRef.current = indexInFocus
      jumpToIndex(indexInFocus, animationEnabled)
    }
    None
  }, (jumpToIndex, keyboardDismissMode, layout.width, indexInFocus))

  let isMovingHorizontally = (_, gestureState: PanResponder.gestureState) => {
    Math.abs(gestureState.dx) > Math.abs(gestureState.dy *. 2.0) &&
      Math.abs(gestureState.vx) > Math.abs(gestureState.vy *. 2.0)
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
    | Some(fun) => fun()
    | None => ()
    }

    if keyboardDismissMode == #"on-drag" {
      Keyboard.dismiss()
    }

    panX->Animated.Value.stopAnimation()
    panX->Animated.Value.setOffset(panX->getValue)
  }

  let respondToGesture = (_, gestureState: PanResponder.gestureState) => {
    let diffX = if layoutDirection == #rtl {
      -.gestureState.dx
    } else {
      gestureState.dx
    }

    if (
      (diffX > 0.0 && indexInFocus <= 0) ||
        (diffX < 0.0 && indexInFocus >= routes->Array.length - 1)
    ) {
      ()
    } else if layout.width != 0. {
      let position = (panX->getOffset +. diffX) /. -.layout.width
      let next = if position > indexInFocus->Int.toFloat {
        position->Math.ceil->Float.toInt
      } else {
        position->Math.floor->Float.toInt
      }

      if next !== indexInFocus {
        listenersRef.current->Array.forEach(listener => listener(next))
      }
    }

    panX->Animated.Value.setValue(diffX)
  }

  let finishGesture = (_, gestureState: PanResponder.gestureState) => {
    panX->Animated.Value.flattenOffset

    switch onSwipeEnd {
    | Some(fun) => fun()
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

  let addEnterListener = React.useCallback1(listener => {
    listenersRef.current->Belt.Array.push(listener)

    () => {
      let index = listenersRef.current->Array.indexOf(listener)

      if index > -1 {
        listenersRef.current->Array.splice(~start=index, ~remove=1, ~insert=[])
      }
    }
  }, [])

  let jumpTo = React.useCallback1(key => {
    let index =
      navigationStateRef.current.routes->Array.findIndex((route: TabViewType.route) =>
        route.key === key
      )

    jumpToIndex(index, false)
  }, [jumpToIndex])

  let panHandlers = PanResponder.create({
    onMoveShouldSetPanResponder: canMoveScreen,
    onMoveShouldSetPanResponderCapture: canMoveScreen,
    onPanResponderGrant: startGesture,
    onPanResponderMove: respondToGesture,
    onPanResponderTerminate: finishGesture,
    onPanResponderRelease: finishGesture,
    onPanResponderTerminationRequest: (_, _) => true,
  })->PanResponder.panHandlers

  let maxTranslate = layout.width *. -(routes->Array.length - 1)->Int.toFloat
  let translateX = Animated.Value.multiply(
    panX->Animated.Interpolation.interpolate({
      inputRange: [maxTranslate, 0.0],
      outputRange: [maxTranslate, 0.0]->Animated.Interpolation.fromFloatArray,
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
      Animated.Value.divide(panX, -.layout.width->Animated.Value.create)->calcToRegular->Some
    } else {
      None
    }
  }, (layout.width, panX))

  children(
    ~indexInFocus,
    ~routes,
    ~position=position
    ->Option.getOr(Animated.Value.create(indexInFocus->Int.toFloat))
    ->regToFloat
    ->Int.fromFloat,
    ~addEnterListener,
    ~jumpTo,
    ~render=children => {
      <Animated.View
        style={array([
          viewStyle(
            ~flex=1.,
            ~flexDirection=#row,
            ~alignItems=#stretch,
            ~transform=[Style.translateX(~translateX=translateX->calcToFloat)],
            ~width=?layout.width != 0.
              ? (routes->Array.length->Int.toFloat *. layout.width)->dp->Some
              : None,
            (),
          ),
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
        {React.Children.mapWithIndex(children, (child, i) => {
          switch routes[i] {
          | Some(route) =>
            let focused = i === indexInFocus
            <View
              key={route.title ++ route.key->Int.toString}
              style=?{if layout.width != 0. {
                Some(viewStyle(~width=layout.width->dp, ()))
              } else if focused {
                Some(StyleSheet.absoluteFill)
              } else {
                None
              }}>
              {focused || layout.width != 0. ? child : React.null}
            </View>
          | None => React.null
          }
        })}
      </Animated.View>
    },
  )
}
