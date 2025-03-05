@react.component
let make = (~children) => {
  let portalManager = React.useContext(PortalContext.portalContext)
  let currentPortalKey = React.useRef(null)

  React.useEffect1(() => {
    switch currentPortalKey.current->Nullable.toOption {
    | Some(key) => portalManager.update(key, children)
    | None => currentPortalKey.current = Value(portalManager.mount(children))
    }
    Some(
      () => {
        switch currentPortalKey.current->Nullable.toOption {
        | Some(key) => portalManager.unmount(key)
        | None => ()
        }
      },
    )
  }, [children])

  React.null
}
