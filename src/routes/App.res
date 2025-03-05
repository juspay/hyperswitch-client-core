open ReactNative
open Style

module ContextWrapper = {
  @react.component
  let make = (~props, ~rootTag, ~children) => {
    <PortalHost>
      <LoadingContext>
        <NativePropContext nativeProp={SdkTypes.nativeJsonToRecord(props, rootTag)}>
          <PaymentScreenContext>
            <ThemeContext>
              <ViewportContext>
                <LoggerContext>
                  <CardDataContext>
                    <CountryStateDataContext>
                      <AllApiDataContext>
                        <LocaleStringDataContext> children </LocaleStringDataContext>
                      </AllApiDataContext>
                    </CountryStateDataContext>
                  </CardDataContext>
                </LoggerContext>
              </ViewportContext>
            </ThemeContext>
          </PaymentScreenContext>
        </NativePropContext>
      </LoadingContext>
    </PortalHost>
  }
}

module App = {
  @react.component
  let make = () => {
    <View style={viewStyle(~flex=1., ())}>
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
      <App />
    </ContextWrapper>
  </ErrorBoundary>
}
