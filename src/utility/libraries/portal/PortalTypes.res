type portalManagerRefType = {
  mount: React.element => Promise.t<int>,
  unmount: int => unit,
}

type portalItem = {
  key: int,
  children: React.element,
}
