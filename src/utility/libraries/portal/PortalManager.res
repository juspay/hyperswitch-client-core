type portalItem = {
  key: int,
  children: React.element,
}

type portals = {
  mount: (int, React.element) => unit,
  update: (int, React.element) => unit,
  unmount: int => unit,
}

@react.component
let make = React.forwardRef((ref: Js.Nullable.t<React.ref<Nullable.t<portals>>>) => {
  let (portals, setPortals) = React.useState(_ => [])

  let mount = React.useCallback0((key, children) => {
    setPortals(prevPortals => [...prevPortals, {key, children}])
  })

  let update = React.useCallback0((key, children) => {
    setPortals(
      prevPortals => prevPortals->Array.map(item => item.key === key ? {...item, children} : item),
    )
  })

  let unmount = React.useCallback0(key => {
    setPortals(prevPortals => prevPortals->Array.filter(item => item.key !== key))
  })

  React.useImperativeHandle0(ref, () => Value({
    mount,
    update,
    unmount,
  }))

  {
    portals
    ->Array.map(({key, children}) =>
      <ReactNative.View
        key={key->Int.toString}
        collapsable=false
        pointerEvents=#"box-none"
        style=ReactNative.StyleSheet.absoluteFill
      >
        {children}
      </ReactNative.View>
    )
    ->React.array
  }
})
