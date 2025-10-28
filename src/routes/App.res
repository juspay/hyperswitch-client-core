open ReactNative
open Style

module ContextWrapper = {
  @react.component
  let make = (~props, ~rootTag, ~children) => {
    let nativeProp = SdkTypes.nativeJsonToRecord(props, rootTag)
    <NativePropContext nativeProp>
      <LoggerContext>
        <ViewportContext
          topInset=nativeProp.hyperParams.topInset bottomInset=nativeProp.hyperParams.bottomInset>
          <ThemeContext appearance=nativeProp.configuration.appearance>
            <LocaleStringDataContext locale=nativeProp.configuration.appearance.locale>
              <CountryStateDataContext>
                <LoadingContext>
                  <DynamicFieldsContext>
                    <BannerContext> children </BannerContext>
                  </DynamicFieldsContext>
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
    <View style={s({flex: 1.})}>
      {WebKit.platform === #android
        ? <StatusBar translucent=true backgroundColor="transparent" />
        : React.null}
      <NavigatorRouterParent />
    </View>
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
