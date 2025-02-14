@react.component
let make = (~children) => {
  let (portalManager, _) = React.useContext(PortalContext.portalContext)
  let currentPortalKey = React.useRef(0)
  let isFirstRender = currentPortalKey.current == 0

  let mount = async () => {
    currentPortalKey.current = await portalManager.mount(children)
  }

  let unmount = () => {
    portalManager.unmount(currentPortalKey.current)
  }

  let update = async () => {
    currentPortalKey.current = await portalManager.update(currentPortalKey.current, children)
  }

  React.useEffect1(() => {
    if !isFirstRender {
      update()->ignore
    }
    None
  }, [children])

  React.useEffect0(() => {
    mount()->ignore
    Some(
      () => {
        unmount()
      },
    )
  })

  React.null
}
