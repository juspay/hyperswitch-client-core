open ReactNative
open Style

@react.component
let make = (~children, ~style, ~keyboardVerticalOffset=48.) => {
  let frame = React.useRef(None)
  let keyboardEvent = React.useRef(None)
  let (bottom, setBottom) = React.useState(() => 0.)

  let relativeKeyboardHeight = async (keyboardFrame: Keyboard.screenRect) => {
    if (
      Platform.os === #ios &&
      keyboardFrame.screenY === 0. &&
      (await AccessibilityInfo.prefersCrossFadeTransitions())
    ) {
      0.
    } else {
      switch frame.current {
      | Some(frame: Event.LayoutEvent.layout) => {
          let keyboardY = keyboardFrame.screenY -. keyboardVerticalOffset
          max(frame.y +. frame.height -. keyboardY, 0.)
        }
      | None => 0.
      }
    }
  }

  let updateBottomIfNecessary = async () => {
    switch keyboardEvent.current {
    | Some(keyboardEvent: Keyboard.keyboardEvent) => {
        let {duration, easing, endCoordinates} = keyboardEvent
        let height = await relativeKeyboardHeight(endCoordinates)

        if bottom != height || height === 0. {
          setBottom(_ => height < 2. *. keyboardVerticalOffset ? 0. : height)

          if duration != 0. {
            LayoutAnimation.configureNext({
              duration: duration > 10. ? duration : 10.,
              update: {
                duration: duration > 10. ? duration : 10.,
                \"type": easing,
              },
            })
          }
        }
      }
    | None => setBottom(_ => 0.)
    }
  }

  let onKeyboardChange = event => {
    keyboardEvent.current = Some(event)
    updateBottomIfNecessary()->ignore
  }

  let onLayoutChange = (event: Event.layoutEvent) => {
    let oldFrame = frame.current
    frame.current = Some(event.nativeEvent.layout)

    switch oldFrame {
    | Some(frame) =>
      if frame.height !== event.nativeEvent.layout.height {
        updateBottomIfNecessary()->ignore
      }
    | None => updateBottomIfNecessary()->ignore
    }
  }

  React.useEffect0(() => {
    let subscriptions = []
    if Platform.os == #ios {
      subscriptions->Array.push(Keyboard.addListener(#keyboardWillChangeFrame, onKeyboardChange))
    } else {
      subscriptions->Array.pushMany([
        Keyboard.addListener(#keyboardDidShow, onKeyboardChange),
        Keyboard.addListener(#keyboardDidHide, onKeyboardChange),
      ])
    }

    Some(
      _ => {
        subscriptions->Array.forEach(subscription => subscription->EventSubscription.remove)
      },
    )
  })

  let style =
    frame.current->Option.isSome && bottom > 0.
      ? array([style, s({paddingBottom: bottom->dp})])
      : style

  <View onLayout=onLayoutChange style> {children} </View>
}
