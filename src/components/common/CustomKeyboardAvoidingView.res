open ReactNative
open Style

@react.component
let make = (~children, ~style, ~sheetBackground=?) => {
  let viewRef = React.useRef(Nullable.null)
  // (y, height) in window coordinates, the same space as the keyboard frame, so the overlap is exact
  // on every device instead of assuming how far the sheet's parent sits from the top of the screen.
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
      | Some((y, height)) => max(y +. height -. keyboardFrame.screenY, 0.)
      | None => 0.
      }
    }
  }

  let updateBottomIfNecessary = async () => {
    switch keyboardEvent.current {
    | Some(keyboardEvent: Keyboard.keyboardEvent) => {
        let {duration, easing, endCoordinates, startCoordinates} = keyboardEvent
        let height = await relativeKeyboardHeight(endCoordinates)

        if bottom != height || height === 0. {
          setBottom(_ => height)

          if duration != 0. {
            // Fabric animates the "keyboard" easing linearly and starts a few frames after the keyboard,
            // so a keyboard moving down uncovers the padding before it has shrunk. Shrink it faster with
            // ease-out so it keeps up. (startCoordinates is only sent on iOS.)
            let isMovingDown =
              Platform.os === #ios && endCoordinates.screenY > startCoordinates.screenY
            let duration = isMovingDown ? duration /. 2. : duration
            LayoutAnimation.configureNext({
              duration: duration > 10. ? duration : 10.,
              update: {
                duration: duration > 10. ? duration : 10.,
                \"type": isMovingDown ? #easeOut : easing,
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

  let onLayoutChange = _ =>
    switch viewRef.current->Nullable.toOption {
    | Some(view) =>
      view->View.measureInWindow((~x as _, ~y, ~width as _, ~height) => {
        let oldFrame = frame.current
        frame.current = Some((y, height))

        switch oldFrame {
        | Some((oldY, oldHeight)) if oldY === y && oldHeight === height => ()
        | _ => updateBottomIfNecessary()->ignore
        }
      })
    | None => ()
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

  let paddingBottom = frame.current->Option.isSome && bottom > 0. ? bottom : 0.
  let style = paddingBottom > 0. ? array([style, s({paddingBottom: paddingBottom->dp})]) : style

  <View ref={viewRef->Ref.value} onLayout=onLayoutChange style>
    // Fills the keyboard padding with the sheet background so translucent keyboards show the sheet,
    // not the backdrop. It covers only the padding, so translucent sheet colours never stack, and
    // stays mounted so it shrinks with the padding instead of disappearing before it.
    {switch sheetBackground {
    | Some(background) =>
      <View
        pointerEvents=#none
        style={array([
          s({
            position: #absolute,
            left: 0.->dp,
            right: 0.->dp,
            bottom: 0.->dp,
            height: paddingBottom->dp,
          }),
          background,
        ])}
      />
    | None => React.null
    }}
    {children}
  </View>
}
