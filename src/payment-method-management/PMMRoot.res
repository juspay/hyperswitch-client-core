// Root component of the `hyperPMM` host: native PMM surfaces (sheet and
// widget) register their own React entry (`index.payment-method-management.js`
// → PMMEntry) under
// their own moduleName, so they mount the PMM navigator directly instead of
// routing through the payments root's sdkState switch. Their props carry
// `pmmState`; `sdkState` parses to NoView on these surfaces.
open ReactNative
open Style

@react.component
let make = (~props, ~rootTag) => {
  <ErrorBoundary rootTag level=FallBackScreen.Top>
    <ContextWrapper props rootTag>
      <PortalHost>
        <View style={s({flex: 1.})}> <PMMangementNavigatorRouter /> </View>
      </PortalHost>
    </ContextWrapper>
  </ErrorBoundary>
}
