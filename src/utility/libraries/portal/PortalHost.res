open PortalManager
open PortalTypes
open ReactNative

external toNullable: Js.nullable<PortalTypes.portalManagerRefType> => Js.Nullable.t<
  React.ref<PortalTypes.portalManagerRefType>,
> = "%identity"

type operation =
  | Mount({key: int, children: React.element})
  | Unmount({key: int})
  | Update({key: int, children: React.element})

@react.component
let make = (~children) => {
  let manager = React.createRef()
  let queue = React.useRef([])

  React.useEffect1(() => {
    switch manager.current {
    | Value(m) =>
      while queue.current->Array.length > 0 {
        switch queue.current->Array.pop {
        | Some(Mount(val)) => m.mount(val.children)->ignore
        | Some(Unmount(val)) => m.unmount(val.key)
        | Some(Update(val)) => m.update(val.key, children)->ignore
        | None => ()
        }
      }
    | _ => ()
    }
    None
  }, [manager])

  <PortalContext>
    <View style={Style.viewStyle(~flex=1., ())} collapsable=false pointerEvents=#"box-none">
      children
    </View>
    <PortalManager portalRef={manager.current->toNullable} />
  </PortalContext>
}
