module SceneComponent = {
  @react.component
  let make = React.memo((
    ~component: (~route: TabViewType.route, ~position: int, ~jumpTo: int => unit) => React.element,
    ~route: TabViewType.route,
    ~jumpTo: int => unit,
    ~position: int,
  ) => component(~route, ~position, ~jumpTo))
}

let sceneMap = (
  scenes: Map.t<
    int,
    (~route: TabViewType.route, ~position: int, ~jumpTo: int => unit) => React.element,
  >,
) => {
  (~route: TabViewType.route, ~position, ~layout as _, ~jumpTo) => {
    switch scenes->Map.get(route.key) {
    | Some(component) =>
      <SceneComponent key={route.key->Int.toString} component route jumpTo position />
    | None => React.null
    }
  }
}
