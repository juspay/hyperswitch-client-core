open React
open ReactNative

@react.component
let make = (~portalRef) => {
  let (portals, setPortals) = React.useState(() => [])
  let (_, setPortalContext) = React.useContext(PortalContext.portalContext)
  let keyIdx = React.useRef(0)

  let mount = children => {
    Promise.make((resolve, _) => {
      setPortals(prev => {
        keyIdx.current = keyIdx.current + 1
        resolve(keyIdx.current)
        [...prev, ({key: keyIdx.current, children}: PortalTypes.portalItem)]
      })
    })
  }

  let unmount = key => {
    setPortals(prev => prev->Array.filter(item => item.key != key))
  }

  React.useImperativeHandle(portalRef, (): PortalTypes.portalManagerRefType => {mount, unmount}, [])

  React.useEffect0(() => {
    setPortalContext({
      mount,
      unmount,
    })
    None
  })

  <>
    {portals
    ->Array.map(({key, children}) =>
      <View
        key={key->Int.toString}
        collapsable=false
        pointerEvents=#"box-none"
        style={StyleSheet.absoluteFill}>
        {children}
      </View>
    )
    ->React.array}
  </>
}
