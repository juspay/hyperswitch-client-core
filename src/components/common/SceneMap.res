module SceneComponent = {
  @react.component
  let make = React.memo((
    ~component,
    ~route as _: TabViewType.route,
    ~jumpTo as _: int => unit,
    ~position as _: int,
  ) => component)
}

let sceneMap = (component, route, jumpTo, position) =>
  <SceneComponent key={route.key->Int.toString} component route jumpTo position />
