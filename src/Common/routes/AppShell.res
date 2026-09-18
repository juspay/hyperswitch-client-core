/* Shared application shell used by the root component of every flow bundle
 * (payments entry `index.js` and the PMM entry `pmmindex.js`). It wires the
 * common context providers + error boundary once so each flow's root only has
 * to supply its own router as `children`.
 */

@react.component
let make = (~props, ~rootTag, ~children) => {
  let nativeProp = SdkTypes.nativeJsonToRecord(props, rootTag)
  <ErrorBoundary rootTag level=FallBackScreen.Top>
    <NativePropContext nativeProp>
      <LoggerContext>
        <SafeAreaContext>
          <ThemeContext appearance=nativeProp.configuration.appearance>
            <LocaleStringDataContext locale=nativeProp.configuration.locale>
              <CountryStateDataContext>
                <LoadingContext>
                  <BannerContext> <PortalHost> children </PortalHost> </BannerContext>
                </LoadingContext>
              </CountryStateDataContext>
            </LocaleStringDataContext>
          </ThemeContext>
        </SafeAreaContext>
      </LoggerContext>
    </NativePropContext>
  </ErrorBoundary>
}
