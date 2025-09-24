open ReactNative
open Style

type level = Top | Screen | Widget

@react.component
let make = (~error: Sentry.fallbackArg, ~level: level, ~rootTag) => {
  let {simplyExit} = HyperModule.useExitPaymentsheet()

  switch level {
  | Top =>
    <SafeAreaView style={s({flex: 1., alignItems: #center, justifyContent: #"flex-end"})}>
      <View
        style={s({
          width: 100.->pct,
          alignItems: #center,
          backgroundColor: "white",
          padding: 20.->dp,
        })}>
        <View style={s({alignItems: #"flex-end", width: 100.->pct})}>
          <CustomPressable
            onPress={_ => simplyExit(PaymentConfirmTypes.defaultCancelError, rootTag, false)}>
            <Icon name="close" fill="black" height=20. width=20. />
          </CustomPressable>
        </View>
        <View style={s({flexDirection: #row, padding: 20.->dp})}>
          <Icon name="errorIcon" fill="black" height=60. width=60. />
          <View style={s({flex: 1., alignItems: #center, justifyContent: #center})}>
            <TextWrapper textType={ErrorTextBold}>
              {"Oops, something went wrong!"->React.string}
            </TextWrapper>
            <TextWrapper textType={ErrorText}>
              {"We'll be back with you shortly :)"->React.string}
            </TextWrapper>
          </View>
        </View>
        <Space />
        <CustomPressable onPress={_ => error.resetError()}>
          <Icon name="refresh" fill="black" height=32. width=32. />
        </CustomPressable>
        <Space />
      </View>
    </SafeAreaView>
  | Screen =>
    <View
      style={s({
        alignItems: #center,
        justifyContent: #center,
        width: 100.->pct,
        padding: 20.->dp,
      })}>
      <View style={s({flexDirection: #row, backgroundColor: "white"})}>
        <Icon name="errorIcon" fill="black" height=60. width=60. />
        <View style={s({flex: 1., alignItems: #center, justifyContent: #center})}>
          <TextWrapper textType={ErrorTextBold}>
            {"Oops, something went wrong!"->React.string}
          </TextWrapper>
          <TextWrapper textType={ErrorText}>
            {"Try another payment method :)"->React.string}
          </TextWrapper>
        </View>
      </View>
    </View>
  | Widget =>
    <View
      style={s({
        flex: 1.,
        backgroundColor: "white",
        alignItems: #center,
        justifyContent: #center,
        paddingHorizontal: 40.->dp,
      })}>
      <View style={s({flexDirection: #row, backgroundColor: "white"})}>
        <Icon name="errorIcon" fill="black" height=32. width=32. />
        <View style={s({flex: 1., alignItems: #center, justifyContent: #center})}>
          <TextWrapper textType={ErrorTextBold}>
            {"Oops, something went wrong!"->React.string}
          </TextWrapper>
        </View>
      </View>
    </View>
  }
}
