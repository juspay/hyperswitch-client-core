@react.component
let make = (~children) => {
  let (portalManager, _) = React.useContext(PortalContext.portalContext)
  let currentPortalKey = React.useRef(0)

  let mount = async () => {
    currentPortalKey.current = await portalManager.mount(children)
  }

  let unmount = () => {
    portalManager.unmount(currentPortalKey.current)
  }

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
