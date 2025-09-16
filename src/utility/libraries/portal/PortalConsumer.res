type portalMethods = {
  mount: React.element => int,
  update: (int, React.element) => unit,
  unmount: int => unit,
}

@react.component
let make = (~manager: option<portalMethods>, ~children) => {
  let keyRef = React.useRef(None)

  React.useEffect0(() => {
    switch manager {
    | Some(mgr) =>
      let key = mgr.mount(children)
      keyRef.current = Some(key)
    | None => ()
    }

    Some(
      () => {
        switch (manager, keyRef.current) {
        | (Some(mgr), Some(key)) => mgr.unmount(key)
        | _ => ()
        }
      },
    )
  })

  React.useEffect1(() => {
    switch (manager, keyRef.current) {
    | (Some(mgr), Some(key)) => mgr.update(key, children)
    | _ => ()
    }
    None
  }, [children])

  React.null
}
