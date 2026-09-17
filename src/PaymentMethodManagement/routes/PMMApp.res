/* Root component of the PMM-only bundle (`hyperPMM`). Mirrors the payments
 * root (`App.res`) but mounts the Payment Methods Management router — keeping
 * the entire payment flow out of this bundle's module graph.
 */
module PMMApp = {
  @react.component
  let make = () => {
    <PMMangementNavigatorRouter />
  }
}

@react.component
let make = (~props, ~rootTag) => {
  <AppShell props rootTag>
    <PMMApp />
  </AppShell>
}
