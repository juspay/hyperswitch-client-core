open ReactNative
open Style

module CustomKeyboardAvoidingView = {
  @react.component
  let make = (~children) => {
    <KeyboardAvoidingView style={viewStyle(~flex=1., ())} behavior={#padding}>
      {children}
    </KeyboardAvoidingView>
  }
}
module ContextWrapper = {
  @react.component
  let make = (~props, ~rootTag, ~children) => {
    <LoadingContext>
      <NativePropContext nativeProp={SdkTypes.nativeJsonToRecord(props, rootTag)}>
        <PaymentScreenContext>
          <ThemeContext>
            <LoggerContext>
              <CardDataContext>
                <AllApiDataContext>
                  <CustomKeyboardAvoidingView> children </CustomKeyboardAvoidingView>
                </AllApiDataContext>
              </CardDataContext>
            </LoggerContext>
          </ThemeContext>
        </PaymentScreenContext>
      </NativePropContext>
    </LoadingContext>
  }
}

module App = {
  @react.component
  let make = () => {
    <View style={viewStyle(~flex=1., ())}>
      {ReactNative.Platform.os == #android
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
