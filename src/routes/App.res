module ContextWrapper = {
  @react.component
  let make = (~props, ~rootTag, ~children) => {
    let nativeProp = SdkTypes.nativeJsonToRecord(props, rootTag)
    <NativePropContext nativeProp>
      <LoggerContext>
        <SafeAreaContext>
          <ThemeContext appearance=nativeProp.configuration.appearance>
            <LocaleStringDataContext locale=nativeProp.configuration.locale>
              <CountryStateDataContext>
                <LoadingContext>
                  <BannerContext> children </BannerContext>
                </LoadingContext>
              </CountryStateDataContext>
            </LocaleStringDataContext>
          </ThemeContext>
        </SafeAreaContext>
      </LoggerContext>
    </NativePropContext>
  }
}

module App = {
  @react.component
  let make = () => {
    <NavigatorRouterParent />
  }
}

@react.component
let make = (~props, ~rootTag) => {
  <ErrorBoundary rootTag level=FallBackScreen.Top>
    <ContextWrapper props rootTag>
      <PortalHost>
        <App />
      </PortalHost>
    </ContextWrapper>
  </ErrorBoundary>
}
