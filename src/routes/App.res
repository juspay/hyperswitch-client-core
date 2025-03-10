open ReactNative
open Style

module ContextWrapper = {
  @react.component
  let make = (~props, ~rootTag, ~children) => {
    <NativePropContext nativeProp={SdkTypes.nativeJsonToRecord(props, rootTag)}>
      <LocaleStringDataContext>
        <PortalHost>
          <LoadingContext>
            <PaymentScreenContext>
              <ThemeContext>
                <ViewportContext>
                  <LoggerContext>
                    <CardDataContext>
                      <CountryStateDataContext>
                        <AllApiDataContext> children </AllApiDataContext>
                      </CountryStateDataContext>
                    </CardDataContext>
                  </LoggerContext>
                </ViewportContext>
              </ThemeContext>
            </PaymentScreenContext>
          </LoadingContext>
        </PortalHost>
      </LocaleStringDataContext>
    </NativePropContext>
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
