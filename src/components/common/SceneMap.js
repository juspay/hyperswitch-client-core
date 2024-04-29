import * as React from 'react';

const SceneComponent = React.memo(({
  component,
  ...rest
}) => {
  return React.createElement(component, rest);
}
);

export function SceneMap(scenes) {
  return ({ route, jumpTo, position }) => (
    <SceneComponent
      key={route.key}
      component={scenes[route.key]}
      route={route}
      jumpTo={jumpTo}
      position={position}
    />
  );
}