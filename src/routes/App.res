module ContextWrapper = {
  @react.component
  let make = (~props, ~rootTag, ~children) => {
    let nativeProp = SdkTypes.nativeJsonToRecord(props, rootTag)
    <NativePropContext nativeProp>
      <LoggerContext>
        <ViewportContext
          topInset={nativeProp.sdkParams.insets
          ->Option.map(insets => insets.top)
          ->Option.getOr(None)}
          bottomInset={nativeProp.sdkParams.insets
          ->Option.map(insets => insets.bottom)
          ->Option.getOr(None)}>
          <ThemeContext appearance=nativeProp.configuration.appearance>
            <LocaleStringDataContext locale=nativeProp.configuration.locale>
              <CountryStateDataContext>
                <LoadingContext>
                  <BannerContext> children </BannerContext>
                </LoadingContext>
              </CountryStateDataContext>
            </LocaleStringDataContext>
          </ThemeContext>
        </ViewportContext>
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
