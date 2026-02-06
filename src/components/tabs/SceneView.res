open ReactNative
open Style

type sceneProps = {loading: bool}

@react.component
let make = (
  ~children,
  ~navigationState: TabViewType.navigationState,
  ~lazy_,
  ~index,
  ~lazyPreloadDistance,
  ~subscribe: TabViewType.listener => unit => unit,
  ~style=empty,
) => {
  let isFocused = navigationState.index === index
  let isLoaded = isFocused || Math.Int.abs(navigationState.index - index) <= lazyPreloadDistance

  let (isLoading, setIsLoading) = React.useState(() => !isLoaded)

  if isLoading && isLoaded {
    setIsLoading(_ => false)
  }

  React.useEffect4(() => {
    let unsubscribe = ref(None)
    let timer = ref(None)

    if lazy_ && isLoading {
      let unsub = subscribe(event => {
        if event.\"type" == #enter && event.index === index {
          setIsLoading(
            prevState => {
              if prevState {
                false
              } else {
                prevState
              }
            },
          )
        }
      })
      unsubscribe := Some(unsub)
    } else if isLoading {
      let timeoutId = setTimeout(() => setIsLoading(_ => false), 0)
      timer := Some(timeoutId)
    }

    Some(
      () => {
        switch unsubscribe.contents {
        | Some(unsub) => unsub()
        | None => ()
        }

        switch timer.contents {
        | Some(timeoutId) => clearTimeout(timeoutId)
        | None => ()
        }
      },
    )
  }, (subscribe, index, isLoading, lazy_))

  <View
    accessibilityElementsHidden={!isFocused}
    importantForAccessibility={isFocused ? #auto : #"no-hide-descendants"}
    style={array([s({flexGrow: 1.}), style])}
  >
    {children({loading: false})}
  </View>
}
