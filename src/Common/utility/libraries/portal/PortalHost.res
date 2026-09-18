open ReactNative
open PortalContext

@react.component
let make = (~children) => {
  let managerRef = React.useRef(null)
  let nextKey = React.useRef(0)
  let queue = React.useRef([])

  React.useEffect1(() => {
    switch managerRef.current->Nullable.toOption {
    | Some(manager: PortalManager.portals) =>
      while queue.current->Array.length > 0 {
        switch queue.current->Array.pop {
        | Some(Mount(val)) => manager.mount(val.key, val.children)->ignore
        | Some(Update(val)) => manager.update(val.key, val.children)->ignore
        | Some(Unmount(val)) => manager.unmount(val.key)
        | None => ()
        }
      }
    | None => ()
    }
    None
  }, [managerRef.current])

  let mount = React.useCallback0(children => {
    let key = nextKey.current + 1
    nextKey.current = key

    switch managerRef.current->Nullable.toOption {
    | Some(manager) => manager.mount(key, children)
    | None => queue.current->Array.push(Mount({key, children}))
    }
    key
  })

  let update = React.useCallback0((key, children) => {
    switch managerRef.current->Nullable.toOption {
    | Some(manager) => manager.update(key, children)
    | None =>
      let index = queue.current->Array.findIndex(o =>
        switch o {
        | Mount(val) => val.key === key
        | Update(val) => val.key === key
        | _ => false
        }
      )
      if index > -1 {
        queue.current[index] = Update({key, children})
      } else {
        queue.current->Array.push(Update({key, children}))
      }
    }
  })

  let unmount = React.useCallback0(key => {
    switch managerRef.current->Nullable.toOption {
    | Some(manager) => manager.unmount(key)
    | None => queue.current->Array.push(Unmount({key: key}))
    }
  })

  <Provider value={mount, update, unmount}>
    <View style={Style.s({flex: 1.})} collapsable=false pointerEvents=#"box-none">
      {children}
    </View>
    <PortalManager ref={managerRef} />
  </Provider>
}
