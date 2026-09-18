open ReactNative

type layout = {
  width: float,
  height: float,
}

@send
external measure: (View.element, (float, float, float, float) => unit) => unit = "measure"

let useMeasureLayout = (
  ref: React.ref<Nullable.t<View.element>>,
  ~onMeasure: option<layout => unit>=?,
) => {
  let (layout, setLayout) = React.useState(() => {width: 0., height: 0.})

  let onMeasureLatest = TabViewType.useLatestCallback((newLayout: layout) => {
    setLayout(currentLayout => {
      if currentLayout.width === newLayout.width && currentLayout.height === newLayout.height {
        currentLayout
      } else {
        newLayout
      }
    })

    switch onMeasure {
    | Some(fn) => fn(newLayout)
    | None => ()
    }
  })

  React.useLayoutEffect2(() => {
    switch ref.current->Nullable.toOption {
    | Some(view) =>
      view->measure((_x, _y, width, height) => {
        onMeasureLatest({width, height})
      })
    | None => ()
    }
    None
  }, (onMeasureLatest, ref))

  let onLayout = React.useCallback1((event: Event.layoutEvent) => {
    let {width, height} = event.nativeEvent.layout
    onMeasureLatest({width, height})
  }, [onMeasureLatest])

  (layout, onLayout)
}
