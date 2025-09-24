open ReactNative
open Style

module ContextWrapper = {
  @react.component
  let make = (~props, ~rootTag, ~children) => {
    <NativePropContext nativeProp={SdkTypes.nativeJsonToRecord(props, rootTag)}>
      <LocaleStringDataContext>
        <CountryStateDataContext>
          <ViewportContext>
            <LoadingContext>
              <PaymentScreenContext>
                <ThemeContext>
                  <LoggerContext>
                    <AllApiDataContext> children </AllApiDataContext>
                  </LoggerContext>
                </ThemeContext>
              </PaymentScreenContext>
            </LoadingContext>
          </ViewportContext>
        </CountryStateDataContext>
      </LocaleStringDataContext>
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
