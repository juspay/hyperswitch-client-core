open ReactNative

let useAnimatedValue = (initialValue: float) => {
  let lazyRef = React.useRef(None)
  if lazyRef.current === None {
    lazyRef.current = Some(Animated.Value.create(initialValue))
  }
  switch lazyRef.current {
  | Some(val) => val
  | None => Animated.Value.create(initialValue)
  }
}
