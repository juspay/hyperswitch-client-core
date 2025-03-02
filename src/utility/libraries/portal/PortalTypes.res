type portalManagerRefType = {
  mount: React.element => Promise.t<int>,
  unmount: int => unit,
  update: (int, React.element) => Promise.t<int>,
}

type portalItem = {
  key: int,
  children: React.element,
}
