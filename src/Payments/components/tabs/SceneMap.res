open ReactNative

type sceneProps = {
  route: TabViewType.route,
  jumpTo: string => unit,
  position: Animated.Interpolation.t,
}

module SceneComponent = {
  @react.component
  let make = (~component, ~route, ~jumpTo, ~position) => {
    component({route, jumpTo, position})
  }
}

module MemoisedSceneComponent = {
  let make = React.memoCustomCompareProps(SceneComponent.make, (prevProps, nextProps) => {
    prevProps.route === nextProps.route
  })
}

let sceneMap = scenes => {
  (~route: TabViewType.route, ~jumpTo, ~position) => {
    let routeKey = route.key
    switch scenes->Map.get(routeKey) {
    | Some(component) => <MemoisedSceneComponent key={routeKey} component route jumpTo position />
    | None => React.null
    }
  }
}
