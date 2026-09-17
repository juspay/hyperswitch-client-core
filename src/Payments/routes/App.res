/* Root component of the payments bundle (`hyperSwitch`). The shared provider
 * stack lives in `src/Common/routes/AppShell.res`; this root only mounts the
 * payments navigation tree (`NavigatorRouterParent`).
 */
@react.component
let make = (~props, ~rootTag) => {
  <AppShell props rootTag>
    <NavigatorRouterParent />
  </AppShell>
}
