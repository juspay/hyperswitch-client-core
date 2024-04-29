open ReactNative
open Style

type handleEnter = int => unit
@live
type timerFunctionType = {unsubscribe: option<int => int>, timer: option<timeoutId>}

@react.component
let make = (
  ~children: (~loading: bool) => React.element,
  ~position as _,
  ~jumpTo as _,
  ~indexInFocus,
  ~lazy_,
  ~layout: Event.ScrollEvent.dimensions,
  ~index,
  ~lazyPreloadDistance,
  ~addEnterListener: handleEnter => unit => unit,
  ~style,
) => {
  let (isLoading, setIsLoading) = React.useState(() =>
    Math.Int.abs(indexInFocus - index) > lazyPreloadDistance
  )

  if isLoading && Math.Int.abs(indexInFocus - index) <= lazyPreloadDistance {
    setIsLoading(_ => false)
  }
  React.useEffect4(() => {
    let handleEnter: handleEnter = value => {
      if value === index {
        setIsLoading(prevState => {
          if prevState {
            false
          } else {
            prevState
          }
        })
      }
    }

    let (unsubscribe, timer) = switch (lazy_, isLoading) {
    | (true, true) => (Some(addEnterListener(handleEnter)), None)
    | (_, true) => (None, Some(setTimeout(() => setIsLoading(_ => false), 0)))
    | _ => (None, None)
    }

    Some(
      _ => {
        switch unsubscribe {
        | Some(fun) => fun()
        | _ => ()
        }

        switch timer {
        | Some(time) => clearTimeout(time)
        | None => ()
        }
      },
    )
  }, (addEnterListener, index, isLoading, lazy_))

  let focused = indexInFocus === index

  <View
    accessibilityElementsHidden={!focused}
    importantForAccessibility={focused ? #auto : #"no-hide-descendants"}
    style={array([viewStyle(~flex=1., ~overflow=#hidden, ~width=layout.width->dp, ()), style])}>
    {focused || layout.width != 0. ? children(~loading=false) : React.null}
  </View>
}
