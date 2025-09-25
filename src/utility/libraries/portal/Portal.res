@react.component
let make = (~children) => {
  let portalManager = React.useContext(PortalContext.portalContext)
  let currentPortalKey = React.useRef(null)

  React.useEffect0(() => {
    currentPortalKey.current = Value(portalManager.mount(children))
    Some(
      () => {
        switch currentPortalKey.current->Nullable.toOption {
        | Some(key) =>
          portalManager.unmount(key)
          currentPortalKey.current = Null
        | None => ()
        }
      },
    )
  })

  React.useEffect1(() => {
    switch currentPortalKey.current->Nullable.toOption {
    | Some(key) => portalManager.update(key, children)
    | None => ()
    }
    None
  }, [children])

  React.null
}
